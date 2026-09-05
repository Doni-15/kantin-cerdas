# Roadmap Pengembangan KantinCerdas

**Dokumen:** Roadmap Produk, Engineering, dan Version Control  
**Versi roadmap:** 2.0  
**Platform:** Android dengan Flutter  
**Target produk:** Aplikasi pesan-ambil pada satu kantin kampus dengan Asisten Pilih Menu berbasis AI  
**Baseline visual:** “Kantin Kampus Praktis” — praktis, hangat, dekat, tenang, dan mudah dipindai  
**Sumber kebenaran visual:** [`DESIGN_SYSTEM.md`](../design/DESIGN_SYSTEM.md)

---

## 1. Tujuan Roadmap

Roadmap ini menjadi pedoman bersama untuk:

- membangun KantinCerdas secara bertahap tanpa memperluas scope;
- menyelesaikan UI yang siap didemonstrasikan menggunakan dummy data dalam dua minggu pertama;
- memastikan pergantian dummy data ke backend tidak memerlukan perubahan besar pada UI;
- mempelajari Git, branch, commit, pull request, tag, dan release secara langsung;
- menentukan versi aplikasi untuk setiap penambahan fitur dan perbaikan;
- menerapkan satu design system yang konsisten pada UI mahasiswa dan pengelola;
- memastikan seluruh kebutuhan pada [Mini-SRS](MINI_SRS.md) dapat ditelusuri sampai ke implementasi dan pengujian.

Roadmap menggunakan **GitHub Flow**: satu branch utama `main` dan branch pendek untuk setiap pekerjaan. Model ini lebih sederhana untuk proyek mahasiswa daripada memelihara branch `develop` dalam waktu lama.

---

## 2. Batas Produk yang Tidak Boleh Berubah Diam-diam

Baseline `v1.0.0` hanya mencakup:

- satu kantin pada satu kampus;
- beberapa stan yang sudah terdaftar;
- katalog, pencarian, dan filter menu;
- Asisten Pilih Menu berbasis AI;
- keranjang dari satu stan;
- pemesanan untuk diambil pada hari yang sama;
- pembayaran di konter;
- pengelolaan status menu dan pesanan;
- notifikasi Android ketika pesanan ditolak atau siap diambil.

Baseline tidak mencakup:

- pengantaran;
- GPS atau peta;
- pembayaran digital;
- pemesanan untuk hari lain atau slot waktu tertentu;
- promo dan voucher;
- rating atau ulasan;
- pendaftaran UMKM umum;
- banyak kampus;
- analitik penjualan lanjutan.

Fitur di luar baseline harus masuk backlog setelah `v1.0.0` dan memerlukan pembaruan [Mini-SRS](MINI_SRS.md) sebelum dikerjakan.

### 2.1 Baseline Pengalaman dan Desain yang Dikunci

Posisi proyek pada revisi roadmap ini adalah **arah visual sudah dipilih, sedangkan implementasi Flutter tetap mengikuti status repository**. Checklist coding tidak boleh dianggap selesai hanya karena mockup sudah tersedia.

Alur utama mahasiswa:

```text
Beranda → Detail Stan / Floating Assistant → Bottom Sheet Rekomendasi → Keranjang → Konfirmasi → Status Pesanan → Ambil dan bayar di konter
```

Alur utama pengelola:

```text
Dashboard → Pesanan Masuk → Detail Pesanan → Terima/Tolak → Diproses → Siap Diambil → Selesai
```

Aturan visual utama:

| Bagian | Keputusan yang dikunci |
|---|---|
| Arah visual | “Kantin Kampus Praktis”: praktis, hangat, dekat, tenang, dan mudah dipindai |
| Warna merek | `#E85D2A` (`brandOrange`) |
| Warna tombol/aksi | `#C74418` (`actionOrange`) agar kontras lebih aman |
| Warna gelap | `#9B341B` (`darkTerracotta`) |
| Latar utama | `#FAFAF8` (`backgroundWarm`) |
| Surface | `#FFFFFF`; `#F7F3F0` hanya untuk section yang perlu dibedakan |
| Outline | `#DDD6D1` |
| Teks utama | `#251B17` (`textPrimary`) |
| Tipografi | Plus Jakarta Sans; fallback Inter/sans-serif sistem |
| Layout | Grid 8 dp, padding halaman 16 dp, target sentuh minimal 48 × 48 dp |
| Bentuk | Radius 8, 12, 16, 24, dan pill; shadow digunakan secara hemat |
| Daftar | Grouped list dan divider; kartu hanya untuk objek mandiri |
| Asisten | FAB 56 × 56 dp pada Beranda/Detail Stan, coachmark satu kali, lalu modal bottom sheet |
| Ikon | Material Symbols Rounded; emoji tidak dipakai sebagai ikon UI |
| Foto | Foto makanan Indonesia yang natural, crop konsisten, tanpa teks/logo |

Navigasi mahasiswa memakai **Beranda—Pesanan—Profil**. Navigasi pengelola memakai **Dashboard—Pesanan—Menu—Profil**. Keranjang muncul sebagai sticky cart bar ketika berisi item, bukan sebagai tab permanen.

[Full Mockup UI/UX v2](../design/mockups/FULL_MOCKUP_UIUX_V2.pdf) yang menjadi acuan meliputi:

- mahasiswa: 11 layar dari Beranda sampai Profil/Preferensi;
- pengelola: 6 layar dari Dashboard sampai Profil;
- state penting: loading, hasil kosong, offline, error/retry, stan tutup, menu habis, coachmark, bottom sheet, dan reduced motion;
- komponen: warna, tipografi, spacing, radius, tombol, input, chip, grouped list, status, quantity stepper, navigation bar, dan floating assistant.

