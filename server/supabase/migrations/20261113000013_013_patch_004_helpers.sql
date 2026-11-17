-- Masalah awalanya sebelum update
-- 1. Di Migrasi 009 (009_read_functions.sql), 
-- seluruh 14 fungsi baca (rpc_get_admin_summary, rpc_list_admin_users, dll.) dideklarasikan sebagai STABLE.
-- 2. Saat PostgREST memanggil fungsi berlabel STABLE, PostgREST otomatis menjalankan transaksi dalam mode READ ONLY.
-- 3. Di dalam fungsi baca tersebut, kita memanggil 
-- public.fn_require_actor(..., FALSE) (dari Migrasi 004), 
-- yang menjalankan SELECT ... FOR SHARE. Di PostgreSQL, 
-- klausa FOR SHARE mengambil row-level lock sehingga ditolak di dalam transaksi READ ONLY (25006).
BEGIN;

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
  ELSIF pg_catalog.current_setting('transaction_read_only', true) = 'on' THEN
    SELECT * INTO v_user
    FROM public.users u
    WHERE u.id = p_actor_id;
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

COMMIT;