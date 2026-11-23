# Migrasi Supabase Kantin Cerdas

Gunakan folder `migrations/` ini sebagai sumber SQL kanonis untuk proyek Supabase Cloud baru (v2.0.0). Supabase sudah menyediakan skema `auth` (`auth.users`, `auth.sessions`, `auth.identities`) dan skema `storage` (`storage.buckets`, `storage.objects`). Backend Dart Shelf memakai Supabase Auth untuk akun dan sesi, `user_metadata.display_name` untuk nama profil, dan `app_metadata.kantin_role` untuk peran (`customer`, `owner`, `admin`).

## Urutan Wajib 8 Migrasi Forward-Only

Jalankan secara berurutan (setiap file berjalan dalam satu transaksi `begin; ... commit;`):

1. [`20261118000001_auth_initial.sql`](migrations/20261118000001_auth_initial.sql) — Bucket privat `kantin-avatars` (JPEG <= 2 MiB, policy restrictive backend-only) + 4 RPC auth `service_role`-only (`kc_auth_session_status`, `kc_auth_can_recover_password`, `kc_auth_recovery_link_pending`, `kc_auth_registration_exists`).
2. [`20261118000002_catalog.sql`](migrations/20261118000002_catalog.sql) — Tabel RLS `catalog_stalls`, `catalog_menu_items` + 2 RPC katalog (`kc_catalog_stalls`, `kc_catalog_menu`). *Bergantung pada `auth.users`.*
3. [`20261121000001_owner_stalls_categories_menu.sql`](migrations/20261121000001_owner_stalls_categories_menu.sql) — Bucket privat `kantin-media`, kolom/tabel RLS Owner (`owner_stall_schedules`, `owner_menu_categories`), trigger `trg_guard_catalog_stall_update`, dan 20 fungsi/RPC Owner. *Bergantung pada #2.*
4. [`20261121000002_owner_orders.sql`](migrations/20261121000002_owner_orders.sql) — Tabel RLS `orders`, `order_items`, `order_status_events`, `order_notification_events`, trigger `trg_guard_order_items_immutable`, dan 9 fungsi/RPC order Owner. *Bergantung pada #2 dan #3.*
5. [`20261121000003_customer_cart_checkout_orders.sql`](migrations/20261121000003_customer_cart_checkout_orders.sql) — Tabel RLS `customer_carts`, `customer_cart_items`, `customer_checkout_attempts`, `owner_applications`, sequence `kc_order_number_seq`, dan 21 fungsi/RPC Customer. *Bergantung pada #2, #3, dan #4.*
6. [`20261121000004_admin_module.sql`](migrations/20261121000004_admin_module.sql) — Tabel RLS `admin_action_logs`, trigger `trg_guard_admin_action_logs_immutable`, dan 16 fungsi/RPC Admin. *Bergantung pada #2–#5.*
7. [`20261122000001_ai_food_assistant.sql`](migrations/20261122000001_ai_food_assistant.sql) — Tabel RLS `ai_daily_usage`, `ai_project_daily_usage`, `ai_call_attempts` + 7 fungsi/RPC kuota & pencarian katalog AI (`Asia/Jakarta`). *Bergantung pada #2 dan #3.*
8. [`20261122000002_realtime_and_push_notifications.sql`](migrations/20261122000002_realtime_and_push_notifications.sql) — Tabel RLS `realtime_channel_topics`, `order_realtime_signals`, `user_push_devices`, `order_push_deliveries`, trigger `trg_order_status_events_realtime_signal` pada `public.order_status_events`, trigger `trg_auth_users_realtime_security` pada `auth.users`, dan 14 fungsi/RPC realtime/push. *Bergantung pada #2, #4, dan `auth.users`.*

> **Catatan keamanan:** Seluruh tabel `public.*` mengaktifkan RLS tanpa policy `anon`/`authenticated` (akses eksklusif melalui `service_role` pada backend Shelf), dan seluruh fungsi `SECURITY DEFINER` mengunci `SET search_path = ''`.

## Prosedur Penerapan ke Proyek Supabase Cloud Baru (Manual via SQL Editor)

**JANGAN** pernah menjalankan `tests/fixtures/provider_schema.sql` atau file `tests/*.sql` di proyek Supabase Cloud produksi/staging.

1. Pastikan proyek Supabase Cloud baru dalam kondisi bersih (belum ada migrasi legacy v1.5.5 `20261108*`–`20261114*`).
2. Buka **Supabase Dashboard (proyek baru) → SQL Editor → New query**.
3. Jalankan setiap file di `server/supabase/migrations/` **satu per satu secara berurutan dari #1 sampai #8**. Pastikan tiap eksekusi selesai `Success` (tanpa error) sebelum lanjut ke nomor berikutnya.
4. Verifikasi awal dengan menjalankan [`verify_initial_schema.sql`](verify_initial_schema.sql) (memastikan migrasi #1 dan #2 mengembalikan `siap = true`), lalu verifikasi keberadaan bucket privat `kantin-avatars` dan `kantin-media` di **Storage → Buckets** (keduanya harus **Private**), serta verifikasi trigger `trg_auth_users_realtime_security` terpasang pada `auth.users`.
5. Catat versi terakhir yang berhasil diterapkan (`20261122000002`). Jika tim kelak beralih ke Supabase CLI, sinkronkan tabel `supabase_migrations.schema_migrations` terlebih dahulu sebelum menjalankan `db push`. [Riwayat migrasi Supabase](https://supabase.com/docs/guides/deployment/database-migrations)
6. Lanjutkan konfigurasi **Authentication** di Dashboard:
   - Asymmetric JWT signing key (`ES256`).
   - Redirect URLs allowlist: `id.kantincerdas.oauth://auth/google?kc_state=*` dan `id.kantincerdas.oauth://auth/verify-email`.
   - Email OTP Expiration disamakan dengan `AUTH_RECOVERY_LINK_TTL_SECONDS` (`3600`).
   - SMTP & Google OAuth Web Client ID/Secret (untuk pengujian A1–A4).

## Pengujian Lokal pada PostgreSQL 16 Disposable

Untuk menguji seluruh 8 migrasi dan suite uji SQL secara lokal pada database kosong sekali pakai (selaras `.github/workflows/ci.yml`):

1. Jalankan [`tests/fixtures/provider_schema.sql`](tests/fixtures/provider_schema.sql) (hanya untuk PostgreSQL lokal tanpa layanan Supabase).
2. Terapkan ke-8 file `migrations/*.sql` secara berurutan.
3. Jalankan [`verify_initial_schema.sql`](verify_initial_schema.sql) lalu seluruh suite uji di `tests/` (`auth.sql`, `owner.sql`, `catalog_compat.sql`, `customer.sql`, `admin.sql`, `ai.sql`, `realtime_push.sql`; catatan: `catalog.sql` menguji skema dasar sebelum migrasi Owner #3, sedangkan `catalog_compat.sql` memverifikasi kompatibilitas katalog sesudah migrasi Owner #3). Seluruh data uji di dalam suite dibatalkan (`rollback;`) pada akhir transaksi.