Setiap perubahan visual harus mengikuti [`DESIGN_SYSTEM.md`](../design/DESIGN_SYSTEM.md). Jika implementasi perlu menyimpang, keputusan tersebut harus dicatat dalam pull request dan dokumen desain diperbarui.

---

## 3. Strategi Penomoran Versi

KantinCerdas menggunakan **Semantic Versioning (SemVer)**:

```text
MAJOR.MINOR.PATCH-PRERELEASE+BUILD
```

Contoh versi Flutter:

```yaml
version: 0.7.0-beta.1+8
```

Artinya:

- `0` adalah MAJOR;
- `7` adalah MINOR;
- `0` adalah PATCH;
- `beta.1` adalah tahap kesiapan;
- `7` setelah tanda `+` adalah nomor build Android dan harus selalu meningkat untuk build yang dibagikan.

### 3.1 Arti Setiap Jenis Versi

| Jenis | Kapan digunakan | Contoh |
|---|---|---|
| **MAJOR** | Perubahan besar yang tidak kompatibel, merombak aktor, alur utama, kontrak API, atau scope produk | `v1.0.0` → `v2.0.0` |
| **MINOR** | Penambahan fitur baru yang tetap kompatibel dengan fitur sebelumnya | `v0.3.0` → `v0.4.0` |
| **PATCH** | Perbaikan bug, keamanan, performa, atau kesalahan teks tanpa menambah kemampuan utama | `v1.0.0` → `v1.0.1` |
| **alpha** | Fitur belum lengkap dan hanya untuk pengembangan internal | `v0.4.0-alpha.1` |
| **beta** | Fitur utama sudah dapat digunakan dan siap diuji pengguna/dosen | `v0.7.0-beta.1` |
| **rc** | Kandidat rilis; tidak boleh ada fitur baru, hanya perbaikan | `v1.0.0-rc.1` |
| **stable** | Versi yang disetujui untuk demo atau pengumpulan akhir | `v1.0.0` |

### 3.2 Aturan Khusus Selama Versi `0.x`

Versi `0.x` menandakan produk masih dikembangkan. Agar mudah dipelajari, tim memakai aturan berikut:

- setiap kelompok fitur baru menaikkan MINOR: `0.3.0` → `0.4.0`;
- perbaikan pada tahap alpha/beta menaikkan nomor prerelease: `alpha.1` → `alpha.2`;
- setelah rilis stabil `v1.0.0`, perbaikan biasa memakai PATCH: `v1.0.1`;
- perubahan yang membatalkan kompatibilitas sebelum `v1.0.0` tetap harus ditulis sebagai `BREAKING CHANGE` pada commit dan release notes;
- setelah `v1.0.0`, perubahan tidak kompatibel wajib menaikkan MAJOR.

### 3.3 Hubungan Perubahan dengan Jenis Versi

| Perubahan | Commit utama | Jenis kenaikan |
|---|---|---|
| Menambah halaman katalog | `feat` | MINOR |
| Menambah Asisten Pilih Menu | `feat` | MINOR |
| Menambah notifikasi Android | `feat` | MINOR |
| Memperbaiki total harga yang salah | `fix` | PATCH/prerelease berikutnya |
| Memperbaiki crash saat jaringan putus | `fix` | PATCH/prerelease berikutnya |
| Mengubah warna tanpa mengubah perilaku | `style` | Tidak perlu rilis sendiri; gabungkan ke rilis berikutnya |
| Refactor tanpa mengubah perilaku | `refactor` | Tidak perlu rilis sendiri atau PATCH jika perlu dibagikan |
| Menambah unit test | `test` | Tidak perlu rilis sendiri |
| Memperbarui SRS/README | `docs` | Tidak perlu rilis aplikasi sendiri |
| Mengubah kontrak API secara tidak kompatibel | `feat!`/`BREAKING CHANGE` | MAJOR setelah `v1.0.0` |
| Mengubah KantinCerdas menjadi marketplace banyak kampus | `feat!` | MAJOR, misalnya `v2.0.0` |

---

## 4. Ringkasan Roadmap Rilis

| Target versi | Jenis | Fokus fitur | Hasil utama |
|---|---|---|---|
| `v0.1.0-alpha.1` | MINOR + alpha | Fondasi proyek, Git, dan acuan desain | Repository, dokumentasi, visual baseline, CI, dan struktur Flutter siap |
| `v0.1.0-alpha.2` | Pemutakhiran alpha | Perapian fondasi | Struktur source, dokumentasi rilis, dan metadata kolaborasi lebih jelas tanpa fitur produk baru |
| `v0.2.0-alpha.1` | MINOR + alpha | Penerapan “Kantin Kampus Praktis” | Theme/token, komponen bersama, navigasi, state umum, dan fake repository |
| `v0.3.0-alpha.1` | MINOR + alpha | Katalog, pencarian, dan filter | Pengguna dapat menemukan menu secara manual |
| `v0.4.0-alpha.1` | MINOR + alpha | Asisten Pilih Menu | UI AI, ekstraksi kriteria, klarifikasi, rekomendasi, dan fallback dummy |
| `v0.5.0-alpha.1` | MINOR + alpha | Keranjang dan pemesanan | Alur satu stan, konfirmasi total, nomor, dan status pesanan |
| `v0.6.0-alpha.1` | MINOR + alpha | Panel pengelola | Pengelola dapat memperbarui stan, menu, dan status pesanan |
| `v0.7.0-beta.1` | MINOR + beta | Notifikasi dan demo UI | Notification API, izin Android 13+, deep link, dan checkpoint dua minggu |
| `v0.8.0-beta.1` | MINOR + beta | Integrasi backend | API client, autentikasi, secure storage, dan pergantian data melalui `.env` |
| `v0.9.0-beta.1` | MINOR + beta | AI dan notifikasi end-to-end | AI melalui backend, validasi hasil, FCM, dan alur pesanan nyata |
| `v1.0.0-rc.1` | MAJOR candidate | Feature freeze dan QA | Semua FR/NFR diuji; hanya bug blocker yang boleh diperbaiki |
| `v1.0.0` | MAJOR stable | Rilis baseline | APK/AAB, dokumentasi, release notes, dan bahan demo final |

