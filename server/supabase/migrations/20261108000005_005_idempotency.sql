-- Active: 1794135430745@@aws-0-ap-southeast-1.pooler.supabase.com@5432@postgres@public
-- ============================================================================
-- MIGRASI 005: PROTOKOL IDEMPOTENSI TERPUSAT, LOOKUP/SEAL, & PEMANGKASAN PII
-- Proyek   : KantinCerdas (Supabase PostgreSQL 15-17)
-- Perbaikan: CRIT-02, CRIT-03, CRIT-04, HIGH-12, MED-20, MED-22
-- ============================================================================
BEGIN;

-- 1. Fungsi penghitung SHA-256 hex kanonis dari JSONB (MED-20)
CREATE OR REPLACE FUNCTION public.fn_compute_payload_hash(p_snapshot JSONB)
RETURNS TEXT
LANGUAGE sql
IMMUTABLE
STRICT
SET search_path = ''
AS $$
  SELECT pg_catalog.encode(
    extensions.digest(pg_catalog.convert_to(p_snapshot::TEXT, 'UTF8'), 'sha256'),
    'hex'
  );
$$;

-- 2. Fungsi pembentuk request_snapshot kanonis seragam per keluarga (Modul D.6 & CRIT-03)
CREATE OR REPLACE FUNCTION public.fn_canonical_order_snapshot(
  p_actor_id TEXT,
  p_submission_id TEXT,
  p_stall_id TEXT,
  p_total_price_idr BIGINT,
  p_order_note TEXT,
  p_items JSONB
)
RETURNS JSONB
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT pg_catalog.jsonb_build_object(
    'customer_id', p_actor_id,
    'submission_id', p_submission_id,
    'stall_id', p_stall_id,
    'total_price_idr', p_total_price_idr,
    'order_note', p_order_note,
    'items', p_items
  );
$$;

CREATE OR REPLACE FUNCTION public.fn_canonical_cancellation_snapshot(
  p_actor_id TEXT,
  p_mutation_id TEXT,
  p_order_id TEXT,
  p_expected_version INTEGER
)
RETURNS JSONB
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT pg_catalog.jsonb_build_object(
    'customer_id', p_actor_id,
    'mutation_id', p_mutation_id,
    'order_id', p_order_id,
    'expected_version', p_expected_version
  );
$$;

CREATE OR REPLACE FUNCTION public.fn_canonical_application_snapshot(
  p_actor_id TEXT,
  p_submission_id TEXT,
  p_name TEXT,
  p_description TEXT,
  p_location TEXT,
  p_phone TEXT,
  p_previous_id TEXT,
  p_previous_version INTEGER
)
RETURNS JSONB
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT pg_catalog.jsonb_build_object(
    'customer_id', p_actor_id,
    'submission_id', p_submission_id,
    'name', p_name,
    'description', p_description,
    'location', p_location,
    'phone', p_phone,
    'previous_id', p_previous_id,
    'previous_version', p_previous_version
  );
$$;

CREATE OR REPLACE FUNCTION public.fn_canonical_food_prefs_snapshot(
  p_actor_id TEXT,
  p_mutation_id TEXT,
  p_expected_version INTEGER,
  p_max_budget_idr INTEGER,
  p_vegetarian BOOLEAN,
  p_avoid_ingredients TEXT[]
)
RETURNS JSONB
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT pg_catalog.jsonb_build_object(
    'customer_id', p_actor_id,
    'mutation_id', p_mutation_id,
    'expected_version', p_expected_version,
    'max_budget_idr', p_max_budget_idr,
    'vegetarian', p_vegetarian,
    'avoid_ingredients', pg_catalog.to_jsonb(p_avoid_ingredients)
  );
$$;

CREATE OR REPLACE FUNCTION public.fn_canonical_owner_snapshot(
  p_actor_id TEXT,
  p_mutation_id TEXT,
  p_stall_id TEXT,
  p_kind TEXT,
  p_target_id TEXT,
  p_expected_version INTEGER,
  p_details JSONB
)
RETURNS JSONB
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT pg_catalog.jsonb_build_object(
    'owner_id', p_actor_id,
    'mutation_id', p_mutation_id,
    'stall_id', p_stall_id,
    'kind', p_kind,
    'target_id', p_target_id,
    'expected_version', p_expected_version,
    'details', COALESCE(p_details, '{}'::JSONB)
  );
$$;

