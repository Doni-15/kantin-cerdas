# Status dan pengujian

**Sumber tunggal status proyek.** Diperbarui pada 4 November 2026 berdasarkan verifikasi langsung terhadap source code di repositori (`app/lib` dan `app/test`).

## Hasil yang sudah dibuktikan

| Pemeriksaan | Hasil verifikasi aktual |
| --- | --- |
| Kesiapan arsitektur & adapter REST API | **Siap diintegrasikan ke backend.** Seluruh 9 `RepositoryImpl`, 9 `ApiDataSource`, `DioMediaUploadRepository`, `AuthInterceptor` (*single-flight refresh*), `Secure*MutationJournal`, dan komposisi DI `buildProductionOverrides()` telah selesai diimplementasikan |
| Batas Clean Architecture & isolasi simulasi | Lulus `architecture_boundary_test.dart` (`core` ↛ `features`, `presentation` ↛ `data`, `domain` ↛ `data`/UI, `repositories` & kontrak `*_datasource.dart` ↛ `Dio`, `app/lib/` bebas simulasi) |
| Dependency sesuai lock | Lulus (`flutter_localizations` aktif, `cupertino_icons` dihapus) |
| Format | Lulus (`dart format --output=none --set-exit-if-changed lib test`) |
| Analyzer `lib` dan `test` (`strict-casts`, `strict-inference`, `strict-raw-types`) | `No issues found!` (exit 0) |
| Tes otomatis (`flutter test --no-pub`) | **94 tes lulus** (mencakup 5 audit batas arsitektur, Zero-Trust media security & image upload audit, unit test core network/storage/pagination/mutation ID, domain standardization, 9 repository data layer & 6 lookup mutasi + pemetaan HTTP 429/5xx/404, presentation reconciliation, router, dan alur simulasi terhubung) |
| APK debug normal & simulasi | Build berhasil (exit 0) |

## Status kesiapan backend dan pekerjaan tersisa

- **Sisi Aplikasi Flutter (Client/Frontend): Siap 100% untuk integrasi backend.**
  - Klien HTTP berbasis `Dio` (`dioClientProvider` dan `baseDioClientProvider`) telah terhubung ke `--dart-define=API_BASE_URL=...` melalui `AppEnvironment`.
  - Seluruh endpoint `/v1/*` (Auth, Katalog, Checkout, Tracking/Cancel Order, Pengajuan Kantin, Preferensi Makanan, Asisten, Owner, Admin, Media Upload, serta 6 endpoint rekonsiliasi `/v1/operations/*`) telah memiliki DTO model, parser ketat, mapper error (`ApiException` + `hasBackendErrorCode`), dan pengiriman header `Idempotency-Key`.
- **Sisi Server Backend: Belum dibangun.**
  - Tim backend dapat langsung mengimplementasikan server REST API sesuai kontrak pada [Spesifikasi Backend](backend/SPESIFIKASI_BACKEND.md) dan [Kamus Data](backend/KAMUS_DATA.md) tanpa perlu mengubah arsitektur aplikasi Flutter.
- **Pekerjaan lanjut sebelum rilis produksi:**
  - Pembangunan layanan server backend & database sesuai kontrak `/v1/*`.
  - Uji integrasi nyata (end-to-end) antara aplikasi dan server staging, termasuk transaksi lintas perangkat.
  - QA visual/perangkat interaktif pada tiga role (`customer`, `owner`, `admin`).
  - Penyediaan `key.properties` produksi untuk rilis Android (`build.gradle.kts` + `proguard-rules.pro` sudah dikonfigurasi dengan R8 code shrinking aktif dan menolak build `Release` secara eksplisit melalui `GradleException` apabila `key.properties` belum lengkap).

## Mengulang pemeriksaan

Dari folder `app`:

```bash
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub --fatal-infos --fatal-warnings lib test
flutter test --no-pub --reporter expanded
flutter build apk --debug --no-pub -t lib/main.dart
flutter build apk --debug --no-pub -t test/support/main_simulation.dart
```

Output kedua perintah `flutter build apk --debug` memakai path `build/app/outputs/flutter-apk/app-debug.apk` yang sama: salin APK pertama ke nama lain sebelum menjalankan build kedua jika ingin menyimpan keduanya.

## Pipeline CI/CD (GitHub Actions)

Repositori ini telah dilengkapi dua workflow otomatis di `.github/workflows/`:

