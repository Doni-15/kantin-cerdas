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

Bagian A design system dilanjutkan pada `feat/design-system-section-a`:
komponen tombol, field/filter, dialog/sheet/snackbar, state konten, serta
pemeriksaan aksesibilitas. Status penyelesaian mengikuti
[UI checklist](../product/UI_CHECKLIST.md) dan
[catatan implementasi](../design/DESIGN_SYSTEM_IMPLEMENTATION.md).

App shell, navigasi, dan fake repository belum tersedia. Milestone tetap
berjalan dan belum menjadi rilis `v0.2.0-alpha.1`.
