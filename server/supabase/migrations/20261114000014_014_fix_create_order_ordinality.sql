-- ============================================================================
-- MIGRASI 014: PERBAIKAN rpc_create_customer_order (WITH ORDINALITY)
-- Proyek   : KantinCerdas (Supabase PostgreSQL 15-17)
-- Masalah  : INSERT INTO public.order_items pada migrasi 006 memakai
--            `jsonb_to_recordset(...) WITH ORDINALITY AS x(<daftar kolom bertipe>)`.
--            PostgreSQL menolak bentuk ini dengan error
--            "WITH ORDINALITY cannot be used with a column definition list".
--            Karena badan fungsi plpgsql baru dikompilasi saat dijalankan,
--            migrasi 006 lolos, tetapi setiap pemanggilan fungsi gagal.
-- Perbaikan: bungkus fungsi dengan ROWS FROM (...) lalu beri alias kolom
--            terpisah. Hanya klausa FROM pada INSERT order_items yang berubah;
--            seluruh logika, tanda tangan, dan hak akses fungsi tetap sama.
-- Catatan  : CREATE OR REPLACE mempertahankan GRANT/REVOKE dari migrasi 006.
--            Migrasi 006 sengaja tidak diedit karena sudah pernah diterapkan.
-- ============================================================================
BEGIN;

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
  FROM ROWS FROM (
    pg_catalog.jsonb_to_recordset(p_items)
      AS (menu_id TEXT, quantity INTEGER, unit_price_idr INTEGER, note TEXT)
  ) WITH ORDINALITY AS x(menu_id, quantity, unit_price_idr, note, ord_pos)
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

COMMIT;
