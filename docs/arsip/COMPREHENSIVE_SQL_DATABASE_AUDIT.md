# COMPREHENSIVE SQL DATABASE AUDIT — PRODUCTION READINESS ASSESSMENT

**Objek Audit Utama:** `supabase_schema_complete.sql` (1.807 baris, 64.139 byte)  
**Basis Pembanding (Kontrak & Kode Sumber):**
- Spesifikasi Backend & Kamus Data: `docs/backend/SPESIFIKASI_BACKEND.md`, `docs/backend/KAMUS_DATA.md`, `docs/backend/PETA_INTEGRASI_FILE.md`
- Dokumentasi Sistem: `README.md`, `docs/01_MULAI_DAN_SIMULASI.md`, `docs/02_ARSITEKTUR_DAN_ATURAN.md`, `docs/03_UI_UX.md`, `docs/04_STATUS_DAN_PENGUJIAN.md`
- Kode Sumber Klien Produksi (Flutter): `app/lib/**` & `app/pubspec.yaml`
- Harness Referensi & Pengujian: `app/test/**` & `.github/workflows/**`

**Lingkungan Verifikasi Empiris:** PostgreSQL 16.x terisolasi (ephemeral container `--rm`, simulasi lingkungan Vanilla PostgreSQL & Supabase PostgreSQL dengan skema `auth`, `storage`, `extensions`, serta role `anon`, `authenticated`, `service_role`). Tidak ada perubahan yang dilakukan pada file sumber proyek.  
**Tanggal Audit:** 8 November 2026  

---

## 1. Executive Summary

Audit teknis menyeluruh telah dilakukan secara paralel terhadap rancangan database `supabase_schema_complete.sql` menggunakan empat jalur pemeriksaan independen (Arsitektur & Spesifikasi, Kontrak Klien Flutter, Integritas Skema/Konkurensi/Performa PL/pgSQL, serta Keamanan/Data Dummy/Kesiapan Operasional Produksi) yang diperkuat dengan **pengujian eksekusi empiris pada PostgreSQL 16 terisolasi**.

Secara permukaan, `supabase_schema_complete.sql` terlihat terstruktur: tidak memuat data dummy/seed pengujian, mendefinisikan 7 tipe `ENUM`, 9 tabel relasional, mengaktifkan Row Level Security (RLS), menyediakan 14 indeks, serta mengimplementasikan 3 fungsi helper dan 12 fungsi RPC transaksional (`PL/pgSQL`) untuk mutasi bisnis dan idempotensi.

Namun, pengujian mendalam berbasis bukti membuktikan bahwa **SQL ini gagal memenuhi syarat kelayakan produksi dan mengandung cacat kritis yang menyebabkan kegagalan fungsi inti, kerusakan integritas data finansial, bypass kontrol konkurensi (CAS), kebocoran otorisasi lintas pengguna, serta penguncian permanen (*permanent deadlock*) pada aplikasi klien Flutter**.

### Ringkasan Kuantitatif Temuan Audit

| Klasifikasi | Jumlah Temuan | Ringkasan Risiko Utama |
| :--- | :---: | :--- |
| **CRITICAL** | **6** | (1) `rpc_create_customer_order` gagal 100% saat runtime di Supabase akibat `SET search_path = public` menyembunyikan `extensions.gen_random_bytes(8)`; (2) Celah Three-Valued Logic (`NULL`) mengizinkan pesanan Rp 50.000 tercatat sebagai `total_price_idr = 1`, mem-bypass CAS di 6 RPC, mem-bypass konfirmasi serah-terima pembayaran, serta menyegel & membocorkan receipt milik pengguna lain; (3) Race condition `ON CONFLICT DO UPDATE` tanpa `WHERE` menimpa receipt yang sudah disegel (`not_applied`) dan menimpa `request_snapshot` saat `pending`; (4) Deadlock permanen jurnal pemulihan klien (`404 NOT_FOUND`) pada `rpc_lookup_or_seal_receipt` untuk 4 dari 6 keluarga mutasi serta korupsi `lookup_snapshot`; (5) Ketidakcocokan fatal `CHECK` constraint (`canteen_applications`, `order_items.note`) dan error `NOT_FOUND` pada RPC mutasi yang melumpuhkan klien Flutter; (6) Absennya `REVOKE EXECUTE` pada fungsi & `ALTER DEFAULT PRIVILEGES` pada skema `public` dengan parameter `p_actor_id TEXT` tanpa ikatan identitas `auth.uid()` / *caller guard*. |
| **HIGH** | **10** | (7) Ketiadaan seluruh server HTTP `backend/` (`/v1/*`) meskipun diklaim selesai di dokumentasi; (8) 7 RPC mutasi tidak memeriksa `users.is_active` & `users.role` di dalam transaksi tulis + stan milik owner nonaktif tetap buka + sesi JWT lama tidak dicabut saat ban; (9) Kebocoran enumerasi seluruh objek & ID pengguna pada bucket `kantin-media` akibat policy `SELECT` di `storage.objects`; (10) Kolom `avatar_url`/`image_url` tanpa validasi memicu *Persistent Catalog/Admin DoS* (*Poison-Pill Record*) & injeksi beacon eksternal; (11) Deadlock pintu masuk sistem karena tidak ada prosedur *bootstrap* `admin` awal maupun proteksi admin aktif terakhir; (12) `audit_events` tidak benar-benar *append-only* dan absen pada 50% RPC mutasi; (13) Overflow 32-bit `INTEGER` pada `orders.total_price_idr` & `v_computed_total`; (14) Deadlock AB-BA (`40P01`) pada `rpc_admin_set_user_access` & inkonsistensi urutan lock; (15) Ketiadaan Foreign Key `order_items.menu_id`, konflik `ON DELETE CASCADE` pada `users.auth_uid`, dan celah invarian status `canteen_applications`; (16) Ketidakcocokan indeks keyset cursor, pemotongan presisi mikrodetik `.MS` pada `fn_utc_iso`, ketidakcocokan GIN `to_tsvector` terhadap pencarian substring, & ketiadaan indeks FK penuh. |
| **MEDIUM** | **6** | (17) Entropi PK acak 64-bit (`gen_random_bytes(8)`) memicu fragmentasi B-tree & risiko tabrakan tanpa mekanisme retry; (18) Celah penyimpanan padding spasi tak terbatas pada `CHECK (length(btrim(col)))`, ketiadaan normalisasi elemen `avoid_ingredients`, & perbedaan hitungan *grapheme cluster* vs *Unicode code point*; (19) Bug validasi RPC Admin (`p_reason` non-kosong pada `approved` & `reason > 300` pada `set_user_access`) yang merusak deserialisasi recovery klien; (20) Ketiadaan RPC `PUT /v1/auth/profile/avatar` (kenaikan `users.version`) & celah `Idempotency-Key` untuk unggah media; (21) Ketiadaan trigger `updated_at` otomatis, `BIGSERIAL` vs `GENERATED ALWAYS AS IDENTITY`, & pembakaran nomor urut `order_number_seq` sebelum validasi; (22) Ketergantungan penuh pada skema internal Supabase tanpa transaksi migrasi terkelola (`supabase/migrations/`), potensi MVCC bloat pada `mutation_receipts`, & syarat wajib PITR (`RPO = 0`). |
| **LOW** | **2** | (23) Inkonsistensi penamaan nilai `ENUM` (`notCharged` camelCase vs `not_applied` snake_case vs `order-cancellations` kebab-case), ketiadaan `created_at` pada `food_preferences`, & komentar header salah hitung (`8 TABEL` padahal 9 tabel); (24) Indeks duplikat 100% `idx_order_items_order_pos` terhadap `uq_order_items_position` & query ulang redundan di `fn_order_record_json`. |
| **INFORMATIONAL** | **2** | (25) Ketidaksinkronan dokumentasi (`docs/04_STATUS_DAN_PENGUJIAN.md` & typo `cancelled` vs `applied` di `SPESIFIKASI_BACKEND.md`); (26) Catatan distribusi APK simulasi (`Simulasi123!`) pada pipeline rilis CD `.github/workflows/cd-release.yml`. |

**Kesimpulan Awal:** Keputusan audit adalah **`NOT PRODUCTION READY`**. File SQL ini belum layak digunakan sebagai fondasi database production sebelum seluruh blocker `CRITICAL` dan `HIGH` diperbaiki serta diverifikasi ulang bersama layer server backend `/v1/*`.

---

## 2. Database Inventory

### 2.1 Inventarisasi File SQL & Artefak Terkait di Repositori

| Path File | Ukuran / Baris | Status Git | Peran Artefak |
| :--- | :--- | :--- | :--- |
| `supabase_schema_complete.sql` | 64.139 B / 1.807 baris | Untracked (`??`) | Monolitik DDL skema database, RLS, indeks, fungsi helper, 12 RPC PL/pgSQL, dan konfigurasi bucket Storage. |
| `backend/` *(direktori)* | **TIDAK ADA** | Tidak ditemukan | Diklaim ada di `docs/04_STATUS_DAN_PENGUJIAN.md:16,23`, namun **absen sepenuhnya** di working tree maupun seluruh riwayat cabang Git. |
| `supabase/` *(direktori)* | **TIDAK ADA** | Tidak ditemukan | Diklaim ada di `docs/04_STATUS_DAN_PENGUJIAN.md:16,26`, namun **absen sepenuhnya** di repositori. |

### 2.2 Identifikasi Target DBMS & Ekosistem

- **Target DBMS:** PostgreSQL 15 / 16 / 17 yang di-host di dalam ekosistem **Supabase** (bukan PostgreSQL standar mandiri).
- **Ketergantungan Eksternal Wajib di luar File SQL:**
  1. Ekstensi `pgcrypto` (baris 10) untuk `gen_random_bytes(8)`.
  2. Skema `auth` dan tabel `auth.users(id UUID)` milik Supabase GoTrue (baris 54).
  3. Skema `storage` beserta tabel `storage.buckets` dan `storage.objects` milik Supabase Storage (baris 1791–1806).
  4. Database roles bawaan Supabase: `anon`, `authenticated`, dan `service_role` (baris 234, 246–247).

### 2.3 Daftar Tipe Data Kustom (`ENUM`) & Sequence

| Nama Komponen | Jenis | Lokasi Baris | Definisi Nilai / Konfigurasi |
| :--- | :--- | :--- | :--- |
| `public.user_role` | `ENUM` | L12–14 | `'customer'`, `'owner'`, `'admin'` |
| `public.menu_category` | `ENUM` | L16–18 | `'rice'`, `'noodles'`, `'drinks'`, `'snacks'`, `'other'` |
| `public.order_status` | `ENUM` | L20–22 | `'waiting'`, `'processing'`, `'ready'`, `'completed'`, `'rejected'`, `'cancelled'` |
| `public.order_payment_status` | `ENUM` | L24–26 | `'unpaid'`, `'paid'`, `'notCharged'` |
| `public.application_status` | `ENUM` | L28–30 | `'submitted'`, `'reviewing'`, `'approved'`, `'rejected'` |
| `public.mutation_family` | `ENUM` | L32–41 | `'orders'`, `'order-cancellations'`, `'canteen-applications'`, `'food-preferences'`, `'owner-mutations'`, `'admin-mutations'` |
| `public.mutation_outcome` | `ENUM` | L43–45 | `'pending'`, `'applied'`, `'not_applied'` |
| `public.order_number_seq` | `SEQUENCE` | L116 | `START 101` (tipe default `BIGINT`, `INCREMENT 1`, `CACHE 1`) |
| `public.audit_events_id_seq` | `SEQUENCE` *(implisit)* | L220 | Dibuat otomatis oleh kolom `id BIGSERIAL` pada `public.audit_events` |

### 2.4 Daftar Seluruh Tabel, Primary Key, Foreign Key, & Constraint

> [!NOTE]
> Komentar pada `supabase_schema_complete.sql` baris 48 menulis `(8 TABEL)`, padahal skema mendefinisikan **9 tabel** di skema `public`.

| No | Tabel (`public.*`) | Baris | Primary Key & Mekanisme ID | Foreign Keys (`ON DELETE` / `ON UPDATE`) | `UNIQUE` & `CHECK` Constraints Eksplisit |
| :---: | :--- | :--- | :--- | :--- | :--- |
| 1 | `users` | L52–75 | `id TEXT` (`DEFAULT 'usr_' \|\| hex(8B)`) | `auth_uid UUID -> auth.users(id)` (`ON DELETE CASCADE`, `ON UPDATE NO ACTION`) | `UNIQUE(auth_uid)`, `UNIQUE(username_key)`, `UNIQUE(email_key)`, `version >= 1`, `chk_users_updated_at`, `chk_users_username_format` (`3..20`, `^[a-zA-Z0-9._]+$`), `chk_users_email_length` (`3..254`), `chk_users_name_length` (`1..120`), `chk_users_keys_lowercase` |
| 2 | `stalls` | L78–94 | `id TEXT` (`DEFAULT 'stl_' \|\| hex(8B)`) | `owner_id TEXT -> public.users(id)` (`ON DELETE RESTRICT`) | `UNIQUE(owner_id)`, `prep_time_min BETWEEN 1 AND 180`, `version >= 1`, `chk_stalls_updated_at`, `chk_stalls_name_length` (`1..120`), `chk_stalls_block_length` (`1..120`), `chk_stalls_desc_length` (`<= 1000`) |
| 3 | `menus` | L97–113 | `id TEXT` (`DEFAULT 'mnu_' \|\| hex(8B)`) | `stall_id TEXT -> public.stalls(id)` (`ON DELETE RESTRICT`) | `price_idr BETWEEN 1 AND 10000000`, `version >= 1`, `chk_menus_updated_at`, `chk_menus_name_length` (`1..120`), `chk_menus_desc_length` (`<= 1000`) |
| 4 | `orders` | L118–141 | `id TEXT` (`DEFAULT 'ord_' \|\| hex(8B)`) | `customer_id -> users(id)` (`RESTRICT`), `stall_id -> stalls(id)` (`RESTRICT`) | `UNIQUE(order_number)`, `total_price_idr >= 1`, `version >= 1`, `chk_orders_updated_at`, `chk_orders_note_length` (`<= 300`), `chk_orders_payment_consistency` |
| 5 | `order_items` | L143–154 | Composite `(order_id, menu_id)` | `order_id -> orders(id)` (`RESTRICT`); **`menu_id` TANPA FK!** | `uq_order_items_position UNIQUE(order_id, position)`, `position >= 0`, `quantity BETWEEN 1 AND 99`, `unit_price_idr BETWEEN 1 AND 10000000`, `chk_order_items_note_length` (`<= 200`) |
| 6 | `canteen_applications` | L157–185 | `id TEXT` (`DEFAULT 'app_' \|\| hex(8B)`) | `applicant_id -> users(id)` (`RESTRICT`), `previous_id -> canteen_applications(id)` (`RESTRICT`), `reviewed_by -> users(id)` (`RESTRICT`), `approved_stall_id -> stalls(id)` (`RESTRICT`) | `UNIQUE(approved_stall_id)`, `version >= 1`, `chk_applications_updated_at`, `chk_applications_fields` (`name 3..80`, `desc 10..500`, `loc 2..120`, `phone 8..20`), `chk_applications_reason_consistency` |
| 7 | `food_preferences` | L188–196 | `customer_id TEXT` | `customer_id -> users(id)` (`ON DELETE CASCADE`) | `max_budget_idr IS NULL OR BETWEEN 1 AND 10000000`, `version >= 1`, `chk_food_prefs_ingredients_limit` (`cardinality <= 20`) |
| 8 | `mutation_receipts` | L199–216 | Composite `(family, request_id)` | `actor_id -> users(id)` (`ON DELETE RESTRICT`) | `request_id ~ '^[a-f0-9]{48}$'`, `chk_mutation_receipts_sealed_consistency` |
| 9 | `audit_events` | L219–230 | `id BIGSERIAL` | **0 Foreign Keys** | Hanya `NOT NULL` pada `actor_id`, `operation`, `target_id`, `request_id`, `outcome`, `occurred_at` |

### 2.5 Peta Relasi Entitas Database (ERD)

```mermaid
erDiagram
    AUTH_USERS["auth.users (Supabase)"] ||--|| USERS : "auth_uid (CASCADE)"
    USERS ||--o| STALLS : "owner_id (RESTRICT, UNIQUE)"
    USERS ||--o| FOOD_PREFERENCES : "customer_id (CASCADE, PK)"
    USERS ||--o{ ORDERS : "customer_id (RESTRICT)"
    USERS ||--o{ CANTEEN_APPLICATIONS : "applicant_id (RESTRICT)"
    USERS ||--o{ CANTEEN_APPLICATIONS : "reviewed_by (RESTRICT)"
    USERS ||--o{ MUTATION_RECEIPTS : "actor_id (RESTRICT)"
    STALLS ||--o{ MENUS : "stall_id (RESTRICT)"
    STALLS ||--o{ ORDERS : "stall_id (RESTRICT)"
    STALLS |o--o| CANTEEN_APPLICATIONS : "approved_stall_id (RESTRICT, UNIQUE)"
    ORDERS ||--|{ ORDER_ITEMS : "order_id (RESTRICT)"
    MENUS ||..o{ ORDER_ITEMS : "menu_id (LOGICAL ONLY - NO FK!)"
    CANTEEN_APPLICATIONS |o--o{ CANTEEN_APPLICATIONS : "previous_id (RESTRICT)"
```

### 2.6 Daftar Indeks Eksplisit (14 Indeks)

| Nama Indeks | Tabel | Baris | Tipe & Ekspresi Kolom | Predikat Parsial (`WHERE`) |
| :--- | :--- | :--- | :--- | :--- |
| `idx_users_admin_cursor` | `users` | L252–253 | B-Tree `(created_at DESC, id DESC)` | — |
| `idx_users_search` | `users` | L254–255 | GIN `to_tsvector('simple', username \|\| ' ' \|\| name \|\| ' ' \|\| email)` | — |
| `idx_stalls_open_cursor` | `stalls` | L257–258 | B-Tree `(is_open DESC, created_at DESC, id DESC)` | — |
| `idx_menus_stall_cursor` | `menus` | L260–262 | B-Tree `(stall_id, created_at DESC, id DESC)` | `WHERE deleted_at IS NULL` |
| `idx_menus_stall_active` | `menus` | L263–265 | B-Tree `(stall_id, is_available, id)` | `WHERE deleted_at IS NULL` |
| `idx_menus_search` | `menus` | L266–268 | GIN `to_tsvector('simple', name \|\| ' ' \|\| description)` | `WHERE deleted_at IS NULL` |
| `idx_orders_customer_cursor` | `orders` | L270–271 | B-Tree `(customer_id, created_at DESC, id DESC)` | — |
| `idx_orders_customer_status_cursor` | `orders` | L272–273 | B-Tree `(customer_id, status, created_at DESC, id DESC)` | — |
| `idx_orders_stall_cursor` | `orders` | L274–275 | B-Tree `(stall_id, status, created_at DESC, id DESC)` | — |
| `idx_order_items_order_pos` | `order_items` | L276–277 | B-Tree `(order_id, position ASC)` | — *(Duplikat 100% dari `uq_order_items_position`)* |
| `idx_canteen_applications_latest_per_applicant` | `canteen_applications` | L279–281 | **UNIQUE** B-Tree `(applicant_id)` | `WHERE is_latest = TRUE` |
| `idx_canteen_applications_admin_cursor` | `canteen_applications` | L282–283 | B-Tree `(status, created_at DESC, id DESC)` | — |
| `idx_mutation_receipts_actor` | `mutation_receipts` | L285–286 | B-Tree `(actor_id, created_at DESC)` | — |
| `idx_audit_events_target` | `audit_events` | L287–288 | B-Tree `(target_id, occurred_at DESC)` | — |

