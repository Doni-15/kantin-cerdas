-- ============================================================================
-- MIGRASI 010: STORAGE BUCKET KANTIN-MEDIA & TATA KELOLA MEDIA ASSETS (MODUL J)
-- Proyek   : KantinCerdas (Supabase PostgreSQL 15-17)
-- Perbaikan: HIGH-09 (hapus policy SELECT di storage.objects yang membuka listing),
--            HIGH-10 & MED-20 (registrasi aset media berkuota & pembersihan yatim)
-- ============================================================================
BEGIN;

-- 1. Pastikan konfigurasi bucket 'kantin-media' tetap ada dan terkunci pada
--    batas 2 MB (2.097.152 byte) serta MIME jpeg/png/webp (Larangan #2 & Modul J)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'kantin-media',
  'kantin-media',
  true,
  2097152,
  ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 2097152,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp'];

-- 2. Hapus policy SELECT "Public media access" pada storage.objects yang membuka
--    celah enumerasi seluruh file/actorId kepada anon (HIGH-09).
--    Catatan: public = true pada storage.buckets sudah cukup untuk melayani
--    unduhan URL publik individual tanpa membuka endpoint listing objek!
DO $$
BEGIN
  DROP POLICY IF EXISTS "Public media access" ON storage.objects;
EXCEPTION
  WHEN insufficient_privilege THEN
    NULL;
END
$$;

-- 3. RPC untuk mencatat unggahan media baru (POST /v1/media/images) secara idempoten
--    beserta penegakan kuota per pengguna (maksimal 200 aset per pengguna)
CREATE OR REPLACE FUNCTION public.rpc_register_media_asset(
  p_actor_id TEXT,
  p_mutation_id TEXT,
  p_category TEXT,
  p_object_path TEXT,
  p_public_url TEXT,
  p_mime_type TEXT,
  p_size_bytes INTEGER,
  p_sha256_hex TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $$
DECLARE
  v_asset public.media_assets%ROWTYPE;
  v_asset_count BIGINT;
  v_req_snapshot JSONB;
  v_decision JSONB;
  v_response JSONB;
  v_lookup JSONB;
BEGIN
  IF p_actor_id IS NULL OR pg_catalog.btrim(p_actor_id) = '' THEN
    RAISE EXCEPTION 'UNAUTHENTICATED: Identitas pengunggah wajib diisi.'
      USING ERRCODE = 'KC001', HINT = 'Pastikan sesi pengguna terautentikasi.';
  END IF;

  IF p_mutation_id IS NULL OR p_mutation_id !~ '^[a-f0-9]{48}$' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Idempotency-Key (p_mutation_id) wajib berupa 48 karakter hex huruf kecil.'
      USING ERRCODE = 'KC004', HINT = 'Sertakan header Idempotency-Key 48 hex saat mengunggah gambar.';
  END IF;

  IF p_category IS NULL OR p_category NOT IN ('profile_avatar', 'menu_photo', 'stall_photo') THEN
    RAISE EXCEPTION 'INVALID_INPUT: Kategori media tidak valid.'
      USING ERRCODE = 'KC004', HINT = 'Gunakan profile_avatar, menu_photo, atau stall_photo.';
  END IF;

  IF p_object_path IS NULL
     OR p_object_path !~ '^[a-z0-9_-]{1,32}_(profile_avatar|menu_photo|stall_photo)_[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.(jpg|png|webp)$' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Nama objek media tidak memenuhi pola kanonis aman.'
      USING ERRCODE = 'KC004', HINT = 'Gunakan ImageSecurityValidator.generateSafeFileName().';
  END IF;

  IF p_public_url IS NULL OR NOT public.fn_is_safe_image_url(p_public_url) THEN
    RAISE EXCEPTION 'INVALID_IMAGE_URL: URL publik gambar tidak valid atau bukan dari bucket kantin-media.'
      USING ERRCODE = 'KC010', HINT = 'Pastikan URL mengarah ke /storage/v1/object/public/kantin-media/<file>.';
  END IF;

  IF p_mime_type IS NULL OR p_mime_type NOT IN ('image/jpeg', 'image/png', 'image/webp') THEN
    RAISE EXCEPTION 'INVALID_INPUT: Tipe MIME gambar wajib image/jpeg, image/png, atau image/webp.'
      USING ERRCODE = 'KC004', HINT = 'Validasi Magic Bytes sebelum mengunggah ke Storage.';
  END IF;

  IF p_size_bytes IS NULL OR p_size_bytes < 32 OR p_size_bytes > 2097152 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Ukuran file gambar wajib antara 32 byte dan 2.097.152 byte (2 MB).'
      USING ERRCODE = 'KC004', HINT = 'Kompres gambar agar berukuran maksimal 2 MB.';
  END IF;

  IF p_sha256_hex IS NULL OR p_sha256_hex !~ '^[a-f0-9]{64}$' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Hash SHA-256 file wajib berupa 64 karakter hex huruf kecil.'
      USING ERRCODE = 'KC004', HINT = 'Hitung SHA-256 byte file di backend sebelum registrasi.';
  END IF;

  v_req_snapshot := pg_catalog.jsonb_build_object(
    'actor_id', p_actor_id,
    'mutation_id', p_mutation_id,
    'kind', 'upload_media_asset',
    'category', p_category,
    'size_bytes', p_size_bytes,
    'sha256_hex', p_sha256_hex
  );

  v_decision := public.fn_begin_mutation('media-images', p_mutation_id, p_actor_id, v_req_snapshot);
  IF (v_decision->>'action') IS NOT DISTINCT FROM 'REPLAY' THEN
    RETURN v_decision->'response';
  END IF;

  PERFORM public.fn_require_actor(
    p_actor_id,
    ARRAY['customer', 'owner', 'admin']::public.user_role[],
    TRUE
  );

  SELECT pg_catalog.count(*) INTO v_asset_count
  FROM public.media_assets ma
  WHERE ma.owner_id = p_actor_id;

  IF v_asset_count >= 200 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Kuota penyimpanan media per pengguna telah penuh (maksimal 200 file).'
      USING ERRCODE = 'KC004', HINT = 'Jalankan pembersihan aset yatim terlebih dahulu.';
  END IF;

  INSERT INTO public.media_assets (
    owner_id, category, object_path, public_url, mime_type, size_bytes, sha256_hex, is_referenced
  ) VALUES (
    p_actor_id, p_category, p_object_path, p_public_url, p_mime_type, p_size_bytes, p_sha256_hex, FALSE
  )
  RETURNING * INTO v_asset;

  v_response := pg_catalog.jsonb_build_object(
    'id', v_asset.id,
    'image_url', v_asset.public_url,
    'object_path', v_asset.object_path
  );

  v_lookup := pg_catalog.jsonb_build_object(
    'actor_id', p_actor_id,
    'mutation_id', p_mutation_id,
    'outcome', 'applied',
    'image_url', v_asset.public_url
  );

  PERFORM public.fn_finish_mutation(
    'media-images', p_mutation_id, p_actor_id, v_req_snapshot, v_response, v_lookup
  );

  INSERT INTO public.audit_events (
    actor_id, operation, target_id, request_id, before_version, after_version, reason, outcome
  ) VALUES (
    p_actor_id, 'upload_media_asset:' || p_category, v_asset.id, p_mutation_id, NULL, 1, NULL, 'applied'
  );

  RETURN v_response;
END;
$$;

-- 4. Fungsi pembersih objek media yatim (orphan assets) yang tidak direferensikan
--    oleh users.avatar_url, stalls.image_url, maupun menus.image_url
CREATE OR REPLACE FUNCTION public.fn_cleanup_orphan_media_assets(
  p_older_than INTERVAL DEFAULT INTERVAL '24 hours'
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $$
DECLARE
  v_cutoff TIMESTAMPTZ;
  v_deleted_paths JSONB;
BEGIN
  PERFORM public.fn_require_service_role();

  IF p_older_than IS NULL OR p_older_than < INTERVAL '1 hour' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Umur minimum objek yatim wajib >= 1 jam.'
      USING ERRCODE = 'KC004', HINT = 'Berikan p_older_than >= 1 hour.';
  END IF;

  v_cutoff := pg_catalog.timezone('utc', pg_catalog.now()) - p_older_than;

  WITH deleted AS (
    DELETE FROM public.media_assets ma
    WHERE ma.created_at < v_cutoff
      AND NOT EXISTS (SELECT 1 FROM public.users u WHERE u.avatar_url = ma.public_url)
      AND NOT EXISTS (SELECT 1 FROM public.stalls s WHERE s.image_url = ma.public_url)
      AND NOT EXISTS (SELECT 1 FROM public.menus m WHERE m.image_url = ma.public_url)
    RETURNING ma.object_path
  )
  SELECT COALESCE(pg_catalog.jsonb_agg(d.object_path), '[]'::JSONB)
  INTO v_deleted_paths
  FROM deleted d;

  RETURN pg_catalog.jsonb_build_object(
    'deleted_count', pg_catalog.jsonb_array_length(v_deleted_paths),
    'deleted_object_paths', v_deleted_paths
  );
END;
$$;

REVOKE ALL ON FUNCTION public.rpc_register_media_asset(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, INTEGER, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.fn_cleanup_orphan_media_assets(INTERVAL) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.rpc_register_media_asset(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, INTEGER, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_cleanup_orphan_media_assets(INTERVAL) TO service_role;

COMMIT;
