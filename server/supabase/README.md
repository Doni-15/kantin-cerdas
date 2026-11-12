# Panduan Operasional Database Supabase (`server/supabase/`)

Panduan ini mencakup urutan eksekusi migrasi PostgreSQL, prosedur bootstrap admin pertama, konfigurasi wajib Supabase Cloud, prasyarat Point-in-Time Recovery (PITR), rotasi `service_role` key, katalog kode error SQL, dan keputusan yang masih terbuka.

## 1. Urutan Migrasi dan Penerapan ke Supabase Cloud 

Seluruh berkas migrasi di `server/supabase/migrations/` dibungkus transaksi (`BEGIN; ... COMMIT;`), bebas data seed produksi, dan dirancang idempoten:   

1. `20261108000001_001_extensions_types.sql` — Skema `extensions` (`pgcrypto`, `pg_trgm`) dan tipe `ENUM` domain.
2. `20261108000002_002_tables.sql` — Generator ID 128-bit (`fn_gen_entity_id`), validator URL gambar dan bahan alergen, definisi tabel (`app_config`, `users`, `stalls`, `menus`, `orders`, `order_items`, `canteen_applications`, `food_preferences`, `mutation_receipts`, `audit_events`, `media_assets`), serta trigger integritas dan immutability.
3. `20261108000003_003_security.sql` — `ENABLE` + `FORCE ROW LEVEL SECURITY` (tanpa policy untuk `anon`/`authenticated`), `ALTER DEFAULT PRIVILEGES`, `REVOKE ALL FROM PUBLIC, anon, authenticated`, dan `GRANT` minimum ke `service_role`.
4. `20261108000004_004_helpers.sql` — Guard `fn_require_service_role()`, `fn_require_actor()`, normalisasi `avoid_ingredients`, `fn_utc_iso()` (`.US`), dan helper proyeksi JSON.
5. `20261108000005_005_idempotency.sql` — Mesin idempotensi `fn_begin_mutation()`, `fn_finish_mutation()`, `rpc_register_pending_mutation()`, `rpc_lookup_or_seal_receipt()`, dan pemangkasan PII `fn_compact_mutation_receipts_pii()`.
6. `20261108000006_006_rpc_customer.sql` — RPC mutasi pelanggan (`rpc_create_customer_order`, `rpc_cancel_customer_order`, `rpc_submit_canteen_application`, `rpc_save_food_preferences`, `rpc_update_profile_avatar`).
7. `20261108000007_007_rpc_owner.sql` — RPC mutasi pemilik stan (`rpc_owner_save_stall`, `rpc_owner_save_menu`, `rpc_owner_delete_menu`, `rpc_owner_transition_order`).
8. `20261108000008_008_rpc_admin.sql` — RPC mutasi admin (`rpc_admin_set_user_access`, `rpc_admin_review_application`).
9. `20261108000009_009_read_functions.sql` — Fungsi baca terparameter (`STABLE`) dan `rpc_register_user_profile()`.
10. `20261108000010_010_storage.sql` — Konfigurasi bucket `kantin-media`, pencabusan policy listing publik `storage.objects`, `rpc_register_media_asset()`, dan pembersihan aset yatim.
11. `20261108000011_011_indexes.sql` — Indeks kursor keyset, Foreign Key, trigram (`gin_trgm_ops`), dan audit.
12. `20261108000012_012_upgrade_from_legacy.sql` — Migrasi upgrade transaksional bagi database yang sebelumnya pernah memasang skema lama.

Jalankan migrasi ke proyek Supabase Cloud dari direktori `server/`:

```bash
cd server
supabase link --project-ref <PROJECT_REF_ID>
supabase db push
```

## 2. Bootstrap Admin Pertama (`server/supabase/bootstrap/promote_initial_admin.sql`)

Berkas `server/supabase/bootstrap/promote_initial_admin.sql` dipisahkan dari folder `migrations/` agar hanya dapat dijalankan oleh DBA (`postgres` / `supabase_admin`):

1. Buat pengguna pertama di Supabase Auth (Dashboard → *Authentication → Users*) dan catat `UUID`-nya.
2. Jalankan isi `server/supabase/bootstrap/promote_initial_admin.sql` pada koneksi `postgres`, lalu panggil:
   ```sql
   SELECT public.bootstrap_promote_initial_admin(
     p_auth_uid => '<UUID-AUTH-USERS>'::UUID,
     p_username => 'admin_utama',
     p_name => 'Administrator KantinCerdas',
     p_allow_additional_admin => FALSE
   );
   ```

