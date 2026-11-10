-- Active: 1794135430745@@aws-0-ap-southeast-1.pooler.supabase.com@5432@postgres@public
-- ============================================================================
-- MIGRASI 012: UPGRADE TRANSAKSIONAL DARI SKEMA LAMA (supabase_schema_complete.sql)
-- Proyek   : KantinCerdas (Supabase PostgreSQL 15-17)
-- Catatan  : Bila migrasi 001..011 dijalankan pada database kosong, blok ALTER
--            di bawah ini bersifat idempoten penuh (memeriksa katalog pg_attribute /
--            pg_constraint sebelum menerapkan perubahan struktur). Bila dijalankan
--            di atas skema lama, migrasi ini meng-upgrade tipe kolom, constraint,
--            kolom baru, dan sequence secara eksplisit tanpa kehilangan data (Modul A).
-- ============================================================================
BEGIN;

-- 1. Pastikan kolom baru pada tabel yang mungkin sudah dibuat oleh skema lama tersedia
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS session_epoch INTEGER NOT NULL DEFAULT 1;

ALTER TABLE public.food_preferences
  ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT pg_catalog.timezone('utc', pg_catalog.now());

-- 2. Upgrade tipe orders.total_price_idr dari INTEGER ke BIGINT bila masih bertipe int4 (HIGH-13)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_catalog.pg_attribute a
    JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    JOIN pg_catalog.pg_type t ON t.oid = a.atttypid
    WHERE n.nspname = 'public'
      AND c.relname = 'orders'
      AND a.attname = 'total_price_idr'
      AND t.typname = 'int4'
  ) THEN
    ALTER TABLE public.orders
      ALTER COLUMN total_price_idr TYPE BIGINT USING total_price_idr::BIGINT;
  END IF;
END
$$;

-- 3. Ubah mutation_receipts.completed_at menjadi nullable bila sebelumnya NOT NULL (MED-20)
ALTER TABLE public.mutation_receipts
  ALTER COLUMN completed_at DROP NOT NULL,
  ALTER COLUMN completed_at DROP DEFAULT;

UPDATE public.mutation_receipts
SET completed_at = NULL
WHERE outcome = 'pending' AND completed_at IS NOT NULL;

UPDATE public.mutation_receipts
SET payload_hash = public.fn_compute_payload_hash(request_snapshot)
WHERE payload_hash IS NULL;

ALTER TABLE public.mutation_receipts
  ALTER COLUMN payload_hash SET NOT NULL;

-- 4. Upgrade DEFAULT kolom id pada kelima tabel entitas ke fn_gen_entity_id 128-bit (CRIT-01 & MED-17)
ALTER TABLE public.users
  ALTER COLUMN id SET DEFAULT public.fn_gen_entity_id('usr');
ALTER TABLE public.stalls
  ALTER COLUMN id SET DEFAULT public.fn_gen_entity_id('stl');
ALTER TABLE public.menus
  ALTER COLUMN id SET DEFAULT public.fn_gen_entity_id('mnu');
ALTER TABLE public.orders
  ALTER COLUMN id SET DEFAULT public.fn_gen_entity_id('ord'),
  ALTER COLUMN order_number DROP DEFAULT;
ALTER TABLE public.canteen_applications
  ALTER COLUMN id SET DEFAULT public.fn_gen_entity_id('app');

-- 5. Perbaiki Foreign Key users.auth_uid -> ON DELETE RESTRICT dan order_items.menu_id -> ON DELETE RESTRICT (HIGH-15)
ALTER TABLE public.users
  DROP CONSTRAINT IF EXISTS users_auth_uid_fkey,
  ADD CONSTRAINT users_auth_uid_fkey FOREIGN KEY (auth_uid) REFERENCES auth.users(id) ON DELETE RESTRICT;

ALTER TABLE public.food_preferences
  DROP CONSTRAINT IF EXISTS food_preferences_customer_id_fkey,
  ADD CONSTRAINT food_preferences_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.users(id) ON DELETE RESTRICT;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_constraint con
    JOIN pg_catalog.pg_class rel ON rel.oid = con.conrelid
    JOIN pg_catalog.pg_namespace nsp ON nsp.oid = rel.relnamespace
    WHERE nsp.nspname = 'public'
      AND rel.relname = 'order_items'
      AND con.conname IN ('order_items_menu_id_fkey', 'fk_order_items_menu')
  ) THEN
    ALTER TABLE public.order_items
      ADD CONSTRAINT order_items_menu_id_fkey FOREIGN KEY (menu_id) REFERENCES public.menus(id) ON DELETE RESTRICT;
  END IF;
END
$$;

-- 6. Ganti constraint lama yang cacat pada order_items dan canteen_applications (CRIT-05)
ALTER TABLE public.order_items
  DROP CONSTRAINT IF EXISTS chk_order_items_note_length,
  ADD CONSTRAINT chk_order_items_note_length CHECK (
    note = pg_catalog.btrim(note) AND pg_catalog.length(note) <= 1200
  );

ALTER TABLE public.canteen_applications
  DROP CONSTRAINT IF EXISTS chk_applications_fields,
  ADD CONSTRAINT chk_applications_fields CHECK (
    name = pg_catalog.btrim(name) AND pg_catalog.length(name) BETWEEN 1 AND 480 AND
    description = pg_catalog.btrim(description) AND pg_catalog.length(description) BETWEEN 1 AND 4000 AND
    location = pg_catalog.btrim(location) AND pg_catalog.length(location) BETWEEN 1 AND 480 AND
    phone = pg_catalog.btrim(phone) AND pg_catalog.length(phone) <= 24 AND
    phone ~ '^\+?[0-9 ()-]+$' AND
    pg_catalog.length(pg_catalog.regexp_replace(phone, '[^0-9]', '', 'g')) BETWEEN 8 AND 15
  );

-- 7. Hapus fungsi overload lama rpc_create_customer_order(..., INTEGER, ...) bila masih ada dari skema lama
DROP FUNCTION IF EXISTS public.rpc_create_customer_order(TEXT, TEXT, TEXT, JSONB, INTEGER, TEXT);

COMMIT;
