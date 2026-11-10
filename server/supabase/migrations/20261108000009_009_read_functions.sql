-- Active: 1794135430745@@aws-0-ap-southeast-1.pooler.supabase.com@5432@postgres@public
-- ============================================================================
-- MIGRASI 009: FUNGSI BACA TERPARAMETER & REGISTRASI ATOMIK (MODUL I & K)
-- Proyek   : KantinCerdas (Supabase PostgreSQL 15-17)
-- Perbaikan: HIGH-07 (menutup celah ketiadaan query baca & mencegah SQLi di sumbernya),
--            HIGH-16 (keyset cursor presisi mikrodetik penuh & pencarian trigram),
--            Modul K (sinkronisasi atomik auth.users <-> public.users)
-- ============================================================================
BEGIN;

-- 1. GET /v1/catalog (rpc_get_customer_catalog)
--    Menghasilkan struktur kembar identik 100% antara menus top-level dan stalls[].menus
--    lengkap dengan field turunan stall_name, block, prep_time_min, dan wait_time
--    sesuai CustomerCatalogModel, StallModel, dan MenuItemModel di Flutter.
CREATE OR REPLACE FUNCTION public.rpc_get_customer_catalog(
  p_actor_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $$
DECLARE
  v_menus JSONB;
  v_stalls JSONB;
BEGIN
  PERFORM public.fn_require_actor(
    p_actor_id,
    ARRAY['customer', 'owner']::public.user_role[],
    FALSE
  );

  SELECT COALESCE(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'id', m.id,
        'name', m.name,
        'stall_id', s.id,
        'stall_name', s.name,
        'block', s.block,
        'price_idr', m.price_idr,
        'prep_time_min', s.prep_time_min,
        'wait_time', (s.prep_time_min::TEXT || ' mnt'),
        'description', m.description,
        'category', m.category::TEXT,
        'is_available', (s.is_open AND u.is_active AND m.is_available),
        'image_url', m.image_url
      )
      ORDER BY s.is_open DESC, s.created_at DESC, s.id DESC, m.created_at DESC, m.id DESC
    ),
    '[]'::JSONB
  ) INTO v_menus
  FROM public.menus m
  JOIN public.stalls s ON s.id = m.stall_id
  JOIN public.users u ON u.id = s.owner_id
  WHERE m.deleted_at IS NULL
    AND u.is_active = TRUE;

  SELECT COALESCE(
    pg_catalog.jsonb_agg(
      pg_catalog.jsonb_build_object(
        'id', s.id,
        'name', s.name,
        'block', s.block,
        'prep_time_min', s.prep_time_min,
        'wait_time', (s.prep_time_min::TEXT || ' mnt'),
        'description', s.description,
        'is_open', (s.is_open AND u.is_active),
        'image_url', s.image_url,
        'menus', COALESCE(
          (
            SELECT pg_catalog.jsonb_agg(
              pg_catalog.jsonb_build_object(
                'id', m2.id,
                'name', m2.name,
                'stall_id', s.id,
                'stall_name', s.name,
                'block', s.block,
                'price_idr', m2.price_idr,
                'prep_time_min', s.prep_time_min,
                'wait_time', (s.prep_time_min::TEXT || ' mnt'),
                'description', m2.description,
                'category', m2.category::TEXT,
                'is_available', (s.is_open AND u.is_active AND m2.is_available),
                'image_url', m2.image_url
              )
              ORDER BY m2.created_at DESC, m2.id DESC
            )
            FROM public.menus m2
            WHERE m2.stall_id = s.id AND m2.deleted_at IS NULL
          ),
          '[]'::JSONB
        )
      )
      ORDER BY s.is_open DESC, s.created_at DESC, s.id DESC
    ),
    '[]'::JSONB
  ) INTO v_stalls
  FROM public.stalls s
  JOIN public.users u ON u.id = s.owner_id
  WHERE u.is_active = TRUE;

  RETURN pg_catalog.jsonb_build_object(
    'menus', v_menus,
    'stalls', v_stalls
  );
END;
$$;