## 3. Setelan Wajib Supabase Cloud, PITR, dan Rotasi Key

1. **Matikan Pendaftaran Publik GoTrue (`enable_signup = false`):** Seluruh registrasi pengguna wajib melewati endpoint backend `POST /v1/auth/register` yang memanggil GoTrue Admin API lalu `public.rpc_register_user_profile`.
2. **Kebijakan Token & Password:** Setel panjang password minimum `>= 8` karakter, `jwt_expiry = 900` detik (15 menit), `enable_refresh_token_rotation = true`, dan aktifkan rate limit pada `/auth/v1/*` serta `/v1/*`.
3. **Pemisahan Staging vs Production & URL Bucket:** Gunakan dua proyek Supabase Cloud terpisah untuk Staging dan Production, lalu setel domain bucket resmi pada masing-masing database:
   ```sql
   ALTER DATABASE postgres SET app.storage_public_base_url = 'https://<project-ref>.supabase.co/storage/v1/object/public/kantin-media/';
   ```
4. **Rotasi `service_role` Key Tanpa Downtime:** Terbitkan secret `service_role` baru di Dashboard Supabase, perbarui `SUPABASE_SERVICE_ROLE_KEY` di secret manager server `/v1/*`, lakukan *rolling restart* server `/v1/*`, lalu cabut key lama.

> **Peringatan:** Proyek Supabase Production wajib mengaktifkan **Point-in-Time Recovery (PITR)** berbasis Continuous WAL Archiving (`RPO` mendekati `0`, `synchronous_commit = on`) sebelum beroperasi. Pemulihan dari *daily snapshot* biasa yang kehilangan transaksi beberapa menit terakhir akan menyebabkan rekonsiliasi `/v1/operations/orders/{id}` menyegel pesanan tunai yang hilang tersebut sebagai `not_created`.

## 4. Katalog Kode Error SQL (`KC001`–`KC022`)

Seluruh `RAISE EXCEPTION` di SQL memakai format `<KODE>: <pesan>`. Error sistem di luar tabel ini (misalnya koneksi putus atau `57P01`) harus dikembalikan server `/v1/*` sebagai `500`/`503` agar klien mempertahankan jurnal lokal dan menjalankan rekonsiliasi:

