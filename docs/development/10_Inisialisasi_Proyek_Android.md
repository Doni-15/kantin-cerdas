# Kantin Cerdas · Inisialisasi proyek Android

Edisi 19 November 2026 untuk branch `rebuild/clean-start`. Gunakan panduan ini saat menyiapkan checkout baru atau melanjutkan repo yang sudah ada. Pendampingnya adalah `11_Metadata_Proyek.json`. Nilai dengan awalan `current_` mencatat keadaan repo. Nilai `candidate` adalah usulan. Nilai `null` menandai informasi yang masih harus ditetapkan pemilik proyek.

## 1. Produk yang akan dibangun

**Kantin Cerdas** adalah aplikasi Android untuk memesan makanan dari kantin di area layanan sekitar USU. Customer mencari kantin dan menu, membuat pesanan, memantau persiapan, lalu mengambil makanan dan membayar tunai. Tujuannya mempersingkat proses antre untuk memesan. Penyebutan USU menjelaskan area layanan. Identitas resmi penerbit masih harus ditetapkan.

| Peran | Pekerjaan dalam MVP |
|---|---|
| Customer | Daftar dalam dua langkah, lengkapi foto, cari menu, kelola keranjang satu kantin, checkout, pantau status serta barcode saat siap, lihat riwayat, dan ajukan diri menjadi Owner melalui profil. |
| Owner | Setelah pengajuan disetujui, buat satu kantin, kelola profil, kategori dan menu, terbitkan kantin, buka/tutup secara manual, proses pesanan serta konfirmasi pembayaran saat serah terima. |
| Admin | Tinjau pengajuan Owner, beri alasan penolakan, kelola status akun, dan periksa indikator pesanan aktif. Batas akses dashboard mengacu pada dokumen 05. |

**Alur utama** dimulai dari Menunggu Konfirmasi, lalu Diproses dan Siap Diambil. Hasil akhir yang sah adalah Selesai, Dibatalkan, Ditolak, Gagal Dipenuhi, Tidak Diambil, dan Gagal Diambil. Gagal Diambil berlaku jika kantin gagal menyerahkan makanan setelah siap. Owner mencatat alasan, pembayaran tetap Belum Lunas, dan pesanan masuk riwayat. Hanya serah terima yang diikuti pembayaran tunai dapat menjadi Selesai sekaligus Lunas.

**Fitur pendamping** adalah Food Assistant. Rekomendasi memakai data katalog nyata. Pencarian katalog dan checkout dapat berjalan ketika Gemini belum aktif atau tidak tersedia. Satu aplikasi Android melayani tiga peran. Versi pertama tidak memerlukan aplikasi Owner atau situs Admin terpisah.

## 2. Keadaan repo yang menjadi titik awal

