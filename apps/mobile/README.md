# KantinCerdas Mobile

Aplikasi Flutter Android untuk layanan pre-order **Pesan & Ambil** di kantin kampus.

## Status

- Rilis resmi: Unreleased
- Target berikutnya: `v0.1.0-alpha.1`
- UI saat ini: scaffold awal Flutter
- Backend: To Be Continued

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
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

## Dokumentasi proyek

- [README utama](../../README.md)
- [Design System](../../docs/design/DESIGN_SYSTEM.md)
- [Roadmap](../../docs/product/ROADMAP.md)
- [Checklist UI](../../docs/product/UI_CHECKLIST.md)