### 2.7 Daftar Fungsi Helper, RPC, Trigger, View, RLS, & Storage

- **Views:** `0` (Tidak ada `VIEW` atau `MATERIALIZED VIEW`).
- **Triggers:** `0` (Tidak ada `TRIGGER` sama sekali di seluruh skema).
- **Procedures (`CREATE PROCEDURE`):** `0`.
- **RLS & Grants (`public`):**
  - `ENABLE ROW LEVEL SECURITY` pada seluruh 9 tabel `public.*` dengan **0 policy** pada skema `public` (L236–244).
  - `REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon, authenticated;` (L246).
  - `REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM anon, authenticated;` (L247).
  - **TIDAK ADA `REVOKE` pada `FUNCTIONS` / `ROUTINES` maupun `ALTER DEFAULT PRIVILEGES`.**
- **Storage Configuration:**
  - `INSERT INTO storage.buckets` untuk bucket `'kantin-media'` (`public = true`, `file_size_limit = 2097152`, `allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp']`) (L1791–1802).
  - Policy `"Public media access"` pada `storage.objects` (`FOR SELECT USING (bucket_id = 'kantin-media')`) (L1804–1807).
- **Functions (15 Fungsi = 3 Helper + 12 Transactional RPC):**

| Nama Fungsi (`public.*`) | Baris | Bahasa / Volatilitas | Security Mode | `search_path` | Peran / Kontrak Endpoint |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `fn_utc_iso(TIMESTAMPTZ)` | L294–301 | `sql` / `IMMUTABLE STRICT` | `INVOKER` | `public` | Format waktu ke ISO-8601 UTC (`YYYY-MM-DD"T"HH24:MI:SS.MS"Z"`). |
| `fn_order_record_json(TEXT)` | L303–351 | `plpgsql` / `STABLE` | `INVOKER` | `public` | Proyeksi JSON `orders` + array `order_items`. |
| `fn_canteen_application_json(...)` | L353–371 | `sql` / `IMMUTABLE STRICT` | `INVOKER` | `public` | Proyeksi JSON `canteen_applications`. |
| `rpc_register_pending_mutation(...)` | L378–426 | `plpgsql` / `VOLATILE` | `INVOKER` | `public` | Pra-registrasi receipt idempotensi berstatus `'pending'`. |
| `rpc_create_customer_order(...)` | L429–582 | `plpgsql` / `VOLATILE` | `INVOKER` | `public` | `POST /v1/customer/orders` (Checkout atomik). |
| `rpc_cancel_customer_order(...)` | L585–684 | `plpgsql` / `VOLATILE` | `INVOKER` | `public` | `POST /v1/customer/orders/{orderId}/cancel`. |
| `rpc_submit_canteen_application(...)` | L687–803 | `plpgsql` / `VOLATILE` | `INVOKER` | `public` | `POST /v1/customer/canteen-applications`. |
| `rpc_save_food_preferences(...)` | L806–917 | `plpgsql` / `VOLATILE` | `INVOKER` | `public` | `PUT /v1/customer/food-preferences`. |
| `rpc_owner_save_stall(...)` | L920–1040 | `plpgsql` / `VOLATILE` | `INVOKER` | `public` | `PUT /v1/owner/stall`. |
| `rpc_owner_save_menu(...)` | L1043–1182 | `plpgsql` / `VOLATILE` | `INVOKER` | `public` | `POST /v1/owner/menus` & `PUT /v1/owner/menus/{id}`. |
| `rpc_owner_delete_menu(...)` | L1185–1282 | `plpgsql` / `VOLATILE` | `INVOKER` | `public` | `DELETE /v1/owner/menus/{id}` (Soft-delete + tombstone). |
| `rpc_owner_transition_order(...)` | L1285–1429 | `plpgsql` / `VOLATILE` | `INVOKER` | `public` | `POST /v1/owner/orders/{orderId}/transition`. |
| `rpc_admin_set_user_access(...)` | L1432–1565 | `plpgsql` / `VOLATILE` | `INVOKER` | `public` | `POST /v1/admin/users/{userId}/access`. |
| `rpc_admin_review_application(...)` | L1568–1718 | `plpgsql` / `VOLATILE` | `INVOKER` | `public` | `POST /v1/admin/applications/{applicationId}/review`. |
| `rpc_lookup_or_seal_receipt(...)` | L1721–1786 | `plpgsql` / `VOLATILE` | `INVOKER` | `public` | `GET /v1/operations/{family}/{requestId}`. |

---

## 3. Schema & Architecture Assessment

### 3.1 Arsitektur 3-Tier & Ketiadaan Server Backend (`backend/`)
Berdasarkan pemeriksaan silang atas `app/pubspec.yaml` (menggunakan `dio`, **tanpa** SDK `supabase_flutter`), `SPESIFIKASI_BACKEND.md:174–180,470–471`, dan `supabase_schema_complete.sql:233–248`, sistem dirancang sebagai **arsitektur 3-tier**:
1. **Klien Flutter (`app/`)** berkomunikasi murni lewat REST HTTP JSON & multipart `/v1/*`.
2. **Server Backend Kustom (`backend/`)** bertugas memverifikasi token sesi, memvalidasi binary gambar (*magic bytes*), mengeksekusi query baca/paginasi, dan memanggil RPC database menggunakan kredensial `service_role`.
3. **Database Supabase (`supabase_schema_complete.sql`)** bertindak sebagai lapisan persistensi dan transaksi atomik.

> [!CAUTION]
> **Kesenjangan Kritis Repositori vs Dokumentasi:** Dokumen `docs/04_STATUS_DAN_PENGUJIAN.md` (baris 16, 23–26, 90) menulis bahwa direktori `backend/` (server Dart `shelf` + `supabase`) dan `supabase/` *"telah disiapkan dan lulus `dart analyze`"*. Faktanya, **direktori `backend/` maupun `supabase/` sama sekali tidak ada di repositori maupun riwayat Git**. Tanpa server perantara `/v1/*`, skema SQL ini (yang sengaja memblokir akses langsung `anon`/`authenticated` melalui RLS zero-policy) **tidak dapat digunakan secara langsung oleh aplikasi Flutter**.

### 3.2 Evaluasi Primary Key, Tipe Data, & Penamaan
1. **Kegagalan Runtime `gen_random_bytes(8)` pada Supabase (`CRITICAL` — Terbukti Empiris):**
   - Di Supabase PostgreSQL, ekstensi `pgcrypto` sudah terpasang secara bawaan di dalam skema `extensions` (`extensions.gen_random_bytes`). Perintah `CREATE EXTENSION IF NOT EXISTS "pgcrypto";` (L10) hanya menghasilkan `NOTICE: extension "pgcrypto" already exists, skipping` dan **tidak** memindahkan fungsi tersebut ke `public`.
   - Seluruh 15 fungsi di file ini menyetel `SET search_path = public` (tanpa `extensions`). Saat `rpc_create_customer_order` mengeksekusi baris 499 (`v_order_id := 'ord_' || encode(gen_random_bytes(8), 'hex');`), PostgreSQL gagal menemukan fungsi tersebut dan melempar:
     `ERROR: function gen_random_bytes(integer) does not exist (SQLSTATE 42883)`.
   - Artinya, **fitur utama pemesanan pelanggan gagal 100% pada runtime Supabase**.
2. **Entropi 64-Bit & Fragmentasi B-Tree pada Primary Key (`MEDIUM`):**
   - `gen_random_bytes(8)` hanya menyediakan ruang acak 64-bit ($2^{64}$) tanpa mekanisme *retry* saat terjadi benturan, serta menghasilkan distribusi acak seragam (*non-monotonic*) pada indeks PK `TEXT` sepanjang 20 karakter (`'ord_'` + 16 hex). Pada skala transaksi tinggi, hal ini memicu *B-tree page splits* (~50% *fill factor*), amplifikasi WAL, dan overhead perbandingan kolasi teks dibanding `UUIDv7` (128-bit berurutan waktu) atau minimal 128-bit hex dengan `COLLATE "C"`.
   - Kolom `id` pada kelima tabel entitas juga tidak memiliki `CHECK` format prefix (sehingga string kosong `''` atau ID salah prefix seperti `'stl_...'` dapat masuk ke `users.id`).
3. **Penggunaan `INTEGER` 32-Bit pada Nilai Total Finansial (`HIGH` — Terbukti Empiris):**
   - `menus.price_idr` mengizinkan hingga `10.000.000` (L103) dan `order_items.quantity` mengizinkan hingga `99` (L148), sehingga 1 baris item mencapai `990.000.000`. Hanya dengan **3 item** dalam satu pesanan, total harga mencapai `2.970.000.000` — melampaui batas atas `INTEGER` 32-bit (`2.147.483.647`) pada `orders.total_price_idr` (L127) dan `v_computed_total` (L446, L530), memicu crash `ERROR: integer out of range (SQLSTATE 22003)`.
4. **Penggunaan `BIGSERIAL` vs `GENERATED ALWAYS AS IDENTITY` (`MEDIUM`):**
   - `audit_events.id` (L220) memakai `BIGSERIAL` (makro `DEFAULT nextval(...)`), bukan standar SQL `BIGINT GENERATED ALWAYS AS IDENTITY`. Ini mengizinkan `INSERT` menyuntikkan nilai `id` manual yang merusak sinkronisasi sequence dan urutan kronologis log audit.
5. **Konsistensi Penamaan & Kelengkapan Kolom (`LOW`):**
   - Penamaan tabel dan kolom sudah konsisten menggunakan `snake_case`, namun nilai `ENUM` mencampur tiga gaya: `camelCase` (`'notCharged'` pada L25), `kebab-case` (`'order-cancellations'` pada L35), dan `snake_case` (`'not_applied'` pada L44).
   - Tabel `food_preferences` (L188–196) tidak memiliki kolom `created_at`, berbeda dari seluruh tabel domain lainnya.

### 3.3 Evaluasi Snapshot Denormalisasi & Soft-Delete
- **Denormalisasi Terencana (`orders.customer_name`, `orders.stall_name`, `order_items.name`, `order_items.unit_price_idr`):** Sudah tepat secara domain agar perubahan nama/harga di masa depan tidak mengubah struk historis pesanan. Namun, kolom-kolom snapshot ini tidak dilengkapi `CHECK` panjang/non-kosong dan tidak dilindungi trigger *immutability*.
- **Soft-Delete (`menus.deleted_at`):** Sudah tepat untuk menjaga histori pesanan, tetapi tabel `menus` belum memiliki `CHECK ((deleted_at IS NULL) OR (is_available = FALSE AND deleted_at >= created_at))` sehingga update langsung dapat menciptakan anomali menu terhapus yang masih berstatus `is_available = TRUE`.

---

## 4. Dummy Data & Seed Audit

Pemeriksaan khusus dilakukan terhadap seluruh **1.807 baris (47 top-level SQL statements)** pada `supabase_schema_complete.sql` serta seluruh file pendukung di repositori untuk memisahkan secara tegas struktur DDL, data referensi, konfigurasi awal, dan data dummy/simulasi.

### 4.1 Klasifikasi Tegas Seluruh Statement pada `supabase_schema_complete.sql`

| Lokasi Baris | Statement / Konstruksi SQL | Nilai Literal / Default yang Diperiksa | Kategori Klasifikasi | Kesimpulan & Bukti Audit |
| :--- | :--- | :--- | :--- | :--- |
| L10 | `CREATE EXTENSION IF NOT EXISTS "pgcrypto";` | `"pgcrypto"` | **(1) Struktur SQL (DDL) Wajib** | Ekstensi kriptografi untuk pembuatan ID acak. |
| L12–45 | 7× `DO $$ BEGIN CREATE TYPE public.<enum> AS ENUM (...);` | Nilai domain role, kategori menu, status order/pembayaran/pengajuan, mutasi | **(1) Struktur SQL (DDL) Wajib** *(sekaligus merepresentasikan **(2) Reference Data** di level tipe)* | Karena daftar referensi dikodekan sebagai tipe `ENUM` PostgreSQL (bukan tabel lookup terpisah), maka tidak diperlukan `INSERT` data referensi. |
| L52–113 | `CREATE TABLE` untuk `users`, `stalls`, `menus` | Prefix `'usr_'`, `'stl_'`, `'mnu_'`; `'customer'`; `prep_time_min = 15`; `version = 1` | **(1) Struktur SQL (DDL) Wajib** | Seluruh `DEFAULT` adalah nilai awal domain yang wajar; **0 baris akun/stan/menu contoh**. |
| L116 | `CREATE SEQUENCE IF NOT EXISTS public.order_number_seq START 101;` | `START 101` | **(1) Struktur DDL / (3) Initial Configuration Wajib** | **Bukan data dummy.** `START 101` memastikan nomor antrean mulai dari format 3 digit (`KC-101`), terpisah dari fixture simulasi (`SIM-100..107`, sequence `1000` di `seed.dart`). |
| L118–230 | `CREATE TABLE` untuk `orders`, `order_items`, `canteen_applications`, `food_preferences`, `mutation_receipts`, `audit_events` | Prefix `'ord_'`, `'KC-'`, `'app_'`; `'waiting'`; `'unpaid'`; `'submitted'`; `'{}'` | **(1) Struktur SQL (DDL) Wajib** | Murni definisi skema; **0 transaksi/pesanan simulasi**. |
| L236–288 | 9× `ALTER TABLE ... ENABLE RLS`, 2× `REVOKE ALL`, 14× `CREATE INDEX` | Role `anon`, `authenticated`; konfigurasi `'simple'` | **(1) Struktur SQL (DDL) Wajib** | Konfigurasi keamanan dan indeks akses data. |
| L294–1786 | 15× `CREATE OR REPLACE FUNCTION` (`fn_*` & `rpc_*`) | Literal status transisi, `15` menit pada approval stan (L1654), `'{}'::jsonb` | **(1) Struktur SQL (DDL) Wajib** | Murni logika transaksional; **tidak ada kredensial hardcoded, email fiktif, atau bypass akun uji**. |
| **L1791–1802** | `INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) VALUES ('kantin-media', 'kantin-media', true, 2097152, ARRAY['image/jpeg', 'image/png', 'image/webp']) ON CONFLICT (id) DO UPDATE ...` | `'kantin-media'`, `true`, `2097152` (2 MB), MIME gambar | **(3) Initial Configuration Wajib** | **Satu-satunya statement `INSERT` di seluruh file SQL.** Wajib ada untuk menyediakan bucket penyimpanan media sesuai `SPESIFIKASI_BACKEND.md:32`. **Jangan dihapus** (cukup perbaiki policy-nya). |
| L1804–1807 | `CREATE POLICY "Public media access" ON storage.objects FOR SELECT ...` | `'kantin-media'` | **(3) Initial Configuration** *(mengandung cacat keamanan — lihat Temuan HIGH-09)* | Bukan data dummy, tetapi policy `SELECT` ini harus dihapus/diubah karena mengekspos listing seluruh file di bucket. |

### 4.2 Pemeriksaan Data Dummy & Akun Uji di Seluruh Repositori
1. **Di dalam `supabase_schema_complete.sql`:** Terverifikasi **0 baris data dummy, 0 akun pengujian, 0 password default, dan 0 transaksi simulasi**.
2. **Di dalam kode produksi Flutter (`app/lib/**`):** Terverifikasi bersih dari fixture simulasi (dijaga pula oleh `app/test/audit/architecture_boundary_test.dart`).
3. **Di dalam direktori pengujian (`app/test/support/simulation/seed.dart` L3–160):** Ditemukan data Kategori **(4) Data Simulasi/Pengujian** (`pelanggan@example.test`, `pemilik@example.test`, `admin@example.test`, password plaintext `Simulasi123!`, pesanan `SIM-100..107`). Data ini terisolasi di `app/test/` dan tidak masuk ke database maupun entrypoint produksi `app/lib/main.dart`.
   - **Catatan Risiko Rilis CD (`INFORMATIONAL`):** File `.github/workflows/cd-release.yml` (L143–178) mem-build `kantin-cerdas-simulation-debug.apk` (yang memuat akun `Simulasi123!`) dan melampirkannya pada halaman GitHub Release berdampingan dengan `kantin-cerdas-release.apk` menggunakan `applicationId` yang sama (`com.kantincerdas.app`). Pastikan artefak demo tersebut tidak didistribusikan ke pengguna produksi.

### 4.3 Kekosongan Konfigurasi Awal Produksi: Deadlock Bootstrap Admin (`HIGH`)
Meskipun ketiadaan akun admin dummy dengan password default di dalam SQL sudah benar secara keamanan, skema saat ini menimbulkan **deadlock operasional (*Chicken-and-Egg*)** pada database baru:
- `public.users.role` selalu memiliki default `'customer'` (L61), dan spesifikasi melarang registrasi publik memilih role selain `'customer'` (`SPESIFIKASI_BACKEND.md:51`).
- `rpc_admin_review_application` (L1628–1631) mewajibkan pemanggil sudah memiliki `role = 'admin'` dan `is_active = TRUE` untuk mempromosikan `customer` menjadi `owner` dan membuat `stalls`.
- `rpc_admin_set_user_access` (L1486–1501) hanya mengubah `is_active` dan melarang perubahan role.
- **Tidak tersedia prosedur/fungsi SQL bootstrap khusus DBA** untuk mempromosikan akun `auth.users` pertama menjadi `'admin'` secara teraudit, serta **tidak ada trigger pelindung admin aktif terakhir** (*last-active-admin guard*).

---

## 5. Security Assessment

### 5.1 Autentikasi, Pengelolaan Identitas, & Pencabutan Sesi (`auth.users` vs `public.users`)
1. **Penyimpanan Password:** Autentikasi didelegasikan ke Supabase Auth (`auth.users`, menggunakan bcrypt/Argon2 yang dikelola GoTrue); `public.users` tidak menyimpan hash password atau token. Pendekatan ini sudah tepat, **tetapi integrasi antara `auth.users` dan `public.users` belum utuh**:
   - Tidak ada trigger `AFTER INSERT ON auth.users` maupun RPC registrasi atomik. Kegagalan di tengah proses registrasi antara GoTrue dan `public.users` akan meninggalkan akun yatim (*orphan*) di `auth.users` yang mengunci alamat email pengguna.
   - Jika endpoint publik Supabase GoTrue (`/auth/v1/signup`) tidak dimatikan (`enable_signup = false` kecuali dikontrol penuh oleh server), pengguna dapat mendaftar langsung ke GoTrue tanpa memiliki profil `public.users`.
2. **Kegagalan Pencabutan Sesi Saat Akun Dinonaktifkan (`HIGH`):**
   - `SPESIFIKASI_BACKEND.md:51` mewajibkan: *"Nonaktif berlaku pada token lama juga. Aktivasi kembali tidak otomatis menghidupkan sesi dicabut."*
   - `rpc_admin_set_user_access` (L1506–1511) hanya mengubah `public.users.is_active = FALSE`. Fungsi ini **tidak** mencabut baris di `auth.sessions` / `auth.refresh_tokens`, **tidak** mengeset `banned_until` di `auth.users`, **tidak** menaikkan `session_epoch` pada `public.users`, dan bahkan **tidak** mengembalikan `auth_uid` agar server backend dapat mencabut sesi GoTrue. Akibatnya, jika akun dinonaktifkan lalu diaktifkan kembali sebelum *refresh token* kedaluwarsa, token lama dari sesi yang seharusnya sudah hangus tetap hidup kembali.

