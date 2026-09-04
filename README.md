# KantinCerdas

[![Flutter CI](https://github.com/Doni-15/kantin-cerdas/actions/workflows/flutter-ci.yml/badge.svg?branch=main)](https://github.com/Doni-15/kantin-cerdas/actions/workflows/flutter-ci.yml)

KantinCerdas adalah aplikasi pre-order **Pesan & Ambil** untuk kantin kampus. Mahasiswa dapat memesan sebelum tiba, memantau status pesanan, lalu mengambil dan membayar di konter.

## Status proyek

**Tahap aktif:** fondasi aplikasi dan GitHub.

### Yang sudah tersedia

- Proyek Flutter untuk Android dengan identitas aplikasi `io.github.doni15.kantincerdas`.
- Struktur awal aplikasi dan pengujian widget.
- Design system “Kantin Hangat” beserta empat mockup acuan.
- Roadmap dan checklist implementasi UI dari fondasi hingga demo.
- Pemeriksaan otomatis untuk format, analisis, test, dan build APK debug.
- Template Issue, Pull Request, serta pembaruan dependency mingguan.

### Yang belum tersedia

- Implementasi UI dan alur dummy secara lengkap.
- Integrasi backend dan data nyata.
- Rilis aplikasi yang siap dipasang pengguna.

## [Releases](https://github.com/Doni-15/kantin-cerdas/releases)

Belum ada rilis yang dipublikasikan.

- Versi aplikasi saat ini: `0.1.0-alpha.1+1`
- Target tag pertama: `v0.1.0-alpha.1`
- Rilis terbaru: **Belum tersedia**

Angka `+1` merupakan build number Flutter. Tag `v0.1.0-alpha.1` baru dibuat setelah fondasi, Mini-SRS, dan seluruh pemeriksaan CI dinyatakan lulus.

## Ruang lingkup utama

- Melihat stan, menu, harga, stok, dan estimasi waktu.
- Pre-order untuk pengambilan pada hari yang sama.
- Rekomendasi menu berdasarkan anggaran dan preferensi.
- Memantau status pesanan sampai siap diambil.
- Pembayaran langsung di konter.

Delivery, pembayaran digital, dan pemesanan untuk hari lain belum termasuk dalam scope awal.

## Struktur repository

```text
kantin-cerdas/
├── .github/          # Workflow dan template GitHub
├── apps/
│   └── mobile/       # Aplikasi Flutter Android
├── docs/
│   ├── design/       # Design system dan mockup
│   └── product/      # Roadmap dan checklist UI
├── CHANGELOG.md
├── CONTRIBUTING.md
└── README.md
```

## Menjalankan aplikasi

```bash
cd apps/mobile
flutter pub get
flutter run
```

## Continuous Integration (CI)

Setiap `push` dan Pull Request menuju `main` diperiksa otomatis oleh GitHub Actions pada lingkungan baru. Pemeriksaannya meliputi:

- konsistensi format kode Dart;
- hasil `flutter analyze`;
- seluruh `flutter test`;
- keberhasilan build APK debug.

Badge **Flutter CI** di bagian atas README berwarna hijau ketika seluruh pemeriksaan berhasil. CI hanya memeriksa kualitas proyek; CI saat ini tidak menerbitkan release dan tidak melakukan deployment.

Pemeriksaan yang sama dapat dijalankan secara lokal:

```bash
cd apps/mobile
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

## Dokumentasi

- [Design System](docs/design/DESIGN_SYSTEM.md)
- [Mockup aplikasi](docs/design/mockups)
- [Roadmap](docs/product/ROADMAP.md)
- [Checklist UI](docs/product/UI_CHECKLIST.md)
