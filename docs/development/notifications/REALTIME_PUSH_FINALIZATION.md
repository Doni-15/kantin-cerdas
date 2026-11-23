# Kantin Cerdas v2.0.0 — Realtime & Push Notification Finalization (Backend + Firebase Android Client)

**Status Pekerjaan:** Local Non-Secret Implementation & QA Complete (No Production/Hosted Deployment, No Secrets Handled)  
**Acuan Bisnis & Teknis:** `ORDER-017` (`FINAL · LOCKED`), `ORDER-017A` (`FINAL · LOCKED`), `ORDER-013B` (`FINAL · LOCKED`), `ADMIN-005` (`FINAL · LOCKED`), `RT-TECH-001`–`RT-TECH-005`, skenario QA `R1` & `R2`.

---

## 1. Pemisahan Status Akhir

### A. DONE & TESTED LOCALLY
1. **Migrasi Forward-Only Database (`server/supabase/migrations/20261122000002_realtime_and_push_notifications.sql`)**:
   - Memanfaatkan kembali `public.order_notification_events` (7 kejadian `ORDER-017A`) dan `public.order_status_events` tanpa mengubah migrasi historis (`20261118000001`–`20261122000001`).
   - Menambahkan tabel RLS `service_role`-only (`realtime_channel_topics`, `order_realtime_signals`, `user_push_devices`, `order_push_deliveries`), trigger sinyal realtime (termasuk `selesai` & `gagal_diambil`), trigger rotasi topik & pencabutan perangkat saat status/role berubah (`R2`), deduplikasi delivery, serta atomic claim dengan bounded retry.
   - Terverifikasi pada disposable PostgreSQL 16 (8 migrasi + 7 suite SQL termasuk `realtime_push.sql` lulus).

2. **Backend Realtime & Push Worker (`server/backend/lib/src/modules/notifications/`)**:
   - Terpasang via `server/backend/lib/src/app/ai_bootstrap.dart` tanpa mengubah `bin/server.dart`, `bin/server_with_owner.dart`, `bin/server_all.dart`, `Dockerfile`, ataupun `.github/workflows/*`.
   - Endpoint `/v1/notifications/*` (status, register/revoke device, private grant, signal polling, live SSE stream dengan revalidasi sesi `R2`) + `PushNotificationWorker` (best-effort, strict 7 event `ORDER-017A`, payload non-sensitif, retry backoff terbatas).
   - Terverifikasi lewat `dart analyze --fatal-infos --fatal-warnings` (0 issue), `dart test` (**292/292 PASS**), serta Live Docker QA (`realtime_push_live_qa.py` x2, `ai_live_qa.py`, `customer_live_qa.py` lulus).