1. **Continuous Integration ([`.github/workflows/ci.yml`](../.github/workflows/ci.yml))**
   - Berjalan otomatis pada setiap `push` dan `pull_request` ke branch `main`, `develop`, dan `staging` (serta `workflow_dispatch`).
   - **Job `quality-and-tests`**: Memvalidasi keutuhan tautan & inventaris dokumen `docs/`, menjalankan `flutter pub get --enforce-lockfile`, `dart format --set-exit-if-changed`, `flutter analyze --fatal-infos --fatal-warnings`, audit batas arsitektur `architecture_boundary_test.dart`, dan seluruh 94 tes otomatis.
   - **Job `build-debug-apks`**: Mengompilasi dua APK debug terpisah (`kantin-cerdas-normal-debug.apk` dan `kantin-cerdas-simulation-debug.apk`) beserta checksum `SHA256SUMS.txt` dan mengunggahnya sebagai GitHub Actions Artifact. Variabel opsional `STAGING_API_BASE_URL` di GitHub Variables dapat diisi untuk menyuntikkan `--dart-define=API_BASE_URL=...` pada APK debug normal.
2. **Continuous Delivery & Rilis ([`.github/workflows/cd-release.yml`](../.github/workflows/cd-release.yml))**
   - Berjalan saat tag versi `v*.*.*` (mis. `v1.0.0`) di-push atau dipicu manual lewat `workflow_dispatch`.
   - Menjalankan *quality gate* penuh, memvalidasi skema `https://` pada `PROD_API_BASE_URL`, men-decode keystore rilis ke `android/key.properties`, mengompilasi `kantin-cerdas-release.apk` dan `kantin-cerdas-release.aab` (dengan R8 shrinking aktif), membersihkan berkas kredensial sementara (`if: always()`), serta menerbitkan **GitHub Release** otomatis beserta `SHA256SUMS.txt`.
   - **GitHub Secrets yang wajib diatur untuk CD Release**:
     - `PROD_API_BASE_URL`: URL HTTPS backend produksi (mis. `https://api.kantincerdas.ac.id`).
     - `ANDROID_KEYSTORE_BASE64`: Hasil `base64 -w 0 kantin-cerdas-release.jks`.
     - `ANDROID_KEYSTORE_PASSWORD`: Password keystore produksi.
     - `ANDROID_KEY_ALIAS`: Alias kunci di dalam keystore.
     - `ANDROID_KEY_PASSWORD`: Password kunci rilis.

## Checklist langsung — belum dicentang

Jalankan mode simulasi, lakukan skenario berikut dan catat hasil nyata.

| Skenario | Hasil yang harus diperiksa |
| --- | --- |
| Pelanggan cari menu → cart → checkout | Satu stan, harga persetujuan sama, satu order, daftar/detail diperbarui |
| Owner terima → siap → selesai | Hanya stan sendiri; versi maju; selesai perlu cashReceived dan foodHandedOver |
| Pelanggan buka riwayat | completed+paid; rincian/harga snapshot tetap |
| Akun kedua membuka ID order pertama | Tidak memperoleh data orang lain |
| Customer mengajukan → admin menyetujui | Satu stan dan role owner; submit sendiri tidak memberi role |
| Akun dipromosikan periksa akses | Navigasi owner, data/recovery pribadi tetap miliknya |
| Admin nonaktifkan akun | Akun target ditolak saat akses ulang; diri sendiri/admin tidak dapat ditarget |
| Unknown → restart → lookup | Tidak retry write; receipt memulihkan hasil sama |
| Conflict | Input dipertahankan, refresh/review diperlukan |
| Slow/empty/readError | Skeleton lalu hasil/kosong/error berbeda, retry read tersedia |
| Asisten kirim lalu logout | Late reply tidak masuk akun baru |
| Preferensi → rekomendasi | Budget/bahan/vegetarian terhubung; bukan AI/alergi guarantee |
| Lupa password | Acknowledgement simulasi, tidak ada email nyata |

Ulangi light/dark, teks besar, layar kecil, keyboard, screen reader dan back Android. Simulasi satu perangkat tidak membuktikan transaksi server lintas perangkat atau keamanan backend.


Format pencatatan: tanggal; device/OS; revisi source; akun/skenario; langkah; hasil yang diharapkan; hasil aktual; lulus/gagal; bukti/log. Jangan masukkan password nyata/token ke laporan.

## Urutan berikutnya

QA tiga role → perbaiki temuan bila ada → terima alur app → sepakati kontrak backend → implementasi/integrasi staging → uji nyata → release review. Source dan kontrak aplikasi sudah tersedia; “tidak perlu revisi lagi selamanya” tidak dapat dijamin.
