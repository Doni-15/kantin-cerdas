# KantinCerdas

[![Flutter CI](https://github.com/Doni-15/kantin-cerdas/actions/workflows/flutter-ci.yml/badge.svg?branch=main)](https://github.com/Doni-15/kantin-cerdas/actions/workflows/flutter-ci.yml)

KantinCerdas adalah aplikasi Android berbasis Flutter untuk layanan pre-order **Pesan & Ambil** di kantin kampus. Mahasiswa dapat memilih menu sebelum tiba, sedangkan pengelola stan dapat memproses pesanan dan memperbarui ketersediaan menu.

Repository ini masih berada pada tahap fondasi. Dokumen produk dan acuan desain sudah tersedia, tetapi UI produk, data dummy, AI, notifikasi, dan backend belum diimplementasikan.

## Tujuan Proyek

KantinCerdas dirancang untuk:

- membantu mahasiswa memilih dan memesan makanan tanpa menunggu lama di kantin;
- menyediakan rekomendasi menu berdasarkan anggaran, preferensi, dan waktu tunggu;
- membantu pengelola stan menerima serta memperbarui status pesanan;
- menghasilkan aplikasi demo yang dapat berjalan tanpa backend terlebih dahulu;
- menjaga struktur UI agar nantinya dapat dihubungkan ke backend tanpa perombakan besar.

## Status Implementasi

| Area | Status saat ini | Keterangan |
| --- | --- | --- |
| Proyek Flutter Android | Tersedia | Scaffold bawaan Flutter dapat dianalisis, diuji, dan dibangun |
| Identitas aplikasi | Tersedia | Nama Android `KantinCerdas` dan application ID `io.github.doni15.kantincerdas` |
| Design system | Terdokumentasi | Token visual, komponen, dan arah desain “Kantin Hangat” |
| Mockup | Tersedia | Empat papan acuan untuk alur mahasiswa dan pengelola |
| Roadmap dan checklist UI | Tersedia | Tahapan pengembangan dan release gate telah dipetakan |
| GitHub workflow | Aktif | CI, Issue Forms, Pull Request template, dan Dependabot |
| UI produk | Belum dimulai | `main.dart` masih menampilkan counter demo bawaan Flutter |
| Data dummy dan state aplikasi | Belum tersedia | Dikerjakan pada milestone UI berikutnya |
| Asisten Pilih Menu berbasis AI | Belum tersedia | Baru berada dalam scope dan rancangan produk |
| Notifikasi Android | Belum tersedia | Direncanakan untuk status pesanan |
| Backend dan API | TBC | Kontrak backend belum ditetapkan |

Status di atas mengikuti isi source code saat ini. Mockup dan checklist tidak dianggap sebagai fitur yang sudah diimplementasikan.

## Ruang Lingkup Produk

### Mahasiswa

- melihat daftar stan dan katalog menu;
- mencari serta memfilter menu;
- memperoleh rekomendasi melalui Asisten Pilih Menu;
- membuat pesanan dari satu stan;
- memantau status pesanan sampai siap diambil;
- membayar langsung di konter.

### Pengelola stan

- membuka atau menutup stan;
- memperbarui ketersediaan menu dan estimasi waktu;
- menerima atau menolak pesanan;
- mengubah status pesanan hingga selesai.

### Di luar baseline

Versi awal tidak mencakup delivery, GPS atau peta, pembayaran digital, promo, rating, pemesanan lintas hari, maupun dukungan banyak kampus.

## Acuan Desain

Arah visual yang dipilih adalah **“Kantin Hangat”**: ramah, cepat, dan menonjolkan makanan. Implementasi Flutter harus mengikuti token dan pola komponen pada design system.

- [Design System](docs/design/DESIGN_SYSTEM.md)
- [Seluruh mockup](docs/design/mockups)

Mockup merupakan acuan implementasi, bukan bukti bahwa layar tersebut sudah tersedia di aplikasi.

## Teknologi

- Flutter `3.44.9`
- Dart `3.12.2`
- Android
- Material
- GitHub Actions

Backend, database, state management, dan layanan AI belum dipilih sebagai implementasi final.

## Struktur Repository

```text
kantin-cerdas/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   ├── workflows/flutter-ci.yml
│   └── PULL_REQUEST_TEMPLATE.md
├── apps/
│   └── mobile/
│       ├── android/
│       ├── lib/
│       ├── test/
│       └── pubspec.yaml
├── docs/
│   ├── design/
│   │   ├── DESIGN_SYSTEM.md
│   │   └── mockups/
│   └── product/
│       ├── ROADMAP.md
│       └── UI_CHECKLIST.md
├── CHANGELOG.md
├── CONTRIBUTING.md
└── README.md
```

## Menjalankan Aplikasi

Persyaratan:

- Flutter SDK `3.44.9`;
- Android SDK dan emulator atau perangkat Android;
- Java yang kompatibel dengan toolchain Flutter.

```bash
cd apps/mobile
flutter pub get
flutter run
```

## Pemeriksaan Kualitas

Jalankan pemeriksaan berikut dari `apps/mobile`:

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

## Continuous Integration

Workflow [Flutter CI](.github/workflows/flutter-ci.yml) menjalankan pemeriksaan yang sama pada mesin GitHub setiap kali ada `push` atau Pull Request menuju `main`.

CI digunakan untuk memastikan source dapat diformat, dianalisis, diuji, dan dibangun pada lingkungan baru. CI saat ini tidak melakukan deployment, tidak mengunggah APK sebagai artefak rilis, dan tidak membuat GitHub Release.

## Versioning dan Release

KantinCerdas menggunakan Semantic Versioning. Nilai versi pada `pubspec.yaml` adalah versi build aplikasi yang sedang dikerjakan; nilai tersebut belum otomatis menjadi rilis resmi.

Rilis resmi hanya dibuat setelah milestone dan release gate terkait selesai. Setiap rilis akan:

1. menunjuk ke commit `main` yang sudah lulus CI;
2. memiliki Git tag, misalnya `v0.1.0-alpha.1`;
3. diterbitkan melalui [GitHub Releases](https://github.com/Doni-15/kantin-cerdas/releases);
4. memiliki release notes yang menjelaskan fitur, validasi, dan keterbatasannya.

Dengan alur tersebut, rilis akan tampil otomatis pada panel **Releases** GitHub seperti rilis SwaDrive. Tag tidak dibuat untuk fitur yang masih berupa rencana.

## Dokumentasi

- [Roadmap pengembangan](docs/product/ROADMAP.md)
- [Checklist implementasi UI](docs/product/UI_CHECKLIST.md)
- [Design system](docs/design/DESIGN_SYSTEM.md)
- [Changelog](CHANGELOG.md)
- [Panduan kontribusi](CONTRIBUTING.md)

## Alur Pengembangan

Setelah commit fondasi, setiap perubahan dikerjakan melalui branch pendek dan Pull Request menuju `main`. Perubahan baru hanya digabungkan setelah scope diperiksa dan CI berhasil.

Aturan branch, commit, pengujian, dan Pull Request tersedia dalam [CONTRIBUTING.md](CONTRIBUTING.md).
