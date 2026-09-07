# KantinCerdas — Flutter Android

Jalankan perintah berikut dari `apps/mobile/`.

| Entry point | Sesi | Navigasi |
| --- | --- | --- |
| `lib/main_student.dart` | Doni, mahasiswa | Beranda, Pesanan, Profil |
| `lib/main_manager.dart` | Bu Rina, pengelola Dapur Bu Rina | Dashboard, Pesanan, Menu, Profil |
| `lib/main.dart` | Mahasiswa secara default | Sama dengan entry point mahasiswa |

```bash
flutter pub get
flutter run -t lib/main_student.dart
flutter run -t lib/main_manager.dart
```

Jalankan satu perintah `flutter run` pada satu waktu.

## Pemeriksaan

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Saat ini aplikasi hanya menyediakan shell dan navigasi dasar.
Sesi contoh bukan autentikasi backend. Daftar menu, transaksi, dan
pengelolaan pesanan belum diimplementasikan.

`DemoSession` masih berupa data immutable. Session repository,
pergantian sesi dinamis, dan route registry mengikuti task berikutnya.

Font runtime disalin dari baseline. Jangan mengedit sumber dalam
`design/baseline/`.

Alur kontribusi: branch tugas → `KantinCerdasv0.1.0` → `main`.
