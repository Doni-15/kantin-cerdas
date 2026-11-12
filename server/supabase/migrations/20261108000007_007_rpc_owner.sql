-- Active: 1794135430745@@aws-0-ap-southeast-1.pooler.supabase.com@5432@postgres@public
-- ============================================================================
-- MIGRASI 007: RPC MUTASI PEMILIK STAN (OWNER)
-- Proyek   : KantinCerdas (Supabase PostgreSQL 15-17)
-- Perbaikan: CRIT-02, CRIT-03, CRIT-05, HIGH-08, HIGH-10, HIGH-12, HIGH-14,
--            MED-18, MED-19, LOW-24
-- ============================================================================
BEGIN;

-- ----------------------------------------------------------------------------
-- 1. RPC 5: PUT /v1/owner/stall (rpc_owner_save_stall)
--    Urutan Lock: advisory(receipt) -> users(owner) -> stalls
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_owner_save_stall(
  p_actor_id TEXT,
  p_mutation_id TEXT,
  p_stall_id TEXT,
  p_name TEXT,
  p_block TEXT,
  p_description TEXT,
  p_is_open BOOLEAN,
  p_prep_time_min INTEGER,
  p_expected_version INTEGER,
  p_image_url TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $$
DECLARE
  v_clean_name TEXT;
  v_clean_block TEXT;
  v_clean_desc TEXT;
  v_clean_image_url TEXT;
  v_stall public.stalls%ROWTYPE;
  v_req_snapshot JSONB;
  v_decision JSONB;
  v_response JSONB;
  v_lookup JSONB;
BEGIN
  IF p_actor_id IS NULL OR pg_catalog.btrim(p_actor_id) = '' THEN
    RAISE EXCEPTION 'UNAUTHENTICATED: Identitas pemilik stan wajib diisi.'
      USING ERRCODE = 'KC001', HINT = 'Pastikan sesi pengguna terautentikasi.';
  END IF;

  IF p_mutation_id IS NULL OR p_mutation_id !~ '^[a-f0-9]{48}$' THEN
    RAISE EXCEPTION 'INVALID_INPUT: mutation_id wajib berupa 48 karakter hex huruf kecil.'
      USING ERRCODE = 'KC004', HINT = 'Gunakan Idempotency-Key 48 hex yang valid.';
  END IF;

  IF p_stall_id IS NULL OR pg_catalog.btrim(p_stall_id) = '' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Identitas stan (p_stall_id) wajib diisi.'
      USING ERRCODE = 'KC004', HINT = 'Berikan stall_id milik owner.';
  END IF;

  IF p_name IS NULL OR p_block IS NULL OR p_is_open IS NULL OR p_prep_time_min IS NULL THEN
    RAISE EXCEPTION 'INVALID_INPUT: Nama, blok, status buka, dan waktu persiapan stan wajib diisi.'
      USING ERRCODE = 'KC004', HINT = 'Lengkapi seluruh parameter wajib stan.';
  END IF;

  IF p_expected_version IS NULL OR p_expected_version < 1 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_expected_version wajib berupa bilangan bulat >= 1.'
      USING ERRCODE = 'KC004', HINT = 'Sertakan expected_version stan untuk pemeriksaan CAS.';
  END IF;

  v_clean_name := pg_catalog.btrim(p_name);
  v_clean_block := pg_catalog.btrim(p_block);
  v_clean_desc := pg_catalog.btrim(COALESCE(p_description, ''));
  v_clean_image_url := NULLIF(pg_catalog.btrim(COALESCE(p_image_url, '')), '');

  IF pg_catalog.length(v_clean_name) < 1 OR pg_catalog.length(v_clean_name) > 480 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Nama stan wajib antara 1 dan 120 karakter.'
      USING ERRCODE = 'KC004', HINT = 'Periksa kembali nama stan.';
  END IF;

  IF pg_catalog.length(v_clean_block) < 1 OR pg_catalog.length(v_clean_block) > 480 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Lokasi/blok stan wajib antara 1 dan 120 karakter.'
      USING ERRCODE = 'KC004', HINT = 'Periksa kembali blok stan.';
  END IF;

  IF pg_catalog.length(v_clean_desc) > 4000 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Deskripsi stan maksimal 1000 karakter.'
      USING ERRCODE = 'KC004', HINT = 'Pangkas deskripsi stan hingga maksimal 1000 grapheme.';
  END IF;

  IF p_prep_time_min < 1 OR p_prep_time_min > 180 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Waktu persiapan (p_prep_time_min) wajib antara 1 dan 180 menit.'
      USING ERRCODE = 'KC004', HINT = 'Masukkan estimasi waktu persiapan 1-180 menit.';
  END IF;

  IF NOT public.fn_is_safe_image_url(v_clean_image_url) THEN
    RAISE EXCEPTION 'INVALID_IMAGE_URL: URL gambar stan tidak valid atau bukan berasal dari bucket resmi kantin-media.'
      USING ERRCODE = 'KC010', HINT = 'Unggah foto stan melalui POST /v1/media/images.';
  END IF;

  v_req_snapshot := public.fn_canonical_owner_snapshot(
    p_actor_id,
    p_mutation_id,
    p_stall_id,
    'save_stall',
    p_stall_id,
    p_expected_version,
    pg_catalog.jsonb_build_object(
      'name', v_clean_name,
      'block', v_clean_block,
      'description', v_clean_desc,
      'is_open', p_is_open,
      'prep_time_min', p_prep_time_min,
      'image_url', v_clean_image_url
    )
  );

  v_decision := public.fn_begin_mutation('owner-mutations', p_mutation_id, p_actor_id, v_req_snapshot);
  IF (v_decision->>'action') IS NOT DISTINCT FROM 'REPLAY' THEN
    RETURN v_decision->'response';
  END IF;

  -- Wajib periksa owner aktif & role = 'owner' di dalam transaksi tulis (HIGH-08)
  PERFORM public.fn_require_actor(
    p_actor_id,
    ARRAY['owner']::public.user_role[],
    FALSE
  );

  SELECT * INTO v_stall
  FROM public.stalls s
  WHERE s.id = p_stall_id
  FOR NO KEY UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_STALL: Stan tidak ditemukan.'
      USING ERRCODE = 'KC016', HINT = 'Pastikan akun owner telah memiliki stan yang disetujui.';
  END IF;

  IF v_stall.owner_id IS DISTINCT FROM p_actor_id THEN
    RAISE EXCEPTION 'FORBIDDEN: Anda bukan pemilik stan ini.'
      USING ERRCODE = 'KC002', HINT = 'Owner hanya dapat mengelola stan miliknya sendiri.';
  END IF;

  IF v_stall.version IS DISTINCT FROM p_expected_version THEN
    RAISE EXCEPTION 'VERSION_CONFLICT: Versi stan telah berubah.'
      USING ERRCODE = 'KC017', HINT = 'Muat ulang data stan sebelum menyimpan perubahan.';
  END IF;

  UPDATE public.stalls
  SET name = v_clean_name,
      block = v_clean_block,
      description = v_clean_desc,
      is_open = p_is_open,
      prep_time_min = p_prep_time_min,
      image_url = v_clean_image_url,
      version = version + 1,
      updated_at = pg_catalog.timezone('utc', pg_catalog.now())
  WHERE id = p_stall_id
  RETURNING * INTO v_stall;

  IF v_clean_image_url IS NOT NULL THEN
    UPDATE public.media_assets
    SET is_referenced = TRUE,
        updated_at = pg_catalog.timezone('utc', pg_catalog.now())
    WHERE owner_id = p_actor_id AND public_url = v_clean_image_url;
  END IF;

  v_response := public.fn_owner_stall_json(v_stall);

  v_lookup := pg_catalog.jsonb_build_object(
    'owner_id', p_actor_id,
    'mutation_id', p_mutation_id,
    'stall_id', v_stall.id,
    'kind', 'save_stall',
    'target_id', v_stall.id,
    'expected_version', p_expected_version,
    'outcome', 'applied',
    'result_id', v_stall.id,
    'result_version', v_stall.version
  );

  PERFORM public.fn_finish_mutation(
    'owner-mutations', p_mutation_id, p_actor_id, v_req_snapshot, v_response, v_lookup
  );

  INSERT INTO public.audit_events (
    actor_id, operation, target_id, request_id, before_version, after_version, reason, outcome
  ) VALUES (
    p_actor_id, 'owner_save_stall', v_stall.id, p_mutation_id,
    p_expected_version, v_stall.version, NULL, 'applied'
  );

  RETURN v_response;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2. RPC 6: POST /v1/owner/menus & PUT /v1/owner/menus/{id} (rpc_owner_save_menu)
--    Urutan Lock: advisory(receipt) -> users(owner) -> stalls(FOR SHARE) -> menus(FOR NO KEY UPDATE)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_owner_save_menu(
  p_actor_id TEXT,
  p_mutation_id TEXT,
  p_stall_id TEXT,
  p_menu_id TEXT,
  p_name TEXT,
  p_description TEXT,
  p_category public.menu_category,
  p_price_idr INTEGER,
  p_is_available BOOLEAN,
  p_expected_version INTEGER DEFAULT NULL,
  p_image_url TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $$
DECLARE
  v_clean_menu_id TEXT;
  v_clean_name TEXT;
  v_clean_desc TEXT;
  v_clean_image_url TEXT;
  v_stall public.stalls%ROWTYPE;
  v_menu public.menus%ROWTYPE;
  v_req_snapshot JSONB;
  v_decision JSONB;
  v_response JSONB;
  v_lookup JSONB;
BEGIN
  IF p_actor_id IS NULL OR pg_catalog.btrim(p_actor_id) = '' THEN
    RAISE EXCEPTION 'UNAUTHENTICATED: Identitas pemilik stan wajib diisi.'
      USING ERRCODE = 'KC001', HINT = 'Pastikan sesi pengguna terautentikasi.';
  END IF;

  IF p_mutation_id IS NULL OR p_mutation_id !~ '^[a-f0-9]{48}$' THEN
    RAISE EXCEPTION 'INVALID_INPUT: mutation_id wajib berupa 48 karakter hex huruf kecil.'
      USING ERRCODE = 'KC004', HINT = 'Gunakan Idempotency-Key 48 hex yang valid.';
  END IF;

  IF p_stall_id IS NULL OR pg_catalog.btrim(p_stall_id) = '' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Identitas stan (p_stall_id) wajib diisi.'
      USING ERRCODE = 'KC004', HINT = 'Berikan stall_id tempat menu berada.';
  END IF;

  IF p_name IS NULL OR p_category IS NULL OR p_price_idr IS NULL OR p_is_available IS NULL THEN
    RAISE EXCEPTION 'INVALID_INPUT: Nama, kategori, harga, dan status ketersediaan menu wajib diisi.'
      USING ERRCODE = 'KC004', HINT = 'Lengkapi seluruh parameter wajib menu.';
  END IF;

  v_clean_menu_id := NULLIF(pg_catalog.btrim(COALESCE(p_menu_id, '')), '');
  v_clean_name := pg_catalog.btrim(p_name);
  v_clean_desc := pg_catalog.btrim(COALESCE(p_description, ''));
  v_clean_image_url := NULLIF(pg_catalog.btrim(COALESCE(p_image_url, '')), '');

  IF (v_clean_menu_id IS NULL) IS DISTINCT FROM (p_expected_version IS NULL) THEN
    RAISE EXCEPTION 'INVALID_INPUT: Pembuatan menu baru wajib tanpa expected_version, sedangkan pembaruan wajib menyertakan menu_id dan expected_version.'
      USING ERRCODE = 'KC004', HINT = 'Periksa kesesuaian pasangan menu_id dan expected_version.';
  END IF;

  IF p_expected_version IS NOT NULL AND p_expected_version < 1 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_expected_version wajib >= 1.'
      USING ERRCODE = 'KC004', HINT = 'Gunakan versi positif pada pembaruan menu.';
  END IF;

  IF pg_catalog.length(v_clean_name) < 1 OR pg_catalog.length(v_clean_name) > 480 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Nama menu wajib antara 1 dan 120 karakter.'
      USING ERRCODE = 'KC004', HINT = 'Periksa panjang nama menu.';
  END IF;

  IF pg_catalog.length(v_clean_desc) > 4000 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Deskripsi menu maksimal 1000 karakter.'
      USING ERRCODE = 'KC004', HINT = 'Pangkas deskripsi menu hingga maksimal 1000 grapheme.';
  END IF;

  IF p_price_idr < 1 OR p_price_idr > 10000000 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Harga menu (p_price_idr) wajib antara Rp 1 dan Rp 10.000.000.'
      USING ERRCODE = 'KC004', HINT = 'Masukkan harga menu dalam rentang 1..10000000.';
  END IF;

  IF NOT public.fn_is_safe_image_url(v_clean_image_url) THEN
    RAISE EXCEPTION 'INVALID_IMAGE_URL: URL gambar menu tidak valid atau bukan berasal dari bucket resmi kantin-media.'
      USING ERRCODE = 'KC010', HINT = 'Unggah foto menu melalui POST /v1/media/images.';
  END IF;

  v_req_snapshot := public.fn_canonical_owner_snapshot(
    p_actor_id,
    p_mutation_id,
    p_stall_id,
    'save_menu',
    v_clean_menu_id,
    p_expected_version,
    pg_catalog.jsonb_build_object(
      'name', v_clean_name,
      'description', v_clean_desc,
      'category', p_category::TEXT,
      'price_idr', p_price_idr,
      'is_available', p_is_available,
      'image_url', v_clean_image_url
    )
  );

  v_decision := public.fn_begin_mutation('owner-mutations', p_mutation_id, p_actor_id, v_req_snapshot);
  IF (v_decision->>'action') IS NOT DISTINCT FROM 'REPLAY' THEN
    RETURN v_decision->'response';
  END IF;

  PERFORM public.fn_require_actor(
    p_actor_id,
    ARRAY['owner']::public.user_role[],
    FALSE
  );

  -- Kunci stalls terlebih dahulu, lalu menus (konsisten dengan rpc_owner_delete_menu — Modul F)
  SELECT * INTO v_stall
  FROM public.stalls s
  WHERE s.id = p_stall_id
  FOR SHARE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_STALL: Stan tidak ditemukan.'
      USING ERRCODE = 'KC016', HINT = 'Pastikan stan owner terdaftar.';
  END IF;

  IF v_stall.owner_id IS DISTINCT FROM p_actor_id THEN
    RAISE EXCEPTION 'FORBIDDEN: Anda bukan pemilik stan ini.'
      USING ERRCODE = 'KC002', HINT = 'Owner hanya dapat mengelola menu pada stan miliknya.';
  END IF;

  IF v_clean_menu_id IS NULL THEN
    INSERT INTO public.menus (
      stall_id, name, description, category, price_idr, is_available, image_url, version
    ) VALUES (
      p_stall_id, v_clean_name, v_clean_desc, p_category, p_price_idr, p_is_available, v_clean_image_url, 1
    )
    RETURNING * INTO v_menu;
  ELSE
    SELECT * INTO v_menu
    FROM public.menus m
    WHERE m.id = v_clean_menu_id AND m.stall_id = p_stall_id
    FOR NO KEY UPDATE;

    -- Menu target tidak ditemukan atau sudah soft-deleted -> VERSION_CONFLICT (CRIT-05 & Modul E.11)
    IF NOT FOUND OR v_menu.deleted_at IS NOT NULL THEN
      RAISE EXCEPTION 'VERSION_CONFLICT: Menu tidak ditemukan atau sudah dihapus.'
        USING ERRCODE = 'KC017', HINT = 'Muat ulang daftar menu stan Anda.';
    END IF;

    IF v_menu.version IS DISTINCT FROM p_expected_version THEN
      RAISE EXCEPTION 'VERSION_CONFLICT: Versi menu telah berubah.'
        USING ERRCODE = 'KC017', HINT = 'Muat ulang menu untuk mendapatkan versi terbaru.';
    END IF;

    UPDATE public.menus
    SET name = v_clean_name,
        description = v_clean_desc,
        category = p_category,
        price_idr = p_price_idr,
        is_available = p_is_available,
        image_url = v_clean_image_url,
        version = version + 1,
        updated_at = pg_catalog.timezone('utc', pg_catalog.now())
    WHERE id = v_clean_menu_id
    RETURNING * INTO v_menu;
  END IF;

  IF v_clean_image_url IS NOT NULL THEN
    UPDATE public.media_assets
    SET is_referenced = TRUE,
        updated_at = pg_catalog.timezone('utc', pg_catalog.now())
    WHERE owner_id = p_actor_id AND public_url = v_clean_image_url;
  END IF;

  v_response := public.fn_owner_menu_json(v_menu);

  v_lookup := pg_catalog.jsonb_build_object(
    'owner_id', p_actor_id,
    'mutation_id', p_mutation_id,
    'stall_id', v_menu.stall_id,
    'kind', 'save_menu',
    'target_id', v_clean_menu_id,
    'expected_version', p_expected_version,
    'outcome', 'applied',
    'result_id', v_menu.id,
    'result_version', v_menu.version
  );

  PERFORM public.fn_finish_mutation(
    'owner-mutations', p_mutation_id, p_actor_id, v_req_snapshot, v_response, v_lookup
  );

  INSERT INTO public.audit_events (
    actor_id, operation, target_id, request_id, before_version, after_version, reason, outcome
  ) VALUES (
    p_actor_id,
    CASE WHEN v_clean_menu_id IS NULL THEN 'owner_create_menu' ELSE 'owner_update_menu' END,
    v_menu.id,
    p_mutation_id,
    p_expected_version,
    v_menu.version,
    NULL,
    'applied'
  );

  RETURN v_response;
END;
$$;

-- ----------------------------------------------------------------------------
-- 3. RPC 7: DELETE /v1/owner/menus/{id} (rpc_owner_delete_menu)
--    Urutan Lock: advisory(receipt) -> users(owner) -> stalls(FOR SHARE) -> menus(FOR NO KEY UPDATE)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_owner_delete_menu(
  p_actor_id TEXT,
  p_mutation_id TEXT,
  p_menu_id TEXT,
  p_expected_version INTEGER
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $$
DECLARE
  v_stall public.stalls%ROWTYPE;
  v_menu public.menus%ROWTYPE;
  v_req_snapshot JSONB;
  v_decision JSONB;
  v_response JSONB;
  v_lookup JSONB;
BEGIN
  IF p_actor_id IS NULL OR pg_catalog.btrim(p_actor_id) = '' THEN
    RAISE EXCEPTION 'UNAUTHENTICATED: Identitas pemilik stan wajib diisi.'
      USING ERRCODE = 'KC001', HINT = 'Pastikan sesi pengguna terautentikasi.';
  END IF;

  IF p_mutation_id IS NULL OR p_mutation_id !~ '^[a-f0-9]{48}$' THEN
    RAISE EXCEPTION 'INVALID_INPUT: mutation_id wajib berupa 48 karakter hex huruf kecil.'
      USING ERRCODE = 'KC004', HINT = 'Gunakan Idempotency-Key 48 hex yang valid.';
  END IF;

  IF p_menu_id IS NULL OR pg_catalog.btrim(p_menu_id) = '' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Identitas menu (p_menu_id) wajib diisi.'
      USING ERRCODE = 'KC004', HINT = 'Berikan menu_id yang akan dihapus.';
  END IF;

  IF p_expected_version IS NULL OR p_expected_version < 1 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_expected_version wajib >= 1.'
      USING ERRCODE = 'KC004', HINT = 'Sertakan expected_version menu untuk pemeriksaan CAS.';
  END IF;

  -- Kunci users terlebih dahulu
  PERFORM public.fn_require_actor(
    p_actor_id,
    ARRAY['owner']::public.user_role[],
    FALSE
  );

  -- Ambil stan milik owner dan kunci dengan FOR SHARE SEBELUM mengunci menus (Modul F & HIGH-14)
  SELECT * INTO v_stall
  FROM public.stalls s
  WHERE s.owner_id = p_actor_id
  FOR SHARE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_STALL: Stan milik owner tidak ditemukan.'
      USING ERRCODE = 'KC016', HINT = 'Pastikan akun owner memiliki stan aktif.';
  END IF;

  -- Sertakan stall_id secara konsisten di dalam v_req_snapshot (CRIT-03 & Modul D.6)
  v_req_snapshot := public.fn_canonical_owner_snapshot(
    p_actor_id,
    p_mutation_id,
    v_stall.id,
    'delete_menu',
    p_menu_id,
    p_expected_version,
    '{}'::JSONB
  );

  v_decision := public.fn_begin_mutation('owner-mutations', p_mutation_id, p_actor_id, v_req_snapshot);
  IF (v_decision->>'action') IS NOT DISTINCT FROM 'REPLAY' THEN
    RETURN v_decision->'response';
  END IF;

  SELECT * INTO v_menu
  FROM public.menus m
  WHERE m.id = p_menu_id
  FOR NO KEY UPDATE;

  IF NOT FOUND OR v_menu.deleted_at IS NOT NULL THEN
    RAISE EXCEPTION 'VERSION_CONFLICT: Menu tidak ditemukan atau sudah dihapus.'
      USING ERRCODE = 'KC017', HINT = 'Muat ulang daftar menu stan Anda.';
  END IF;

  IF v_menu.stall_id IS DISTINCT FROM v_stall.id THEN
    RAISE EXCEPTION 'FORBIDDEN: Anda bukan pemilik menu ini.'
      USING ERRCODE = 'KC002', HINT = 'Owner hanya dapat menghapus menu dari stan miliknya.';
  END IF;

  IF v_menu.version IS DISTINCT FROM p_expected_version THEN
    RAISE EXCEPTION 'VERSION_CONFLICT: Versi menu telah berubah.'
      USING ERRCODE = 'KC017', HINT = 'Muat ulang daftar menu sebelum menghapus.';
  END IF;

  UPDATE public.menus
  SET deleted_at = pg_catalog.timezone('utc', pg_catalog.now()),
      is_available = FALSE,
      version = version + 1,
      updated_at = pg_catalog.timezone('utc', pg_catalog.now())
  WHERE id = p_menu_id
  RETURNING * INTO v_menu;

  v_response := pg_catalog.jsonb_build_object(
    'status', 'ok',
    'id', v_menu.id,
    'version', v_menu.version
  );

  v_lookup := pg_catalog.jsonb_build_object(
    'owner_id', p_actor_id,
    'mutation_id', p_mutation_id,
    'stall_id', v_stall.id,
    'kind', 'delete_menu',
    'target_id', v_menu.id,
    'expected_version', p_expected_version,
    'outcome', 'applied',
    'result_id', v_menu.id,
    'result_version', v_menu.version
  );

  PERFORM public.fn_finish_mutation(
    'owner-mutations', p_mutation_id, p_actor_id, v_req_snapshot, v_response, v_lookup
  );

  INSERT INTO public.audit_events (
    actor_id, operation, target_id, request_id, before_version, after_version, reason, outcome
  ) VALUES (
    p_actor_id, 'owner_delete_menu', v_menu.id, p_mutation_id,
    p_expected_version, v_menu.version, NULL, 'applied'
  );

  RETURN v_response;
END;
$$;

-- ----------------------------------------------------------------------------
-- 4. RPC 8: POST /v1/owner/orders/{orderId}/transition (rpc_owner_transition_order)
--    Urutan Lock: advisory(receipt) -> users(owner) -> stalls(FOR SHARE) -> orders(FOR NO KEY UPDATE)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_owner_transition_order(
  p_actor_id TEXT,
  p_mutation_id TEXT,
  p_order_id TEXT,
  p_target_status public.order_status,
  p_expected_version INTEGER,
  p_reason TEXT DEFAULT '',
  p_cash_received BOOLEAN DEFAULT FALSE,
  p_food_handed_over BOOLEAN DEFAULT FALSE
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $$
DECLARE
  v_clean_reason TEXT;
  v_cash BOOLEAN;
  v_food BOOLEAN;
  v_stall public.stalls%ROWTYPE;
  v_order public.orders%ROWTYPE;
  v_new_payment public.order_payment_status;
  v_req_snapshot JSONB;
  v_decision JSONB;
  v_response JSONB;
  v_lookup JSONB;
BEGIN
  IF p_actor_id IS NULL OR pg_catalog.btrim(p_actor_id) = '' THEN
    RAISE EXCEPTION 'UNAUTHENTICATED: Identitas pemilik stan wajib diisi.'
      USING ERRCODE = 'KC001', HINT = 'Pastikan sesi pengguna terautentikasi.';
  END IF;

  IF p_mutation_id IS NULL OR p_mutation_id !~ '^[a-f0-9]{48}$' THEN
    RAISE EXCEPTION 'INVALID_INPUT: mutation_id wajib berupa 48 karakter hex huruf kecil.'
      USING ERRCODE = 'KC004', HINT = 'Gunakan Idempotency-Key 48 hex yang valid.';
  END IF;

  IF p_order_id IS NULL OR pg_catalog.btrim(p_order_id) = '' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Identitas pesanan (p_order_id) wajib diisi.'
      USING ERRCODE = 'KC004', HINT = 'Berikan order_id yang akan diproses.';
  END IF;

  IF p_target_status IS NULL THEN
    RAISE EXCEPTION 'INVALID_INPUT: Status tujuan (p_target_status) wajib diisi.'
      USING ERRCODE = 'KC004', HINT = 'Berikan status tujuan transisi pesanan.';
  END IF;

  IF p_expected_version IS NULL OR p_expected_version < 1 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_expected_version wajib >= 1.'
      USING ERRCODE = 'KC004', HINT = 'Sertakan expected_version pesanan untuk pemeriksaan CAS.';
  END IF;

  -- Tolak NULL pada boolean serah terima sejak awal DAN gunakan COALESCE (CRIT-02 & Modul E.5)
  IF p_cash_received IS NULL OR p_food_handed_over IS NULL THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_cash_received dan p_food_handed_over tidak boleh NULL.'
      USING ERRCODE = 'KC004', HINT = 'Kirim nilai boolean eksplisit TRUE atau FALSE.';
  END IF;

  v_cash := COALESCE(p_cash_received, FALSE);
  v_food := COALESCE(p_food_handed_over, FALSE);
  v_clean_reason := NULLIF(pg_catalog.btrim(COALESCE(p_reason, '')), '');

  IF v_clean_reason IS NOT NULL AND pg_catalog.length(v_clean_reason) > 300 THEN
    RAISE EXCEPTION 'INVALID_REASON: Alasan penolakan pesanan maksimal 300 karakter.'
      USING ERRCODE = 'KC007', HINT = 'Pangkas alasan penolakan hingga maksimal 300 grapheme.';
  END IF;

  -- Kunci users lalu stalls mengikuti hierarki lock global (Modul F)
  PERFORM public.fn_require_actor(
    p_actor_id,
    ARRAY['owner']::public.user_role[],
    FALSE
  );

  SELECT * INTO v_stall
  FROM public.stalls s
  WHERE s.owner_id = p_actor_id
  FOR SHARE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_STALL: Stan milik owner tidak ditemukan.'
      USING ERRCODE = 'KC016', HINT = 'Pastikan akun owner memiliki stan aktif.';
  END IF;

  v_req_snapshot := public.fn_canonical_owner_snapshot(
    p_actor_id,
    p_mutation_id,
    v_stall.id,
    'transition_order',
    p_order_id,
    p_expected_version,
    pg_catalog.jsonb_build_object(
      'order_status', p_target_status::TEXT,
      'reason', COALESCE(v_clean_reason, ''),
      'cash_received', v_cash,
      'food_handed_over', v_food
    )
  );

  v_decision := public.fn_begin_mutation('owner-mutations', p_mutation_id, p_actor_id, v_req_snapshot);
  IF (v_decision->>'action') IS NOT DISTINCT FROM 'REPLAY' THEN
    RETURN v_decision->'response';
  END IF;

  SELECT * INTO v_order
  FROM public.orders o
  WHERE o.id = p_order_id
  FOR NO KEY UPDATE;

  -- Pesanan tidak ditemukan pada operasi tulis -> VERSION_CONFLICT (CRIT-05)
  IF NOT FOUND THEN
    RAISE EXCEPTION 'VERSION_CONFLICT: Pesanan tidak ditemukan atau statusnya telah berubah.'
      USING ERRCODE = 'KC017', HINT = 'Muat ulang daftar pesanan stan.';
  END IF;

  IF v_order.stall_id IS DISTINCT FROM v_stall.id THEN
    RAISE EXCEPTION 'FORBIDDEN: Anda bukan pemilik stan untuk pesanan ini.'
      USING ERRCODE = 'KC002', HINT = 'Owner hanya dapat memproses pesanan yang masuk ke stannya.';
  END IF;

  IF v_order.version IS DISTINCT FROM p_expected_version THEN
    RAISE EXCEPTION 'VERSION_CONFLICT: Versi pesanan telah berubah.'
      USING ERRCODE = 'KC017', HINT = 'Muat ulang pesanan sebelum memproses transisi.';
  END IF;

  -- Validasi mesin status transisi dengan NULL-safe boolean
  IF v_order.status = 'waiting' AND p_target_status = 'processing' THEN
    IF v_clean_reason IS NOT NULL OR v_cash IS DISTINCT FROM FALSE OR v_food IS DISTINCT FROM FALSE THEN
      RAISE EXCEPTION 'INVALID_TRANSITION: Transisi ke processing tidak boleh menyertakan alasan atau konfirmasi serah terima.'
        USING ERRCODE = 'KC009', HINT = 'Kosongkan reason dan set cash_received/food_handed_over ke FALSE.';
    END IF;
    v_new_payment := 'unpaid';
  ELSIF v_order.status = 'waiting' AND p_target_status = 'rejected' THEN
    IF v_clean_reason IS NULL THEN
      RAISE EXCEPTION 'INVALID_REASON: Penolakan pesanan wajib menyertakan alasan.'
        USING ERRCODE = 'KC007', HINT = 'Berikan alasan penolakan antara 1 dan 300 karakter.';
    END IF;
    IF v_cash IS DISTINCT FROM FALSE OR v_food IS DISTINCT FROM FALSE THEN
      RAISE EXCEPTION 'INVALID_TRANSITION: Penolakan pesanan tidak boleh menyertakan konfirmasi serah terima.'
        USING ERRCODE = 'KC009', HINT = 'Set cash_received dan food_handed_over ke FALSE saat menolak pesanan.';
    END IF;
    v_new_payment := 'notCharged';
  ELSIF v_order.status = 'processing' AND p_target_status = 'ready' THEN
    IF v_clean_reason IS NOT NULL OR v_cash IS DISTINCT FROM FALSE OR v_food IS DISTINCT FROM FALSE THEN
      RAISE EXCEPTION 'INVALID_TRANSITION: Transisi ke ready tidak boleh menyertakan alasan atau konfirmasi serah terima.'
        USING ERRCODE = 'KC009', HINT = 'Kosongkan reason dan set cash_received/food_handed_over ke FALSE.';
    END IF;
    v_new_payment := 'unpaid';
  ELSIF v_order.status = 'ready' AND p_target_status = 'completed' THEN
    IF v_clean_reason IS NOT NULL
       OR COALESCE(p_cash_received, FALSE) IS DISTINCT FROM TRUE
       OR COALESCE(p_food_handed_over, FALSE) IS DISTINCT FROM TRUE THEN
      RAISE EXCEPTION 'INVALID_TRANSITION: Penyelesaian pesanan wajib mengonfirmasi uang diterima dan makanan diserahkan tanpa alasan penolakan.'
        USING ERRCODE = 'KC009', HINT = 'Pastikan cash_received = TRUE, food_handed_over = TRUE, dan reason kosong.';
    END IF;
    v_new_payment := 'paid';
  ELSE
    RAISE EXCEPTION 'VERSION_CONFLICT: Transisi status dari % ke % tidak diizinkan.', v_order.status, p_target_status
      USING ERRCODE = 'KC017', HINT = 'Muat ulang status pesanan terbaru.';
  END IF;

  UPDATE public.orders
  SET status = p_target_status,
      payment_status = v_new_payment,
      rejection_reason = CASE WHEN p_target_status = 'rejected' THEN v_clean_reason ELSE NULL END,
      version = version + 1,
      updated_at = pg_catalog.timezone('utc', pg_catalog.now())
  WHERE id = p_order_id
  RETURNING * INTO v_order;

  -- Bangun JSON langsung dari record v_order tanpa query ulang (LOW-24 & Modul E.10)
  v_response := public.fn_order_record_json(v_order);

  v_lookup := pg_catalog.jsonb_build_object(
    'owner_id', p_actor_id,
    'mutation_id', p_mutation_id,
    'stall_id', v_order.stall_id,
    'kind', 'transition_order',
    'target_id', v_order.id,
    'expected_version', p_expected_version,
    'order_status', p_target_status::TEXT,
    'outcome', 'applied',
    'result_id', v_order.id,
    'result_version', v_order.version,
    'result_order_status', v_order.status::TEXT,
    'payment_status', v_order.payment_status::TEXT
  );

  PERFORM public.fn_finish_mutation(
    'owner-mutations', p_mutation_id, p_actor_id, v_req_snapshot, v_response, v_lookup
  );

  INSERT INTO public.audit_events (
    actor_id, operation, target_id, request_id, before_version, after_version, reason, outcome
  ) VALUES (
    p_actor_id, 'transition_order:' || p_target_status::TEXT, p_order_id, p_mutation_id,
    p_expected_version, v_order.version, v_clean_reason, 'applied'
  );

  RETURN v_response;
END;
$$;

-- Pengamanan hak eksekusi fungsi Modul E (Owner)
REVOKE ALL ON FUNCTION public.rpc_owner_save_stall(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN, INTEGER, INTEGER, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.rpc_owner_save_menu(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, public.menu_category, INTEGER, BOOLEAN, INTEGER, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.rpc_owner_delete_menu(TEXT, TEXT, TEXT, INTEGER) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.rpc_owner_transition_order(TEXT, TEXT, TEXT, public.order_status, INTEGER, TEXT, BOOLEAN, BOOLEAN) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.rpc_owner_save_stall(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, BOOLEAN, INTEGER, INTEGER, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.rpc_owner_save_menu(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, public.menu_category, INTEGER, BOOLEAN, INTEGER, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.rpc_owner_delete_menu(TEXT, TEXT, TEXT, INTEGER) TO service_role;
GRANT EXECUTE ON FUNCTION public.rpc_owner_transition_order(TEXT, TEXT, TEXT, public.order_status, INTEGER, TEXT, BOOLEAN, BOOLEAN) TO service_role;

COMMIT;