3. **Integrasi Flutter Android Firebase Cloud Messaging (Non-Secret) (`app/lib/features/notifications/` + `app/android/` + `app/lib/app/auth_view.dart`)**:
   - Dependensi minimal ditambahkan tanpa upgrade massal: `firebase_core: ^5.2.0` dan `firebase_messaging: ^17.1.0`.
   - Konfigurasi Android Gradle & Manifest tanpa menaikkan Gradle (`9.1.0`), AGP (`9.0.1`), maupun Kotlin (`2.3.20`):
     - `app/android/settings.gradle.kts`: registrasi plugin `com.google.gms.google-services` versi `4.4.4` (`apply false`).
     - `app/android/app/build.gradle.kts`: menerapkan `com.google.gms.google-services` secara otomatis **hanya ketika** `app/android/app/google-services.json` disediakan manual oleh pemilik proyek (build debug/CI non-secret tetap lulus tanpa file palsu).
     - `app/android/app/src/main/AndroidManifest.xml`: izin `POST_NOTIFICATIONS` (Android 13+), default channel `kantin_order_updates`, dan intent-filter `FLUTTER_NOTIFICATION_CLICK`.
     - `app/android/app/src/main/kotlin/com/kantincerdas/app/MainActivity.kt`: membuat Android 8+ `NotificationChannel("kantin_order_updates", "Pembaruan Pesanan", IMPORTANCE_HIGH)`.
     - `.gitignore`: menambahkan `**/google-services.json`, `**/key.properties`, `*.jks`, dan `*.keystore`.
   - Implementasi Dart terpisah di belakang boundary `PushMessagingClient`:
     - `FirebasePushMessagingClient` & `initializeFirebaseMessagingSafely()` + top-level `@pragma('vm:entry-point') firebaseMessagingBackgroundHandler`: aman saat `google-services.json` belum ada (degradasi halus tanpa mengganggu checkout/order/realtime).
     - `FirebasePushTokenSource`: menangani permintaan izin notifikasi (termasuk `denied`/`deniedPermanently` pada Android 13+), mengambil token FCM registrasi (`getToken()`), dan mengalirkan pembaruan token (`onTokenRefresh`) ke backend `POST /v1/notifications/devices` dengan deduplikasi token.
     - `RealtimeOrderSyncNotifier`: mendaftarkan token awal, memperbarui saat `onTokenRefresh`, membatalkan listener & mencabut perangkat (`DELETE /v1/notifications/devices/<deviceId>`) pada logout/account switch (`R2`).
     - `PushNotificationCoordinator` & `AuthView`: menangani notifikasi foreground (SnackBar + tombol `Lihat` + invalidasi REST otoritatif), background tap (`onMessageOpenedApp`), dan cold-start tap (`getInitialMessage`), deduplikasi `event_id`, serta gerbang autentikasi & otorisasi ketat (`resolveAuthorizedPushDestination`) sebelum membuka `CustomerOrderDetailPage` atau `OwnerOrderDetailPage` existing (menolak unauthenticated, profil belum lengkap, Admin/`ADMIN-005`, dan eskalasi Customer -> Owner).
   - Terverifikasi lewat `flutter analyze --no-pub --fatal-infos --fatal-warnings lib test` (0 issue), `flutter test --no-pub` (**116/116 PASS** termasuk `realtime_notifications_test.dart` dan `firebase_push_client_test.dart`), serta `flutter build apk --debug` (`✓ Built build/app/outputs/flutter-apk/app-debug.apk`).

---

### B. PREPARED (Belum Diuji Live dengan Firebase Sungguhan)
1. **Android `FirebasePushMessagingClient` & Background Handler**: terhubung penuh ke SDK `firebase_core` + `firebase_messaging` dan lolos kompilasi APK debug, namun belum dijalankan terhadap Firebase project resmi dengan `google-services.json` asli.
2. **Backend `HttpFcmTransport` & `GoogleOAuth2TokenProvider`**: siap mengirim FCM HTTP v1 (`FCM_ENABLED=false` secara default), lolos uji matematika RS256 dan `MockClient`, namun belum diuji live ke Google OAuth2/FCM.
3. **Backend `SupabaseHttpRealtimeBroadcaster`**: siap mengirim broadcast privat (`REALTIME_SUPABASE_BROADCAST_ENABLED=false` secara default), lolos uji `MockClient`, belum diuji pada Supabase Realtime hosted.

---

### C. BLOCKED / OWNER MANUAL ACTION
1. **Firebase Console & File `app/android/app/google-services.json`:**
   - Package Name permanen yang disepakati adalah `id.kantincerdas.app` (file `google-services.json` sudah diunduh dan FCM API V1 sudah Enabled).
   - Penempatan `app/android/app/google-services.json` dilakukan **bersamaan dengan migrasi terkoordinasi** `applicationId` Android dari `com.kantincerdas.app` ke `id.kantincerdas.app` (jangan commit file ke Git publik).
2. **Backend FCM HTTP v1 Authentication — `PENDING` (Kebijakan GCP):**
   - Pembuatan Service Account private key JSON diblokir oleh kebijakan keamanan Google Cloud (`iam.disableServiceAccountKeyCreation`). **Jangan menonaktifkan kebijakan keamanan GCP.**
   - Biarkan `FCM_ENABLED=false` dan `FCM_WORKER_ENABLED=false` sementara waktu (SSE + REST fallback tetap berjalan) sampai pendekatan autentikasi keyless tanpa Google Cloud Billing yang aman untuk Railway Free (misal GCP Workload Identity Federation berbasis OIDC) diputuskan dan diimplementasikan. *(Catatan: Cloud Run / Cloud Functions v2 memerlukan akun billing GCP aktif meskipun memiliki kuota gratis.)*