CREATE OR REPLACE FUNCTION public.fn_canonical_admin_snapshot(
  p_actor_id TEXT,
  p_mutation_id TEXT,
  p_kind TEXT,
  p_target_id TEXT,
  p_expected_version INTEGER,
  p_target_role TEXT,
  p_applicant_id TEXT,
  p_is_active BOOLEAN,
  p_decision TEXT,
  p_reason TEXT
)
RETURNS JSONB
LANGUAGE sql
IMMUTABLE
SET search_path = ''
AS $$
  SELECT pg_catalog.jsonb_build_object(
    'admin_id', p_actor_id,
    'mutation_id', p_mutation_id,
    'kind', p_kind,
    'target_id', p_target_id,
    'expected_version', p_expected_version,
    'target_role', p_target_role,
    'applicant_id', p_applicant_id,
    'is_active', p_is_active,
    'decision', p_decision,
    'reason', p_reason
  );
$$;

-- 3. Fungsi pembentuk lookup_snapshot minimal yang valid untuk penyegelan negatif (CRIT-04)
CREATE OR REPLACE FUNCTION public.fn_build_default_not_applied_lookup(
  p_family public.mutation_family,
  p_request_id TEXT,
  p_actor_id TEXT,
  p_request_snapshot JSONB,
  p_unseen_sealed BOOLEAN
)
RETURNS JSONB
LANGUAGE plpgsql
IMMUTABLE
SET search_path = ''
AS $$
DECLARE
  v_snap JSONB := COALESCE(p_request_snapshot, '{}'::JSONB);
BEGIN
  CASE p_family
    WHEN 'orders' THEN
      RETURN pg_catalog.jsonb_build_object(
        'customer_id', p_actor_id,
        'submission_id', p_request_id,
        'status', 'not_created',
        'outcome', 'not_applied',
        'unseen_sealed', p_unseen_sealed
      );
    WHEN 'canteen-applications' THEN
      RETURN pg_catalog.jsonb_build_object(
        'customer_id', p_actor_id,
        'submission_id', p_request_id,
        'status', 'not_submitted',
        'outcome', 'not_applied',
        'unseen_sealed', p_unseen_sealed
      );
    WHEN 'order-cancellations' THEN
      RETURN pg_catalog.jsonb_build_object(
        'customer_id', p_actor_id,
        'mutation_id', p_request_id,
        'stall_id', COALESCE(v_snap->>'stall_id', ''),
        'order_number', COALESCE(v_snap->>'order_number', ''),
        'order_id', COALESCE(v_snap->>'order_id', ''),
        'expected_version', v_snap->'expected_version',
        'outcome', 'not_applied',
        'unseen_sealed', p_unseen_sealed
      );
    WHEN 'food-preferences' THEN
      RETURN pg_catalog.jsonb_build_object(
        'customer_id', p_actor_id,
        'mutation_id', p_request_id,
        'expected_version', v_snap->'expected_version',
        'max_budget_idr', v_snap->'max_budget_idr',
        'vegetarian', COALESCE((v_snap->>'vegetarian')::BOOLEAN, FALSE),
        'avoid_ingredients', COALESCE(v_snap->'avoid_ingredients', '[]'::JSONB),
        'outcome', 'not_applied',
        'unseen_sealed', p_unseen_sealed
      );
    WHEN 'owner-mutations' THEN
      RETURN pg_catalog.jsonb_build_object(
        'owner_id', p_actor_id,
        'mutation_id', p_request_id,
        'stall_id', COALESCE(v_snap->>'stall_id', ''),
        'kind', COALESCE(v_snap->>'kind', 'save_stall'),
        'target_id', v_snap->'target_id',
        'expected_version', v_snap->'expected_version',
        'order_status', v_snap->'order_status',
        'outcome', 'not_applied',
        'unseen_sealed', p_unseen_sealed
      );
    WHEN 'admin-mutations' THEN
      RETURN pg_catalog.jsonb_build_object(
        'admin_id', p_actor_id,
        'mutation_id', p_request_id,
        'kind', COALESCE(v_snap->>'kind', 'change_access'),
        'target_id', COALESCE(v_snap->>'target_id', ''),
        'expected_version', v_snap->'expected_version',
        'decision', v_snap->'decision',
        'applicant_id', v_snap->'applicant_id',
        'is_active', v_snap->'is_active',
        'target_role', v_snap->'target_role',
        'reason', COALESCE(v_snap->>'reason', ''),
        'outcome', 'not_applied',
        'unseen_sealed', p_unseen_sealed
      );
    ELSE
      RETURN pg_catalog.jsonb_build_object(
        'actor_id', p_actor_id,
        'mutation_id', p_request_id,
        'outcome', 'not_applied',
        'unseen_sealed', p_unseen_sealed
      );
  END CASE;
