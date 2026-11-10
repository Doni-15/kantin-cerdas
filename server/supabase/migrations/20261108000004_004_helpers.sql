-- Active: 1794135430745@@aws-0-ap-southeast-1.pooler.supabase.com@5432@postgres@public
-- ============================================================================
-- MIGRASI 004: FUNGSI HELPER OTORISASI, PROYEKSI JSON, & NORMALISASI INPUT
-- Proyek   : KantinCerdas (Supabase PostgreSQL 15-17)
-- Perbaikan: CRIT-02, CRIT-06, HIGH-08, HIGH-16 (.US 6 digit), MED-18, LOW-24
-- ============================================================================
BEGIN;

-- 1. Guard pemanggil wajib service_role / superuser migrasi (Modul B & CRIT-06)
CREATE OR REPLACE FUNCTION public.fn_require_service_role()
RETURNS VOID
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $$
DECLARE
  v_jwt_role TEXT;
BEGIN
  IF CURRENT_USER NOT IN ('service_role', 'postgres', 'supabase_admin') THEN
    RAISE EXCEPTION 'FORBIDDEN: Akses langsung ke fungsi database ditolak.'
      USING ERRCODE = 'KC002', HINT = 'Gunakan server backend /v1/* dengan kredensial service_role.';
  END IF;

  v_jwt_role := NULLIF(pg_catalog.btrim(pg_catalog.current_setting('request.jwt.claim.role', true)), '');
  IF v_jwt_role IS NOT NULL AND v_jwt_role IS DISTINCT FROM 'service_role' THEN
    RAISE EXCEPTION 'FORBIDDEN: Klaim role JWT bukan service_role.'
      USING ERRCODE = 'KC002', HINT = 'Klien anon/authenticated tidak diizinkan memanggil RPC secara langsung.';
  END IF;
END;
$$;

-- 2. Validasi dan penguncian aktor aktif beserta pemeriksaan role (Modul E.2 & HIGH-08)
--    Membaca public.users dengan FOR SHARE (atau FOR NO KEY UPDATE bila p_for_update = TRUE)
CREATE OR REPLACE FUNCTION public.fn_require_actor(
  p_actor_id TEXT,
  p_allowed_roles public.user_role[],
  p_for_update BOOLEAN DEFAULT FALSE
)
RETURNS public.users
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $$
DECLARE
  v_user public.users%ROWTYPE;
BEGIN
  PERFORM public.fn_require_service_role();

  IF p_actor_id IS NULL OR pg_catalog.btrim(p_actor_id) = '' THEN
    RAISE EXCEPTION 'UNAUTHENTICATED: Identitas pelaku (p_actor_id) wajib diisi.'
      USING ERRCODE = 'KC001', HINT = 'Pastikan token sesi diverifikasi server sebelum memanggil RPC.';
  END IF;

  IF p_allowed_roles IS NULL OR pg_catalog.cardinality(p_allowed_roles) IS NULL OR pg_catalog.cardinality(p_allowed_roles) = 0 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Daftar role yang diizinkan tidak boleh kosong.'
      USING ERRCODE = 'KC004', HINT = 'Berikan minimal satu role pada p_allowed_roles.';
  END IF;

  IF COALESCE(p_for_update, FALSE) THEN
    SELECT * INTO v_user
    FROM public.users u
    WHERE u.id = p_actor_id
    FOR NO KEY UPDATE;
  ELSE
    SELECT * INTO v_user
    FROM public.users u
    WHERE u.id = p_actor_id
    FOR SHARE;
  END IF;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'ACCOUNT_DISABLED: Akun pelaku tidak ditemukan atau tidak aktif.'
      USING ERRCODE = 'KC003', HINT = 'Cabut sesi klien dan arahkan ke halaman login.';
  END IF;

  IF v_user.is_active IS DISTINCT FROM TRUE THEN
    RAISE EXCEPTION 'ACCOUNT_DISABLED: Akun pengguna sedang dinonaktifkan.'
      USING ERRCODE = 'KC003', HINT = 'Cabut sesi klien dan arahkan ke halaman login.';
  END IF;

  IF NOT (v_user.role = ANY(p_allowed_roles)) THEN
    RAISE EXCEPTION 'FORBIDDEN: Role % tidak diizinkan menjalankan operasi ini.', v_user.role
      USING ERRCODE = 'KC002', HINT = 'Periksa matriks otorisasi role pada spesifikasi backend.';
  END IF;

  RETURN v_user;
END;
$$;

-- 3. Normalisasi & validasi array avoid_ingredients (MED-18 & Modul E.8)
CREATE OR REPLACE FUNCTION public.fn_normalize_avoid_ingredients(p_raw TEXT[])
RETURNS TEXT[]
LANGUAGE plpgsql
IMMUTABLE
SET search_path = ''
AS $$
DECLARE
  v_result TEXT[] := '{}'::TEXT[];
  v_seen TEXT[] := '{}'::TEXT[];
  v_elem TEXT;
  v_trimmed TEXT;
  v_lower TEXT;
