# Kantin Cerdas

**Kantin Cerdas** adalah aplikasi pemesanan makanan kantin kampus yang dikembangkan menggunakan Flutter, Dart Shelf, dan Supabase. Aplikasi ini dirancang untuk mendukung pengelolaan pemesanan makanan secara digital melalui tiga peran utama: **Customer, Owner, dan Admin**.

Flutter menangani antarmuka pengguna, Dart Shelf menyediakan REST API dan logika bisnis, sedangkan Supabase digunakan untuk autentikasi, database, dan penyimpanan file.

## Tech Stack

### Core Technologies

| Komponen | Teknologi | Versi |
|---|---|---|
| Frontend Framework | Flutter | 3.44.9 |
| Programming Language | Dart | 3.12.2 |
| Backend Framework | Shelf | ^1.4.2 |
| API Routing | Shelf Router | ^1.1.2 |
| Backend SDK | Supabase Dart | ^2.16.5 |
| Database | PostgreSQL (Supabase) | Managed |
| Authentication | Supabase Auth | Managed |
| File Storage | Supabase Storage | Managed |

### Infrastructure & Integrations

| Komponen | Teknologi | Versi / Standar |
|---|---|---|
| Backend Hosting | Railway | Free Tier |
| Containerization | Docker | Multi-stage Build |
| Push Notifications | Firebase Cloud Messaging | HTTP v1 |
| AI Integration | Google Gemini API | Configurable Model |
| OAuth Authentication | Google OAuth 2.0 | PKCE |
| CI/CD | GitHub Actions | YAML Workflows |
| Android Build System | Gradle | 9.1.0 |
| Java Development Kit | OpenJDK | 17 |
| Application Distribution | GitHub Releases | Android APK |

> **Catatan:** Versi dependensi menggunakan constraint yang didefinisikan proyek. Versi aktual paket mengikuti lockfile. Integrasi Gemini AI dan Firebase FCM masih dalam tahap finalisasi dan belum diaktifkan sepenuhnya. Infrastruktur Railway juga masih dalam persiapan deployment.

## Struktur Proyek

```text
kantin-cerdas/
├── app/                 # Flutter Application
├── server/
│   ├── backend/         # Dart Shelf REST API
│   └── supabase/        # Database Migrations & Tests
├── docs/                # Project Documentation
├── tests/               # Integration & E2E Tests
├── .github/
│   └── workflows/       # CI/CD Automation
└── README.md
```

- [app/](app/) — Aplikasi Flutter untuk Customer, Owner, dan Admin. Android menggunakan Application ID `id.kantincerdas.app`.
- [server/backend/](server/backend/) — Backend REST API berbasis Dart Shelf dengan prefix default `/v1`.
- [server/supabase/](server/supabase/) — Migrasi database, kebijakan keamanan, dan pengujian SQL.
- [docs/](docs/) — Dokumentasi arsitektur, autentikasi, spesifikasi, serta pengembangan aplikasi.
- [tests/](tests/) — Pengujian integrasi dan end-to-end.
- [.github/workflows/](.github/workflows/) — Otomatisasi analisis kode, pengujian, dan persiapan build Android.

## Menjalankan Proyek

### Persyaratan

- Flutter SDK 3.44.9
- Dart SDK 3.12.2
- Java Development Kit 17
- Android SDK
- Git
- Proyek Supabase beserta konfigurasi API

### Backend — Dart Shelf

Masuk ke direktori backend:

```bash
cd server/backend
```

Buat file `.env` lokal berdasarkan [contoh konfigurasi](server/backend/.env.example), kemudian isi konfigurasi Supabase yang diperlukan.

Jangan menyimpan API Key atau secret asli di repository.

Pulihkan dependensi:

```bash
dart pub get --enforce-lockfile
```

Jalankan backend:

```bash
dart run bin/server.dart
```

Secara default, backend menggunakan:

```text
http://localhost:8080/v1
```

Healthcheck:

```text
http://localhost:8080/v1/health
```

### Frontend — Flutter

Masuk ke direktori aplikasi:

```bash
cd app
```

Pulihkan dependensi:

```bash
flutter pub get --enforce-lockfile
```

Jalankan aplikasi:

```bash
flutter run
```

Untuk konfigurasi API, Android, dan build, lihat [panduan aplikasi](app/README.md).

Konfigurasi autentikasi, Google OAuth, dan manajemen sesi dijelaskan pada [dokumentasi Auth](docs/AUTH.md).

## Pengujian & Validasi

### Backend

Jalankan dari direktori `server/backend/`:

```bash
dart analyze --fatal-infos --fatal-warnings
dart test
```

### Flutter

Jalankan dari direktori `app/`:

```bash
flutter analyze --no-pub --fatal-infos --fatal-warnings lib test
flutter test --no-pub
```

### Database

Pengujian database mencakup validasi migrasi SQL, struktur tabel, Row Level Security (RLS), fungsi, dan kebijakan akses.

Lihat [dokumentasi migrasi Supabase](server/supabase/README.md) untuk urutan migrasi serta prosedur verifikasi.

## Deployment & Distribution

Backend Kantin Cerdas disiapkan untuk deployment menggunakan **Railway** dengan Docker, sedangkan aplikasi Android direncanakan didistribusikan melalui **GitHub Releases**.

GitHub Actions digunakan untuk membantu otomatisasi analisis kode, pengujian, dan proses build Android.

Konfigurasi production dan integrasi cloud harus diverifikasi sebelum aplikasi digunakan secara publik.

## Dokumentasi

Dokumentasi teknis dan pengembangan tersedia melalui direktori [docs/](docs/), meliputi arsitektur sistem, autentikasi, database, pengujian, dan integrasi layanan eksternal.

---

**Kantin Cerdas** — Campus Canteen Ordering System.