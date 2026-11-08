-- ============================================================================
-- MIGRASI 003: KEAMANAN, PRIVILEGE, RLS ZERO-POLICY, & GUARD SERVICE_ROLE
-- Proyek   : KantinCerdas (Supabase PostgreSQL 15-17)
-- Perbaikan: CRIT-06 (REVOKE EXECUTE, ALTER DEFAULT PRIVILEGES, caller guard),
--            HIGH-12 (REVOKE UPDATE/DELETE/TRUNCATE pada audit_events)
-- ============================================================================
BEGIN;

-- 1. Aktifkan ENABLE + FORCE ROW LEVEL SECURITY pada seluruh tabel di skema public
--    dengan NOL policy untuk anon dan authenticated (Aturan Kerja #7 & Modul B).
ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_config FORCE ROW LEVEL SECURITY;

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users FORCE ROW LEVEL SECURITY;

ALTER TABLE public.stalls ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stalls FORCE ROW LEVEL SECURITY;

ALTER TABLE public.menus ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.menus FORCE ROW LEVEL SECURITY;

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders FORCE ROW LEVEL SECURITY;

ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items FORCE ROW LEVEL SECURITY;

ALTER TABLE public.canteen_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.canteen_applications FORCE ROW LEVEL SECURITY;

ALTER TABLE public.food_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.food_preferences FORCE ROW LEVEL SECURITY;

ALTER TABLE public.mutation_receipts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mutation_receipts FORCE ROW LEVEL SECURITY;

ALTER TABLE public.audit_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_events FORCE ROW LEVEL SECURITY;

ALTER TABLE public.media_assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.media_assets FORCE ROW LEVEL SECURITY;

-- 2. Cabut hak CREATE pada skema public dari PUBLIC, anon, dan authenticated
REVOKE CREATE ON SCHEMA public FROM PUBLIC, anon, authenticated;

-- 3. Amankan ALTER DEFAULT PRIVILEGES pada skema public agar tabel, sequence,
--    dan fungsi baru di migrasi berikutnya otomatis tertutup rapat (CRIT-06)
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE ALL ON TABLES FROM PUBLIC, anon, authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE ALL ON SEQUENCES FROM PUBLIC, anon, authenticated;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
  REVOKE ALL ON FUNCTIONS FROM PUBLIC, anon, authenticated;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_catalog.pg_roles WHERE rolname = 'supabase_admin')
     AND pg_catalog.pg_has_role(CURRENT_USER, 'supabase_admin', 'MEMBER') THEN
    EXECUTE pg_catalog.format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA public REVOKE ALL ON TABLES FROM PUBLIC, anon, authenticated', 'supabase_admin');
    EXECUTE pg_catalog.format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA public REVOKE ALL ON SEQUENCES FROM PUBLIC, anon, authenticated', 'supabase_admin');
    EXECUTE pg_catalog.format('ALTER DEFAULT PRIVILEGES FOR ROLE %I IN SCHEMA public REVOKE ALL ON FUNCTIONS FROM PUBLIC, anon, authenticated', 'supabase_admin');
  END IF;
EXCEPTION
  WHEN insufficient_privilege THEN
    NULL;
END
$$;

-- 4. Cabut seluruh hak pada objek yang sudah ada dari PUBLIC, anon, dan authenticated
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC, anon, authenticated;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC, anon, authenticated;
REVOKE ALL ON ALL ROUTINES IN SCHEMA public FROM PUBLIC, anon, authenticated;

-- 5. Berikan hak minimum yang dibutuhkan kepada service_role saja
GRANT USAGE ON SCHEMA public TO service_role;

GRANT SELECT ON TABLE public.app_config TO service_role;
GRANT SELECT, INSERT, UPDATE ON TABLE public.users TO service_role;
GRANT SELECT, INSERT, UPDATE ON TABLE public.stalls TO service_role;
GRANT SELECT, INSERT, UPDATE ON TABLE public.menus TO service_role;
GRANT SELECT, INSERT, UPDATE ON TABLE public.orders TO service_role;
GRANT SELECT, INSERT ON TABLE public.order_items TO service_role;
GRANT SELECT, INSERT, UPDATE ON TABLE public.canteen_applications TO service_role;
GRANT SELECT, INSERT, UPDATE ON TABLE public.food_preferences TO service_role;
GRANT SELECT, INSERT, UPDATE ON TABLE public.mutation_receipts TO service_role;
GRANT SELECT, INSERT ON TABLE public.audit_events TO service_role;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.media_assets TO service_role;

-- Pastikan UPDATE, DELETE, TRUNCATE pada audit_events & order_items serta DELETE/TRUNCATE
-- pada mutation_receipts dicabut secara eksplisit dari service_role (Modul B & Modul G)
REVOKE UPDATE, DELETE, TRUNCATE ON TABLE public.audit_events FROM PUBLIC, anon, authenticated, service_role;
REVOKE UPDATE, DELETE, TRUNCATE ON TABLE public.order_items FROM PUBLIC, anon, authenticated, service_role;
REVOKE DELETE, TRUNCATE ON TABLE public.mutation_receipts FROM PUBLIC, anon, authenticated, service_role;

GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_gen_entity_id(TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_storage_public_base_url() TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_is_safe_image_url(TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.fn_is_valid_avoid_ingredients(TEXT[]) TO service_role;

COMMIT;
