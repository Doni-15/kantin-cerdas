# Rilis KantinCerdas

Direktori ini menjadi indeks kebijakan, rencana, dan riwayat rilis
KantinCerdas. `CHANGELOG.md` merangkum perubahan lintas versi, sedangkan setiap
file versi di sini menjadi sumber release notes GitHub untuk tag yang sama.

## Kebijakan rilis

- Versi source mengikuti `MAJOR.MINOR.PATCH-PRERELEASE+BUILD` di
  `apps/mobile/pubspec.yaml`; tag Git tidak menyertakan build metadata `+BUILD`.
- Tag hanya dibuat dari commit `main` yang sudah lulus Flutter CI.
- Tag rilis dibuat sebagai annotated tag dan tidak dipindahkan atau diganti.
- Rilis `alpha`, `beta`, dan `rc` diterbitkan sebagai GitHub prerelease. Status
  stable/Latest hanya digunakan setelah ada keputusan rilis stabil.
- Release notes diambil dari `docs/releases/<tag>.md`.
- Debug APK hanya untuk validasi dan tidak diunggah sebagai aset rilis.
- Penerbitan dilakukan setelah verifikasi CI `main`; tidak ada workflow
  hard-coded per versi yang tetap aktif.

## Riwayat

| Versi | Tanggal | Fokus | Catatan |
| --- | --- | --- | --- |
| [`v0.1.0-alpha.2`](v0.1.0-alpha.2.md) | 4 September 2026 | Perapian fondasi kolaborasi, struktur, dan dokumentasi | [GitHub Release](https://github.com/Doni-15/kantin-cerdas/releases/tag/v0.1.0-alpha.2) |
| [`v0.1.0-alpha.1`](v0.1.0-alpha.1.md) | 4 September 2026 | Fondasi awal proyek dan acuan produk | [GitHub Release](https://github.com/Doni-15/kantin-cerdas/releases/tag/v0.1.0-alpha.1) |

## Rencana berikutnya

Ruang lingkup yang belum dirilis dicatat di [`NEXT.md`](NEXT.md). Entri di sana
adalah rencana, bukan bukti bahwa fitur telah tersedia.