| Kode (`error.code`) | SQLSTATE | HTTP | Semantik Jurnal Klien | Pola Pesan Standar |
|---|---:|---:|---|---|
| `UNAUTHENTICATED` | `KC001` | `401` | Definitif No-Commit (picu refresh / akhiri sesi) | `UNAUTHENTICATED: Identitas ... wajib diisi.` |
| `FORBIDDEN` | `KC002` | `403` | Definitif No-Commit (hapus dari jurnal) | `FORBIDDEN: ...` |
| `ACCOUNT_DISABLED` | `KC003` | `403` | Definitif No-Commit (cabut sesi lokal & ke login) | `ACCOUNT_DISABLED: Akun ... tidak aktif.` |
| `INVALID_INPUT` | `KC004` | `400`/`422` | Definitif No-Commit (hapus dari jurnal) | `INVALID_INPUT: ...` |
| `INVALID_ORDER_ITEMS` | `KC005` | `400`/`422` | Definitif No-Commit (hapus dari jurnal) | `INVALID_ORDER_ITEMS: ...` |
| `INVALID_QUANTITY` | `KC006` | `400`/`422` | Definitif No-Commit (hapus dari jurnal) | `INVALID_QUANTITY: Kuantitas item wajib bernilai antara 1 dan 99.` |
| `INVALID_REASON` | `KC007` | `400`/`422` | Definitif No-Commit (hapus dari jurnal) | `INVALID_REASON: ...` |
| `INVALID_DECISION` | `KC008` | `400`/`422` | Definitif No-Commit (hapus dari jurnal) | `INVALID_DECISION: Keputusan hanya boleh approved atau rejected.` |
| `INVALID_TRANSITION` | `KC009` | `400`/`422` | Definitif No-Commit (hapus dari jurnal) | `INVALID_TRANSITION: ...` |
| `INVALID_IMAGE_URL` | `KC010` | `400`/`422` | Definitif No-Commit (hapus dari jurnal) | `INVALID_IMAGE_URL: URL ... tidak valid atau bukan berasal dari bucket resmi kantin-media.` |
| `INVALID_INGREDIENTS` | `KC011` | `400`/`422` | Definitif No-Commit (hapus dari jurnal) | `INVALID_INGREDIENTS: ...` |
| `STALL_NOT_FOUND` | `KC012` | `404` | Definitif No-Commit (khusus checkout: dipetakan ke Rejected) | `STALL_NOT_FOUND: Stan tujuan tidak ditemukan.` |
| `STALL_CLOSED` | `KC013` | `409` | Definitif No-Commit (hapus dari jurnal) | `STALL_CLOSED: Stan sedang tutup atau tidak melayani pesanan.` |
| `MENU_UNAVAILABLE` | `KC014` | `409` | Definitif No-Commit (hapus dari jurnal) | `MENU_UNAVAILABLE: Menu ... sedang tidak tersedia.` |
| `PRICE_CHANGED` | `KC015` | `409` | Definitif No-Commit (minta konfirmasi harga baru) | `PRICE_CHANGED: ...` |
| `NO_STALL` | `KC016` | `409` | Definitif No-Commit (dipetakan ke `OwnerNoStallFailure`) | `NO_STALL: Stan ... tidak ditemukan.` |
| `VERSION_CONFLICT` | `KC017` | `409` | Definitif No-Commit (minta muat ulang data) | `VERSION_CONFLICT: ...` |
| `IDEMPOTENCY_PAYLOAD_MISMATCH` | `KC018` | `409` | Definitif No-Commit untuk payload baru (receipt lama tetap utuh) | `IDEMPOTENCY_PAYLOAD_MISMATCH: Payload berbeda untuk Idempotency-Key yang sama.` |
| `LATE_SEALED_REQUEST` | `KC019` | `409` | Definitif No-Commit (ID telah disegel sebagai `not_applied`) | `LATE_SEALED_REQUEST: ...` |
| `IMMUTABLE_VIOLATION` | `KC020` | `409` | Definitif No-Commit (pelanggaran trigger immutability) | `IMMUTABLE_VIOLATION: ...` |
| `LAST_ADMIN_PROTECTED` | `KC021` | `409` | Definitif No-Commit (menolak penghapusan admin terakhir) | `LAST_ADMIN_PROTECTED: Tidak dapat menonaktifkan, menurunkan role, atau menghapus admin aktif terakhir.` |
| `ORDER_INTEGRITY_VIOLATION` | `KC022` | `409` | Definitif No-Commit (invarian `orders` $\leftrightarrow$ `order_items`) | `ORDER_INTEGRITY_VIOLATION: Pesanan ... wajib memiliki minimal 1 item dengan total_price_idr sama dengan jumlah item.` |

## 5. Keputusan Terbuka dan Kewajiban Integrasi Backend `/v1/*`

1. **Rekonsiliasi Mutasi yang Tidak Pernah Sampai ke Server (`OD-02`):** Ketika `GET /v1/operations/{family}/{mutationId}` dipanggil untuk `mutationId` yang belum pernah diterima server pada keluarga `order-cancellations`, `food-preferences`, `owner-mutations`, dan `admin-mutations`, controller Flutter memeriksa kecocokan `pending.matches(result.request)`. `rpc_lookup_or_seal_receipt` telah mendukung parameter `p_fallback_lookup` (jika klien mengirim header `X-Recovery-Intent` ke backend) sekaligus mengembalikan penanda `"unseen_sealed": true` bila `p_fallback_lookup` bernilai `NULL`. Tim harus memilih salah satu opsi integrasi tersebut sebelum mengaktifkan server `/v1/*`.
2. **Penegakan `session_epoch` dan Pencabutan Sesi GoTrue:** Saat `rpc_admin_set_user_access` menonaktifkan pengguna (`is_active = FALSE`), database menaikkan `users.session_epoch` dan mengembalikan `auth_uid`. Server `/v1/*` wajib memeriksa kecocokan `session_epoch` pada setiap request terautentikasi dan segera mencabut refresh token GoTrue milik `auth_uid` tersebut.
3. **Validasi Grapheme dan Magic Bytes di Server `/v1/*`:** Sebelum memanggil RPC PostgreSQL, server Dart wajib memvalidasi panjang grapheme (`.characters.length`) sesuai batas kontrak (database menerapkan batas pertahanan `4x` code point untuk mengakomodasi emoji ZWJ) serta memvalidasi *magic bytes* gambar pada `POST /v1/media/images` sebelum memanggil `rpc_register_media_asset`.
4. **Kewajiban `Idempotency-Key` pada `PUT /v1/auth/profile/avatar`:** Pastikan `AuthApiDataSource.updateProfileAvatar` menyertakan header `Idempotency-Key` (atau server menurunkan kunci deterministik dari sesi dan payload) saat memanggil `rpc_update_profile_avatar`.