> Tag versi hanya dibuat setelah branch fitur sudah masuk ke `main` dan kriteria penerimaan versinya terpenuhi.

---

## 5. Roadmap Terperinci per Versi

## `v0.1.0-alpha.1` — Fondasi Proyek dan Version Control

**Jenis versi:** MINOR prarilis alpha  
**Estimasi:** Hari 1  
**Tujuan belajar:** repository, branch, commit, pull request, dan tag pertama

### Pekerjaan

- Membuat repository Git dan proyek Flutter.
- Menambahkan `.gitignore` Flutter/Android.
- Menambahkan `README.md`, `ROADMAP.md`, dan [Mini-SRS](MINI_SRS.md).
- Menambahkan [`DESIGN_SYSTEM.md`](../design/DESIGN_SYSTEM.md), mockup mahasiswa/pengelola, dan mencatat keputusan “Kantin Kampus Praktis”.
- Menambahkan `.env.example`; file `.env` asli wajib masuk `.gitignore`.
- Menetapkan struktur awal:

```text
lib/
├── app/
├── core/
├── features/
└── shared/
```

- Mengaktifkan formatter, linter, `flutter analyze`, dan `flutter test`.
- Membuat workflow CI sederhana untuk pull request.
- Menetapkan Conventional Commits dan aturan branch.

### Branch yang digunakan

```text
chore/project-bootstrap
chore/ci-quality-gate
docs/add-project-docs
```

### Kriteria selesai

- Proyek dapat dijalankan oleh anggota lain dari hasil clone.
- Tidak ada secret atau file `.env` asli dalam Git.
- `dart format`, `flutter analyze`, dan `flutter test` berhasil.
- Diff Pull Request pertama diperiksa dan digabungkan setelah CI berhasil.
- Sumber kebenaran visual dan mockup terpilih tersedia bagi seluruh anggota tim.
- Tag `v0.1.0-alpha.1` dibuat dari `main`.

### Pemutakhiran `v0.1.0-alpha.2`

Pemutakhiran ini hanya merapikan fondasi kolaborasi, struktur source, dan
dokumentasi rilis. App shell, design tokens, navigasi, fake data, reusable
components, serta seluruh fitur produk tetap berada pada `v0.2.0-alpha.1` dan
versi berikutnya.

---

## `v0.2.0-alpha.1` — App Shell, Design System, dan Arsitektur Data

**Jenis versi:** MINOR prarilis alpha  
**Estimasi:** Hari 2–3  
**Tujuan belajar:** memecah perubahan besar menjadi beberapa branch kecil

### Fitur

- `ThemeData`/`ColorScheme` berdasarkan token “Kantin Kampus Praktis”; warna tidak ditulis berulang di widget.
- Tipografi Plus Jakarta Sans dengan fallback Inter/sans-serif sistem.
- Token spacing berbasis grid 8 dp, radius 8/12/16/24/pill, dan elevation yang terbatas.
- Material Symbols Rounded untuk ikon aplikasi.
- Komponen bersama untuk primary/secondary/tertiary/destructive button beserta state loading dan disabled.
- Komponen bersama untuk search field, filter chip, menu row, status badge, quantity stepper, dialog, bottom sheet, snackbar, dan sticky cart bar.
- Komponen loading, skeleton, empty, error/retry, offline, disabled, dan success yang konsisten.
- Navigasi mahasiswa: Beranda—Pesanan—Profil.
- Navigasi pengelola: Dashboard—Pesanan—Menu—Profil.
- Model domain awal: `User`, `Stall`, `MenuItem`, `Order`, dan `Recommendation`.
- Repository interface agar UI tidak bergantung langsung pada dummy/API.
- Implementasi `FakeRepository` dan seed dummy data.
- Konfigurasi environment untuk memilih sumber data tanpa merombak UI.
- Widget catalog/showcase internal untuk memeriksa seluruh komponen dan state visual.

### Branch yang digunakan

```text
feat/kantin-praktis-theme
feat/shared-ui-components
feat/app-navigation
feat/domain-models
chore/fake-repository
test/design-system
```

### Kriteria selesai

- Semua halaman utama dapat dinavigasi walaupun isinya masih dummy.
- Theme, komponen, dan navigasi mengikuti [`DESIGN_SYSTEM.md`](../design/DESIGN_SYSTEM.md) dan mockup terpilih.
- Tidak ada warna, text style, spacing, atau radius utama yang hard-coded berulang di feature widget.
- Tombol/input memiliki target sentuh minimal 48 × 48 dp dan state interaksi lengkap.
- UI mahasiswa dan pengelola memakai bahasa visual yang sama.
- Widget utama tidak overflow pada lebar 360, 390, dan 412 dp serta saat text scale diperbesar.
- UI hanya mengenal repository interface, bukan JSON/API secara langsung.
- State loading, kosong, gagal/retry, offline, disabled, dan berhasil dapat disimulasikan.
- Pull request UI menyertakan screenshot perbandingan terhadap acuan visual.
- Tag `v0.2.0-alpha.1` dibuat dari `main`.