BEGIN
  IF p_raw IS NULL THEN
    RAISE EXCEPTION 'INVALID_INGREDIENTS: Daftar bahan yang dihindari tidak boleh NULL.'
      USING ERRCODE = 'KC011', HINT = 'Kirim array kosong {} bila tidak ada bahan yang dihindari.';
  END IF;

  IF pg_catalog.cardinality(p_raw) IS NULL OR pg_catalog.cardinality(p_raw) = 0 THEN
    RETURN '{}'::TEXT[];
  END IF;

  FOREACH v_elem IN ARRAY p_raw LOOP
    IF v_elem IS NULL THEN
      RAISE EXCEPTION 'INVALID_INGREDIENTS: Elemen bahan yang dihindari tidak boleh NULL.'
        USING ERRCODE = 'KC011', HINT = 'Pastikan setiap elemen avoid_ingredients berupa teks valid.';
    END IF;

    v_trimmed := pg_catalog.btrim(v_elem);
    IF pg_catalog.length(v_trimmed) = 0 THEN
      RAISE EXCEPTION 'INVALID_INGREDIENTS: Elemen bahan yang dihindari tidak boleh kosong.'
        USING ERRCODE = 'KC011', HINT = 'Hapus elemen string kosong sebelum menyimpan.';
    END IF;

    IF v_trimmed ~ '[,\r\n]' THEN
      RAISE EXCEPTION 'INVALID_INGREDIENTS: Elemen bahan tidak boleh mengandung koma atau baris baru.'
        USING ERRCODE = 'KC011', HINT = 'Pisahkan bahan menjadi elemen array tersendiri.';
    END IF;

    IF pg_catalog.length(v_trimmed) > 240 THEN
      RAISE EXCEPTION 'INVALID_INGREDIENTS: Panjang nama bahan melebihi batas maksimum.'
        USING ERRCODE = 'KC011', HINT = 'Setiap bahan maksimal 60 grapheme.';
    END IF;

    v_lower := pg_catalog.lower(v_trimmed);
    IF v_lower = ANY(v_seen) THEN
      RAISE EXCEPTION 'INVALID_INGREDIENTS: Bahan % terduplikasi (case-insensitive).', v_trimmed
        USING ERRCODE = 'KC011', HINT = 'Pastikan daftar avoid_ingredients unik secara case-insensitive.';
    END IF;

    v_seen := pg_catalog.array_append(v_seen, v_lower);
    v_result := pg_catalog.array_append(v_result, v_trimmed);
  END LOOP;

  IF pg_catalog.cardinality(v_result) > 20 THEN
    RAISE EXCEPTION 'INVALID_INGREDIENTS: Jumlah bahan yang dihindari maksimal 20 item.'
      USING ERRCODE = 'KC011', HINT = 'Kurangi daftar bahan yang dihindari hingga maksimal 20 elemen.';
  END IF;

  RETURN v_result;
END;
$$;

-- 4. Format waktu ke ISO-8601 UTC presisi mikrodetik penuh (.US — 6 digit)
--    Terbukti kompatibel dengan RegExp _explicitTimezonePattern & DateTime.tryParse
--    di json_map_utils.dart serta mencegah kehilangan baris pada kursor keyset (HIGH-16).
CREATE OR REPLACE FUNCTION public.fn_utc_iso(p_ts TIMESTAMPTZ)
RETURNS TEXT
LANGUAGE sql
STABLE
STRICT
SET search_path = ''
AS $$
  SELECT pg_catalog.to_char(p_ts AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"');
$$;

-- 5. Overload fn_order_record_json(public.orders) yang menerima record langsung
--    tanpa query ulang ke public.orders (LOW-24 & Modul E.10)
CREATE OR REPLACE FUNCTION public.fn_order_record_json(p_order public.orders)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
STRICT
SET search_path = ''
AS $$
DECLARE
  v_items JSONB;
BEGIN
  SELECT COALESCE(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'menu_id', oi.menu_id,
        'name', oi.name,
        'quantity', oi.quantity,
        'unit_price_idr', oi.unit_price_idr,
        'note', oi.note
      ) ORDER BY oi.position ASC
    ),
    '[]'::JSONB
  ) INTO v_items
  FROM public.order_items oi
  WHERE oi.order_id = p_order.id;

  RETURN pg_catalog.jsonb_build_object(
    'id', p_order.id,
    'order_number', p_order.order_number,
    'customer_id', p_order.customer_id,
    'customer_name', p_order.customer_name,
    'stall_id', p_order.stall_id,
    'stall_name', p_order.stall_name,
    'status', p_order.status::TEXT,
    'payment_status', p_order.payment_status::TEXT,
    'total_price_idr', p_order.total_price_idr,
    'note', p_order.note,
    'rejection_reason', p_order.rejection_reason,
    'created_at', public.fn_utc_iso(p_order.created_at),
    'updated_at', public.fn_utc_iso(p_order.updated_at),
    'version', p_order.version,
    'items', v_items
  );
