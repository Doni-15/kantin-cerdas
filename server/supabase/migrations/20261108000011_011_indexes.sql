-- ============================================================================
-- MIGRASI 011: INDEKS KEYSET CURSOR, FOREIGN KEY, TRIGRAM, & AUDIT (MODUL H)
-- Proyek   : KantinCerdas (Supabase PostgreSQL 15-17)
-- Perbaikan: HIGH-12, HIGH-15, HIGH-16, LOW-24
--            Setiap indeks mencantumkan query target di komentar dan telah
--            diselaraskan 100% dengan predikat WHERE + ORDER BY fungsi baca.
-- ============================================================================
BEGIN;

-- Hapus indeks lama yang duplikat atau salah struktur bila ada
DROP INDEX IF EXISTS public.idx_order_items_order_pos;
DROP INDEX IF EXISTS public.idx_orders_customer_status_cursor;
DROP INDEX IF EXISTS public.idx_menus_stall_active;
DROP INDEX IF EXISTS public.idx_users_search;
DROP INDEX IF EXISTS public.idx_menus_search;

-- ----------------------------------------------------------------------------
-- 1. INDEKS TABEL public.users
-- ----------------------------------------------------------------------------

-- Target Query: rpc_list_admin_users (paginasi kursor daftar pengguna oleh Admin)
--   SELECT * FROM public.users WHERE (created_at, id) < ($1, $2) ORDER BY created_at DESC, id DESC LIMIT $3;
CREATE INDEX IF NOT EXISTS idx_users_admin_cursor
  ON public.users (created_at DESC, id DESC);

-- Target Query: rpc_list_admin_users dengan filter pencarian substring ILIKE / strpos(lower(...))
--   SELECT * FROM public.users WHERE lower(coalesce(username,'') || ' ' || coalesce(name,'') || ' ' || coalesce(email,'')) LIKE '%kata%';
CREATE INDEX IF NOT EXISTS idx_users_search_trgm
  ON public.users
  USING gin ((pg_catalog.lower(COALESCE(username, '') || ' ' || COALESCE(name, '') || ' ' || COALESCE(email, ''))) extensions.gin_trgm_ops);

-- ----------------------------------------------------------------------------
-- 2. INDEKS TABEL public.stalls
-- ----------------------------------------------------------------------------

-- Target Query: rpc_get_customer_catalog & rpc_get_admin_summary (urutan stan buka lalu waktu buat)
--   SELECT * FROM public.stalls ORDER BY is_open DESC, created_at DESC, id DESC;
CREATE INDEX IF NOT EXISTS idx_stalls_open_cursor
  ON public.stalls (is_open DESC, created_at DESC, id DESC);

-- ----------------------------------------------------------------------------
-- 3. INDEKS TABEL public.menus
-- ----------------------------------------------------------------------------

-- Target Query: Validasi Foreign Key penuh menus.stall_id -> stalls.id (termasuk baris soft-deleted)
--   SELECT 1 FROM public.menus WHERE stall_id = $1;
CREATE INDEX IF NOT EXISTS idx_menus_stall_fk
  ON public.menus (stall_id);

-- Target Query: rpc_list_owner_menus tanpa filter is_available & katalog per stan
--   SELECT * FROM public.menus WHERE stall_id = $1 AND deleted_at IS NULL AND (created_at, id) < ($2, $3) ORDER BY created_at DESC, id DESC;
CREATE INDEX IF NOT EXISTS idx_menus_stall_cursor
  ON public.menus (stall_id, created_at DESC, id DESC)
  WHERE deleted_at IS NULL;

-- Target Query: rpc_list_owner_menus dengan filter is_available = TRUE/FALSE
--   SELECT * FROM public.menus WHERE stall_id = $1 AND is_available = $2 AND deleted_at IS NULL AND (created_at, id) < ($3, $4) ORDER BY created_at DESC, id DESC;
CREATE INDEX IF NOT EXISTS idx_menus_stall_available_cursor
  ON public.menus (stall_id, is_available, created_at DESC, id DESC)
  WHERE deleted_at IS NULL;

