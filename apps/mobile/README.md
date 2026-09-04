# KantinCerdas Mobile

Aplikasi Flutter Android untuk layanan pre-order **Pesan & Ambil** di kantin kampus.

## Status

- Versi source: `0.1.0-alpha.1+1`
- Tahap: fondasi aplikasi
- UI saat ini: layar status KantinCerdas; alur produk belum diimplementasikan
- Backend: To Be Continued

Versi ini bukan aplikasi siap produksi. Katalog, pemesanan, asisten AI, notifikasi, dan integrasi backend masih berada pada milestone berikutnya.

## Toolchain

- Flutter `3.44.9`
- Dart `3.12.2`
- Platform: Android
- Application ID: `io.github.doni15.kantincerdas`

## Menjalankan aplikasi

```bash
flutter pub get
flutter run
```

## Pemeriksaan kualitas

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

## Konfigurasi

Template konfigurasi tersedia di [`.env.example`](../../.env.example). Fondasi `v0.1.0-alpha.1` belum membaca environment variable apa pun dan file `.env` asli tidak boleh masuk Git.

## Dokumentasi proyek

- [README utama](../../README.md)
- [Mini-SRS](../../docs/product/MINI_SRS.md)
- [Design System](../../docs/design/DESIGN_SYSTEM.md)
- [Roadmap](../../docs/product/ROADMAP.md)
- [Checklist UI](../../docs/product/UI_CHECKLIST.md)
- [Catatan rilis `v0.1.0-alpha.1`](../../docs/releases/v0.1.0-alpha.1.md)
