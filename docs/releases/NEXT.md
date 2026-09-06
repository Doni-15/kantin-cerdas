# Rencana v0.2.0-alpha.1

`v0.2.0-alpha.1` direncanakan sebagai tahap implementasi UI pertama setelah
fondasi `v0.1`. Target berikut belum tersedia pada rilis
`v0.1.0-alpha.2`; progres pengembangannya dicatat di bawah:

- app shell untuk area mahasiswa dan pengelola;
- design tokens “Kantin Kampus Praktis” untuk warna, tipografi, spacing, radius, dan
  theme;
- navigasi dasar antarhalaman utama;
- fake data lokal untuk skenario demo tanpa backend;
- reusable components yang benar-benar dipakai oleh lebih dari satu layar;
- fondasi menu row, floating assistant, coachmark, dan bottom sheet yang
  mengikuti design system v2.

## Progres fondasi — 6 September 2026

Fondasi token/theme, scroll konten dengan AppBar tetap (landscape 48 dp),
dan smoke test sudah di-merge melalui PR #8. CI pada commit merge `9985675`
lulus; analyze, test, build, dan peluncuran emulator juga terbukti pada log lokal.

## Selesai dikerjakan — bagian A

UI-201–UI-207 sudah diimplementasikan dan tervalidasi otomatis pada
[PR #9](https://github.com/Doni-15/kantin-cerdas/pull/9); PR ini **belum di-merge** ke `main`.

- Token warna/status, tipografi, spacing, radius, elevation, dan motion.
- Tombol primary/secondary/tertiary/destructive beserta state interaksinya.
- Input/pencarian/filter, dialog, bottom sheet, dan snackbar.
- Loading/skeleton, empty, error/retry, offline, disabled, dan success.
- Pengujian aksesibilitas/interaksi dan entry point pratinjau komponen.

**Validasi commit `fff535b`:** [CI](https://github.com/Doni-15/kantin-cerdas/actions/runs/34021544192)
lulus format, analyzer, 17 tes, dan build APK debug. Enam screenshot pratinjau
terang/gelap pada 360/390/412 dp sudah diperiksa.

## Pekerjaan berikutnya

- Merge PR #9 setelah proses review; centang checklist integrasi setelah merge.
- Bagian B: app shell dan navigasi mahasiswa/pengelola.
- Bagian C: model domain, kontrak repository, dan fake data.
- Komponen visual lanjutan, pengujian app shell, dan release gate v0.2.
- Review TalkBack serta screenshot emulator untuk bukti pengujian perangkat.

Milestone `v0.2.0-alpha.1` tetap berjalan; belum ada tag atau rilis baru.
Rincian hasil mengikuti [UI checklist](../product/UI_CHECKLIST.md) dan
[catatan implementasi](../design/DESIGN_SYSTEM_IMPLEMENTATION.md).