END;
$$;

-- 4. Fungsi pusat awal mutasi: fn_begin_mutation (Modul D)
--    Mengembalikan JSONB:
--    - {'action': 'EXECUTE'} bila mutasi harus dijalankan
--    - {'action': 'REPLAY', 'response': <response_snapshot>} bila sudah applied dengan payload identik
--    Melempar exception domain bila parameter tidak valid, actor berbeda, payload berbeda, atau sudah disegel.
CREATE OR REPLACE FUNCTION public.fn_begin_mutation(
  p_family public.mutation_family,
  p_request_id TEXT,
  p_actor_id TEXT,
  p_request_snapshot JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $$
DECLARE
  v_existing public.mutation_receipts%ROWTYPE;
  v_hash TEXT;
BEGIN
  PERFORM public.fn_require_service_role();

  IF p_family IS NULL THEN
    RAISE EXCEPTION 'INVALID_INPUT: Keluarga mutasi (p_family) wajib diisi.'
      USING ERRCODE = 'KC004', HINT = 'Berikan nilai enum mutation_family yang valid.';
  END IF;

  IF p_actor_id IS NULL OR pg_catalog.btrim(p_actor_id) = '' THEN
    RAISE EXCEPTION 'UNAUTHENTICATED: Identitas pelaku (p_actor_id) wajib diisi.'
      USING ERRCODE = 'KC001', HINT = 'Pastikan sesi pengguna terautentikasi.';
  END IF;

  IF p_request_id IS NULL OR p_request_id !~ '^[a-f0-9]{48}$' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Idempotency-Key (request_id) wajib berupa 48 karakter hex huruf kecil.'
      USING ERRCODE = 'KC004', HINT = 'Format request_id harus ^[a-f0-9]{48}$.';
  END IF;

  IF p_request_snapshot IS NULL OR pg_catalog.jsonb_typeof(p_request_snapshot) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Snapshot request wajib berupa objek JSON.'
      USING ERRCODE = 'KC004', HINT = 'Gunakan fungsi fn_canonical_*_snapshot untuk membentuk snapshot.';
  END IF;

  -- Baris pertama protokol konkurensi: kunci deterministik per (family, request_id)
  -- Menutup celah race "baris belum ada" pada level isolasi READ COMMITTED (Modul D.1)
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(p_family::TEXT || ':' || p_request_id, 0)
  );

  v_hash := public.fn_compute_payload_hash(p_request_snapshot);

  SELECT * INTO v_existing
  FROM public.mutation_receipts mr
  WHERE mr.family = p_family AND mr.request_id = p_request_id
  FOR NO KEY UPDATE;

  IF FOUND THEN
    -- Validasi kepemilikan actor_id pada SEMUA state memakai IS DISTINCT FROM (Modul D.2)
    IF v_existing.actor_id IS DISTINCT FROM p_actor_id THEN
      RAISE EXCEPTION 'FORBIDDEN: Idempotency-Key milik pengguna lain.'
        USING ERRCODE = 'KC002', HINT = 'Setiap Idempotency-Key terikat eksklusif pada satu actor_id.';
    END IF;

    -- Bandingkan request_snapshot & payload_hash pada SEMUA state (pending, applied, not_applied)
    -- Kecuali baris not_applied yang disegel negatif sebelum request sempat sampai (request_snapshot = '{}')
    IF v_existing.request_snapshot IS DISTINCT FROM '{}'::JSONB THEN
      IF v_existing.payload_hash IS DISTINCT FROM v_hash
         OR v_existing.request_snapshot IS DISTINCT FROM p_request_snapshot THEN
        RAISE EXCEPTION 'IDEMPOTENCY_PAYLOAD_MISMATCH: Payload berbeda untuk Idempotency-Key yang sama.'
          USING ERRCODE = 'KC018', HINT = 'Gunakan Idempotency-Key baru untuk payload mutasi yang berbeda.';
      END IF;
    END IF;

    -- State applied -> REPLAY (Modul D.4)
    IF v_existing.outcome = 'applied' THEN
      RETURN pg_catalog.jsonb_build_object(
        'action', 'REPLAY',
        'response', v_existing.response_snapshot
      );
    END IF;

    -- State not_applied atau sealed -> LATE_SEALED_REQUEST (Modul D.4)
    IF v_existing.outcome = 'not_applied' OR v_existing.sealed = TRUE THEN
      RAISE EXCEPTION 'LATE_SEALED_REQUEST: Permintaan telah disegel sebagai tidak diterapkan.'
        USING ERRCODE = 'KC019', HINT = 'Buat mutasi baru dengan Idempotency-Key baru.';
    END IF;
  END IF;

  RETURN pg_catalog.jsonb_build_object('action', 'EXECUTE');