---

## `v0.3.0-alpha.1` — Katalog, Pencarian, dan Filter Manual

**Jenis versi:** MINOR prarilis alpha  
**Estimasi:** Hari 4–5  
**Requirement:** FR-01, FR-02, dan bagian fallback FR-06

### Fitur

- Beranda “Kantin Kampus Praktis” berisi sapaan, search field, kategori, daftar “Cepat jadi”, daftar “Stan yang buka”, dan floating assistant yang tidak mendominasi konten.
- Daftar stan dan status buka/tutup tanpa jarak, rating, promo, atau elemen delivery.
- Detail stan dan daftar menu berdasarkan stan.
- Baris menu dan Detail Menu berisi foto, nama, harga, stan, ketersediaan, tingkat kepedasan, serta estimasi penyajian.
- Pencarian nama menu.
- Filter kategori, rentang harga, dan tingkat kepedasan memakai filter chip dari design system.
- Empty state apabila tidak ada menu yang cocok.
- Foto makanan memiliki crop konsisten dan fallback ketika gagal dimuat.
- Pengujian filter dan pencarian.

### Branch yang digunakan

```text
feat/stall-catalog
feat/menu-search
feat/menu-filter
test/catalog-filter
```

### Kriteria selesai

- Pengguna dapat menemukan menu tanpa menggunakan AI.
- Hanya menu tersedia yang dapat dipilih untuk dipesan.
- Filter dapat dihapus dan tidak meninggalkan state lama.
- Beranda, Detail Stan, dan baris menu sesuai acuan “Kantin Kampus Praktis” pada lebar 360/390/412 dp.
- Screenshot hasil implementasi dibandingkan dengan mockup mahasiswa.
- Tag `v0.3.0-alpha.1` dibuat dari `main`.

---

## `v0.4.0-alpha.1` — Asisten Pilih Menu Berbasis AI

**Jenis versi:** MINOR prarilis alpha  
**Estimasi:** Hari 6–7  
**Requirement:** FR-03 sampai FR-06

### Fitur UI dan kontrak

- Floating assistant 56 × 56 dp hanya pada Beranda dan Detail Stan; route lain dan seluruh sisi pengelola menyembunyikannya.
- Coachmark “Bingung pilih? Aku bantu cari menu.” muncul satu kali setelah konten stabil, dapat ditutup, dan state sudah dilihat disimpan lokal.
- Pengingat kontekstual hanya muncul saat ada kebutuhan nyata dan maksimal satu kali per sesi.
- Reduced motion menonaktifkan animasi scale tanpa menghilangkan akses ke asisten.
- Asisten terbuka sebagai modal bottom sheet yang dimulai dari pilihan budget, waktu tunggu, selera, dan field “Tulis pilihan lain…”.
- Pertanyaan klarifikasi mempertahankan input dan pilihan sebelumnya.
- Maksimal lima rekomendasi disertai alasan, data katalog terverifikasi, serta aksi buka detail atau tambah ke keranjang.
- Error state, timeout, retry, hasil kosong, dan kembali ke filter manual.
- `FakeAiRecommendationService` untuk demo UI.
- Interface `AiRecommendationService` agar integrasi AI nyata tidak mengubah halaman.

### Batas keamanan

- AI tidak boleh mengarang nama, harga, stok, atau estimasi.
- AI tidak boleh membuat pesanan otomatis.
- API key AI tidak boleh disimpan di aplikasi Flutter.
- Semua hasil rekomendasi harus divalidasi ulang terhadap data menu.

### Branch yang digunakan

```text
feat/floating-menu-assistant
feat/ai-criteria-parser-contract
feat/ai-recommendation-card
feat/ai-fallback
```

### Kriteria selesai

- Skenario “Rp20.000, tidak pedas, maksimal 10 menit” menghasilkan rekomendasi dummy yang sesuai.
- Masukan ambigu menghasilkan permintaan klarifikasi.
- Simulasi kegagalan AI tetap memberikan akses ke filter manual.
- Floating assistant, coachmark, bottom sheet, chip kriteria, dan rekomendasi memakai komponen/token design system serta sesuai mockup v2.
- Tag `v0.4.0-alpha.1` dibuat dari `main`.

---

## `v0.5.0-alpha.1` — Keranjang dan Pemesanan Satu Stan

**Jenis versi:** MINOR prarilis alpha  
**Estimasi:** Hari 8  
**Requirement:** FR-07 dan FR-08

### Fitur

- Sticky cart bar muncul di atas bottom navigation ketika keranjang berisi item.
- Menambahkan, mengurangi, dan menghapus item.
- Mencegah item dari stan berbeda berada dalam satu keranjang.
- Menghitung subtotal dan total.
- Memeriksa ulang harga serta ketersediaan sebelum konfirmasi.
- Menampilkan halaman Keranjang, Konfirmasi, Pesanan Berhasil, dan Detail Pesanan sesuai acuan visual.
- Menampilkan ringkasan “bayar di konter” tanpa biaya tambahan yang tidak dijelaskan.
- Membuat nomor pesanan dummy.
- Menampilkan lifecycle sebagai timeline vertikal:

```text
Menunggu Konfirmasi → Diproses → Siap Diambil → Selesai
                         └──── alternatif: Ditolak
```

### Branch yang digunakan

