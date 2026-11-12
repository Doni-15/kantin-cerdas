-- Active: 1794135430745@@aws-0-ap-southeast-1.pooler.supabase.com@5432@postgres@public
BEGIN;

-- 1. Selaraskan fn_is_safe_image_url dengan pola kanonis MediaPaths (hingga 32 char actor + kategori + UUIDv4)
CREATE OR REPLACE FUNCTION public.fn_is_safe_image_url(p_url TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
IMMUTABLE
SET search_path = ''
AS $$
DECLARE
  v_lower TEXT;
BEGIN
  IF p_url IS NULL THEN
    RETURN TRUE;
  END IF;

  IF p_url IS DISTINCT FROM pg_catalog.btrim(p_url) THEN
    RETURN FALSE;
  END IF;
  IF pg_catalog.length(p_url) < 1 OR pg_catalog.length(p_url) > 512 THEN
    RETURN FALSE;
  END IF;

  IF p_url ~ '[\x00-\x20\x7f<">''\\`@]' THEN
    RETURN FALSE;
  END IF;

  v_lower := pg_catalog.lower(p_url);

  IF pg_catalog.strpos(v_lower, '..') > 0
     OR pg_catalog.strpos(v_lower, '%2e') > 0
     OR pg_catalog.strpos(v_lower, '%5c') > 0
     OR pg_catalog.strpos(v_lower, '%2f') > 0 THEN
    RETURN FALSE;
  END IF;

  IF p_url !~ '^https://[a-zA-Z0-9.-]+(:[0-9]{1,5})?/storage/v1/object/public/kantin-media/[a-z0-9_-]{1,32}_(profile_avatar|menu_photo|stall_photo)_[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.(jpg|jpeg|png|webp)$' THEN
    RETURN FALSE;
  END IF;

  RETURN TRUE;
END;
$$;

-- 2. Perketat rpc_update_profile_avatar: wajibkan URL terdaftar di media_assets milik p_actor_id
--    dengan category = 'profile_avatar', dan lepaskan is_referenced pada foto profil lama.
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
  v_old_avatar_url TEXT;
  v_before_version INTEGER;
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

  -- Pastikan URL baru benar-benar terdaftar di media_assets milik p_actor_id dengan kategori profile_avatar
  IF v_clean_url IS NOT NULL THEN
    UPDATE public.media_assets
    SET is_referenced = TRUE,
        updated_at = pg_catalog.timezone('utc', pg_catalog.now())
    WHERE owner_id = p_actor_id
      AND category = 'profile_avatar'
      AND public_url = v_clean_url;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'INVALID_IMAGE_URL: Foto profil belum terdaftar atau bukan milik akun ini.'
        USING ERRCODE = 'KC010', HINT = 'Unggah foto profil melalui POST /v1/media/images terlebih dahulu.';
    END IF;
  END IF;

  v_old_avatar_url := v_user.avatar_url;
  v_before_version := v_user.version;

  UPDATE public.users
  SET avatar_url = v_clean_url,
      version = version + 1,
      updated_at = pg_catalog.timezone('utc', pg_catalog.now())
  WHERE id = p_actor_id
  RETURNING * INTO v_user;

  -- Lepaskan referensi pada avatar lama agar dapat dibersihkan fn_cleanup_orphan_media_assets
  IF v_old_avatar_url IS NOT NULL AND v_old_avatar_url IS DISTINCT FROM v_clean_url THEN
    UPDATE public.media_assets
    SET is_referenced = FALSE,
        updated_at = pg_catalog.timezone('utc', pg_catalog.now())
    WHERE owner_id = p_actor_id
      AND category = 'profile_avatar'
      AND public_url = v_old_avatar_url;
  END IF;

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

COMMIT;