END;
$$;

-- 5. Fungsi pusat akhir mutasi: fn_finish_mutation (Modul D)
--    Menulis hasil applied dengan guard keras WHERE sealed = FALSE AND outcome = 'pending' AND actor_id = EXCLUDED.actor_id
CREATE OR REPLACE FUNCTION public.fn_finish_mutation(
  p_family public.mutation_family,
  p_request_id TEXT,
  p_actor_id TEXT,
  p_request_snapshot JSONB,
  p_response_snapshot JSONB,
  p_lookup_snapshot JSONB
)
RETURNS VOID
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $$
DECLARE
  v_hash TEXT;
  v_now TIMESTAMPTZ := pg_catalog.timezone('utc', pg_catalog.now());
BEGIN
  PERFORM public.fn_require_service_role();

  IF p_response_snapshot IS NULL OR p_lookup_snapshot IS NULL THEN
    RAISE EXCEPTION 'INVALID_INPUT: response_snapshot dan lookup_snapshot tidak boleh NULL saat menyelesaikan mutasi.'
      USING ERRCODE = 'KC004', HINT = 'Pastikan hasil mutasi dan lookup dibentuk sebelum memanggil fn_finish_mutation.';
  END IF;

  v_hash := public.fn_compute_payload_hash(p_request_snapshot);

  INSERT INTO public.mutation_receipts (
    family, request_id, actor_id, payload_hash, outcome,
    request_snapshot, response_snapshot, lookup_snapshot, sealed, created_at, completed_at
  ) VALUES (
    p_family, p_request_id, p_actor_id, v_hash, 'applied',
    p_request_snapshot, p_response_snapshot, p_lookup_snapshot, TRUE, v_now, v_now
  )
  ON CONFLICT (family, request_id) DO UPDATE SET
    outcome = 'applied',
    response_snapshot = EXCLUDED.response_snapshot,
    lookup_snapshot = EXCLUDED.lookup_snapshot,
    sealed = TRUE,
    completed_at = v_now
  WHERE public.mutation_receipts.sealed = FALSE
    AND public.mutation_receipts.outcome = 'pending'
    AND public.mutation_receipts.actor_id = EXCLUDED.actor_id
    AND public.mutation_receipts.payload_hash = EXCLUDED.payload_hash
    AND public.mutation_receipts.request_snapshot = EXCLUDED.request_snapshot;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'LATE_SEALED_REQUEST: Receipt mutasi telah disegel atau dimodifikasi oleh proses lain.'
      USING ERRCODE = 'KC019', HINT = 'Transaksi dibatalkan karena receipt tidak lagi berstatus pending milik pelaku.';
  END IF;
END;
$$;

