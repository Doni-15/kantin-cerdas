# UI Authentication — Fondasi Tema, Responsivitas, Aksesibilitas

**Cakupan:** aturan visual lintas seluruh halaman Authentication; bukan desain satu layar.
**Sumber:** tujuh file Dart dari `theme.zip` pengguna.

## 1. Identitas visual yang diikuti

| Hal | Ketentuan |
|---|---|
| Framework | Flutter Material 3 (`useMaterial3: true` pada `KcTheme`) |
| Tema | `KcTheme.light`, `KcTheme.dark` |
| Font | `KcTypography.fontFamily = 'PlusJakartaSans'` |
| Judul utama | `textTheme.headlineLarge`: 24sp / line height 32 / w600 |
| Judul lebih ringkas | `headlineMedium`: 22/30/w600; `headlineSmall`: 20/28/w600 |
| Isi field | `bodyLarge`: 16/24/w400 |
| Deskripsi | `bodyMedium`: 14/20/w400 |
| Pesan penjelas singkat | `bodySmall`: 12/16/w400, hindari lebih kecil |
| Teks tombol | `labelLarge`: 14/20/w600 |
| Radius kontrol | `KcRadius.control = 12` |
| Radius dialog | `KcRadius.modal = 20` |
| Spacing | `KcSpacing.xs=8`, `sm=12`, `md=16`, `lg=24`, `pageHorizontal=16` |
| Ukuran area sentuh minimum | `KcSizes.minimumTouchTarget = 48` logical pixels |

Pakai `Theme.of(context).colorScheme`, `Theme.of(context).textTheme`, dan theme component yang telah didefinisikan di `kc_theme.dart`. **Jangan menaruh hex dari tabel berikut secara hardcoded dalam widget**. Tabel hanya verifikasi terhadap sumber.

| Semantic ColorScheme | Light | Dark | Pemakaian |
|---|---|---|---|
| `primary` | `#B83D13` | `#FF9A62` | Tombol utama / tautan aktif |
| `onPrimary` | `#FFFFFF` | `#321708` | Teks pada tombol utama |
| `surface` | `#FAFAFA` | `#161618` | Latar layar |
| `surfaceContainer` | `#F4F4F5` | `#27272A` | Isi kontrol input |
| `onSurface` | `#252528` | `#F5F5F6` | Judul / label utama |
| `onSurfaceVariant` | `#5F5F69` | `#C4C4CC` | Subteks / hint |
| `outline` | `#7B7B85` | `#94949E` | Border field utama |
| `outlineVariant` | `#E1E1E6` | `#414147` | Divider dan batas halus |
| `error` | `#B3261E` | `#FFB4AB` | Feedback error |

## 2. Komposisi visual

- Latar halaman sederhana; **tidak ada kartu besar yang membungkus semua field**.
- Teks judul + deskripsi **rata tengah** pada layar Auth.
- Label field dan input rata kiri. Ikon input **tidak perlu** kecuali fungsional (misalnya show/hide password).
- Primary CTA full-width di dalam kolom form; secondary social sign-in tombol outlined full-width.
- **Jangan** menambahkan banner promo, foto/ilustrasi kuliner, gradient, shadow berat, carousel, dekorasi acak, atau mengulang branding pada semua layar.
- Logo asli tampil pada Login; layar pendukung memakai tombol kembali dan judul; jangan mengarang aset logo.
- Jarak/ukuran boleh beradaptasi sesuai layar, tetapi **jangan mengubah urutan komponen yang telah disetujui**.

## 3. Responsivitas — aturan yang dapat diuji

- **Mobile-first.** Pada lebar kecil, satu kolom yang diberi padding horizontal dasar 16dp dari tema; konten menggulir sesuai kebutuhan.
- Pada lebar besar/tablet/desktop, tetap satu kolom dengan **maksimum lebar form sekitar 420 logical px** dan dipusatkan; tidak membuat split hero baru.
- `SafeArea` diperhatikan. Keyboard terbuka tidak boleh menutupi tombol aksi yang harus dijangkau; user dapat scroll.
- **Tidak** boleh mengandalkan posisi absolute, tinggi layar tetap, maupun spacer besar yang membuat tindakan penting tidak terjangkau.
- Saat teks sistem diperbesar, teks boleh membungkus dan tinggi kontrol berkembang; tidak boleh clipping, overlap, atau overflow.
- Orientasi landscape dan layar pendek harus tetap fungsional; jarak header berkurang secara adaptif.
- Pada layar besar gunakan area kosong secara tenang, bukan membesarkan font/input secara proporsional tanpa batas.
- Tautan, kontrol kembali, dan password visibility memiliki target sentuh **minimum 48×48** meskipun teks/ikonnya lebih kecil.
- Autofill email/password, fokus, tombol keyboard, screen reader label dan tab order mengikuti alur visual; error bisa dibaca screen reader.

## 4. Light dan Dark Mode adalah fitur wajib semua layar

- Kedua mode **memiliki susunan konten, fungsi, validasi, state, dan navigasi sama**; hanya nilai warna/kontras mengikuti `KcTheme`.
- Hindari field dengan permukaan light hardcoded pada tema gelap, placeholder tidak terbaca, atau logo tidak kontras. Bila logo asli hanya cocok untuk satu mode, **cek aset resmi/varian resmi**; jangan memodifikasi logo tanpa persetujuan.
- Mode dapat mengikuti sistem atau pengaturan aplikasi yang tersedia. Dokumen UI Auth ini **tidak menambah kontrol theme toggle pada layar Login**.
- Uji teks sekunder, disabled CTA, error, outlined Google, divider, foto avatar dan indikator progres pada kedua mode.

## 5. Ketergantungan aset dan integrasi

- `theme.zip` berisi tujuh file Dart, **tidak** menyertakan `pubspec.yaml`, gambar logo, atau font `.ttf`. Periksa asset registration dalam proyek nyata sebelum mengimplementasikan UI.
- Gunakan **logo Google resmi**, bukan ikon Chrome yang digunakan pada wireframe awal.
- Pemilih foto, deep link verifikasi/reset, session validation, dan service auth **tidak boleh disimpulkan dari dokumen tema**. Itu kontrak integrasi terpisah.

## 6. Matriks pemeriksaan global

| Situasi | Hasil yang diwajibkan UI |
|---|---|
| Android 320dp, 360dp, 430dp | Tidak ada overflow; field, link, tombol dapat dijangkau |
| Keyboard terbuka | Fokus input dan CTA dapat dijangkau lewat scroll |
| Tablet/desktop | Kolom kerja nyaman ≤±420dp dan berada di tengah |
| Landscape | Header mengecil adaptif, tidak ada clipped form |
| Text scaling sistem | Tidak ada clipped text; target tap terjaga |
| Light | Warna kontras sesuai theme light |
| Dark | Warna kontras sesuai theme dark; tidak ada hardcode |
| Screen reader / keyboard | Label, fokus, dan pesan error bisa diakses |