```text
feat/single-stall-cart
feat/order-confirmation
feat/order-status
test/order-total
```

### Kriteria selesai

- Total pesanan benar untuk perubahan jumlah item.
- Jika tidak ada biaya lain, nilai subtotal dan total harus sama.
- Aplikasi menolak penambahan menu dari stan lain atau meminta pengguna mengosongkan keranjang.
- Menu yang habis tidak dapat dikonfirmasi.
- Sticky cart bar, quantity stepper, tombol aksi, dan status timeline mengikuti design system.
- Screenshot Keranjang dan Status Pesanan dibandingkan dengan mockup mahasiswa.
- Tag `v0.5.0-alpha.1` dibuat dari `main`.

---

## `v0.6.0-alpha.1` — Panel Pengelola Stan

**Jenis versi:** MINOR prarilis alpha  
**Estimasi:** Hari 9  
**Requirement:** FR-09

### Fitur

- Dashboard “Kantin Kampus Praktis” berisi status buka/tutup, ringkasan antrean, dan daftar “Perlu tindakan”.
- Navigasi pengelola: Dashboard—Pesanan—Menu—Profil.
- Tampilan Pesanan Masuk dengan filter Baru, Diproses, dan Siap.
- Detail Pesanan menampilkan item, catatan, total, label bayar di konter, serta aksi Terima/Tolak.
- Memperbarui status buka/tutup.
- Halaman Kelola Menu untuk memperbarui ketersediaan dan estimasi penyajian.
- Menerima atau menolak pesanan beserta alasan.
- Mengubah status pesanan menjadi Diproses, Siap Diambil, atau Selesai.
- Pembatasan tampilan berdasarkan peran pengguna.
- Tidak menampilkan grafik pendapatan, promo, multi-stan, atau fitur delivery.

### Branch yang digunakan

```text
feat/vendor-dashboard
feat/menu-availability
feat/vendor-order-status
```

### Kriteria selesai

- Pengelola hanya melihat dan mengubah data stannya.
- Perubahan status dummy langsung terlihat pada halaman pelanggan.
- Transisi status yang tidak valid ditolak.
- Dashboard, Pesanan Masuk, Detail Pesanan, dan Kelola Menu konsisten dengan design system dan mockup pengelola.
- Screenshot setiap layar utama pengelola dilampirkan pada pull request terkait.
- Tag `v0.6.0-alpha.1` dibuat dari `main`.

---

## `v0.7.0-beta.1` — Notification API dan Checkpoint UI Dua Minggu

**Jenis versi:** MINOR prarilis beta  
**Estimasi:** Hari 10  
**Requirement:** FR-10 dan pemetaan komponen Android

### Fitur

- Membuat `NotificationChannel`.
- Meminta `POST_NOTIFICATIONS` hanya pada Android 13 atau lebih baru.
- Menampilkan notifikasi lokal saat status simulasi menjadi Siap Diambil atau Ditolak.
- Menggunakan `Intent/PendingIntent` agar ketukan notifikasi membuka detail pesanan.
- Menampilkan status tetap di dalam aplikasi jika izin notifikasi ditolak.
- Menyiapkan abstraction notifikasi agar local notification dapat diganti FCM.
- Melakukan visual QA seluruh layar terhadap mockup terpilih dan [`DESIGN_SYSTEM.md`](../design/DESIGN_SYSTEM.md).
- Memeriksa lebar 360/390/412 dp, text scale, keyboard, SafeArea, kontras, dan target sentuh.
- Menghapus warna/style hard-coded, placeholder, serta komponen visual yang tidak sesuai sistem.

### Branch yang digunakan

```text
feat/android-notification
feat/notification-permission
feat/order-deep-link
test/notification-fallback
```

### Kriteria checkpoint dua minggu

- UI mahasiswa dan pengelola dapat didemonstrasikan dari awal sampai akhir.
- Semua data masih boleh dummy, tetapi tidak ditulis langsung di widget.
- Asisten AI memiliki alur lengkap walaupun respons masih disimulasikan.
- Notifikasi Android dapat didemonstrasikan pada perangkat/emulator.
- Tidak ada halaman yang hanya menampilkan loading tanpa batas.
- Semua layar mahasiswa dan pengelola menggunakan token “Kantin Kampus Praktis” dan Material Symbols Rounded secara konsisten.
- Visual QA tidak memiliki temuan blocker/major; bukti screenshot tersedia untuk alur utama.
- Tidak ada overflow pada lebar target dan harga/total tetap terbaca saat text scale diperbesar.
- Tag `v0.7.0-beta.1` menjadi versi demo UI sebelum UTS.

---

## `v0.8.0-beta.1` — Integrasi Backend dan Penggantian Data Source

**Jenis versi:** MINOR prarilis beta  
**Estimasi:** Minggu 3  
**Tujuan:** mengganti data dummy tanpa refactor besar

### Fitur

- `ApiClient` dengan base URL dari `.env`.
- DTO dan mapper terpisah dari model domain.
- `RemoteRepository` untuk akun, stan, menu, dan pesanan.
- Login/autentikasi sesuai kontrak backend.
- Penyimpanan token melalui secure storage/Android Keystore.
- Timeout, retry terbatas, dan pemetaan error.
- Pemilihan `FakeRepository` atau `RemoteRepository` melalui konfigurasi.
- Integration test menggunakan mock server atau staging.

### Contoh konfigurasi

```text
DATA_SOURCE=fake
API_BASE_URL=https://staging.example.invalid
```

> Nilai secret tidak boleh disimpan dalam repository. `.env.example` hanya berisi nama variabel dan contoh yang tidak sensitif.