-- 2. GET /v1/customer/orders (rpc_list_customer_orders — kursor keyset TIMESTAMPTZ mikrodetik)
CREATE OR REPLACE FUNCTION public.rpc_list_customer_orders(
  p_actor_id TEXT,
  p_history BOOLEAN,
  p_cursor_ts TIMESTAMPTZ DEFAULT NULL,
  p_cursor_id TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 30
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $$
DECLARE
  v_items JSONB := '[]'::JSONB;
  v_rec public.orders%ROWTYPE;
  v_count INTEGER := 0;
  v_last_ts TIMESTAMPTZ := NULL;
  v_last_id TEXT := NULL;
  v_has_more BOOLEAN := FALSE;
  v_next_cursor TEXT := NULL;
BEGIN
  PERFORM public.fn_require_actor(
    p_actor_id,
    ARRAY['customer', 'owner']::public.user_role[],
    FALSE
  );

  IF p_history IS NULL THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_history wajib diisi.'
      USING ERRCODE = 'KC004', HINT = 'Kirim TRUE untuk riwayat atau FALSE untuk pesanan aktif.';
  END IF;

  IF p_limit IS NULL OR p_limit < 1 OR p_limit > 100 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_limit wajib antara 1 dan 100.'
      USING ERRCODE = 'KC004', HINT = 'Gunakan batas halaman 1..100.';
  END IF;

  IF (p_cursor_ts IS NULL) IS DISTINCT FROM (p_cursor_id IS NULL) THEN
    RAISE EXCEPTION 'INVALID_INPUT: Kursor paginasi harus menyertakan p_cursor_ts dan p_cursor_id secara berpasangan.'
      USING ERRCODE = 'KC004', HINT = 'Dekode token kursor menjadi pasangan timestamp dan id.';
  END IF;

  FOR v_rec IN
    SELECT *
    FROM public.orders o
    WHERE o.customer_id = p_actor_id
      AND (
        (p_history = FALSE AND o.status IN ('waiting', 'processing', 'ready'))
        OR (p_history = TRUE AND o.status IN ('completed', 'rejected', 'cancelled'))
      )
      AND (
        p_cursor_ts IS NULL
        OR (o.created_at, o.id) < (p_cursor_ts, p_cursor_id)
      )
    ORDER BY o.created_at DESC, o.id DESC
    LIMIT (p_limit + 1)
  LOOP
    v_count := v_count + 1;
    IF v_count <= p_limit THEN
      v_items := v_items || pg_catalog.jsonb_build_array(public.fn_order_record_json(v_rec));
      v_last_ts := v_rec.created_at;
      v_last_id := v_rec.id;
    ELSE
      v_has_more := TRUE;
    END IF;
  END LOOP;

  IF v_has_more AND v_last_ts IS NOT NULL AND v_last_id IS NOT NULL THEN
    v_next_cursor := public.fn_utc_iso(v_last_ts) || '|' || v_last_id;
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'items', v_items,
    'next_cursor', v_next_cursor
  );
END;
$$;

