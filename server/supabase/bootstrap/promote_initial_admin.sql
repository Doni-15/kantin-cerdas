-- ============================================================================
-- BOOTSTRAP ADMIN PERTAMA
-- Proyek   : KantinCerdas (Supabase PostgreSQL)
-- Dirujuk  : server/supabase/README.md, bagian "Bootstrap Admin Pertama"
-- Tujuan   : Membuat profil publik dan memberi role `admin` kepada akun
--            Supabase Auth yang sudah ada. Dibutuhkan karena registrasi lewat
--            aplikasi hanya menghasilkan role `customer`, dan hanya admin yang
--            dapat menyetujui pengajuan stan.
-- Keamanan : Berkas ini sengaja TIDAK berada di folder migrations/. Fungsi
--            hanya dapat dijalankan oleh `postgres` atau `supabase_admin`
--            (SQL Editor Dashboard / koneksi DBA). `service_role`, `anon`,
--            dan `authenticated` tidak diberi hak EXECUTE, sehingga backend
--            /v1/* tidak dapat membuat admin lewat fungsi ini.
-- Perilaku : - Wajib ada baris di auth.users untuk p_auth_uid.
--            - Bila sudah ada admin aktif, ditolak kecuali
--              p_allow_additional_admin = TRUE.
--            - Aman diulang: bila akun sudah berstatus admin, profilnya
--              dikembalikan tanpa perubahan.
--            - Pembuatan profil memakai public.rpc_register_user_profile,
--              jadi validasi username, nama, dan email sama dengan registrasi
--              lewat aplikasi.
-- ============================================================================
BEGIN;

CREATE OR REPLACE FUNCTION public.bootstrap_promote_initial_admin(
  p_auth_uid UUID,
  p_username TEXT,
  p_name TEXT,
  p_allow_additional_admin BOOLEAN DEFAULT FALSE
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $$
DECLARE
  v_email TEXT;
  v_user public.users%ROWTYPE;
  v_before_version INTEGER;
BEGIN
  IF CURRENT_USER NOT IN ('postgres', 'supabase_admin') THEN
    RAISE EXCEPTION 'FORBIDDEN: Bootstrap admin hanya boleh dijalankan oleh postgres atau supabase_admin.'
      USING ERRCODE = 'KC002';
  END IF;

  IF p_auth_uid IS NULL THEN
    RAISE EXCEPTION 'INVALID_INPUT: p_auth_uid wajib diisi.'
      USING ERRCODE = 'KC004';
  END IF;

  SELECT u.email INTO v_email
  FROM auth.users u
  WHERE u.id = p_auth_uid;

  IF NOT FOUND OR v_email IS NULL OR pg_catalog.btrim(v_email) = '' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Akun dengan UUID % tidak ditemukan di auth.users atau tidak memiliki email.', p_auth_uid
      USING ERRCODE = 'KC004',
            HINT = 'Buat pengguna di Dashboard (Authentication > Users) lalu salin UUID-nya.';
  END IF;

  -- Idempoten: akun ini sudah admin, tidak ada yang diubah.
  SELECT * INTO v_user
  FROM public.users u
  WHERE u.auth_uid = p_auth_uid;

  IF FOUND AND v_user.role = 'admin' AND v_user.is_active THEN
    RETURN public.fn_user_json(v_user);
  END IF;

  IF NOT COALESCE(p_allow_additional_admin, FALSE) AND EXISTS (
    SELECT 1 FROM public.users a WHERE a.role = 'admin' AND a.is_active
  ) THEN
    RAISE EXCEPTION 'INVALID_INPUT: Sudah ada admin aktif. Gunakan p_allow_additional_admin => TRUE bila memang ingin menambah admin.'
      USING ERRCODE = 'KC004';
  END IF;

  -- Membuat profil (atau mengambil yang sudah ada) dengan validasi yang sama
  -- seperti registrasi dari aplikasi. Hasil sementara role = 'customer'.
  PERFORM public.rpc_register_user_profile(p_auth_uid, p_username, v_email, p_name);

  SELECT * INTO v_user
  FROM public.users u
  WHERE u.auth_uid = p_auth_uid
  FOR NO KEY UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'INTERNAL: Profil tidak ditemukan setelah registrasi.'
      USING ERRCODE = 'KC004';
  END IF;

  IF v_user.is_active IS DISTINCT FROM TRUE THEN
    RAISE EXCEPTION 'ACCOUNT_DISABLED: Akun dinonaktifkan; aktifkan dulu sebelum dijadikan admin.'
      USING ERRCODE = 'KC003';
  END IF;

  v_before_version := v_user.version;

  UPDATE public.users
  SET role = 'admin',
      version = version + 1,
      updated_at = pg_catalog.timezone('utc', pg_catalog.now())
  WHERE id = v_user.id
  RETURNING * INTO v_user;

  INSERT INTO public.audit_events (
    actor_id, operation, target_id, request_id, before_version, after_version, reason, outcome
  ) VALUES (
    v_user.id, 'bootstrap_promote_initial_admin', v_user.id,
    'bootstrap_' || p_auth_uid::TEXT, v_before_version, v_user.version,
    'Bootstrap admin pertama oleh DBA', 'applied'
  );

  RETURN public.fn_user_json(v_user);
END;
$$;

REVOKE ALL ON FUNCTION public.bootstrap_promote_initial_admin(UUID, TEXT, TEXT, BOOLEAN)
  FROM PUBLIC, anon, authenticated, service_role;

COMMIT;
