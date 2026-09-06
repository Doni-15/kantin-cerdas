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

Pengembangan `v0.2.0-alpha.1` sudah dimulai. Pada branch
`fix/theme-foundation-20260906-002855`, token dipusatkan di
`lib/shared/design_system/`, tema dilengkapi, layar fondasi diberi scroll,
dan ekspektasi ikon smoke test disesuaikan.

Analyze, satu widget test, build APK debug, serta pemasangan dan peluncuran
di emulator lulus menurut log lokal. Saat dicatat, perubahan belum di-merge
ke `main`; milestone belum selesai. Rincian validasi dan pekerjaan berikutnya
mengikuti [UI checklist](../product/UI_CHECKLIST.md).