### 5.2 Celah Hak Akses Fungsi (`EXECUTE`), Default Privileges, & Eksposur PostgREST (`CRITICAL`)
- **Bukti SQL (`L246–247` vs `L294–1786`):**
  ```sql
  REVOKE ALL ON ALL TABLES IN SCHEMA public FROM anon, authenticated;
  REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM anon, authenticated;
  -- (Fungsi-fungsi dibuat di baris 294–1786 TANPA REVOKE EXECUTE!)
  ```
- **Bukti Empiris PostgreSQL 16 (Test 3 & Test 5):** Query katalog `has_function_privilege` membuktikan bahwa **ke-15 fungsi di skema `public` memiliki `anon_exec = true` dan `auth_exec = true`**!
- **Mengapa Ini Kritis di Supabase:**
  1. PostgreSQL secara bawaan memberikan hak `EXECUTE` pada setiap fungsi baru kepada pseudo-role `PUBLIC` (diwarisi oleh `anon` dan `authenticated`). Selain itu, Supabase menyetel `ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS/TABLES/SEQUENCES TO anon, authenticated`.
  2. Karena skema `public` diekspos oleh PostgREST (`/rest/v1/`), siapa pun yang memegang `anon` key publik (dan URL project Supabase terlihat jelas pada setiap URL gambar `kantin-media`) dapat mengunduh spesifikasi OpenAPI dari seluruh 15 RPC internal dan mengeksekusi langsung `POST /rest/v1/rpc/fn_utc_iso`.
  3. Seluruh 12 RPC menerima identitas pelaku semata-mata dari parameter teks bebas `p_actor_id TEXT` (bukan `auth.uid()`) dan tidak memverifikasi bahwa pemanggil adalah `service_role`. Saat ini akses tabel dari `anon` tertahan semata-mata karena fungsi berstatus `SECURITY INVOKER` dan hak tabel dicabut di L246. Jika seorang developer di masa depan menambahkan `SECURITY DEFINER` pada satu saja fungsi RPC atau membuat tabel baru tanpa `REVOKE` ulang (karena `ALTER DEFAULT PRIVILEGES` belum dicabut!), **seluruh kontrol akses runtuh seketika dan penyerang anonim dapat menyamar sebagai `admin` atau `owner` mana pun**.

### 5.3 Bypass Kepemilikan & Penyegelan Lintas Akun via `p_actor_id = NULL` (`CRITICAL` — Terbukti Empiris)
- Di seluruh 12 RPC (L397, L469, L614, L726, L840, L963, L1088, L1216, L1328, L1473, L1615, L1740), pemeriksaan kepemilikan ditulis sebagai:
  ```sql
  IF v_receipt.actor_id != p_actor_id THEN
    RAISE EXCEPTION 'FORBIDDEN: ...';
  END IF;
  ```
- Dalam logika tiga-nilai (*Three-Valued Logic*) SQL, jika bug pada layer pemanggil mengirim `p_actor_id => NULL`, ekspresi `'usr_cust1' != NULL` menghasilkan `NULL` (dianggap `FALSE` oleh blok `IF` PL/pgSQL!).
- **Bukti Empiris PostgreSQL 16 (Test J):** Memanggil `rpc_lookup_or_seal_receipt('orders', '<request_id_milik_budi>', NULL, NULL)` **berhasil menembus blok `FORBIDDEN`, menyegel transaksi `pending` milik Budi menjadi `not_applied`, dan membocorkan seluruh isi JSON `lookup_snapshot` milik Budi!**

### 5.4 Absennya Pemeriksaan `is_active` & `role` pada Transaksi Tulis (`HIGH` — Terbukti Empiris)
Bertentangan dengan `SPESIFIKASI_BACKEND.md:40–51` (*"Server memeriksa token, akun aktif, role terkini dan ownership setiap request termasuk dalam transaksi write"*):
1. **Keempat RPC Owner (`rpc_owner_save_stall`, `rpc_owner_save_menu`, `rpc_owner_delete_menu`, `rpc_owner_transition_order`):** Sama sekali **tidak membaca `public.users`**! Pengujian empiris (Test 7) membuktikan owner yang sudah diblokir admin (`is_active = FALSE`) masih dapat mengubah profil stan, menambah/menghapus menu, dan memproses pesanan.
2. **`rpc_cancel_customer_order` & `rpc_save_food_preferences`:** Sama sekali **tidak membaca `public.users`**! Akun nonaktif dapat membatalkan pesanan dan menyimpan preferensi; bahkan akun `admin` dapat menyimpan `food_preferences` (Test F).
3. **`rpc_create_customer_order`:** Membaca `public.users` tanpa lock `FOR SHARE`, **tidak menolak `role = 'admin'`** (Test D membuktikan `admin` berhasil membuat pesanan `KC-103` padahal dilarang oleh `SPESIFIKASI_BACKEND.md:44` dan `user_role.dart:16`), serta **tidak memeriksa apakah pemilik stan (`v_stall.owner_id`) masih aktif** (`is_active = TRUE`). Karena `rpc_admin_set_user_access` juga tidak menutup stan (`stalls.is_open = FALSE`) saat memblokir seorang `owner`, pelanggan tetap bisa memesan ke stan milik owner yang telah dinonaktifkan!

### 5.5 Kebocoran Enumerasi Objek pada Supabase Storage (`HIGH`)
- Baris 1795 mengeset `public = true` pada bucket `kantin-media`, lalu baris 1805–1806 menambahkan:
  ```sql
  CREATE POLICY "Public media access" ON storage.objects
    FOR SELECT USING (bucket_id = 'kantin-media');
  ```
- Di Supabase Storage, `public = true` pada `storage.buckets` **sudah cukup** untuk melayani unduhan file publik melalui URL `/storage/v1/object/public/kantin-media/<nama_file>` tanpa policy RLS apa pun pada `storage.objects`.
- Menambahkan policy `FOR SELECT` pada `storage.objects` justru memberikan izin kepada pengguna tanpa login (`anon`) untuk memanggil endpoint `POST /storage/v1/object/list/kantin-media` dan **memanen daftar seluruh nama file di dalam bucket**, yang sesuai format `{actorId}_{category}_{uuidV4}.{ext}` membocorkan daftar `usr_...` aktif beserta metadata waktu unggah seluruh pengguna.

