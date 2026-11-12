# Panduan UI/UX dan Sistem Desain (`KcTheme`)

Dokumen ini menggabungkan aturan perilaku state antarmuka pengguna dengan kamus token visual Material 3 yang diimplementasikan di `app/lib/theme/`.

## 1. Perilaku State dan Interaksi Layar

| Kondisi | Perilaku Standar |
|---|---|
| Pembacaan awal | Menampilkan `KcSkeleton` / `KcLoadingSkeleton` sesuai bentuk daftar, detail, form, atau kartu ringkasan |
| Sukses kosong | Menampilkan `KcStatusPanel` dengan penjelasan singkat dan tombol aksi yang relevan |
| Error / timeout baca | Menampilkan pesan Bahasa Indonesia yang jelas disertai tombol **Coba lagi** (tanpa *stack trace* atau token) |
| Belum terhubung (`API_BASE_URL` kosong) | Menampilkan status layanan belum tersedia pada entrypoint normal tanpa data atau klaim sukses palsu |
| Pengiriman form (*submit*) | Menonaktifkan tombol sementara dan menampilkan indikator proses untuk mencegah klik atau dialog ganda |
| Hasil mutasi belum diketahui (*unknown*) | Menampilkan panel pemulihan (*recovery*) untuk memeriksa status operasi tanpa mengirim ulang mutasi |
| Perubahan form belum disimpan | Meminta konfirmasi sebelum pengguna keluar dari halaman atau menimpa isian |
| Sesi berubah / logout | Menutup dialog lama dan mengabaikan respons asinkron dari sesi sebelumnya |
| Paginasi | Menggunakan navigasi tumpukan kursor halaman (**Sebelumnya / Selanjutnya**); muat ulang kembali ke halaman awal |
| Unggah dan tampil gambar | `KcImagePickerField`, `KcImageSourceSheet`, dan `KcEntityImage` memvalidasi *magic bytes* JPG/PNG/WEBP `<= 2 MB` (dimensi `<= 8192 px`) dengan fallback aman |

- **Animasi & Aksesibilitas:** `KcSkeleton` mematuhi `disableAnimations`/`accessibleNavigation` dan `TickerMode.valuesOf(context).enabled`, menggunakan satu label loading, dan tidak interaktif. Entrypoint normal tidak memakai penundaan buatan.
- **Asisten Pelanggan:** Input pesan dibatasi maksimal 500 grapheme (termasuk emoji), state dibersihkan saat sesi berakhir, dan rekomendasi diberi catatan bukan jaminan medis bebas alergen.
- **Referensi Visual Awal:** Berkas [`desain/REFERENSI_UI_UX.pdf`](desain/REFERENSI_UI_UX.pdf) disimpan sebagai rujukan desain awal dan bukan tangkapan layar build terbaru.

## 2. Token Warna dan Status

Arah visual menggunakan aksen utama oranye di atas permukaan netral (`#FAFAFA` pada tema terang untuk membedakan kartu putih `#FFFFFF`, dan `#161618` pada tema gelap). Jangan memilih warna terang/gelap secara manual dengan `isDark ? ... : ...` atau memakai `Colors.white`/`Colors.black` secara langsung; ambil selalu dari `Theme.of(context).colorScheme` dan `KcStatusColors.of(context)`.

### 2.1 Palet Utama dan Surface

| Token `ColorScheme` | Terang | Gelap | Pasangan Teks/Ikon | Kegunaan Utama |
|---|---|---|---|---|
| `primary` | `#B83D13` | `#FF9A62` | `onPrimary` (`#FFFFFF` / `#321708`) | Aksi utama, elemen aktif, aksen fokus |
| `primaryContainer` | `#FFF0E9` | `#43291D` | `onPrimaryContainer` (`#6B2A12` / `#FFDCC8`) | Latar aksen lembut dan sorotan aktif |
| `secondary` | `#8A4A2F` | `#E5B39A` | `onSecondary` | Aksen hangat sekunder |
| `secondaryContainer` | — | — | `onSecondaryContainer` | Indikator chip dan tab navigasi terpilih |
| `tertiary` | `#52525B` | `#D4D4DC` | `onTertiary` | Aksen pendukung netral |
| `surface` | `#FAFAFA` | `#161618` | `onSurface` (`#252528` / `#F5F5F6`) | Latar halaman utama, judul, dan harga |
| `surfaceContainerLow` | `#FFFFFF` | `#1F1F22` | `onSurface` | Kartu (`Card`) dan bilah navigasi |
| `surfaceContainer` | `#F4F4F5` | `#27272A` | `onSurfaceVariant` (`#5F5F69` / `#C4C4CC`) | Kolom input, chip normal, panel standar |
| `surfaceContainerHigh` / `Highest` | — | — | `onSurface` | Panel bertingkat dan lintasan indikator progres |
| `outline` / `outlineVariant` | — | — | — | Border input/kontrol (`outline`) serta divider dan tepi kartu (`outlineVariant`) |
| `error` / `errorContainer` | — | — | `onError` / `onErrorContainer` | Status gagal, border error input, dan banner kegagalan |
| `inverseSurface` / `inversePrimary` | `#29292E` | `#F5F5F6` | `onInverseSurface` | Latar dan tombol aksi `SnackBar` (kontras sekitar 6.93:1 terang / 5.19:1 gelap) |