### Branch yang digunakan

```text
feat/api-client
feat/remote-repository
feat/auth-session
chore/environment-config
test/backend-integration
```

### Kriteria selesai

- Mengubah `DATA_SOURCE` mengganti fake dan remote implementation tanpa mengubah widget.
- Token tidak terlihat di log.
- Error 401, 403, 404, 409, 422, dan 500 memiliki respons UI yang jelas.
- Tag `v0.8.0-beta.1` dibuat dari `main`.

---

## `v0.9.0-beta.1` — AI Nyata, FCM, dan Alur End-to-End

**Jenis versi:** MINOR prarilis beta  
**Estimasi:** Minggu 4

### Fitur

- Endpoint backend untuk Asisten Pilih Menu.
- API key AI hanya berada di backend.
- Backend mengirim menu/kriteria minimum ke layanan AI.
- Respons AI berupa data terstruktur dan merujuk ID menu.
- Backend memvalidasi harga, stok, stan, dan ID menu sebelum hasil dikirim ke aplikasi.
- Firebase Cloud Messaging untuk perubahan status pesanan.
- `FirebaseMessagingService` menerima pesan saat aplikasi di latar belakang.
- Notifikasi membuka detail pesanan yang sesuai.
- Pengujian end-to-end dari rekomendasi sampai pesanan selesai.

### Branch yang digunakan

```text
feat/ai-backend-integration
feat/ai-response-validation
feat/fcm-order-status
test/order-end-to-end
```

### Kriteria selesai

- AI tidak dapat menampilkan menu yang tidak ada atau sudah habis.
- Pesanan yang diubah pengelola memperbarui halaman pelanggan.
- Status Siap Diambil dan Ditolak menghasilkan push notification.
- Gangguan AI tetap mengaktifkan pencarian/filter manual.
- Tag `v0.9.0-beta.1` dibuat dari `main`.

---

## `v1.0.0-rc.1` — Feature Freeze dan Quality Assurance

**Jenis versi:** kandidat MAJOR pertama  
**Estimasi:** Awal Minggu 5

### Aturan fase RC

- Tidak menerima fitur baru.
- Hanya bug blocker, critical, atau high yang boleh diperbaiki.
- Setiap perbaikan harus memiliki test reproduksi.
- Jika masih ada masalah, gunakan `v1.0.0-rc.2`, bukan langsung mengubah ke `v1.0.1`.

### Pemeriksaan wajib

- Seluruh FR-01 sampai FR-10 dapat didemonstrasikan.
- Seluruh NFR memiliki bukti uji atau inspeksi.
- `dart format`, `flutter analyze`, unit test, widget test, dan integration test berhasil.
- Tidak ada API key atau secret di APK/repository.
- Area sentuh utama minimal 48 dp.
- Permission hanya diminta ketika dibutuhkan.
- Tidak ada crash pada alur utama dan kondisi jaringan gagal.
- APK release dapat dipasang pada perangkat Android 10+.
- [Mini-SRS](MINI_SRS.md), README, CHANGELOG, dan roadmap sesuai implementasi.

---

## `v1.0.0` — Rilis Baseline KantinCerdas

**Jenis versi:** MAJOR stable  
**Estimasi:** Akhir Minggu 5

### Artefak rilis

- APK/AAB versi final.
- Source code pada tag `v1.0.0`.
- `CHANGELOG.md`.
- [Mini-SRS](MINI_SRS.md) final.
- Panduan menjalankan aplikasi.
- `.env.example`.
- Akun atau data demo yang aman.
- Skenario presentasi dari awal sampai akhir.

### Kriteria rilis

- Semua pemeriksaan RC berhasil.
- Tidak ada bug blocker atau critical yang terbuka.
- Tag dibuat dari commit yang sama dengan APK/AAB final.
- Release notes menjelaskan fitur, batas produk, cara instalasi, dan masalah yang diketahui.

---

## 6. Jadwal Ringkas

| Waktu | Versi yang dituju | Fokus |
|---|---|---|
| Hari 1 | `v0.1.0-alpha.1` | Repository, Git workflow, CI, struktur proyek, dan memasukkan acuan desain |
| Hari 2–3 | `v0.2.0-alpha.1` | Implementasi “Kantin Kampus Praktis”, komponen bersama, navigasi, dan fake repository |
| Hari 4–5 | `v0.3.0-alpha.1` | Katalog, pencarian, dan filter |
| Hari 6–7 | `v0.4.0-alpha.1` | Asisten AI dengan dummy service |
| Hari 8 | `v0.5.0-alpha.1` | Keranjang dan pemesanan |
| Hari 9 | `v0.6.0-alpha.1` | Panel pengelola dan status |
| Hari 10 | `v0.7.0-beta.1` | Notifikasi lokal dan demo UI dua minggu |
| Minggu 3 | `v0.8.0-beta.1` | Backend, autentikasi, remote repository, dan `.env` |
| Minggu 4 | `v0.9.0-beta.1` | AI nyata, FCM, dan alur end-to-end |
| Minggu 5 awal | `v1.0.0-rc.1` | Feature freeze, test, keamanan, dan perbaikan |
| Minggu 5 akhir | `v1.0.0` | Build, dokumentasi, presentasi, dan rilis final |

Jika jadwal perkuliahan lebih pendek, prioritasnya adalah mempertahankan checkpoint `v0.7.0-beta.1` untuk demo UI dan menurunkan risiko integrasi dengan tetap memakai repository abstraction.

---

## 7. Alur Version Control untuk Setiap Fitur

### 7.1 Siklus Kerja