### 5.6 Kolom URL Gambar Tanpa Validasi: *Persistent Catalog DoS* & Tracking Eksternal (`HIGH`)
- Kolom `users.avatar_url` (L60), `stalls.image_url` (L84), dan `menus.image_url` (L105) bertipe `TEXT` bebas tanpa `CHECK` constraint dan tanpa sanitasi di `rpc_owner_save_stall` / `rpc_owner_save_menu`.
- Di sisi klien Flutter (`stall_mapper.dart:16–22`, `menu_item_mapper.dart:26–32`, `user_model.dart:39–45`), fungsi `ImageSecurityValidator.normalizeSafeImageUrl()` melempar `DataParsingException` apabila ada URL yang tidak berawalan `http://`/`https://`, melebihi 512 karakter, mengandung userinfo `@`, `..`, `\`, karakter kontrol, atau tanda kutip/kurung sudut.
- Karena `GET /v1/catalog` memuat seluruh stan dan menu sekaligus dalam satu snapshot (`SPESIFIKASI_BACKEND.md:142`), **satu saja nilai `image_url` tidak valid yang masuk ke `stalls` atau `menus` akan melumpuhkan halaman katalog bagi 100% pengguna aplikasi (*Poison-Pill DoS*)!** Selain itu, ketiadaan pembatasan domain ke host Storage resmi memungkinkan pemilik stan menyisipkan URL server eksternal untuk memanen alamat IP dan `User-Agent` seluruh pelanggan atau mengganti gambar secara sepihak setelah lolos peninjauan.

### 5.7 Keamanan Log Audit & SQL Injection
- **SQL Injection:** Seluruh 15 fungsi di `supabase_schema_complete.sql` menggunakan variabel terikat PL/pgSQL (tanpa `EXECUTE` SQL dinamis), sehingga **aman dari SQL Injection di lapisan skrip SQL ini**. Risiko SQLi pada endpoint baca/pencarian di server HTTP berstatus **NOT VERIFIED** karena kode `backend/` belum tersedia.
- **Integritas `audit_events` (`HIGH`):** Meskipun diberi komentar `-- Append-Only Log Audit Server` (L218), tidak ada trigger yang melarang `UPDATE`/`DELETE`, dan pengujian empiris (Test 3) membuktikan `service_role` memegang hak penuh `DELETE` dan `UPDATE` atas `public.audit_events`. Selain itu, **5 dari 10 RPC mutasi** (`rpc_submit_canteen_application`, `rpc_save_food_preferences`, `rpc_owner_save_stall`, `rpc_owner_save_menu`, `rpc_owner_delete_menu`) sama sekali tidak mencatat baris ke `audit_events`.

---

## 6. Data Integrity Assessment

### 6.1 Kerusakan Integritas Finansial & Bypass CAS Akibat SQL Three-Valued Logic (`CRITICAL` — Terbukti Empiris)
Parameter fungsi PL/pgSQL secara default boleh bernilai `NULL`. Penggunaan operator `!=`, `GREATEST`, dan `NOT` tanpa guard `IS NULL` / `IS DISTINCT FROM` menciptakan 3 celah integritas fatal yang seluruhnya **terbukti pada pengujian PostgreSQL 16**:

1. **Eksploitasi Pesanan Rp 1 (`rpc_create_customer_order` L507 & L542 — Test H):**
   ```sql
   -- L507: GREATEST(NULL, 1) menghasilkan 1, BUKAN NULL!
   INSERT INTO public.orders (..., total_price_idr, ...) VALUES (..., GREATEST(p_total_price_idr, 1), ...);
   ...
   -- L542: 50000 != NULL menghasilkan NULL (falsy), sehingga RAISE EXCEPTION dilewati!
   IF v_computed_total != p_total_price_idr THEN
     RAISE EXCEPTION 'PRICE_CHANGED: ...';
   END IF;
   ```
   Ketika `p_total_price_idr` bernilai `NULL`, database meng-commit pesanan senilai Rp 50.000 dengan `orders.total_price_idr = 1` sementara `order_items` mencatat `50000`! Selain merusak buku besar kas, ketidaksesuaian `total_price_idr != SUM(items)` ini memicu `ArgumentError` -> `DataParsingException` di konstruktor `OrderRecord` Flutter, merusak layar daftar pesanan bagi pelanggan dan pemilik stan sekaligus.
2. **Bypass Penuh Optimistic Locking / CAS pada 6 RPC (`p_expected_version => NULL` — Test I):**
   Pada `rpc_cancel_customer_order` (L634), `rpc_owner_save_stall` (L983), `rpc_owner_delete_menu` (L1239), `rpc_owner_transition_order` (L1351), `rpc_admin_set_user_access` (L1502), dan `rpc_admin_review_application` (L1637), kondisi `IF v_entity.version != p_expected_version` mengevaluasi ke `NULL` (falsy) saat `p_expected_version IS NULL`, sehingga pembaruan menimpa versi terbaru secara buta tanpa pengecekan CAS!
3. **Bypass Konfirmasi Tunai & Serah Terima Makanan (`rpc_owner_transition_order` L1371 — Test I):**
   Pada transisi `ready -> completed`, kondisi `IF v_clean_reason IS NOT NULL OR NOT p_cash_received OR NOT p_food_handed_over` mengevaluasi `FALSE OR NULL OR NULL` -> `NULL` (falsy) saat kedua boolean bernilai `NULL`, menandai pesanan `completed` dan `paid` tanpa konfirmasi pembayaran maupun penyerahan makanan!

### 6.2 Cacat Protokol Idempotensi, Race Condition Penyegelan, & `mutation_receipts` (`CRITICAL` — Terbukti Empiris)
1. **Late Commit Menimpa Receipt yang Sudah Disegel (`not_applied` -> `applied`):**
   Di level isolasi default PostgreSQL (`READ COMMITTED`), `SELECT * INTO v_existing_receipt FROM public.mutation_receipts ... FOR UPDATE` (L463, L608, dst.) **tidak mengambil kunci apa pun apabila baris belum ada**. Jika request mutasi berjalan lambat lalu klien memanggil `rpc_lookup_or_seal_receipt` (L1776) yang meng-commit baris `outcome = 'not_applied', sealed = TRUE` (sehingga klien membuka kunci jurnal dan membuat pesanan baru), transaksi mutasi yang terlambat tadi akan mencapai blok:
   ```sql
   INSERT INTO public.mutation_receipts (...) VALUES (..., 'applied', ..., TRUE, ...)
   ON CONFLICT (family, request_id) DO UPDATE SET outcome = 'applied', ...
   ```
   Karena `ON CONFLICT DO UPDATE` **tidak memiliki klausa `WHERE public.mutation_receipts.sealed = FALSE`**, mutasi terlambat tersebut **menimpa segel `not_applied` menjadi `applied`** dan menciptakan pesanan ganda! Hal yang sama terjadi bila dua request identik tiba bersamaan sebelum baris receipt ada: keduanya mengeksekusi `INSERT INTO public.orders` dan menciptakan dua pesanan berbeda.
2. **Payload Berbeda Menimpa `request_snapshot` Saat Status `pending` (Test 6):**
   Di seluruh 10 RPC mutasi (L472–479, dst.), pengecekan `v_existing_receipt.request_snapshot != v_req_snapshot` hanya diletakkan di dalam cabang `IF v_existing_receipt.outcome = 'applied'`. Ketika baris berstatus `'pending'` (hasil `rpc_register_pending_mutation`), pengiriman ulang ID yang sama dengan payload berbeda **tidak ditolak** dan langsung menimpa `request_snapshot` (melanggar `SPESIFIKASI_BACKEND.md:121`).
3. **Ketidaksesuaian Skema `v_req_snapshot` Antara RPC:**
   `rpc_owner_delete_menu` (L1202) dan `rpc_owner_transition_order` (L1310) tidak menyertakan `'stall_id'` pada `v_req_snapshot` (berbeda dari `rpc_owner_save_stall` L945 & `rpc_owner_save_menu` L1070); `rpc_admin_set_user_access` (L1457) tidak menyertakan `'target_role'`; dan `rpc_admin_review_application` (L1599) tidak menyertakan `'applicant_id'`.
4. **Anomali Kolom `mutation_receipts` (L199–216):**
   - `completed_at` disetel `NOT NULL DEFAULT timezone('utc', now())` sehingga receipt `'pending'` yang belum selesai sudah memiliki stempel waktu selesai.
   - `payload_hash TEXT` (L203) tidak pernah diisi di satu pun RPC (`NULL` permanen).
   - `chk_mutation_receipts_sealed_consistency` (L212–215) tidak memeriksa konsistensi `response_snapshot IS NOT NULL` saat `outcome = 'applied'`.
   - Jika transaksi mutasi gagal secara definitif (`PRICE_CHANGED`, `VERSION_CONFLICT`) setelah `rpc_register_pending_mutation` di-commit pada transaksi terpisah, `RAISE EXCEPTION` me-rollback transaksi mutasi dan meninggalkan baris `'pending'` menggantung tanpa disegel.

### 6.3 Ketidakcocokan Constraint SQL vs Kontrak Domain & Celah Validasi Data (`CRITICAL` & `HIGH`)

| Tabel & Kolom | Kontrak `SPESIFIKASI_BACKEND.md` & Klien Flutter | Constraint `supabase_schema_complete.sql` | Bukti Dampak Integritas & Runtime |
| :--- | :--- | :--- | :--- |
| `canteen_applications.name` | `1..120` grapheme (`canteen_application.dart:45`) | `length(btrim(name)) BETWEEN 3 AND 80` (L176) | Input sah 1–2 atau 81–120 karakter gagal dengan `23514` (`500` -> mengunci jurnal klien). Kontradiktif dengan `stalls.name` (`1..120`, L91)! |
| `canteen_applications.description` | `1..1000` grapheme (`canteen_application.dart:47`) | `BETWEEN 10 AND 500` (L177) | Input sah 1–9 atau 501–1000 karakter gagal dengan `23514`. Kontradiktif dengan `stalls.description` (`<= 1000`, L93)! |
| `canteen_applications.location` | `1..120` grapheme (`canteen_application.dart:49`) | `BETWEEN 2 AND 120` (L178) | Lokasi 1 karakter (mis. `'A'`) gagal dengan `23514`. |
| `canteen_applications.phone` | `<= 24` karakter, regex `^\+?[0-9 ()-]+$`, **8..15 digit** | `BETWEEN 8 AND 20`, **tanpa regex digit** (L179) | Nomor valid 21–24 karakter ditolak; sebaliknya teks `'BUKAN-NOMOR-HP'` diterima DB (Test E) lalu **membuat layar Admin & Customer crash dengan `DataParsingException`**! |
| `order_items.note` | `<= 300` grapheme (`customer_input_limits.dart:6`) | `length(note) <= 200` (L153) | Catatan item 201–300 karakter lolos validasi Flutter tetapi meledak di DB (`23514`) dan mengunci jurnal checkout! |
| `food_preferences.avoid_ingredients` | Maks 20 elemen; tiap elemen trim, `1..60` grapheme, unik *case-insensitive*, tanpa `,`/`\n`/`\r` | Hanya `cardinality <= 20` (L195) | Elemen `NULL`, `''`, duplikat `'udang'`/`'UDANG'`, koma, atau teks 10.000 karakter lolos masuk DB (Test F) lalu **membuat layar Preferensi crash permanen**! |
| Seluruh kolom `CHECK (length(btrim(col)) ...)` | Nilai tersimpan wajib sudah di-trim (`col = btrim(col)`) | Hanya memeriksa panjang sesudah `btrim()` (L70–71, L91–92, L111, L176–179) | String berisi **50.000 spasi di depan** (`repeat(' ', 50000) \|\| 'Stan A'`) lolos masuk DB (terbukti pada Test E: `raw_name_len = 50006`)! |
| Batas panjang karakter (*grapheme* vs *code point*) | Dihitung per *Unicode extended grapheme cluster* (`.characters.length`) | `length()` PostgreSQL menghitung *Unicode code point* | Emoji gabungan ZWJ (`👨‍👩‍👧‍👦` = 1 grapheme, 7 code point) di dekat batas maksimum lolos di klien/Dart tetapi gagal `23514` di PostgreSQL. |

### 6.4 Relasi Foreign Key, Orphan Records, & Invarian Lintas Kolom (`HIGH`)
1. **Absennya Foreign Key pada `order_items.menu_id` (L145):** Walaupun `menus` sudah memakai soft-delete (`deleted_at`) khusus agar baris menu tidak pernah dihapus fisik, `order_items.menu_id` tidak memiliki `REFERENCES public.menus(id) ON DELETE RESTRICT`. Akibatnya, database mengizinkan `order_items` merujuk ke `menu_id` fiktif pada `INSERT` langsung dan tidak mencegah penghapusan fisik tidak sengaja pada `public.menus`.
2. **Konflik Aturan `ON DELETE CASCADE` pada `users.auth_uid` (L54):** Menghapus baris di `auth.users` memicu `CASCADE` ke `public.users`, yang akan **langsung gagal dengan `23503 foreign_key_violation`** jika pengguna pernah membuat pesanan, stan, pengajuan, atau receipt mutasi (`ON DELETE RESTRICT`), tetapi menghapus senyap tanpa jejak audit jika pengguna baru memiliki `food_preferences`. Seharusnya gunakan `ON DELETE RESTRICT` pada `users.auth_uid`.
3. **Ketiadaan Invarian Status pada `canteen_applications` (L157–185):** Pengujian empiris (Test E) membuktikan database menerima baris berstatus `'approved'` dengan `approved_stall_id = NULL`, `reviewed_by = NULL`, dan `reviewed_at = NULL`! Selain itu, tidak ada constraint `previous_id != id`, tidak ada `UNIQUE (previous_id)` (mencegah percabangan ganda dari satu pengajuan yang ditolak), tidak ada partial unique index `WHERE status IN ('submitted', 'reviewing')` (`SPESIFIKASI_BACKEND.md:64`), dan status `'reviewing'` di dalam `ENUM` (L29) merupakan *dead state* karena tidak ada satu pun RPC yang dapat mengubah status menjadi `'reviewing'`.
4. **Ketiadaan Invarian `orders` <-> `order_items` di Level Skema:** Tidak ada constraint trigger (`DEFERRABLE INITIALLY DEFERRED`) yang menjamin setiap `orders` memiliki minimal 1 `order_items` dan `orders.total_price_idr = SUM(quantity * unit_price_idr)`.
5. **Deadlock Konkurensi AB-BA pada `rpc_admin_set_user_access` (L1486 & L1495):** Fungsi mengunci baris admin pemanggil dengan `FOR SHARE` (L1486) lalu mengunci `p_target_user_id` dengan `FOR UPDATE` (L1495) **sebelum** memeriksa `v_target.role = 'admin'`. Jika Admin A dan Admin B saling menargetkan secara bersamaan, terjadi deadlock klasik AB-BA (`SQLSTATE 40P01`). Urutan kunci tabel antara `rpc_owner_save_menu` (`stalls -> menus`) dan `rpc_owner_delete_menu` (`menus -> stalls`) juga terbalik, serta pembuatan awal `canteen_applications` (L747) dan `food_preferences` (L853) rentan melempar `23505` mentah pada submit paralel pertama karena `users` tidak dikunci `FOR NO KEY UPDATE`.

---

## 7. Performance & Scalability Assessment

Evaluasi dilakukan secara objektif berdasarkan struktur tabel, definisi ke-14 indeks (L252–288), dan pola akses data nyata pada kontrak repository di `SPESIFIKASI_BACKEND.md` serta `app/lib/`. *(Catatan: benchmark throughput/latensi beban tinggi tidak diklaim karena server HTTP `/v1/*` belum tersedia; seluruh analisis di bawah ini berbasis rencana akses indeks PostgreSQL yang dapat dibuktikan secara struktural).*

### 7.1 Evaluasi Indeks Keyset Pagination vs Pola Query Aplikasi (`HIGH`)

| Endpoint & Kontrak Query | Indeks Saat Ini di `supabase_schema_complete.sql` | Masalah Struktural Rencana Eksekusi PostgreSQL |
| :--- | :--- | :--- |
| `GET /v1/customer/orders`<br>(`history = false` -> `status IN ('waiting','processing','ready')`; `history = true` -> `status IN ('completed','rejected','cancelled')`) | `idx_orders_customer_cursor (customer_id, created_at DESC, id DESC)` (L270)<br>& `idx_orders_customer_status_cursor (customer_id, status, created_at DESC, id DESC)` (L272) | Klien **tidak pernah** memfilter 1 status tunggal pada endpoint ini, melainkan himpunan 3 status (`IN (...)`)! Indeks `(customer_id, status, created_at DESC, id DESC)` tidak dapat mengalirkan hasil terurut `(created_at DESC, id DESC)` lintas 3 nilai `status` tanpa operasi **Sort di memori**; sebaliknya memakai `idx_orders_customer_cursor` saat `history = false` memaksa pembacaan ribuan pesanan riwayat lama milik pelanggan aktif. Diperlukan *partial index* khusus pesanan aktif `WHERE status IN ('waiting', 'processing', 'ready')`. |
| `GET /v1/owner/orders`<br>(`stall_id` wajib, `status` **opsional/nullable**) | `idx_orders_stall_cursor (stall_id, status, created_at DESC, id DESC)` (L274) | Saat pemilik membuka tab **"Semua Pesanan"** (`status IS NULL`), kolom kedua indeks adalah `status` sehingga PostgreSQL tidak dapat membaca urutan `(created_at DESC, id DESC)` secara langsung dan harus membaca serta mengurutkan seluruh histori pesanan stan! Wajib tambah indeks `(stall_id, created_at DESC, id DESC)`. |
| `GET /v1/admin/applications`<br>(`status` **opsional/nullable**) | `idx_canteen_applications_admin_cursor (status, created_at DESC, id DESC)` (L282) | Saat admin menampilkan seluruh pengajuan tanpa filter status (`status IS NULL`), tidak ada indeks yang diawali `(created_at DESC, id DESC)`, memicu **Full `SeqScan` + `Sort`** pada `canteen_applications`! |
| `GET /v1/owner/menus`<br>(`stall_id` wajib, `available` **opsional**, urutan `created_at DESC, id DESC`) | `idx_menus_stall_active (stall_id, is_available, id) WHERE deleted_at IS NULL` (L263) | Indeks kehilangan kolom `created_at DESC` dan mengurutkan `id ASC`, sehingga tidak selaras dengan kursor keyset `(created_at DESC, id DESC)`. |
| `GET /v1/admin/summary`<br>(`activeOrders`: hitung semua pesanan berstatus aktif secara global) | **Tidak ada indeks global pada `status`** | Seluruh indeks pada `orders` diawali oleh `customer_id` atau `stall_id` (L270–275). Menghitung `COUNT(*) FROM orders WHERE status IN ('waiting','processing','ready')` memicu **Full Table `SeqScan`** pada setiap pembukaan dashboard Admin! |
| `fn_order_record_json` pada `order_items` | `uq_order_items_position UNIQUE (order_id, position)` (L152) **DAN** `idx_order_items_order_pos (order_id, position ASC)` (L276) | **100% indeks duplikat identik.** Constraint `UNIQUE (order_id, position)` sudah membuat indeks B-Tree yang persis sama. `idx_order_items_order_pos` menggandakan beban tulis/WAL dan ruang disk tanpa manfaat baca. |

### 7.2 Kehilangan Presisi Mikrodetik pada `fn_utc_iso` yang Merusak Kursor Keyset (`HIGH`)
- Pada baris 300: `SELECT to_char(p_ts AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"');`
- Tipe `TIMESTAMPTZ` di PostgreSQL menyimpan presisi **mikrodetik** (6 digit pecahan, mis. `.123456Z`), sedangkan mask `'MS'` memotongnya menjadi **milidetik** (3 digit, `.123Z`). Apabila server menyusun token `next_cursor` dari timestamp 3 digit tersebut (`.123000Z`) lalu menjalankan kursor `WHERE (created_at, id) < ($cursor_ts, $cursor_id)`, maka baris lain yang tercipta pada milidetik yang sama di mikrodetik `.123100Z .. .123999Z` akan bernilai `.123456Z < .123000Z` = **FALSE** sehingga **hilang secara permanen dari halaman berikutnya**! Selain itu, melabeli `to_char` sebagai `IMMUTABLE` menghambat *inlining* fungsi SQL tertentu. Gunakan mask 6 digit `'YYYY-MM-DD"T"HH24:MI:SS.US"Z"'`.

### 7.3 Ketiadaan Indeks Foreign Key Penuh (`MEDIUM–HIGH`)
PostgreSQL tidak membuat indeks otomatis pada sisi pereferensi Foreign Key, dan **planner tidak dapat memakai *partial index* (`WHERE ...`) untuk memvalidasi penghapusan/pembaruan induk FK**:
1. `menus.stall_id` (L99): Kedua indeks yang ada (L260, L263) bersifat parsial (`WHERE deleted_at IS NULL`), sehingga validasi FK terhadap `stalls` memicu `SeqScan` atas seluruh baris termasuk soft-deleted.
2. `canteen_applications.applicant_id` (L159): Indeks L279 bersifat parsial (`WHERE is_latest = TRUE`), sehingga histori pengajuan lama tidak terindeks untuk FK maupun audit riwayat pemohon.
3. `canteen_applications.previous_id` (L167): **Tidak memiliki indeks sama sekali** (seharusnya `UNIQUE` index).
4. `canteen_applications.reviewed_by` (L168): **Tidak memiliki indeks sama sekali**.
5. `order_items.menu_id` (L145): Kolom kedua pada PK `(order_id, menu_id)`, **tidak memiliki indeks sendiri** ketika FK ke `menus(id)` ditambahkan.

### 7.4 Ketidakcocokan Indeks Pencarian Teks GIN `to_tsvector('simple', ...)` (`HIGH`)
- Baris 254–255 (`idx_users_search`) dan 266–268 (`idx_menus_search`) memakai `USING gin (to_tsvector('simple', ...))`.
- Parser `'simple'` memperlakukan alamat email (`budi.santoso@kampus.ac.id`) dan username ber-underscore (`budi_01`) sebagai **satu token utuh tunggal**. Pencarian kata `'santoso'`, `'kampus'`, atau `'01'` menggunakan `to_tsquery` menghasilkan **0 baris**!
- Lebih lanjut, kontrak pencarian aplikasi (`simulation/owner.dart:52`, `simulation/admin.dart:34–36`) mengharapkan pencocokan **substring *case-insensitive*** (`ILIKE '%kata%'`). PostgreSQL **sama sekali tidak bisa memakai indeks `to_tsvector`** untuk operator `ILIKE '%...%'`, sehingga jatuh kembali ke `SeqScan`! Solusi yang tepat adalah ekstensi `pg_trgm` dengan operator class `gin_trgm_ops`.

### 7.5 Bottleneck Skalabilitas Jangka Panjang
1. **Snapshot Katalog Penuh (`GET /v1/catalog`):** Sesuai `SPESIFIKASI_BACKEND.md:142`, katalog mengembalikan seluruh stan dan seluruh menu aktif dalam satu respons JSON (bahkan menduplikasi objek menu di tingkat atas `menus` dan di dalam `stalls[].menus`). Ketika jumlah menu menembus ribuan item, ukuran payload dan serialisasi JSON akan membengkak signifikan.
2. **Kontensi Sequence & Perulangan Query Per Item:**
   - `order_number_seq` (L116) dan `audit_events_id_seq` (L220) menggunakan default `CACHE 1` (sebaiknya `CACHE 50` untuk jam makan siang puncak) dan `rpc_create_customer_order` memanggil `nextval('order_number_seq')` (L500) sebelum validasi item sehingga membakar nomor antrean pada setiap kegagalan harga/stok (terbukti pada Test C).
   - `rpc_create_customer_order` (L510–540) menjalankan `SELECT * FROM public.menus ... FOR SHARE` satu per satu di dalam loop `FOR v_item` tanpa batas atas panjang array JSON `p_items` dan tanpa pengurutan `menu_id` (berisiko lambat pada array besar serta rawan deadlock jika bersilang dengan transaksi update batch menu).
   - `fn_order_record_json` (L313) melakukan `SELECT * FROM public.orders` ulang padahal pemanggilnya (`rpc_cancel_customer_order` L644 & `rpc_owner_transition_order` L1386) baru saja memperoleh baris `v_order` lewat `RETURNING *`.
3. **MVCC Tuple Bloat & Pertumbuhan Tak Terbatas pada `mutation_receipts` & `audit_events`:**
   - Pola dua langkah (`INSERT` oleh `rpc_register_pending_mutation` lalu `UPDATE` oleh `ON CONFLICT DO UPDATE`) menciptakan 1 *dead tuple* per transaksi ditambah penyimpanan 3 kolom `JSONB` besar (termasuk seluruh struktur pesanan dan item pada `response_snapshot`). Tanpa partisi waktu (`PARTITION BY RANGE`) pada `audit_events` dan kebijakan pemangkasan PII (*compaction*) pada `mutation_receipts`, ukuran tabel dan indeks akan terus membengkak tanpa batas.

---

## 8. Application Compatibility

Pemeriksaan kompatibilitas dilakukan dengan membandingkan ke-36 spesifikasi endpoint HTTP `/v1/*` (`SPESIFIKASI_BACKEND.md:174–180`) beserta seluruh datasource, mapper error, dan model DTO di `app/lib/` terhadap `supabase_schema_complete.sql`.

### 8.1 Matriks Cakupan Kontrak Aplikasi vs Dukungan Database

| Domain Fitur | Total Endpoint `/v1/*` | Didukung RPC di SQL | Kompatibilitas Kontrak & Temuan Kritis |
| :--- | :---: | :---: | :--- |
| **Auth & Profil** (`/v1/auth/*`) | **8** | **0 dari 8** | **TIDAK LENGKAP:** Tidak ada RPC/trigger untuk registrasi atomik (`auth.users` + `public.users`), login via `identifier` (`username_key` / `email_key`), pencabutan sesi saat ban/logout, maupun **`PUT /v1/auth/profile/avatar`** (yang wajib menaikkan `users.version` agar CAS admin tetap valid, sesuai `SPESIFIKASI_BACKEND.md:59,109`). |
| **Media Upload** (`POST /v1/media/images`) | **1** | **Parsial (Bucket saja)** | **TIDAK LENGKAP:** Klien (`media_upload_api_service.dart:57`) mengirim header `Idempotency-Key` 48-hex, tetapi `public.mutation_family` (L33–40) **tidak memiliki enum `'media-images'`**, tidak ada tabel kepemilikan/orphan aset media, dan validasi *Magic Bytes* tidak dapat dilakukan oleh Supabase Storage saja. |
| **Katalog & Asisten AI** (`/v1/catalog`, `/v1/customer/assistant/recommend`) | **2** | **0 dari 2** | **BERGANTUNG SERVER:** Belum ada view/fungsi SQL pembentuk struktur kembar `CustomerCatalog` (`menus` top-level dan `stalls[].menus` wajib identik 100% dengan field turunan `stall_name`, `block`, `prep_time_min`, jika selisih 1 item `CustomerCatalog` melempar `FormatException`). |
| **Pembacaan & Paginasi** (`GET` Orders, Menus, Stall, Users, Summary, Applications) | **13** | **Parsial (2 helper JSON)** | **CACAT INDEKS & PRESISI:** Helper `fn_order_record_json` & `fn_canteen_application_json` cocok dengan `OrderRecordModel` & `CanteenApplicationModel`, tetapi belum ada query/fungsi paginasi kursor opaque, presisi `.MS` pada `fn_utc_iso` berisiko melompati item kursor, dan indeks tanpa filter status belum tersedia. |
| **Mutasi Bisnis** (Customer, Owner, Admin — 10 operasi) | **11** *(POST/PUT/DELETE)* | **11 dari 11** *(10 RPC)* | **KOMPATIBEL PADA JALUR SUKSES SEMPIT, CACAT PADA VALIDASI & ERROR:** Format JSON sukses (`v_response`) cocok dengan DTO klien, **TETAPI** memiliki 5 cacat pemutus kontrak: (1) batas `order_items.note <= 200` vs `300`; (2) batas `canteen_applications` nama/deskripsi/telepon salah; (3) `avoid_ingredients` tidak dinormalisasi; (4) error `'NOT_FOUND'` pada 5 RPC mutasi membuat klien masuk mode `UnknownFailure` (mengunci jurnal!); (5) `p_reason` non-kosong pada `approved` & `reason > 300` pada `set_user_access` merusak deserialisasi `PendingAdminMutation`. |
| **Pemulihan Operasi** (`GET /v1/operations/{family}/{requestId}`) | **1 (×6 family)** | **1 RPC (`rpc_lookup_or_seal_receipt`)** | **RUSAK KRITIS (DEADLOCK PERMANEN KLIEN):** Gagal memulihkan 4 dari 6 keluarga mutasi ketika request awal terputus sebelum mencapai server, serta gagal memperbarui `lookup_snapshot` saat menyegel baris `'pending'`. |

### 8.2 Bukti Deadlock Permanen Klien Flutter pada `/v1/operations/{family}/{requestId}` (`CRITICAL`)
Mekanisme jurnal idempotensi pada aplikasi Flutter (`OwnerMutationController`, `AdminMutationController`, `FoodPreferencesController`, `CustomerOrderCancellationController`) bekerja sebagai berikut:
1. Sebelum mengirim request HTTP tulis, aplikasi menyimpan intent mutasi ke penyimpanan terenkripsi lokal (`FlutterSecureStorage`) dan mengunci seluruh tombol aksi (`blocked == true`). Aplikasi **sengaja tidak menyediakan tombol hapus paksa lokal** (`SPESIFIKASI_BACKEND.md:138`).
2. Apabila paket jaringan gagal mencapai server (internet terputus, timeout DNS/TCP, atau aplikasi tertutup sesaat setelah menulis jurnal), database belum memiliki baris di `public.mutation_receipts`.
3. Ketika pengguna membuka kembali aplikasi dan menekan pemulihan (`recover()`), keempat datasource (`owner_api_datasource.dart:277`, `admin_api_datasource.dart:208`, `food_preferences_api_datasource.dart:79`, `customer_order_tracking_api_datasource.dart:110`) hanya memanggil **`GET /v1/operations/{family}/{mutationId}` tanpa body dan tanpa query parameter**.
4. Karena server tidak pernah menerima request awal, server tidak mengetahui metadata request (`stall_id`, `kind`, `expected_version`, `max_budget_idr`, `order_id`, `order_number`, dll.) sehingga memanggil `rpc_lookup_or_seal_receipt(..., p_fallback_lookup => NULL)`.
5. Baris 1756–1758 pada `supabase_schema_complete.sql` langsung mengeksekusi:
   ```sql
   IF p_family NOT IN ('orders', 'canteen-applications') AND p_fallback_lookup IS NULL THEN
     RAISE EXCEPTION 'NOT_FOUND: Receipt mutasi tidak ditemukan.';
   END IF;
   ```
   *(Dibuktikan empiris pada PostgreSQL 16 Test G).*
6. Seluruh repository klien (`owner_repository_impl.dart:234`, dll.) memetakan HTTP `404 NOT_FOUND` pada operasi lookup menjadi `UnconfirmedFailure` / `UnknownFailure` dan **menolak menghapus jurnal lokal**! Bahkan seandainya server mengirim JSON dummy, baris `if (!pending.matches(result.request))` di controller (`owner_mutation_controller.dart:376`) akan menolak respons tersebut. *(Pada pengujian lokal `app/test/support/simulation/owner.dart:378`, bug desain ini tertutup karena harness simulasi berjalan di memori yang sama dan mengintip jurnal lokal perangkat secara langsung).*
7. **Akibatnya:** Setiap gangguan koneksi sebelum paket sampai ke server pada 4 fitur tersebut akan **mengunci akun pengguna secara permanen tanpa jalan keluar kecuali menghapus data aplikasi (*clear app data*)**.

### 8.3 Bukti Ketidakcocokan Kode Error `'NOT_FOUND'` pada 5 RPC Mutasi (`CRITICAL`)
Pada `rpc_cancel_customer_order` (L629), `rpc_owner_save_menu` (L1122), `rpc_owner_transition_order` (L1343), `rpc_admin_set_user_access` (L1497), dan `rpc_admin_review_application` (L1635), ketiadaan entitas target melempar `'NOT_FOUND: ...'`. Apabila server memetakannya menjadi HTTP `404`, mapper kegagalan mutasi di klien Flutter (`owner_failure_mapper.dart:21–36`, `admin_failure_mapper.dart:19–47`, `customer_failure_mapper.dart:69–84`) **tidak mengenali `404` sebagai penolakan definitif (*no-commit*)** dan menerjemahkannya sebagai `UnknownFailure` / `UnconfirmedFailure` yang mengunci jurnal lokal! Bandingkan dengan `rpc_owner_delete_menu` (L1231) yang sudah benar melempar `'VERSION_CONFLICT'` (`409`).

---

## 9. Production Readiness Assessment

### 9.1 Pengujian Eksekusi Database Kosong & Idempotensi Migrasi
1. **Pada PostgreSQL 16 Standar (Vanilla / AWS RDS / Cloud SQL):** **GAGAL TOTAL** pada baris 75 (`ERROR: schema "auth" does not exist`), baris 246 (`role "anon" does not exist`), dan baris 1791 (`schema "storage" does not exist`) — terbukti pada Test 1. Skrip ini 100% terikat pada platform Supabase.
2. **Pada Lingkungan Kompatibel Supabase PostgreSQL 16:**
   - Eksekusi DDL pertama dan kedua berhasil menyelesaikan 47 statement tanpa error sintaks DDL (terbukti pada Test 2).
   - **NAMUN terjadi "Idempotensi Semu" (*Fake Idempotency*):** Penggunaan `CREATE TABLE IF NOT EXISTS` (L52–230) dan `DO $$ CREATE TYPE/POLICY ... EXCEPTION WHEN duplicate_object THEN NULL` (L12–45, L1804–1807) **mengabaikan perubahan kolom, constraint, nilai enum, maupun definisi policy secara diam-diam** apabila skrip dijalankan ulang terhadap database yang sudah ada. Selain itu, perubahan tanda tangan parameter pada `CREATE OR REPLACE FUNCTION` akan menciptakan fungsi *overload* ganda yang membingungkan PostgREST (`PGRST203`).
   - Seluruh 1.807 baris tidak dibungkus blok transaksi `BEGIN; ... COMMIT;`, sehingga kegagalan di tengah eksekusi meninggalkan skema setengah jadi.
   - **Kegagalan Runtime Pasca-Deploy:** Meskipun DDL sukses terpasang di Supabase, pemanggilan `rpc_create_customer_order` langsung gagal saat runtime akibat `SET search_path = public` vs `extensions.gen_random_bytes(8)` (Test 4).

### 9.2 Strategi Versioning, Pemisahan Lingkungan, Backup, & Recovery (PITR)
- **Ketiadaan Versioning Migrasi & CI Database:** Repositori tidak memiliki struktur `supabase/migrations/<timestamp>_<nama>.sql`, `supabase/config.toml`, maupun pengujian skema otomatis di `.github/workflows/ci.yml`.
- **Persyaratan Kritis Backup & Point-in-Time Recovery (`RPO = 0`):**
  > [!WARNING]
  > Karena aplikasi menerapkan protokol *negative-sealing* (`rpc_lookup_or_seal_receipt` menyegel permanen `request_id` yang tidak ditemukan di `mutation_receipts` menjadi `not_created` / `not_applied`), **database produksi WAJIB mengaktifkan Continuous WAL Archiving / Point-in-Time Recovery (PITR) dengan `synchronous_commit = on`**. Apabila terjadi insiden dan database dipulihkan dari *daily snapshot* yang kehilangan transaksi 10 menit terakhir (`RPO > 0`), aplikasi pelanggan yang me-recovery pesanan yang sebenarnya sudah dibayar tunai akan memicu penyegelan otomatis `not_created` di database pulihan!

### 9.3 Pemisahan Tegas: Temuan Terbukti, Dugaan Risiko, & Aspek `NOT VERIFIED`

1. **Temuan yang Terbukti Secara Empiris / Bukti Kode Konkret (*Proven*):**
   - Kegagalan runtime `gen_random_bytes(8)` pada `rpc_create_customer_order` di lingkungan ber-skema `extensions` Supabase (Test 4).
   - Eksploitasi `NULL` pada `p_total_price_idr` (menciptakan pesanan `total_price_idr = 1` atas item Rp 50.000 — Test H), `p_expected_version` (bypass CAS di 6 RPC — Test I), `p_cash_received`/`p_food_handed_over` (bypass serah terima — Test I), dan `p_actor_id` (menyegel & membocorkan receipt pengguna lain — Test J).
   - Penimpaan `request_snapshot` oleh payload berbeda saat status `pending` (Test 6) dan tiadanya klausa `WHERE` pada `ON CONFLICT DO UPDATE` di ke-10 RPC.
   - Bypass otorisasi akun nonaktif pada RPC Owner (Test 7) dan akun `admin` pada pembuatan pesanan/preferensi (Test D & Test F).
   - Overflow `INT4` pada `rpc_create_customer_order` (Test A), error `23505` pada item duplikat (Test B), pembakaran sequence `order_number_seq` pada checkout gagal (Test C), lolosnya nomor telepon alfabetik & padding 50.000 spasi (Test E), lolosnya elemen `NULL`/duplikat/raksasa pada `avoid_ingredients` (Test F), serta error `NOT_FOUND` pada `rpc_lookup_or_seal_receipt` untuk mutasi yang gagal terkirim (Test G).
   - Hak `EXECUTE` publik pada ke-15 fungsi untuk `anon` & `authenticated` serta hak `DELETE` pada `audit_events` untuk `service_role` (Test 3 & Test 5).
   - Ketiadaan direktori `backend/` dan `supabase/` di repositori.
2. **Dugaan Risiko Berbasis Struktur (*Architectural / Scale Risks*):**
   - Degradasi performa pada `SeqScan` / in-memory `Sort` untuk paginasi pesanan/pengajuan dan ringkasan admin ketika tabel `orders` tumbuh mencapai puluhan ribu hingga ratusan ribu baris.
   - Fragmentasi halaman B-Tree dan MVCC bloat pada `orders`, `mutation_receipts`, dan `audit_events` seiring peningkatan volume transaksi harian.
   - Risiko melompatnya baris paginasi keyset pada transaksi serentak dalam milidetik yang sama akibat format `.MS`.
3. **Aspek yang Belum Dapat Diverifikasi (`NOT VERIFIED`) & Informasi yang Wajib Diberikan Tim Pengembang:**
   - **Kode Sumber Server Backend (`/v1/*`):** `NOT VERIFIED` (tidak ada di repositori). Diperlukan untuk memverifikasi bagaimana token JWT divalidasi, bagaimana `p_actor_id` diekstrak, bagaimana error PL/pgSQL dipetakan ke kode HTTP + JSON `error.code`, bagaimana query baca/paginasi/pencarian mencegah SQL Injection, dan bagaimana validasi binary *Magic Bytes* dilakukan pada `POST /v1/media/images`.
   - **Konfigurasi Platform Supabase Target (`config.toml` / Pengaturan Dashboard):** `NOT VERIFIED`. Perlu dipastikan apakah `enable_signup` publik dimatikan atau dibatasi, kebijakan kekuatan password GoTrue (`>= 8` karakter), masa berlaku JWT (`JWT expiry`), rate limiting Auth/Storage, tier paket Supabase (apakah PITR aktif), dan pemisahan kredensial proyek *staging* vs *production*.
   - **Benchmark Beban Konkurensi Riil:** `NOT VERIFIED` pada level end-to-end API karena ketiadaan komponen server aplikasi.

---

## 10. Findings & Remediation Plan

Seluruh 26 temuan diurutkan berdasarkan tingkat keparahan dan prioritas eksekusi perbaikan. Setiap temuan memuat 6 elemen wajib sesuai standar audit.

---

### A. Temuan Tingkat `CRITICAL` (Prioritas P0 — Blocker Mutlak)

#### [CRIT-01] Kegagalan Runtime `gen_random_bytes(8)` pada Supabase Akibat Konflik `SET search_path = public` vs Skema `extensions`
- **Komponen / Tabel Terkait:** Ekstensi `pgcrypto`, `public.rpc_create_customer_order`, serta ekspresi `DEFAULT` pada `users.id`, `stalls.id`, `menus.id`, `orders.id`, `canteen_applications.id`.
- **Lokasi / Statement SQL:** Baris `10` (`CREATE EXTENSION IF NOT EXISTS "pgcrypto";`), baris `53, 79, 98, 119, 158`, baris `298–1728` (`SET search_path = public`), dan baris `499` (`v_order_id := 'ord_' || encode(gen_random_bytes(8), 'hex');`).
- **Deskripsi Masalah:** Pemanggilan `gen_random_bytes(8)` tidak menyertakan kualifikasi skema `extensions.`, sementara seluruh fungsi menyetel `SET search_path = public` yang menghapus skema `extensions` dari jalur pencarian simbol saat runtime.
- **Dampak terhadap Sistem:** Fitur utama pembuatan pesanan (`POST /v1/customer/orders` -> `rpc_create_customer_order`) **gagal 100% pada runtime Supabase** dengan `SQLSTATE 42883`, sehingga tidak ada satu pun pesanan pelanggan yang dapat dibuat. Eksekusi DDL tabel pada runner migrasi yang mengeset `search_path = public` juga gagal total.
- **Alasan Teknis:** Di proyek Supabase, `pgcrypto` sudah terpasang di skema `extensions`. Perintah `CREATE EXTENSION IF NOT EXISTS "pgcrypto"` bersifat *no-op* bila ekstensi sudah ada dan tidak memindahkannya ke `public`. Berbeda dengan ekspresi `DEFAULT` kolom yang di-resolve ke OID saat `CREATE TABLE`, pernyataan di dalam blok PL/pgSQL baru me-resolve fungsi saat eksekusi menggunakan `search_path` milik fungsi tersebut (`public`).
- **Rekomendasi Perbaikan Konkret:**
  ```sql
  CREATE SCHEMA IF NOT EXISTS extensions;
  CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;

  -- Kualifikasi eksplisit pada seluruh DEFAULT tabel dan di dalam rpc_create_customer_order (baris 499):
  -- v_order_id := 'ord_' || encode(extensions.gen_random_bytes(16), 'hex');
  -- Dan gunakan SET search_path = public, extensions, pg_temp pada fungsi yang memerlukan pgcrypto,
  -- atau gunakan fungsi bawaan inti PostgreSQL 13+: replace(gen_random_uuid()::text, '-', '').
  ```

---

#### [CRIT-02] Eksploitasi Three-Valued Logic (`NULL`) Merusak Nilai Total Pesanan (`Rp 1`), Mem-bypass CAS di 6 RPC, Mem-bypass Serah Terima, & Membocorkan Receipt Lintas Akun
- **Komponen / Tabel Terkait:** `public.orders`, `public.mutation_receipts`, dan seluruh 12 fungsi `public.rpc_*`.
- **Lokasi / Statement SQL:**
  - `rpc_create_customer_order` baris `507` (`GREATEST(p_total_price_idr, 1)`) & baris `542` (`IF v_computed_total != p_total_price_idr`);
  - Pemeriksaan CAS `!= p_expected_version` pada baris `634` (RPC 2), `983` (RPC 5), `1239` (RPC 7), `1351` (RPC 8), `1502` (RPC 9), `1637` (RPC 10);
  - Pemeriksaan serah terima pada baris `1371` (`IF v_clean_reason IS NOT NULL OR NOT p_cash_received OR NOT p_food_handed_over`);
  - Pemeriksaan kepemilikan receipt pada baris `397, 469, 614, 726, 840, 963, 1088, 1216, 1328, 1473, 1615, 1740` (`IF v_existing.actor_id != p_actor_id`).
- **Deskripsi Masalah:** Seluruh parameter fungsi PL/pgSQL tidak divalidasi terhadap `NULL` dan dibandingkan memakai operator `!=` / `NOT` / `GREATEST` alih-alih `IS DISTINCT FROM` atau guard `IS NULL`.
- **Dampak terhadap Sistem:**
  1. Pesanan senilai puluhan ribu rupiah ter-commit ke `public.orders` dengan `total_price_idr = 1` (merusak data keuangan dan memicu crash `DataParsingException` pada tampilan pesanan Flutter).
  2. Enam operasi tulis kehilangan proteksi *Optimistic Concurrency Control* (CAS) sepenuhnya bila `p_expected_version` bernilai `NULL`.
  3. Pesanan ditandai `completed` & `paid` meskipun konfirmasi uang tunai dan penyerahan makanan bernilai `NULL`.
  4. Pemanggilan `rpc_lookup_or_seal_receipt` dengan `p_actor_id => NULL` menyegel transaksi `pending` pengguna lain dan mengembalikan `lookup_snapshot` rahasia milik korban.
- **Alasan Teknis:** Di PostgreSQL, `GREATEST(NULL, 1)` menghasilkan `1` (mengabaikan argumen `NULL`), sedangkan `x != NULL` dan `FALSE OR NULL` menghasilkan `UNKNOWN` (`NULL`), yang dievaluasi sebagai **falsy** oleh pernyataan `IF ... THEN` di PL/pgSQL sehingga seluruh blok `RAISE EXCEPTION` dilewati!
- **Rekomendasi Perbaikan Konkret:**
  ```sql
  -- 1. Wajib tambahkan validasi eksplisit di awal setiap RPC:
  IF p_actor_id IS NULL OR btrim(p_actor_id) = '' THEN
    RAISE EXCEPTION 'UNAUTHENTICATED: Identitas pelaku wajib diisi.';
  END IF;
  -- Pada RPC 1:
  IF p_total_price_idr IS NULL OR p_total_price_idr < 1 THEN
    RAISE EXCEPTION 'INVALID_INPUT: Total harga konfirmasi tidak valid.';
  END IF;
  -- Pada RPC 2, 5, 7, 8, 9, 10:
  IF p_expected_version IS NULL OR p_expected_version < 1 THEN
    RAISE EXCEPTION 'INVALID_INPUT: expected_version wajib diisi.';
  END IF;
  -- 2. Ganti seluruh perbandingan != dengan IS DISTINCT FROM dan boolean dengan COALESCE(..., FALSE):
  IF v_existing_receipt.actor_id IS DISTINCT FROM p_actor_id THEN ...
  IF v_order.version IS DISTINCT FROM p_expected_version THEN ...
  IF v_clean_reason IS NOT NULL OR NOT COALESCE(p_cash_received, FALSE) OR NOT COALESCE(p_food_handed_over, FALSE) THEN ...
  ```

---

#### [CRIT-03] Cacat Konkurensi Protokol Idempotensi: `ON CONFLICT DO UPDATE` Tanpa `WHERE` Menimpa Segel `not_applied` & Mengizinkan Eksekusi Ganda / Timpa Payload
- **Komponen / Tabel Terkait:** `public.mutation_receipts`, `rpc_register_pending_mutation`, ke-10 RPC mutasi (RPC 1–10), dan `rpc_lookup_or_seal_receipt`.
- **Lokasi / Statement SQL:** Baris `391–417`, `463–480 & 559–572` (serta pola identik pada baris `608–674`, `720–799`, `834–913`, `957–1036`, `1082–1178`, `1210–1278`, `1322–1418`, `1467–1554`, `1609–1707`), dan `1734–1782`.
- **Deskripsi Masalah:** (1) `SELECT ... FOR UPDATE` pada baris `mutation_receipts` yang belum ada tidak mengunci apa pun pada isolasi `READ COMMITTED`; (2) `INSERT ... ON CONFLICT (family, request_id) DO UPDATE` di akhir ke-10 RPC tidak memiliki klausa `WHERE`; (3) kecocokan `request_snapshot` sama sekali tidak diperiksa saat `outcome = 'pending'` maupun `sealed = TRUE`; (4) skema JSON `v_req_snapshot` tidak konsisten antar-RPC (kehilangan `stall_id`/`target_role`/`applicant_id` di RPC 7–10).
- **Dampak terhadap Sistem:** Transaksi lambat yang terlambat selesai **menimpa baris yang sudah disegel sebagai `not_applied` (`sealed = TRUE`) menjadi `applied`** setelah klien diberi tahu bahwa pesanan gagal dibuat (memicu pesanan ganda!). Dua request paralel identik tanpa pra-registrasi sama-sama lolos dan membuat dua pesanan berbeda. Request ulang dengan payload berbeda pada saat `pending` menimpa `request_snapshot` asli secara diam-diam.
- **Alasan Teknis:** PostgreSQL tidak menerapkan *predicate/gap locking* pada `READ COMMITTED`. Tanpa penguncian kunci deterministik (`pg_advisory_xact_lock`) di awal transaksi dan tanpa guard `WHERE public.mutation_receipts.sealed = FALSE` pada `ON CONFLICT DO UPDATE`, operasi upsert menimpa baris yang baru di-insert transaksi lain secara buta.
- **Rekomendasi Perbaikan Konkret:**
  ```sql
  -- 1. Serialisasi per kunci idempotensi di baris pertama SELURUH RPC (0 s.d. 11):
  PERFORM pg_advisory_xact_lock(hashtextextended(p_family::text || ':' || p_request_id, 0));

  -- 2. Periksa actor_id & payload_hash / request_snapshot pada SEMUA state (pending, applied, not_applied):
  IF FOUND THEN
    IF v_existing_receipt.actor_id IS DISTINCT FROM p_actor_id THEN
      RAISE EXCEPTION 'FORBIDDEN: Idempotency-Key milik pengguna lain.';
    END IF;
    IF v_existing_receipt.request_snapshot != '{}'::jsonb
       AND v_existing_receipt.request_snapshot IS DISTINCT FROM v_req_snapshot THEN
      RAISE EXCEPTION 'IDEMPOTENCY_PAYLOAD_MISMATCH: Payload berbeda untuk Idempotency-Key yang sama.';
    END IF;
    IF v_existing_receipt.outcome = 'applied' THEN
      RETURN v_existing_receipt.response_snapshot;
    ELSIF v_existing_receipt.sealed THEN
      RAISE EXCEPTION 'LATE_SEALED_REQUEST: Permintaan telah disegel sebagai tidak diterapkan.';
    END IF;
  END IF;

  -- 3. Tambahkan guard WHERE ketat pada ON CONFLICT DO UPDATE & periksa FOUND:
  INSERT INTO public.mutation_receipts (...) VALUES (...)
  ON CONFLICT (family, request_id) DO UPDATE SET ...
  WHERE public.mutation_receipts.sealed = FALSE
    AND public.mutation_receipts.outcome = 'pending'
    AND public.mutation_receipts.actor_id = EXCLUDED.actor_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'LATE_SEALED_REQUEST: Receipt telah disegel oleh proses rekonsiliasi.';
  END IF;
  ```

---

#### [CRIT-04] Deadlock Permanen Pemulihan Jurnal Klien (`404 NOT_FOUND`) & Korupsi `lookup_snapshot` pada `rpc_lookup_or_seal_receipt`
- **Komponen / Tabel Terkait:** `public.rpc_lookup_or_seal_receipt`, `public.mutation_receipts`, dan kontrak `GET /v1/operations/{family}/{requestId}`.
- **Lokasi / Statement SQL:** Baris `1744–1758`:
  ```sql
  IF v_receipt.outcome = 'pending' THEN
    UPDATE public.mutation_receipts SET outcome = 'not_applied', sealed = TRUE ...
  END IF;
  RETURN v_receipt.lookup_snapshot;
  ...
  IF p_family NOT IN ('orders', 'canteen-applications') AND p_fallback_lookup IS NULL THEN
    RAISE EXCEPTION 'NOT_FOUND: Receipt mutasi tidak ditemukan.';
  END IF;
  ```
- **Deskripsi Masalah:** Pertama, ketika paket mutasi awal (`order-cancellations`, `food-preferences`, `owner-mutations`, `admin-mutations`) gagal mencapai server karena putus koneksi, klien memanggil `GET /v1/operations/{family}/{mutationId}` tanpa body/query tambahan sehingga `p_fallback_lookup` bernilai `NULL` dan RPC melempar `NOT_FOUND` (`404`). Kedua, saat menyegel baris `'pending'` menjadi `'not_applied'` (L1745), fungsi mengubah kolom `outcome` tetapi **tidak memperbarui field `outcome`/`status` di dalam JSON `lookup_snapshot`** serta langsung membunuh request yang mungkin masih berjalan (*in-flight*).
- **Dampak terhadap Sistem:** Akun pengguna (Customer, Owner, maupun Admin) **terkunci permanen dalam status *pending recovery*** (`blocked == true` selamanya) setiap kali terjadi kegagalan jaringan sebelum paket sampai ke server, karena aplikasi Flutter tidak menganggap `404` pada endpoint lookup sebagai `notApplied` dan tidak menyediakan tombol hapus jurnal paksa.
- **Alasan Teknis:** Kontrak `SPESIFIKASI_BACKEND.md:134` menegaskan *"Tidak ditemukan bukan notApplied. Final negatif hanya sah setelah ID disegel atomik terhadap late commit"*, sedangkan model DTO klien (`OwnerMutationLookupModel`, `AdminMutationLookupModel`, `FoodPreferencesLookupModel`, `OrderCancellationLookupModel`) mewajibkan kembalinya snapshot request agar lulus `pending.matches(result.request)`.
- **Rekomendasi Perbaikan Konkret:**
  1. Pada `rpc_lookup_or_seal_receipt` baris `1745`, perbarui juga JSON `lookup_snapshot`:
     `lookup_snapshot = jsonb_set(lookup_snapshot, '{outcome}', '"not_applied"'::jsonb, true)` (dan `'status'` -> `'not_created'`/`'not_submitted'` untuk `orders`/`canteen-applications`), serta bedakan mutasi yang sedang memegang lock transaksi aktif (`pg_try_advisory_xact_lock`: jika sedang terkunci oleh worker aktif, kembalikan status `'pending'` tanpa menyegel!).
  2. Untuk menangani request yang belum pernah sampai ke server pada ke-4 keluarga tersebut, selaraskan protokol antara `rpc_lookup_or_seal_receipt` dan klien/server: izinkan `rpc_lookup_or_seal_receipt` menyegel `(family, request_id)` dengan `lookup_snapshot = jsonb_build_object('actor_id', p_actor_id, 'mutation_id', p_request_id, 'outcome', 'not_applied', 'unseen_sealed', true)` (TANPA melempar `NOT_FOUND`), dan pastikan adapter/controller atau query parameter rekonsiliasi menyertakan metadata jurnal lokal yang terverifikasi.

---

#### [CRIT-05] Ketidakcocokan Fatal `CHECK` Constraint (`canteen_applications`, `order_items.note`) & Kode Error `'NOT_FOUND'` pada 5 RPC Mutasi yang Melumpuhkan Klien Flutter
- **Komponen / Tabel Terkait:** `public.canteen_applications`, `public.order_items`, serta RPC 2, 6, 8, 9, 10.
- **Lokasi / Statement SQL:** Baris `153` (`chk_order_items_note_length CHECK (length(note) <= 200)`), baris `175–180` (`chk_applications_fields`), serta `RAISE EXCEPTION 'NOT_FOUND: ...'` pada baris `629, 1122, 1343, 1497, 1635`.
- **Deskripsi Masalah:**
  1. `order_items.note` dibatasi `<= 200` di SQL padahal spesifikasi & validasi Flutter mengizinkan `<= 300`.
  2. `canteen_applications` membatasi `name` `3..80` (vs `1..120`), `description` `10..500` (vs `1..1000`), `location` `2..120` (vs `1..120`), dan `phone` `8..20` tanpa validasi regex angka (vs `<= 24` karakter berpola `^\+?[0-9 ()-]+$` dengan `8..15` digit).
  3. Lima RPC mutasi melempar kode `'NOT_FOUND'` ketika entitas target tidak ditemukan/sudah dihapus.
- **Dampak terhadap Sistem:**
  - Input sah pengguna dari form Flutter gagal dengan error PostgreSQL mentah `23514` (`HTTP 500`), yang oleh klien dianggap status `unknown` sehingga mengunci jurnal lokal.
  - Nomor telepon alfabetik (mis. `'BUKAN-NOMOR-HP'`) dapat masuk ke DB lalu menyebabkan `DataParsingException` yang melumpuhkan halaman daftar pengajuan Admin dan halaman status pengajuan Customer.
  - Error `'NOT_FOUND'` (`HTTP 404`) pada mutasi tidak dipetakan sebagai kegagalan definitif di Flutter (`owner_failure_mapper.dart`, `admin_failure_mapper.dart`, `customer_failure_mapper.dart`), sehingga mengunci jurnal lokal pengguna!
- **Alasan Teknis:** Klien hanya menerjemahkan `404` menjadi `null` pada operasi **baca** entitas tunggal; pada operasi **tulis**, hilangnya target CAS adalah konflik status/versi (`409 VERSION_CONFLICT`), sebagaimana yang sudah diterapkan dengan benar di `rpc_owner_delete_menu` baris `1231`.
- **Rekomendasi Perbaikan Konkret:**
  ```sql
  -- 1. Selaraskan CHECK constraint dengan SPESIFIKASI_BACKEND.md & domain Flutter (beri ruang UTF-8 untuk emoji gabungan):
  ALTER TABLE public.order_items
    DROP CONSTRAINT IF EXISTS chk_order_items_note_length,
    ADD CONSTRAINT chk_order_items_note_length CHECK (length(note) <= 1200);

  ALTER TABLE public.canteen_applications
    DROP CONSTRAINT IF EXISTS chk_applications_fields,
    ADD CONSTRAINT chk_applications_fields CHECK (
      name = btrim(name) AND length(name) BETWEEN 1 AND 480 AND
      description = btrim(description) AND length(description) BETWEEN 1 AND 4000 AND
      location = btrim(location) AND length(location) BETWEEN 1 AND 480 AND
      phone = btrim(phone) AND length(phone) <= 24 AND
      phone ~ '^\+?[0-9 ()-]+$' AND
      length(regexp_replace(phone, '[^0-9]', '', 'g')) BETWEEN 8 AND 15
    );
  -- 2. Ganti RAISE EXCEPTION 'NOT_FOUND: ...' pada baris 629, 1122, 1343, 1497, 1635 menjadi 'VERSION_CONFLICT: ...'
  --    serta validasi batas grapheme secara presisi di server Dart sebelum memanggil RPC.
  ```

---

#### [CRIT-06] Absennya `REVOKE EXECUTE` pada Fungsi, Absennya `ALTER DEFAULT PRIVILEGES`, & Eksposur PostgREST `/rest/v1/rpc/*` dengan `p_actor_id TEXT` Tanpa Guard Role
- **Komponen / Tabel Terkait:** Skema `public`, seluruh 15 fungsi (`fn_*` & `rpc_*`), serta hak akses role `PUBLIC`, `anon`, `authenticated`, `service_role`.
- **Lokasi / Statement SQL:** Baris `246–247` (`REVOKE ALL ON ALL TABLES/SEQUENCES ...`) dan baris `294–1786` (deklarasi 15 fungsi tanpa `REVOKE` sesudahnya).
- **Deskripsi Masalah:** Skrip mencabut hak pada tabel dan sequence untuk `anon` dan `authenticated`, namun **tidak mencabut hak `EXECUTE` pada fungsi dari `PUBLIC`, `anon`, dan `authenticated`**, **tidak mengubah `ALTER DEFAULT PRIVILEGES` bawaan Supabase**, dan menerima `p_actor_id TEXT` mentah tanpa memverifikasi bahwa pemanggil adalah `service_role`.
- **Dampak terhadap Sistem:** Seluruh tanda tangan dan parameter ke-15 RPC internal terekspos secara publik pada skema OpenAPI PostgREST (`/rest/v1/`), fungsi SQL murni (`fn_utc_iso`) dapat dipanggil langsung oleh `anon`, tabel/fungsi baru pada migrasi berikutnya otomatis terbuka ke `anon`/`authenticated`, dan kesalahan sekecil menambahkan `SECURITY DEFINER` di masa depan langsung memicu pengambilalihan akun penuh (*full account takeover*) atas seluruh role termasuk `admin`.
- **Alasan Teknis:** PostgreSQL memberikan `EXECUTE` ke `PUBLIC` secara otomatis untuk setiap fungsi baru, dan Supabase menambahkan default grant eksplisit ke `anon` dan `authenticated` di skema `public`. Mencabut hak dari `anon, authenticated` tanpa `PUBLIC` tidak pernah mencabut hak `EXECUTE` yang diwarisi dari `PUBLIC`.
- **Rekomendasi Perbaikan Konkret:**
  ```sql
  ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
    REVOKE ALL ON TABLES FROM PUBLIC, anon, authenticated;
  ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
    REVOKE ALL ON SEQUENCES FROM PUBLIC, anon, authenticated;
  ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public
    REVOKE ALL ON FUNCTIONS FROM PUBLIC, anon, authenticated;

  REVOKE CREATE ON SCHEMA public FROM PUBLIC, anon, authenticated;
  REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC, anon, authenticated;
  REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM PUBLIC, anon, authenticated;
  REVOKE ALL ON ALL ROUTINES IN SCHEMA public FROM PUBLIC, anon, authenticated;

  GRANT USAGE ON SCHEMA public TO service_role;
  GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
  GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
  GRANT EXECUTE ON ALL ROUTINES IN SCHEMA public TO service_role;
  ```
  Tambahkan pula pengecekan di dalam fungsi helper otorisasi terpusat bahwa `current_user IN ('service_role', 'postgres', 'supabase_admin')` atau pindahkan seluruh RPC ke skema privat (`app_private`) yang tidak diekspos PostgREST.

---

### B. Temuan Tingkat `HIGH` (Prioritas P1 — Wajib Selesai Sebelum Production)

#### [HIGH-07] Ketiadaan Seluruh Server HTTP Backend (`/v1/*`) & Celah 24 Endpoint Tanpa Dukungan Database
- **Komponen / Tabel Terkait:** Lapisan integrasi aplikasi `backend/` & 24 endpoint Auth/Read/Media/AI.
- **Lokasi / Statement SQL:** `supabase_schema_complete.sql:233–248` vs `docs/04_STATUS_DAN_PENGUJIAN.md:16,23–26` & `SPESIFIKASI_BACKEND.md:174–180`.
- **Deskripsi Masalah:** Skema SQL mematikan akses langsung klien (`Zero Direct Anon Access`) dan mengasumsikan keberadaan server Dart (`service_role`), tetapi repositori sama sekali tidak memiliki kode server `backend/`, sehingga 0 dari 36 endpoint HTTP `/v1/*` tersedia (dan 24 di antaranya belum memiliki fungsi/view pendukung di SQL).
- **Dampak terhadap Sistem:** Aplikasi produksi Flutter (`--dart-define=API_BASE_URL=...`) tidak dapat login, mendaftar, memuat katalog, mengunggah foto, maupun bertransaksi sama sekali.
- **Alasan Teknis:** Klien Flutter menggunakan `Dio` ke REST `/v1/*` dan mewajibkan amplop error JSON `{"code": "..."}` (`hasBackendErrorCode == true`), bukan protokol PostgREST Supabase.
- **Rekomendasi Perbaikan Konkret:** Bangun dan sertakan kode sumber server `backend/` ke dalam repositori kontrol versi, implementasikan ke-36 endpoint `/v1/*` beserta parser error PL/pgSQL (`CODE: pesan` -> status HTTP + JSON `code`), serta koreksi klaim keliru pada `docs/04_STATUS_DAN_PENGUJIAN.md`.

---

#### [HIGH-08] Absennya Pemeriksaan `users.is_active` & `users.role` di 7 RPC Tulis, Stan Owner Nonaktif Tetap Buka, & Sesi Lama Tidak Dicabut Saat Ban
- **Komponen / Tabel Terkait:** `public.users`, `public.stalls`, `auth.users`, RPC 1, 2, 4, 5, 6, 7, 8, 9, 11.
- **Lokasi / Statement SQL:** Baris `482–493`, `585–684`, `806–917`, `920–1429`, `1506–1511`, `1721–1786`.
- **Deskripsi Masalah:** Enam RPC mutasi (`rpc_cancel_customer_order`, `rpc_save_food_preferences`, dan keempat `rpc_owner_*`) tidak memeriksa `public.users.is_active` maupun `role`; `rpc_create_customer_order` mengizinkan `role = 'admin'` dan tidak memeriksa apakah owner stan masih aktif; `rpc_admin_set_user_access` tidak menutup stan milik owner yang diblokir dan tidak mencabut sesi/epoch token autentikasi.
- **Dampak terhadap Sistem:** Akun yang telah diblokir admin tetap dapat mengubah menu/stan/pesanan; pelanggan dapat memesan ke stan yang pemiliknya sudah diblokir (pesanan menggantung tak terlayani); admin dapat membuat pesanan pelanggan; dan token lama hidup kembali jika akun diaktifkan ulang.
- **Alasan Teknis:** Pelanggaran langsung terhadap matriks otorisasi dan aturan pencabutan sesi di `SPESIFIKASI_BACKEND.md:40–51`.
- **Rekomendasi Perbaikan Konkret:** Buat fungsi `public.fn_require_active_actor(p_actor_id TEXT, p_allowed_roles public.user_role[])` dengan `SELECT ... FOR SHARE` yang wajib dipanggil di awal setiap RPC; tambahkan kolom `session_epoch INTEGER NOT NULL DEFAULT 1` pada `public.users` yang dinaikkan saat `p_is_active = FALSE` (serta cabut sesi GoTrue via Admin API menggunakan `auth_uid`); otomatis set `stalls.is_open = FALSE` saat owner dinonaktifkan; dan periksa `owner.is_active = TRUE` saat checkout di `rpc_create_customer_order`.

---

#### [HIGH-09] Kebocoran Enumerasi Seluruh File & ID Pengguna pada Bucket `kantin-media`
- **Komponen / Tabel Terkait:** `storage.buckets`, `storage.objects`.
- **Lokasi / Statement SQL:** Baris `1791–1807` (`CREATE POLICY "Public media access" ON storage.objects FOR SELECT USING (bucket_id = 'kantin-media');`).
- **Deskripsi Masalah:** Bucket publik diberi tambahan RLS policy `FOR SELECT` pada tabel `storage.objects`.
- **Dampak terhadap Sistem:** Pihak eksternal tanpa autentikasi dapat memanggil API list Supabase Storage (`POST /storage/v1/object/list/kantin-media`) dan mengunduh daftar seluruh path gambar yang memuat `actorId` (`usr_...`), kategori aset, dan waktu aktivitas seluruh pengguna.
- **Alasan Teknis:** Di Supabase Storage, `storage.buckets.public = true` sudah mengizinkan pembacaan file individual melalui endpoint `/object/public/kantin-media/...` tanpa policy `SELECT` pada `storage.objects`. Policy `SELECT` hanya diperlukan apabila ingin membuka fitur *directory listing* kepada publik.
- **Rekomendasi Perbaikan Konkret:** Hapus policy `SELECT` tersebut (`DROP POLICY IF EXISTS "Public media access" ON storage.objects;`) dan tambahkan tabel `public.media_assets` untuk melacak kepemilikan objek, kuota unggah per pengguna, dan pembersihan file yatim (*orphan cleanup*).

---

#### [HIGH-10] Ketiadaan Validasi Kolom `avatar_url` / `image_url` Memicu *Persistent Catalog/Admin DoS* (*Poison-Pill*) & Beacon Eksternal
- **Komponen / Tabel Terkait:** `public.users.avatar_url`, `public.stalls.image_url`, `public.menus.image_url`, `rpc_owner_save_stall`, `rpc_owner_save_menu`.
- **Lokasi / Statement SQL:** Baris `60`, `84`, `105`, `930`, `993`, `1054`, `1117`, `1134`.
- **Deskripsi Masalah:** Ketiga kolom URL gambar tidak memiliki `CHECK` constraint format, panjang (`<= 512`), skema (`https://`), maupun pembatasan domain bucket resmi, serta tidak menormalisasi string kosong menjadi `NULL`.
- **Dampak terhadap Sistem:** Satu saja URL cacat (mis. string relatif, spasi, `javascript:...`, atau `> 512` karakter) yang tersimpan di `stalls` atau `menus` menyebabkan `ImageSecurityValidator.normalizeSafeImageUrl()` di klien melempar `DataParsingException` dan **melumpuhkan `GET /v1/catalog` untuk 100% pengguna**! URL `https://` ke domain eksternal juga membocorkan IP seluruh pengguna ke server pihak ketiga.
- **Alasan Teknis:** Deserializer Flutter menolak keras seluruh respons katalog apabila terdapat 1 item dengan URL tidak aman (`stall_mapper.dart`, `menu_item_mapper.dart`, `user_model.dart`).
- **Rekomendasi Perbaikan Konkret:** Tambahkan fungsi `IMMUTABLE` `public.fn_is_safe_image_url(TEXT)` dan pasang sebagai `CHECK` constraint pada `users.avatar_url`, `stalls.image_url`, dan `menus.image_url` yang mewajibkan `NULL` atau URL HTTPS kanonis `/storage/v1/object/public/kantin-media/<safe_file_name>` maksimal 512 karakter, serta gunakan `NULLIF(btrim(p_image_url), '')` di RPC.

---

#### [HIGH-11] Deadlock Operasional Bootstrap Admin Awal & Ketiadaan Proteksi Admin Aktif Terakhir
- **Komponen / Tabel Terkait:** `public.users`, `rpc_admin_set_user_access`, `rpc_admin_review_application`.
- **Lokasi / Statement SQL:** Baris `61`, `1486–1501`, `1628–1631`.
- **Deskripsi Masalah:** Seluruh akun baru berstatus `'customer'`, tidak ada prosedur SQL teraudit untuk menetapkan `'admin'` pertama pada instalasi produksi kosong, dan tidak ada trigger yang mencegah penghapusan/penonaktifan admin aktif terakhir.
- **Dampak terhadap Sistem:** Sistem baru tidak memiliki admin sehingga tidak ada pengajuan stan yang dapat disetujui dan aplikasi tidak dapat beroperasi kecuali operator melakukan manipulasi SQL mentah tanpa jejak audit; sebaliknya kesalahan query manual dapat menghapus satu-satunya admin aktif.
- **Alasan Teknis:** Spesifikasi (`SPESIFIKASI_BACKEND.md:51`) menuntut prosedur server/DBA terpisah untuk bootstrap admin, namun belum disediakan di skema database.
- **Rekomendasi Perbaikan Konkret:** Sediakan fungsi khusus `postgres`/`supabase_admin` (`public.bootstrap_promote_initial_admin` yang dicabut hak eksekusinya dari `PUBLIC, anon, authenticated, service_role` dan mencatat `audit_events`) serta pasang trigger `BEFORE UPDATE OR DELETE ON public.users` yang menolak penonaktifan/penurunan role apabila tidak tersisa admin aktif lainnya.

---

#### [HIGH-12] Log Audit (`audit_events`) Dapat Dimodifikasi/Dihapus & Absen pada 50% RPC Mutasi Bisnis
- **Komponen / Tabel Terkait:** `public.audit_events`, `public.mutation_receipts`, serta RPC 3, 4, 5, 6, 7, 10, 11.
- **Lokasi / Statement SQL:** Baris `218–230`, `687–1282`, `1646–1715`, `1721–1786`.
- **Deskripsi Masalah:** (1) `public.audit_events` tidak memiliki trigger *append-only* dan `service_role` memegang hak `UPDATE, DELETE, TRUNCATE`; (2) `mutation_receipts` yang sudah `sealed = TRUE` juga tidak dilindungi trigger *immutability*; (3) 5 dari 10 RPC mutasi (`rpc_submit_canteen_application`, `rpc_save_food_preferences`, `rpc_owner_save_stall`, `rpc_owner_save_menu`, `rpc_owner_delete_menu`) serta penyegelan di `rpc_lookup_or_seal_receipt` sama sekali tidak menulis ke `audit_events`; (4) `rpc_admin_review_application` tidak mencatat event audit sekunder atas pembuatan stan baru dan promosi role `owner`.
- **Dampak terhadap Sistem:** Jejak forensik perubahan harga menu, pembukaan/penutupan stan, penghapusan menu, dan pengajuan stan hilang sepenuhnya, serta log audit yang ada dapat dihapus apabila kredensial backend disalahgunakan.
- **Alasan Teknis:** RLS tidak berlaku bagi `service_role` (`BYPASSRLS`), sehingga sifat *append-only* wajib ditegakkan melalui trigger `BEFORE UPDATE OR DELETE` dan pencabutan hak `UPDATE, DELETE, TRUNCATE` dari `service_role`.
- **Rekomendasi Perbaikan Konkret:** Pasang trigger pelarang `UPDATE`/`DELETE` pada `public.audit_events` dan pada baris `sealed = TRUE` di `public.mutation_receipts`, jalankan `REVOKE UPDATE, DELETE, TRUNCATE ON public.audit_events FROM service_role;`, lengkapi `INSERT INTO public.audit_events` di seluruh RPC mutasi, serta tambahkan indeks `(actor_id, occurred_at DESC)` dan `(request_id)`.

---

#### [HIGH-13] Overflow 32-Bit `INTEGER` pada `orders.total_price_idr` & Akumulator `v_computed_total`
- **Komponen / Tabel Terkait:** `public.orders`, `public.rpc_create_customer_order`.
- **Lokasi / Statement SQL:** Baris `127` (`total_price_idr INTEGER`), baris `434` (`p_total_price_idr INTEGER`), baris `446` (`v_computed_total INTEGER := 0;`), dan baris `530` (`v_computed_total := v_computed_total + (v_current_menu.price_idr * v_item.quantity);`).
- **Deskripsi Masalah:** Batas maksimum kolom harga menu (`10.000.000`) dikali kuantitas (`99`) menghasilkan `990.000.000` per item, sehingga pesanan dengan $\ge 3$ jenis item dapat melampaui nilai maksimum `INTEGER` 32-bit (`2.147.483.647`).
- **Dampak terhadap Sistem:** Checkout sah dalam batas domain menu & kuantitas gagal dengan error PostgreSQL mentah `22003: integer out of range` (`HTTP 500`) yang mengunci jurnal checkout pelanggan.
- **Alasan Teknis:** Perkalian `INT4 * INT4` dan penjumlahan ke variabel `INT4` di PostgreSQL melempar exception aritmetika begitu melebihi $2^{31}-1$.
- **Rekomendasi Perbaikan Konkret:** Ubah `orders.total_price_idr`, parameter `p_total_price_idr`, dan variabel `v_computed_total` menjadi `BIGINT` (dengan cast `v_current_menu.price_idr::BIGINT * v_item.quantity::BIGINT` serta batas wajar `CHECK (total_price_idr BETWEEN 1 AND 1000000000)` agar tetap aman direpresentasikan sebagai integer JSON IEEE-754).

---

#### [HIGH-14] Deadlock Konkurensi AB-BA (`40P01`), Inversi Urutan Lock, & Race `23505` pada Insert Awal
- **Komponen / Tabel Terkait:** `rpc_admin_set_user_access`, `rpc_owner_save_menu`, `rpc_owner_delete_menu`, `rpc_create_customer_order`, `rpc_submit_canteen_application`, `rpc_save_food_preferences`.
- **Lokasi / Statement SQL:** Baris `1486 & 1495`, `1101 & 1120` vs `1229 & 1234`, `510–520`, `739 & 747`, `853–866`.
- **Deskripsi Masalah:**
  1. `rpc_admin_set_user_access` mengunci `p_actor_id` (`FOR SHARE`) lalu `p_target_user_id` (`FOR UPDATE`) tanpa pengurutan ID sebelum memeriksa role admin target (memicu deadlock AB-BA).
  2. Urutan kunci antara `rpc_owner_save_menu` (`stalls -> menus`) dan `rpc_owner_delete_menu` (`menus -> stalls`) saling berlawanan, dan `rpc_create_customer_order` mengunci `menus` satu per satu sesuai urutan JSON klien tanpa deduplikasi `menu_id` (memicu `23505` pada item duplikat).
  3. Pengajuan stan pertama dan penyimpanan preferensi pertama tidak mengunci baris induk `public.users` dengan `FOR NO KEY UPDATE`, sehingga dua request awal berbeda ID berbenturan dengan `23505` mentah.
- **Dampak terhadap Sistem:** Kegagalan transaksi sporadis dengan kode `40P01` atau `23505` (`HTTP 500`) di bawah beban paralel yang berujung pada penguncian jurnal mutasi di perangkat pengguna.
- **Alasan Teknis:** Penguncian baris lintas tabel/entitas dengan urutan tidak deterministik melanggar disiplin pencegahan deadlock transaksi relasional.
- **Rekomendasi Perbaikan Konkret:** Standarkan hierarki penguncian global (`advisory_lock(receipt) -> users [ORDER BY id, FOR NO KEY UPDATE] -> stalls -> menus [ORDER BY id] -> orders`), tolak duplikasi `menu_id` dan batasi panjang array `p_items <= 100` sebelum loop di `rpc_create_customer_order`, serta gunakan `FOR NO KEY UPDATE` alih-alih `FOR UPDATE` saat kolom PK/UNIQUE tidak diubah.

---

#### [HIGH-15] Ketiadaan FK `order_items.menu_id`, Konflik `ON DELETE CASCADE` pada `users.auth_uid`, & Celah Invarian `canteen_applications` / `orders`
- **Komponen / Tabel Terkait:** `public.users`, `public.orders`, `public.order_items`, `public.canteen_applications`.
- **Lokasi / Statement SQL:** Baris `54`, `118–154`, `157–185`, `279–281`.
- **Deskripsi Masalah:**
  1. `order_items.menu_id` (L145) tidak memiliki `REFERENCES public.menus(id) ON DELETE RESTRICT`.
  2. `users.auth_uid` (L54) memakai `ON DELETE CASCADE`, bertabrakan dengan `ON DELETE RESTRICT` pada tabel-tabel anak (`orders`, `stalls`, dll.).
  3. `canteen_applications` mengizinkan `status = 'approved'` dengan `approved_stall_id = NULL` / `reviewed_by = NULL` / `reviewed_at = NULL`, mengizinkan percabangan ganda `previous_id` (tanpa `UNIQUE`), tidak memiliki partial unique index `WHERE status IN ('submitted','reviewing')`, dan memiliki nilai enum `'reviewing'` tanpa RPC pendukung.
  4. Tidak ada constraint trigger yang menjamin `orders` memiliki $\ge 1$ `order_items` dan `total_price_idr = SUM(quantity * unit_price_idr)`.
- **Dampak terhadap Sistem:** Risiko *orphan reference* pada item pesanan, perilaku penghapusan akun yang tidak konsisten di Supabase Studio, potensi data pengajuan korup, dan ketiadaan jaminan integritas penjumlahan pesanan di level tabel.
- **Alasan Teknis:** Aturan integritas referensial dan mesin status hanya ditegakkan sebagian di kode prosedural RPC tanpa pengaman deklaratif di level skema.
- **Rekomendasi Perbaikan Konkret:**
  ```sql
  ALTER TABLE public.users
    DROP CONSTRAINT IF EXISTS users_auth_uid_fkey,
    ADD CONSTRAINT users_auth_uid_fkey FOREIGN KEY (auth_uid) REFERENCES auth.users(id) ON DELETE RESTRICT;

  ALTER TABLE public.order_items
    ADD CONSTRAINT fk_order_items_menu FOREIGN KEY (menu_id) REFERENCES public.menus(id) ON DELETE RESTRICT;

  ALTER TABLE public.canteen_applications
    ADD CONSTRAINT uq_canteen_applications_previous_id UNIQUE (previous_id),
    ADD CONSTRAINT chk_applications_review_consistency CHECK (
      (status IN ('submitted', 'reviewing') AND reviewed_by IS NULL AND reviewed_at IS NULL AND approved_stall_id IS NULL) OR
      (status = 'rejected' AND reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL AND approved_stall_id IS NULL AND reviewed_by != applicant_id) OR
      (status = 'approved' AND reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL AND approved_stall_id IS NOT NULL AND reviewed_by != applicant_id)
    ),
    ADD CONSTRAINT chk_applications_no_self_prev CHECK (previous_id IS NULL OR previous_id != id);

  CREATE UNIQUE INDEX IF NOT EXISTS idx_canteen_applications_one_active
    ON public.canteen_applications (applicant_id)
    WHERE status IN ('submitted', 'reviewing');
  ```

---

#### [HIGH-16] Ketidakcocokan Indeks Keyset Pagination, Truncation Mikrodetik `fn_utc_iso` (`.MS`), Ketidakcocokan GIN `to_tsvector`, & Absennya Indeks FK
- **Komponen / Tabel Terkait:** Indeks skema `public` (L252–288) dan `public.fn_utc_iso` (L294–301).
- **Lokasi / Statement SQL:** Baris `254–255`, `260–284`, `294–301`.
- **Deskripsi Masalah:** (1) Indeks paginasi pesanan pelanggan, pesanan stan tanpa filter status, pengajuan admin tanpa filter status, menu stan terfilter `available`, dan hitungan `activeOrders` di ringkasan admin tidak sesuai dengan predikat/urutan query; (2) `fn_utc_iso` memotong mikrodetik menjadi milidetik (`.MS`); (3) indeks GIN `to_tsvector('simple', ...)` tidak mendukung pencarian substring `ILIKE '%...%'` maupun pemecahan token email/underscore; (4) lima relasi FK kehilangan indeks B-Tree penuh.
- **Dampak terhadap Sistem:** Degradasi performa ke *Full Table `SeqScan`* dan *in-memory `Sort`* saat volume transaksi membesar, hasil pencarian pengguna/menu gagal menemukan substring yang diharapkan, serta potensi baris terlewat pada halaman ke-2 paginasi kursor.
- **Alasan Teknis:** Kursor keyset membutuhkan kecocokan presisi penuh (`TIMESTAMPTZ` 6 digit `.US`) dan urutan prefiks kolom indeks yang persis sama dengan klausa `WHERE` + `ORDER BY`, sedangkan pencarian substring `ILIKE` di PostgreSQL membutuhkan indeks trigram (`pg_trgm`).
- **Rekomendasi Perbaikan Konkret:**
  ```sql
  CREATE EXTENSION IF NOT EXISTS "pg_trgm" WITH SCHEMA extensions;

  -- Perbaiki fn_utc_iso ke presisi mikrodetik penuh (.US):
  CREATE OR REPLACE FUNCTION public.fn_utc_iso(p_ts TIMESTAMPTZ)
  RETURNS TEXT LANGUAGE sql STABLE STRICT SET search_path = public, pg_temp AS $$
    SELECT to_char(p_ts AT TIME ZONE 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.US"Z"');
  $$;

  -- Tambahkan indeks kursor & FK yang hilang, perbaiki indeks menu aktif, dan gunakan gin_trgm_ops:
  DROP INDEX IF EXISTS public.idx_orders_customer_status_cursor;
  CREATE INDEX IF NOT EXISTS idx_orders_customer_active_cursor
    ON public.orders (customer_id, created_at DESC, id DESC)
    WHERE status IN ('waiting', 'processing', 'ready');
  CREATE INDEX IF NOT EXISTS idx_orders_stall_all_cursor
    ON public.orders (stall_id, created_at DESC, id DESC);
  CREATE INDEX IF NOT EXISTS idx_orders_active_global
    ON public.orders (created_at DESC)
    WHERE status IN ('waiting', 'processing', 'ready');
  CREATE INDEX IF NOT EXISTS idx_canteen_applications_all_cursor
    ON public.canteen_applications (created_at DESC, id DESC);

  DROP INDEX IF EXISTS public.idx_menus_stall_active;
  CREATE INDEX IF NOT EXISTS idx_menus_stall_active_cursor
    ON public.menus (stall_id, is_available, created_at DESC, id DESC)
    WHERE deleted_at IS NULL;

  -- Indeks FK penuh:
  CREATE INDEX IF NOT EXISTS idx_menus_stall_fk ON public.menus (stall_id);
  CREATE INDEX IF NOT EXISTS idx_order_items_menu_fk ON public.order_items (menu_id);
  CREATE INDEX IF NOT EXISTS idx_canteen_applications_applicant_fk ON public.canteen_applications (applicant_id);
  CREATE INDEX IF NOT EXISTS idx_canteen_applications_reviewed_by_fk ON public.canteen_applications (reviewed_by) WHERE reviewed_by IS NOT NULL;

  -- Indeks pencarian substring berbasis trigram:
  DROP INDEX IF EXISTS public.idx_users_search;
  CREATE INDEX IF NOT EXISTS idx_users_search_trgm
    ON public.users USING gin ((lower(coalesce(username, '') || ' ' || coalesce(name, '') || ' ' || coalesce(email, ''))) extensions.gin_trgm_ops);
  DROP INDEX IF EXISTS public.idx_menus_search;
  CREATE INDEX IF NOT EXISTS idx_menus_search_trgm
    ON public.menus USING gin ((lower(coalesce(name, '') || ' ' || coalesce(description, ''))) extensions.gin_trgm_ops)
    WHERE deleted_at IS NULL;
  ```

---

### C. Temuan Tingkat `MEDIUM` (Prioritas P2 — Perbaikan Konsistensi, Skalabilitas, & Operasional)

#### [MED-17] Entropi PK 64-Bit (`gen_random_bytes(8)`), Fragmentasi B-Tree, & Absennya Format `CHECK` pada ID
- **Komponen / Tabel Terkait:** Kolom `id` pada `users`, `stalls`, `menus`, `orders`, `canteen_applications`.
- **Lokasi / Statement SQL:** Baris `53`, `79`, `98`, `119`, `158`, `499`.
- **Deskripsi Masalah:** Pembuatan ID memakai `gen_random_bytes(8)` (64-bit acak non-monoton) tanpa mekanisme retry benturan, tanpa `COLLATE "C"`, dan tanpa `CHECK` pola prefix pada kolom `id`.
- **Dampak terhadap Sistem:** Amplifikasi tulis (*page splits*) pada indeks PK B-Tree seiring pertumbuhan baris, peluang tabrakan meningkat mengikuti paradoks ulang tahun tanpa penanganan retry (`23505`), serta tidak ada pencegah penyisipan ID berformat salah.
- **Alasan Teknis:** Distribusi acak merata menyebar penulisan ke seluruh leaf page B-Tree, sementara kolasi teks default lebih lambat daripada perbandingan byte `"C"`.
- **Rekomendasi Perbaikan Konkret:** Tingkatkan ke 16 byte (128-bit hex) atau skema `UUIDv7` berurutan waktu dengan prefix entitas (mis. `'ord_' || ...`), tambahkan `COLLATE "C"`, dan pasang `CHECK (id ~ '^ord_[a-f0-9]{16,32}$')` sesuai prefix masing-masing tabel.

---

#### [MED-18] Celah Penyimpanan Padding Spasi Tak Terbatas (`btrim`), Elemen `avoid_ingredients` Tanpa Validasi/Normalisasi, & Grapheme vs Code Point
- **Komponen / Tabel Terkait:** `users`, `stalls`, `menus`, `orders`, `canteen_applications`, `food_preferences`, `rpc_save_food_preferences`, `rpc_create_customer_order`.
- **Lokasi / Statement SQL:** Baris `67–74`, `91–93`, `111–112`, `134, 139`, `175–184`, `192, 195`, `507, 536`, `865, 874`.
- **Deskripsi Masalah:** (1) Constraint `CHECK (length(btrim(col)) BETWEEN ...)` mengizinkan puluhan ribu spasi kosong di awal/akhir teks tersimpan ke disk; (2) `avoid_ingredients` di `food_preferences` menerima elemen `NULL`, string kosong, koma/newline, duplikat *case-insensitive*, dan elemen `> 60` karakter; (3) `rpc_create_customer_order` tidak mem-`btrim` catatan pesanan/item; (4) `users.email` tidak memiliki `CHECK` pola dasar email; (5) `length()` PostgreSQL menghitung *code point* bukan *grapheme*.
- **Dampak terhadap Sistem:** Penyimpanan data kotor yang memicu `DataParsingException` pada klien Flutter (terutama pada halaman Preferensi Makanan) serta potensi penolakan `23514` pada teks ber-emoji gabungan.
- **Alasan Teknis:** Klien Flutter mewajibkan setiap elemen `avoid_ingredients` bersih, unik *case-insensitive*, tanpa `,`/`\n`/`\r`, dan `<= 60` grapheme (`food_preferences.dart:19–40`).
- **Rekomendasi Perbaikan Konkret:** Wajibkan `col = btrim(col)` pada seluruh kolom teks tertrim; tambahkan regex dasar email `email ~ '^[^@\s]+@[^@\s]+\.[^@\s]+$'`; normalisasi (trim, filter kosong, tolak `,`/`\r`/`\n`, deduplikasi `lower()`, batasi `<= 60` grapheme) array `p_avoid_ingredients` di dalam `rpc_save_food_preferences` serta tambahkan fungsi validator `CHECK` bebas `NULL` pada `food_preferences.avoid_ingredients`.

---

#### [MED-19] Bug Validasi RPC Admin (`p_reason` Non-Kosong pada `approved` & `reason > 300` pada `rpc_admin_set_user_access`) Merusak Deserialisasi Recovery
- **Komponen / Tabel Terkait:** `public.rpc_admin_review_application` dan `public.rpc_admin_set_user_access`.
- **Lokasi / Statement SQL:** Baris `1452–1455, 1532` (RPC 9) dan baris `1590–1597, 1686` (RPC 10).
- **Deskripsi Masalah:** (1) `rpc_admin_review_application` tidak menolak `p_decision = 'approved'` yang disertai `p_reason` tidak kosong, lalu menyimpan `reason` tersebut ke `v_lookup` (L1686); (2) `rpc_admin_set_user_access` memeriksa `length(v_clean_reason) = 0` tetapi tidak memeriksa batas atas `<= 300`, demikian pula `rpc_owner_transition_order` dan `rpc_admin_review_application` tidak melempar kode domain `INVALID_REASON` sebelum menabrak `CHECK` tabel.
- **Dampak terhadap Sistem:** Ketika klien Admin menjalankan rekonsiliasi `/v1/operations/admin-mutations/{id}`, `PendingAdminMutation` di Flutter melempar `ArgumentError` -> `DataParsingException`, mengunci sesi mutasi Admin secara permanen!
- **Alasan Teknis:** Konstruktor `PendingAdminMutation` (`pending_admin_mutation.dart:28,32–35`) mewajibkan `reason` kosong saat `decision == approved` dan panjang `1..300` grapheme pada perubahan akses.
- **Rekomendasi Perbaikan Konkret:** Tambahkan `IF p_decision = 'approved' AND v_clean_reason IS NOT NULL THEN RAISE EXCEPTION 'INVALID_REASON: Persetujuan tidak boleh menyertakan alasan penolakan.'; END IF;` di RPC 10, dan tambahkan `IF length(v_clean_reason) > 300 THEN RAISE EXCEPTION 'INVALID_REASON: Alasan maksimal 300 karakter.'; END IF;` di RPC 8, 9, dan 10.

---

#### [MED-20] Absennya RPC `PUT /v1/auth/profile/avatar` (Kenaikan `users.version`) & Ketiadaan Keluarga Idempotensi Unggah Media
- **Komponen / Tabel Terkait:** `public.users`, `public.mutation_family`, `public.mutation_receipts`.
- **Lokasi / Statement SQL:** Baris `33–40`, `52–75`, `199–216`.
- **Deskripsi Masalah:** Tidak ada RPC untuk memperbarui foto profil (`PUT /v1/auth/profile/avatar`) yang secara atomik menaikkan `users.version = version + 1` dan mencatat `audit_events`; selain itu enum `public.mutation_family` tidak memuat nilai untuk `POST /v1/media/images` yang mengirim header `Idempotency-Key`, kolom `completed_at` pada `mutation_receipts` bernilai `NOT NULL` saat status masih `'pending'`, dan kolom `payload_hash` selalu `NULL`.
- **Dampak terhadap Sistem:** Pembaruan profil langsung tanpa menaikkan `version` melanggar kontrak CAS Admin (`SPESIFIKASI_BACKEND.md:59,109`); retry unggah media tidak terlindungi tabel receipt; dan metadata waktu penyelesaian receipt `'pending'` tidak akurat.
- **Alasan Teknis:** `mutation_receipts.completed_at` disetel `NOT NULL DEFAULT timezone('utc', now())` pada L210 dan `payload_hash` tidak pernah dihitung dengan `digest(..., 'sha256')`.
- **Rekomendasi Perbaikan Konkret:** Tambahkan `rpc_update_profile_avatar`, tambahkan `'media-images'` ke `public.mutation_family`, ubah `mutation_receipts.completed_at` menjadi `TIMESTAMPTZ` nullable dengan `CHECK ((outcome = 'pending') = (completed_at IS NULL))`, dan isi `payload_hash = encode(extensions.digest(v_req_snapshot::text, 'sha256'), 'hex')`.

---

#### [MED-21] Ketiadaan Trigger `updated_at` & Immutability, Penggunaan `BIGSERIAL`, serta Pembakaran Sequence `order_number_seq`
- **Komponen / Tabel Terkait:** Seluruh tabel bermutasi, `public.order_number_seq`, `public.audit_events`, `rpc_create_customer_order`.
- **Lokasi / Statement SQL:** Baris `65, 89, 109, 116, 132, 173, 194, 220, 500`.
- **Deskripsi Masalah:** (1) Tidak ada trigger `BEFORE UPDATE` untuk memperbarui `updated_at = GREATEST(timezone('utc', now()), OLD.created_at)` maupun menjaga kolom immutable (`stalls.owner_id`, snapshot `orders`/`order_items`); (2) `audit_events.id` memakai `BIGSERIAL` alih-alih `GENERATED ALWAYS AS IDENTITY`; (3) kedua sequence menggunakan `CACHE 1`, dan `rpc_create_customer_order` memanggil `nextval('order_number_seq')` (L500) **sebelum** memvalidasi item & harga pesanan (L510–544).
- **Dampak terhadap Sistem:** Lompatan nomor antrean `KC-xxx` setiap kali checkout gagal karena harga berubah/menu habis, risiko pelanggaran `chk_*_updated_at` bila terjadi *NTP clock step-back* tipis, serta ketiadaan proteksi kolom immutable dari update non-RPC.
- **Alasan Teknis:** `nextval()` bersifat non-transaksional (tidak ikut di-rollback ketika transaksi gagal), sehingga wajib dipanggil paling akhir setelah seluruh validasi item dan total harga lolos!
- **Rekomendasi Perbaikan Konkret:** Pindahkan pemanggilan `nextval('public.order_number_seq')` dan `INSERT INTO public.orders` ke bawah validasi item (atau validasi menggunakan CTE/temp array terlebih dahulu), set `CACHE 50` pada `order_number_seq` dan sequence `audit_events`, ganti `BIGSERIAL` menjadi `BIGINT GENERATED ALWAYS AS IDENTITY`, serta pasang trigger penjaga `updated_at` dan kolom immutable.

---

#### [MED-22] Idempotensi Migrasi Semu, Absennya Versioning `supabase/migrations/`, Bloat `mutation_receipts`, & Syarat Wajib PITR (`RPO = 0`)
- **Komponen / Tabel Terkait:** Arsitektur deployment `supabase_schema_complete.sql` secara keseluruhan.
- **Lokasi / Statement SQL:** Baris `1–1807` (penggunaan `IF NOT EXISTS` & `EXCEPTION WHEN duplicate_object`).
- **Deskripsi Masalah:** Skema dikelola sebagai satu file monolitik tanpa pembungkus transaksi `BEGIN; ... COMMIT;`, tanpa riwayat migrasi berurutan (`supabase/migrations/`), tanpa pengujian database di CI, tanpa partisi/kebijakan pemangkasan PII pada `mutation_receipts` & `audit_events`, dan tanpa dokumentasi prasyarat mutlak WAL Point-in-Time Recovery (PITR).
- **Dampak terhadap Sistem:** *Schema drift* tersembunyi antar-lingkungan *staging* dan *production*, pembengkakan tabel JSONB dalam jangka panjang, serta risiko penyegelan palsu `not_created` atas pesanan yang sudah dibayar apabila database dipulihkan dari backup harian non-PITR (`RPO > 0`).
- **Alasan Teknis:** `CREATE TABLE IF NOT EXISTS` melewati perubahan struktur tabel yang sudah ada tanpa peringatan, sedangkan protokol *negative-sealing* di `rpc_lookup_or_seal_receipt` mengasumsikan database tidak pernah mengalami kemunduran state pasca-commit.
- **Rekomendasi Perbaikan Konkret:** Pecah skema ke dalam migrasi terversioning `supabase/migrations/` yang dijalankan secara transaksional dan diuji dengan `supabase db reset` + `pgTAP` di CI; terapkan partisi bulanan pada `audit_events` dan job pembersihan PII tua pada `mutation_receipts` (tanpa menghapus kunci tombstone `(family, request_id, actor_id, outcome, sealed)`); serta wajibkan tier Supabase dengan **PITR aktif (`synchronous_commit = on`)** sebelum go-live.

---

### D. Temuan Tingkat `LOW` (Prioritas P3 — Peningkatan Kualitas & Efisiensi)

#### [LOW-23] Inkonsistensi Gaya Penamaan Nilai `ENUM`, Absennya `created_at` pada `food_preferences`, & Kesalahan Hitung Komentar Header
- **Komponen / Tabel Terkait:** Tipe `ENUM`, `public.food_preferences`, komentar dokumentasi SQL.
- **Lokasi / Statement SQL:** Baris `25` (`'notCharged'`), baris `33–40` (`'order-cancellations'`, dll.), baris `44` (`'not_applied'`), baris `48` (`8 TABEL`), baris `188–196`.
- **Deskripsi Masalah:** Pencampuran `camelCase`, `kebab-case`, dan `snake_case` pada nilai `ENUM`; ketiadaan kolom `created_at` pada `food_preferences`; serta komentar header L48 yang menyebut 8 tabel padahal terdapat 9 tabel.
- **Dampak terhadap Sistem:** Tidak memutus fungsionalitas saat ini (klien Flutter sudah mengantisipasi `'notCharged'`), tetapi meningkatkan beban kognitif pemeliharaan kode.
- **Alasan Teknis:** Konvensi penamaan nilai enum belum distandarkan sejak awal perancangan kontrak transport.
- **Rekomendasi Perbaikan Konkret:** Tambahkan `created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())` beserta `chk_food_prefs_updated_at` pada `food_preferences`, perbaiki komentar baris 48 menjadi `9 TABEL`, dan dokumentasikan pemetaan gaya penamaan enum secara eksplisit.

---

#### [LOW-24] Indeks Duplikat 100% `idx_order_items_order_pos` & Query Ulang Redundan pada `fn_order_record_json`
- **Komponen / Tabel Terkait:** `public.order_items`, `public.fn_order_record_json`.
- **Lokasi / Statement SQL:** Baris `152` vs `276–277`, dan baris `303–316` vs `644–646, 1386–1388`.
- **Deskripsi Masalah:** `idx_order_items_order_pos (order_id, position ASC)` identik 100% dengan indeks dari `CONSTRAINT uq_order_items_position UNIQUE (order_id, position)`. Selain itu, `fn_order_record_json(p_order_id TEXT)` melakukan `SELECT * FROM public.orders` ulang padahal RPC pemanggil sudah memegang baris `v_order` terbaru dari `UPDATE ... RETURNING *`.
- **Dampak terhadap Sistem:** Pemborosan ruang disk, memori shared buffers, dan I/O tulis pada setiap item pesanan yang masuk, serta 1 pembacaan indeks PK ekstra pada setiap pembatalan/transisi pesanan.
- **Alasan Teknis:** PostgreSQL otomatis membangun indeks B-Tree unik untuk setiap constraint `UNIQUE` dengan urutan kolom yang sama.
- **Rekomendasi Perbaikan Konkret:** Hapus `DROP INDEX IF EXISTS public.idx_order_items_order_pos;` dan sediakan overload/ubah `fn_order_record_json(p_order public.orders)` agar menerima record langsung sebagaimana `fn_canteen_application_json(p_app public.canteen_applications)`.

---

### E. Temuan Tingkat `INFORMATIONAL` (Catatan Teknis & Tata Kelola Rilis)

#### [INFO-25] Ketidaksinkronan Dokumentasi Status Proyek & Typo Spesifikasi Lookup Pembatalan
- **Komponen / Tabel Terkait:** `docs/04_STATUS_DAN_PENGUJIAN.md` & `docs/backend/SPESIFIKASI_BACKEND.md`.
- **Lokasi / Statement SQL:** `docs/04_STATUS_DAN_PENGUJIAN.md:16,23–26,90` dan `docs/backend/SPESIFIKASI_BACKEND.md:127` vs `supabase_schema_complete.sql:655`.
- **Deskripsi Masalah:** Dokumentasi status menyatakan `backend/` dan `supabase/` sudah ada di repositori (faktanya belum ada). Selain itu, beberapa bagian dokumentasi lama/catatan menyebut outcome `'cancelled'` untuk lookup pembatalan, sedangkan implementasi aktual Flutter (`OrderCancellationLookupModel`) dan `supabase_schema_complete.sql:655` menggunakan `'applied'` (yang sudah tepat).
- **Dampak terhadap Sistem:** Berpotensi menyesatkan tim pengembang backend atau QA saat mengimplementasikan endpoint `/v1/operations/order-cancellations/{id}`.
- **Alasan Teknis:** Dokumentasi diperbarui mendahului komit artefak server ke repositori.
- **Rekomendasi Perbaikan Konkret:** Selaraskan isi `docs/04_STATUS_DAN_PENGUJIAN.md` dengan kondisi aktual repositori dan pastikan server menggunakan `'applied'` / `'not_applied'` sesuai kode sumber klien Flutter.

---

#### [INFO-26] Distribusi Artefak APK Simulasi Berisi Kredensial Demo pada Workflow CD Rilis
- **Komponen / Tabel Terkait:** Pipeline CI/CD `.github/workflows/cd-release.yml` & `app/test/support/simulation/seed.dart`.
- **Lokasi / Statement SQL:** `.github/workflows/cd-release.yml:143–178` (tidak berada di SQL, relevan terhadap audit kebocoran akun simulasi produksi).
- **Deskripsi Masalah:** Meskipun `supabase_schema_complete.sql` bersih 100% dari data dummy, workflow rilis GitHub Actions mengunggah `kantin-cerdas-simulation-debug.apk` (yang memuat akun demo `Simulasi123!`) pada halaman rilis yang sama dengan APK produksi menggunakan `applicationId` identik (`com.kantincerdas.app`).
- **Dampak terhadap Sistem:** Risiko pengguna akhir salah mengunduh APK simulasi atau terjadinya konflik tanda tangan paket saat instalasi di perangkat.
- **Alasan Teknis:** Tidak digunakannya `--flavor` / `applicationIdSuffix` terpisah (mis. `.sim`) untuk build simulasi.
- **Rekomendasi Perbaikan Konkret:** Pisahkan `applicationIdSuffix` untuk varian simulasi dan batasi unggahan APK simulasi hanya pada artefak CI internal, bukan rilis publik produksi.

---

### F. Rencana Tahapan Remediasi Terprioritas (*Actionable Remediation Roadmap*)

1. **Tahap 1 — Perbaikan Blocker Kritis Database (P0 / Wajib Sebelum Integrasi Apa Pun):**
   - Perbaiki resolusi `extensions.gen_random_bytes` & `SET search_path` (**CRIT-01**).
   - Tutup seluruh celah `NULL` Three-Valued Logic menggunakan guard `NOT NULL` + `IS DISTINCT FROM` + `COALESCE` di seluruh 12 RPC (**CRIT-02**).
   - Rombak protokol idempotensi dengan `pg_advisory_xact_lock`, validasi `request_snapshot`/`payload_hash` di semua state, dan klausa `WHERE sealed = FALSE` pada `ON CONFLICT DO UPDATE` (**CRIT-03**).
   - Perbaiki protokol penyegelan & rekonsiliasi `rpc_lookup_or_seal_receipt` bersama kontrak `/v1/operations/*` agar tidak pernah memicu deadlock `404` atau basi pada `lookup_snapshot` (**CRIT-04**).
   - Selaraskan seluruh `CHECK` constraint (`canteen_applications`, `order_items.note`) dan ganti error `'NOT_FOUND'` pada RPC tulis menjadi `'VERSION_CONFLICT'` (**CRIT-05**).
   - Terapkan `ALTER DEFAULT PRIVILEGES` dan `REVOKE ALL ON ALL ROUTINES ... FROM PUBLIC, anon, authenticated` serta isolasi role `service_role` (**CRIT-06**).
2. **Tahap 2 — Penguatan Keamanan, Otorisasi, & Kelengkapan Arsitektur (P1 / Wajib Sebelum Staging/UAT):**
   - Sediakan server `backend/` (`/v1/*`) beserta seluruh 36 endpoint dan pemetaan kode error JSON (**HIGH-07**).
   - Terapkan `fn_require_active_actor` di seluruh RPC, penutupan stan otomatis saat owner diblokir, dan pencabutan sesi/`session_epoch` saat ban (**HIGH-08**).
   - Hapus policy `SELECT` publik di `storage.objects`, tambahkan tabel `media_assets`, dan pasang validator `fn_is_safe_image_url` pada seluruh kolom URL gambar (**HIGH-09**, **HIGH-10**).
   - Tambahkan fungsi bootstrap admin teraudit + trigger pelindung admin aktif terakhir (**HIGH-11**), trigger *append-only* + kelengkapan log `audit_events` di semua RPC (**HIGH-12**), tipe `BIGINT` pada `total_price_idr` (**HIGH-13**), urutan lock bebas deadlock (**HIGH-14**), FK `order_items.menu_id` + constraint status `canteen_applications` (**HIGH-15**), serta indeks paginasi/FK/`pg_trgm` dan presisi `.US` pada `fn_utc_iso` (**HIGH-16**).
3. **Tahap 3 — Pematangan Operasional Produksi & Efisiensi (P2 & P3):**
   - Selesaikan temuan **MED-17** s.d. **MED-22** (entropi ID 128-bit/UUIDv7, sanitasi `avoid_ingredients` & trim ketat, validasi `reason` RPC Admin, `rpc_update_profile_avatar`, pemindahan `nextval` ke akhir validasi checkout, migrasi terkelola `supabase/migrations/` + pengujian `pgTAP` di CI, serta aktivasi **Supabase PITR `RPO = 0`**) diikuti pembersihan **LOW-23** s.d. **INFO-26**.

---

## 11. Final Verdict

### Keputusan Akhir: **`NOT PRODUCTION READY`**

### Alasan Teknis Keputusan
Berdasarkan standar *database engineering* dan *security auditing* profesional serta bukti pengujian empiris pada PostgreSQL 16, rancangan `supabase_schema_complete.sql` **tidak dapat diterima untuk digunakan langsung di lingkungan production** karena enam alasan teknis fundamental:

1. **Kegagalan Fungsionalitas Inti Saat Runtime (`CRIT-01`):** Fungsi checkout utama `rpc_create_customer_order` terbukti gagal 100% pada lingkungan standar Supabase akibat ketidakcocokan `SET search_path = public` terhadap lokasi ekstensi `extensions.pgcrypto`.
2. **Kerusakan Integritas Finansial & Bypass Kontrol Konkurensi (`CRIT-02`):** Kesalahan penanganan logika `NULL` di PL/pgSQL terbukti memungkinkan pembuatan pesanan bernilai puluhan ribu rupiah dengan `orders.total_price_idr = 1`, mem-bypass *Optimistic Concurrency Control* (`expected_version`) pada 6 RPC mutasi, menandai pesanan lunas tanpa konfirmasi penerimaan uang/penyerahan makanan, serta menyegel dan membocorkan receipt transaksi milik pengguna lain.
3. **Runtuhnya Jaminan Idempotensi & Deadlock Permanen Klien (`CRIT-03`, `CRIT-04`):** Ketiadaan penguncian kuncian belum-ada dan absennya klausa `WHERE` pada `ON CONFLICT DO UPDATE` memungkinkan mutasi terlambat menimpa transaksi yang sudah disegel sebagai batal (`not_applied`), sementara desain `rpc_lookup_or_seal_receipt` terbukti mengunci akun pengguna Flutter secara permanen setiap kali terjadi putus koneksi sebelum request mutasi mencapai server.
4. **Ketidakcocokan Kontrak Aplikasi yang Memicu Kegagalan Sistemik (`CRIT-05`, `HIGH-10`):** Batas constraint SQL pada pengajuan stan dan catatan item bertolak belakang dengan validasi aplikasi klien, sementara longgarnya validasi format nomor telepon, elemen bahan alergen, dan URL gambar memungkinkan masuknya satu baris data cacat (*poison-pill*) yang sanggup melumpuhkan pembacaan katalog dan panel admin bagi seluruh pengguna.
5. **Celah Pertahanan Berlapis (*Defense-in-Depth*) & Otorisasi Transaksional (`CRIT-06`, `HIGH-08`, `HIGH-09`, `HIGH-12`):** Hak `EXECUTE` pada seluruh fungsi masih terbuka bagi `PUBLIC`/`anon`/`authenticated`, `ALTER DEFAULT PRIVILEGES` belum diamankan, 7 RPC tulis tidak memverifikasi status aktif/role pengguna di dalam transaksi, policy Storage membocorkan daftar seluruh file/ID pengguna kepada publik, dan tabel audit belum bersifat *append-only* serta melewatkan separuh operasi mutasi.
6. **Ketidaklengkapan Ekosistem Backend & Kesiapan Operasional (`HIGH-07`, `HIGH-11`, `MED-22`):** Seluruh layer server HTTP `/v1/*` (36 endpoint) belum tersedia di repositori, prosedur bootstrap admin awal belum ada, dan mekanisme versioned migration serta jaminan PITR (`RPO = 0`) belum disiapkan.

Database ini baru dapat dinaikkan statusnya ke tahap evaluasi ulang menuju `PRODUCTION READY` setelah seluruh temuan `CRITICAL` dan `HIGH` pada Bagian 10 diselesaikan, diintegrasikan dengan kode sumber server backend `/v1/*`, dan lulus uji regresi otomatis pada lingkungan staging Supabase yang terisolasi.
