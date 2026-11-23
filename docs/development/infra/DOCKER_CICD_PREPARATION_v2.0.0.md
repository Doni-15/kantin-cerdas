# Preparasi Docker & CI/CD — Kantin Cerdas v2.0.0

**Tanggal:** 2026-11-22  
**Mode:** `INFRASTRUCTURE PREPARATION ONLY` (belum ada deployment Railway, belum ada migration Supabase hosted, belum ada GitHub Release, belum ada tag `v2.0.0`).

---

## 1. Ringkasan Status Komponen

| Komponen | Berkas | Status | Keterangan |
| --- | --- | --- | --- |
| Backend Multi-Stage Dockerfile | `server/backend/Dockerfile`, `docker-entrypoint.sh`, `.dockerignore` | **PREPARED & TESTED (Lokal)** | Build AOT `bin/server.dart` pada `dart:3.12.2` -> `debian:13.6-slim`, non-root UID `10001`, mendukung Railway `PORT` & `0.0.0.0` tanpa mengubah source Dart |
| GitHub Actions CI | `.github/workflows/ci.yml` | **PREPARED (YAML Validated Locally)** / **NOT ACTIVATED (Remote)** | Menjalankan hygiene/whitespace (+ blokir legacy `cd-release.yml`), Dart backend analyze+test, PostgreSQL 16 migrations+SQL tests, Flutter analyze+test, Android Debug APK, Docker build+Railway Host/healthcheck smoke, dan `CI Required Gate`; eksekusi runner GitHub menunggu push branch |
| Railway CD Config-as-Code | `server/backend/railway.json` | **PREPARED** / **NOT ACTIVATED** | Target 1 service modular monolith (`Root Directory = /server/backend`, `Railway Config File Path = /server/backend/railway.json`, `/v1/health`); autodeploy & `Wait for CI` belum diaktifkan |
| Android APK Build Workflow | `.github/workflows/android-apk-prepare.yml` | **PREPARED** / **NOT ACTIVATED** | Trigger manual (`workflow_dispatch`) untuk verifikasi build `2.0.0` tanpa menerbitkan GitHub Release dan tanpa membuat keystore baru |
| Supabase Hosted Migration & Config | `server/supabase/migrations/*.sql` | **BLOCKED / NOT ACTIVATED** | Belum diterapkan ke proyek Supabase hosted (kebijakan READ-ONLY) |
| Production Keystore & Release Signing | `app/android/app/build.gradle.kts` (`key.properties`) | **BLOCKED / NOT ACTIVATED** | Identitas aplikasi `com.kantincerdas.app` sudah siap membaca `android/key.properties`; GitHub Secrets keystore produksi belum disediakan |

---

## 2. Struktur Docker Backend & Cara Build Lokal

### Toolchain & Base Image Terkunci (Sesuai Lingkungan Tervalidasi)
- **Builder:** `dart:3.12.2` (berbasis Debian 13.6 `trixie`), memakai `dart pub get --enforce-lockfile` agar tidak pernah meng-upgrade dependensi otomatis.
- **Runtime:** `debian:13.6-slim` (kecocokan glibc exact dengan `dart:3.12.2`), hanya memasang `ca-certificates`, membuat user non-root `appuser` (`10001:10001`), dan menyalin binary AOT hasil kompilasi + `docker-entrypoint.sh`.
- **Entrypoint Kanonis:** Default build target adalah `ARG ENTRYPOINT=bin/server.dart` (mengaktifkan Health + Auth + Catalog + Owner + Customer + Admin + AI + Notifications dalam satu proses modular monolith).
- **Dukungan `PORT` Railway Tanpa Refactor Kode:** `ServerConfig` di `server/backend/lib/src/core/config/server_config.dart` membaca `SERVER_PORT` dan `SERVER_HOST`. Skrip `server/backend/docker-entrypoint.sh` memetakan `PORT -> SERVER_PORT` (bila `SERVER_PORT` kosong), memastikan `SERVER_HOST=0.0.0.0`, lalu menjalankan `exec /app/bin/server` agar `SIGTERM` diterima langsung oleh PID 1. **Jangan menyetel `SERVER_PORT` tetap di Railway Variables** agar tidak menimpa `PORT` dinamis dari Railway.
- **Keamanan Image:** `.dockerignore` menolak `.env`, `.env.*`, `secrets/`, `*.jks`, `*.keystore`, `test/`, dan `.dart_tool/`. Tidak ada database lokal di dalam container; seluruh data/Auth/Storage tetap menuju Supabase via environment variable.

### Perintah Build & Uji Lokal