-- 6. RPC 0: rpc_register_pending_mutation (Modul D.10)
--    Menyimpan receipt berstatus pending tanpa pernah menimpa request_snapshot pada state apa pun.
CREATE OR REPLACE FUNCTION public.rpc_register_pending_mutation(
  p_family public.mutation_family,
  p_request_id TEXT,
  p_actor_id TEXT,
  p_request_snapshot JSONB,
  p_default_not_applied_lookup JSONB DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $$
DECLARE
  v_existing public.mutation_receipts%ROWTYPE;
  v_hash TEXT;
  v_lookup JSONB;
BEGIN
  PERFORM public.fn_require_service_role();

  IF p_family IS NULL THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_family wajib diisi.'
      USING ERRCODE = 'KC004', HINT = 'Isi p_family dengan nilai enum mutation_family.';
  END IF;

  IF p_actor_id IS NULL OR pg_catalog.btrim(p_actor_id) = '' THEN
    RAISE EXCEPTION 'UNAUTHENTICATED: Identitas pelaku (p_actor_id) wajib diisi.'
      USING ERRCODE = 'KC001', HINT = 'Pastikan sesi pengguna terautentikasi.';
  END IF;

  IF p_request_id IS NULL OR p_request_id !~ '^[a-f0-9]{48}$' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Idempotency-Key (p_request_id) wajib berupa 48 karakter hex huruf kecil.'
      USING ERRCODE = 'KC004', HINT = 'Format p_request_id harus ^[a-f0-9]{48}$.';
  END IF;

  IF p_request_snapshot IS NULL
     OR pg_catalog.jsonb_typeof(p_request_snapshot) IS DISTINCT FROM 'object'
     OR p_request_snapshot = '{}'::JSONB THEN
    RAISE EXCEPTION 'INVALID_INPUT: p_request_snapshot wajib berupa objek JSON non-kosong.'
      USING ERRCODE = 'KC004', HINT = 'Kirim snapshot kanonis dari parameter request.';
  END IF;

  -- Kunci advisory deterministik per (family, request_id)
  PERFORM pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(p_family::TEXT || ':' || p_request_id, 0)
  );

  -- Pastikan aktor aktif & valid
  PERFORM public.fn_require_actor(
    p_actor_id,
    ARRAY['customer', 'owner', 'admin']::public.user_role[],
    FALSE
  );

  v_hash := public.fn_compute_payload_hash(p_request_snapshot);

  SELECT * INTO v_existing
  FROM public.mutation_receipts mr
  WHERE mr.family = p_family AND mr.request_id = p_request_id
  FOR NO KEY UPDATE;

  IF FOUND THEN
    IF v_existing.actor_id IS DISTINCT FROM p_actor_id THEN
      RAISE EXCEPTION 'FORBIDDEN: Idempotency-Key milik pengguna lain.'
        USING ERRCODE = 'KC002', HINT = 'Setiap Idempotency-Key terikat pada satu pengguna.';
    END IF;

    IF v_existing.request_snapshot IS DISTINCT FROM '{}'::JSONB THEN
      IF v_existing.payload_hash IS DISTINCT FROM v_hash
         OR v_existing.request_snapshot IS DISTINCT FROM p_request_snapshot THEN
        RAISE EXCEPTION 'IDEMPOTENCY_PAYLOAD_MISMATCH: Payload berbeda untuk Idempotency-Key yang sama.'
          USING ERRCODE = 'KC018', HINT = 'Jangan mengubah payload untuk Idempotency-Key yang sudah terdaftar.';
      END IF;
    END IF;

    RETURN pg_catalog.jsonb_build_object(
      'outcome', v_existing.outcome::TEXT,
      'sealed', v_existing.sealed,
      'response_snapshot', v_existing.response_snapshot,
      'lookup_snapshot', v_existing.lookup_snapshot
    );
  END IF;

  v_lookup := COALESCE(
    p_default_not_applied_lookup,
    public.fn_build_default_not_applied_lookup(p_family, p_request_id, p_actor_id, p_request_snapshot, FALSE)
  );

  INSERT INTO public.mutation_receipts (
    family, request_id, actor_id, payload_hash, outcome,
    request_snapshot, response_snapshot, lookup_snapshot, sealed, created_at, completed_at
  ) VALUES (
    p_family, p_request_id, p_actor_id, v_hash, 'pending',
    p_request_snapshot, NULL, v_lookup, FALSE, pg_catalog.timezone('utc', pg_catalog.now()), NULL
  );

  INSERT INTO public.audit_events (
    actor_id, operation, target_id, request_id, before_version, after_version, reason, outcome
  ) VALUES (
    p_actor_id, 'register_pending:' || p_family::TEXT, p_request_id, p_request_id, NULL, NULL, NULL, 'pending'
  );

  RETURN pg_catalog.jsonb_build_object(
    'outcome', 'pending',
    'sealed', FALSE,
    'response_snapshot', NULL,
    'lookup_snapshot', v_lookup
  );
END;
$$;