-- Target Query: Pencarian substring menu pada rpc_list_owner_menus / katalog
--   SELECT * FROM public.menus WHERE deleted_at IS NULL AND lower(coalesce(name,'') || ' ' || coalesce(description,'')) LIKE '%kata%';
CREATE INDEX IF NOT EXISTS idx_menus_search_trgm
  ON public.menus
  USING gin ((pg_catalog.lower(COALESCE(name, '') || ' ' || COALESCE(description, ''))) extensions.gin_trgm_ops)
  WHERE deleted_at IS NULL;

-- ----------------------------------------------------------------------------
-- 4. INDEKS TABEL public.orders & public.order_items
-- ----------------------------------------------------------------------------

-- Target Query: rpc_list_customer_orders saat p_history = FALSE (pesanan aktif pelanggan)
--   SELECT * FROM public.orders WHERE customer_id = $1 AND status IN ('waiting','processing','ready') AND (created_at, id) < ($2, $3) ORDER BY created_at DESC, id DESC;
CREATE INDEX IF NOT EXISTS idx_orders_customer_active_cursor
  ON public.orders (customer_id, created_at DESC, id DESC)
  WHERE status IN ('waiting', 'processing', 'ready');

-- Target Query: rpc_list_customer_orders untuk riwayat pelanggan & FK customer_id penuh
--   SELECT * FROM public.orders WHERE customer_id = $1 AND (created_at, id) < ($2, $3) ORDER BY created_at DESC, id DESC;
CREATE INDEX IF NOT EXISTS idx_orders_customer_cursor
  ON public.orders (customer_id, created_at DESC, id DESC);

-- Target Query: rpc_list_owner_orders saat p_status IS NULL (tab "Semua Pesanan" Owner & FK stall_id)
--   SELECT * FROM public.orders WHERE stall_id = $1 AND (created_at, id) < ($2, $3) ORDER BY created_at DESC, id DESC;
CREATE INDEX IF NOT EXISTS idx_orders_stall_all_cursor
  ON public.orders (stall_id, created_at DESC, id DESC);

-- Target Query: rpc_list_owner_orders dengan filter p_status spesifik
--   SELECT * FROM public.orders WHERE stall_id = $1 AND status = $2 AND (created_at, id) < ($3, $4) ORDER BY created_at DESC, id DESC;
CREATE INDEX IF NOT EXISTS idx_orders_stall_status_cursor
  ON public.orders (stall_id, status, created_at DESC, id DESC);

-- Target Query: rpc_get_admin_summary untuk menghitung activeOrders secara global
--   SELECT count(*) FROM public.orders WHERE status IN ('waiting','processing','ready');
CREATE INDEX IF NOT EXISTS idx_orders_active_global
  ON public.orders (created_at DESC)
  WHERE status IN ('waiting', 'processing', 'ready');

-- Target Query: Validasi Foreign Key order_items.menu_id -> menus.id (HIGH-15 & HIGH-16)
--   Catatan LOW-24: Indeks (order_id, position) sudah disediakan otomatis oleh UNIQUE constraint uq_order_items_position.
CREATE INDEX IF NOT EXISTS idx_order_items_menu_fk
  ON public.order_items (menu_id);

-- ----------------------------------------------------------------------------
-- 5. INDEKS TABEL public.canteen_applications
-- ----------------------------------------------------------------------------

-- Target Query: Invarian 1 pengajuan latest per pemohon & rpc_get_my_canteen_application
--   SELECT * FROM public.canteen_applications WHERE applicant_id = $1 AND is_latest = TRUE;
CREATE UNIQUE INDEX IF NOT EXISTS idx_canteen_applications_latest_per_applicant
  ON public.canteen_applications (applicant_id)
  WHERE is_latest = TRUE;

