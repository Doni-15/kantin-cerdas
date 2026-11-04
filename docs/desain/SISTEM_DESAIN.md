# Design System KantinCerdas

Implementasi token berada di `app/lib/theme/`. Dokumen ini menjadi acuan desain terpusat; perintah Flutter dijalankan dari folder `app/`.

Design system adalah acuan visual bersama untuk seluruh aplikasi.

Arah visual: oranye sebagai aksen utama, permukaan netral untuk konten,
dan warna status sesuai maknanya. Pada tema terang, halaman abu-abu sangat
muda membantu membedakan kartu putih. Tema gelap memakai abu-abu netral.

Gunakan panduan ini saat menyusun UI dari komponen Material dan token aplikasi.

- [1. Kamus design system](#1-kamus-design-system)
- [2. Cara penggunaan](#2-cara-penggunaan)
- [3. Aturan singkat](#3-aturan-singkat)
- [4. Light dan dark mode](#4-light-dan-dark-mode)
- [5. Peta file dan validasi](#5-peta-file-dan-validasi)

---

## 1. Kamus Design System

### 1.1 Warna Utama

| Token | Artinya | Dipakai untuk |
|---|---|---|
| `primary` | Warna utama aplikasi | Aksi utama, elemen aktif, aksen utama |
| `onPrimary` | Warna isi di atas `primary` | Teks/ikon pada background `primary` |
| `primaryContainer` | Primary versi lebih lembut | Background aksen, pilihan aktif |
| `onPrimaryContainer` | Warna isi di atas `primaryContainer` | Teks/ikon |
| `secondary` | Aksen hangat yang lebih tenang | Aksen tambahan |
| `onSecondary` | Warna isi di atas `secondary` | Teks/ikon |
| `secondaryContainer` | Secondary versi lembut | Chip/navigation aktif |
| `onSecondaryContainer` | Isi di atas `secondaryContainer` | Teks/ikon |
| `tertiary` | Aksen abu-abu netral | Aksen pendukung; hijau memakai status sukses |
| `onTertiary` | Isi di atas `tertiary` | Teks/ikon |
| `tertiaryContainer` | Tertiary versi lembut | Background aksen |
| `onTertiaryContainer` | Isi di atas `tertiaryContainer` | Teks/ikon |

---

### 1.2 Surface

| Token | Artinya | Dipakai untuk |
|---|---|---|
| `surface` | Permukaan utama | Background halaman |
| `surfaceDim` | Surface lebih redup | Permukaan redup |
| `surfaceBright` | Surface lebih terang | Permukaan terang |
| `surfaceContainerLowest` | Container pada level terendah | Lapisan dasar sesuai kebutuhan layout |
| `surfaceContainerLow` | Container ringan | Card |
| `surfaceContainer` | Container standar | Input, panel |
| `surfaceContainerHigh` | Container lebih menonjol | Panel bertingkat |
| `surfaceContainerHighest` | Container paling menonjol | Track/progress atau surface tinggi |
| `onSurface` | Konten utama di atas surface | Judul, harga, teks utama |
| `onSurfaceVariant` | Konten sekunder | Subtitle, hint, metadata, ikon sekunder |

---

### 1.3 Border dan Error

| Token | Artinya | Dipakai untuk |
|---|---|---|
| `outline` | Border yang jelas | Input, kontrol |
| `outlineVariant` | Border yang lebih halus | Divider, border card |
| `error` | Warna error utama | Error, kegagalan |
| `onError` | Isi di atas `error` | Teks/ikon |
| `errorContainer` | Background error | Banner/pesan error |
| `onErrorContainer` | Isi di atas `errorContainer` | Teks/ikon error |

---

### 1.4 Warna Khusus Material

| Token | Artinya | Dipakai untuk |
|---|---|---|
| `inverseSurface` | Surface dengan kontras terbalik | Snackbar |
| `onInverseSurface` | Isi di atas `inverseSurface` | Teks snackbar |
| `inversePrimary` | Primary untuk inverse surface | Aksi snackbar |
| `surfaceTint` | Tint surface Material | Internal Material |
| `shadow` | Warna bayangan | Shadow |
| `scrim` | Lapisan belakang modal | Dialog/bottom sheet |

Biasanya token pada tabel ini **tidak perlu dipakai langsung di screen**.

---

### 1.5 Warna Status

| Token | Artinya | Dipakai untuk |
|---|---|---|
| `status.success` | Status positif | Berhasil, siap diambil |
| `status.successContainer` | Background status positif | Banner/badge berhasil |
| `status.warning` | Status peringatan | Perlu perhatian |
| `status.warningContainer` | Background peringatan | Banner/badge warning |
| `status.info` | Status informasi | Informasi tambahan |
| `status.infoContainer` | Background informasi | Banner/badge info |
| `colors.error` | Status gagal | Error |
| `colors.errorContainer` | Background gagal | Banner error |
| `colors.onErrorContainer` | Isi di atas background gagal | Teks/ikon pada banner error |

#### 1.5.1 Status Pesanan

Status pesanan tidak memiliki palet warna terpisah. Gunakan token semantik
yang sudah tersedia pada design system.

| Status pesanan | Foreground | Background |
| --- | --- | --- |
| Menunggu konfirmasi | `status.warning` | `status.warningContainer` |
| Diproses | `status.info` | `status.infoContainer` |
| Siap diambil | `status.success` | `status.successContainer` |
| Selesai | `status.success` | `status.successContainer` |
| Ditolak | `colors.onErrorContainer` | `colors.errorContainer` |

Contoh:

```dart
final colors = Theme.of(context).colorScheme;
final status = KcStatusColors.of(context);
```

---

### 1.6 Typography

| Token | Ukuran | Tinggi baris | Bobot | Dipakai untuk |
|---|---:|---:|---:|---|
| `headlineLarge` | 24 | 32 | 600 | Judul utama halaman |
| `headlineMedium` | 22 | 30 | 600 | Judul halaman ringkas |
| `headlineSmall` | 20 | 28 | 600 | Judul dialog/bagian menonjol |
| `titleLarge` | 18 | 24 | 600 | Judul app bar/section |
| `titleMedium` | 16 | 24 | 600 | Nama menu/judul item |
| `titleSmall` | 14 | 20 | 600 | Judul konten padat |
| `bodyLarge` | 16 | 24 | 400 | Isi besar dan dasar teks input |
| `bodyMedium` | 14 | 20 | 400 | Deskripsi/isi standar |
| `bodySmall` | 12 | 16 | 400 | Metadata/keterangan singkat |
| `labelLarge` | 14 | 20 | 600 | Label tombol/chip |
| `labelMedium` | 12 | 16 | 500 | Label navigasi/kontrol ringkas |
| `labelSmall` | 12 | 16 | 500 | Label pendukung |

Font:

```text
Plus Jakarta Sans
```

Nama family pada konfigurasi Flutter adalah `PlusJakartaSans`, dengan
bobot font 400, 500, dan 600. Cocokkan nama family dan bobot dengan deklarasi
font di `pubspec.yaml`.

Dua belas gaya custom di atas memakai `letterSpacing: 0` agar tracking-nya
ditentukan eksplisit saat memakai Plus Jakarta Sans. Line height dinyatakan
sebagai rasio `lineHeight / fontSize`; ukuran yang dicantumkan adalah ukuran
dasar sebelum text scaling sistem.

Role `displayLarge`, `displayMedium`, dan `displaySmall` tetap mengikuti
skala dasar Material dengan family yang sama. Gunakan untuk kebutuhan
display khusus, bukan teks konten sehari-hari. Warna teks ditentukan oleh
tema aktif atau komponen; `KcTypography` mempertahankan properti style dasar.

---

### 1.7 Spacing

| Token | Nilai | Dipakai untuk |
|---|---:|---|
| `KcSpacing.xs` | 8 | Jarak kecil, ikon dengan teks |
| `KcSpacing.sm` | 12 | Jarak elemen dalam satu kelompok |
| `KcSpacing.md` | 16 | Jarak/padding standar |
| `KcSpacing.lg` | 24 | Jarak antar-section |
| `KcSpacing.pageHorizontal` | 16 | Padding kiri-kanan halaman |

Semua nilai memakai logical pixel. Gunakan jarak lebih kecil untuk elemen
yang saling berkaitan dan jarak lebih besar untuk memisahkan bagian konten.
`pageHorizontal` adalah alias semantik dari `md`: halaman memakai nama
berdasarkan fungsinya, sedangkan padding umum tetap memakai skala `md`.
Pada layar lebar, lebar konten dan penempatan kolom ditangani oleh layout.

---

### 1.8 Radius

| Token | Nilai | Dipakai untuk |
|---|---:|---|
| `KcRadius.small` | 10 | Chip, badge |
| `KcRadius.control` | 12 | Input, button |
| `KcRadius.card` | 16 | Kartu menu dan ringkasan pesanan |
| `KcRadius.modal` | 20 | Dialog dan sudut atas bottom sheet |
| `KcRadius.pill` | 999 | Bentuk kapsul |

---

### 1.9 Sizes

| Token | Nilai | Dipakai untuk |
|---|---:|---|
| `KcSizes.minimumTouchTarget` | 48 | Minimum area sentuh |

`48` adalah lebar dan tinggi minimum area sentuh, dalam logical pixel.
Ukuran ikon dapat lebih kecil daripada area sentuhnya. Terapkan token ini
sebagai batas minimum melalui `minimumSize` atau `BoxConstraints`, bukan
sebagai tinggi tetap. Komponen tetap boleh membesar mengikuti konten dan
skala teks; constraint dari parent harus memungkinkan ukuran tersebut.

---

### 1.10 Komponen

| Komponen | Artinya / digunakan untuk |
|---|---|
| `FilledButton` | Aksi utama |
| `OutlinedButton` | Aksi sekunder |
| `TextButton` | Aksi ringan |
| `IconButton` | Aksi dengan ikon |
| `Card` | Kelompok konten |
| `TextField` | Input |
| `TextFormField` | Input dalam form |
| `Chip` | Label/pilihan kecil |
| `NavigationBar` | Navigasi utama |
| `AppBar` | Header halaman |
| `BottomSheet` | Panel dari bawah |
| `Dialog` | Dialog/modal |
| `SnackBar` | Pesan sementara |
| `CircularProgressIndicator` / `LinearProgressIndicator` | Loading/progress |

Komponen tersebut sudah memiliki styling dasar dari `KcTheme`.

---

### 1.11 Cari Cepat

| Kalau mau membuat... | Pakai |
|---|---|
| Background halaman | `colors.surface` |
| Card | `Card` |
| Panel custom | `colors.surfaceContainer` |
| Teks utama | `colors.onSurface` |
| Teks sekunder | `colors.onSurfaceVariant` |
| Tombol utama | `FilledButton` |
| Tombol sekunder | `OutlinedButton` |
| Tombol ringan | `TextButton` |
| Aksen utama custom | `colors.primary` |
| Background aksen | `colors.primaryContainer` |
| Border jelas | `colors.outline` |
| Divider/border halus | `colors.outlineVariant` |
| Berhasil | `status.success` |
| Peringatan | `status.warning` |
| Informasi | `status.info` |
| Error | `colors.error` |
| Judul halaman | `headlineLarge/Medium/Small` |
| Judul section | `titleLarge` |
| Judul item | `titleMedium` |
| Isi teks | `bodyMedium` |
| Keterangan | `bodySmall` |
| Jarak normal | `KcSpacing.md` |
| Jarak section | `KcSpacing.lg` |
| Radius input/tombol | `KcRadius.control` |
| Radius kartu | `KcRadius.card` |

---

## 2. Cara Penggunaan

### 2.1 Mengaktifkan Theme

```dart
MaterialApp(
  theme: KcTheme.light,
  darkTheme: KcTheme.dark,
  themeMode: ThemeMode.system,
)
```

Dengan `ThemeMode.system`, tema mengikuti pengaturan perangkat. Pada
`MaterialApp.router`, pasang properti `theme`, `darkTheme`, dan `themeMode`
yang sama sambil mempertahankan konfigurasi router proyek.

---

### 2.2 Mengambil Token

| Yang dibutuhkan | Cara mengambil |
|---|---|
| Theme | `Theme.of(context)` |
| Warna | `Theme.of(context).colorScheme` |
| Typography | `Theme.of(context).textTheme` |
| Status | `KcStatusColors.of(context)` |
| Spacing | `KcSpacing...` |
| Radius | `KcRadius...` |
| Sizes | `KcSizes...` |

Biasanya:

```dart
final theme = Theme.of(context);
final colors = theme.colorScheme;
final status = KcStatusColors.of(context);
```

---

### 2.3 Contoh Penggunaan Warna

| Kebutuhan | Contoh |
|---|---|
| Background | `color: colors.surface` |
| Teks utama | `color: colors.onSurface` |
| Teks sekunder | `color: colors.onSurfaceVariant` |
| Aksen | `color: colors.primary` |
| Border | `color: colors.outline` |
| Divider | `color: colors.outlineVariant` |
| Error | `color: colors.error` |

---

### 2.4 Pasangan Warna

| Background | Isi di atasnya |
|---|---|
| `primary` | `onPrimary` |
| `primaryContainer` | `onPrimaryContainer` |
| `secondary` | `onSecondary` |
| `secondaryContainer` | `onSecondaryContainer` |
| `tertiary` | `onTertiary` |
| `tertiaryContainer` | `onTertiaryContainer` |
| `surface` | `onSurface` |
| `error` | `onError` |
| `errorContainer` | `onErrorContainer` |

Contoh:

```dart
Container(
  color: colors.primaryContainer,
  child: Text(
    'Pesanan aktif',
    style: theme.textTheme.labelLarge?.copyWith(
      color: colors.onPrimaryContainer,
    ),
  ),
)
```

---

### 2.5 Typography

| Kebutuhan | Contoh |
|---|---|
| Judul | `theme.textTheme.headlineSmall` |
| Judul section | `theme.textTheme.titleLarge` |
| Judul item | `theme.textTheme.titleMedium` |
| Isi | `theme.textTheme.bodyMedium` |
| Keterangan | `theme.textTheme.bodySmall` |

Contoh:

```dart
Text(
  'Menu cepat siap',
  style: theme.textTheme.titleLarge,
)
```

---

### 2.6 Spacing

| Kebutuhan | Contoh |
|---|---|
| Jarak kecil | `SizedBox(height: KcSpacing.xs)` |
| Jarak normal | `SizedBox(height: KcSpacing.md)` |
| Jarak section | `SizedBox(height: KcSpacing.lg)` |
| Padding halaman | `EdgeInsets.symmetric(horizontal: KcSpacing.pageHorizontal)` |

---

### 2.7 Tombol

| Jenis aksi | Komponen |
|---|---|
| Utama | `FilledButton` |
| Sekunder | `OutlinedButton` |
| Ringan | `TextButton` |
| Ikon | `IconButton` |

Contoh:

```dart
FilledButton(
  onPressed: onCreateOrder,
  child: const Text('Buat pesanan'),
)
```

`onCreateOrder` adalah callback dari widget pemanggil yang menjalankan
validasi dan proses pemesanan. Saat aksi belum tersedia atau submit sedang
berjalan, gunakan `onPressed: null`. Pencegahan submit ganda tetap ditangani
pada controller; theme hanya menentukan tampilan komponen.

Styling warna, radius, padding, dan tipografi standar diambil dari `KcTheme`.

Padding tombol filled/outlined memakai `lg` horizontal dan `sm` vertikal.
Text button memakai `md` horizontal dan `sm` vertikal; icon button memakai
`xs` di semua sisi. Batas minimum tetap berasal dari `KcSizes` sehingga
kontrol dapat membesar mengikuti teks dan constraint layout.

### 2.8 Label Input

`labelStyle` dan `floatingLabelStyle` mengikuti state input melalui
`WidgetStateTextStyle`. Urutan prioritasnya:

| State | Warna label |
|---|---|
| Disabled | `colors.onSurface` dengan alpha 0.38 |
| Error, termasuk saat fokus | `colors.error` |
| Fokus tanpa error | `colors.primary` |
| Normal | `colors.onSurfaceVariant` |

Label yang sudah mengambang kembali memakai warna normal saat input tidak
fokus. Gunakan styling bawaan ini agar label dan border error konsisten.

Label dan hint input memakai `bodyLarge` (16). Label mengambang mengikuti
mekanisme skala bawaan Flutter. Ikon prefix/suffix memakai prioritas warna
state yang sama dengan label. Padding input memakai `md` di semua sisi.

### 2.9 Kontras Aksi SnackBar

Pada tema gelap, `inversePrimary` menggunakan `#B83D13` di atas
`inverseSurface` (`#F5F5F6`). Rasio kontras warna solid ini sekitar **5.19:1**.
Pada tema terang, `#FF9A62` di atas `#29292E` menghasilkan sekitar **6.93:1**.

Perhitungan ini berlaku untuk pasangan warna tersebut tanpa overlay, bukan
sertifikasi aksesibilitas seluruh aplikasi. Acuan teks berukuran normal:
[WCAG 2.2 Contrast Minimum](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html).

### 2.10 Palet Utama

| Token | Terang | Gelap |
|---|---|---|
| `primary` | `#B83D13` | `#FF9A62` |
| `onPrimary` | `#FFFFFF` | `#321708` |
| `primaryContainer` | `#FFF0E9` | `#43291D` |
| `onPrimaryContainer` | `#6B2A12` | `#FFDCC8` |
| `secondary` | `#8A4A2F` | `#E5B39A` |
| `tertiary` | `#52525B` | `#D4D4DC` |
| `surface` | `#FAFAFA` | `#161618` |
| `surfaceContainerLow` | `#FFFFFF` | `#1F1F22` |
| `surfaceContainer` | `#F4F4F5` | `#27272A` |
| `onSurface` | `#252528` | `#F5F5F6` |
| `onSurfaceVariant` | `#5F5F69` | `#C4C4CC` |

`primary` dipakai terutama untuk aksi utama dan state aktif. Gunakan
`onSurface` untuk teks konten, termasuk harga. Konten di atas container
berwarna tetap memakai pasangan `on...Container` yang sesuai.

Role `primaryFixed`, `secondaryFixed`, dan `tertiaryFixed`, beserta pasangan
foreground-nya, ditentukan eksplisit agar konsisten dengan palet custom.
Role fixed memiliki warna yang sama pada tema terang dan gelap.

Token `success`, `warning`, dan `info` adalah foreground untuk container
status masing-masing. Hindari menjadikannya background solid dengan teks
putih karena pasangan tersebut belum disediakan oleh design system.

### 2.11 State Chip dan Navigasi

| Komponen dan state | Foreground | Background |
|---|---|---|
| Chip normal | `onSurfaceVariant` | `surfaceContainer` |
| Chip terpilih | `onSecondaryContainer` | `secondaryContainer` |
| Chip disabled | `onSurface` alpha 0.38 | `onSurface` alpha 0.12 |
| Ikon navigasi normal | `onSurfaceVariant` | `surfaceContainerLow` |
| Ikon navigasi terpilih | `onSecondaryContainer` | Indikator `secondaryContainer` |
| Navigasi disabled | `onSurface` alpha 0.38 | `surfaceContainerLow` |

State disabled memiliki prioritas di atas selected. Label `ChoiceChip`
terpilih menggunakan resolver yang sama melalui `secondaryLabelStyle`.
Label navigasi aktif memakai `onSurface` dan bobot 600; normal memakai
`onSurfaceVariant` dan bobot 500. Feedback hover/focus/pressed tombol tetap
mengikuti komponen Material.

Judul dialog memakai `headlineSmall`; judul app bar memakai `titleLarge`.
Pengaturan system overlay pada app bar menetapkan tampilan status bar;
system navigation bar mengikuti pengaturan aplikasi/platform.

---

## 3. Aturan Singkat

| Gunakan | Jangan |
|---|---|
| `colors.surface` | `Colors.white` |
| `colors.onSurface` | `Colors.black` |
| `colors.primary` | Hardcode warna oranye |
| `TextTheme` | Font size sembarang |
| `KcSpacing` | Magic number jika token tersedia |
| Komponen Material | Membuat tombol standar dari nol |
| Theme aktif | Memilih warna Light/Dark manual |
| Status colors | Menggunakan primary untuk semua status |

---

## 4. Light dan Dark Mode

Pilihan `ThemeMode` dikelola pada akar aplikasi. Widget mengambil token dari
`Theme.of(context)` agar mengikuti tema aktif.

Jangan:

```dart
isDark ? warnaDark : warnaLight
```

Gunakan:

```dart
colors.surface
colors.onSurface
colors.primary
```

`KcTheme` otomatis memberikan warna Light atau Dark yang sesuai.


---

## 5. Peta File dan Validasi

| File | Tanggung jawab |
|---|---|
| `kc_colors.dart` | ColorScheme dan extension warna status |
| `kc_typography.dart` | Font family dan skala teks |
| `kc_spacing.dart` | Jarak dan padding layout |
| `kc_radius.dart` | Radius komponen |
| `kc_sizes.dart` | Ukuran minimum area sentuh |
| `kc_theme.dart` | Merakit ThemeData dan styling komponen Material |
| `kc_theme_exports.dart` | Mengekspor API theme untuk dipakai UI |

Nilai token pada panduan ini telah dicocokkan dengan source theme yang direvisi.
Pemetaan file font tetap perlu diperiksa melalui `pubspec.yaml`.

Status analyzer/tes/build terbaru ada di [Status dan pengujian](../04_STATUS_DAN_PENGUJIAN.md). Golden test dan QA visual khusus tema tidak boleh dianggap lulus hanya dari tes yang tersedia. Uji layar kecil, keyboard, teks panjang/besar, normal/selected/disabled/error pada light/dark.

Perintah dari folder app:

```bash
dart format lib/theme
flutter analyze --no-pub --fatal-infos --fatal-warnings lib test
flutter test --no-pub
```
