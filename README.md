# KantinCerdas

Aplikasi Flutter + Riverpod untuk pelanggan, pemilik stan, dan admin dengan arsitektur Clean Architecture 3-lapis (`presentation/`, `domain/`, `data/`). Mode simulasi terisolasi di `app/test/support/` untuk pengujian tiga role secara lokal; mode normal siap dihubungkan ke REST API backend melalui `--dart-define=API_BASE_URL=...`.

**Mulai membaca dari [Pusat Dokumentasi](docs/README.md).** Di sana terdapat fungsi setiap dokumen, urutan baca, dan status pengujian terkini.

Untuk menjalankan mode simulasi dari folder proyek:

```bash
cd app
flutter pub get --enforce-lockfile
flutter run -t test/support/main_simulation.dart
```

Untuk menjalankan aplikasi dengan backend REST API:

```bash
cd app
flutter run -t lib/main.dart --dart-define=API_BASE_URL=https://api.kantincerdas.ac.id
```

| Kebutuhan | Buka |
| --- | --- |
| Menjalankan aplikasi dan memilih akun uji | [Mulai dan simulasi](docs/01_MULAI_DAN_SIMULASI.md) |
| Memahami atau melanjutkan kode | [Arsitektur dan aturan](docs/02_ARSITEKTUR_DAN_ATURAN.md) |
| Mengetahui hasil verifikasi & pengujian | [Status dan pengujian](docs/04_STATUS_DAN_PENGUJIAN.md) |
| Membangun dan mengintegrasikan backend | [Spesifikasi backend](docs/backend/SPESIFIKASI_BACKEND.md) |

Panduan aktif berada di `docs/`. Arsip adalah catatan historis, bukan acuan implementasi terbaru.