```bash
# Build image produksi lokal (default bin/server_all.dart)
docker build -f server/backend/Dockerfile -t kantin-cerdas-backend:local server/backend

# Contoh build dengan entrypoint legacy bila diperlukan untuk perbandingan
docker build -f server/backend/Dockerfile --build-arg ENTRYPOINT=bin/server.dart -t kantin-cerdas-backend:legacy server/backend

# Jalankan container lokal dengan konfigurasi QA (misal .dart_tool/auth-verification/shelf.env)
docker run --rm --network host \
  --env-file .dart_tool/auth-verification/shelf.env \
  -e PORT=18580 \
  kantin-cerdas-backend:local
```

---

## 3. Pipeline CI GitHub Actions (`.github/workflows/ci.yml`)

- **Trigger:** `push` dan `pull_request` pada branch `rebuild/clean-start` dan `main`, serta `workflow_dispatch`.
- **Versi Terkunci:** Dart `3.12.2`, Flutter `3.44.9` (`stable`), PostgreSQL `16`, `--enforce-lockfile` pada `dart pub get` & `flutter pub get`.
- **Syarat PASS (Seluruh Job Wajib `success`):**
  1. `hygiene`: memastikan tidak ada `.env` / `key.properties` / `*.jks` / `*.keystore` yang ter-track di Git, serta menjalankan `git diff --check` atas rentang commit/PR.
  2. `backend`: `dart pub get --enforce-lockfile` -> `dart analyze --fatal-infos --fatal-warnings` -> `dart test`.
  3. `sql-migrations`: menjalankan `provider_schema.sql` -> seluruh `server/supabase/migrations/*.sql` urut -> `auth.sql`, `owner.sql`, `catalog_compat.sql`, `customer.sql`, `admin.sql`, `ai.sql` pada service container `postgres:16` disposable.
  4. `flutter`: `flutter pub get --enforce-lockfile` -> `flutter analyze --no-pub --fatal-infos --fatal-warnings lib test` -> `flutter test --no-pub`.
  5. `docker-backend`: membangun `server/backend/Dockerfile`, memeriksa user non-root (`UID != 0`), memastikan `/app/.env` tidak ada di image, serta memverifikasi container hidup dengan `PORT=18080` dan `/v1/health` mengembalikan `"status":"ok"`.
  6. `ci-gate`: gerbang tunggal (`if: always()`) yang **gagal apabila ada job yang bukan `success`** (tidak pernah meloloskan status `skipped`).

---

## 4. Persiapan Railway CD (`server/backend/railway.json`)

- **Arsitektur Target:** Satu Railway service untuk satu backend modular monolith Dart Shelf (`Dockerfile` di `Root Directory = server/backend`), terhubung ke Supabase Cloud.
- **Konfigurasi Tersedia:** `server/backend/railway.json` menetapkan `DOCKERFILE`, `healthcheckPath: "/v1/health"`, `healthcheckTimeout: 30`, `restartPolicyType: "ON_FAILURE"`, `numReplicas: 1`.

