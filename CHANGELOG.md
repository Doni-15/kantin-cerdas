# Changelog

Semua perubahan penting KantinCerdas dicatat dalam dokumen ini.

Format changelog mengikuti Keep a Changelog dan penomoran versi mengikuti Semantic Versioning.

## [Unreleased]

## [0.1.0-alpha.1] - 2026-09-04

### Added

- Fondasi proyek Flutter Android dengan application ID `io.github.doni15.kantincerdas`.
- Mini-SRS sebagai baseline kebutuhan fungsional dan nonfungsional produk.
- Struktur awal `lib/app`, `lib/core`, `lib/features`, dan `lib/shared`.
- Template `.env.example` tanpa secret untuk integrasi backend berikutnya.
- Dokumentasi roadmap, checklist UI, design system “Kantin Hangat”, dan empat mockup.
- Smoke test untuk layar status fondasi KantinCerdas.
- Workflow Flutter CI untuk format, analisis, test, dan debug build Android.
- Template Pull Request, Issue Forms, dan Dependabot mingguan.

### Changed

- Mengganti counter demo bawaan Flutter dengan layar status fondasi KantinCerdas.
- Menyelaraskan README utama dan README aplikasi dengan status implementasi nyata.
- Memperluas format check CI ke seluruh proyek Flutter.

### Known limitations

- Alur katalog, pencarian, keranjang, pesanan, pengelola stan, dan notifikasi belum diimplementasikan.
- Asisten Pilih Menu dan integrasi backend belum tersedia.
- Rilis ini tidak menyertakan APK siap distribusi dan belum ditujukan untuk penggunaan produksi.

[Unreleased]: https://github.com/Doni-15/kantin-cerdas/compare/v0.1.0-alpha.1...HEAD
[0.1.0-alpha.1]: https://github.com/Doni-15/kantin-cerdas/releases/tag/v0.1.0-alpha.1