-- 3. GET /v1/customer/orders/{orderId} (rpc_get_customer_order)
CREATE OR REPLACE FUNCTION public.rpc_get_customer_order(
  p_actor_id TEXT,
  p_order_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $$
DECLARE
  v_order public.orders%ROWTYPE;
BEGIN
  PERFORM public.fn_require_actor(
    p_actor_id,
    ARRAY['customer', 'owner']::public.user_role[],
    FALSE
  );

  IF p_order_id IS NULL OR pg_catalog.btrim(p_order_id) = '' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_order_id wajib diisi.'
      USING ERRCODE = 'KC004', HINT = 'Berikan order_id yang valid.';
  END IF;

  SELECT * INTO v_order
  FROM public.orders o
  WHERE o.id = p_order_id;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  IF v_order.customer_id IS DISTINCT FROM p_actor_id THEN
    RAISE EXCEPTION 'FORBIDDEN: Anda bukan pemilik pesanan ini.'
      USING ERRCODE = 'KC002', HINT = 'Pelanggan hanya dapat membaca pesanannya sendiri.';
  END IF;

  RETURN public.fn_order_record_json(v_order);
END;
$$;

-- 4. GET /v1/customer/canteen-applications/me (rpc_get_my_canteen_application)
CREATE OR REPLACE FUNCTION public.rpc_get_my_canteen_application(
  p_actor_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $$
DECLARE
  v_app public.canteen_applications%ROWTYPE;
BEGIN
  PERFORM public.fn_require_actor(
    p_actor_id,
    ARRAY['customer', 'owner']::public.user_role[],
    FALSE
  );

  SELECT * INTO v_app
  FROM public.canteen_applications ca
  WHERE ca.applicant_id = p_actor_id AND ca.is_latest = TRUE;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  RETURN public.fn_canteen_application_json(v_app);
END;
$$;

-- 5. GET /v1/customer/food-preferences (rpc_get_my_food_preferences)
CREATE OR REPLACE FUNCTION public.rpc_get_my_food_preferences(
  p_actor_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $$
DECLARE
  v_prefs public.food_preferences%ROWTYPE;
BEGIN
  PERFORM public.fn_require_actor(
    p_actor_id,
    ARRAY['customer', 'owner']::public.user_role[],
    FALSE
  );

  SELECT * INTO v_prefs
  FROM public.food_preferences fp
  WHERE fp.customer_id = p_actor_id;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'customer_id', v_prefs.customer_id,
    'version', v_prefs.version,
    'max_budget_idr', v_prefs.max_budget_idr,
    'vegetarian', v_prefs.vegetarian,
    'avoid_ingredients', pg_catalog.to_jsonb(v_prefs.avoid_ingredients)
  );
END;
$$;

-- 6. GET /v1/owner/stall (rpc_get_owner_stall)
CREATE OR REPLACE FUNCTION public.rpc_get_owner_stall(
  p_actor_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $$
DECLARE
  v_stall public.stalls%ROWTYPE;
BEGIN
  PERFORM public.fn_require_actor(
    p_actor_id,
    ARRAY['owner']::public.user_role[],
    FALSE
  );

  SELECT * INTO v_stall
  FROM public.stalls s
  WHERE s.owner_id = p_actor_id;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  RETURN public.fn_owner_stall_json(v_stall);
END;
$$;

-- 7. GET /v1/owner/menus (rpc_list_owner_menus)
CREATE OR REPLACE FUNCTION public.rpc_list_owner_menus(
  p_actor_id TEXT,
  p_stall_id TEXT,
  p_search TEXT DEFAULT '',
  p_available BOOLEAN DEFAULT NULL,
  p_cursor_ts TIMESTAMPTZ DEFAULT NULL,
  p_cursor_id TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 30
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $$
DECLARE
  v_stall public.stalls%ROWTYPE;
  v_clean_search TEXT;
  v_items JSONB := '[]'::JSONB;
  v_rec public.menus%ROWTYPE;
  v_count INTEGER := 0;
  v_last_ts TIMESTAMPTZ := NULL;
  v_last_id TEXT := NULL;
  v_has_more BOOLEAN := FALSE;
  v_next_cursor TEXT := NULL;
BEGIN
  PERFORM public.fn_require_actor(
    p_actor_id,
    ARRAY['owner']::public.user_role[],
    FALSE
  );

  IF p_stall_id IS NULL OR pg_catalog.btrim(p_stall_id) = '' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_stall_id wajib diisi.'
      USING ERRCODE = 'KC004', HINT = 'Berikan stall_id milik owner.';
  END IF;

  IF p_limit IS NULL OR p_limit < 1 OR p_limit > 100 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_limit wajib antara 1 dan 100.'
      USING ERRCODE = 'KC004', HINT = 'Gunakan batas halaman 1..100.';
  END IF;

  IF (p_cursor_ts IS NULL) IS DISTINCT FROM (p_cursor_id IS NULL) THEN
    RAISE EXCEPTION 'INVALID_INPUT: Kursor paginasi harus menyertakan p_cursor_ts dan p_cursor_id secara berpasangan.'
      USING ERRCODE = 'KC004', HINT = 'Dekode token kursor menjadi pasangan timestamp dan id.';
  END IF;

  v_clean_search := pg_catalog.lower(pg_catalog.btrim(COALESCE(p_search, '')));
  IF pg_catalog.length(v_clean_search) > 480 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Kata kunci pencarian melebihi batas maksimum 120 karakter.'
      USING ERRCODE = 'KC004', HINT = 'Pangkas kata kunci pencarian hingga maksimal 120 grapheme.';
  END IF;

  SELECT * INTO v_stall
  FROM public.stalls s
  WHERE s.id = p_stall_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_STALL: Stan tidak ditemukan.'
      USING ERRCODE = 'KC016', HINT = 'Pastikan stan owner terdaftar.';
  END IF;

  IF v_stall.owner_id IS DISTINCT FROM p_actor_id THEN
    RAISE EXCEPTION 'FORBIDDEN: Anda bukan pemilik stan ini.'
      USING ERRCODE = 'KC002', HINT = 'Owner hanya dapat membaca menu dari stannya sendiri.';
  END IF;

  FOR v_rec IN
    SELECT *
    FROM public.menus m
    WHERE m.stall_id = p_stall_id
      AND m.deleted_at IS NULL
      AND (p_available IS NULL OR m.is_available IS NOT DISTINCT FROM p_available)
      AND (
        v_clean_search = ''
        OR pg_catalog.strpos(
          pg_catalog.lower(COALESCE(m.name, '') || ' ' || COALESCE(m.description, '')),
          v_clean_search
        ) > 0
      )
      AND (
        p_cursor_ts IS NULL
        OR (m.created_at, m.id) < (p_cursor_ts, p_cursor_id)
      )
    ORDER BY m.created_at DESC, m.id DESC
    LIMIT (p_limit + 1)
  LOOP
    v_count := v_count + 1;
    IF v_count <= p_limit THEN
      v_items := v_items || pg_catalog.jsonb_build_array(public.fn_owner_menu_json(v_rec));
      v_last_ts := v_rec.created_at;
      v_last_id := v_rec.id;
    ELSE
      v_has_more := TRUE;
    END IF;
  END LOOP;

  IF v_has_more AND v_last_ts IS NOT NULL AND v_last_id IS NOT NULL THEN
    v_next_cursor := public.fn_utc_iso(v_last_ts) || '|' || v_last_id;
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'items', v_items,
    'next_cursor', v_next_cursor
  );
END;
$$;

-- 8. GET /v1/owner/orders (rpc_list_owner_orders)
CREATE OR REPLACE FUNCTION public.rpc_list_owner_orders(
  p_actor_id TEXT,
  p_stall_id TEXT,
  p_status public.order_status DEFAULT NULL,
  p_cursor_ts TIMESTAMPTZ DEFAULT NULL,
  p_cursor_id TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 30
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $$
DECLARE
  v_stall public.stalls%ROWTYPE;
  v_items JSONB := '[]'::JSONB;
  v_rec public.orders%ROWTYPE;
  v_count INTEGER := 0;
  v_last_ts TIMESTAMPTZ := NULL;
  v_last_id TEXT := NULL;
  v_has_more BOOLEAN := FALSE;
  v_next_cursor TEXT := NULL;
BEGIN
  PERFORM public.fn_require_actor(
    p_actor_id,
    ARRAY['owner']::public.user_role[],
    FALSE
  );

  IF p_stall_id IS NULL OR pg_catalog.btrim(p_stall_id) = '' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_stall_id wajib diisi.'
      USING ERRCODE = 'KC004', HINT = 'Berikan stall_id milik owner.';
  END IF;

  IF p_limit IS NULL OR p_limit < 1 OR p_limit > 100 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_limit wajib antara 1 dan 100.'
      USING ERRCODE = 'KC004', HINT = 'Gunakan batas halaman 1..100.';
  END IF;

  IF (p_cursor_ts IS NULL) IS DISTINCT FROM (p_cursor_id IS NULL) THEN
    RAISE EXCEPTION 'INVALID_INPUT: Kursor paginasi harus menyertakan p_cursor_ts dan p_cursor_id secara berpasangan.'
      USING ERRCODE = 'KC004', HINT = 'Dekode token kursor menjadi pasangan timestamp dan id.';
  END IF;

  SELECT * INTO v_stall
  FROM public.stalls s
  WHERE s.id = p_stall_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_STALL: Stan tidak ditemukan.'
      USING ERRCODE = 'KC016', HINT = 'Pastikan stan owner terdaftar.';
  END IF;

  IF v_stall.owner_id IS DISTINCT FROM p_actor_id THEN
    RAISE EXCEPTION 'FORBIDDEN: Anda bukan pemilik stan ini.'
      USING ERRCODE = 'KC002', HINT = 'Owner hanya dapat membaca pesanan dari stannya sendiri.';
  END IF;

  FOR v_rec IN
    SELECT *
    FROM public.orders o
    WHERE o.stall_id = p_stall_id
      AND (p_status IS NULL OR o.status IS NOT DISTINCT FROM p_status)
      AND (
        p_cursor_ts IS NULL
        OR (o.created_at, o.id) < (p_cursor_ts, p_cursor_id)
      )
    ORDER BY o.created_at DESC, o.id DESC
    LIMIT (p_limit + 1)
  LOOP
    v_count := v_count + 1;
    IF v_count <= p_limit THEN
      v_items := v_items || pg_catalog.jsonb_build_array(public.fn_order_record_json(v_rec));
      v_last_ts := v_rec.created_at;
      v_last_id := v_rec.id;
    ELSE
      v_has_more := TRUE;
    END IF;
  END LOOP;

  IF v_has_more AND v_last_ts IS NOT NULL AND v_last_id IS NOT NULL THEN
    v_next_cursor := public.fn_utc_iso(v_last_ts) || '|' || v_last_id;
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'items', v_items,
    'next_cursor', v_next_cursor
  );
END;
$$;

-- 9. GET /v1/owner/orders/{orderId} (rpc_get_owner_order)
CREATE OR REPLACE FUNCTION public.rpc_get_owner_order(
  p_actor_id TEXT,
  p_stall_id TEXT,
  p_order_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $$
DECLARE
  v_stall public.stalls%ROWTYPE;
  v_order public.orders%ROWTYPE;
BEGIN
  PERFORM public.fn_require_actor(
    p_actor_id,
    ARRAY['owner']::public.user_role[],
    FALSE
  );

  IF p_stall_id IS NULL OR pg_catalog.btrim(p_stall_id) = ''
     OR p_order_id IS NULL OR pg_catalog.btrim(p_order_id) = '' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_stall_id dan p_order_id wajib diisi.'
      USING ERRCODE = 'KC004', HINT = 'Berikan stall_id dan order_id yang valid.';
  END IF;

  SELECT * INTO v_stall
  FROM public.stalls s
  WHERE s.id = p_stall_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'NO_STALL: Stan tidak ditemukan.'
      USING ERRCODE = 'KC016', HINT = 'Pastikan stan owner terdaftar.';
  END IF;

  IF v_stall.owner_id IS DISTINCT FROM p_actor_id THEN
    RAISE EXCEPTION 'FORBIDDEN: Anda bukan pemilik stan ini.'
      USING ERRCODE = 'KC002', HINT = 'Owner hanya dapat membaca pesanan dari stannya sendiri.';
  END IF;

  SELECT * INTO v_order
  FROM public.orders o
  WHERE o.id = p_order_id AND o.stall_id = p_stall_id;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  RETURN public.fn_order_record_json(v_order);
END;
$$;

-- 10. GET /v1/admin/summary (rpc_get_admin_summary)
CREATE OR REPLACE FUNCTION public.rpc_get_admin_summary(
  p_actor_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $$
DECLARE
  v_users BIGINT;
  v_stalls BIGINT;
  v_open_stalls BIGINT;
  v_pending_apps BIGINT;
  v_active_orders BIGINT;
BEGIN
  PERFORM public.fn_require_actor(
    p_actor_id,
    ARRAY['admin']::public.user_role[],
    FALSE
  );

  SELECT pg_catalog.count(*) INTO v_users FROM public.users;
  SELECT pg_catalog.count(*) INTO v_stalls FROM public.stalls;
  SELECT pg_catalog.count(*) INTO v_open_stalls FROM public.stalls s WHERE s.is_open = TRUE;
  SELECT pg_catalog.count(*) INTO v_pending_apps
  FROM public.canteen_applications ca
  WHERE ca.status IN ('submitted', 'reviewing');
  SELECT pg_catalog.count(*) INTO v_active_orders
  FROM public.orders o
  WHERE o.status IN ('waiting', 'processing', 'ready');

  RETURN pg_catalog.jsonb_build_object(
    'users', v_users,
    'stalls', v_stalls,
    'open_stalls', v_open_stalls,
    'pending_applications', v_pending_apps,
    'active_orders', v_active_orders
  );
END;
$$;

-- 11. GET /v1/admin/users (rpc_list_admin_users)
CREATE OR REPLACE FUNCTION public.rpc_list_admin_users(
  p_actor_id TEXT,
  p_search TEXT DEFAULT '',
  p_cursor_ts TIMESTAMPTZ DEFAULT NULL,
  p_cursor_id TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 30
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $$
DECLARE
  v_clean_search TEXT;
  v_users JSONB := '[]'::JSONB;
  v_rec public.users%ROWTYPE;
  v_count INTEGER := 0;
  v_last_ts TIMESTAMPTZ := NULL;
  v_last_id TEXT := NULL;
  v_has_more BOOLEAN := FALSE;
  v_next_cursor TEXT := NULL;
BEGIN
  PERFORM public.fn_require_actor(
    p_actor_id,
    ARRAY['admin']::public.user_role[],
    FALSE
  );

  IF p_limit IS NULL OR p_limit < 1 OR p_limit > 100 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_limit wajib antara 1 dan 100.'
      USING ERRCODE = 'KC004', HINT = 'Gunakan batas halaman 1..100.';
  END IF;

  IF (p_cursor_ts IS NULL) IS DISTINCT FROM (p_cursor_id IS NULL) THEN
    RAISE EXCEPTION 'INVALID_INPUT: Kursor paginasi harus menyertakan p_cursor_ts dan p_cursor_id secara berpasangan.'
      USING ERRCODE = 'KC004', HINT = 'Dekode token kursor menjadi pasangan timestamp dan id.';
  END IF;

  v_clean_search := pg_catalog.lower(pg_catalog.btrim(COALESCE(p_search, '')));
  IF pg_catalog.length(v_clean_search) > 480 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Kata kunci pencarian melebihi batas maksimum 120 karakter.'
      USING ERRCODE = 'KC004', HINT = 'Pangkas kata kunci pencarian hingga maksimal 120 grapheme.';
  END IF;

  FOR v_rec IN
    SELECT *
    FROM public.users u
    WHERE (
      v_clean_search = ''
      OR pg_catalog.strpos(
        pg_catalog.lower(COALESCE(u.username, '') || ' ' || COALESCE(u.name, '') || ' ' || COALESCE(u.email, '')),
        v_clean_search
      ) > 0
    )
    AND (
      p_cursor_ts IS NULL
      OR (u.created_at, u.id) < (p_cursor_ts, p_cursor_id)
    )
    ORDER BY u.created_at DESC, u.id DESC
    LIMIT (p_limit + 1)
  LOOP
    v_count := v_count + 1;
    IF v_count <= p_limit THEN
      v_users := v_users || pg_catalog.jsonb_build_array(public.fn_user_json(v_rec));
      v_last_ts := v_rec.created_at;
      v_last_id := v_rec.id;
    ELSE
      v_has_more := TRUE;
    END IF;
  END LOOP;

  IF v_has_more AND v_last_ts IS NOT NULL AND v_last_id IS NOT NULL THEN
    v_next_cursor := public.fn_utc_iso(v_last_ts) || '|' || v_last_id;
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'users', v_users,
    'next_cursor', v_next_cursor
  );
END;
$$;

-- 12. GET /v1/admin/users/{userId} (rpc_get_admin_user)
CREATE OR REPLACE FUNCTION public.rpc_get_admin_user(
  p_actor_id TEXT,
  p_target_user_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $$
DECLARE
  v_user public.users%ROWTYPE;
BEGIN
  PERFORM public.fn_require_actor(
    p_actor_id,
    ARRAY['admin']::public.user_role[],
    FALSE
  );

  IF p_target_user_id IS NULL OR pg_catalog.btrim(p_target_user_id) = '' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_target_user_id wajib diisi.'
      USING ERRCODE = 'KC004', HINT = 'Berikan user_id yang valid.';
  END IF;

  SELECT * INTO v_user
  FROM public.users u
  WHERE u.id = p_target_user_id;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'user', public.fn_user_json(v_user),
    'version', v_user.version
  );
END;
$$;

-- 13. GET /v1/admin/applications (rpc_list_admin_applications)
CREATE OR REPLACE FUNCTION public.rpc_list_admin_applications(
  p_actor_id TEXT,
  p_status public.application_status DEFAULT NULL,
  p_cursor_ts TIMESTAMPTZ DEFAULT NULL,
  p_cursor_id TEXT DEFAULT NULL,
  p_limit INTEGER DEFAULT 30
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $$
DECLARE
  v_items JSONB := '[]'::JSONB;
  v_rec public.canteen_applications%ROWTYPE;
  v_count INTEGER := 0;
  v_last_ts TIMESTAMPTZ := NULL;
  v_last_id TEXT := NULL;
  v_has_more BOOLEAN := FALSE;
  v_next_cursor TEXT := NULL;
BEGIN
  PERFORM public.fn_require_actor(
    p_actor_id,
    ARRAY['admin']::public.user_role[],
    FALSE
  );

  IF p_limit IS NULL OR p_limit < 1 OR p_limit > 100 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_limit wajib antara 1 dan 100.'
      USING ERRCODE = 'KC004', HINT = 'Gunakan batas halaman 1..100.';
  END IF;

  IF (p_cursor_ts IS NULL) IS DISTINCT FROM (p_cursor_id IS NULL) THEN
    RAISE EXCEPTION 'INVALID_INPUT: Kursor paginasi harus menyertakan p_cursor_ts dan p_cursor_id secara berpasangan.'
      USING ERRCODE = 'KC004', HINT = 'Dekode token kursor menjadi pasangan timestamp dan id.';
  END IF;

  FOR v_rec IN
    SELECT *
    FROM public.canteen_applications ca
    WHERE (p_status IS NULL OR ca.status IS NOT DISTINCT FROM p_status)
      AND (
        p_cursor_ts IS NULL
        OR (ca.created_at, ca.id) < (p_cursor_ts, p_cursor_id)
      )
    ORDER BY ca.created_at DESC, ca.id DESC
    LIMIT (p_limit + 1)
  LOOP
    v_count := v_count + 1;
    IF v_count <= p_limit THEN
      v_items := v_items || pg_catalog.jsonb_build_array(public.fn_canteen_application_json(v_rec));
      v_last_ts := v_rec.created_at;
      v_last_id := v_rec.id;
    ELSE
      v_has_more := TRUE;
    END IF;
  END LOOP;

  IF v_has_more AND v_last_ts IS NOT NULL AND v_last_id IS NOT NULL THEN
    v_next_cursor := public.fn_utc_iso(v_last_ts) || '|' || v_last_id;
  END IF;

  RETURN pg_catalog.jsonb_build_object(
    'items', v_items,
    'next_cursor', v_next_cursor
  );
END;
$$;

-- 14. GET /v1/admin/applications/{applicationId} (rpc_get_admin_application)
CREATE OR REPLACE FUNCTION public.rpc_get_admin_application(
  p_actor_id TEXT,
  p_application_id TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
STABLE
SET search_path = ''
AS $$
DECLARE
  v_app public.canteen_applications%ROWTYPE;
BEGIN
  PERFORM public.fn_require_actor(
    p_actor_id,
    ARRAY['admin']::public.user_role[],
    FALSE
  );

  IF p_application_id IS NULL OR pg_catalog.btrim(p_application_id) = '' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Parameter p_application_id wajib diisi.'
      USING ERRCODE = 'KC004', HINT = 'Berikan application_id yang valid.';
  END IF;

  SELECT * INTO v_app
  FROM public.canteen_applications ca
  WHERE ca.id = p_application_id;

  IF NOT FOUND THEN
    RETURN NULL;
  END IF;

  RETURN public.fn_canteen_application_json(v_app);
END;
$$;

-- 15. Registrasi profil atomik (Modul K: sinkronisasi auth.users <-> public.users)
--     Selalu menetapkan role = 'customer', is_active = TRUE, version = 1, session_epoch = 1.
CREATE OR REPLACE FUNCTION public.rpc_register_user_profile(
  p_auth_uid UUID,
  p_username TEXT,
  p_email TEXT,
  p_name TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
VOLATILE
SET search_path = ''
AS $$
DECLARE
  v_clean_username TEXT;
  v_clean_email TEXT;
  v_clean_name TEXT;
  v_username_key TEXT;
  v_email_key TEXT;
  v_user public.users%ROWTYPE;
BEGIN
  PERFORM public.fn_require_service_role();

  IF p_auth_uid IS NULL OR p_username IS NULL OR p_email IS NULL OR p_name IS NULL THEN
    RAISE EXCEPTION 'INVALID_INPUT: Seluruh parameter registrasi (auth_uid, username, email, name) wajib diisi.'
      USING ERRCODE = 'KC004', HINT = 'Lengkapi data registrasi pengguna.';
  END IF;

  v_clean_username := pg_catalog.btrim(p_username);
  v_clean_email := pg_catalog.btrim(p_email);
  v_clean_name := pg_catalog.btrim(p_name);
  v_username_key := pg_catalog.lower(v_clean_username);
  v_email_key := pg_catalog.lower(v_clean_email);

  IF pg_catalog.length(v_clean_username) < 3
     OR pg_catalog.length(v_clean_username) > 20
     OR v_clean_username !~ '^[a-zA-Z0-9._]+$' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Username wajib 3-20 karakter alfanumerik, titik, atau underscore.'
      USING ERRCODE = 'KC004', HINT = 'Periksa format username.';
  END IF;

  IF pg_catalog.length(v_clean_email) < 3
     OR pg_catalog.length(v_clean_email) > 254
     OR v_clean_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' THEN
    RAISE EXCEPTION 'INVALID_INPUT: Format alamat email tidak valid.'
      USING ERRCODE = 'KC004', HINT = 'Periksa format email.';
  END IF;

  IF pg_catalog.length(v_clean_name) < 1 OR pg_catalog.length(v_clean_name) > 480 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Nama pengguna wajib antara 1 dan 120 karakter.'
      USING ERRCODE = 'KC004', HINT = 'Periksa panjang nama pengguna.';
  END IF;

  -- Kunci advisory pada username_key dan email_key agar pesan konflik deterministik
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('reg_user:' || v_username_key, 0));
  PERFORM pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtextextended('reg_email:' || v_email_key, 0));

  IF EXISTS (SELECT 1 FROM public.users u WHERE u.auth_uid = p_auth_uid) THEN
    SELECT * INTO v_user FROM public.users u WHERE u.auth_uid = p_auth_uid;
    RETURN public.fn_user_json(v_user);
  END IF;

  IF EXISTS (SELECT 1 FROM public.users u WHERE u.username_key = v_username_key) THEN
    RAISE EXCEPTION 'INVALID_INPUT: USERNAME_TAKEN: Username sudah digunakan.'
      USING ERRCODE = 'KC004', HINT = 'Pilih username lain yang belum terdaftar.';
  END IF;

  IF EXISTS (SELECT 1 FROM public.users u WHERE u.email_key = v_email_key) THEN
    RAISE EXCEPTION 'INVALID_INPUT: EMAIL_TAKEN: Email sudah digunakan.'
      USING ERRCODE = 'KC004', HINT = 'Gunakan alamat email lain.';
  END IF;

  INSERT INTO public.users (
    auth_uid, username, username_key, email, email_key, name, role, is_active, session_epoch, version
  ) VALUES (
    p_auth_uid, v_clean_username, v_username_key, v_clean_email, v_email_key, v_clean_name,
    'customer', TRUE, 1, 1
  )
  RETURNING * INTO v_user;

  INSERT INTO public.audit_events (
    actor_id, operation, target_id, request_id, before_version, after_version, reason, outcome
  ) VALUES (
    v_user.id, 'register_user_profile', v_user.id, v_user.id, NULL, 1, NULL, 'applied'
  );

  RETURN public.fn_user_json(v_user);
END;
$$;

-- Pengamanan hak eksekusi fungsi Modul I & K
REVOKE ALL ON FUNCTION public.rpc_get_customer_catalog(TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.rpc_list_customer_orders(TEXT, BOOLEAN, TIMESTAMPTZ, TEXT, INTEGER) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.rpc_get_customer_order(TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.rpc_get_my_canteen_application(TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.rpc_get_my_food_preferences(TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.rpc_get_owner_stall(TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.rpc_list_owner_menus(TEXT, TEXT, TEXT, BOOLEAN, TIMESTAMPTZ, TEXT, INTEGER) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.rpc_list_owner_orders(TEXT, TEXT, public.order_status, TIMESTAMPTZ, TEXT, INTEGER) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.rpc_get_owner_order(TEXT, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.rpc_get_admin_summary(TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.rpc_list_admin_users(TEXT, TEXT, TIMESTAMPTZ, TEXT, INTEGER) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.rpc_get_admin_user(TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.rpc_list_admin_applications(TEXT, public.application_status, TIMESTAMPTZ, TEXT, INTEGER) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.rpc_get_admin_application(TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.rpc_register_user_profile(UUID, TEXT, TEXT, TEXT) FROM PUBLIC, anon, authenticated;

GRANT EXECUTE ON FUNCTION public.rpc_get_customer_catalog(TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.rpc_list_customer_orders(TEXT, BOOLEAN, TIMESTAMPTZ, TEXT, INTEGER) TO service_role;
GRANT EXECUTE ON FUNCTION public.rpc_get_customer_order(TEXT, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.rpc_get_my_canteen_application(TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.rpc_get_my_food_preferences(TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.rpc_get_owner_stall(TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.rpc_list_owner_menus(TEXT, TEXT, TEXT, BOOLEAN, TIMESTAMPTZ, TEXT, INTEGER) TO service_role;
GRANT EXECUTE ON FUNCTION public.rpc_list_owner_orders(TEXT, TEXT, public.order_status, TIMESTAMPTZ, TEXT, INTEGER) TO service_role;
GRANT EXECUTE ON FUNCTION public.rpc_get_owner_order(TEXT, TEXT, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.rpc_get_admin_summary(TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.rpc_list_admin_users(TEXT, TEXT, TIMESTAMPTZ, TEXT, INTEGER) TO service_role;
GRANT EXECUTE ON FUNCTION public.rpc_get_admin_user(TEXT, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.rpc_list_admin_applications(TEXT, public.application_status, TIMESTAMPTZ, TEXT, INTEGER) TO service_role;
GRANT EXECUTE ON FUNCTION public.rpc_get_admin_application(TEXT, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.rpc_register_user_profile(UUID, TEXT, TEXT, TEXT) TO service_role;

COMMIT;