### Environment Variables & Secrets Railway (Diisi Saat Aktivasi Nanti)
- **Aplikasi & Server:** `APP_ENV=staging` (untuk deployment pengujian pertama; naikkan ke `production` saat rilis live), `APP_DEBUG=false`, `APP_VERSION=2.0.0`, `LOG_FORMAT=json`, `LOG_INCLUDE_STACK_TRACE=false`. **Jangan menyetel `SERVER_PORT`** (`PORT` disuntik otomatis oleh Railway dan dipetakan oleh `docker-entrypoint.sh`; `SERVER_HOST=0.0.0.0` sudah default di Dockerfile).
- **Supabase Cloud (Secrets):** `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, `SUPABASE_SECRET_KEY`. (`SUPABASE_PROJECT_REF`, `AUTH_JWKS_URL`, `AUTH_JWT_ISSUER`, dan `STORAGE_PUBLIC_BASE_URL` otomatis diturunkan dari `SUPABASE_URL` bila dikosongkan.)
- **Auth & Security:** `AUTH_JWT_AUDIENCE=authenticated` (**wajib tanpa default**), `AUTH_JWT_ALLOWED_ALGORITHMS=ES256`, `AUTH_REQUIRE_EMAIL_VERIFIED=true`, `AUTH_GOOGLE_ENABLED=false` (atau `true` di `staging` saat siap uji A1–A4), `AUTH_GOOGLE_PRODUCTION_VERIFIED=false` (ubah `true` hanya sesudah uji A1–A4 hosted lulus), `AUTH_RECOVERY_LINK_TTL_SECONDS=3600`, `SECURITY_ALLOWED_HOSTS=<your-railway-service>.up.railway.app,healthcheck.railway.app` (**wajib sertakan `healthcheck.railway.app`** agar probe `/v1/health` Railway tidak ditolak HTTP 403), `SECURITY_ENABLE_SECURITY_HEADERS=true`, `CORS_ENABLED=false` (Android-only), `STORAGE_BUCKET_NAME=kantin-media`.
- **AI Food Assistant & Firebase FCM (Default Aman — Pending):** `AI_PROVIDER_ENABLED=false`, `AI_FREE_TIER_VERIFIED=false`, `AI_PRIVACY_AUDIENCE_VERIFIED=false`, `AI_PROJECT_DAILY_CAP=0`, `FCM_ENABLED=false`, `FCM_WORKER_ENABLED=false`, `REALTIME_SUPABASE_BROADCAST_ENABLED=false`. *(Jangan mengaktifkan Gemini sebelum gerbang `docs/development/ai/AI_FUTURE_ACTIVATION.md` lulus, dan jangan mengaktifkan FCM sebelum autentikasi keyless tanpa Cloud Billing tersedia.)*

### Cara Mengaktifkan `Wait for CI` di Railway (Setelah Milestone Siap)
1. Pastikan seluruh perubahan lokal v2.0.0 sudah di-review, di-commit, workflow lama `origin/main:.github/workflows/cd-release.yml` (dengan project ref Supabase lama) dihapus saat integrasi ke `main`, dan di-push ke branch `main`.
2. Pastikan GitHub Actions `Kantin Cerdas CI` (`.github/workflows/ci.yml`) minimal **1x lulus penuh** pada `main` (`CI Required Gate` hijau) **sebelum** mengaktifkan toggle **Wait for CI**.
3. Pada GitHub Repository Settings -> Branch Protection Rules, wajibkan status check **`CI Required Gate`** pada branch `main`.
4. Pada Railway Dashboard -> Service -> Settings:
   - Set **Source Repo** ke `Doni-15/kantin-cerdas` dan **Branch** ke `main`.
   - Set **Root Directory** ke `/server/backend`.
   - Set **Railway Config File Path** (Config-as-code) secara eksplisit ke `/server/backend/railway.json` *(Railway tidak otomatis membaca `railway.json` dari Root Directory tanpa path ini)*.
   - Generate Public Domain (`<your-railway-service>.up.railway.app`), lalu isi seluruh Environment Variables & Secrets di tab Variables (termasuk `SECURITY_ALLOWED_HOSTS=<your-railway-service>.up.railway.app,healthcheck.railway.app`, tanpa `SERVER_PORT`).
   - Aktifkan toggle **Wait for CI** setelah run CI pertama di `main` terbukti hijau.

---

## 5. Konfigurasi Supabase Hosted yang Diperlukan Saat Rilis

1. Terapkan seluruh 8 migrasi `server/supabase/migrations/*.sql` secara berurutan (`20261118000001_auth_initial.sql` sampai `20261122000002_realtime_and_push_notifications.sql`). Lihat panduan lengkap di `server/supabase/README.md`. **Jangan** menerapkan fixture `provider_schema.sql` ke hosted.
2. Jalankan `server/supabase/verify_initial_schema.sql` dan verifikasi seluruh tabel RLS, RPC, trigger, serta bucket privat `kantin-avatars` & `kantin-media` aktif dengan policy restrictive backend-only.
3. Konfigurasi SMTP untuk email mahasiswa, asymmetric JWT `ES256`, Redirect URLs (`id.kantincerdas.oauth://auth/google?kc_state=*`, `id.kantincerdas.oauth://auth/verify-email`), serta template OTP/recovery sesuai `docs/AUTH.md`.
4. Jalankan uji penerimaan hosted `A1`–`A4` sebelum mengaktifkan Google OAuth produksi (`AUTH_GOOGLE_PRODUCTION_VERIFIED=true`).

---

## 6. Mekanisme APK Build & GitHub Releases (`v2.0.0`)

- **Identitas & Signing Existing (`app/android/app/build.gradle.kts`):**
  - `applicationId` / `namespace`: `com.kantincerdas.app`
  - Java/Kotlin target: **Java 17**, Gradle **9.1.0**, AGP **9.0.1**, Kotlin **2.3.20**, Flutter **3.44.9**
  - `build.gradle.kts` sudah mendukung `app/android/key.properties` (`storeFile`, `storePassword`, `keyAlias`, `keyPassword`) dan `AUTH_EMAIL_LINK_HOST` manifest placeholder.
  - `app/android/.gitignore` sudah mengabaikan `key.properties`, `*.jks`, dan `*.keystore`.
- **Workflow Persiapan (`.github/workflows/android-apk-prepare.yml`):**
  - Hanya berjalan manual via `workflow_dispatch`, wajib lulus `flutter analyze` & `flutter test` terlebih dahulu, menggunakan `--build-name=2.0.0` & `--build-number=<N>`, menghasilkan `SHA256SUMS.txt`, menghapus berkas signing sementara pada `if: always()`, dan mengunggah artifact privat (`7` hari) **tanpa menerbitkan GitHub Release**.
- **GitHub Secrets yang Dibutuhkan Nanti (untuk mode signed release):**
  - `ANDROID_KEYSTORE_BASE64` (encode base64 dari keystore rilis resmi pemilik proyek — **bukan** keystore acak dari CI)
  - `ANDROID_KEYSTORE_PASSWORD`
  - `ANDROID_KEY_ALIAS`
  - `ANDROID_KEY_PASSWORD`
- **Aktivasi GitHub Release (Saat v2.0.0 Siap Nanti):** Setelah seluruh QA perangkat fisik & hosted lulus, buat workflow/tag trigger terpisah atau tambahkan langkah `gh release create` setelah verifikasi signature & checksum, lalu barulah buat tag `v2.0.0`.

---

## 7. Daftar Pending Work Infrastruktur

| ID | Pekerjaan Tertinggal | Status | Dependency | Acceptance Criteria |
| --- | --- | --- | --- | --- |
| `INFRA-DEP-001` | Eksekusi nyata `.github/workflows/ci.yml` pada GitHub Actions runner | `NOT ACTIVATED` | Review lokal, commit, & push branch ke GitHub | Seluruh 6 job (`hygiene`..`ci-gate`) lulus hijau di GitHub Actions |
| `INFRA-DEP-002` | Koneksi Railway Service + Variables + aktifkan `Wait for CI` | `NOT ACTIVATED` | `INFRA-DEP-001` & Supabase hosted siap | Deploy otomatis hanya berjalan sesudah `CI Required Gate` lulus dan `/v1/health` 200 di domain Railway |
| `INFRA-DEP-003` | Penerapan 8 migrasi & konfigurasi SMTP/Redirect URLs di Supabase Hosted | `BLOCKED` | Window deployment & akses proyek Supabase baru | Semua migrasi `20261118000001..20261122000002` sukses & uji `A1`–`A4` lulus |
| `INFRA-DEP-004` | Penyimpanan keystore produksi resmi di GitHub Secrets | `BLOCKED` | Keystore resmi pemilik proyek + migrasi terkoordinasi `id.kantincerdas.app` | `android-apk-prepare.yml` mode `release_prepare` sukses menghasilkan APK tersign + `SHA256SUMS.txt` |
| `INFRA-DEP-005` | Publikasi APK `v2.0.0` melalui GitHub Releases & tag `v2.0.0` | `NOT ACTIVATED` | `INFRA-DEP-002`, `INFRA-DEP-003`, `INFRA-DEP-004`, QA perangkat fisik | Tag `v2.0.0` & GitHub Release memuat APK signed + SHA-256 terverifikasi |
| `INFRA-DEP-006` | Penyelarasan whitespace legacy (`server.dart`, `bootstrap.dart`, `router.dart`) sebelum commit final | `PREPARED` | Persetujuan pemilik repo (saat ini file legacy READ-ONLY) | `git diff --check` global bersih tanpa warning trailing whitespace |

---

## 8. Checklist Aktivasi CD Milestone v2.0.0

- [ ] Seluruh fitur & QA lokal (Auth, Catalog, Owner, Customer, Admin, AI fallback) ditinjau dan di-commit rapi.
- [ ] Push ke branch integrasi dan pastikan seluruh job di `.github/workflows/ci.yml` (`CI Required Gate`) berstatus **PASS** (bukan `skipped`).
- [ ] Aktifkan Branch Protection pada branch deployment target dengan required check `CI Required Gate`.
- [ ] Terapkan seluruh migration SQL ke Supabase hosted, verifikasi Storage/Auth/SMTP/App Links, dan jalankan uji `A1`–`A4`.
- [ ] Konfigurasi service Railway (`Root Directory = server/backend`), isi seluruh Secrets/Variables, aktifkan **Wait for CI**, dan verifikasi `/v1/health` + smoke test end-to-end.
- [ ] Pasang 4 secret signing Android di GitHub Secrets, uji `android-apk-prepare.yml` (`release_dry_run`), verifikasi instalasi APK pada perangkat Android fisik, lalu aktifkan publikasi GitHub Release `v2.0.0`.