END;
$$;

-- Overload pendamping berdasarkan ID untuk fungsi baca (tetap mendelegasikan ke overload record)
CREATE OR REPLACE FUNCTION public.fn_order_record_json(p_order_id TEXT)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $$
DECLARE
  v_order public.orders%ROWTYPE;
BEGIN
  IF p_order_id IS NULL OR pg_catalog.btrim(p_order_id) = '' THEN
    RETURN NULL;
  END IF;

  SELECT * INTO v_order
  FROM public.orders o
  WHERE o.id = p_order_id;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  RETURN public.fn_order_record_json(v_order);
END;
$$;

-- 6. Proyeksi JSON pengajuan stan kantin (kompatibel CanteenApplicationModel)
CREATE OR REPLACE FUNCTION public.fn_canteen_application_json(p_app public.canteen_applications)
RETURNS JSONB
LANGUAGE sql
STABLE
STRICT
SET search_path = ''
AS $$
  SELECT pg_catalog.jsonb_build_object(
    'id', p_app.id,
    'applicant_id', p_app.applicant_id,
    'name', p_app.name,
    'description', p_app.description,
    'location', p_app.location,
    'phone', p_app.phone,
    'status', p_app.status::TEXT,
    'reason', p_app.reason,
    'created_at', public.fn_utc_iso(p_app.created_at),
    'version', p_app.version
  );
$$;

-- 7. Proyeksi JSON pengguna (kompatibel UserModel)
CREATE OR REPLACE FUNCTION public.fn_user_json(p_user public.users)
RETURNS JSONB
LANGUAGE sql
IMMUTABLE
STRICT
SET search_path = ''
AS $$
  SELECT pg_catalog.jsonb_build_object(
    'id', p_user.id,
    'username', p_user.username,
    'email', p_user.email,
    'name', p_user.name,
    'role', p_user.role::TEXT,
    'is_active', p_user.is_active,
    'avatar_url', p_user.avatar_url
  );
$$;

-- 8. Proyeksi JSON menu owner (kompatibel OwnerMenu)
CREATE OR REPLACE FUNCTION public.fn_owner_menu_json(p_menu public.menus)
RETURNS JSONB
LANGUAGE sql
IMMUTABLE
STRICT
SET search_path = ''
AS $$
  SELECT pg_catalog.jsonb_build_object(
    'id', p_menu.id,
    'stall_id', p_menu.stall_id,
    'name', p_menu.name,
    'description', p_menu.description,
    'category', p_menu.category::TEXT,
    'price_idr', p_menu.price_idr,
    'is_available', p_menu.is_available,
    'version', p_menu.version,
    'image_url', p_menu.image_url
  );
$$;

-- 9. Proyeksi JSON stan owner (kompatibel OwnerStall)
CREATE OR REPLACE FUNCTION public.fn_owner_stall_json(p_stall public.stalls)
RETURNS JSONB
LANGUAGE sql
IMMUTABLE
STRICT
SET search_path = ''
AS $$
  SELECT pg_catalog.jsonb_build_object(
    'id', p_stall.id,
    'owner_id', p_stall.owner_id,
    'name', p_stall.name,
    'block', p_stall.block,
    'description', p_stall.description,
    'is_open', p_stall.is_open,
    'prep_time_min', p_stall.prep_time_min,
    'version', p_stall.version,
    'image_url', p_stall.image_url
  );
$$;

-- Pastikan seluruh fungsi helper di atas hanya dapat dieksekusi oleh service_role
REVOKE ALL ON FUNCTION public.fn_require_service_role() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_require_actor(TEXT, public.user_role[], BOOLEAN) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_normalize_avoid_ingredients(TEXT[]) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_utc_iso(TIMESTAMPTZ) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_order_record_json(public.orders) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_order_record_json(TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_canteen_application_json(public.canteen_applications) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_user_json(public.users) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_owner_menu_json(public.menus) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_owner_stall_json(public.stalls) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.fn_require_service_role() TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_require_actor(TEXT, public.user_role[], BOOLEAN) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_normalize_avoid_ingredients(TEXT[]) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_utc_iso(TIMESTAMPTZ) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_order_record_json(public.orders) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_order_record_json(TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_canteen_application_json(public.canteen_applications) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_user_json(public.users) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_owner_menu_json(public.menus) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_owner_stall_json(public.stalls) TO service_role;

COMMIT;