Pemeriksaan berpatokan pada commit `30e9cb33eda57cc55e8ae89ffb8febd990ca608f`. Rekan yang bekerja pada commit lebih baru perlu membandingkan struktur sebelum menyalin paket. [Snapshot repo](https://github.com/Doni-15/kantin-cerdas/tree/30e9cb33eda57cc55e8ae89ffb8febd990ca608f)

| Ada di commit tersebut | Konsekuensi saat mulai |
|---|---|
| `app/` berisi proyek Flutter, `lib/main.dart`, tes penghitung, `android/` dan scaffold platform lain. | Gunakan proyek yang ada. Build pertama menargetkan Android. Tes penghitung hanya menjadi pemeriksaan awal alat. |
| `server/backend/` adalah paket Dart tersendiri dengan `pubspec.yaml`, lockfile dan `bin/server.dart`. | Jalankan perintah backend di sini. Jangan membuat server kedua di root. |
| `lib/src/app/` berisi bootstrap dan router. `lib/src/core/` berisi konfigurasi, error, HTTP dan middleware. `lib/src/infrastructure/supabase/` berisi factory klien server dan klien pengguna. Ada rangkaian tes backend. | Tambahkan Auth sebagai fitur di atas fondasi ini. Factory klien dan konfigurasi Auth yang ada belum membuktikan pendaftaran atau login bekerja. |
| Router mendefinisikan health check di bawah API prefix. Contoh konfigurasi memakai `/v1`, port `8080`, dan tiga environment. | Endpoint awal di laptop dengan konfigurasi contoh ialah `http://127.0.0.1:8080/v1/health`. Respons ini memeriksa proses HTTP dan konfigurasi dasar. Pengujian Auth dan database dilakukan tersendiri. |
| Pada tree Git yang diperiksa, direktori root yang tercatat adalah `app/` dan `server/`. | `database/`, `docs/` dan folder fitur baru di paket merupakan struktur tujuan. Direktori kosong di laptop tidak muncul dalam tree Git. |

## 3. Metadata dan informasi aplikasi

| Isian | Acuan awal | Lokasi atau alasan |
|---|---|---|
| Nama tampilan | **Kantin Cerdas** | Ubah label launcher saat ini dari `kantin_cerdas` pada `app/android/app/src/main/AndroidManifest.xml`. Untuk lokalisasi, gunakan resource Android `@string/app_name` dan isi nilainya di `res/values/strings.xml`. Selaraskan judul Flutter saat layar aplikasi dibangun. |
| Slug repo / package Dart | `kantin-cerdas` / `kantin_cerdas` | Nama package dipertahankan agar impor Dart tetap valid. |
| Package backend | `kantin_cerdas_backend` | Sudah digunakan di `server/backend/pubspec.yaml`. |
| Deskripsi aplikasi | Pesan makanan kantin, pantau pesanan, lalu ambil dan bayar tunai. | Salinan deskripsi panjang tersedia di JSON. Ganti deskripsi template Flutter dengan deskripsi produk. |
| Bahasa, uang, waktu | Bahasa Indonesia, `id-ID` untuk tag bahasa, `id_ID` untuk konfigurasi backend, IDR dalam rupiah bulat, `Asia/Jakarta` untuk tanggal bisnis. | Contoh tampilan harga Rp15.000. Pergantian tanggal kuota individu mengikuti pukul 00.00 WIB. |
| Versi aplikasi | `1.0.0+1` sudah tercatat. Versi pengguna `1.0.0`, nomor build Android `1`. | Pertahankan sebagai titik awal. Metadata versi template tidak membuktikan rilis publik; untuk distribusi berikutnya naikkan nomor build. |
| Versi layanan | Backend `1.0.0`, API `/v1`. | Versi paket backend, API, dokumen dan build Android dapat berubah sendiri. |
| Toolchain | Constraint Dart di dua paket `^3.12.2`. Android menyasar Java/Kotlin 17. Flutter scaffold mencatat kanal stable dan revisi `6b182d2c…`. | Catatan pengembangan menyebut Flutter 3.44.9. Konfirmasi dengan `flutter --version` dan simpan hasilnya bersama commit uji. Android memakai nilai compile/min/target SDK dari Flutter Gradle. |
| Application ID / namespace saat ini | `com.example.kantin_cerdas` | Nilai template pada `app/android/app/build.gradle.kts`. Package dan lokasi `MainActivity.kt` masih mengikutinya. |
| Kandidat ID Android rilis | `id.kantincerdas.mobile` | Usulan penamaan. Konfirmasi identitas penerbit dan ketersediaan ID sebelum mendaftarkan aplikasi ke Firebase, OAuth atau Play. ID final tetap kosong di JSON. |
| Pemilik operasional | Nama penerbit, kontak dukungan, domain API publik, URL kebijakan privasi, URL permintaan penghapusan akun, lisensi dan kanal distribusi masih terbuka. | Masukkan data asli sebelum publikasi. Nama akun GitHub tidak otomatis menjadi nama penerbit. |

Bidang inti berikut dapat diterapkan pada **pubspec yang sudah ada**. Edit bidangnya saja agar dependensi serta konfigurasi Flutter tetap utuh.

```yaml
name: kantin_cerdas
description: "Pesan makanan kantin, pantau pesanan, lalu ambil dan bayar tunai."
publish_to: 'none'
version: 1.0.0+1
```

Saat ID rilis diputuskan, selaraskan `applicationId`, `namespace`, deklarasi package Kotlin, dan lokasi `MainActivity.kt`. Periksa manifest hasil build, daftar ulang konfigurasi aplikasi yang terikat package, serta cocokkan sidik jari sertifikat untuk Google Sign-In pada build yang diuji. Konfigurasi Gradle yang diperiksa masih memakai signing debug pada tipe release. Sebelum distribusi, siapkan signing rilis dan simpan kunci di luar repo. Pada Play App Signing, bedakan sertifikat penandatangan aplikasi yang terpasang dari sertifikat upload. [Identitas aplikasi Android](https://developer.android.com/build/configure-app-module) · [Rilis Flutter Android](https://docs.flutter.dev/deployment/android) · [Firebase Android](https://firebase.google.com/docs/android/setup)

## 4. Struktur direktori dan kepemilikan fitur

| Path dari root | Isi dan kapan disiapkan |
|---|---|
| `app/lib/main.dart` dan `app/lib/app/` | Titik masuk yang sudah ada serta lokasi tujuan untuk bootstrap, navigasi dan pengalihan menurut sesi, role, status dan kelengkapan profil. |
| `app/lib/theme/` | Tema, tipografi dan komponen visual bersama. Bila checkout lokal sudah memiliki tema dari pekerjaan tim, tinjau dahulu sebelum menambahkan file. |
| `app/lib/core/config/` dan `core/network/` | Konfigurasi publik Android dan akses HTTP bersama. Konfigurasi ini dibaca dari dalam `app/lib/`. |
| `app/lib/features/auth/` | Irisan pertama. Tempatkan layar, pengelolaan state dan akses data Auth di fitur ini. Pecah ke subfolder ketika ada implementasi yang memakai bagiannya. |
| `app/test/features/auth/` dan `app/integration_test/` | Tes logika/UI dan alur pada Android. Tes dua metode login tetap memerlukan proyek pengujian Supabase. |
| `server/backend/bin/`, `lib/src/app/`, `lib/src/core/` dan `lib/src/infrastructure/` | Pertahankan entrypoint server, router, layanan bersama dan klien eksternal yang sudah tersedia di paket backend. |
| `server/backend/lib/src/features/auth/` dan `server/backend/test/features/auth/` | Endpoint atau layanan aplikasi untuk profil dan otorisasi, serta pengujian yang mendampingi. Verifikasi JWT, status akun dan hak tindakan di sisi server. |
| `database/migrations/` dan `database/seeds/` | Satu urutan migrasi skema aplikasi dan data uji sintetis terpisah. Nama migrasi yang disarankan berbentuk waktu UTC dan tujuan, misalnya `20261119000100_create_profiles.sql`. Pilih runner yang membaca path ini atau sesuaikan ke jalur migrasi runner yang dipilih sebelum membuat migrasi pertama. |
| `docs/business/`, `docs/architecture/`, `docs/development/`, `docs/api/` | Spesifikasi 01–06, arsitektur 07, pengujian/keputusan/panduan awal, dan kontrak HTTP yang telah disepakati. Metadata proyek diletakkan di `docs/development/`. |
| Modul berikutnya | Tambahkan katalog, keranjang, pesanan, Owner, Admin dan Food Assistant saat fitur tersebut mulai dikerjakan. Fitur pesanan menyimpan satu model status bersama bagi semua peran. Backend dapat menggabungkan operasi keranjang dan checkout dalam batas transaksi yang sama. |
| Notifikasi dan CI | Tempatkan adapter FCM di `server/backend/lib/src/infrastructure/notifications/` saat mulai digunakan. Worker memakai backend yang sama. Folder `.github/workflows/` disiapkan saat ada pemeriksaan yang dapat dijalankan di CI. |

Arsip memuat direktori tahap awal dan sembilan dokumen acuan beserta panduan ini dan metadata JSON. Folder tahap berikutnya terdaftar di `scaffold.directories_for_later_features` dalam JSON. File aplikasi dan backend yang sudah ada tetap berasal dari Git. Folder kosong berfungsi sebagai petunjuk tata letak dan baru tercatat di Git sesudah berisi file.

## 5. Lingkungan dan konfigurasi

| Lingkungan | Data dan layanan | Tujuan |
|---|---|---|
| development | Konfigurasi lokal dan data uji. Backend dapat diikat ke loopback untuk uji dari laptop. | Menjalankan aplikasi dan tes rutin. |
| staging | Proyek Supabase pengujian, SMTP ke alamat penguji, konfigurasi Google Android, lalu Firebase/FCM saat notifikasi mulai diuji. | Membuktikan identitas, sesi, transaksi, pemulihan dan akses perangkat dengan konfigurasi yang menyerupai target. |
| production | Identitas penerbit, domain HTTPS dan kredensial khusus produksi yang dikelola operator. | Distribusi setelah uji terkait lulus. |

Gunakan `server/backend/.env.example` dari commit yang sedang dikerjakan sebagai daftar variabel aktual. Loader backend membaca `.env` relatif terhadap direktori kerja, lalu nilai environment proses mengambil prioritas. Isi nilai Supabase dan Auth sebagai satu set yang mengarah ke proyek uji yang sama. Konfigurasi SMTP dan redirect aktual berada pada layanan terkait. Hindari memasukkan kredensial server, token sesi, password SMTP, kredensial FCM pengirim atau kunci Gemini ke APK, dokumen, ataupun commit.

Aplikasi kelak membutuhkan alamat Shelf, URL Supabase dan publishable key yang memang ditujukan bagi klien. Simpan hanya konfigurasi publik tersebut pada mekanisme build Flutter yang dipilih. Nama variabel dan pembacanya perlu ditambahkan bersama integrasi pertama. `SUPABASE_SECRET_KEY` hanya dipakai server untuk operasi yang memang memerlukan hak tersebut. Contoh backend saat ini memuat `AUTH_REQUIRE_EMAIL_VERIFIED=false`. Saat membangun pemesanan, uji bahwa email/password belum terverifikasi tidak dapat membuat pesanan sesuai AUTH-001. Jangan menyamakan nilai contoh development dengan kebijakan checkout.

Untuk emulator Android standar, layanan pada loopback laptop dapat dijangkau melalui `10.0.2.2`. Untuk HP fisik yang terhubung USB, opsi development adalah `adb reverse tcp:8080 tcp:8080`, lalu gunakan `127.0.0.1:8080` dari aplikasi selama pemetaan aktif. Di staging/production gunakan HTTPS. Periksa izin `android.permission.INTERNET` pada **manifest utama** saat integrasi jaringan dimulai. Jika menggunakan HTTP lokal, batasi pengecualian cleartext pada build debug sesuai kebutuhan. [Jaringan emulator](https://developer.android.com/studio/run/emulator-networking) · [Networking Flutter](https://docs.flutter.dev/data-and-backend/networking)

## 6. Memulai dari checkout yang ada

Contoh berikut menggunakan Bash. Jalankan dari root checkout repo. Baca hasil status sebelum mengganti branch. Untuk paket ZIP, ekstrak terlebih dahulu ke direktori terpisah, periksa isinya, lalu salin direktori atau dokumen yang diperlukan ke checkout. Contoh perbandingan dari root repo adalah `git diff --no-index -- docs /lokasi-ekstraksi/docs` bila kedua folder sudah ada. Kode keluar 1 dari perintah perbandingan berarti ada selisih.

```bash
git status --short --branch
git branch --show-current
git rev-parse --short HEAD
flutter --version
dart --version
flutter doctor -v
flutter devices
```

**Flutter.** Dari root repo, jalankan pemeriksaan fondasi dan bangun APK debug. Untuk uji interaktif, jalankan `flutter run -d ID_PERANGKAT` dari `app/` dengan ID yang muncul pada `flutter devices`.

```bash
(
  cd app || exit 1
  flutter pub get && flutter analyze && flutter test && flutter build apk --debug
)
```

**Backend.** Siapkan konfigurasi dari contoh bila belum ada. Isi nilai sebenarnya untuk lingkungan pengujian sebelum menjalankan server. Simpan perubahan lokal di luar Git. Tes server pada snapshot menggunakan port 8080 dan menjalankan proses server sendiri. Kosongkan port saat menjalankan suite, lalu nyalakan server manual sesudah tes.

```bash
(
  cd server/backend || exit 1
  test -e .env || cp .env.example .env
  dart pub get
)
```

```bash
(
  cd server/backend || exit 1
  dart analyze && dart test
)
```

Di terminal pertama jalankan server. Di terminal kedua, periksa health check dengan host, port, dan prefix dari konfigurasi aktif. Contoh berikut memakai Linux dan nilai development pada template.

```bash
(cd server/backend && SERVER_HOST=127.0.0.1 dart run bin/server.dart)
```

```bash
curl --fail --show-error http://127.0.0.1:8080/v1/health
```

Respons sukses berisi data `status=ok`, nama aplikasi, versi layanan dan environment. Jika konfigurasinya ditolak saat start, periksa pesan konfigurasi dan variabel terkait tanpa membagikan nilainya. Jika health berhasil tetapi HP tak terhubung, periksa alamat dari sisi perangkat, izin jaringan build tersebut, dan protokol HTTP/HTTPS.

## 7. Kapan inisialisasi dianggap selesai

| Tahap | Bukti yang dicatat | Tindak lanjut |
|---|---|---|
| Fondasi developer | SHA branch, versi SDK, hasil analisis dan tes dua paket, APK debug terbuka pada Android yang dipilih, health mengembalikan respons sukses. | Mulai integrasi Auth UI + backend. Tes yang sudah ada dicatat dengan nama dan hasil aktual. |
| Fitur Auth pertama | Staging mengirim email ke akun penguji di luar tim, redirect kembali ke app, foto wajib dapat dilanjutkan, dan kasus A1–A4 menunjukkan satu ID dan satu profil untuk penautan yang sah dengan sesi tervalidasi. | Jika kebijakan AUTH-005A gagal, tinjau mekanisme Auth sebelum menggantungkan fitur berikut pada hasil login. Google tetap nonaktif untuk produksi sampai A1–A4 lulus. |
| Alur pemesanan | Jalankan pengujian dokumen 08 termasuk dua checkout bersamaan, pemulihan respons hilang, O4 Gagal Diambil, pengambilan tunai, dan E1 dua perangkat. | Uji pencabutan sesi realtime, penerima push, barcode fisik, dan kegagalan worker sebelum pilot kantin. |
| Aktivasi Gemini atau distribusi publik | Verifikasi syarat audiens/data dan kuota untuk Gemini. Jika akan terbit di Play, selesaikan identitas rilis, signing, kontak, kebijakan data dan alur permintaan penghapusan akun. | Tanggal pilot atau rilis ditetapkan berdasarkan bukti build dan layanan yang benar-benar dipakai. |

**Status paket ini.** Struktur dan metadata dibandingkan dengan commit rujukan. Belum ada hasil build Android, eksekusi tes aplikasi, atau login staging dari penyusunan paket ini. Catat hasil pengujian nyata di dokumen 08. Fondasi teknis lain yang belum memiliki bukti tetap tercatat di dokumen 09.