3. **Pengujian Perangkat Fisik & Hosted Pilot (`R1` & `R2`)**:
   - Menerapkan migrasi `20261122000002_realtime_and_push_notifications.sql` pada Supabase hosted, membangun APK dengan `google-services.json` resmi, dan menguji pengiriman push nyata (foreground, background, terminated, logout 2 perangkat, penolakan izin Android 13+) pada perangkat Android fisik/Play Services.

---

## 2. Matriks Event `ORDER-017A`

| Event Outbox | Transisi Status | Penerima Push | Realtime Signal? | Push FCM? |
|---|---|---|---|---|
| `order_created` | `null -> menunggu_konfirmasi` | Owner | Ya | **Ya** |
| `order_cancelled` | `menunggu_konfirmasi -> dibatalkan` | Owner | Ya | **Ya** |
| `order_accepted` | `menunggu_konfirmasi -> diproses` | Customer | Ya | **Ya** |
| `order_rejected` | `menunggu_konfirmasi -> ditolak` | Customer | Ya | **Ya** |
| `order_ready` | `diproses -> siap_diambil` | Customer | Ya | **Ya** |
| `order_failed_fulfill` | `diproses -> gagal_dipenuhi` | Customer | Ya | **Ya** |
| `order_not_picked_up` | `siap_diambil -> tidak_diambil` | Customer | Ya | **Ya** |
| *(tidak ada)* | `siap_diambil -> selesai` | *(tidak ada)* | **Ya** | **Tidak** |
| *(tidak ada)* | `siap_diambil -> gagal_diambil` | *(tidak ada)* | **Ya** | **Tidak** |
| *(tidak ada)* | Seluruh aktivitas Admin | *(tidak ada)* | **Tidak** | **Tidak** |

---

## 3. Panduan Konfigurasi Manual (Nama Variabel & Lokasi File Saja — Tanpa Nilai Rahasia)

### A. Lokasi File Konfigurasi Android (Dikelola Manual Pemilik Proyek)
- `app/android/app/google-services.json` — diunduh manual dari Firebase Console untuk Package Name permanen `id.kantincerdas.app` (dipasang bersamaan saat migrasi terkoordinasi `applicationId` dari `com.kantincerdas.app` ke `id.kantincerdas.app`). Begitu file ini tersedia di lokasi tersebut, `app/android/app/build.gradle.kts` otomatis menerapkan plugin `com.google.gms.google-services`.
- `app/android/key.properties` & keystore rilis — hanya untuk build rilis bertanda tangan (dikelola manual / GitHub Secrets).

### B. Variabel Lingkungan Backend (Railway / Server)
| Nama Variabel | Nilai Default | Keterangan |
|---|---|---|
| `FCM_ENABLED` | `false` | Ubah ke `true` setelah seluruh kredensial FCM siap |
| `FCM_PROJECT_ID` | *(kosong)* | Firebase Project ID |
| `FCM_CLIENT_EMAIL` | *(kosong)* | `client_email` dari Firebase Service Account |
| `FCM_PRIVATE_KEY` | *(kosong)* | `private_key` PKCS#8 dari Firebase Service Account |
| `FCM_TOKEN_URI` | `https://oauth2.googleapis.com/token` | Endpoint OAuth2 Google |
| `FCM_API_BASE_URL` | `https://fcm.googleapis.com` | Base URL FCM HTTP v1 |
| `FCM_REQUEST_TIMEOUT_SECONDS` | `10` | Timeout per request FCM HTTP v1 |
| `FCM_MAX_RETRY_ATTEMPTS` | `5` | Batas percobaan ulang error sementara |
| `FCM_WORKER_ENABLED` | `false` | Aktifkan retry sweep otomatis worker push |
| `FCM_WORKER_POLL_INTERVAL_SECONDS` | `3` | Interval dasar worker |
| `REALTIME_SUPABASE_BROADCAST_ENABLED` | `false` | Ubah ke `true` jika mengaktifkan broadcast Supabase Realtime hosted |
| `REALTIME_SIGNAL_POLL_INTERVAL_MS` | `500` | Interval broker SSE saat ada subscriber aktif |
| `REALTIME_STREAM_HEARTBEAT_SECONDS` | `15` | Interval heartbeat `: ping` SSE |
| `REALTIME_SESSION_RECHECK_SECONDS` | `5` | Interval revalidasi sesi & deteksi rotasi topik (`R2`) |