1. Buat issue berisi tujuan dan acceptance criteria.
2. Ambil issue dan buat branch dari `main` terbaru.
3. Kerjakan satu perubahan yang fokus.
4. Commit kecil menggunakan Conventional Commits.
5. Push branch dan buat pull request.
6. Jalankan CI dan minta review anggota lain.
7. Perbaiki temuan tanpa menghapus riwayat kerja penting.
8. Gunakan squash merge agar riwayat `main` tetap bersih.
9. Hapus branch setelah merge.
10. Setelah seluruh fitur milestone masuk, ubah versi, perbarui changelog, lalu buat tag.

### 7.2 Contoh Perintah

```bash
git switch main
git pull --ff-only
git switch -c feat/menu-filter

# Setelah melakukan perubahan
git add lib test
git commit -m "feat(catalog): add price and spice filters"
git push -u origin feat/menu-filter

# Buat pull request dan merge setelah review/CI berhasil.
```

Setelah milestone selesai:

```bash
git switch main
git pull --ff-only
git tag -a v0.3.0-alpha.1 -m "Catalog, search, and filter milestone"
git push origin v0.3.0-alpha.1
```

### 7.3 Aturan Branch

| Prefix | Penggunaan | Contoh |
|---|---|---|
| `feat/` | Fitur baru | `feat/floating-menu-assistant` |
| `fix/` | Perbaikan bug | `fix/order-total-rounding` |
| `refactor/` | Perbaikan struktur tanpa fitur baru | `refactor/catalog-repository` |
| `test/` | Menambah atau memperbaiki test | `test/order-status-transition` |
| `docs/` | Dokumentasi | `docs/update-mini-srs` |
| `chore/` | Tooling, CI, dependency, konfigurasi | `chore/flutter-ci` |
| `release/` | Persiapan RC/stable jika diperlukan | `release/1.0.0` |

Aturan utama:

- jangan mengerjakan dua fitur yang tidak berkaitan dalam satu branch;
- branch harus dibuat dari `main` terbaru;
- branch idealnya selesai dalam satu sampai tiga hari;
- jangan commit `.env`, API key, token, password, atau file build;
- jangan push langsung ke `main` kecuali tim hanya satu orang dan tetap ingin membuat PR untuk latihan.

### 7.4 Conventional Commits

```text
feat(ai): add clarification state
fix(order): prevent mixed-stall cart
refactor(data): separate DTO from domain model
test(catalog): cover empty filter result
docs(srs): align notification requirement
chore(ci): run analyze and tests on pull request
```

Perubahan yang tidak kompatibel:

```text
feat(api)!: replace order status response contract

BREAKING CHANGE: status field is replaced by statusCode and statusLabel.
```

---

## 8. Pull Request dan Code Review

### Template ringkas pull request

```markdown
## Tujuan
Menjelaskan masalah yang diselesaikan.

## Perubahan
- Perubahan utama pertama
- Perubahan utama kedua

## Requirement terkait
FR-xx / NFR-xx

## Cara menguji
1. Langkah pengujian
2. Hasil yang diharapkan

## Bukti
Screenshot/video/log test yang relevan.

## Acuan visual
- Layar/komponen pada [`DESIGN_SYSTEM.md`](../design/DESIGN_SYSTEM.md)
- Jelaskan penyimpangan jika implementasi sengaja berbeda

## Checklist
- [ ] Format, analyze, dan test berhasil
- [ ] Tidak ada secret
- [ ] State loading/error/empty ditangani
- [ ] UI mengikuti token dan komponen “Kantin Kampus Praktis”
- [ ] Screenshot pada lebar 390 dp dilampirkan untuk perubahan visual
- [ ] Dokumentasi diperbarui bila perlu
```

### Checklist reviewer

- Perubahan sesuai issue dan [Mini-SRS](MINI_SRS.md).
- Nama variabel/kelas mudah dipahami.
- Widget tidak langsung mengakses API atau dummy JSON.
- Error dan kondisi kosong ditangani.
- Tidak ada duplikasi besar.
- Tidak ada secret atau data sensitif di log.
- Test mencakup risiko utama.
- UI memakai token design system, bukan warna/spacing/radius baru yang tersebar di widget.
- UI sesuai struktur mockup; penyimpangan visual memiliki alasan yang dicatat.
- UI tetap dapat digunakan pada lebar 360/390/412 dp dan ketika text scale diperbesar.
- Foto tidak terdistorsi, teks tidak terpotong, dan target sentuh minimal 48 × 48 dp.

---

## 9. Quality Gate Sebelum Merge

Minimal jalankan:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Untuk rilis beta/RC:

```bash
flutter test integration_test
flutter build apk --release
```

Pull request tidak boleh digabungkan jika:

- build gagal;
- analyzer memiliki error;
- test utama gagal;
- acceptance criteria belum terpenuhi;
- terdapat API key atau token dalam perubahan;
- perubahan visual menyimpang dari design system tanpa penjelasan atau pembaruan dokumen;
- screenshot menunjukkan overflow, teks terpotong, kontras buruk, atau target sentuh terlalu kecil;
- perubahan menambah fitur di luar scope tanpa pembaruan roadmap dan [Mini-SRS](MINI_SRS.md).

---

## 10. Definition of Done

Sebuah fitur dinyatakan selesai jika:

