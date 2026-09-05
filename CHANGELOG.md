# Changelog

Semua perubahan penting KantinCerdas dicatat dalam dokumen ini.

Format changelog mengikuti Keep a Changelog dan penomoran versi mengikuti Semantic Versioning.

## [Unreleased]

### Changed

- Menyelaraskan design system, roadmap, checklist UI, panduan kontribusi, dan copy layar fondasi dengan Full Mockup UI/UX v2 “Kantin Kampus Praktis”.
- Mengunci floating assistant sebagai bantuan kontekstual pada Beranda dan Detail Stan, dengan coachmark satu kali, modal bottom sheet, fallback manual, serta dukungan reduced motion.
- Menggantikan empat PNG mockup awal dengan satu paket PDF Full Mockup UI/UX v2 sebagai acuan visual resmi tim.

## [0.1.0-alpha.2] - 2026-09-04

### Changed

- Menjadikan `lib/main.dart` entry point dan memisahkan app serta layar status
  fondasi ke `lib/app` tanpa mengubah UI produk.
- Mengganti placeholder `.gitkeep` dengan dokumentasi tanggung jawab dan batas
  dependency pada folder yang belum memiliki implementasi.
- Menyesuaikan widget test dengan struktur import baru.
- Menata `docs/releases` sebagai indeks kebijakan, rencana versi berikutnya, dan
  riwayat release notes.
- Menyelaraskan README, panduan kontribusi, roadmap, checklist, serta metadata
  kolaborasi dengan status fondasi aktual.
- Memensiunkan workflow penerbitan sekali pakai `v0.1.0-alpha.1`; Flutter CI
  tetap menjadi quality gate aktif.

### Known limitations

- Rilis ini tidak menambahkan app shell, design tokens, navigasi, fake data,
  reusable components, maupun fitur produk.
- Perilaku pada perangkat Android fisik belum diverifikasi.
- Debug APK hanya digunakan untuk validasi dan tidak diterbitkan sebagai aset.

## [0.1.0-alpha.1] - 2026-09-04

### Added

- Fondasi proyek Flutter Android dengan application ID `io.github.doni15.kantincerdas`.
- Mini-SRS sebagai baseline kebutuhan fungsional dan nonfungsional produk.
- Struktur awal `lib/app`, `lib/core`, `lib/features`, dan `lib/shared`.
- Template `.env.example` tanpa secret untuk integrasi backend berikutnya.
- Dokumentasi roadmap, checklist UI, design system “Kantin Hangat”, dan empat mockup.
- Smoke test untuk layar status fondasi KantinCerdas.
- Workflow Flutter CI untuk format, analisis, test, dan debug build Android.
- Proses penerbitan prerelease pertama setelah CI `main` berhasil.
- Template Pull Request, Issue Forms, dan Dependabot mingguan.

### Changed

- Mengganti counter demo bawaan Flutter dengan layar status fondasi KantinCerdas.
- Menyelaraskan README utama dan README aplikasi dengan status implementasi nyata.
- Memperluas format check CI ke seluruh proyek Flutter.

### Known limitations

- Alur katalog, pencarian, keranjang, pesanan, pengelola stan, dan notifikasi belum diimplementasikan.
- Asisten Pilih Menu dan integrasi backend belum tersedia.
- Rilis ini tidak menyertakan APK siap distribusi dan belum ditujukan untuk penggunaan produksi.

[Unreleased]: https://github.com/Doni-15/kantin-cerdas/compare/v0.1.0-alpha.2...HEAD
[0.1.0-alpha.2]: https://github.com/Doni-15/kantin-cerdas/releases/tag/v0.1.0-alpha.2
[0.1.0-alpha.1]: https://github.com/Doni-15/kantin-cerdas/releases/tag/v0.1.0-alpha.1
