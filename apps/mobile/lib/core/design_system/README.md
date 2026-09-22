# Design System KantinCerdas

Design system adalah acuan visual bersama untuk seluruh aplikasi.

Jika lupa **token apa yang harus dipakai**, lihat Bagian 1.
Jika lupa **cara menggunakannya di Flutter**, lihat Bagian 2.

---

# 1. Kamus Design System

## 1.1 Warna Utama

| Token | Artinya | Dipakai untuk |
|---|---|---|
| `primary` | Warna utama aplikasi | Aksi utama, elemen aktif, aksen utama |
| `onPrimary` | Warna isi di atas `primary` | Teks/ikon pada background `primary` |
| `primaryContainer` | Primary versi lebih lembut | Background aksen, pilihan aktif |
| `onPrimaryContainer` | Warna isi di atas `primaryContainer` | Teks/ikon |
| `secondary` | Warna aksen sekunder | Aksen tambahan |
| `onSecondary` | Warna isi di atas `secondary` | Teks/ikon |
| `secondaryContainer` | Secondary versi lembut | Chip/navigation aktif |
| `onSecondaryContainer` | Isi di atas `secondaryContainer` | Teks/ikon |
| `tertiary` | Warna aksen tambahan | Aksen tambahan |
| `onTertiary` | Isi di atas `tertiary` | Teks/ikon |
| `tertiaryContainer` | Tertiary versi lembut | Background aksen |
| `onTertiaryContainer` | Isi di atas `tertiaryContainer` | Teks/ikon |

---

## 1.2 Surface

| Token | Artinya | Dipakai untuk |
|---|---|---|
| `surface` | Permukaan utama | Background halaman |
| `surfaceDim` | Surface lebih redup | Permukaan redup |
| `surfaceBright` | Surface lebih terang | Permukaan terang |
| `surfaceContainerLowest` | Container paling dekat dengan background | Permukaan level rendah |
| `surfaceContainerLow` | Container ringan | Card |
| `surfaceContainer` | Container standar | Input, panel |
| `surfaceContainerHigh` | Container lebih menonjol | Panel bertingkat |
| `surfaceContainerHighest` | Container paling menonjol | Track/progress atau surface tinggi |
| `onSurface` | Konten utama di atas surface | Judul, harga, teks utama |
| `onSurfaceVariant` | Konten sekunder | Subtitle, hint, metadata, ikon sekunder |

---

## 1.3 Border dan Error

| Token | Artinya | Dipakai untuk |
|---|---|---|
| `outline` | Border yang jelas | Input, kontrol |
| `outlineVariant` | Border yang lebih halus | Divider, border card |
| `error` | Warna error utama | Error, kegagalan |
| `onError` | Isi di atas `error` | Teks/ikon |
| `errorContainer` | Background error | Banner/pesan error |
| `onErrorContainer` | Isi di atas `errorContainer` | Teks/ikon error |

---

## 1.4 Warna Khusus Material

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

## 1.5 Warna Status

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

---

# 1.6 Typography

| Token | Ukuran | Weight | Dipakai untuk |
|---|---:|---:|---|
| `headlineLarge` | 24 | 600 | Judul layar utama |
| `headlineMedium` | 22 | 600 | Judul layar |
| `headlineSmall` | 20 | 600 | Judul kecil/dialog |
| `titleLarge` | 17 | 600 | Judul section |
| `titleMedium` | 16 | 500 | Judul item |
| `titleSmall` | 14 | 600 | Judul card kecil |
| `bodyLarge` | 16 | 400 | Teks isi besar |
| `bodyMedium` | 14 | 400 | Teks isi normal |
| `bodySmall` | 12 | 400 | Teks pendukung |
| `labelLarge` | 14 | 600 | Label tombol |
| `labelMedium` | 12 | 500 | Label kecil |
| `labelSmall` | 12 | 500 | Label pendukung |

Font:

```text
Plus Jakarta Sans
```

---

# 1.7 Spacing

| Token | Nilai | Dipakai untuk |
|---|---:|---|
| `KcSpacing.xs` | 8 | Jarak kecil, ikon dengan teks |
| `KcSpacing.sm` | 12 | Jarak elemen dalam satu kelompok |
| `KcSpacing.md` | 16 | Jarak/padding standar |
| `KcSpacing.lg` | 24 | Jarak antar-section |
| `KcSpacing.pageHorizontal` | 16 | Padding kiri-kanan halaman |

---

# 1.8 Radius

| Token | Nilai | Dipakai untuk |
|---|---:|---|
| `KcRadius.small` | 10 | Chip, badge |
| `KcRadius.control` | 12 | Input, button, card |
| `KcRadius.pill` | 999 | Bentuk kapsul |

---

# 1.9 Sizes

| Token | Nilai | Dipakai untuk |
|---|---:|---|
| `KcSizes.minimumTouchTarget` | 48 | Minimum area sentuh |

`48` adalah area sentuh minimum, bukan ukuran ikon.

---

# 1.10 Komponen

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
| `BottomNavigationBar` | Navigasi bawah lama |
| `AppBar` | Header halaman |
| `BottomSheet` | Panel dari bawah |
| `Dialog` | Dialog/modal |
| `SnackBar` | Pesan sementara |
| `ProgressIndicator` | Loading/progress |

Komponen tersebut sudah memiliki styling dasar dari `KcTheme`.

---

# 1.11 Cari Cepat

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
| Radius standar | `KcRadius.control` |

---

# 2. Cara Penggunaan

## 2.1 Mengaktifkan Theme

```dart
MaterialApp(
  theme: KcTheme.light,
  darkTheme: KcTheme.dark,
  themeMode: ThemeMode.system,
)
```

Tema otomatis mengikuti perangkat.

---

## 2.2 Mengambil Token

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

## 2.3 Contoh Penggunaan Warna

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

## 2.4 Pasangan Warna

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
    style: TextStyle(
      color: colors.onPrimaryContainer,
    ),
  ),
)
```

---

## 2.5 Typography

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

## 2.6 Spacing

| Kebutuhan | Contoh |
|---|---|
| Jarak kecil | `SizedBox(height: KcSpacing.xs)` |
| Jarak normal | `SizedBox(height: KcSpacing.md)` |
| Jarak section | `SizedBox(height: KcSpacing.lg)` |
| Padding halaman | `EdgeInsets.symmetric(horizontal: KcSpacing.pageHorizontal)` |

---

## 2.7 Tombol

| Jenis aksi | Komponen |
|---|---|
| Utama | `FilledButton` |
| Sekunder | `OutlinedButton` |
| Ringan | `TextButton` |
| Ikon | `IconButton` |

Contoh:

```dart
FilledButton(
  onPressed: () {},
  child: const Text('Buat pesanan'),
)
```

Tidak perlu mengatur warna, radius, padding, atau typography jika mengikuti style standar.

---

# 3. Aturan Singkat

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

# 4. Light dan Dark Mode

Widget **tidak memilih tema sendiri**.

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