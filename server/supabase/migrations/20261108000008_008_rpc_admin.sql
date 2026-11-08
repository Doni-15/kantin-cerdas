-- ============================================================================
-- MIGRASI 008: RPC MUTASI ADMIN (KELOLA AKSES & REVIEW PENGAJUAN STAN)
-- Proyek   : KantinCerdas (Supabase PostgreSQL 15-17)
-- Perbaikan: CRIT-02, CRIT-03, CRIT-05, HIGH-08, HIGH-11, HIGH-12, HIGH-14,
--            MED-18, MED-19
-- ============================================================================
BEGIN;

-- ----------------------------------------------------------------------------
-- 1. RPC 9: POST /v1/admin/users/{userId}/access (rpc_admin_set_user_access)
--    Urutan Lock: advisory(receipt) -> users(ORDER BY id ASC, FOR NO KEY UPDATE) -> stalls(FOR NO KEY UPDATE)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_admin_set_user_access(
  p_actor_id TEXT,
  p_mutation_id TEXT,
  p_target_user_id TEXT,
  p_expected_version INTEGER,
  p_is_active BOOLEAN,
  p_reason TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $$
DECLARE
  v_clean_reason TEXT;
  v_admin public.users%ROWTYPE;
  v_target public.users%ROWTYPE;
  v_stall public.stalls%ROWTYPE;
  v_stall_before_version INTEGER;
  v_req_snapshot JSONB;
  v_decision JSONB;
  v_response JSONB;
  v_lookup JSONB;
BEGIN
  IF p_actor_id IS NULL OR pg_catalog.btrim(p_actor_id) = '' THEN
    RAISE EXCEPTION 'UNAUTHENTICATED: Identitas admin wajib diisi.'
      USING ERRCODE = 'KC001', HINT = 'Pastikan sesi admin terautentikasi.';
  END IF;

  IF p_mutation_id IS NULL OR p_mutation_id !~ '^[a-f0-9]{48}$' THEN
    RAISE EXCEPTION 'INVALID_INPUT: mutation_id wajib berupa 48 karakter hex huruf kecil.'
      USING ERRCODE = 'KC004', HINT = 'Gunakan Idempotency-Key 48 hex yang valid.';
  END IF;

  IF p_target_user_id IS NULL OR pg_catalog.btrim(p_target_user_id) = '' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Identitas pengguna target (p_target_user_id) wajib diisi.'
      USING ERRCODE = 'KC004', HINT = 'Berikan user_id target yang akan diubah aksesnya.';
  END IF;

  IF p_expected_version IS NULL OR p_expected_version < 1 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_expected_version wajib >= 1.'
      USING ERRCODE = 'KC004', HINT = 'Sertakan expected_version pengguna target.';
  END IF;

  IF p_is_active IS NULL THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_is_active tidak boleh NULL.'
      USING ERRCODE = 'KC004', HINT = 'Kirim nilai boolean TRUE atau FALSE untuk p_is_active.';
  END IF;

  -- Validasi alasan wajib 1..300 karakter (MED-19 & Modul E.6)
  v_clean_reason := pg_catalog.btrim(COALESCE(p_reason, ''));
  IF pg_catalog.length(v_clean_reason) < 1 OR pg_catalog.length(v_clean_reason) > 300 THEN
    RAISE EXCEPTION 'INVALID_REASON: Alasan perubahan akses wajib diisi dan maksimal 300 karakter.'
      USING ERRCODE = 'KC007', HINT = 'Berikan alasan perubahan akses antara 1 dan 300 grapheme.';
  END IF;

  IF p_actor_id IS NOT DISTINCT FROM p_target_user_id THEN
    RAISE EXCEPTION 'FORBIDDEN: Admin tidak dapat mengubah status akses akunnya sendiri.'
      USING ERRCODE = 'KC002', HINT = 'Gunakan akun admin lain bila diperlukan.';
  END IF;

  -- Kunci dua baris users dalam urutan ID deterministik (ORDER BY id ASC)
  -- untuk mencegah deadlock AB-BA (40P01) saat dua admin saling menargetkan (HIGH-14 & Modul F)
  PERFORM public.fn_require_service_role();

  PERFORM 1
  FROM public.users u
  WHERE u.id IN (p_actor_id, p_target_user_id)
  ORDER BY u.id ASC
  FOR NO KEY UPDATE;

  SELECT * INTO v_admin
  FROM public.users u
  WHERE u.id = p_actor_id;

  IF NOT FOUND OR v_admin.is_active IS DISTINCT FROM TRUE THEN
    RAISE EXCEPTION 'ACCOUNT_DISABLED: Akun admin tidak ditemukan atau sedang nonaktif.'
      USING ERRCODE = 'KC003', HINT = 'Cabut sesi klien dan arahkan ke halaman login.';
  END IF;

  IF v_admin.role IS DISTINCT FROM 'admin' THEN
    RAISE EXCEPTION 'FORBIDDEN: Hanya admin aktif yang dapat mengubah akses pengguna.'
      USING ERRCODE = 'KC002', HINT = 'Operasi ini memerlukan role admin.';
  END IF;

  SELECT * INTO v_target
  FROM public.users u
  WHERE u.id = p_target_user_id;

  -- Target tidak ditemukan pada operasi tulis -> VERSION_CONFLICT (CRIT-05 & Modul E.11)
  IF NOT FOUND THEN
    RAISE EXCEPTION 'VERSION_CONFLICT: Pengguna target tidak ditemukan.'
      USING ERRCODE = 'KC017', HINT = 'Muat ulang daftar pengguna admin.';
  END IF;

  IF v_target.role IS NOT DISTINCT FROM 'admin' THEN
    RAISE EXCEPTION 'FORBIDDEN: Tidak dapat mengubah akses sesama admin.'
      USING ERRCODE = 'KC002', HINT = 'Akses akun admin tidak dapat diubah melalui endpoint ini.';
  END IF;

  -- Sertakan target_role di dalam v_req_snapshot (CRIT-03 & Modul D.6)
  v_req_snapshot := public.fn_canonical_admin_snapshot(
    p_actor_id,
    p_mutation_id,
    'change_access',
    p_target_user_id,
    p_expected_version,
    v_target.role::TEXT,
    NULL,
    p_is_active,
    NULL,
    v_clean_reason
  );

  v_decision := public.fn_begin_mutation('admin-mutations', p_mutation_id, p_actor_id, v_req_snapshot);
  IF (v_decision->>'action') IS NOT DISTINCT FROM 'REPLAY' THEN
    RETURN v_decision->'response';
  END IF;

  IF v_target.version IS DISTINCT FROM p_expected_version
     OR v_target.is_active IS NOT DISTINCT FROM p_is_active THEN
    RAISE EXCEPTION 'VERSION_CONFLICT: Versi atau status aktif pengguna telah berubah.'
      USING ERRCODE = 'KC017', HINT = 'Muat ulang detail pengguna sebelum mencoba lagi.';
  END IF;

  -- Saat menonaktifkan akun: naikkan session_epoch agar token lama otomatis gugur
  -- dan aktivasi ulang di masa depan tidak menghidupkan kembali sesi lama (HIGH-08 & Modul E.6)
  UPDATE public.users
  SET is_active = p_is_active,
      session_epoch = CASE WHEN p_is_active = FALSE THEN session_epoch + 1 ELSE session_epoch END,
      version = version + 1,
      updated_at = pg_catalog.timezone('utc', pg_catalog.now())
  WHERE id = p_target_user_id
  RETURNING * INTO v_target;

  -- Saat menonaktifkan owner: tutup stan miliknya (stalls.is_open = FALSE) dengan menaikkan version stan
  IF p_is_active = FALSE AND v_target.role = 'owner' THEN
    SELECT * INTO v_stall
    FROM public.stalls s
    WHERE s.owner_id = v_target.id
    FOR NO KEY UPDATE;

    IF FOUND AND v_stall.is_open = TRUE THEN
      v_stall_before_version := v_stall.version;

      UPDATE public.stalls
      SET is_open = FALSE,
          version = version + 1,
          updated_at = pg_catalog.timezone('utc', pg_catalog.now())
      WHERE id = v_stall.id
      RETURNING * INTO v_stall;

      INSERT INTO public.audit_events (
        actor_id, operation, target_id, request_id, before_version, after_version, reason, outcome
      ) VALUES (
        p_actor_id, 'auto_close_stall_on_owner_disable', v_stall.id, p_mutation_id,
        v_stall_before_version, v_stall.version, v_clean_reason, 'applied'
      );
    END IF;
  END IF;

  -- Kembalikan user + version (kompatibel AdminUserRecord) ditambah auth_uid & session_epoch
  -- agar server backend dapat mencabut sesi GoTrue secara instan (Modul E.6)
  v_response := pg_catalog.jsonb_build_object(
    'user', public.fn_user_json(v_target),
    'version', v_target.version,
    'auth_uid', v_target.auth_uid::TEXT,
    'session_epoch', v_target.session_epoch
  );

  v_lookup := pg_catalog.jsonb_build_object(
    'admin_id', p_actor_id,
    'mutation_id', p_mutation_id,
    'kind', 'change_access',
    'target_id', v_target.id,
    'expected_version', p_expected_version,
    'reason', v_clean_reason,
    'is_active', p_is_active,
    'target_role', v_target.role::TEXT,
    'outcome', 'applied',
    'result_version', v_target.version,
    'result_is_active', v_target.is_active,
    'result_role', v_target.role::TEXT
  );

  PERFORM public.fn_finish_mutation(
    'admin-mutations', p_mutation_id, p_actor_id, v_req_snapshot, v_response, v_lookup
  );

  INSERT INTO public.audit_events (
    actor_id, operation, target_id, request_id, before_version, after_version, reason, outcome
  ) VALUES (
    p_actor_id, 'change_access', v_target.id, p_mutation_id,
    p_expected_version, v_target.version, v_clean_reason, 'applied'
  );

  RETURN v_response;
END;
$$;

-- ----------------------------------------------------------------------------
-- 2. RPC 10: POST /v1/admin/applications/{applicationId}/review (rpc_admin_review_application)
--    Urutan Lock: advisory(receipt) -> users(ORDER BY id ASC) -> stalls -> canteen_applications
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_admin_review_application(
  p_actor_id TEXT,
  p_mutation_id TEXT,
  p_application_id TEXT,
  p_expected_version INTEGER,
  p_decision public.application_status,
  p_reason TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $$
DECLARE
  v_clean_reason TEXT;
  v_app_applicant_id TEXT;
  v_admin public.users%ROWTYPE;
  v_applicant public.users%ROWTYPE;
  v_applicant_before_version INTEGER;
  v_app public.canteen_applications%ROWTYPE;
  v_stall_id TEXT := NULL;
  v_req_snapshot JSONB;
  v_decision JSONB;
  v_response JSONB;
  v_lookup JSONB;
BEGIN
  IF p_actor_id IS NULL OR pg_catalog.btrim(p_actor_id) = '' THEN
    RAISE EXCEPTION 'UNAUTHENTICATED: Identitas admin wajib diisi.'
      USING ERRCODE = 'KC001', HINT = 'Pastikan sesi admin terautentikasi.';
  END IF;

  IF p_mutation_id IS NULL OR p_mutation_id !~ '^[a-f0-9]{48}$' THEN
    RAISE EXCEPTION 'INVALID_INPUT: mutation_id wajib berupa 48 karakter hex huruf kecil.'
      USING ERRCODE = 'KC004', HINT = 'Gunakan Idempotency-Key 48 hex yang valid.';
  END IF;

  IF p_application_id IS NULL OR pg_catalog.btrim(p_application_id) = '' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Identitas pengajuan (p_application_id) wajib diisi.'
      USING ERRCODE = 'KC004', HINT = 'Berikan application_id yang akan ditinjau.';
  END IF;

  IF p_expected_version IS NULL OR p_expected_version < 1 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_expected_version wajib >= 1.'
      USING ERRCODE = 'KC004', HINT = 'Sertakan expected_version pengajuan untuk pemeriksaan CAS.';
  END IF;

  IF p_decision IS NULL OR p_decision NOT IN ('approved', 'rejected') THEN
    RAISE EXCEPTION 'INVALID_DECISION: Keputusan hanya boleh approved atau rejected.'
      USING ERRCODE = 'KC008', HINT = 'Pilih approved atau rejected.';
  END IF;

  v_clean_reason := NULLIF(pg_catalog.btrim(COALESCE(p_reason, '')), '');

  -- Perbaikan MED-19 & Modul E.7: approved dengan p_reason tidak kosong -> INVALID_REASON
  IF p_decision = 'approved' AND v_clean_reason IS NOT NULL THEN
    RAISE EXCEPTION 'INVALID_REASON: Keputusan approved tidak boleh menyertakan alasan penolakan.'
      USING ERRCODE = 'KC007', HINT = 'Kosongkan parameter p_reason saat menyetujui pengajuan.';
  END IF;

  IF p_decision = 'rejected' AND (v_clean_reason IS NULL OR pg_catalog.length(v_clean_reason) > 300) THEN
    RAISE EXCEPTION 'INVALID_REASON: Penolakan pengajuan wajib menyertakan alasan maksimal 300 karakter.'
      USING ERRCODE = 'KC007', HINT = 'Berikan alasan penolakan antara 1 dan 300 grapheme.';
  END IF;

  PERFORM public.fn_require_service_role();

  -- Baca applicant_id terlebih dahulu tanpa lock agar kita dapat mengunci users
  -- dalam urutan ID deterministik sebelum mengunci canteen_applications (Modul F)
  SELECT ca.applicant_id INTO v_app_applicant_id
  FROM public.canteen_applications ca
  WHERE ca.id = p_application_id;

  IF NOT FOUND THEN
    -- Periksa terlebih dahulu apakah ini replay dari mutasi yang sudah ada
    v_req_snapshot := public.fn_canonical_admin_snapshot(
      p_actor_id, p_mutation_id, 'review_application', p_application_id,
      p_expected_version, NULL, NULL, NULL, p_decision::TEXT, COALESCE(v_clean_reason, '')
    );
    v_decision := public.fn_begin_mutation('admin-mutations', p_mutation_id, p_actor_id, v_req_snapshot);
    IF (v_decision->>'action') IS NOT DISTINCT FROM 'REPLAY' THEN
      RETURN v_decision->'response';
    END IF;

    PERFORM public.fn_require_actor(p_actor_id, ARRAY['admin']::public.user_role[], FALSE);

    RAISE EXCEPTION 'VERSION_CONFLICT: Pengajuan stan tidak ditemukan.'
      USING ERRCODE = 'KC017', HINT = 'Muat ulang daftar pengajuan stan.';
  END IF;

  -- Sertakan applicant_id secara konsisten di dalam v_req_snapshot (CRIT-03 & Modul D.6)
  v_req_snapshot := public.fn_canonical_admin_snapshot(
    p_actor_id,
    p_mutation_id,
    'review_application',
    p_application_id,
    p_expected_version,
    NULL,
    v_app_applicant_id,
    NULL,
    p_decision::TEXT,
    COALESCE(v_clean_reason, '')
  );

  v_decision := public.fn_begin_mutation('admin-mutations', p_mutation_id, p_actor_id, v_req_snapshot);
  IF (v_decision->>'action') IS NOT DISTINCT FROM 'REPLAY' THEN
    RETURN v_decision->'response';
  END IF;

  -- Kunci baris users (admin dan applicant) dalam urutan ID deterministik (ORDER BY id ASC)
  PERFORM 1
  FROM public.users u
  WHERE u.id IN (p_actor_id, v_app_applicant_id)
  ORDER BY u.id ASC
  FOR NO KEY UPDATE;

  SELECT * INTO v_admin
  FROM public.users u
  WHERE u.id = p_actor_id;

  IF NOT FOUND OR v_admin.is_active IS DISTINCT FROM TRUE THEN
    RAISE EXCEPTION 'ACCOUNT_DISABLED: Akun admin tidak ditemukan atau sedang nonaktif.'
      USING ERRCODE = 'KC003', HINT = 'Cabut sesi klien dan arahkan ke halaman login.';
  END IF;

  IF v_admin.role IS DISTINCT FROM 'admin' THEN
    RAISE EXCEPTION 'FORBIDDEN: Hanya admin aktif yang dapat meninjau pengajuan stan.'
      USING ERRCODE = 'KC002', HINT = 'Operasi ini memerlukan role admin.';
  END IF;

  IF p_actor_id IS NOT DISTINCT FROM v_app_applicant_id THEN
    RAISE EXCEPTION 'FORBIDDEN: Admin tidak dapat meninjau pengajuan milik sendiri.'
      USING ERRCODE = 'KC002', HINT = 'Pengajuan harus ditinjau oleh admin lain.';
  END IF;

  SELECT * INTO v_applicant
  FROM public.users u
  WHERE u.id = v_app_applicant_id;

  IF NOT FOUND OR v_applicant.is_active IS DISTINCT FROM TRUE THEN
    RAISE EXCEPTION 'VERSION_CONFLICT: Akun pemohon tidak ditemukan atau sudah tidak aktif.'
      USING ERRCODE = 'KC017', HINT = 'Muat ulang detail pengajuan dan pengguna.';
  END IF;

  -- Kunci baris canteen_applications sesuai urutan lock global (sesudah users & stalls)
  SELECT * INTO v_app
  FROM public.canteen_applications ca
  WHERE ca.id = p_application_id
  FOR NO KEY UPDATE;

  IF v_app.version IS DISTINCT FROM p_expected_version
     OR v_app.status NOT IN ('submitted', 'reviewing') THEN
    RAISE EXCEPTION 'VERSION_CONFLICT: Versi atau status pengajuan stan telah berubah.'
      USING ERRCODE = 'KC017', HINT = 'Muat ulang daftar pengajuan stan.';
  END IF;

  IF p_decision = 'approved' THEN
    IF v_applicant.role IS DISTINCT FROM 'customer'
       OR EXISTS (SELECT 1 FROM public.stalls s WHERE s.owner_id = v_applicant.id) THEN
      RAISE EXCEPTION 'VERSION_CONFLICT: Pemohon sudah memiliki stan atau bukan lagi berstatus customer.'
        USING ERRCODE = 'KC017', HINT = 'Muat ulang profil pemohon.';
    END IF;

    INSERT INTO public.stalls (
      owner_id, name, block, description, is_open, prep_time_min, version
    ) VALUES (
      v_applicant.id, v_app.name, v_app.location, v_app.description, FALSE, 15, 1
    )
    RETURNING id INTO v_stall_id;

    v_applicant_before_version := v_applicant.version;

    UPDATE public.users
    SET role = 'owner',
        version = version + 1,
        updated_at = pg_catalog.timezone('utc', pg_catalog.now())
    WHERE id = v_applicant.id
    RETURNING * INTO v_applicant;

    -- Catat audit untuk setiap efek samping (pembuatan stan & promosi role — HIGH-12 & Modul E.7)
    INSERT INTO public.audit_events (
      actor_id, operation, target_id, request_id, before_version, after_version, reason, outcome
    ) VALUES
      (p_actor_id, 'create_stall_on_approval', v_stall_id, p_mutation_id, NULL, 1, NULL, 'applied'),
      (p_actor_id, 'promote_user_to_owner', v_applicant.id, p_mutation_id, v_applicant_before_version, v_applicant.version, NULL, 'applied');
  END IF;

  UPDATE public.canteen_applications
  SET status = p_decision,
      reason = CASE WHEN p_decision = 'rejected' THEN v_clean_reason ELSE NULL END,
      reviewed_by = p_actor_id,
      reviewed_at = pg_catalog.timezone('utc', pg_catalog.now()),
      approved_stall_id = v_stall_id,
      version = version + 1,
      updated_at = pg_catalog.timezone('utc', pg_catalog.now())
  WHERE id = p_application_id
  RETURNING * INTO v_app;

  v_response := public.fn_canteen_application_json(v_app);

  v_lookup := pg_catalog.jsonb_build_object(
    'admin_id', p_actor_id,
    'mutation_id', p_mutation_id,
    'kind', 'review_application',
    'target_id', v_app.id,
    'applicant_id', v_app.applicant_id,
    'expected_version', p_expected_version,
    'decision', p_decision::TEXT,
    'reason', COALESCE(v_clean_reason, ''),
    'outcome', 'applied',
    'result_version', v_app.version,
    'result_decision', v_app.status::TEXT,
    'result_role', CASE WHEN p_decision = 'approved' THEN 'owner' ELSE NULL END,
    'approved_stall_id', v_stall_id
  );

  PERFORM public.fn_finish_mutation(
    'admin-mutations', p_mutation_id, p_actor_id, v_req_snapshot, v_response, v_lookup
  );

  INSERT INTO public.audit_events (
    actor_id, operation, target_id, request_id, before_version, after_version, reason, outcome
  ) VALUES (
    p_actor_id, 'review_application:' || p_decision::TEXT, v_app.id, p_mutation_id,
    p_expected_version, v_app.version, v_clean_reason, 'applied'
  );

  RETURN v_response;
END;
$$;

-- Pengamanan hak eksekusi fungsi Modul E (Admin)
REVOKE ALL ON FUNCTION public.rpc_admin_set_user_access(TEXT, TEXT, TEXT, INTEGER, BOOLEAN, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.rpc_admin_review_application(TEXT, TEXT, TEXT, INTEGER, public.application_status, TEXT) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.rpc_admin_set_user_access(TEXT, TEXT, TEXT, INTEGER, BOOLEAN, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.rpc_admin_review_application(TEXT, TEXT, TEXT, INTEGER, public.application_status, TEXT) TO service_role;

COMMIT;