-- Target Query: Invarian maksimal 1 pengajuan aktif ('submitted','reviewing') per pemohon (HIGH-15)
--   SELECT * FROM public.canteen_applications WHERE applicant_id = $1 AND status IN ('submitted','reviewing');
CREATE UNIQUE INDEX IF NOT EXISTS idx_canteen_applications_one_active
  ON public.canteen_applications (applicant_id)
  WHERE status IN ('submitted', 'reviewing');

-- Target Query: rpc_list_admin_applications tanpa filter status (p_status IS NULL)
--   SELECT * FROM public.canteen_applications WHERE (created_at, id) < ($1, $2) ORDER BY created_at DESC, id DESC;
CREATE INDEX IF NOT EXISTS idx_canteen_applications_all_cursor
  ON public.canteen_applications (created_at DESC, id DESC);

-- Target Query: rpc_list_admin_applications dengan filter status & rpc_get_admin_summary (pendingApplications)
--   SELECT * FROM public.canteen_applications WHERE status = $1 AND (created_at, id) < ($2, $3) ORDER BY created_at DESC, id DESC;
CREATE INDEX IF NOT EXISTS idx_canteen_applications_status_cursor
  ON public.canteen_applications (status, created_at DESC, id DESC);

-- Target Query: Validasi Foreign Key penuh applicant_id -> users.id & riwayat pengajuan pemohon
--   SELECT * FROM public.canteen_applications WHERE applicant_id = $1;
CREATE INDEX IF NOT EXISTS idx_canteen_applications_applicant_fk
  ON public.canteen_applications (applicant_id);

-- Target Query: Validasi Foreign Key reviewed_by -> users.id & audit peninjau
--   SELECT * FROM public.canteen_applications WHERE reviewed_by = $1;
CREATE INDEX IF NOT EXISTS idx_canteen_applications_reviewed_by_fk
  ON public.canteen_applications (reviewed_by)
  WHERE reviewed_by IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 6. INDEKS TABEL public.mutation_receipts, public.audit_events, & public.media_assets
-- ----------------------------------------------------------------------------

-- Target Query: Riwayat mutasi per aktor & pemangkasan PII
--   SELECT * FROM public.mutation_receipts WHERE actor_id = $1 ORDER BY created_at DESC;
CREATE INDEX IF NOT EXISTS idx_mutation_receipts_actor
  ON public.mutation_receipts (actor_id, created_at DESC);

-- Target Query: Job pemangkasan PII pada receipt tersegel berdasarkan completed_at
--   SELECT * FROM public.mutation_receipts WHERE sealed = TRUE AND completed_at < $1;
CREATE INDEX IF NOT EXISTS idx_mutation_receipts_compaction
  ON public.mutation_receipts (completed_at)
  WHERE sealed = TRUE AND completed_at IS NOT NULL;

-- Target Query: Penelusuran jejak audit berdasarkan target entitas
--   SELECT * FROM public.audit_events WHERE target_id = $1 ORDER BY occurred_at DESC;
CREATE INDEX IF NOT EXISTS idx_audit_events_target
  ON public.audit_events (target_id, occurred_at DESC);

-- Target Query: Penelusuran jejak audit berdasarkan pelaku (Modul G)
--   SELECT * FROM public.audit_events WHERE actor_id = $1 ORDER BY occurred_at DESC;
CREATE INDEX IF NOT EXISTS idx_audit_events_actor
  ON public.audit_events (actor_id, occurred_at DESC);

-- Target Query: Korelasi audit_events dengan Idempotency-Key / request_id (Modul G)
--   SELECT * FROM public.audit_events WHERE request_id = $1;
CREATE INDEX IF NOT EXISTS idx_audit_events_request_id
  ON public.audit_events (request_id);

-- Target Query: Penegakan kuota media per pengguna & pencarian berdasarkan URL publik
--   SELECT count(*) FROM public.media_assets WHERE owner_id = $1;
CREATE INDEX IF NOT EXISTS idx_media_assets_owner
  ON public.media_assets (owner_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_media_assets_public_url
  ON public.media_assets (public_url);

COMMIT;
