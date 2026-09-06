# Implementasi bagian A — Design system

Scope: UI-201 sampai UI-207 pada milestone `v0.2.0-alpha.1`.
Implementasi ini tidak menambahkan katalog produk, navigasi peran, atau backend.

## Lokasi dan penggunaan

- `lib/shared/design_system/`: warna, tipografi, spacing, radius, ukuran,
  elevation, dan motion. Perakitan `ThemeData` tetap di `lib/app/theme/`.
- `lib/shared/widgets/kc_button.dart`: primary, secondary, tertiary, destructive.
  `loading: true` menonaktifkan callback, memberi label Memproses, dan
  menampilkan indikator statis jika reduced motion aktif. Gunakan label tindakan
  yang spesifik; jelaskan alasan disabled dalam teks di dekat tombol.
- `kc_fields.dart`: input dengan label tetap, validasi, helper text, serta
  pencarian dengan tombol hapus. Pemanggil memiliki dan membuang controller
  serta focus node; komponen tidak menyimpan data domain.
- `kc_filter_bar.dart`: filter pilihan jamak dalam satu baris yang dapat
  digulir. Pemanggil menentukan aturan pilihan melalui callback.
- `kc_overlays.dart`: konfirmasi dengan fokus awal pada Batal, modal bottom
  sheet yang dapat digulir di atas keyboard, serta snackbar. Pembatalan dialog
  menghasilkan `false`; tindakan destruktif baru dilakukan setelah hasil `true`.
- `kc_state_view.dart`: loading/skeleton, empty, error/retry, offline, disabled,
  dan success. Untuk offline, kirim data tersimpan sebagai `child`, bukan
  menggantinya dengan layar kosong. Skeleton statis dan tidak mengumumkan
  setiap garis kepada pembaca layar.

Pasangan warna status menggunakan foreground dan container bersama, termasuk
pada tema gelap. Jangan menempatkan foreground status langsung pada background
gelap. `waiting` tetap `#9A6700` untuk ikon; `waitingText` (`#906000`) dipakai
untuk teks kecil pada `waitingContainer` agar memenuhi kontras 4.5:1.

Elevation: `flat = 0` untuk konten/app bar/navigation bar, `floating = 1`
untuk snackbar, `modal = 3` untuk dialog dan bottom sheet. Tinggi kontrol
adalah minimum, bukan batas yang memotong label saat teks diperbesar.

## Pratinjau komponen

Jalankan dari `apps/mobile`:

```bash
flutter run -t lib/design_system_preview.dart
```

Halaman ini merupakan entry point pengembang terpisah. `flutter run` biasa
tetap membuka layar fondasi dengan AppBar tetap. Pratinjau menyediakan pergantian
tema, semua varian tombol, input, filter, dialog, bottom sheet, snackbar, dan
enam state konten. Data contoh hanya copy demonstrasi komponen, bukan fake
repository atau fitur pesanan.

## Bukti pemeriksaan UI-207

`test/design_system_test.dart` memeriksa:

- rasio kontras pasangan teks terang/gelap dan warna status minimal 4.5:1;
- guideline Flutter untuk target Android 48 dp, label aksesibel, dan kontras;
- pencegahan aksi pada loading/disabled, pencarian/hapus, validasi dan retry;
- urutan Tab, aktivasi Enter, indikator fokus, dan pemulihan fokus dialog;
- layout pada 360/390/412 dp dan landscape 800 × 360 dp dengan teks 200%;
- bottom sheet yang dapat digulir dengan inset keyboard dan teks besar;
- indikator loading statis serta transisi komponen saat reduced motion aktif.

Hasil eksekusi mengikuti [CI pada PR #9](https://github.com/Doni-15/kantin-cerdas/pull/9).
Tes pratinjau memuat font proyek dan menghasilkan enam screenshot (360/390/412 dp,
terang/gelap) sebagai artifact `design-system-preview` pada CI, disimpan 7 hari.
Screenshot tersebut merupakan render tes Flutter, bukan tangkapan emulator. Tes widget tidak menggantikan
review TalkBack pada perangkat atau pemeriksaan visual screenshot. Sebelum
release gate UI, jalankan pratinjau pada emulator, periksa teks besar dan tema
terang/gelap, lalu lampirkan screenshot 390 dp serta 360 atau 412 dp.

Checkbox checklist tetap mengikuti aturan diuji dan sudah di-merge ke `main`.
