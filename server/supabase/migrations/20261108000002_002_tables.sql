-- Active: 1794135430745@@aws-0-ap-southeast-1.pooler.supabase.com@5432@postgres@public
-- ============================================================================
-- MIGRASI 002: TABEL INTI, CONSTRAINT INVARIAN, & TRIGGER PENJAGA INTEGRITAS
-- Proyek   : KantinCerdas (Supabase PostgreSQL 15-17)
-- Perbaikan: CRIT-01, CRIT-05, HIGH-08, HIGH-10, HIGH-11, HIGH-12, HIGH-13,
--            HIGH-15, MED-17, MED-18, MED-20, MED-21, LOW-23, LOW-24
--
-- HIERARKI PENGUNCIAN GLOBAL & TUNGGAL (MODUL F — WAJIB DIIKUTI SEMUA RPC):
--   1. pg_advisory_xact_lock(hashtextextended(family || ':' || request_id, 0))
--   2. public.users (ORDER BY id ASC, FOR NO KEY UPDATE / FOR SHARE)
--   3. public.stalls (FOR NO KEY UPDATE / FOR SHARE)
--   4. public.menus (ORDER BY id ASC, FOR NO KEY UPDATE / FOR SHARE)
--   5. public.orders (FOR NO KEY UPDATE / FOR SHARE)
--   6. public.order_items
--   7. public.canteen_applications (FOR NO KEY UPDATE)
--   8. public.food_preferences (FOR NO KEY UPDATE)
--   9. public.media_assets (FOR NO KEY UPDATE)
-- ============================================================================
BEGIN;

-- ----------------------------------------------------------------------------
-- 1. FUNGSI GENERATOR ID 128-BIT & VALIDATOR IMMUTABLE UNTUK CHECK CONSTRAINT
-- ----------------------------------------------------------------------------

-- Pembuat ID 128-bit berbasis gen_random_uuid() inti PostgreSQL (CRIT-01, MED-17)
CREATE OR REPLACE FUNCTION public.fn_gen_entity_id(p_prefix TEXT)
RETURNS TEXT
LANGUAGE sql
VOLATILE
SET search_path = ''
AS $$
  SELECT p_prefix || '_' || pg_catalog.replace(pg_catalog.gen_random_uuid()::TEXT, '-', '');
$$;

-- Tabel konfigurasi aplikasi tunggal (untuk host storage per environment: staging vs production)
CREATE TABLE IF NOT EXISTS public.app_config (
  config_key TEXT COLLATE "C" PRIMARY KEY CHECK (
    config_key = pg_catalog.btrim(config_key) AND pg_catalog.length(config_key) BETWEEN 1 AND 64
  ),
  config_value TEXT NOT NULL CHECK (
    config_value = pg_catalog.btrim(config_value) AND pg_catalog.length(config_value) BETWEEN 1 AND 512
  ),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.timezone('utc', pg_catalog.now())
);

-- Fungsi pembaca host/base URL bucket resmi (HIGH-10)
-- Dapat dioverride per sesi/database dengan ALTER DATABASE ... SET app.storage_public_base_url = '...'
-- atau melalui baris di public.app_config.
CREATE OR REPLACE FUNCTION public.fn_storage_public_base_url()
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT COALESCE(
    NULLIF(pg_catalog.btrim(pg_catalog.current_setting('app.storage_public_base_url', true)), ''),
    '/storage/v1/object/public/kantin-media/'
  );
$$;

