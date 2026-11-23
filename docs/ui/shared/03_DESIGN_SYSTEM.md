# Design System — bersumber dari theme.zip asli

**Bukti sumber:** `theme/kc_theme.dart`, `kc_colors.dart`, `kc_typography.dart`, `kc_spacing.dart`, `kc_radius.dart`, `kc_sizes.dart`. Jangan membuat tema alternatif berdasarkan warna preview percakapan.

## Token terverifikasi

| Token / API | Nilai / kewajiban |
|---|---|
| `KcTheme.light`, `.dark` | Dua `ThemeData` Material 3, `useMaterial3: true` |
| `KcTypography.fontFamily` | `PlusJakartaSans` |
| `headlineLarge` | 24sp; line-height 32; w600 |
| `titleLarge` | 18sp; line-height 24; w600 |
| `titleMedium` | 16sp; line-height 24; w600 |
| `bodyLarge` | 16sp; line-height 24; w400 |
| `bodyMedium` | 14sp; line-height 20; w400 |
| `bodySmall` | 12sp; line-height 16; w400 |
| `labelLarge` | 14sp; line-height 20; w600 |
| `labelMedium` | 12sp; line-height 16; w500 |
| `KcSpacing.xs / sm / md / lg` | 8 / 12 / 16 / 24 |
| `KcSpacing.pageHorizontal` | 16 |
| `KcRadius.small/control/card/modal/pill` | 10 / 12 / 16 / 20 / 999 |
| `KcSizes.minimumTouchTarget` | 48 logical px |
| `KcStatusColors` | Theme extension untuk warna status; ikuti definisi aktual, jangan menggambar palet sendiri |

## Standar visual lintas modul

- Minimalis, white space terstruktur, judul tidak berulang, divider tipis, warna hanya ketika menandai aksi utama/status.
- Daftar Owner/Admin: satu permukaan daftar berisi baris + divider, **bukan satu kartu besar per baris**.
- Customer: kartu kantin/menu ringkas horizontal sesuai UI LOCKED; foto kecil dan placeholder jika foto opsional kosong.
- Formulir pendek (1 input: kategori) melalui **modal bottom sheet**; formulir panjang (menu, kantin, pendaftaran, pengajuan) halaman khusus.
- Desain tema mengikuti `Theme.of(context).colorScheme`, `textTheme` dan `KcStatusColors`, tidak menempel warna mockup hex.
- Ikon gunakan Material Icons Flutter yang tersedia; **chatbot Customer: `Icons.smart_toy_rounded`**. Ikon lain mengikuti konsistensi Material 3.
- Jangan menyematkan nama kantin Customer palsu, gambar stok dekoratif, rating, badge diskon, atau angka kuota contoh sebagai data produksi.

## Navigasi visual

- Customer root: notched `BottomAppBar` + `FloatingActionButtonLocation.centerDocked`, `CircularNotchedRectangle`, FAB diameter visual ~56dp, gap/notch halus; FAB robot tanpa teks visual, **semanticLabel Food Assistant**; 4 icon+label seimbang di kiri/kanan.
- Owner/Admin root: empat item datar sejajar, tanpa FAB robot atau notch; FAB `+` hanya pada daftar Menu Owner, kanan bawah di atas nav; tidak ditempelkan pada daftar sebagai baris.
- Subhalaman: tombol Kembali, tidak menggandakan bottom navigation; semua touch target >=48dp.
- SafeArea, gesture inset, papan ketik, scrolling, font scale, rotasi, tablet. Ukuran breakpoint implementasi perlu berdasarkan ruang tersedia, bukan angka arbitrer dari mockup.

## Aset

- Logo/font harus benar-benar tersedia di repo; `theme.zip` tidak menjamin aset logo/font dibundel. Jika hilang, laporkan dependensi; jangan membuat logo sementara lalu mengklaim resmi.
- Foto kantin/menu opsional; avatar fallback jika data gambar tidak ada.
