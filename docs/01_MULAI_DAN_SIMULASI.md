# Mulai dan simulasi

Untuk pembaca yang ingin menjalankan/demo aplikasi. Untuk hasil validasi terbaru buka [Status dan pengujian](04_STATUS_DAN_PENGUJIAN.md).

## Persiapan dan perintah

Gunakan Flutter yang mendukung constraint Dart ^3.12.2, dependency sesuai pubspec.lock, serta device/emulator dan Android SDK untuk Android. Jangan upgrade semua package hanya karena ada pemberitahuan versi baru.

Dari root kantin_cerdas:

```bash
cd app
flutter pub get --enforce-lockfile
flutter run -t test/support/main_simulation.dart
```

Jika ada beberapa device, pilih device yang diinginkan.

Untuk menjalankan entry produksi (`lib/main.dart`) yang terhubung ke server REST API backend, berikan konfigurasi `API_BASE_URL`:

```bash
cd app
flutter run -t lib/main.dart --dart-define=API_BASE_URL=https://api.kantincerdas.ac.id
```

Jika `lib/main.dart` dijalankan tanpa `--dart-define=API_BASE_URL=...`, `AppEnvironment.isApiConfigured` bernilai `false` dan aplikasi akan menampilkan status bahwa layanan belum terhubung (tanpa mengarang data fiktif atau membocorkan fixture simulasi).

## Akun awal


| Username | Role | Keterangan |
| --- | --- | --- |
| pelanggan | customer | Alya, pesanan aktif dan riwayat; dapat mengajukan stan |
| pelanggan2 | customer | Bima, pengajuan menunggu admin dan pesanan pribadi |
| pemilik | owner | Dapur Nusantara, stan buka |
| pemilik2 | owner | Warung Mie Kampus, stan buka |
| pemilik3 | owner | Kedai Segar, stan tutup |
| admin | admin | Meninjau pengajuan dan mengatur akses |

Password semua akun awal: `Simulasi123!`. Email memakai domain `example.test`.
Seed: 3 stan, 15 menu (termasuk habis), 8 pesanan pada beberapa status.
Registrasi membuat akun customer fiktif; login dilakukan melalui form biasa.
Permintaan reset hanya mensimulasikan penerimaan, tidak mengirim email/link.
Asisten memilih dari katalog/preferensi uji, dilabeli simulasi dan bukan AI nyata.
Preferensi bahan tidak menjamin makanan aman untuk alergi.


## Cara kerja dan batas simulasi

Label MODE SIMULASI dan panel Kontrol membedakan mode uji. UI/controller/router sama; repository dan jurnal di-override dengan database lokal. Snapshot menyimpan akun, stan, menu, pengajuan, preferensi, pesanan, receipt dan jurnal.

Data bertahan setelah logout/restart pada instalasi yang sama. Namespace kantin_cerdas.simulation.v1. terpisah dari token/jurnal normal. Gunakan hanya data fiktif: password simulasi disimpan sebagai fixture lokal. Reset melalui panel Kontrol meminta konfirmasi dan mengembalikan seed; ini menghapus perubahan data simulasi.

Kedua entry memakai applicationId com.kantincerdas.app. Memasang APK normal/simulasi mengganti executable terpasang; bukan dua aplikasi berdampingan. Simulasi satu perangkat tidak membuktikan transaksi atau keamanan server lintas perangkat.

## Kontrol skenario


Normal: delay baca/tulis 450 ms. Lambat: 3 detik untuk operasi data bersesi.
Daftar kosong: katalog/list/detail pesanan kosong, tanpa menghapus data asli.
Gagal baca: pembacaan gagal; kembali ke Normal lalu Muat ulang.
Konflik tulis: request disegel tanpa commit; tinjau ulang form sebelum mencoba lagi.
Respons tulis hilang: commit terjadi, respons gagal; kembali Normal lalu pilih
Periksa hasil pada panel recovery. Jangan mengirim ulang untuk membuat sukses.
Latensi buatan hanya berada dalam adapter simulasi.


## Contoh alur pertama

Login pelanggan → pilih menu/checkout → logout → login pemilik stan yang sama → terima/siapkan/selesaikan pesanan → kembali pelanggan dan periksa riwayat. Checklist lengkap serta expected result ada di [04](04_STATUS_DAN_PENGUJIAN.md).
