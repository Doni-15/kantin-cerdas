# KantinCerdas

[![Flutter CI](https://github.com/Doni-15/kantin-cerdas/actions/workflows/flutter-ci.yml/badge.svg?branch=main)](https://github.com/Doni-15/kantin-cerdas/actions/workflows/flutter-ci.yml)

KantinCerdas adalah aplikasi pre-order **Pesan & Ambil** untuk kantin kampus. Mahasiswa dapat memesan sebelum tiba, memantau status pesanan, lalu mengambil dan membayar di konter.

## Status proyek

| Bagian | Status |
|---|---|
| Rilis resmi | Unreleased |
| Target berikutnya | `v0.1.0-alpha.1` |
| Tahap aktif | Fondasi aplikasi dan GitHub |
| Implementasi UI | Belum dimulai |
| Backend | To Be Continued |

Nilai `0.1.0-alpha.1+1` di `pubspec.yaml` merupakan target build. Versi tersebut baru menjadi rilis resmi setelah release gate dan CI lulus, kemudian tag Git dibuat.

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

## Pemeriksaan kualitas

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