-- Validator URL gambar Zero-Trust selaras ImageSecurityValidator.normalizeSafeImageUrl() (HIGH-10)
-- Menerima NULL atau URL https:// ke path resmi /storage/v1/object/public/kantin-media/<nama_aman>
-- maksimal 512 karakter, tanpa userinfo @, .., backslash, karakter kontrol, kutip, atau kurung sudut.
CREATE OR REPLACE FUNCTION public.fn_is_safe_image_url(p_url TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
SET search_path = ''
AS $$
DECLARE
  v_lower TEXT;
BEGIN
  IF p_url IS NULL THEN
    RETURN TRUE;
  END IF;

  -- Tolak string belum di-trim, kosong, atau melebihi 512 karakter
  IF p_url IS DISTINCT FROM pg_catalog.btrim(p_url) THEN
    RETURN FALSE;
  END IF;
  IF pg_catalog.length(p_url) < 1 OR pg_catalog.length(p_url) > 512 THEN
    RETURN FALSE;
  END IF;

  -- Tolak karakter kontrol ASCII (0x00-0x20, 0x7F), spasi, <, >, ", ', \, `, atau userinfo @
  IF p_url ~ '[\x00-\x20\x7f<">''\\`@]' THEN
    RETURN FALSE;
  END IF;

  v_lower := pg_catalog.lower(p_url);

  -- Tolak path traversal (.. atau %2e%2e atau %5c)
  IF pg_catalog.strpos(v_lower, '..') > 0
     OR pg_catalog.strpos(v_lower, '%2e%2e') > 0
     OR pg_catalog.strpos(v_lower, '%5c') > 0 THEN
    RETURN FALSE;
  END IF;

  -- Wajib skema https:// menuju path resmi /storage/v1/object/public/kantin-media/<safe_file_name>
  -- Nama file wajib mengikuti pola kanonis {actor}_{category}_{uuid-v4}.{jpg|jpeg|png|webp}
  -- selaras dengan chk_media_assets_object_path_safe (baris 491) dan 010_storage.sql
  IF p_url !~ '^https://[a-zA-Z0-9.-]+(:[0-9]{1,5})?/storage/v1/object/public/kantin-media/[a-z0-9_-]{1,32}_(profile_avatar|menu_photo|stall_photo)_[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.(jpg|jpeg|png|webp)$' THEN
    RETURN FALSE;
  END IF;

  RETURN TRUE;
END;
$$;

-- Validator CHECK untuk array avoid_ingredients pada food_preferences (MED-18)
-- Menolak elemen NULL, kosong, belum di-trim, mengandung koma/newline/CR, > 240 code point (60 grapheme),
-- duplikat case-insensitive, atau kardinalitas > 20.
CREATE OR REPLACE FUNCTION public.fn_is_valid_avoid_ingredients(p_items TEXT[])
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
SET search_path = ''
AS $$
DECLARE
  v_count INTEGER;
  v_item TEXT;
  v_seen TEXT[] := '{}'::TEXT[];
  v_lower TEXT;
BEGIN
  IF p_items IS NULL THEN
    RETURN FALSE;
  END IF;

  v_count := pg_catalog.cardinality(p_items);
  IF v_count IS NULL OR v_count > 20 THEN
    RETURN FALSE;
  END IF;
  IF v_count = 0 THEN
    RETURN TRUE;
  END IF;

  FOREACH v_item IN ARRAY p_items LOOP
    IF v_item IS NULL THEN
      RETURN FALSE;
    END IF;
    IF v_item IS DISTINCT FROM pg_catalog.btrim(v_item) THEN
      RETURN FALSE;
    END IF;
    IF pg_catalog.length(v_item) < 1 OR pg_catalog.length(v_item) > 240 THEN
      RETURN FALSE;
    END IF;
    IF v_item ~ '[,\r\n]' THEN
      RETURN FALSE;
    END IF;
    v_lower := pg_catalog.lower(v_item);
    IF v_lower = ANY(v_seen) THEN
      RETURN FALSE;
    END IF;
    v_seen := pg_catalog.array_append(v_seen, v_lower);
  END LOOP;

  RETURN TRUE;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2. DEFINISI 10 TABEL DOMAIN, OPERASIONAL, & MEDIA DI SKEMA PUBLIC
--    Catatan MED-18: Batas panjang teks di PostgreSQL menggunakan code point
--    sebesar 4x batas grapheme klien (mis. 120 grapheme -> 480 code point,
--    300 grapheme -> 1200 code point, 1000 grapheme -> 4000 code point) agar
--    emoji gabungan ZWJ yang valid di Flutter tidak ditolak oleh PostgreSQL.
-- ----------------------------------------------------------------------------

-- Tabel 1: public.users
CREATE TABLE IF NOT EXISTS public.users (
  id TEXT COLLATE "C" PRIMARY KEY DEFAULT public.fn_gen_entity_id('usr'),
  auth_uid UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE RESTRICT,
  username TEXT NOT NULL,
  username_key TEXT COLLATE "C" NOT NULL UNIQUE,
  email TEXT NOT NULL,
  email_key TEXT COLLATE "C" NOT NULL UNIQUE,
  name TEXT NOT NULL,
  avatar_url TEXT,
  role public.user_role NOT NULL DEFAULT 'customer',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  session_epoch INTEGER NOT NULL DEFAULT 1,
  version INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.timezone('utc', pg_catalog.now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.timezone('utc', pg_catalog.now()),
  CONSTRAINT chk_users_id_format CHECK (id ~ '^usr_[a-f0-9]{32}$'),
  CONSTRAINT chk_users_version_pos CHECK (version >= 1),
  CONSTRAINT chk_users_session_epoch_pos CHECK (session_epoch >= 1),
  CONSTRAINT chk_users_updated_at CHECK (updated_at >= created_at),
  CONSTRAINT chk_users_username_format CHECK (
    username = pg_catalog.btrim(username)
    AND pg_catalog.length(username) BETWEEN 3 AND 20
    AND username ~ '^[a-zA-Z0-9._]+$'
  ),
  CONSTRAINT chk_users_email_format CHECK (
    email = pg_catalog.btrim(email)
    AND pg_catalog.length(email) BETWEEN 3 AND 254
    AND email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'
  ),
  CONSTRAINT chk_users_name_length CHECK (
    name = pg_catalog.btrim(name)
    AND pg_catalog.length(name) BETWEEN 1 AND 480
  ),
  CONSTRAINT chk_users_keys_lowercase CHECK (
    username_key = pg_catalog.lower(pg_catalog.btrim(username))
    AND email_key = pg_catalog.lower(pg_catalog.btrim(email))
  ),
  CONSTRAINT chk_users_avatar_url_safe CHECK (public.fn_is_safe_image_url(avatar_url))
);

-- Tabel 2: public.stalls (1 owner = 1 stan, owner_id immutable)
CREATE TABLE IF NOT EXISTS public.stalls (
  id TEXT COLLATE "C" PRIMARY KEY DEFAULT public.fn_gen_entity_id('stl'),
  owner_id TEXT COLLATE "C" NOT NULL UNIQUE REFERENCES public.users(id) ON DELETE RESTRICT,
  name TEXT NOT NULL,
  block TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  image_url TEXT,
  is_open BOOLEAN NOT NULL DEFAULT FALSE,
  prep_time_min INTEGER NOT NULL DEFAULT 15,
  version INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.timezone('utc', pg_catalog.now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.timezone('utc', pg_catalog.now()),
  CONSTRAINT chk_stalls_id_format CHECK (id ~ '^stl_[a-f0-9]{32}$'),
  CONSTRAINT chk_stalls_prep_time CHECK (prep_time_min BETWEEN 1 AND 180),
  CONSTRAINT chk_stalls_version_pos CHECK (version >= 1),
  CONSTRAINT chk_stalls_updated_at CHECK (updated_at >= created_at),
  CONSTRAINT chk_stalls_name_length CHECK (
    name = pg_catalog.btrim(name)
    AND pg_catalog.length(name) BETWEEN 1 AND 480
  ),
  CONSTRAINT chk_stalls_block_length CHECK (
    block = pg_catalog.btrim(block)
    AND pg_catalog.length(block) BETWEEN 1 AND 480
  ),
  CONSTRAINT chk_stalls_desc_length CHECK (
    description = pg_catalog.btrim(description)
    AND pg_catalog.length(description) <= 4000
  ),
  CONSTRAINT chk_stalls_image_url_safe CHECK (public.fn_is_safe_image_url(image_url))
);

-- Tabel 3: public.menus (Soft-delete via deleted_at)
CREATE TABLE IF NOT EXISTS public.menus (
  id TEXT COLLATE "C" PRIMARY KEY DEFAULT public.fn_gen_entity_id('mnu'),
  stall_id TEXT COLLATE "C" NOT NULL REFERENCES public.stalls(id) ON DELETE RESTRICT,
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  category public.menu_category NOT NULL,
  price_idr INTEGER NOT NULL,
  is_available BOOLEAN NOT NULL DEFAULT TRUE,
  image_url TEXT,
  version INTEGER NOT NULL DEFAULT 1,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.timezone('utc', pg_catalog.now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.timezone('utc', pg_catalog.now()),
  CONSTRAINT chk_menus_id_format CHECK (id ~ '^mnu_[a-f0-9]{32}$'),
  CONSTRAINT chk_menus_price_range CHECK (price_idr BETWEEN 1 AND 10000000),
  CONSTRAINT chk_menus_version_pos CHECK (version >= 1),
  CONSTRAINT chk_menus_updated_at CHECK (updated_at >= created_at),
  CONSTRAINT chk_menus_soft_delete_consistency CHECK (
    (deleted_at IS NULL) OR (is_available = FALSE AND deleted_at >= created_at)
  ),
  CONSTRAINT chk_menus_name_length CHECK (
    name = pg_catalog.btrim(name)
    AND pg_catalog.length(name) BETWEEN 1 AND 480
  ),
  CONSTRAINT chk_menus_desc_length CHECK (
    description = pg_catalog.btrim(description)
    AND pg_catalog.length(description) <= 4000
  ),
  CONSTRAINT chk_menus_image_url_safe CHECK (public.fn_is_safe_image_url(image_url))
);

-- Sequence nomor antrean pesanan: tetap CACHE 1 agar nomor antrean KC-xxx yang
-- tampil ke pengguna berurutan ketat tanpa melompat antar-koneksi (Modul E.4).
CREATE SEQUENCE IF NOT EXISTS public.order_number_seq
  AS BIGINT
  START WITH 101
  INCREMENT BY 1
  MINVALUE 101
  NO MAXVALUE
  CACHE 1;

-- Tabel 4: public.orders (total_price_idr BIGINT — HIGH-13)
CREATE TABLE IF NOT EXISTS public.orders (
  id TEXT COLLATE "C" PRIMARY KEY DEFAULT public.fn_gen_entity_id('ord'),
  order_number TEXT COLLATE "C" NOT NULL UNIQUE,
  customer_id TEXT COLLATE "C" NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  customer_name TEXT NOT NULL,
  stall_id TEXT COLLATE "C" NOT NULL REFERENCES public.stalls(id) ON DELETE RESTRICT,
  stall_name TEXT NOT NULL,
  status public.order_status NOT NULL DEFAULT 'waiting',
  payment_status public.order_payment_status NOT NULL DEFAULT 'unpaid',
  total_price_idr BIGINT NOT NULL,
  note TEXT NOT NULL DEFAULT '',
  rejection_reason TEXT,
  version INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.timezone('utc', pg_catalog.now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.timezone('utc', pg_catalog.now()),
  CONSTRAINT chk_orders_id_format CHECK (id ~ '^ord_[a-f0-9]{32}$'),
  CONSTRAINT chk_orders_number_format CHECK (order_number ~ '^KC-[0-9]{3,20}$'),
  CONSTRAINT chk_orders_total_price_range CHECK (total_price_idr BETWEEN 1 AND 1000000000),
  CONSTRAINT chk_orders_version_pos CHECK (version >= 1),
  CONSTRAINT chk_orders_updated_at CHECK (updated_at >= created_at),
  CONSTRAINT chk_orders_customer_name_snapshot CHECK (
    customer_name = pg_catalog.btrim(customer_name)
    AND pg_catalog.length(customer_name) BETWEEN 1 AND 480
  ),
  CONSTRAINT chk_orders_stall_name_snapshot CHECK (
    stall_name = pg_catalog.btrim(stall_name)
    AND pg_catalog.length(stall_name) BETWEEN 1 AND 480
  ),
  CONSTRAINT chk_orders_note_length CHECK (
    note = pg_catalog.btrim(note)
    AND pg_catalog.length(note) <= 1200
  ),
  CONSTRAINT chk_orders_payment_consistency CHECK (
    (status IN ('waiting', 'processing', 'ready') AND payment_status = 'unpaid' AND rejection_reason IS NULL) OR
    (status = 'completed' AND payment_status = 'paid' AND rejection_reason IS NULL) OR
    (status = 'cancelled' AND payment_status = 'notCharged' AND rejection_reason IS NULL) OR
    (
      status = 'rejected'
      AND payment_status = 'notCharged'
      AND rejection_reason IS NOT NULL
      AND rejection_reason = pg_catalog.btrim(rejection_reason)
      AND pg_catalog.length(rejection_reason) BETWEEN 1 AND 1200
    )
  )
);

-- Tabel 5: public.order_items (FK ke menus(id) ON DELETE RESTRICT, note <= 300 grapheme / 1200 cp)
CREATE TABLE IF NOT EXISTS public.order_items (
  order_id TEXT COLLATE "C" NOT NULL REFERENCES public.orders(id) ON DELETE RESTRICT,
  menu_id TEXT COLLATE "C" NOT NULL REFERENCES public.menus(id) ON DELETE RESTRICT,
  position INTEGER NOT NULL,
  name TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  unit_price_idr INTEGER NOT NULL,
  note TEXT NOT NULL DEFAULT '',
  PRIMARY KEY (order_id, menu_id),
  CONSTRAINT uq_order_items_position UNIQUE (order_id, position),
  CONSTRAINT chk_order_items_position_nonneg CHECK (position >= 0),
  CONSTRAINT chk_order_items_quantity_range CHECK (quantity BETWEEN 1 AND 99),
  CONSTRAINT chk_order_items_unit_price_range CHECK (unit_price_idr BETWEEN 1 AND 10000000),
  CONSTRAINT chk_order_items_name_snapshot CHECK (
    name = pg_catalog.btrim(name)
    AND pg_catalog.length(name) BETWEEN 1 AND 480
  ),
  CONSTRAINT chk_order_items_note_length CHECK (
    note = pg_catalog.btrim(note)
    AND pg_catalog.length(note) <= 1200
  )
);

-- Tabel 6: public.canteen_applications (CRIT-05 & HIGH-15)
CREATE TABLE IF NOT EXISTS public.canteen_applications (
  id TEXT COLLATE "C" PRIMARY KEY DEFAULT public.fn_gen_entity_id('app'),
  applicant_id TEXT COLLATE "C" NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  location TEXT NOT NULL,
  phone TEXT NOT NULL,
  status public.application_status NOT NULL DEFAULT 'submitted',
  reason TEXT,
  version INTEGER NOT NULL DEFAULT 1,
  previous_id TEXT COLLATE "C" UNIQUE REFERENCES public.canteen_applications(id) ON DELETE RESTRICT,
  reviewed_by TEXT COLLATE "C" REFERENCES public.users(id) ON DELETE RESTRICT,
  reviewed_at TIMESTAMPTZ,
  approved_stall_id TEXT COLLATE "C" UNIQUE REFERENCES public.stalls(id) ON DELETE RESTRICT,
  is_latest BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.timezone('utc', pg_catalog.now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.timezone('utc', pg_catalog.now()),
  CONSTRAINT chk_applications_id_format CHECK (id ~ '^app_[a-f0-9]{32}$'),
  CONSTRAINT chk_applications_version_pos CHECK (version >= 1),
  CONSTRAINT chk_applications_updated_at CHECK (updated_at >= created_at),
  CONSTRAINT chk_applications_no_self_prev CHECK (previous_id IS NULL OR previous_id <> id),
  CONSTRAINT chk_applications_fields CHECK (
    name = pg_catalog.btrim(name) AND pg_catalog.length(name) BETWEEN 1 AND 480 AND
    description = pg_catalog.btrim(description) AND pg_catalog.length(description) BETWEEN 1 AND 4000 AND
    location = pg_catalog.btrim(location) AND pg_catalog.length(location) BETWEEN 1 AND 480 AND
    phone = pg_catalog.btrim(phone) AND pg_catalog.length(phone) <= 24 AND
    phone ~ '^\+?[0-9 ()-]+$' AND
    pg_catalog.length(pg_catalog.regexp_replace(phone, '[^0-9]', '', 'g')) BETWEEN 8 AND 15
  ),
  CONSTRAINT chk_applications_status_review_consistency CHECK (
    (
      status IN ('submitted', 'reviewing')
      AND reason IS NULL
      AND reviewed_by IS NULL
      AND reviewed_at IS NULL
      AND approved_stall_id IS NULL
    ) OR (
      status = 'rejected'
      AND reason IS NOT NULL
      AND reason = pg_catalog.btrim(reason)
      AND pg_catalog.length(reason) BETWEEN 1 AND 1200
      AND reviewed_by IS NOT NULL
      AND reviewed_at IS NOT NULL
      AND approved_stall_id IS NULL
      AND reviewed_by <> applicant_id
    ) OR (
      status = 'approved'
      AND reason IS NULL
      AND reviewed_by IS NOT NULL
      AND reviewed_at IS NOT NULL
      AND approved_stall_id IS NOT NULL
      AND reviewed_by <> applicant_id
    )
  )
);

-- Tabel 7: public.food_preferences (MED-18, LOW-23: tambah created_at & chk_food_prefs_updated_at)
CREATE TABLE IF NOT EXISTS public.food_preferences (
  customer_id TEXT COLLATE "C" PRIMARY KEY REFERENCES public.users(id) ON DELETE RESTRICT,
  max_budget_idr INTEGER,
  vegetarian BOOLEAN NOT NULL DEFAULT FALSE,
  avoid_ingredients TEXT[] NOT NULL DEFAULT '{}'::TEXT[],
  version INTEGER NOT NULL DEFAULT 1,
  created_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.timezone('utc', pg_catalog.now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.timezone('utc', pg_catalog.now()),
  CONSTRAINT chk_food_prefs_budget_range CHECK (
    max_budget_idr IS NULL OR (max_budget_idr BETWEEN 1 AND 10000000)
  ),
  CONSTRAINT chk_food_prefs_version_pos CHECK (version >= 1),
  CONSTRAINT chk_food_prefs_updated_at CHECK (updated_at >= created_at),
  CONSTRAINT chk_food_prefs_ingredients_valid CHECK (
    public.fn_is_valid_avoid_ingredients(avoid_ingredients)
  )
);

-- Tabel 8: public.mutation_receipts (CRIT-03, CRIT-04, MED-20)
CREATE TABLE IF NOT EXISTS public.mutation_receipts (
  family public.mutation_family NOT NULL,
  request_id TEXT COLLATE "C" NOT NULL,
  actor_id TEXT COLLATE "C" NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  payload_hash TEXT COLLATE "C" NOT NULL,
  outcome public.mutation_outcome NOT NULL,
  request_snapshot JSONB NOT NULL,
  response_snapshot JSONB,
  lookup_snapshot JSONB NOT NULL,
  sealed BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.timezone('utc', pg_catalog.now()),
  completed_at TIMESTAMPTZ,
  PRIMARY KEY (family, request_id),
  CONSTRAINT chk_mutation_receipts_request_id_hex CHECK (request_id ~ '^[a-f0-9]{48}$'),
  CONSTRAINT chk_mutation_receipts_payload_hash_hex CHECK (payload_hash ~ '^[a-f0-9]{64}$'),
  CONSTRAINT chk_mutation_receipts_completed_at_consistency CHECK (
    (outcome = 'pending') = (completed_at IS NULL)
  ),
  CONSTRAINT chk_mutation_receipts_response_consistency CHECK (
    (outcome <> 'applied') OR (response_snapshot IS NOT NULL)
  ),
  CONSTRAINT chk_mutation_receipts_sealed_consistency CHECK (
    (outcome = 'pending' AND sealed = FALSE) OR
    (outcome IN ('applied', 'not_applied') AND sealed = TRUE)
  )
);

-- Tabel 9: public.audit_events (HIGH-12, MED-21: BIGINT GENERATED ALWAYS AS IDENTITY)
CREATE TABLE IF NOT EXISTS public.audit_events (
  id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  actor_id TEXT COLLATE "C" NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(actor_id)) >= 1),
  operation TEXT NOT NULL CHECK (
    operation = pg_catalog.btrim(operation) AND pg_catalog.length(operation) BETWEEN 1 AND 120
  ),
  target_id TEXT COLLATE "C" NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(target_id)) >= 1),
  request_id TEXT COLLATE "C" NOT NULL CHECK (pg_catalog.length(pg_catalog.btrim(request_id)) >= 1),
  before_version INTEGER CHECK (before_version IS NULL OR before_version >= 1),
  after_version INTEGER CHECK (after_version IS NULL OR after_version >= 1),
  reason TEXT CHECK (reason IS NULL OR (reason = pg_catalog.btrim(reason) AND pg_catalog.length(reason) <= 1200)),
  outcome TEXT NOT NULL CHECK (
    outcome = pg_catalog.btrim(outcome) AND pg_catalog.length(outcome) BETWEEN 1 AND 64
  ),
  occurred_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.timezone('utc', pg_catalog.now())
);

-- Tabel 10: public.media_assets (Modul J / HIGH-09: kuota per pengguna & pembersihan objek yatim)
CREATE TABLE IF NOT EXISTS public.media_assets (
  id TEXT COLLATE "C" PRIMARY KEY DEFAULT public.fn_gen_entity_id('med'),
  owner_id TEXT COLLATE "C" NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  category TEXT COLLATE "C" NOT NULL CHECK (category IN ('profile_avatar', 'menu_photo', 'stall_photo')),
  object_path TEXT COLLATE "C" NOT NULL UNIQUE,
  public_url TEXT NOT NULL,
  mime_type TEXT COLLATE "C" NOT NULL CHECK (mime_type IN ('image/jpeg', 'image/png', 'image/webp')),
  size_bytes INTEGER NOT NULL CHECK (size_bytes BETWEEN 32 AND 2097152),
  sha256_hex TEXT COLLATE "C" NOT NULL CHECK (sha256_hex ~ '^[a-f0-9]{64}$'),
  is_referenced BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.timezone('utc', pg_catalog.now()),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.timezone('utc', pg_catalog.now()),
  CONSTRAINT chk_media_assets_id_format CHECK (id ~ '^med_[a-f0-9]{32}$'),
  CONSTRAINT chk_media_assets_updated_at CHECK (updated_at >= created_at),
  CONSTRAINT chk_media_assets_object_path_safe CHECK (
    object_path ~ '^[a-z0-9_-]{1,32}_(profile_avatar|menu_photo|stall_photo)_[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.(jpg|png|webp)$'
  ),
  CONSTRAINT chk_media_assets_public_url_safe CHECK (public.fn_is_safe_image_url(public_url))
);

-- ----------------------------------------------------------------------------
-- 3. TRIGGER PENJAGA INTEGRITAS, IMMUTABILITY, & INVARIAN (MODUL C, D, G)
-- ----------------------------------------------------------------------------

-- A. Trigger generik BEFORE UPDATE: set updated_at otomatis & tolak perubahan created_at
CREATE OR REPLACE FUNCTION public.fn_trg_touch_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  v_now TIMESTAMPTZ := pg_catalog.timezone('utc', pg_catalog.now());
BEGIN
  IF NEW.created_at IS DISTINCT FROM OLD.created_at THEN
    RAISE EXCEPTION 'IMMUTABLE_VIOLATION: Kolom created_at tidak boleh diubah.'
      USING ERRCODE = 'KC020', HINT = 'Pertahankan nilai created_at asli.';
  END IF;

  IF v_now >= OLD.created_at THEN
    NEW.updated_at := v_now;
  ELSE
    NEW.updated_at := OLD.created_at;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_users_touch_updated_at ON public.users;
CREATE TRIGGER trg_users_touch_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.fn_trg_touch_updated_at();

DROP TRIGGER IF EXISTS trg_stalls_touch_updated_at ON public.stalls;
CREATE TRIGGER trg_stalls_touch_updated_at
  BEFORE UPDATE ON public.stalls
  FOR EACH ROW EXECUTE FUNCTION public.fn_trg_touch_updated_at();

DROP TRIGGER IF EXISTS trg_menus_touch_updated_at ON public.menus;
CREATE TRIGGER trg_menus_touch_updated_at
  BEFORE UPDATE ON public.menus
  FOR EACH ROW EXECUTE FUNCTION public.fn_trg_touch_updated_at();

DROP TRIGGER IF EXISTS trg_orders_touch_updated_at ON public.orders;
CREATE TRIGGER trg_orders_touch_updated_at
  BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.fn_trg_touch_updated_at();

DROP TRIGGER IF EXISTS trg_applications_touch_updated_at ON public.canteen_applications;
CREATE TRIGGER trg_applications_touch_updated_at
  BEFORE UPDATE ON public.canteen_applications
  FOR EACH ROW EXECUTE FUNCTION public.fn_trg_touch_updated_at();

DROP TRIGGER IF EXISTS trg_food_prefs_touch_updated_at ON public.food_preferences;
CREATE TRIGGER trg_food_prefs_touch_updated_at
  BEFORE UPDATE ON public.food_preferences
  FOR EACH ROW EXECUTE FUNCTION public.fn_trg_touch_updated_at();

DROP TRIGGER IF EXISTS trg_media_assets_touch_updated_at ON public.media_assets;
CREATE TRIGGER trg_media_assets_touch_updated_at
  BEFORE UPDATE ON public.media_assets
  FOR EACH ROW EXECUTE FUNCTION public.fn_trg_touch_updated_at();

-- B. Trigger immutability pada stalls (id, owner_id tidak boleh berubah)
CREATE OR REPLACE FUNCTION public.fn_trg_stalls_immutable()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF NEW.id IS DISTINCT FROM OLD.id OR NEW.owner_id IS DISTINCT FROM OLD.owner_id THEN
    RAISE EXCEPTION 'IMMUTABLE_VIOLATION: Kepemilikan stan (owner_id) dan id bersifat permanen.'
      USING ERRCODE = 'KC020', HINT = 'Jangan mengubah id atau owner_id pada tabel stalls.';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_stalls_immutable ON public.stalls;
CREATE TRIGGER trg_stalls_immutable
  BEFORE UPDATE ON public.stalls
  FOR EACH ROW EXECUTE FUNCTION public.fn_trg_stalls_immutable();

-- C. Trigger immutability snapshot pada orders (id, order_number, customer, stall, total, note)
CREATE OR REPLACE FUNCTION public.fn_trg_orders_immutable()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF NEW.id IS DISTINCT FROM OLD.id
     OR NEW.order_number IS DISTINCT FROM OLD.order_number
     OR NEW.customer_id IS DISTINCT FROM OLD.customer_id
     OR NEW.customer_name IS DISTINCT FROM OLD.customer_name
     OR NEW.stall_id IS DISTINCT FROM OLD.stall_id
     OR NEW.stall_name IS DISTINCT FROM OLD.stall_name
     OR NEW.total_price_idr IS DISTINCT FROM OLD.total_price_idr
     OR NEW.note IS DISTINCT FROM OLD.note THEN
    RAISE EXCEPTION 'IMMUTABLE_VIOLATION: Snapshot identitas dan finansial pesanan tidak boleh diubah.'
      USING ERRCODE = 'KC020', HINT = 'Hanya status, payment_status, rejection_reason, version, dan updated_at yang dapat diperbarui.';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_orders_immutable ON public.orders;
CREATE TRIGGER trg_orders_immutable
  BEFORE UPDATE ON public.orders
  FOR EACH ROW EXECUTE FUNCTION public.fn_trg_orders_immutable();

-- D. Trigger immutability penuh pada order_items (tidak boleh UPDATE atau DELETE)
CREATE OR REPLACE FUNCTION public.fn_trg_order_items_immutable()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  RAISE EXCEPTION 'IMMUTABLE_VIOLATION: Baris order_items adalah snapshot historis dan tidak boleh diubah atau dihapus.'
    USING ERRCODE = 'KC020', HINT = 'Snapshot item pesanan bersifat permanen setelah dibuat.';
END;
$$;

DROP TRIGGER IF EXISTS trg_order_items_immutable ON public.order_items;
CREATE TRIGGER trg_order_items_immutable
  BEFORE UPDATE OR DELETE ON public.order_items
  FOR EACH ROW EXECUTE FUNCTION public.fn_trg_order_items_immutable();

-- E. Constraint trigger DEFERRABLE INITIALLY DEFERRED: orders <-> order_items (HIGH-15)
--    Menjamin setiap pesanan memiliki >= 1 item dan total_price_idr = SUM(quantity * unit_price_idr)
CREATE OR REPLACE FUNCTION public.fn_trg_verify_order_items_total()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  v_order_id TEXT;
  v_order RECORD;
  v_item_count BIGINT;
  v_items_sum BIGINT;
BEGIN
  IF TG_TABLE_NAME = 'orders' THEN
    v_order_id := COALESCE(NEW.id, OLD.id);
  ELSE
    v_order_id := COALESCE(NEW.order_id, OLD.order_id);
  END IF;

  SELECT id, total_price_idr INTO v_order
  FROM public.orders
  WHERE id = v_order_id;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  SELECT pg_catalog.count(*), COALESCE(pg_catalog.sum(oi.quantity::BIGINT * oi.unit_price_idr::BIGINT), 0)
  INTO v_item_count, v_items_sum
  FROM public.order_items oi
  WHERE oi.order_id = v_order_id;

  IF v_item_count < 1 OR v_items_sum IS DISTINCT FROM v_order.total_price_idr THEN
    RAISE EXCEPTION 'ORDER_INTEGRITY_VIOLATION: Pesanan % wajib memiliki minimal 1 item dengan total_price_idr sama dengan jumlah item.', v_order_id
      USING ERRCODE = 'KC022', HINT = 'Pastikan order_items dimasukkan dalam transaksi yang sama dan total_price_idr cocok.';
  END IF;

  RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_orders_verify_total ON public.orders;
CREATE CONSTRAINT TRIGGER trg_orders_verify_total
  AFTER INSERT OR UPDATE OF total_price_idr ON public.orders
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW EXECUTE FUNCTION public.fn_trg_verify_order_items_total();

DROP TRIGGER IF EXISTS trg_order_items_verify_total ON public.order_items;
CREATE CONSTRAINT TRIGGER trg_order_items_verify_total
  AFTER INSERT ON public.order_items
  DEFERRABLE INITIALLY DEFERRED
  FOR EACH ROW EXECUTE FUNCTION public.fn_trg_verify_order_items_total();

-- F. Trigger Last-Active-Admin Guard pada public.users (HIGH-11)
CREATE OR REPLACE FUNCTION public.fn_trg_protect_last_active_admin()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
DECLARE
  v_remaining_admins BIGINT;
BEGIN
  IF OLD.role = 'admin' AND OLD.is_active = TRUE THEN
    IF TG_OP = 'DELETE'
       OR NEW.role IS DISTINCT FROM 'admin'
       OR NEW.is_active IS DISTINCT FROM TRUE THEN
      SELECT pg_catalog.count(*) INTO v_remaining_admins
      FROM public.users u
      WHERE u.role = 'admin'
        AND u.is_active = TRUE
        AND u.id IS DISTINCT FROM OLD.id;

      IF v_remaining_admins < 1 THEN
        RAISE EXCEPTION 'LAST_ADMIN_PROTECTED: Tidak dapat menonaktifkan, menurunkan role, atau menghapus admin aktif terakhir.'
          USING ERRCODE = 'KC021', HINT = 'Promosikan admin aktif lain terlebih dahulu.';
      END IF;
    END IF;
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_users_protect_last_admin ON public.users;
CREATE TRIGGER trg_users_protect_last_admin
  BEFORE UPDATE OR DELETE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.fn_trg_protect_last_active_admin();

-- G. Trigger Append-Only pada public.audit_events (HIGH-12, Modul G)
CREATE OR REPLACE FUNCTION public.fn_trg_audit_events_append_only()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  RAISE EXCEPTION 'IMMUTABLE_VIOLATION: Tabel audit_events bersifat append-only dan tidak boleh diubah atau dihapus.'
    USING ERRCODE = 'KC020', HINT = 'Log audit tidak dapat dimodifikasi oleh role mana pun.';
END;
$$;

DROP TRIGGER IF EXISTS trg_audit_events_append_only ON public.audit_events;
CREATE TRIGGER trg_audit_events_append_only
  BEFORE UPDATE OR DELETE ON public.audit_events
  FOR EACH ROW EXECUTE FUNCTION public.fn_trg_audit_events_append_only();

-- H. Trigger Immutability pada public.mutation_receipts yang sudah sealed = TRUE (Modul D.9)
--    Menolak semua DELETE dan semua UPDATE pada baris yang sudah sealed = TRUE,
--    kecuali prosedur pemangkasan PII resmi yang mengeset session GUC
--    app.allow_pii_compaction = 'on' dan tetap mempertahankan seluruh kolom kunci tombstone.
CREATE OR REPLACE FUNCTION public.fn_trg_mutation_receipts_immutable()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = ''
AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    RAISE EXCEPTION 'IMMUTABLE_VIOLATION: Baris mutation_receipts (tombstone idempotensi) tidak boleh dihapus.'
      USING ERRCODE = 'KC020', HINT = 'Gunakan fn_compact_mutation_receipts_pii untuk memangkas snapshot PII tanpa menghapus tombstone.';
  END IF;

  IF OLD.sealed = TRUE THEN
    IF COALESCE(pg_catalog.current_setting('app.allow_pii_compaction', true), '') = 'on'
       AND NEW.family IS NOT DISTINCT FROM OLD.family
       AND NEW.request_id IS NOT DISTINCT FROM OLD.request_id
       AND NEW.actor_id IS NOT DISTINCT FROM OLD.actor_id
       AND NEW.payload_hash IS NOT DISTINCT FROM OLD.payload_hash
       AND NEW.outcome IS NOT DISTINCT FROM OLD.outcome
       AND NEW.sealed IS NOT DISTINCT FROM OLD.sealed
       AND NEW.created_at IS NOT DISTINCT FROM OLD.created_at
       AND NEW.completed_at IS NOT DISTINCT FROM OLD.completed_at THEN
      RETURN NEW;
    END IF;

    RAISE EXCEPTION 'LATE_SEALED_REQUEST: Receipt mutasi telah disegel dan tidak dapat diubah lagi.'
      USING ERRCODE = 'KC019', HINT = 'Receipt berstatus sealed bersifat permanen.';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_mutation_receipts_sealed_immutable ON public.mutation_receipts;
CREATE TRIGGER trg_mutation_receipts_sealed_immutable
  BEFORE UPDATE OR DELETE ON public.mutation_receipts
  FOR EACH ROW EXECUTE FUNCTION public.fn_trg_mutation_receipts_immutable();

COMMIT;
