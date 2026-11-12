-- Active: 1794135430745@@aws-0-ap-southeast-1.pooler.supabase.com@5432@postgres@public
-- ============================================================================
-- MIGRASI 006: RPC MUTASI PELANGGAN & PROFIL (CUSTOMER & AVATAR)
-- Proyek   : KantinCerdas (Supabase PostgreSQL 15-17)
-- Perbaikan: CRIT-01, CRIT-02, CRIT-03, CRIT-05, HIGH-08, HIGH-10, HIGH-12,
--            HIGH-13, HIGH-14, MED-17, MED-18, MED-20, MED-21, LOW-24
-- ============================================================================
BEGIN;

-- ----------------------------------------------------------------------------
-- 1. RPC 1: POST /v1/customer/orders (rpc_create_customer_order)
--    Urutan Lock: advisory(receipt) -> users(actor, owner) -> stalls -> menus(ORDER BY id) -> orders -> order_items
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_create_customer_order(
  p_actor_id TEXT,
  p_submission_id TEXT,
  p_stall_id TEXT,
  p_items JSONB,
  p_total_price_idr BIGINT,
  p_order_note TEXT DEFAULT ''
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $$
DECLARE
  v_customer public.users%ROWTYPE;
  v_stall_owner public.users%ROWTYPE;
  v_stall public.stalls%ROWTYPE;
  v_clean_order_note TEXT;
  v_req_snapshot JSONB;
  v_decision JSONB;
  v_item_count INTEGER;
  v_distinct_menu_count INTEGER;
  v_item RECORD;
  v_current_menu public.menus%ROWTYPE;
  v_computed_total BIGINT := 0;
  v_order_id TEXT;
  v_order_number TEXT;
  v_response JSONB;
  v_lookup JSONB;
BEGIN
  -- 1. Validasi NULL & format seluruh parameter input (Aturan #3 & CRIT-02)
  IF p_actor_id IS NULL OR pg_catalog.btrim(p_actor_id) = '' THEN
    RAISE EXCEPTION 'UNAUTHENTICATED: Identitas pelanggan wajib diisi.'
      USING ERRCODE = 'KC001', HINT = 'Pastikan token sesi pelanggan valid.';
  END IF;

  IF p_submission_id IS NULL OR p_submission_id !~ '^[a-f0-9]{48}$' THEN
    RAISE EXCEPTION 'INVALID_INPUT: submission_id wajib berupa 48 karakter hex huruf kecil.'
      USING ERRCODE = 'KC004', HINT = 'Gunakan Idempotency-Key 48 hex yang valid.';
  END IF;

  IF p_stall_id IS NULL OR pg_catalog.btrim(p_stall_id) = '' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Identitas stan (p_stall_id) wajib diisi.'
      USING ERRCODE = 'KC004', HINT = 'Berikan stall_id tujuan pemesanan.';
  END IF;

  -- Tolak p_total_price_idr NULL atau <= 0 sejak awal; JANGAN PERNAH memakai GREATEST(p_total_price_idr, 1) (CRIT-02)
  IF p_total_price_idr IS NULL OR p_total_price_idr < 1 OR p_total_price_idr > 1000000000 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Total harga konfirmasi (p_total_price_idr) wajib bernilai antara 1 dan 1000000000.'
      USING ERRCODE = 'KC004', HINT = 'Kirim total harga konfirmasi dalam bilangan bulat positif IDR.';
  END IF;

  v_clean_order_note := pg_catalog.btrim(COALESCE(p_order_note, ''));
  IF pg_catalog.length(v_clean_order_note) > 1200 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Catatan pesanan melebihi batas maksimum 300 karakter.'
      USING ERRCODE = 'KC004', HINT = 'Pangkas catatan pesanan hingga maksimal 300 grapheme.';
  END IF;

  IF p_items IS NULL OR pg_catalog.jsonb_typeof(p_items) IS DISTINCT FROM 'array' THEN
    RAISE EXCEPTION 'INVALID_ORDER_ITEMS: Daftar item pesanan wajib berupa array JSON.'
      USING ERRCODE = 'KC005', HINT = 'Kirim array objek item pesanan yang valid.';
  END IF;

  v_item_count := pg_catalog.jsonb_array_length(p_items);
  IF v_item_count < 1 OR v_item_count > 100 THEN
    RAISE EXCEPTION 'INVALID_ORDER_ITEMS: Jumlah jenis item pesanan wajib antara 1 dan 100.'
      USING ERRCODE = 'KC005', HINT = 'Pastikan keranjang memuat minimal 1 dan maksimal 100 jenis menu.';
  END IF;

  -- 2. Protokol idempotensi terpusat (Modul D)
  v_req_snapshot := public.fn_canonical_order_snapshot(
    p_actor_id, p_submission_id, p_stall_id, p_total_price_idr, v_clean_order_note, p_items
  );

  v_decision := public.fn_begin_mutation('orders', p_submission_id, p_actor_id, v_req_snapshot);
  IF (v_decision->>'action') IS NOT DISTINCT FROM 'REPLAY' THEN
    RETURN v_decision->'response';
  END IF;

  -- 3. Validasi dan kunci aktor: hanya customer atau owner aktif; admin ditolak (HIGH-08)
  v_customer := public.fn_require_actor(
    p_actor_id,
    ARRAY['customer', 'owner']::public.user_role[],
    FALSE
  );

  -- 4. Validasi struktur elemen p_items dan tolak menu_id duplikat dengan INVALID_ORDER_ITEMS (bukan 23505)
  IF EXISTS (
    SELECT 1
    FROM pg_catalog.jsonb_to_recordset(p_items)
      AS x(menu_id TEXT, quantity INTEGER, unit_price_idr INTEGER, note TEXT)
    WHERE x.menu_id IS NULL OR pg_catalog.btrim(x.menu_id) = ''
  ) THEN
    RAISE EXCEPTION 'INVALID_ORDER_ITEMS: Setiap item pesanan wajib memiliki menu_id yang valid.'
      USING ERRCODE = 'KC005', HINT = 'Periksa kembali menu_id pada setiap elemen items.';
  END IF;

  SELECT pg_catalog.count(DISTINCT pg_catalog.btrim(x.menu_id))
  INTO v_distinct_menu_count
  FROM pg_catalog.jsonb_to_recordset(p_items)
    AS x(menu_id TEXT, quantity INTEGER, unit_price_idr INTEGER, note TEXT);

  IF v_distinct_menu_count IS DISTINCT FROM v_item_count THEN
    RAISE EXCEPTION 'INVALID_ORDER_ITEMS: Terdapat menu_id duplikat di dalam daftar item pesanan.'
      USING ERRCODE = 'KC005', HINT = 'Gabungkan kuantitas untuk menu yang sama menjadi satu baris item.';
  END IF;

  -- Validasi kuantitas, catatan item, dan format harga konfirmasi sebelum mengunci menu
  FOR v_item IN
    SELECT
      pg_catalog.btrim(x.menu_id) AS menu_id,
      x.quantity,
      x.unit_price_idr,
      pg_catalog.btrim(COALESCE(x.note, '')) AS clean_note
    FROM pg_catalog.jsonb_to_recordset(p_items)
      AS x(menu_id TEXT, quantity INTEGER, unit_price_idr INTEGER, note TEXT)
  LOOP
    IF v_item.quantity IS NULL OR v_item.quantity < 1 OR v_item.quantity > 99 THEN
      RAISE EXCEPTION 'INVALID_QUANTITY: Kuantitas item wajib bernilai antara 1 dan 99.'
        USING ERRCODE = 'KC006', HINT = 'Periksa kembali jumlah item pada keranjang.';
    END IF;

    IF pg_catalog.length(v_item.clean_note) > 1200 THEN
      RAISE EXCEPTION 'INVALID_INPUT: Catatan item melebihi batas maksimum 300 karakter.'
        USING ERRCODE = 'KC004', HINT = 'Pangkas catatan item hingga maksimal 300 grapheme.';
    END IF;

    IF v_item.unit_price_idr IS NULL OR v_item.unit_price_idr < 1 OR v_item.unit_price_idr > 10000000 THEN
      RAISE EXCEPTION 'PRICE_CHANGED: Harga konfirmasi item tidak valid atau telah berubah.'
        USING ERRCODE = 'KC015', HINT = 'Muat ulang katalog untuk melihat harga terbaru.';
    END IF;
  END LOOP;

  -- 5. Kunci stan (FOR SHARE) dan pastikan pemilik stan juga masih aktif (HIGH-08)
  SELECT * INTO v_stall
  FROM public.stalls s
  WHERE s.id = p_stall_id
  FOR SHARE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'STALL_NOT_FOUND: Stan tujuan tidak ditemukan.'
      USING ERRCODE = 'KC012', HINT = 'Pilih stan lain yang tersedia di katalog.';
  END IF;

  SELECT * INTO v_stall_owner
  FROM public.users u
  WHERE u.id = v_stall.owner_id
  FOR SHARE;

  IF NOT FOUND OR v_stall_owner.is_active IS DISTINCT FROM TRUE OR v_stall.is_open IS DISTINCT FROM TRUE THEN
    RAISE EXCEPTION 'STALL_CLOSED: Stan sedang tutup atau tidak melayani pesanan.'
      USING ERRCODE = 'KC013', HINT = 'Pilih stan lain yang sedang buka.';
  END IF;

  -- 6. Kunci dan validasi menu dalam urutan deterministik ORDER BY menu_id ASC (Modul F & HIGH-14)
  FOR v_item IN
    SELECT
      pg_catalog.btrim(x.menu_id) AS menu_id,
      x.quantity,
      x.unit_price_idr
    FROM pg_catalog.jsonb_to_recordset(p_items)
      AS x(menu_id TEXT, quantity INTEGER, unit_price_idr INTEGER, note TEXT)
    ORDER BY pg_catalog.btrim(x.menu_id) ASC
  LOOP
    SELECT * INTO v_current_menu
    FROM public.menus m
    WHERE m.id = v_item.menu_id
      AND m.stall_id = p_stall_id
      AND m.deleted_at IS NULL
    FOR SHARE;

    IF NOT FOUND OR v_current_menu.is_available IS DISTINCT FROM TRUE THEN
      RAISE EXCEPTION 'MENU_UNAVAILABLE: Menu % sedang tidak tersedia.', v_item.menu_id
        USING ERRCODE = 'KC014', HINT = 'Hapus menu yang habis dari keranjang lalu coba lagi.';
    END IF;

    IF v_item.unit_price_idr IS DISTINCT FROM v_current_menu.price_idr THEN
      RAISE EXCEPTION 'PRICE_CHANGED: Harga menu % telah berubah.', v_current_menu.name
        USING ERRCODE = 'KC015', HINT = 'Muat ulang katalog dan konfirmasi harga terbaru.';
    END IF;

    v_computed_total := v_computed_total + (v_current_menu.price_idr::BIGINT * v_item.quantity::BIGINT);
  END LOOP;

  IF v_computed_total < 1 OR v_computed_total > 1000000000 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Total harga pesanan melampaui batas transaksi maksimum.'
      USING ERRCODE = 'KC004', HINT = 'Total pesanan harus berada di antara Rp 1 dan Rp 1.000.000.000.';
  END IF;

  IF v_computed_total IS DISTINCT FROM p_total_price_idr THEN
    RAISE EXCEPTION 'PRICE_CHANGED: Total harga pesanan tidak sesuai dengan perhitungan server.'
      USING ERRCODE = 'KC015', HINT = 'Muat ulang keranjang untuk menyinkronkan total harga.';
  END IF;

  -- 7. Panggil nextval('order_number_seq') PALING AKHIR sesudah seluruh validasi lolos (MED-21 & Modul E.4)
  v_order_id := public.fn_gen_entity_id('ord');
  v_order_number := 'KC-' || pg_catalog.nextval('public.order_number_seq')::TEXT;

  -- Simpan pesanan dengan total terhitung server (v_computed_total)
  INSERT INTO public.orders (
    id, order_number, customer_id, customer_name, stall_id, stall_name,
    status, payment_status, total_price_idr, note, version
  ) VALUES (
    v_order_id, v_order_number, v_customer.id, v_customer.name, v_stall.id, v_stall.name,
    'waiting', 'unpaid', v_computed_total, v_clean_order_note, 1
  );

  -- Simpan item pesanan sesuai urutan posisi di array klien
  INSERT INTO public.order_items (
    order_id, menu_id, position, name, quantity, unit_price_idr, note
  )
  SELECT
    v_order_id,
    pg_catalog.btrim(x.menu_id),
    (x.ord_pos - 1)::INTEGER,
    m.name,
    x.quantity,
    m.price_idr,
    pg_catalog.btrim(COALESCE(x.note, ''))
  FROM pg_catalog.jsonb_to_recordset(p_items) WITH ORDINALITY
    AS x(menu_id TEXT, quantity INTEGER, unit_price_idr INTEGER, note TEXT, ord_pos BIGINT)
  JOIN public.menus m ON m.id = pg_catalog.btrim(x.menu_id);

  -- 8. Bentuk respons & lookup snapshot, selesaikan receipt, dan catat audit
  v_response := pg_catalog.jsonb_build_object(
    'order_id', v_order_id,
    'order_number', v_order_number,
    'total_price_idr', v_computed_total
  );

  v_lookup := pg_catalog.jsonb_build_object(
    'customer_id', p_actor_id,
    'submission_id', p_submission_id,
    'status', 'confirmed',
    'order_id', v_order_id
  );

  PERFORM public.fn_finish_mutation(
    'orders', p_submission_id, p_actor_id, v_req_snapshot, v_response, v_lookup
  );

  INSERT INTO public.audit_events (
    actor_id, operation, target_id, request_id, before_version, after_version, reason, outcome
  ) VALUES (
    p_actor_id, 'create_order', v_order_id, p_submission_id, NULL, 1, NULL, 'applied'
  );

  RETURN v_response;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2. RPC 2: POST /v1/customer/orders/{orderId}/cancel (rpc_cancel_customer_order)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_cancel_customer_order(
  p_actor_id TEXT,
  p_mutation_id TEXT,
  p_order_id TEXT,
  p_expected_version INTEGER
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $$
DECLARE
  v_order public.orders%ROWTYPE;
  v_req_snapshot JSONB;
  v_decision JSONB;
  v_response JSONB;
  v_lookup JSONB;
BEGIN
  IF p_actor_id IS NULL OR pg_catalog.btrim(p_actor_id) = '' THEN
    RAISE EXCEPTION 'UNAUTHENTICATED: Identitas pelanggan wajib diisi.'
      USING ERRCODE = 'KC001', HINT = 'Pastikan sesi pengguna terautentikasi.';
  END IF;

  IF p_mutation_id IS NULL OR p_mutation_id !~ '^[a-f0-9]{48}$' THEN
    RAISE EXCEPTION 'INVALID_INPUT: mutation_id wajib berupa 48 karakter hex huruf kecil.'
      USING ERRCODE = 'KC004', HINT = 'Gunakan Idempotency-Key 48 hex yang valid.';
  END IF;

  IF p_order_id IS NULL OR pg_catalog.btrim(p_order_id) = '' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Identitas pesanan (p_order_id) wajib diisi.'
      USING ERRCODE = 'KC004', HINT = 'Berikan order_id yang akan dibatalkan.';
  END IF;

  IF p_expected_version IS NULL OR p_expected_version < 1 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_expected_version wajib berupa bilangan bulat >= 1.'
      USING ERRCODE = 'KC004', HINT = 'Sertakan versi pesanan saat ini untuk pemeriksaan CAS.';
  END IF;

  v_req_snapshot := public.fn_canonical_cancellation_snapshot(
    p_actor_id, p_mutation_id, p_order_id, p_expected_version
  );

  v_decision := public.fn_begin_mutation('order-cancellations', p_mutation_id, p_actor_id, v_req_snapshot);
  IF (v_decision->>'action') IS NOT DISTINCT FROM 'REPLAY' THEN
    RETURN v_decision->'response';
  END IF;

  -- Wajib periksa aktor aktif & role customer/owner (HIGH-08)
  PERFORM public.fn_require_actor(
    p_actor_id,
    ARRAY['customer', 'owner']::public.user_role[],
    FALSE
  );

  SELECT * INTO v_order
  FROM public.orders o
  WHERE o.id = p_order_id
  FOR NO KEY UPDATE;

  -- Entitas target tidak ditemukan pada operasi tulis -> VERSION_CONFLICT (CRIT-05 & Modul E.11)
  IF NOT FOUND THEN
    RAISE EXCEPTION 'VERSION_CONFLICT: Pesanan tidak ditemukan atau statusnya telah berubah.'
      USING ERRCODE = 'KC017', HINT = 'Muat ulang daftar pesanan Anda.';
  END IF;

  IF v_order.customer_id IS DISTINCT FROM p_actor_id THEN
    RAISE EXCEPTION 'FORBIDDEN: Anda bukan pemilik pesanan ini.'
      USING ERRCODE = 'KC002', HINT = 'Hanya pembuat pesanan yang dapat membatalkannya.';
  END IF;

  IF v_order.version IS DISTINCT FROM p_expected_version
     OR v_order.status IS DISTINCT FROM 'waiting' THEN
    RAISE EXCEPTION 'VERSION_CONFLICT: Status atau versi pesanan telah berubah.'
      USING ERRCODE = 'KC017', HINT = 'Pesanan yang sudah diproses tidak dapat dibatalkan.';
  END IF;

  UPDATE public.orders
  SET status = 'cancelled',
      payment_status = 'notCharged',
      version = version + 1,
      updated_at = pg_catalog.timezone('utc', pg_catalog.now())
  WHERE id = p_order_id
  RETURNING * INTO v_order;

  -- Bangun JSON langsung dari record v_order tanpa query ulang (LOW-24 & Modul E.10)
  v_response := public.fn_order_record_json(v_order);

  v_lookup := pg_catalog.jsonb_build_object(
    'customer_id', p_actor_id,
    'mutation_id', p_mutation_id,
    'stall_id', v_order.stall_id,
    'order_number', v_order.order_number,
    'order_id', v_order.id,
    'expected_version', p_expected_version,
    'outcome', 'applied',
    'result_version', v_order.version,
    'order_status', 'cancelled',
    'payment_status', 'notCharged'
  );

  PERFORM public.fn_finish_mutation(
    'order-cancellations', p_mutation_id, p_actor_id, v_req_snapshot, v_response, v_lookup
  );

  INSERT INTO public.audit_events (
    actor_id, operation, target_id, request_id, before_version, after_version, reason, outcome
  ) VALUES (
    p_actor_id, 'cancel_order', p_order_id, p_mutation_id, p_expected_version, v_order.version, NULL, 'applied'
  );

  RETURN v_response;
END;
$$;

-- ----------------------------------------------------------------------------
-- 3. RPC 3: POST /v1/customer/canteen-applications (rpc_submit_canteen_application)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_submit_canteen_application(
  p_actor_id TEXT,
  p_submission_id TEXT,
  p_name TEXT,
  p_description TEXT,
  p_location TEXT,
  p_phone TEXT,
  p_previous_id TEXT DEFAULT NULL,
  p_previous_version INTEGER DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $$
DECLARE
  v_clean_name TEXT;
  v_clean_desc TEXT;
  v_clean_loc TEXT;
  v_clean_phone TEXT;
  v_clean_prev_id TEXT;
  v_digits TEXT;
  v_latest public.canteen_applications%ROWTYPE;
  v_new_app public.canteen_applications%ROWTYPE;
  v_req_snapshot JSONB;
  v_decision JSONB;
  v_response JSONB;
  v_lookup JSONB;
BEGIN
  IF p_actor_id IS NULL OR pg_catalog.btrim(p_actor_id) = '' THEN
    RAISE EXCEPTION 'UNAUTHENTICATED: Identitas pemohon wajib diisi.'
      USING ERRCODE = 'KC001', HINT = 'Pastikan sesi pengguna terautentikasi.';
  END IF;

  IF p_submission_id IS NULL OR p_submission_id !~ '^[a-f0-9]{48}$' THEN
    RAISE EXCEPTION 'INVALID_INPUT: submission_id wajib berupa 48 karakter hex huruf kecil.'
      USING ERRCODE = 'KC004', HINT = 'Gunakan Idempotency-Key 48 hex yang valid.';
  END IF;

  IF p_name IS NULL OR p_description IS NULL OR p_location IS NULL OR p_phone IS NULL THEN
    RAISE EXCEPTION 'INVALID_INPUT: Nama stan, deskripsi, lokasi, dan nomor telepon wajib diisi.'
      USING ERRCODE = 'KC004', HINT = 'Lengkapi seluruh field formulir pengajuan stan.';
  END IF;

  v_clean_name := pg_catalog.btrim(p_name);
  v_clean_desc := pg_catalog.btrim(p_description);
  v_clean_loc := pg_catalog.btrim(p_location);
  v_clean_phone := pg_catalog.btrim(p_phone);
  v_clean_prev_id := NULLIF(pg_catalog.btrim(COALESCE(p_previous_id, '')), '');

  IF pg_catalog.length(v_clean_name) < 1 OR pg_catalog.length(v_clean_name) > 480 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Nama stan pengajuan wajib antara 1 dan 120 karakter.'
      USING ERRCODE = 'KC004', HINT = 'Periksa panjang nama stan yang diajukan.';
  END IF;

  IF pg_catalog.length(v_clean_desc) < 1 OR pg_catalog.length(v_clean_desc) > 4000 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Deskripsi pengajuan wajib antara 1 dan 1000 karakter.'
      USING ERRCODE = 'KC004', HINT = 'Periksa panjang deskripsi pengajuan stan.';
  END IF;

  IF pg_catalog.length(v_clean_loc) < 1 OR pg_catalog.length(v_clean_loc) > 480 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Lokasi pengajuan wajib antara 1 dan 120 karakter.'
      USING ERRCODE = 'KC004', HINT = 'Periksa panjang lokasi blok stan.';
  END IF;

  v_digits := pg_catalog.regexp_replace(v_clean_phone, '[^0-9]', '', 'g');
  IF pg_catalog.length(v_clean_phone) > 24
     OR v_clean_phone !~ '^\+?[0-9 ()-]+$'
     OR pg_catalog.length(v_digits) < 8
     OR pg_catalog.length(v_digits) > 15 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Format nomor telepon tidak valid (8-15 digit, maksimal 24 karakter).'
      USING ERRCODE = 'KC004', HINT = 'Gunakan angka, spasi, tanda kurung, tanda hubung, atau awalan +.';
  END IF;

  IF (v_clean_prev_id IS NULL) IS DISTINCT FROM (p_previous_version IS NULL) THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter previous_id dan previous_version harus keduanya diisi atau keduanya NULL.'
      USING ERRCODE = 'KC004', HINT = 'Sertakan pasangan previous_id dan previous_version saat mengajukan ulang.';
  END IF;

  IF p_previous_version IS NOT NULL AND p_previous_version < 1 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter previous_version harus >= 1.'
      USING ERRCODE = 'KC004', HINT = 'Gunakan versi pengajuan terakhir yang ditolak.';
  END IF;

  v_req_snapshot := public.fn_canonical_application_snapshot(
    p_actor_id, p_submission_id, v_clean_name, v_clean_desc, v_clean_loc,
    v_clean_phone, v_clean_prev_id, p_previous_version
  );

  v_decision := public.fn_begin_mutation('canteen-applications', p_submission_id, p_actor_id, v_req_snapshot);
  IF (v_decision->>'action') IS NOT DISTINCT FROM 'REPLAY' THEN
    RETURN v_decision->'response';
  END IF;

  -- Kunci baris induk users (FOR NO KEY UPDATE) agar dua submit pertama paralel
  -- dari pemohon yang sama ter-serialisasi dan tidak melempar 23505 mentah (Modul F & HIGH-14)
  PERFORM public.fn_require_actor(
    p_actor_id,
    ARRAY['customer']::public.user_role[],
    TRUE
  );

  SELECT * INTO v_latest
  FROM public.canteen_applications ca
  WHERE ca.applicant_id = p_actor_id AND ca.is_latest = TRUE
  FOR NO KEY UPDATE;

  IF NOT FOUND THEN
    IF v_clean_prev_id IS NOT NULL OR p_previous_version IS NOT NULL THEN
      RAISE EXCEPTION 'VERSION_CONFLICT: Tidak ada pengajuan sebelumnya untuk diajukan ulang.'
        USING ERRCODE = 'KC017', HINT = 'Muat ulang halaman pengajuan stan.';
    END IF;
  ELSE
    IF v_latest.status IS DISTINCT FROM 'rejected' THEN
      RAISE EXCEPTION 'VERSION_CONFLICT: Pengajuan sebelumnya masih aktif atau sudah disetujui.'
        USING ERRCODE = 'KC017', HINT = 'Tunggu hasil peninjauan pengajuan yang sedang berjalan.';
    END IF;
    IF v_clean_prev_id IS DISTINCT FROM v_latest.id
       OR p_previous_version IS DISTINCT FROM v_latest.version THEN
      RAISE EXCEPTION 'VERSION_CONFLICT: Identitas atau versi pengajuan sebelumnya tidak cocok.'
        USING ERRCODE = 'KC017', HINT = 'Muat ulang status pengajuan terbaru sebelum mengirim ulang.';
    END IF;

    UPDATE public.canteen_applications
    SET is_latest = FALSE,
        updated_at = pg_catalog.timezone('utc', pg_catalog.now())
    WHERE id = v_latest.id;
  END IF;

  INSERT INTO public.canteen_applications (
    applicant_id, name, description, location, phone,
    status, version, previous_id, is_latest
  ) VALUES (
    p_actor_id, v_clean_name, v_clean_desc, v_clean_loc, v_clean_phone,
    'submitted', 1, v_clean_prev_id, TRUE
  )
  RETURNING * INTO v_new_app;

  v_response := public.fn_canteen_application_json(v_new_app);

  v_lookup := pg_catalog.jsonb_build_object(
    'customer_id', p_actor_id,
    'submission_id', p_submission_id,
    'status', 'submitted',
    'receipt', v_response
  );

  PERFORM public.fn_finish_mutation(
    'canteen-applications', p_submission_id, p_actor_id, v_req_snapshot, v_response, v_lookup
  );

  INSERT INTO public.audit_events (
    actor_id, operation, target_id, request_id, before_version, after_version, reason, outcome
  ) VALUES (
    p_actor_id, 'submit_canteen_application', v_new_app.id, p_submission_id,
    p_previous_version, v_new_app.version, NULL, 'applied'
  );

  RETURN v_response;
END;
$$;

-- ----------------------------------------------------------------------------
-- 4. RPC 4: PUT /v1/customer/food-preferences (rpc_save_food_preferences)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_save_food_preferences(
  p_actor_id TEXT,
  p_mutation_id TEXT,
  p_expected_version INTEGER,
  p_max_budget_idr INTEGER,
  p_vegetarian BOOLEAN,
  p_avoid_ingredients TEXT[]
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $$
DECLARE
  v_normalized_ingredients TEXT[];
  v_current public.food_preferences%ROWTYPE;
  v_saved public.food_preferences%ROWTYPE;
  v_req_snapshot JSONB;
  v_decision JSONB;
  v_response JSONB;
  v_lookup JSONB;
BEGIN
  IF p_actor_id IS NULL OR pg_catalog.btrim(p_actor_id) = '' THEN
    RAISE EXCEPTION 'UNAUTHENTICATED: Identitas pengguna wajib diisi.'
      USING ERRCODE = 'KC001', HINT = 'Pastikan sesi pengguna terautentikasi.';
  END IF;

  IF p_mutation_id IS NULL OR p_mutation_id !~ '^[a-f0-9]{48}$' THEN
    RAISE EXCEPTION 'INVALID_INPUT: mutation_id wajib berupa 48 karakter hex huruf kecil.'
      USING ERRCODE = 'KC004', HINT = 'Gunakan Idempotency-Key 48 hex yang valid.';
  END IF;

  IF p_expected_version IS NOT NULL AND p_expected_version < 1 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_expected_version harus NULL (buat baru) atau >= 1.'
      USING ERRCODE = 'KC004', HINT = 'Kirim NULL bila preferensi belum pernah disimpan atau versi >= 1.';
  END IF;

  IF p_max_budget_idr IS NOT NULL AND (p_max_budget_idr < 1 OR p_max_budget_idr > 10000000) THEN
    RAISE EXCEPTION 'INVALID_INPUT: Batas anggaran (p_max_budget_idr) wajib NULL atau antara 1 dan 10000000.'
      USING ERRCODE = 'KC004', HINT = 'Masukkan anggaran dalam rentang Rp 1 s.d. Rp 10.000.000.';
  END IF;

  IF p_vegetarian IS NULL THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_vegetarian tidak boleh NULL.'
      USING ERRCODE = 'KC004', HINT = 'Kirim nilai boolean TRUE atau FALSE untuk p_vegetarian.';
  END IF;

  -- Normalisasi & validasi avoid_ingredients SEBELUM membentuk snapshot & menyimpan (Modul E.8)
  v_normalized_ingredients := public.fn_normalize_avoid_ingredients(p_avoid_ingredients);

  v_req_snapshot := public.fn_canonical_food_prefs_snapshot(
    p_actor_id, p_mutation_id, p_expected_version, p_max_budget_idr, p_vegetarian, v_normalized_ingredients
  );

  v_decision := public.fn_begin_mutation('food-preferences', p_mutation_id, p_actor_id, v_req_snapshot);
  IF (v_decision->>'action') IS NOT DISTINCT FROM 'REPLAY' THEN
    RETURN v_decision->'response';
  END IF;

  -- Kunci baris induk users (FOR NO KEY UPDATE) untuk mencegah race 23505 pada insert pertama
  -- dan tolak role admin (HIGH-08 & HIGH-14)
  PERFORM public.fn_require_actor(
    p_actor_id,
    ARRAY['customer', 'owner']::public.user_role[],
    TRUE
  );

  SELECT * INTO v_current
  FROM public.food_preferences fp
  WHERE fp.customer_id = p_actor_id
  FOR NO KEY UPDATE;

  IF NOT FOUND THEN
    IF p_expected_version IS NOT NULL THEN
      RAISE EXCEPTION 'VERSION_CONFLICT: Preferensi belum ada namun expected_version dikirim.'
        USING ERRCODE = 'KC017', HINT = 'Muat ulang preferensi makanan terlebih dahulu.';
    END IF;

    INSERT INTO public.food_preferences (
      customer_id, max_budget_idr, vegetarian, avoid_ingredients, version
    ) VALUES (
      p_actor_id, p_max_budget_idr, p_vegetarian, v_normalized_ingredients, 1
    )
    RETURNING * INTO v_saved;
  ELSE
    IF p_expected_version IS NULL OR v_current.version IS DISTINCT FROM p_expected_version THEN
      RAISE EXCEPTION 'VERSION_CONFLICT: Versi preferensi makanan tidak cocok.'
        USING ERRCODE = 'KC017', HINT = 'Muat ulang preferensi makanan untuk mendapatkan versi terbaru.';
    END IF;

    UPDATE public.food_preferences
    SET max_budget_idr = p_max_budget_idr,
        vegetarian = p_vegetarian,
        avoid_ingredients = v_normalized_ingredients,
        version = version + 1,
        updated_at = pg_catalog.timezone('utc', pg_catalog.now())
    WHERE customer_id = p_actor_id
    RETURNING * INTO v_saved;
  END IF;

  v_response := pg_catalog.jsonb_build_object(
    'customer_id', v_saved.customer_id,
    'version', v_saved.version,
    'max_budget_idr', v_saved.max_budget_idr,
    'vegetarian', v_saved.vegetarian,
    'avoid_ingredients', pg_catalog.to_jsonb(v_saved.avoid_ingredients)
  );

  v_lookup := pg_catalog.jsonb_build_object(
    'customer_id', p_actor_id,
    'mutation_id', p_mutation_id,
    'expected_version', p_expected_version,
    'max_budget_idr', p_max_budget_idr,
    'vegetarian', p_vegetarian,
    'avoid_ingredients', pg_catalog.to_jsonb(v_normalized_ingredients),
    'outcome', 'applied',
    'saved', v_response
  );

  PERFORM public.fn_finish_mutation(
    'food-preferences', p_mutation_id, p_actor_id, v_req_snapshot, v_response, v_lookup
  );

  INSERT INTO public.audit_events (
    actor_id, operation, target_id, request_id, before_version, after_version, reason, outcome
  ) VALUES (
    p_actor_id, 'save_food_preferences', p_actor_id, p_mutation_id,
    p_expected_version, v_saved.version, NULL, 'applied'
  );

  RETURN v_response;
END;
$$;

-- ----------------------------------------------------------------------------
-- 5. RPC 12: PUT /v1/auth/profile/avatar (rpc_update_profile_avatar — MED-20)
--    Memperbarui avatar_url, memverifikasi kepemilikan aset media berkategori
--    profile_avatar di public.media_assets, menaikkan users.version agar CAS
--    Admin konsisten, serta mencatat audit_events dan mutation_receipts.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_update_profile_avatar(
  p_actor_id TEXT,
  p_mutation_id TEXT,
  p_avatar_url TEXT DEFAULT NULL,
  p_expected_version INTEGER DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $$
DECLARE
  v_user public.users%ROWTYPE;
  v_before_version INTEGER;
  v_old_avatar_url TEXT;
  v_clean_url TEXT;
  v_req_snapshot JSONB;
  v_decision JSONB;
  v_response JSONB;
  v_lookup JSONB;
BEGIN
  IF p_actor_id IS NULL OR pg_catalog.btrim(p_actor_id) = '' THEN
    RAISE EXCEPTION 'UNAUTHENTICATED: Identitas pengguna wajib diisi.'
      USING ERRCODE = 'KC001', HINT = 'Pastikan sesi pengguna terautentikasi.';
  END IF;

  IF p_mutation_id IS NULL OR p_mutation_id !~ '^[a-f0-9]{48}$' THEN
    RAISE EXCEPTION 'INVALID_INPUT: mutation_id wajib berupa 48 karakter hex huruf kecil.'
      USING ERRCODE = 'KC004', HINT = 'Sertakan Idempotency-Key 48 hex pada pembaruan avatar.';
  END IF;

  IF p_expected_version IS NOT NULL AND p_expected_version < 1 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_expected_version harus NULL atau >= 1.'
      USING ERRCODE = 'KC004', HINT = 'Gunakan nilai versi positif bila menyertakan expected_version.';
  END IF;

  v_clean_url := NULLIF(pg_catalog.btrim(COALESCE(p_avatar_url, '')), '');
  IF NOT public.fn_is_safe_image_url(v_clean_url) THEN
    RAISE EXCEPTION 'INVALID_IMAGE_URL: URL foto profil tidak valid atau bukan berasal dari bucket resmi kantin-media.'
      USING ERRCODE = 'KC010', HINT = 'Unggah gambar melalui POST /v1/media/images terlebih dahulu.';
  END IF;

  v_req_snapshot := pg_catalog.jsonb_build_object(
    'actor_id', p_actor_id,
    'mutation_id', p_mutation_id,
    'kind', 'update_profile_avatar',
    'avatar_url', v_clean_url,
    'expected_version', p_expected_version
  );

  v_decision := public.fn_begin_mutation('media-images', p_mutation_id, p_actor_id, v_req_snapshot);
  IF (v_decision->>'action') IS NOT DISTINCT FROM 'REPLAY' THEN
    RETURN v_decision->'response';
  END IF;

  v_user := public.fn_require_actor(
    p_actor_id,
    ARRAY['customer', 'owner', 'admin']::public.user_role[],
    TRUE
  );

  IF p_expected_version IS NOT NULL AND v_user.version IS DISTINCT FROM p_expected_version THEN
    RAISE EXCEPTION 'VERSION_CONFLICT: Versi profil pengguna telah berubah.'
      USING ERRCODE = 'KC017', HINT = 'Muat ulang profil pengguna sebelum mencoba lagi.';
  END IF;

  v_before_version := v_user.version;
  v_old_avatar_url := v_user.avatar_url;

  -- Wajib pastikan v_clean_url terdaftar di public.media_assets milik p_actor_id
  -- dengan kategori 'profile_avatar' (Urutan Lock: advisory -> users -> media_assets)
  IF v_clean_url IS NOT NULL THEN
    UPDATE public.media_assets
    SET is_referenced = TRUE,
        updated_at = pg_catalog.timezone('utc', pg_catalog.now())
    WHERE owner_id = p_actor_id
      AND category = 'profile_avatar'
      AND public_url = v_clean_url;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'INVALID_IMAGE_URL: Foto profil belum terdaftar di media_assets milik pengguna ini atau bukan berkategori profile_avatar.'
        USING ERRCODE = 'KC010', HINT = 'Unggah gambar melalui POST /v1/media/images dengan kategori profile_avatar terlebih dahulu.';
    END IF;
  END IF;

  -- Lepas penanda referensi pada avatar lama bila diganti atau dihapus
  IF v_old_avatar_url IS NOT NULL AND v_old_avatar_url IS DISTINCT FROM v_clean_url THEN
    UPDATE public.media_assets
    SET is_referenced = FALSE,
        updated_at = pg_catalog.timezone('utc', pg_catalog.now())
    WHERE owner_id = p_actor_id
      AND category = 'profile_avatar'
      AND public_url = v_old_avatar_url;
  END IF;

  UPDATE public.users
  SET avatar_url = v_clean_url,
      version = version + 1,
      updated_at = pg_catalog.timezone('utc', pg_catalog.now())
  WHERE id = p_actor_id
  RETURNING * INTO v_user;

  v_response := public.fn_user_json(v_user);

  v_lookup := pg_catalog.jsonb_build_object(
    'actor_id', p_actor_id,
    'mutation_id', p_mutation_id,
    'outcome', 'applied',
    'result_version', v_user.version,
    'user', v_response
  );

  PERFORM public.fn_finish_mutation(
    'media-images', p_mutation_id, p_actor_id, v_req_snapshot, v_response, v_lookup
  );

  INSERT INTO public.audit_events (
    actor_id, operation, target_id, request_id, before_version, after_version, reason, outcome
  ) VALUES (
    p_actor_id, 'update_profile_avatar', p_actor_id, p_mutation_id,
    v_before_version, v_user.version, NULL, 'applied'
  );

  RETURN v_response;
END;
$$;

-- Pengamanan hak eksekusi fungsi Modul E (Customer & Avatar)
REVOKE ALL ON FUNCTION public.rpc_create_customer_order(TEXT, TEXT, TEXT, JSONB, BIGINT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.rpc_cancel_customer_order(TEXT, TEXT, TEXT, INTEGER) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.rpc_submit_canteen_application(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, INTEGER) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.rpc_save_food_preferences(TEXT, TEXT, INTEGER, INTEGER, BOOLEAN, TEXT[]) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.rpc_update_profile_avatar(TEXT, TEXT, TEXT, INTEGER) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.rpc_create_customer_order(TEXT, TEXT, TEXT, JSONB, BIGINT, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.rpc_cancel_customer_order(TEXT, TEXT, TEXT, INTEGER) TO service_role;
GRANT EXECUTE ON FUNCTION public.rpc_submit_canteen_application(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, INTEGER) TO service_role;
GRANT EXECUTE ON FUNCTION public.rpc_save_food_preferences(TEXT, TEXT, INTEGER, INTEGER, BOOLEAN, TEXT[]) TO service_role;
GRANT EXECUTE ON FUNCTION public.rpc_update_profile_avatar(TEXT, TEXT, TEXT, INTEGER) TO service_role;

COMMIT;