-- 7. RPC 11: rpc_lookup_or_seal_receipt (Modul D.11 & CRIT-04)
--    - Memakai pg_try_advisory_xact_lock: bila sedang dipegang worker mutasi aktif,
--      JANGAN menyegel; kembalikan status pending/in_progress yang jelas.
--    - Saat menyegel pending -> not_applied, perbarui juga JSON lookup_snapshot
--      (outcome -> 'not_applied', serta status -> 'not_created'/'not_submitted' bila relevan).
--    - Untuk p_actor_id IS NULL -> UNAUTHENTICATED.
--    - Untuk request yang belum pernah sampai ke server (baris belum ada & p_fallback_lookup IS NULL):
--      JANGAN melempar NOT_FOUND. Segel sebagai not_applied dengan lookup_snapshot minimal valid
--      dan penanda unseen_sealed = TRUE, serta catat audit_events.
CREATE OR REPLACE FUNCTION public.rpc_lookup_or_seal_receipt(
  p_family public.mutation_family,
  p_request_id TEXT,
  p_actor_id TEXT,
  p_fallback_lookup JSONB DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $$
DECLARE
  v_receipt public.mutation_receipts%ROWTYPE;
  v_lock_acquired BOOLEAN;
  v_updated_lookup JSONB;
  v_empty_hash TEXT;
  v_now TIMESTAMPTZ := pg_catalog.timezone('utc', pg_catalog.now());
BEGIN
  PERFORM public.fn_require_service_role();

  IF p_actor_id IS NULL OR pg_catalog.btrim(p_actor_id) = '' THEN
    RAISE EXCEPTION 'UNAUTHENTICATED: Identitas pelaku (p_actor_id) wajib diisi.'
      USING ERRCODE = 'KC001', HINT = 'Pastikan sesi pengguna terautentikasi saat memanggil lookup.';
  END IF;

  IF p_family IS NULL THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_family wajib diisi.'
      USING ERRCODE = 'KC004', HINT = 'Berikan nilai enum mutation_family yang valid.';
  END IF;

  IF p_request_id IS NULL OR p_request_id !~ '^[a-f0-9]{48}$' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_request_id wajib berupa 48 karakter hex huruf kecil.'
      USING ERRCODE = 'KC004', HINT = 'Format p_request_id harus ^[a-f0-9]{48}$.';
  END IF;

  IF p_fallback_lookup IS NOT NULL AND pg_catalog.jsonb_typeof(p_fallback_lookup) IS DISTINCT FROM 'object' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_fallback_lookup harus berupa objek JSON atau NULL.'
      USING ERRCODE = 'KC004', HINT = 'Kirim objek JSON metadata intent atau biarkan NULL.';
  END IF;

  -- Verifikasi pelaku ada (izinkan lookup oleh pemilik sesi)
  PERFORM public.fn_require_actor(
    p_actor_id,
    ARRAY['customer', 'owner', 'admin']::public.user_role[],
    FALSE
  );

  -- Coba ambil advisory lock tanpa memblokir worker mutasi yang sedang berjalan (Modul D.11)
  v_lock_acquired := pg_catalog.pg_try_advisory_xact_lock(
    pg_catalog.hashtextextended(p_family::TEXT || ':' || p_request_id, 0)
  );

  IF v_lock_acquired IS DISTINCT FROM TRUE THEN
    -- Worker mutasi sedang aktif memegang kunci; jangan menyegel!
    SELECT * INTO v_receipt
    FROM public.mutation_receipts mr
    WHERE mr.family = p_family AND mr.request_id = p_request_id;

    IF FOUND AND v_receipt.actor_id IS DISTINCT FROM p_actor_id THEN
      RAISE EXCEPTION 'FORBIDDEN: Tidak memiliki hak akses atas mutasi ini.'
        USING ERRCODE = 'KC002', HINT = 'Mutasi ini dimiliki oleh pengguna lain.';
    END IF;

    IF FOUND THEN
      v_updated_lookup := pg_catalog.jsonb_set(v_receipt.lookup_snapshot, '{outcome}', '"pending"'::JSONB, TRUE);
      v_updated_lookup := pg_catalog.jsonb_set(v_updated_lookup, '{in_progress}', 'true'::JSONB, TRUE);
      IF p_family IN ('orders', 'canteen-applications') THEN
        v_updated_lookup := pg_catalog.jsonb_set(v_updated_lookup, '{status}', '"pending"'::JSONB, TRUE);
      END IF;
      RETURN v_updated_lookup;
    END IF;

    -- Baris belum terlihat karena transaksi worker belum commit, kembalikan status pending/in_progress
    v_updated_lookup := COALESCE(
      p_fallback_lookup,
      public.fn_build_default_not_applied_lookup(p_family, p_request_id, p_actor_id, '{}'::JSONB, FALSE)
    );
    v_updated_lookup := pg_catalog.jsonb_set(v_updated_lookup, '{outcome}', '"pending"'::JSONB, TRUE);
    v_updated_lookup := pg_catalog.jsonb_set(v_updated_lookup, '{in_progress}', 'true'::JSONB, TRUE);
    IF p_family IN ('orders', 'canteen-applications') THEN
      v_updated_lookup := pg_catalog.jsonb_set(v_updated_lookup, '{status}', '"pending"'::JSONB, TRUE);
    END IF;
    RETURN v_updated_lookup;
  END IF;

  -- Lock berhasil dipegang: periksa apakah baris receipt sudah ada
  SELECT * INTO v_receipt
  FROM public.mutation_receipts mr
  WHERE mr.family = p_family AND mr.request_id = p_request_id
  FOR NO KEY UPDATE;

  IF FOUND THEN
    IF v_receipt.actor_id IS DISTINCT FROM p_actor_id THEN
      RAISE EXCEPTION 'FORBIDDEN: Tidak memiliki hak akses atas mutasi ini.'
        USING ERRCODE = 'KC002', HINT = 'Mutasi ini dimiliki oleh pengguna lain.';
    END IF;

    -- Jika sebelumnya masih 'pending' dan tidak ada worker aktif, segel atomik menjadi 'not_applied'
    IF v_receipt.outcome = 'pending' THEN
      v_updated_lookup := pg_catalog.jsonb_set(v_receipt.lookup_snapshot, '{outcome}', '"not_applied"'::JSONB, TRUE);
      IF p_family = 'orders' THEN
        v_updated_lookup := pg_catalog.jsonb_set(v_updated_lookup, '{status}', '"not_created"'::JSONB, TRUE);
      ELSIF p_family = 'canteen-applications' THEN
        v_updated_lookup := pg_catalog.jsonb_set(v_updated_lookup, '{status}', '"not_submitted"'::JSONB, TRUE);
      END IF;

      UPDATE public.mutation_receipts
      SET outcome = 'not_applied',
          lookup_snapshot = v_updated_lookup,
          sealed = TRUE,
          completed_at = v_now
      WHERE family = p_family AND request_id = p_request_id
      RETURNING * INTO v_receipt;

      INSERT INTO public.audit_events (
        actor_id, operation, target_id, request_id, before_version, after_version, reason, outcome
      ) VALUES (
        p_actor_id, 'seal_pending_receipt:' || p_family::TEXT, p_request_id, p_request_id,
        NULL, NULL, 'Pending receipt sealed on recovery lookup', 'not_applied'
      );
    END IF;

    RETURN v_receipt.lookup_snapshot;
  END IF;

  -- Kasus request belum pernah sampai ke server: segel negatif (family, request_id) sebagai not_applied
  -- tanpa pernah melempar NOT_FOUND (CRIT-04)
  IF p_fallback_lookup IS NOT NULL THEN
    v_updated_lookup := pg_catalog.jsonb_set(p_fallback_lookup, '{outcome}', '"not_applied"'::JSONB, TRUE);
    v_updated_lookup := pg_catalog.jsonb_set(v_updated_lookup, '{unseen_sealed}', 'true'::JSONB, TRUE);
    IF p_family = 'orders' THEN
      v_updated_lookup := pg_catalog.jsonb_set(v_updated_lookup, '{status}', '"not_created"'::JSONB, TRUE);
    ELSIF p_family = 'canteen-applications' THEN
      v_updated_lookup := pg_catalog.jsonb_set(v_updated_lookup, '{status}', '"not_submitted"'::JSONB, TRUE);
    END IF;
  ELSE
    v_updated_lookup := public.fn_build_default_not_applied_lookup(
      p_family, p_request_id, p_actor_id, '{}'::JSONB, TRUE
    );
  END IF;

  v_empty_hash := public.fn_compute_payload_hash('{}'::JSONB);

  INSERT INTO public.mutation_receipts (
    family, request_id, actor_id, payload_hash, outcome,
    request_snapshot, response_snapshot, lookup_snapshot, sealed, created_at, completed_at
  ) VALUES (
    p_family, p_request_id, p_actor_id, v_empty_hash, 'not_applied',
    '{}'::JSONB, NULL, v_updated_lookup, TRUE, v_now, v_now
  );

  INSERT INTO public.audit_events (
    actor_id, operation, target_id, request_id, before_version, after_version, reason, outcome
  ) VALUES (
    p_actor_id, 'seal_unseen_receipt:' || p_family::TEXT, p_request_id, p_request_id,
    NULL, NULL, 'Unseen request sealed on recovery lookup', 'not_applied'
  );

  RETURN v_updated_lookup;
END;
$$;

-- 8. Fungsi pemangkas PII pada mutation_receipts tua tanpa menghapus kunci tombstone (Modul G & MED-22)
CREATE OR REPLACE FUNCTION public.fn_compact_mutation_receipts_pii(
  p_older_than INTERVAL DEFAULT INTERVAL '90 days'
)
RETURNS BIGINT
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $$
DECLARE
  v_cutoff TIMESTAMPTZ;
  v_count BIGINT;
BEGIN
  PERFORM public.fn_require_service_role();

  IF p_older_than IS NULL OR p_older_than < INTERVAL '1 day' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Interval retensi minimal 1 hari.'
      USING ERRCODE = 'KC004', HINT = 'Berikan p_older_than >= 1 day.';
  END IF;

  v_cutoff := pg_catalog.timezone('utc', pg_catalog.now()) - p_older_than;

  -- Aktifkan flag transaksi lokal untuk mengizinkan pemangkasan snapshot pada baris sealed
  PERFORM pg_catalog.set_config('app.allow_pii_compaction', 'on', true);

  UPDATE public.mutation_receipts mr
  SET request_snapshot = pg_catalog.jsonb_build_object('redacted', true, 'compacted_at', public.fn_utc_iso(pg_catalog.timezone('utc', pg_catalog.now()))),
      response_snapshot = CASE
        WHEN mr.outcome = 'applied' THEN pg_catalog.jsonb_build_object('redacted', true)
        ELSE NULL
      END,
      lookup_snapshot = pg_catalog.jsonb_build_object(
        'actor_id', mr.actor_id,
        'mutation_id', mr.request_id,
        'outcome', mr.outcome::TEXT,
        'redacted', true
      )
  WHERE mr.sealed = TRUE
    AND mr.completed_at IS NOT NULL
    AND mr.completed_at < v_cutoff
    AND COALESCE((mr.request_snapshot->>'redacted')::BOOLEAN, FALSE) IS DISTINCT FROM TRUE;

  GET DIAGNOSTICS v_count = ROW_COUNT;

  PERFORM pg_catalog.set_config('app.allow_pii_compaction', 'off', true);

  INSERT INTO public.audit_events (
    actor_id, operation, target_id, request_id, before_version, after_version, reason, outcome
  ) VALUES (
    'system', 'compact_mutation_receipts_pii', 'mutation_receipts', 'system_compaction',
    NULL, NULL, 'Compacted ' || v_count::TEXT || ' sealed receipts older than ' || p_older_than::TEXT, 'applied'
  );

  RETURN v_count;
END;
$$;

-- Pengamanan hak eksekusi fungsi Modul D
REVOKE ALL ON FUNCTION public.fn_compute_payload_hash(JSONB) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_canonical_order_snapshot(TEXT, TEXT, TEXT, BIGINT, TEXT, JSONB) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_canonical_cancellation_snapshot(TEXT, TEXT, TEXT, INTEGER) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_canonical_application_snapshot(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, INTEGER) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_canonical_food_prefs_snapshot(TEXT, TEXT, INTEGER, INTEGER, BOOLEAN, TEXT[]) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_canonical_owner_snapshot(TEXT, TEXT, TEXT, TEXT, TEXT, INTEGER, JSONB) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_canonical_admin_snapshot(TEXT, TEXT, TEXT, TEXT, INTEGER, TEXT, TEXT, BOOLEAN, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_build_default_not_applied_lookup(public.mutation_family, TEXT, TEXT, JSONB, BOOLEAN) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_begin_mutation(public.mutation_family, TEXT, TEXT, JSONB) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_finish_mutation(public.mutation_family, TEXT, TEXT, JSONB, JSONB, JSONB) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.rpc_register_pending_mutation(public.mutation_family, TEXT, TEXT, JSONB, JSONB) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.rpc_lookup_or_seal_receipt(public.mutation_family, TEXT, TEXT, JSONB) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_compact_mutation_receipts_pii(INTERVAL) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.fn_compute_payload_hash(JSONB) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_canonical_order_snapshot(TEXT, TEXT, TEXT, BIGINT, TEXT, JSONB) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_canonical_cancellation_snapshot(TEXT, TEXT, TEXT, INTEGER) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_canonical_application_snapshot(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, INTEGER) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_canonical_food_prefs_snapshot(TEXT, TEXT, INTEGER, INTEGER, BOOLEAN, TEXT[]) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_canonical_owner_snapshot(TEXT, TEXT, TEXT, TEXT, TEXT, INTEGER, JSONB) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_canonical_admin_snapshot(TEXT, TEXT, TEXT, TEXT, INTEGER, TEXT, TEXT, BOOLEAN, TEXT, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_build_default_not_applied_lookup(public.mutation_family, TEXT, TEXT, JSONB, BOOLEAN) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_begin_mutation(public.mutation_family, TEXT, TEXT, JSONB) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_finish_mutation(public.mutation_family, TEXT, TEXT, JSONB, JSONB, JSONB) TO service_role;
GRANT EXECUTE ON FUNCTION public.rpc_register_pending_mutation(public.mutation_family, TEXT, TEXT, JSONB, JSONB) TO service_role;
GRANT EXECUTE ON FUNCTION public.rpc_lookup_or_seal_receipt(public.mutation_family, TEXT, TEXT, JSONB) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_compact_mutation_receipts_pii(INTERVAL) TO service_role;

COMMIT;
