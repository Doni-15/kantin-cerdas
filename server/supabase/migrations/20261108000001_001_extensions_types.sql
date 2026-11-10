-- Active: 1794135430745@@aws-0-ap-southeast-1.pooler.supabase.com@5432@postgres@public
-- ============================================================================
-- MIGRASI 001: EKSTENSI & TIPE ENUM KUSTOM
-- Proyek   : KantinCerdas (Supabase PostgreSQL 15-17)
-- Perbaikan: CRIT-01 (skema extensions eksplisit), MED-20 (enum media-images),
--            LOW-23 (dokumentasi pemetaan gaya penamaan enum)
-- ============================================================================
BEGIN;

-- 1. Pastikan skema extensions tersedia (kompatibel penuh dengan Supabase)
CREATE SCHEMA IF NOT EXISTS extensions;
GRANT USAGE ON SCHEMA extensions TO postgres, anon, authenticated, service_role;

-- 2. Pasang ekstensi wajib secara eksplisit di dalam skema extensions
--    Catatan: Pembuatan ID entitas memakai pg_catalog.gen_random_uuid() bawaan
--    inti PostgreSQL agar tidak bergantung pada search_path ke extensions (CRIT-01).
--    pgcrypto dipasang untuk hashing SHA-256 kanonis (payload_hash), sedangkan
--    pg_trgm dipasang untuk indeks pencarian substring ILIKE (HIGH-16).
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pg_trgm" WITH SCHEMA extensions;

-- 3. Definisi tipe ENUM domain di skema public secara idempoten aman
--    Catatan LOW-23: Nilai enum dipertahankan 100% sesuai kontrak serialisasi
--    klien Flutter (mis. 'notCharged' camelCase, 'order-cancellations' kebab-case,
--    'not_applied' snake_case). Lihat DECISIONS.md untuk tabel pemetaan lengkap.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_type t
    JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public' AND t.typname = 'user_role'
  ) THEN
    CREATE TYPE public.user_role AS ENUM ('customer', 'owner', 'admin');
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_type t
    JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public' AND t.typname = 'menu_category'
  ) THEN
    CREATE TYPE public.menu_category AS ENUM ('rice', 'noodles', 'drinks', 'snacks', 'other');
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_type t
    JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public' AND t.typname = 'order_status'
  ) THEN
    CREATE TYPE public.order_status AS ENUM ('waiting', 'processing', 'ready', 'completed', 'rejected', 'cancelled');
  END IF;
END
$$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_type t
    JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public' AND t.typname = 'order_payment_status'
  ) THEN
    CREATE TYPE public.order_payment_status AS ENUM ('unpaid', 'paid', 'notCharged');
  END IF;
END
$$;

-- Catatan HIGH-15: Nilai 'reviewing' dipertahankan karena menjadi kontrak
-- CanteenApplicationStatus di klien Flutter (canteen_application.dart:6,21).
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_type t
    JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public' AND t.typname = 'application_status'
  ) THEN
    CREATE TYPE public.application_status AS ENUM ('submitted', 'reviewing', 'approved', 'rejected');
  END IF;
END
$$;

-- Perbaikan MED-20: Menambahkan 'media-images' untuk idempotensi POST /v1/media/images
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_type t
    JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public' AND t.typname = 'mutation_family'
  ) THEN
    CREATE TYPE public.mutation_family AS ENUM (
      'orders',
      'order-cancellations',
      'canteen-applications',
      'food-preferences',
      'owner-mutations',
      'admin-mutations',
      'media-images'
    );
  END IF;
END
$$;

-- Pastikan nilai 'media-images' ditambahkan bila tipe mutation_family sudah ada sebelumnya
ALTER TYPE public.mutation_family ADD VALUE IF NOT EXISTS 'media-images';

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_catalog.pg_type t
    JOIN pg_catalog.pg_namespace n ON n.oid = t.typnamespace
    WHERE n.nspname = 'public' AND t.typname = 'mutation_outcome'
  ) THEN
    CREATE TYPE public.mutation_outcome AS ENUM ('pending', 'applied', 'not_applied');
  END IF;
END
$$;

COMMIT;
