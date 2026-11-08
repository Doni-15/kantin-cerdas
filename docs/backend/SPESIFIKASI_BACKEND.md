# Spesifikasi backend strict

Dokumen ini menetapkan kontrak endpoint REST API `/v1/*`, aturan validasi input, otorisasi lintas peran, protokol idempotensi, dan kode error HTTP antara aplikasi Flutter (`app/`) dan server backend.

## Daftar isi

- [1. Cakupan](#1-cakupan)
- [2. Validasi umum](#2-validasi-umum)
- [3. Otorisasi](#3-otorisasi)
- [4. Tabel/collection logis yang diharapkan](#4-tabelcollection-logis-yang-diharapkan)
- [5. Auth dan sesi](#5-auth-dan-sesi)
- [6. Checkout dan transisi pesanan](#6-checkout-dan-transisi-pesanan)
- [7. Pengajuan, approval dan akses](#7-pengajuan-approval-dan-akses)
- [8. Menu, stan, preferensi, asisten](#8-menu-stan-preferensi-asisten)
- [9. Idempotensi, unknown dan receipt](#9-idempotensi-unknown-dan-receipt)
- [10. Pembacaan, pagination dan cache](#10-pembacaan-pagination-dan-cache)
- [11. Kontrak transport, endpoint, dan kode error HTTP](#11-kontrak-transport-endpoint-dan-kode-error-http)
- [12. Gate integrasi](#12-gate-integrasi)
- [13. Signature repository aktual](#13-signature-repository-aktual)
- [14. Pintu adapter aplikasi (Sudah Terhubung)](#14-pintu-adapter-aplikasi-sudah-terhubung)
- [15. Pilihan stack server backend](#15-pilihan-stack-server-backend)

## 1. Cakupan

Tiga role: customer, owner, admin. Owner juga boleh memakai fitur pribadi customer atas userId yang sama. Fitur: katalog, keranjang satu stan, checkout tunai pengambilan, tracking/cancel, pengajuan stan, kelola usaha/pesanan, administrasi akses, preferensi, rekomendasi, serta upload foto profil/menu/stan dengan validasi Zero-Trust.

Belum ada delivery, wallet, QRIS, refund, push notification, atau chat owner. Lupa password baru meminta email; konsumsi link/token reset belum ada di app. Jangan menganggap fitur SRS arsip sudah diimplementasikan.

Backend menentukan otorisasi, harga, waktu, versi dan status. Client hanya mengirim intent dan batas persetujuan.

## 2. Validasi umum

ID string opaque nonkosong; server menghasilkan ID entity, client menghasilkan submissionId/mutationId. Waktu UTC dipetakan ke DateTime; updatedAt >= createdAt. Uang integer IDR, bukan float. Versi integer positif monoton; CAS membandingkan expectedVersion secara atomik.

| Input | Batas kontrak |
| --- | --- |
| Harga/anggaran | 1–10.000.000 IDR; budget boleh null |
| Kuantitas item | Integer 1–99; menuId unik per pesanan; satu stan |
| Catatan item/order | Maksimal 300 grapheme |
| Nama menu/stan | Wajib, trim, maksimal 120 grapheme |
| Deskripsi menu/stan | Maksimal 1.000 grapheme |
| Blok/lokasi | Wajib, maksimal 120 grapheme |
| Persiapan | 1–180 menit |
| Pengajuan | Nama 120, deskripsi wajib 1.000, lokasi 120; telepon max 24 karakter, 8–15 digit; optional + di awal, digit/spasi/()- |
| Alasan | Maksimal 300 grapheme; wajib saat reject atau ubah akses |

> Perlu konfirmasi: `OwnerOrderTransition.maxRejectionReasonLength` di `app/lib/features/owner/domain/entities/owner_order_transition.dart` membatasi alasan penolakan pesanan pemilik stan hingga 240 grapheme, sedangkan tabel ini dan alasan admin menetapkan 300 grapheme.
| Bahan dihindari | Maksimal 20, masing-masing 60 grapheme, trim, unik case-insensitive, tanpa koma/newline per elemen |
| Pencarian | Maksimal 120 grapheme |
| Pesan asisten | Wajib, maksimal 500 grapheme |
| Pagination | Default 30, request yang mengekspos limit 1–100, response <= limit |
| File gambar (`POST /v1/media/images`) | Maksimal 2 MB (`2.097.152` byte), Magic Bytes wajib JPG/PNG/WEBP (`image/jpeg`, `image/png`, `image/webp`), bebas payload skrip/polyglot (`<script`, `<?php`, `<svg`, dll.), nama file kanonis acak `{sanitizedActorId}_{category}_{uuidV4}.{ext}` (`category`: `profile_avatar` \| `menu_photo` \| `stall_photo`) |
| URL gambar (`image_url` / `avatar_url`) | Opsional (`null` atau string HTTP/HTTPS valid maksimal 512 karakter tanpa userInfo, karakter kontrol/HTML, atau path traversal `..`) |

Grapheme berarti karakter yang terlihat termasuk emoji gabungan. Jangan diam-diam memotong input atau mengganti dengan byte count. Normalisasi harus selaras constructor domain; response sukses sesuai hasil normalisasi.

Auth client sekarang: username ASCII alnum/underscore/titik 6–20; password 6–128 grapheme; nama wajib maksimal 120 grapheme; email pola dasar maksimal 254 grapheme (seluruh panjang dihitung berbasis `.characters.length`). **Sebelum adapter auth aktif**, tetapkan kebijakan kekuatan password server, normalisasi identifier, expiry dan rate limit; sinkronkan dengan backend. Minimum client bukan rekomendasi keamanan produksi.

## 3. Otorisasi

| Operasi | Customer aktif | Owner aktif | Admin aktif |
| --- | --- | --- | --- |
| Katalog/asisten | Ya | Ya | Tidak lewat kontrak customer |
| Checkout/order/preferensi/cancel pribadi | Milik sendiri | Milik sendiri | Tidak |
| Submit pengajuan baru | Sesuai latest status | Tidak | Tidak |
| Read/recovery pengajuan lama | Milik sendiri | Milik sendiri setelah promosi | Melalui kontrak admin |
| Menu/stan/pesanan usaha | Tidak | Stan miliknya | Tidak lewat kontrak owner |
| Ringkasan/pengguna/pengajuan admin | Tidak | Tidak | Ya |
| Ubah akses | Tidak | Tidak | Target customer/owner, bukan diri sendiri/admin |

Server memeriksa token, akun aktif, role terkini dan ownership setiap request termasuk dalam transaksi write. ID payload tidak memberi izin. Registrasi selalu customer; bootstrap admin prosedur server terpisah; role owner hanya approval. Nonaktif berlaku pada token lama juga. Aktivasi kembali tidak otomatis menghidupkan sesi dicabut. Jangan bocorkan detail resource lintas akun; kebijakan 403/404 konsisten.

## 4. Tabel/collection logis yang diharapkan

Nama snake_case usulan; adapter memetakan ke entity camelCase. SQL/document database boleh dipakai jika invariant sama.

| Tabel | Field utama | Relasi, constraint, indeks |
| --- | --- | --- |
| users | id:string PK; username,username_key,email,email_key,name:string; avatar_url:string?; role:enum; is_active:bool; version:int; created_at,updated_at:timestamp | username_key/email_key unik; versi naik pada profil/role/akses; indeks pencarian admin; credential bukan data publik |
| stalls | id:string PK; owner_id:string; name,block,description:string; image_url:string?; is_open:bool; prep_time_min:int; version:int; created_at,updated_at | FK users; owner_id unik (satu stan per owner); hanya approval membuat stan; owner_id immutable |
| menus | id:string PK; stall_id:string; name,description:string; category:enum; price_idr:int; is_available:bool; image_url:string?; version:int; deleted_at:timestamp? | FK stalls; rice/noodles/drinks/snacks/other; indeks stall+filter+urutan; delete tidak merusak order snapshot |
| orders | id:string PK; order_number:string; customer_id,stall_id:string; customer_name,stall_name:string snapshot; status,payment_status:enum; total_price_idr:int; note:string; version:int; rejection_reason:string?; created_at,updated_at | order_number unik; FK logis users/stalls; indeks customer+status+created_at+id dan stall+status+created_at+id; total=sum item |
| order_items | order_id,menu_id:string; position:int; name:string snapshot; quantity,unit_price_idr:int; note:string | unique order_id+menu_id; urutan stabil; nama/harga snapshot tetap meski menu berubah/dihapus; tanpa cascade penghapusan riwayat |
| canteen_applications | id,applicant_id:string; name,description,location,phone:string; status:enum; version:int; reason:string?; created_at; previous_id:string?; reviewed_by:string?; reviewed_at:timestamp?; approved_stall_id:string? | FK users; latest pointer/constraint satu aktif submitted/reviewing; previous latest rejected; unique approved_stall_id; riwayat dipertahankan |
| food_preferences | customer_id:string PK; max_budget_idr:int?; vegetarian:bool; avoid_ingredients:string[]; version:int; updated_at | FK users; satu record per identitas termasuk owner |
| mutation_receipts | actor_id,operation,request_id:string; payload_hash:string; request_snapshot:object; outcome:enum; result_snapshot:object?; result_version:int?; sealed:bool; created_at,completed_at | unique actor+operation+ID; fingerprint canonical; hasil final immutable; lookup hanya aktor yang sah |
| audit_events | id,actor_id,operation,target_id,request_id:string; before_version,after_version:int?; reason:string?; outcome:string; occurred_at | append-only server; korelasi receipt; minimalkan PII; tidak log password/token |
| auth_sessions (custom auth) | id,user_id,token_hash:string; expires_at,revoked_at,created_at | Hash token, revocation efektif; managed Auth dapat mengganti dengan mekanisme setara |

Password custom memakai password hashing layanan, bukan plaintext atau reversible encryption; managed Auth tidak menduplikasi credential ke users. Pilihan algoritma, retensi PII, TTL sesi, rotasi dan backup harus ditinjau tim backend.

Field reviewed_by/previous_id adalah kebutuhan server tambahan, bukan field Flutter yang sudah ada. User tidak mempunyai version/stallId; AdminUserRecord membungkus user+version. CanteenApplication tidak mempunyai applicantName. Order menyimpan nama pada saat transaksi. Lihat [kamus entity](KAMUS_DATA.md).

## 5. Auth dan sesi

Login identifier+password → credential/aktif diverifikasi → User + accessToken tidak kosong, refreshToken/expiresAt opsional menurut LoginResponseModel → token disimpan lokal → navigasi berdasarkan role layanan. Tidak mengirim credential lewat route/log.

Restore membaca token → cek expiry yang diketahui → bila kedaluwarsa dan `refreshToken` tersedia, memanggil `POST /v1/auth/refresh` (*single-flight* di `AuthInterceptor` & `AuthRepositoryImpl`), lalu memverifikasi `getCurrentUser` otoritatif. Kegagalan jaringan/timeout saat refresh mempertahankan token lokal (tidak me-logout pengguna); hanya penolakan definitif `401`/`403` berkode error backend yang membersihkan sesi. Mutasi non-`GET` (`POST`/`PUT`/`PATCH`/`DELETE`) yang menerima `401` me-refresh token tetapi tidak di-retry otomatis oleh interceptor agar bebas duplikasi. Periksa akses akun terikat identitas dan generasi sesi awal.

Logout menghapus token lokal dahulu; revoke server memakai token snapshot, bukan global token sesi baru. Gagal storage bukan logout sukses. Change password memverifikasi password saat ini dan sesi aktif; kebijakan revoke sesi lain perlu disepakati.

Reset email → validasi/rate limit → acknowledgement netral baik email terdaftar/tidak. Tidak mengubah sesi aktif. Layanan harus menyediakan token/link sekali pakai, expiry, consume atomik, anti-replay dan halaman reset; alur konsumsi link belum ada di app. Acknowledgement bukan bukti email sampai.

## 6. Checkout dan transisi pesanan

1. Ambil actor dari sesi customer/owner pribadi, bukan payload userId.
2. Terima submissionId, draft satu stan dan confirmation unitPricesIdr/total/cashOnPickup. Draft memuat menuId, quantity, note dan orderNote; tidak memiliki expectedMenuVersion.
3. Atomik: stan buka, seluruh menu ada/milik stan/tersedia, input valid, harga server persis harga yang disetujui, total server sama tanpa biaya tambahan.
4. Harga berbeda → priceChanged tanpa order; jangan otomatis menerima harga baru.
5. Commit order waiting+unpaid, snapshot item/harga/nama, receipt submission dan audit konsisten. Kembalikan orderId setelah commit.
6. Respons hilang → lookup ID sama; tidak membuat pesanan baru.

| Awal | Aksi | Akhir | Payment |
| --- | --- | --- | --- |
| waiting/unpaid | Owner terima | processing | unpaid |
| waiting/unpaid | Owner tolak + alasan | rejected | notCharged |
| waiting/unpaid | Customer pemilik cancel | cancelled | notCharged |
| processing/unpaid | Owner siap | ready | unpaid |
| ready/unpaid | Owner selesai, cashReceived=true dan foodHandedOver=true | completed | paid |

Terminal tidak dibuka kembali. Cancel dan accept bersaing pada expectedVersion sama: tepat satu commit. Transisi mempertahankan identity, nomor, item, note, total, createdAt; updatedAt/versi maju. Rejected perlu alasan, status lain tidak membawa rejectionReason. Paid adalah pencatatan uang tunai oleh owner, bukan bukti payment gateway.

## 7. Pengajuan, approval dan akses

Submit hanya customer aktif. previousId/previousVersion null hanya belum pernah mengajukan; ulang hanya terhadap latest rejected dengan versi cocok. Buat record baru submitted tanpa reason, riwayat tetap, role belum berubah.

Review admin hanya submitted/reviewing dengan CAS. Reject wajib alasan. Approve wajib konsisten antara keputusan, tepat satu stan dan role owner; applied baru sah setelah seluruh side effect wajib tersedia. Customer melakukan Periksa akses akun untuk role baru; userId dan data pribadi lama tetap.

SetUserAccess menolak diri sendiri/admin lain/perubahan role. CAS + perubahan aktif + versi + alasan audit konsisten. Perubahan profil/role lain juga menaikkan versi agar snapshot admin lama ditolak.

## 8. Menu, stan, preferensi, asisten

Stan owner diperoleh dari sesi; jangan membolehkan memilih ownerId. Create menu ID baru/versi>=1; update/delete CAS+ownership+mutationId. Respons update mencerminkan input normalisasi. Delete meninggalkan receipt/tombstone versi dan tidak menghapus snapshot pesanan. Save stan mempertahankan id/ownerId.

Preferensi: expectedVersion null=create-if-absent; lainnya CAS. Respons applied menyertakan snapshot tepat pada commit request, bukan preferensi terbaru dari write lain.

Asisten membaca katalog/preferensi aktor; menu rekomendasi harus data nyata yang sah, bukan ID/harga karangan. API key AI hanya di server. Respons timeout/rate limit/error dipetakan; preferensi bahan bukan jaminan alergi. Riwayat percakapan server belum menjadi kontrak; app menyimpan percakapan dalam state UI.

## 9. Idempotensi, unknown dan receipt

Client menyimpan ID+snapshot di jurnal sebelum dispatch. Server mengikat actor+operation+ID ke fingerprint payload canonical lengkap: target, expectedVersion, harga, alasan, flags, previousId. ID sama/payload berbeda ditolak tanpa menimpa receipt. ID sama/payload identik mengembalikan hasil commit asli, tanpa write baru.

Otorisasi/prasyarat, CAS, data, receipt immutable dan audit harus konsisten. Client tidak retry write otomatis, tetapi server tetap tahan replay/perangkat lain.

| Keluarga | Outcome lookup | Bukti wajib |
| --- | --- | --- |
| Checkout | pending/confirmed/notCreated | customerId, submissionId; confirmed orderId |
| Pengajuan | pending/submitted/notSubmitted | customerId, submissionId, snapshot awal submitted sesuai input |
| Owner | pending/applied/notApplied | PendingOwnerMutation lengkap, target/stan/jenis, hasil ID/versi, status/payment bila order |
| Admin | pending/applied/notApplied | PendingAdminMutation lengkap, versi/intent akses/keputusan; approval owner+approvedStallId |
| Preferensi | pending/applied/notApplied | PendingFoodPreferences+input/expectedVersion dan snapshot commit |
| Cancel | pending/applied/notApplied | Aktor/order/stan/nomor/ID/versi; cancelled+notCharged+versi meningkat |

> Perlu konfirmasi: Enum Dart `OrderCancellationOutcome` memakai nama `cancelled` (parser menerima string `"applied"` maupun `"cancelled"`), dan pemulihan `GET /v1/operations/{family}/{id}` untuk mutasi yang belum pernah sampai ke server memerlukan keputusan antara pengiriman header `X-Recovery-Intent` atau relaksasi parser saat `unseen_sealed = true`.

**Tidak ditemukan bukan notApplied.** Versi berubah/null/read gagal bukan receipt. Final negatif hanya sah setelah ID disegel atomik terhadap late commit. Lookup boleh mengoordinasikan seal di server tetapi tidak mengirim ulang mutasi bisnis. Pending mengunci aksi sampai hasil pasti.

Jurnal client tidak punya TTL. Jangan menghapus dedupe/receipt/seal dengan TTL singkat lalu menghidupkan ID lama. Sebelum produksi pilih retensi selama ID masih dapat dipakai, atau protokol expiry yang menolak permanen ID lama dan dipahami recovery client. Pilihan kedua perlu perubahan kontrak/migrasi jurnal. Sepakati retensi PII dan tombstone minimal; tidak otomatis menyimpan seluruh payload sensitif selamanya.

Error definitif menjamin no commit sekarang maupun terlambat. Timeout/disconnect/5xx/response invalid sesudah dispatch berarti unknown. Storage jurnal gagal menahan submit; tidak ada tombol hapus pending sebagai pengganti recovery.

## 10. Pembacaan, pagination dan cache

CustomerCatalog sekarang snapshot penuh dengan daftar menu umum dan nested stan konsisten. Jika terlalu besar, ubah kontrak bersama app; jangan menyamarkan halaman pertama sebagai snapshot lengkap.

Cursor opaque terikat aktor, filter, urutan stabil+tie-breaker ID dan snapshot. Stale cursor ditolak sebagai failure read yang dapat dimuat ulang. Response <= limit, ID unik, nextCursor null pada akhir, tidak kosong/berulang. Default 30, batas 1–100 bila query mengekspos limit.

History personal hanya completed/rejected/cancelled; aktif waiting/processing/ready. Owner hanya stall sendiri. Detail null hanya setelah read otoritatif menyatakan tidak ditemukan. Cache tidak boleh dipakai untuk menentukan hasil mutasi. App belum menjanjikan realtime lintas perangkat.

## 11. Kontrak transport, endpoint, dan kode error HTTP

Envelope error standar dari backend: `{ "code": "...", "message": "...", "request_id": "...", "field_errors": {...}, "details": {...} }` (atau dibungkus di dalam objek `"error": { ... }`) tanpa menyertakan token maupun stack trace.

**Penting (`hasBackendErrorCode`)**: Parser klien (`mapDioException` → `ApiException`) memeriksa keberadaan field `code` bertipe string nonkosong pada body JSON (`error.hasBackendErrorCode`).
- Pada pembacaan entitas tunggal (`getMyStall`, `getMyOrder`, `getUser`, `getApplication`, `getMyApplication`, `getMyPreferences`), hanya HTTP `404` yang disertai `code` backend nonkosong (mis. `{"code": "NOT_FOUND", "message": "..."}`) yang diterjemahkan menjadi `null` (data belum ada). HTTP `404` kosong dari reverse proxy/gateway tanpa JSON `code` dianggap sebagai kegagalan jaringan/konfigurasi dan tidak dianggap data kosong.
- Pada seluruh mutasi terjurnal, hanya respons error HTTP `400`/`401`/`403`/`404`/`409`/`422` yang memiliki `hasBackendErrorCode == true` yang dianggap sebagai penolakan definitif (*no-commit*) sehingga jurnal lokal dapat dibersihkan/dibuka kuncinya. Respons error dari proxy/gateway tanpa `code` JSON bisnis dipetakan menjadi status `unknown`/`unconfirmed` dan mempertahankan jurnal lokal untuk rekonsiliasi.

| Kondisi | Semantik di Client | HTTP & `code` Wajib dari Backend |
| --- | --- | --- |
| Input invalid / prasyarat gagal sebelum commit | Definitif (*no-commit* dijamin) | `400` / `422` + `code` nonkosong (+ `field_errors` opsional) |
| Kredensial login salah | Definitif pada login | `401` + `code: "INVALID_CREDENTIALS"` |
| Password saat ini salah (ubah password) | Definitif tanpa menghapus sesi aktif | `401` + `code: "INVALID_CURRENT_PASSWORD"` |
| Token akses kedaluwarsa / tidak valid | Memicu *single-flight* `POST /v1/auth/refresh` atau akhiri sesi | `401` + `code: "TOKEN_EXPIRED"` \| `"UNAUTHENTICATED"` \| `"INVALID_TOKEN"` |
| Akun dinonaktifkan admin | Langsung mencabut sesi lokal & mengarahkan ke login | `403` + `code: "ACCOUNT_DISABLED"` |
| Akses ditolak / bukan pemilik resource | Definitif (*forbidden* / *access failure*) | `403` + `code` nonkosong (mis. `"FORBIDDEN"`) |
| Entitas tunggal tidak ditemukan (read opsional) | Diterjemahkan ke `null` oleh datasource read | `404` + `code: "NOT_FOUND"` |
| Owner belum memiliki stan | Dipetakan ke `OwnerNoStallFailure` | `404` / `409` + `code: "NO_STALL"` |
| Konflik username / email saat registrasi | Dipetakan ke `AuthUsernameTakenFailure` / `AuthEmailTakenFailure` | `409` + `code: "USERNAME_TAKEN"` \| `"EMAIL_TAKEN"` (atau `field_errors.username`/`email`) |
| Harga menu berubah saat checkout | Dipetakan ke `CustomerOrderPriceChangedFailure` tanpa membuat pesanan | `409` + `code: "PRICE_CHANGED"` |
| Stan tutup / menu habis / pesanan ditolak saat checkout | Dipetakan ke `CustomerOrderRejectedFailure` tanpa commit | `400` / `409` / `422` + `code: "STALL_CLOSED"` \| `"MENU_UNAVAILABLE"` \| `"ORDER_REJECTED"` |
| Konflik versi CAS (`expected_version` tidak cocok) | Definitif (*no-commit* dijamin); pengguna diminta muat ulang | `409` + `code: "VERSION_CONFLICT"` |
| Rate limit | Read dapat dicoba ulang; mutasi terjurnal tidak dianggap gagal definitif kecuali dijamin *no-commit* | `429` + `code: "RATE_LIMITED"` \| `"TOO_MANY_REQUESTS"` (+ header `Retry-After`) |
| Timeout / `5xx` / koneksi putus / respons tanpa `code` | Status `unknown` / `unconfirmed`; wajib dipulihkan lewat endpoint lookup `/v1/operations/*` | Bukan *no-commit* otomatis |
| `API_BASE_URL` belum diisi pada saat build/run | `*NotConfiguredFailure` lokal | Klien tidak mengirim request jaringan |

Kontrak endpoint HTTP berawalan `/v1`:
- **Auth & Profil**: `POST /v1/auth/login`, `POST /v1/auth/register`, `GET /v1/auth/me`, `POST /v1/auth/refresh`, `POST /v1/auth/logout`, `POST /v1/auth/change-password`, `POST /v1/auth/password-reset`, `PUT /v1/auth/profile/avatar` (menerima `{'avatar_url': string?}` untuk memperbarui atau menghapus foto profil dan mengembalikan objek `User`).
- **Media (Zero-Trust Image Upload)**: `POST /v1/media/images` (`multipart/form-data` dengan field `category`, `file_name` kanonis `{actorId}_{category}_{uuidV4}.{ext}`, dan biner `file` tervalidasi Magic Bytes JPG/PNG/WEBP <= 2 MB + header `Idempotency-Key`; mengembalikan `{'image_url': 'https://...'}`).
- **Customer**: `GET /v1/catalog`, `POST /v1/customer/orders`, `GET /v1/customer/orders`, `GET /v1/customer/orders/{orderId}`, `POST /v1/customer/orders/{orderId}/cancel`, `GET /v1/customer/canteen-applications/me`, `POST /v1/customer/canteen-applications` (menyertakan `previous_id` dan `previous_version`), `GET` & `PUT /v1/customer/food-preferences`, `POST /v1/customer/assistant/recommend`.
- **Owner (berbasis sesi)**: `GET` & `PUT /v1/owner/stall`, `GET` & `POST /v1/owner/menus`, `PUT` & `DELETE /v1/owner/menus/{id}` (`DELETE` menyertakan query `expected_version` serta body), `GET /v1/owner/orders`, `GET /v1/owner/orders/{orderId}`, `POST /v1/owner/orders/{orderId}/transition`.
- **Admin**: `GET /v1/admin/summary`, `GET /v1/admin/users`, `GET /v1/admin/users/{userId}`, `POST /v1/admin/users/{userId}/access`, `GET /v1/admin/applications`, `GET /v1/admin/applications/{applicationId}`, `POST /v1/admin/applications/{applicationId}/review`.
- **Pemulihan Mutasi Terjurnal (`GET /v1/operations/{family}/{requestId}`)**: `/v1/operations/orders/{submissionId}`, `/v1/operations/order-cancellations/{mutationId}`, `/v1/operations/canteen-applications/{submissionId}`, `/v1/operations/food-preferences/{mutationId}`, `/v1/operations/owner-mutations/{mutationId}`, `/v1/operations/admin-mutations/{mutationId}`. Seluruh 10 operasi mutasi terjurnal wajib mengirim header `Idempotency-Key`.

Timeout app umumnya 30 detik; checkout memakai batas 45 detik pada controller. Timeout client tidak membatalkan transaksi server. Tetapkan budget server dan tetap sediakan lookup hasil terlambat.

## 12. Gate integrasi

1. Sepakati auth policy, wire/error schema, indeks/uniqueness, kapasitas katalog/batas payload, retensi/seal dan timezone/normalisasi.
2. Implementasikan read+mapper ketat: required field, enum, integer, timestamp dan ownership. Null/error tidak disamakan.
3. Implementasikan write+CAS+dedupe+receipt+lookup lengkap sebelum flag configured true.
4. Uji duplicate ID, ID sama/payload berbeda, harga berubah, race cancel/accept, dua perangkat, akun nonaktif dan promosi role.
5. Uji commit lalu response hilang, lookup sebelum/selama commit, seal lalu late request, restart, storage gagal, token lama, receipt setelah entity berubah.
6. Pastikan entry normal bebas fixture/secret, TLS/rate limit/audit/monitoring/backup ditinjau, tidak ada service key di APK.
7. Lulus analyzer, tes app, tes kontrak adapter, integrasi staging, build dan device QA. Ganti debug signing sebelum release.

## 13. Signature repository aktual

Diambil dari source terkini (`app/lib/`); import dan komentar dihilangkan. Entity adalah kontrak Dart, sedangkan serialisasi JSON ditangani oleh model di `app/lib/features/*/data/models/` dan `app/lib/core/media/`. Jurnal lokal disimpan di perangkat menggunakan `FlutterSecureStorage` dan tidak dipindahkan ke server.

### media_upload_repository

Source: `app/lib/core/media/media_upload_repository.dart`

```dart
abstract interface class MediaUploadRepository {
  bool get isConfigured;

  Future<String> uploadImage(ValidatedUploadImage image);
}
```

### admin_repository

Source: `app/lib/features/admin/domain/repositories/admin_repository.dart`

```dart
abstract interface class AdminRepository {
  bool get isMutationConfigured;

  Future<AdminMutationLookup> lookupMutation({required String mutationId});


  Future<AdminUserRecord?> getUser({required String userId});

  Future<AdminUserRecord> setUserAccess(
    AdminUserAccessChange change, {
    required String mutationId,
  });

  Future<AdminApplicationPage> listApplications({
    CanteenApplicationStatus? status,
    String? cursor,
    int limit = 30,
  });

  Future<CanteenApplication?> getApplication({required String applicationId});

  Future<CanteenApplication> reviewApplication(
    AdminApplicationReview review, {
    required String mutationId,
  });

  Future<AdminSummary> getSummary();

  Future<AdminUserPage> listUsers({
    required String search,
    String? cursor,
    int limit = 30,
  });
}
```

### auth_repository

Source: `app/lib/features/auth/domain/repositories/auth_repository.dart`

```dart
abstract interface class AuthRepository {
  Future<User> login({required String identifier, required String password});

  Future<User> register({
    required String name,
    required String username,
    required String email,
    required String password,
  });

  Future<void> requestPasswordReset({required String email});

  Future<User?> restoreSession();

  Future<void> logout();

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<User> updateProfileAvatar({required String? avatarUrl});
}
```

### canteen_application_repository

Source: `app/lib/features/customer/domain/repositories/canteen_application_repository.dart`

```dart
abstract interface class CanteenApplicationRepository {
  bool get isSubmissionConfigured;

  Future<CanteenApplication?> getMyApplication();

  Future<CanteenApplication> submit(PendingCanteenApplication submission);

  Future<CanteenApplicationLookup> lookupSubmission({
    required String submissionId,
  });
}
```

### customer_assistant_repository

Source: `app/lib/features/customer/domain/repositories/customer_assistant_repository.dart`

```dart
abstract interface class CustomerAssistantRepository {
  Future<AssistantReply> recommend(String message);
}
```

### customer_catalog_repository

Source: `app/lib/features/customer/domain/repositories/customer_catalog_repository.dart`

```dart
abstract interface class CustomerCatalogRepository {
  Future<CustomerCatalog> getCatalog();
}
```

### customer_order_repository

Source: `app/lib/features/customer/domain/repositories/customer_order_repository.dart`

```dart
abstract interface class CustomerOrderRepository {
  bool get isCheckoutConfigured;

  Future<String> createOrder({
    required OrderDraft draft,
    required String submissionId,
    required CustomerOrderPriceConfirmation confirmation,
  });

  Future<OrderSubmissionLookup> lookupSubmission({
    required String submissionId,
  });

}
```

### customer_order_tracking_repository

Source: `app/lib/features/customer/domain/repositories/customer_order_tracking_repository.dart`

```dart
abstract interface class CustomerOrderTrackingRepository {
  bool get isCancellationConfigured;

  Future<OrderCancellationLookup> lookupCancellation({
    required String mutationId,
  });

  Future<OrderRecord> cancelMyOrder(
    CustomerOrderCancellation cancellation, {
    required String mutationId,
  });

  Future<OrderRecord?> getMyOrder({required String orderId});

  Future<OrderRecordPage> listMyOrders({
    required bool history,
    String? cursor,
    int limit = 30,
  });
}
```

### food_preferences_repository

Source: `app/lib/features/customer/domain/repositories/food_preferences_repository.dart`

```dart
abstract interface class FoodPreferencesRepository {
  bool get isSaveConfigured;

  Future<FoodPreferencesSnapshot?> getMyPreferences();

  Future<FoodPreferencesSnapshot> saveMyPreferences(
    FoodPreferencesUpdate update, {
    required String mutationId,
  });

  Future<FoodPreferencesLookup> lookupSave({required String mutationId});
}
```

### owner_repository

Source: `app/lib/features/owner/domain/repositories/owner_repository.dart`

```dart
abstract interface class OwnerRepository {
  bool get isMutationConfigured;

  Future<OwnerMutationLookup> lookupMutation({required String mutationId});


  Future<OwnerStall?> getMyStall();
  Future<OwnerMenuPage> listMenus({
    required String stallId,
    required String search,
    bool? available,
    String? cursor,
    int limit = 30,
  });

  Future<OwnerMenu> saveMenu(
    OwnerMenuInput input, {
    required String mutationId,
  });

  Future<void> deleteMenu({
    required String id,
    required int expectedVersion,
    required String mutationId,
  });

  Future<OwnerStall> saveStall(
    OwnerStallInput input, {
    required String mutationId,
  });
  Future<OrderRecordPage> listOrders({
    required String stallId,
    OrderStatus? status,
    String? cursor,
    int limit = 30,
  });

  Future<OrderRecord?> getMyOrder({
    required String stallId,
    required String orderId,
  });

  Future<OrderRecord> transitionOrder(
    OwnerOrderTransition input, {
    required String mutationId,
  });
}
```


## 14. Pintu adapter aplikasi (Sudah Terhubung)

Seluruh interface domain di `app/lib/features/*/domain/repositories/` dan `app/lib/core/media/media_upload_repository.dart` telah memiliki implementasi konkret berbasis `Dio` dan diikat secara terpusat di `buildProductionOverrides()` (`app/lib/app/production_overrides.dart`).

| Fitur | Kontrak Domain & DataSource | Implementasi Produksi | Provider DI |
| --- | --- | --- | --- |
| Auth & Profil | `AuthRepository` / `AuthDataSource` | `AuthRepositoryImpl` / `AuthApiDataSource` | `authRepositoryProvider`, `authDataSourceProvider`, `authTokenRefresherProvider` |
| Media Upload | `MediaUploadRepository` | `DioMediaUploadRepository` | `mediaUploadRepositoryProvider`, `dioMediaUploadRepositoryProvider` |
| Katalog | `CustomerCatalogRepository` / `CustomerCatalogDataSource` | `CustomerCatalogRepositoryImpl` / `CustomerCatalogApiDataSource` | `customerCatalogRepositoryProvider`, `customerCatalogDataSourceProvider` |
| Checkout | `CustomerOrderRepository` / `CustomerOrderDataSource` | `CustomerOrderRepositoryImpl` / `CustomerOrderApiDataSource` | `customerOrderRepositoryProvider`, `customerOrderDataSourceProvider` |
| Tracking/cancel | `CustomerOrderTrackingRepository` / `CustomerOrderTrackingDataSource` | `CustomerOrderTrackingRepositoryImpl` / `CustomerOrderTrackingApiDataSource` | `customerOrderTrackingRepositoryProvider`, `customerOrderTrackingDataSourceProvider` |
| Pengajuan | `CanteenApplicationRepository` / `CanteenApplicationDataSource` | `CanteenApplicationRepositoryImpl` / `CanteenApplicationApiDataSource` | `canteenApplicationRepositoryProvider`, `canteenApplicationDataSourceProvider` |
| Preferensi | `FoodPreferencesRepository` / `FoodPreferencesDataSource` | `FoodPreferencesRepositoryImpl` / `FoodPreferencesApiDataSource` | `foodPreferencesRepositoryProvider`, `foodPreferencesDataSourceProvider` |
| Asisten | `CustomerAssistantRepository` / `CustomerAssistantDataSource` | `CustomerAssistantRepositoryImpl` / `CustomerAssistantApiDataSource` | `customerAssistantRepositoryProvider`, `customerAssistantDataSourceProvider` |
| Owner | `OwnerRepository` / `OwnerDataSource` | `OwnerRepositoryImpl` / `OwnerApiDataSource` | `ownerRepositoryProvider`, `ownerDataSourceProvider` |
| Admin | `AdminRepository` / `AdminDataSource` | `AdminRepositoryImpl` / `AdminApiDataSource` | `adminRepositoryProvider`, `adminDataSourceProvider` |

Seluruh flag konfigurasi (`isConfigured`, `isCheckoutConfigured`, `isCancellationConfigured`, `isSubmissionConfigured`, `isSaveConfigured`, `isMutationConfigured`) otomatis bernilai `true` ketika aplikasi dijalankan dengan `--dart-define=API_BASE_URL=https://...` (`AppEnvironment.isApiConfigured`).

Prinsip integrasi server yang wajib dijaga:
- Null/kosong hanya dikembalikan ketika pembacaan otoritatif berhasil (atau `404` dengan kode `NOT_FOUND` untuk entitas tunggal); error jaringan/akses/data rusak tidak boleh dianggap kosong.
- Identitas aktor selalu berasal dari token sesi terverifikasi di server, bukan dipercaya dari body request.
- Error definitif (`hasBackendErrorCode == true` pada `400`/`401`/`403`/`409`/`422`) wajib menjamin tidak ada commit maupun *late commit*; timeout atau `5xx` setelah dispatch adalah `unknown` dan dipulihkan melalui `/v1/operations/*`.
- Cursor paginasi terikat aktor/filter/urutan; `items.length <= limit`, ID unik, dan `next_cursor` tidak boleh string kosong atau berulang.
- Versi integer positif monoton untuk CAS (`expected_version`); receipt menyimpan hasil saat commit (immutable), bukan snapshot terkini yang sudah berubah oleh request lain.
- Uang dalam integer IDR penuh, metode pembayaran `CASH_ON_PICKUP` tanpa biaya tambahan tersembunyi.
- Mutasi tidak di-retry otomatis oleh `AuthInterceptor`; pembacaan (`GET`/`HEAD`/`OPTIONS`) dapat di-retry satu kali secara transparan setelah *single-flight token refresh* berhasil.

## 15. Pilihan stack server backend

Aplikasi Flutter berkomunikasi melalui protokol standar REST API JSON (`/v1/*`) dan `multipart/form-data` (`/v1/media/images`) menggunakan `Dio`. Tim backend bebas menggunakan teknologi server pilihan (misalnya Go, Node.js/NestJS, Laravel, Python/FastAPI, atau Cloud Run/Functions) selama memenuhi kontrak endpoint, struktur JSON, kode error, transaksi atomik CAS, dan idempotensi `Idempotency-Key` pada dokumen ini. Apabila di masa depan ingin mengganti transport selain REST `/v1/*`, cukup sediakan implementasi `*_datasource.dart` baru dan arahkan di `buildProductionOverrides()` tanpa mengubah layer `domain/` maupun `presentation/`.