- issue dan acceptance criteria tersedia;
- kode sudah diformat dan lolos analyzer;
- unit/widget test yang relevan tersedia dan berhasil;
- loading, error, empty, dan success state ditangani;
- komponen visual memakai token dan shared component dari [`DESIGN_SYSTEM.md`](../design/DESIGN_SYSTEM.md);
- perubahan visual telah diperiksa pada lebar 360/390/412 dp dan text scale yang lebih besar;
- screenshot pembanding terhadap mockup dilampirkan bila perubahan memengaruhi UI;
- tidak ada secret atau data sensitif dalam source/log;
- fitur sesuai FR/NFR terkait;
- pull request sudah direview;
- dokumentasi diperbarui;
- branch sudah masuk ke `main`;
- milestone tag dibuat hanya jika semua fitur dalam versi tersebut selesai.

“UI sudah terlihat” belum berarti fitur selesai apabila state gagal, test, atau integrasi repository belum disiapkan.

---

## 11. Strategi Bugfix dan Hotfix

### Saat alpha/beta

Jika `v0.7.0-beta.1` memiliki bug notifikasi, perbaiki pada branch:

```text
fix/notification-permission-denied
```

Setelah merge dan diuji, tag:

```text
v0.7.0-beta.2
```

### Setelah `v1.0.0`

Contoh bug total harga:

```text
v1.0.0 → v1.0.1
```

Contoh dua perbaikan tambahan:

```text
v1.0.1 → v1.0.2
```

Patch tidak boleh diam-diam menambah fitur baru.

---

## 12. Risiko dan Mitigasi

| Risiko | Dampak | Mitigasi roadmap |
|---|---|---|
| Backend belum siap | UI terhambat | Repository interface dan fake implementation sejak `v0.2.0` |
| AI mengarang menu/harga | Rekomendasi salah | Respons terstruktur, referensi `menuId`, dan validasi backend pada `v0.9.0` |
| API key bocor | Penyalahgunaan layanan | AI hanya dipanggil backend; secret tidak masuk aplikasi/Git |
| Izin notifikasi ditolak | Pengguna tidak melihat push | Status tetap tersedia di aplikasi dan izin bersifat opsional |
| Konflik Git | Waktu terbuang | Branch kecil, pull request cepat, dan update dari `main` secara rutin |
| Desain berubah antaranggota | UI tidak konsisten dan sulit dipelihara | [`DESIGN_SYSTEM.md`](../design/DESIGN_SYSTEM.md) menjadi sumber kebenaran; token dan shared component diterapkan sejak `v0.2.0` |
| Mockup bagus tetapi tidak responsif | Overflow pada perangkat nyata | Uji 360/390/412 dp, text scale, SafeArea, keyboard, dan target sentuh pada setiap milestone UI |
| Scope bertambah | Target tidak selesai | Fitur di luar baseline masuk backlog dan memerlukan perubahan SRS |
| Demo tergantung internet | Presentasi gagal | Fake data dan local notification tetap tersedia untuk mode demo |
| Bug muncul menjelang rilis | Rilis tidak stabil | Feature freeze pada `v1.0.0-rc.1` |

---

## 13. Backlog Setelah `v1.0.0`

Fitur berikut bukan bagian dari baseline dan hanya dikerjakan jika versi utama sudah stabil:

| Calon versi | Jenis | Fitur | Catatan |
|---|---|---|---|
| `v1.0.1` | PATCH | Perbaikan bug produksi pertama | Tidak boleh menambah fitur |
| `v1.1.0` | MINOR | Pemesanan dengan slot waktu pengambilan | Memerlukan pembaruan SRS dan aturan kuota/no-show |
| `v1.2.0` | MINOR | Riwayat dan favorit menu | Masih kompatibel dengan baseline |
| `v1.3.0` | MINOR | Analitik sederhana untuk pengelola | Perlu aturan privasi dan akses |
| `v2.0.0` | MAJOR | Banyak kampus atau marketplace UMKM umum | Mengubah scope, aktor, data, backend, dan model bisnis |

Pengantaran dan pembayaran digital tidak disarankan sebelum kebutuhan hukum, keamanan, rekonsiliasi, refund, dan operasionalnya didefinisikan dalam SRS baru.

---

## 14. Format Catatan Rilis

Gunakan `CHANGELOG.md` dengan pola:

```markdown
## [0.7.0-beta.1] - YYYY-MM-DD

### Added
- Android notification channel.
- Runtime permission untuk Android 13+.
- Deep link ke detail pesanan.

### Changed
- Abstraksi notifikasi disiapkan untuk FCM.

### Fixed
- Status tetap terlihat ketika izin notifikasi ditolak.

### Known Issues
- Status masih berasal dari dummy repository.
```

---

## 15. Urutan Implementasi yang Tidak Boleh Dibalik

```text
Kunci acuan visual “Kantin Kampus Praktis” dan Full Mockup UI/UX v2
        ↓
Fondasi Git, dokumentasi desain, dan arsitektur data
        ↓
Implementasi theme, token, komponen bersama, dan app shell
        ↓
Katalog serta filter manual
        ↓
Asisten AI dan fallback
        ↓
Keranjang serta pesanan
        ↓
Panel pengelola
        ↓
Notifikasi Android
        ↓
Integrasi backend
        ↓
AI + FCM end-to-end
        ↓
RC, pengujian, dan rilis v1.0.0
```

Alasan utama urutan ini adalah agar setiap layar dibangun dari bahasa visual dan komponen yang sama, lalu AI, backend, dan notifikasi tidak ditambahkan di atas UI serta model data yang belum stabil. Dengan urutan tersebut, versi `v0.7.0-beta.1` sudah konsisten dengan mockup dan dapat digunakan untuk presentasi UI, sedangkan integrasi nyata dapat ditambahkan tanpa menulis ulang seluruh aplikasi.