### 2.2 Warna Semantik Status dan Pesanan (`KcStatusColors`)

Token `status.success`, `status.warning`, dan `status.info` adalah warna *foreground* di atas container masing-masing (jangan dijadikan latar solid berteks putih):

| Status Pesanan / Kondisi | Foreground | Background Container |
|---|---|---|
| Menunggu konfirmasi (`pending`) / Peringatan | `status.warning` | `status.warningContainer` |
| Diproses (`preparing`) / Informasi | `status.info` | `status.infoContainer` |
| Siap diambil (`ready`) & Selesai (`completed`) | `status.success` | `status.successContainer` |
| Ditolak (`rejected`) / Gagal | `colors.onErrorContainer` | `colors.errorContainer` |

## 3. Tipografi, Spacing, Radius, dan Ukuran Sentuh

### 3.1 Skala Tipografi (`PlusJakartaSans`, `letterSpacing: 0`)

| Token `TextTheme` | Ukuran (dp) | Tinggi Baris | Bobot | Kegunaan |
|---|---:|---:|---:|---|
| `headlineLarge` / `Medium` / `Small` | 24 / 22 / 20 | 32 / 30 / 28 | 600 | Judul utama halaman, halaman ringkas, dan judul dialog/modal |
| `titleLarge` / `Medium` / `Small` | 18 / 16 / 14 | 24 / 24 / 20 | 600 | Judul `AppBar`/section, nama menu/item, dan subjudul padat |
| `bodyLarge` / `Medium` / `Small` | 16 / 14 / 12 | 24 / 20 / 16 | 400 | Teks input form (`bodyLarge`), isi deskripsi standar, dan metadata/keterangan |
| `labelLarge` / `Medium` / `Small` | 14 / 12 / 12 | 20 / 16 / 16 | 600 / 500 / 500 | Label tombol/chip (`labelLarge`), label navigasi, dan label pendukung |

### 3.2 Spacing, Radius, dan Area Sentuh Minimum

| Kategori | Token | Nilai (dp) | Kegunaan |
|---|---|---:|---|
| Spacing (`KcSpacing`) | `xs` / `sm` / `md` / `lg` | `8` / `12` / `16` / `24` | Jarak ikon-teks (`xs`), antar-elemen sekelompok (`sm`), padding standar (`md`), jarak antar-section (`lg`) |
| Spacing Halaman | `KcSpacing.pageHorizontal` | `16` | Padding horizontal standar halaman (alias semantik `md`) |
| Radius (`KcRadius`) | `small` / `control` / `card` / `modal` / `pill` | `10` / `12` / `16` / `20` / `999` | Chip/badge (`10`), input/tombol (`12`), kartu menu/pesanan (`16`), dialog/sheet (`20`), kapsul (`999`) |
| Ukuran (`KcSizes`) | `KcSizes.minimumTouchTarget` | `48` | Lebar dan tinggi minimum area sentuh (`minimumSize` / `BoxConstraints`, bukan tinggi tetap) |

## 4. Komponen Standar dan Pola Penggunaan

```dart
final theme = Theme.of(context);
final colors = theme.colorScheme;
final status = KcStatusColors.of(context);
```

- **Tombol:** Gunakan `FilledButton` untuk aksi utama, `OutlinedButton` untuk aksi sekunder, `TextButton` untuk aksi ringan, dan `IconButton` untuk aksi ikon. Saat operasi sedang berjalan, setel `onPressed: null`.
- **Input Form (`TextField` / `TextFormField`):** Menggunakan padding `KcSpacing.md` di semua sisi dan `bodyLarge` untuk label/hint. Prioritas warna label dan ikon otomatis mengikuti state: *disabled* (`onSurface` alpha 0.38) $\rightarrow$ *error* (`colors.error`) $\rightarrow$ *focused* (`colors.primary`) $\rightarrow$ *normal* (`colors.onSurfaceVariant`).
- **Chip & Navigasi (`ChoiceChip` / `NavigationBar`):** Kondisi normal memakai `onSurfaceVariant` di atas `surfaceContainer` (`surfaceContainerLow` untuk bar navigasi); kondisi terpilih memakai `onSecondaryContainer` di atas `secondaryContainer` dengan bobot teks 600.

## 5. Peta Berkas Tema dan Validasi

| Berkas di `app/lib/theme/` | Tanggung Jawab |
|---|---|
| `kc_colors.dart` | Definisi `ColorScheme` terang/gelap dan `ThemeExtension` `KcStatusColors` |
| `kc_typography.dart` | Konfigurasi font `PlusJakartaSans` dan skala `TextTheme` |
| `kc_spacing.dart`, `kc_radius.dart`, `kc_sizes.dart` | Konstanta jarak layout, radius sudut, dan batas ukuran sentuh minimum |
| `kc_theme.dart` & `kc_theme_exports.dart` | Perakitan `ThemeData` (`KcTheme.light`, `KcTheme.dark`) dan ekspor terpusat untuk layer UI |

Setelah mengubah berkas di `app/lib/theme/`, jalankan pemeriksaan dari direktori `app/`:

```bash
dart format lib/theme
flutter analyze --no-pub --fatal-infos --fatal-warnings lib test
flutter test --no-pub
```
