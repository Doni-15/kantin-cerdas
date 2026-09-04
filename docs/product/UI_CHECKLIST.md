# Checklist Pengerjaan UI KantinCerdas

**Dokumen:** Checklist implementasi dan version control fase UI  
**Versi dokumen:** 2.0  
**Pembaruan:** 4 September 2026  
**Cakupan:** `v0.1.0-alpha.1` sampai `v0.7.0-beta.1`, termasuk maintenance
`v0.1.0-alpha.2`
**Platform:** Android dengan Flutter  
**Mode data:** Dummy/fake repository  
**Baseline visual:** “Kantin Kampus Praktis”  
**Sumber kebenaran visual:** [`DESIGN_SYSTEM.md`](../design/DESIGN_SYSTEM.md)  
**Kelanjutan backend:** To Be Continued (TBC)

---

## 1. Cara Menggunakan Checklist

Dokumen ini dibuat agar bisa ditempatkan di repository GitHub sebagai `UI_CHECKLIST.md`. Setiap kode seperti `UI-301` dapat dijadikan satu GitHub Issue.

Arti status pada tabel ringkasan:

- ⬜ **Belum mulai**
- 🟨 **Sedang dikerjakan**
- 🟩 **Selesai**
- 🟥 **Terhambat**

Aturan pencatatan:

- Centang tugas hanya setelah perubahan sudah diuji dan masuk ke `main`.
- Satu issue idealnya dikerjakan dalam satu branch yang fokus.
- Jangan mencentang satu versi sebagai selesai jika release gate-nya belum terpenuhi.
- Isi nama penanggung jawab dan nomor pull request pada kolom/catatan issue di GitHub.
- Data dummy tidak boleh ditulis langsung di widget; widget harus mengambil data melalui interface/service/repository.
- Semua warna, typography, spacing, radius, ikon, dan pola komponen harus mengikuti [`DESIGN_SYSTEM.md`](../design/DESIGN_SYSTEM.md).
- Untuk perubahan visual, lampirkan screenshot implementasi pada lebar 390 dp dan satu lebar pembanding 360 atau 412 dp.
- Cocokkan tujuan, hierarki, state, dan perilaku dengan mockup v2; kesamaan piksel bukan pengganti usability dan aksesibilitas.
- API key, token, password, dan `.env` asli tidak boleh masuk ke Git.

Urutan sumber keputusan:

1. [Mini-SRS](MINI_SRS.md) mengunci kebutuhan dan batas fitur.
2. [`DESIGN_SYSTEM.md`](../design/DESIGN_SYSTEM.md) v2 mengunci bahasa visual, komponen, dan perilaku interaksi.
3. Paket **Full Mockup UI/UX v2** menjadi acuan layar dan state untuk review visual.
4. Dokumen ini melacak pekerjaan, bukti pengujian, dan release gate.

Jika keempatnya bertentangan, jangan menebak saat implementasi. Catat keputusan tim lalu perbarui dokumen sumber yang tepat dalam pull request yang sama.

Perbedaan nomor versi:

```text
pubspec.yaml : 0.3.0-alpha.1+4
Git tag      : v0.3.0-alpha.1
```

Nomor setelah `+` adalah build number Android dan harus terus meningkat untuk setiap build yang dibagikan.

---

## 2. Batas Fase UI

Fase ini hanya mengerjakan:

- UI mahasiswa dan pengelola stan;
- navigasi dan state management;
- model domain dan kontrak repository/service;
- fake repository dan dummy data;
- simulasi Asisten Pilih Menu;
- simulasi lifecycle pesanan;
- notifikasi lokal Android untuk status pesanan;
- unit test, widget test, dan demo end-to-end dengan data lokal.

Fase ini belum mengerjakan:

- server/backend dan database daring;
- autentikasi nyata;
- pemanggilan model AI dari internet;
- Firebase Cloud Messaging;
- sinkronisasi real-time antarperangkat;
- payment gateway, GPS, peta, dan pengantaran.

> **Stop point fase UI:** pekerjaan UI dianggap selesai pada `v0.7.0-beta.1`. Integrasi backend dimulai hanya setelah kontrak API dan backend tersedia.

### 2.1 Baseline UI yang Sudah Dikunci

Keputusan desain berikut sudah final untuk fase UI dan tidak perlu didesain ulang ketika coding dimulai:

| Bagian | Baseline |
|---|---|
| Arah visual | “Kantin Kampus Praktis”: praktis, hangat, dekat, tenang, dan mudah dipindai |
| Warna merek | `#E85D2A` |
| Warna aksi/tombol | `#C74418` |
| Terracotta | `#9B341B` |
| Aksen emas | `#F4B740` untuk perhatian non-kritis |
| Latar utama | `#FAFAF8` |
| Surface | `#FFFFFF` |
| Surface hangat | `#F7F3F0`, hanya bila section perlu dipisahkan |
| Outline | `#DDD6D1` |
| Teks utama | `#251B17` |
| Font | Plus Jakarta Sans; fallback Inter/sans-serif sistem |
| Spacing | Grid 8 dp; padding halaman 16 dp |
| Radius | 8, 12, 16, 24, dan pill |
| Ikon | Material Symbols Rounded |
| Target sentuh | Minimal 48 × 48 dp |
| Daftar | Grouped list dan divider; kartu hanya untuk objek mandiri |
| Asisten | Tombol mengambang 56 × 56 dp, coachmark satu kali, lalu modal bottom sheet |

Layar acuan mahasiswa: **Beranda, Hasil Pencarian, Detail Stan, Detail Menu, Asisten Pilih Menu, Hasil Rekomendasi, Keranjang, Konfirmasi, Pesanan Berhasil, Status Pesanan, dan Profil/Preferensi**.  
Layar acuan pengelola: **Dashboard, Pesanan Masuk, Detail Pesanan, Kelola Menu, Pengaturan Stan, dan Profil**.

State acuan wajib: **loading, hasil kosong, offline dengan data tersimpan, error dan retry, stan tutup, menu habis, first visit, returning visit, keyboard terbuka, sticky cart aktif, dan reduced motion**.

### 2.2 Aturan Interaksi yang Tidak Boleh Berubah Diam-diam

- Oranye menandai merek, aksi utama, dan state aktif; jangan menjadikannya wash pada seluruh layar.
- Hindari gradien, glow, ilustrasi robot besar, kartu bertumpuk, pill berlebihan, dan slogan dekoratif yang membuat UI terasa seperti template AI.
- Asisten hanya tampil pada Beranda dan Detail Stan. Asisten disembunyikan pada hasil pencarian, detail menu, keranjang, konfirmasi, pesanan berhasil, status pesanan, profil, dan seluruh area pengelola.
- Coachmark asisten tampil satu kali setelah konten utama stabil, dapat ditutup, dan status sudah dilihat disimpan secara lokal.
- Pengingat kontekstual hanya boleh muncul saat ada kebutuhan nyata dan maksimal satu kali per sesi.
- Asisten dibuka sebagai modal bottom sheet, bukan halaman chat kosong atau maskot yang mendominasi aplikasi.
- Floating assistant harus bergeser di atas sticky cart dan tidak boleh menutup harga, tombol `Tambah`, bottom navigation, atau keyboard.
- Keranjang hanya memuat menu dari satu stan dan pembayaran baseline tetap **bayar di konter**.
- Warna bukan satu-satunya penanda status; sertakan label dan ikon yang bermakna.

### 2.3 Matriks Acuan Full Mockup UI/UX v2

| ID acuan | Layar/state | Milestone utama |
|---|---|---|
| `MHS-01` | Beranda | `v0.3.0-alpha.1` |
| `MHS-02` | Hasil Pencarian | `v0.3.0-alpha.1` |
| `MHS-03` | Detail Stan | `v0.3.0-alpha.1` |
| `MHS-04` | Detail Menu | `v0.3.0-alpha.1` |
| `MHS-05` | Asisten Pilih Menu / bottom sheet kebutuhan | `v0.4.0-alpha.1` |
| `MHS-06` | Hasil Rekomendasi | `v0.4.0-alpha.1` |
| `MHS-07` | Keranjang | `v0.5.0-alpha.1` |
| `MHS-08` | Konfirmasi Pesanan | `v0.5.0-alpha.1` |
| `MHS-09` | Pesanan Berhasil | `v0.5.0-alpha.1` |
| `MHS-10` | Status Pesanan | `v0.5.0-alpha.1` |
| `MHS-11` | Profil dan Preferensi Makanan | shell `v0.2`, preferensi `v0.4` |
| `PGL-01` | Dashboard Pengelola | `v0.6.0-alpha.1` |
| `PGL-02` | Pesanan Masuk | `v0.6.0-alpha.1` |
| `PGL-03` | Detail Pesanan | `v0.6.0-alpha.1` |
| `PGL-04` | Kelola Menu | `v0.6.0-alpha.1` |
| `PGL-05` | Pengaturan Stan | `v0.6.0-alpha.1` |
| `PGL-06` | Profil Pengelola | `v0.6.0-alpha.1` |
| `STATE-01` | Loading Beranda dan Hasil Pencarian Kosong | `v0.2`–`v0.3` |
| `STATE-02` | Offline dengan data tersimpan dan Error Memuat Pesanan | `v0.2`–`v0.6` |
| `STATE-03` | Stan Tutup dan Menu Habis | `v0.3.0-alpha.1` |
| `STATE-04` | Floating assistant, coachmark, bottom sheet, dan reduced motion | `v0.4.0-alpha.1` |

> Keputusan desain sudah terkunci, tetapi checklist implementasi tetap kosong sampai perubahan benar-benar dibuat, diuji, dan di-merge ke `main`.

---

## 3. Ringkasan Pelacakan Versi

| Versi | Target hasil | Waktu | Status | Tag |
|---|---|---:|---|---|
| `v0.1.0-alpha.1` | Fondasi Flutter, Git, quality gate, dan acuan desain | Hari 1 | 🟨 | 🟩 |
| `v0.1.0-alpha.2` | Perapian fondasi kolaborasi dan dokumentasi rilis | Maintenance | 🟩 | 🟩 |
| `v0.2.0-alpha.1` | Implementasi “Kantin Kampus Praktis”, app shell, dan fake data | Hari 2–3 | ⬜ | ⬜ |
| `v0.3.0-alpha.1` | Katalog, pencarian, dan filter | Hari 4–5 | ⬜ | ⬜ |
| `v0.4.0-alpha.1` | UI Asisten Pilih Menu | Hari 6–7 | ⬜ | ⬜ |
| `v0.5.0-alpha.1` | Keranjang dan pemesanan dummy | Hari 8 | ⬜ | ⬜ |
| `v0.6.0-alpha.1` | Panel pengelola stan | Hari 9 | ⬜ | ⬜ |
| `v0.7.0-beta.1` | Notifikasi Android dan demo UI lengkap | Hari 10 | ⬜ | ⬜ |

---

## 4. Checklist per Versi

### `v0.1.0-alpha.1` — Fondasi Proyek dan Version Control

**Target:** proyek dapat di-clone, dijalankan, diuji, dan dikembangkan dengan alur Git yang konsisten.  
**Versi `pubspec.yaml`:** `0.1.0-alpha.1+1`

#### A. Repository dan proyek

- [x] **UI-101** — Membuat repository GitHub KantinCerdas.
- [x] **UI-102** — Membuat proyek Flutter dengan application ID yang disepakati.
- [ ] **UI-103** — Memastikan proyek dapat dijalankan pada emulator/perangkat Android.
- [x] **UI-104** — Menambahkan `.gitignore` untuk Flutter, Android, IDE, build, dan `.env`.
- [x] **UI-105** — Menambahkan `.env.example` tanpa nilai rahasia.
- [x] **UI-106** — Menambahkan `README.md` berisi cara clone, setup, run, test, dan build.
- [x] **UI-107** — Menambahkan [Mini-SRS](MINI_SRS.md), roadmap, checklist UI, dan [`DESIGN_SYSTEM.md`](../design/DESIGN_SYSTEM.md) ke repository.

#### B. Struktur dan kualitas awal

- [x] **UI-108** — Menyiapkan struktur `lib/app`, `lib/core`, `lib/features`, dan `lib/shared`.
- [x] **UI-109** — Mengaktifkan aturan lint yang disepakati tim.
- [x] **UI-110** — Membuat minimal satu smoke test bawaan proyek.
- [x] **UI-111** — Menyiapkan CI untuk menjalankan format check, analyze, dan test pada pull request.
- [x] **UI-112** — Menambahkan template pull request.
- [x] **UI-113** — Membuat label GitHub: `feature`, `bug`, `ui`, `test`, `docs`, `blocked`, dan `release`.
- [x] **UI-114** — Membuat milestone GitHub untuk `v0.1` sampai `v0.7`.

#### C. Latihan Git

- [x] **UI-115** — Menetapkan `main` sebagai branch utama.
- [x] **UI-116** — Menulis aturan nama branch dan Conventional Commits di `CONTRIBUTING.md` atau `README.md`.
- [x] **UI-117** — Menggunakan minimal satu branch kerja berumur pendek dari `main`.
- [x] **UI-118** — Membuat Pull Request, memeriksa diff, menunggu CI, lalu melakukan squash merge.
- [x] **UI-119** — Menghapus branch kerja yang sudah di-merge.
- [x] **UI-120** — Menambahkan mockup awal mahasiswa dan pengelola ke dokumentasi proyek.
- [ ] **UI-121** — Menyimpan paket Full Mockup UI/UX v2 pada lokasi tim yang stabil dan menautkannya dari dokumentasi repository.

#### Release gate `v0.1.0-alpha.1`

- [ ] Anggota lain dapat menjalankan proyek dari hasil clone tanpa file lokal pembuat proyek.
- [x] `dart format --set-exit-if-changed .` berhasil.
- [x] `flutter analyze` berhasil tanpa error.
- [x] `flutter test` berhasil.
- [x] Tidak ada secret atau `.env` asli dalam Git.
- [x] [`DESIGN_SYSTEM.md`](../design/DESIGN_SYSTEM.md) dan mockup terpilih dapat diakses seluruh anggota tim.
- [ ] README menyatakan bahwa “Kantin Kampus Praktis” dan Full Mockup UI/UX v2 adalah baseline yang tidak diubah tanpa keputusan tim.
- [ ] Semua issue milestone `v0.1` sudah ditutup.
- [x] `CHANGELOG.md` telah diperbarui.
- [x] Versi `pubspec.yaml` sudah `0.1.0-alpha.1+1`.
- [x] Tag `v0.1.0-alpha.1` dibuat dari commit terbaru di `main` dan di-push.

> `v0.1.0-alpha.2` hanya merapikan fondasi kolaborasi, struktur source, dan
> dokumentasi. Versi maintenance ini tidak menyelesaikan item UI produk dan
> tidak menjadi alasan untuk mencentang validasi emulator/perangkat.

---

### `v0.2.0-alpha.1` — App Shell, Design System, dan Fake Data

**Target:** semua halaman utama bisa dinavigasi dan memiliki fondasi UI/data yang siap diganti ke backend.  
**Versi `pubspec.yaml`:** `0.2.0-alpha.1+3`

#### A. Design system

- [ ] **UI-201** — Membuat token `KcColors`/`ColorScheme` dengan `#E85D2A`, `#C74418`, `#9B341B`, `#F4B740`, `#FAFAF8`, `#FFFFFF`, `#F7F3F0`, `#DDD6D1`, `#251B17`, serta warna status pada design system.
- [ ] **UI-202** — Membuat `TextTheme` Plus Jakarta Sans untuk Display, Heading, Title, Body, Label, dan Caption.
- [ ] **UI-203** — Membuat token spacing 4/8/12/16/24/32/40/48, radius 8/12/16/24/pill, serta elevation terbatas.
- [ ] **UI-204** — Membuat komponen primary, secondary, tertiary, dan destructive button dengan state pressed, focused, loading, dan disabled.
- [ ] **UI-205** — Membuat komponen search field, input, filter chip, dialog, modal bottom sheet, dan snackbar sesuai “Kantin Kampus Praktis”.
- [ ] **UI-206** — Membuat komponen loading/skeleton, empty, error/retry, offline, disabled, dan success yang konsisten.
- [ ] **UI-207** — Menguji kontras, text scaling, target sentuh minimal 48 × 48 dp, urutan fokus, dan reduced motion.

#### B. App shell dan navigasi

- [ ] **UI-208** — Membuat splash/initial screen sederhana.
- [ ] **UI-209** — Membuat UI masuk atau pemilihan peran khusus mode demo.
- [ ] **UI-210** — Membuat shell mahasiswa dengan navigasi Beranda—Pesanan—Profil.
- [ ] **UI-211** — Membuat shell pengelola dengan navigasi Dashboard—Pesanan—Menu—Profil.
- [ ] **UI-212** — Menentukan route name/path pada satu tempat.
- [ ] **UI-213** — Menangani halaman tidak ditemukan dan navigasi kembali.
- [ ] **UI-214** — Menjaga state halaman penting ketika berpindah tab serta mendefinisikan visibilitas floating assistant per route.

#### C. Domain dan sumber data dummy

- [ ] **UI-215** — Membuat model domain `User`, `Stall`, `MenuItem`, `Cart`, `Order`, dan `Recommendation`.
- [ ] **UI-216** — Membuat enum untuk peran, status stan, status menu, dan status pesanan.
- [ ] **UI-217** — Membuat interface repository/service yang dibutuhkan UI.
- [ ] **UI-218** — Membuat `FakeRepository` dengan data beberapa stan dan menu yang realistis.
- [ ] **UI-219** — Menyediakan skenario dummy: sukses, loading, kosong, gagal, offline dengan data tersimpan, stan tutup, dan menu habis.
- [ ] **UI-220** — Menyediakan satu konfigurasi untuk memilih fake/remote data source tanpa mengubah widget.
- [ ] **UI-221** — Memastikan widget tidak mengimpor file JSON dummy secara langsung.

#### D. Pengujian

- [ ] **UI-222** — Membuat test untuk parsing/model domain utama.
- [ ] **UI-223** — Membuat widget test navigasi mahasiswa.
- [ ] **UI-224** — Membuat widget test navigasi pengelola.
- [ ] **UI-225** — Menguji tampilan loading, empty, error, dan success.

#### E. Komponen visual bersama

- [ ] **UI-226** — Membuat shared menu row dengan foto 88 × 88 dp, nama, harga, stan, ketersediaan, estimasi, aksi `Tambah`, dan divider; jangan membungkus setiap baris dalam kartu.
- [ ] **UI-227** — Membuat primitive floating assistant: FAB 56 × 56 dp, coachmark, dan modal bottom sheet tanpa memasukkan logika rekomendasi ke widget.
- [ ] **UI-228** — Membuat status badge, order timeline, dan quantity stepper berdasarkan design system.
- [ ] **UI-229** — Menggunakan Material Symbols Rounded dan menghapus emoji sebagai ikon UI.
- [ ] **UI-230** — Membuat halaman/catalog internal untuk melihat seluruh komponen dan state visual.

#### Branch yang disarankan

- [ ] `feat/kantin-praktis-theme`
- [ ] `feat/shared-ui-components`
- [ ] `feat/app-navigation`
- [ ] `feat/domain-models`
- [ ] `chore/fake-repository`
- [ ] `test/app-shell`

#### Release gate `v0.2.0-alpha.1`

- [ ] Semua layar utama dapat dibuka walaupun isinya masih dummy.
- [ ] Mode mahasiswa dan pengelola dapat didemonstrasikan.
- [ ] Theme, komponen, dan navigation bar mengikuti [`DESIGN_SYSTEM.md`](../design/DESIGN_SYSTEM.md).
- [ ] Tidak ada warna, spacing, atau style utama yang berulang secara hard-coded.
- [ ] Surface utama tetap putih/netral hangat dan penggunaan oranye dibatasi pada merek, aksi utama, dan state aktif.
- [ ] Daftar menu/pesanan menggunakan grouped list serta divider; kartu tidak dipakai berulang tanpa kebutuhan struktur.
- [ ] Tidak ada gradien, glow, robot besar, kartu bertumpuk, atau pill dekoratif yang tidak punya fungsi.
- [ ] Tidak ada emoji yang digunakan sebagai ikon antarmuka.
- [ ] Semua tombol/input utama memiliki target sentuh minimal 48 × 48 dp.
- [ ] UI tidak overflow pada lebar 360, 390, dan 412 dp serta saat text scale diperbesar.
- [ ] Screenshot catalog komponen dan app shell pada lebar 390 dp tersedia.
- [ ] Fake data hanya diakses melalui abstraksi repository/service.
- [ ] Format, analyze, dan seluruh test berhasil.
- [ ] Semua pull request milestone sudah di-review dan di-merge.
- [ ] `CHANGELOG.md` telah diperbarui.
- [ ] Versi `pubspec.yaml` sudah `0.2.0-alpha.1+3`.
- [ ] Tag `v0.2.0-alpha.1` dibuat dan di-push.

---

### `v0.3.0-alpha.1` — Katalog, Pencarian, dan Filter

**Target:** mahasiswa bisa menemukan menu secara manual tanpa AI.  
**Requirement terkait:** FR-01, FR-02, dan fallback FR-06  
**Versi `pubspec.yaml`:** `0.3.0-alpha.1+4`

#### A. Daftar stan dan menu

- [ ] **UI-301** — Membuat Beranda “Kantin Kampus Praktis”: sapaan, search field, kategori, daftar “Cepat jadi”, daftar “Stan yang buka”, serta floating assistant yang tidak mendominasi konten.
- [ ] **UI-302** — Membuat daftar stan beserta nama, foto, status buka/tutup, dan estimasi tanpa jarak/rating/promo.
- [ ] **UI-303** — Membuat Detail Stan seperti acuan “Dapur Bu Rina”: status buka, estimasi, chip kategori, dan daftar menu.
- [ ] **UI-304** — Membuat daftar menu milik satu stan.
- [ ] **UI-305** — Menggunakan shared menu row berisi foto, nama, harga, stan, status tersedia, pedas, estimasi penyajian, dan aksi `Tambah` yang sejajar.
- [ ] **UI-306** — Membuat halaman Detail Menu dengan foto, harga, deskripsi, catatan untuk penjual, quantity stepper, serta CTA tambah ke keranjang.
- [ ] **UI-307** — Menonaktifkan aksi pemesanan saat stan tutup atau menu habis.

#### B. Pencarian dan filter

- [ ] **UI-308** — Membuat pencarian berdasarkan nama menu.
- [ ] **UI-309** — Membuat filter kategori makanan/minuman.
- [ ] **UI-310** — Membuat filter rentang harga.
- [ ] **UI-311** — Membuat filter tingkat kepedasan.
- [ ] **UI-312** — Menampilkan filter aktif sebagai chip.
- [ ] **UI-313** — Menambahkan aksi hapus satu filter dan reset semua filter.
- [ ] **UI-314** — Menampilkan jumlah hasil pencarian/filter.
- [ ] **UI-315** — Menampilkan empty state ketika tidak ada menu yang cocok.
- [ ] **UI-316** — Mempertahankan query dan filter saat pengguna membuka detail lalu kembali.

#### C. State dan pengujian

- [ ] **UI-317** — Menangani loading, error, retry, dan data kosong untuk daftar stan.
- [ ] **UI-318** — Menangani loading, error, retry, dan data kosong untuk daftar menu.
- [ ] **UI-319** — Membuat unit test pencarian nama menu.
- [ ] **UI-320** — Membuat unit test kombinasi kategori, harga, dan kepedasan.
- [ ] **UI-321** — Membuat widget test reset filter dan empty state.
- [ ] **UI-322** — Menguji scrolling dan overflow pada layar kecil.

#### D. Kesesuaian visual

- [ ] **UI-323** — Menggunakan foto makanan dengan rasio/crop konsisten serta fallback image.
- [ ] **UI-324** — Memastikan halaman tidak menampilkan delivery, jarak, rating, voucher, atau pembayaran digital.
- [ ] **UI-325** — Membandingkan screenshot Beranda, Hasil Pencarian, Detail Stan, dan Detail Menu pada 390 dp serta satu lebar pembanding dengan mockup v2.

#### Branch yang disarankan

- [ ] `feat/stall-catalog`
- [ ] `feat/menu-catalog`
- [ ] `feat/menu-search`
- [ ] `feat/menu-filter`
- [ ] `test/catalog-filter`

#### Release gate `v0.3.0-alpha.1`

- [ ] Pengguna dapat menemukan menu tanpa menggunakan AI.
- [ ] Search dan seluruh kombinasi filter menghasilkan data yang benar.
- [ ] Filter dapat dihapus tanpa menyisakan state lama.
- [ ] Menu habis/stan tutup tidak dapat ditambahkan ke keranjang.
- [ ] Beranda, Hasil Pencarian, Detail Stan, Detail Menu, dan menu row konsisten dengan “Kantin Kampus Praktis”.
- [ ] Floating assistant hanya tampil di Beranda dan Detail Stan, serta tidak menutup konten atau aksi katalog.
- [ ] Daftar tetap ringkas dengan divider dan tidak berubah menjadi tumpukan kartu generik.
- [ ] UI lulus pemeriksaan pada lebar 360/390/412 dp dan screenshot pembanding tersedia.
- [ ] Format, analyze, dan seluruh test berhasil.
- [ ] Semua pull request milestone sudah di-review dan di-merge.
- [ ] `CHANGELOG.md` telah diperbarui.
- [ ] Versi `pubspec.yaml` sudah `0.3.0-alpha.1+4`.
- [ ] Tag `v0.3.0-alpha.1` dibuat dan di-push.

---

### `v0.4.0-alpha.1` — UI Asisten Pilih Menu

**Target:** alur AI lengkap dapat didemonstrasikan dengan respons terkontrol dari fake service.  
**Requirement terkait:** FR-03 sampai FR-06  
**Versi `pubspec.yaml`:** `0.4.0-alpha.1+5`

#### A. Tombol mengambang dan coachmark

- [ ] **UI-401** — Membuat floating assistant 56 × 56 dp dengan semantic label “Buka asisten pilih menu”.
- [ ] **UI-402** — Menampilkan floating assistant hanya pada Beranda dan Detail Stan; route lain dan seluruh sisi pengelola harus menyembunyikannya.
- [ ] **UI-403** — Menunggu konten utama stabil sekitar 800 ms, lalu menjalankan animasi satu kali `1.00 → 1.06 → 1.00` selama sekitar 240 ms.
- [ ] **UI-404** — Membuat coachmark pertama dengan judul “Bingung pilih?”, isi “Aku bantu cari menu.”, area ketuk untuk membuka asisten, dan tombol tutup 48 dp.
- [ ] **UI-405** — Menyimpan `hasSeenAssistantCoachmark` secara lokal setelah coachmark ditutup atau asisten digunakan.
- [ ] **UI-406** — Membatasi pengingat kontekstual pada kebutuhan nyata, misalnya hasil pencarian kosong, maksimal satu kali per sesi.
- [ ] **UI-407** — Menonaktifkan animasi scale ketika reduced motion aktif tanpa menghilangkan akses ke tombol.
- [ ] **UI-408** — Menggeser tombol di atas sticky cart dan memastikan tombol tidak menutup harga, aksi `Tambah`, bottom navigation, atau keyboard.
- [ ] **UI-409** — Mengelola fokus saat coachmark dibuka/ditutup dan mengembalikannya ke pemicu yang logis.

#### B. Modal bottom sheet kebutuhan

- [ ] **UI-410** — Membuka modal bottom sheet berjudul “Bantu pilih menu”, bukan halaman percakapan kosong.
- [ ] **UI-411** — Menyediakan pilihan cepat untuk budget, waktu tunggu, dan selera seperti “Di bawah Rp20.000”, “Cepat jadi”, “Tidak pedas”, dan “Pakai nasi”.
- [ ] **UI-412** — Menyediakan field “Tulis pilihan lain…” dengan label yang tetap terbaca saat pengguna mengetik.
- [ ] **UI-413** — Menyediakan satu CTA utama “Cari rekomendasi”.
- [ ] **UI-414** — Menampilkan ringkasan kriteria yang dipilih sebagai chip yang dapat diubah atau dihapus.
- [ ] **UI-415** — Meminta klarifikasi jika input belum cukup jelas tanpa menghapus pilihan sebelumnya.
- [ ] **UI-416** — Menampilkan indikator proses, error manusiawi, dan aksi retry ketika rekomendasi sedang disiapkan atau gagal.
- [ ] **UI-417** — Menjaga bottom sheet dapat digulir, aman terhadap keyboard, dan tidak melebihi sekitar 85% tinggi layar.

#### C. Hasil rekomendasi

- [ ] **UI-418** — Menampilkan maksimal lima menu yang paling cocok dalam bottom sheet atau layar lanjutan yang jelas.
- [ ] **UI-419** — Menampilkan alasan singkat mengapa setiap menu direkomendasikan.
- [ ] **UI-420** — Menampilkan harga, tingkat pedas, estimasi, stan, dan ketersediaan dari repository.
- [ ] **UI-421** — Membuat aksi buka Detail Menu dari rekomendasi.
- [ ] **UI-422** — Membuat aksi tambah ke keranjang dari rekomendasi dengan aturan satu stan.
- [ ] **UI-423** — Menampilkan kondisi tidak ada menu yang cocok beserta aksi mengubah pilihan.
- [ ] **UI-424** — Menyediakan fallback ke pencarian/filter manual pada kondisi kosong, timeout, dan error.
- [ ] **UI-425** — Memastikan rekomendasi memakai shared menu row/token dan tidak memperkenalkan kartu visual baru tanpa alasan.

#### D. Fake AI service dan keamanan kontrak

- [ ] **UI-426** — Membuat interface `AiRecommendationService` yang tidak bergantung pada widget.
- [ ] **UI-427** — Membuat `FakeAiRecommendationService` dengan skenario prompt lengkap, ambigu, kosong, timeout, dan gagal.
- [ ] **UI-428** — Memastikan hasil fake AI hanya mengembalikan `menuId` yang tersedia pada katalog aktif.
- [ ] **UI-429** — Memvalidasi ulang nama, harga, stok, dan estimasi dari repository, bukan dari teks AI.
- [ ] **UI-430** — Memastikan tidak ada API key atau pemanggilan AI nyata di aplikasi.
- [ ] **UI-431** — Memastikan AI tidak dapat membuat pesanan otomatis atau melewati konfirmasi pengguna.

#### E. Pengujian dan bukti visual

- [ ] **UI-432** — Menguji kebutuhan “Rp20.000, tidak pedas, maksimal 10 menit”.
- [ ] **UI-433** — Menguji input ambigu menghasilkan klarifikasi dan pilihan pengguna tetap tersimpan.
- [ ] **UI-434** — Menguji `menuId` tidak valid tidak ditampilkan.
- [ ] **UI-435** — Menguji first visit, dismiss, returning visit, dan pengingat maksimal satu kali per sesi.
- [ ] **UI-436** — Menguji seluruh route yang harus menampilkan atau menyembunyikan floating assistant.
- [ ] **UI-437** — Menguji keyboard, sticky cart, text scale besar, lebar 360/390/412 dp, serta reduced motion tanpa overflow atau overlap.
- [ ] **UI-438** — Membandingkan screenshot state diam, coachmark, bottom sheet kebutuhan, dan hasil rekomendasi dengan mockup v2.

#### Branch yang disarankan

- [ ] `feat/floating-menu-assistant`
- [ ] `feat/assistant-coachmark`
- [ ] `feat/assistant-bottom-sheet`
- [ ] `feat/ai-criteria-summary`
- [ ] `feat/ai-clarification-state`
- [ ] `feat/ai-recommendation-card`
- [ ] `feat/ai-fallback`
- [ ] `test/assistant-behavior`

#### Release gate `v0.4.0-alpha.1`

- [ ] Prompt lengkap menghasilkan rekomendasi dummy yang sesuai.
- [ ] Prompt ambigu menghasilkan pertanyaan klarifikasi.
- [ ] Rekomendasi hanya memakai menu yang tersedia di fake repository.
- [ ] Error, timeout, retry, empty, dan success state dapat didemonstrasikan.
- [ ] Tidak ada secret atau API key AI di source code.
- [ ] Floating assistant hanya tampil pada Beranda dan Detail Stan, tidak menutup aksi lain, dan tersembunyi pada route yang dikunci.
- [ ] Coachmark hanya tampil satu kali, pengingat kontekstual maksimal satu kali per sesi, dan reduced motion dihormati.
- [ ] Asisten terbuka sebagai modal bottom sheet yang dimulai dari kebutuhan pengguna, bukan chat kosong.
- [ ] Screenshot empat state asisten sesuai hierarki visual “Kantin Kampus Praktis”.
- [ ] Format, analyze, dan seluruh test berhasil.
- [ ] Semua pull request milestone sudah di-review dan di-merge.
- [ ] `CHANGELOG.md` telah diperbarui.
- [ ] Versi `pubspec.yaml` sudah `0.4.0-alpha.1+5`.
- [ ] Tag `v0.4.0-alpha.1` dibuat dan di-push.

---

### `v0.5.0-alpha.1` — Keranjang dan Pemesanan Dummy

**Target:** mahasiswa dapat menyelesaikan alur pemesanan satu stan menggunakan data lokal.  
**Requirement terkait:** FR-07 dan FR-08  
**Versi `pubspec.yaml`:** `0.5.0-alpha.1+6`

#### A. Keranjang

- [ ] **UI-501** — Membuat state keranjang yang tidak disimpan langsung di widget halaman.
- [ ] **UI-502** — Menambahkan item dari katalog, detail, dan rekomendasi AI.
- [ ] **UI-503** — Menambah dan mengurangi jumlah item.
- [ ] **UI-504** — Menghapus satu item dan mengosongkan keranjang.
- [ ] **UI-505** — Menghitung subtotal per item dan total keseluruhan.
- [ ] **UI-506** — Menampilkan empty state keranjang.
- [ ] **UI-507** — Mencegah pencampuran menu dari stan berbeda.
- [ ] **UI-508** — Menampilkan dialog pilihan saat pengguna mencoba menambah menu dari stan lain.
- [ ] **UI-509** — Memeriksa ulang status stan, stok, harga, dan estimasi melalui fake repository.

#### B. Konfirmasi dan status pesanan

- [ ] **UI-510** — Membuat halaman ringkasan pesanan.
- [ ] **UI-511** — Menampilkan informasi “Bayar di konter” tanpa biaya tambahan yang tidak dijelaskan.
- [ ] **UI-512** — Menampilkan konfirmasi akhir dan persetujuan “Saya sudah memeriksa pesanan” sebelum tombol buat pesanan aktif.
- [ ] **UI-513** — Membuat nomor pesanan dummy yang mudah dibaca.
- [ ] **UI-514** — Membuat halaman sukses pemesanan.
- [ ] **UI-515** — Membuat daftar pesanan aktif mahasiswa.
- [ ] **UI-516** — Membuat Detail Pesanan dengan timeline vertikal mengikuti warna status design system.
- [ ] **UI-517** — Mendukung status Menunggu Konfirmasi, Diproses, Siap Diambil, Selesai, dan Ditolak.
- [ ] **UI-518** — Menampilkan alasan ketika pesanan ditolak.
- [ ] **UI-519** — Menyediakan kontrol simulasi status hanya untuk mode demo/debug.

#### C. Pengujian

- [ ] **UI-520** — Menguji perhitungan total untuk beberapa item dan perubahan jumlah.
- [ ] **UI-521** — Menguji larangan keranjang lintas stan.
- [ ] **UI-522** — Menguji menu habis atau perubahan harga sebelum konfirmasi.
- [ ] **UI-523** — Menguji seluruh transisi status yang valid.
- [ ] **UI-524** — Menguji transisi status yang tidak valid ditolak.
- [ ] **UI-525** — Membuat widget test alur katalog sampai sukses pemesanan.

#### D. Kesesuaian visual

- [ ] **UI-526** — Menampilkan sticky cart bar di atas bottom navigation ketika keranjang berisi item.
- [ ] **UI-527** — Menguji bahwa subtotal sama dengan total ketika tidak ada biaya tambahan.
- [ ] **UI-528** — Menangani loading, empty, error/retry, disabled, dan perubahan data saat konfirmasi tanpa kehilangan isi keranjang.
- [ ] **UI-529** — Memastikan floating assistant tersembunyi pada Keranjang, Konfirmasi, Pesanan Berhasil, dan Status Pesanan.
- [ ] **UI-530** — Menentukan aturan pembatalan pesanan pada Mini-SRS sebelum mengaktifkan tombol “Batalkan pesanan”; sembunyikan aksi jika aturan belum disepakati.
- [ ] **UI-531** — Membandingkan screenshot Keranjang, Konfirmasi, Pesanan Berhasil, dan Status Pesanan pada 390 dp serta satu lebar pembanding dengan mockup v2.

#### Branch yang disarankan

- [ ] `feat/single-stall-cart`
- [ ] `feat/order-confirmation`
- [ ] `feat/order-success`
- [ ] `feat/order-status`
- [ ] `test/order-flow`

#### Release gate `v0.5.0-alpha.1`

- [ ] Total tetap benar setelah tambah, kurang, dan hapus item.
- [ ] Subtotal sama dengan total apabila tidak ada biaya lain yang ditampilkan.
- [ ] Pengguna tidak dapat mencampur menu dari dua stan.
- [ ] Menu yang sudah habis tidak dapat dikonfirmasi.
- [ ] Alur katalog → keranjang → konfirmasi → nomor pesanan berjalan tanpa backend.
- [ ] Semua status pesanan dapat disimulasikan secara valid.
- [ ] Sticky cart bar, quantity stepper, tombol aksi, dan timeline menggunakan shared component “Kantin Kampus Praktis”.
- [ ] Floating assistant tidak muncul selama checkout dan pemantauan pesanan.
- [ ] Tombol pembatalan tidak diaktifkan sebelum aturan bisnisnya terdokumentasi.
- [ ] Screenshot empat layar pemesanan sesuai acuan visual v2.
- [ ] Format, analyze, dan seluruh test berhasil.
- [ ] Semua pull request milestone sudah di-review dan di-merge.
- [ ] `CHANGELOG.md` telah diperbarui.
- [ ] Versi `pubspec.yaml` sudah `0.5.0-alpha.1+6`.
- [ ] Tag `v0.5.0-alpha.1` dibuat dan di-push.

---

### `v0.6.0-alpha.1` — Panel Pengelola Stan

**Target:** pengelola dapat mengelola kondisi stan, menu, dan pesanan melalui UI dummy.  
**Requirement terkait:** FR-09  
**Versi `pubspec.yaml`:** `0.6.0-alpha.1+7`

#### A. Dashboard dan menu

- [ ] **UI-601** — Membuat Dashboard “Kantin Kampus Praktis” berisi status stan, ringkasan hari ini, daftar “Perlu tindakan”, dan pesanan terbaru tanpa grafik dekoratif.
- [ ] **UI-602** — Membuat Pengaturan Stan dengan aksi buka/tutup, informasi dasar, jam operasional, dan estimasi yang memang ada pada kebutuhan produk.
- [ ] **UI-603** — Membuat Kelola Menu dengan foto, harga, estimasi, dan switch tersedia/habis.
- [ ] **UI-604** — Membuat aksi ubah menu tersedia/habis.
- [ ] **UI-605** — Membuat aksi ubah estimasi waktu penyajian pada layar Pengaturan Stan atau Detail Menu sesuai tanggung jawab datanya.
- [ ] **UI-606** — Menampilkan konfirmasi dan feedback untuk setiap perubahan.
- [ ] **UI-607** — Memastikan pengelola dummy hanya melihat data stannya sendiri.

#### B. Pengelolaan pesanan

- [ ] **UI-608** — Membuat Pesanan Masuk dengan informasi nomor, mahasiswa, jumlah item, total, dan waktu tunggu.
- [ ] **UI-609** — Membuat filter/tab Baru, Diproses, dan Siap.
- [ ] **UI-610** — Membuat Detail Pesanan berisi item, catatan, total, label bayar di konter, dan aksi status.
- [ ] **UI-611** — Membuat aksi terima pesanan.
- [ ] **UI-612** — Membuat aksi tolak pesanan dan input alasan wajib.
- [ ] **UI-613** — Membuat aksi ubah status ke Diproses, Siap Diambil, dan Selesai.
- [ ] **UI-614** — Menonaktifkan aksi yang tidak sesuai dengan status saat ini.
- [ ] **UI-615** — Menampilkan dialog konfirmasi untuk perubahan status penting.
- [ ] **UI-616** — Memastikan perubahan pada mode pengelola terlihat pada mode mahasiswa melalui fake repository yang sama.

#### C. Pengujian

- [ ] **UI-617** — Menguji pembatasan data berdasarkan stan/peran dummy.
- [ ] **UI-618** — Menguji alasan penolakan wajib diisi.
- [ ] **UI-619** — Menguji transisi status valid dan tidak valid.
- [ ] **UI-620** — Menguji perubahan ketersediaan menu tampil pada katalog mahasiswa.
- [ ] **UI-621** — Membuat widget test alur pesanan masuk sampai selesai.

#### D. Kesesuaian visual

- [ ] **UI-622** — Membuat navigation bar pengelola: Dashboard—Pesanan—Menu—Profil.
- [ ] **UI-623** — Memastikan UI pengelola memakai token dan shared component yang sama dengan UI mahasiswa.
- [ ] **UI-624** — Memastikan tidak ada grafik penjualan, promo, multi-stan, delivery, atau fitur di luar baseline.
- [ ] **UI-625** — Memastikan grouped list, tab status, toggle, dialog, dan feedback aksi pengelola memakai komponen bersama secara konsisten.
- [ ] **UI-626** — Membuat Profil Pengelola dengan informasi akun, akses Pengaturan Stan, notifikasi, bantuan, tentang aplikasi, dan aksi keluar.
- [ ] **UI-627** — Menangani loading, empty, error/retry, offline, disabled, dan success pada daftar pesanan serta menu pengelola.
- [ ] **UI-628** — Membandingkan screenshot Dashboard, Pesanan Masuk, Detail Pesanan, Kelola Menu, Pengaturan Stan, dan Profil pada 390 dp serta satu lebar pembanding dengan mockup v2.
- [ ] **UI-629** — Menyembunyikan aksi tambah/edit/hapus menu jika Mini-SRS belum mendefinisikan kebutuhan dan aturan bisnisnya; jangan menganggap tombol pada mockup sebagai scope otomatis.

#### Branch yang disarankan

- [ ] `feat/vendor-dashboard`
- [ ] `feat/stall-operating-status`
- [ ] `feat/menu-availability`
- [ ] `feat/vendor-order-status`
- [ ] `test/vendor-flow`

#### Release gate `v0.6.0-alpha.1`

- [ ] Pengelola hanya melihat dan mengubah data stannya.
- [ ] Pesanan dapat diterima, ditolak, diproses, disiapkan, dan diselesaikan.
- [ ] Transisi status yang tidak valid tidak dapat dilakukan.
- [ ] Perubahan dummy terlihat konsisten di UI mahasiswa dan pengelola.
- [ ] Enam layar pengelola sesuai hierarki dan perilaku mockup “Kantin Kampus Praktis”.
- [ ] Navigation bar dan seluruh status pengelola memakai design system yang sama dengan mahasiswa.
- [ ] Tidak ada fitur pengelola di luar Mini-SRS yang aktif hanya karena terlihat pada mockup.
- [ ] Format, analyze, dan seluruh test berhasil.
- [ ] Semua pull request milestone sudah di-review dan di-merge.
- [ ] `CHANGELOG.md` telah diperbarui.
- [ ] Versi `pubspec.yaml` sudah `0.6.0-alpha.1+7`.
- [ ] Tag `v0.6.0-alpha.1` dibuat dan di-push.

---

### `v0.7.0-beta.1` — Notifikasi Android dan Demo UI Lengkap

**Target:** seluruh UI dapat didemonstrasikan end-to-end tanpa backend dan menggunakan satu Android API.  
**Requirement terkait:** FR-10 dan pemetaan komponen Android  
**Versi `pubspec.yaml`:** `0.7.0-beta.1+8`

#### A. Notifikasi lokal Android

- [ ] **UI-701** — Menentukan pesan notifikasi untuk status Siap Diambil dan Ditolak.
- [ ] **UI-702** — Membuat `NotificationChannel` untuk status pesanan.
- [ ] **UI-703** — Menambahkan permission notifikasi yang diperlukan pada Android.
- [ ] **UI-704** — Meminta `POST_NOTIFICATIONS` hanya pada Android 13 atau lebih baru.
- [ ] **UI-705** — Menjelaskan manfaat notifikasi sebelum meminta izin jika diperlukan.
- [ ] **UI-706** — Menampilkan notifikasi lokal saat simulasi status menjadi Siap Diambil.
- [ ] **UI-707** — Menampilkan notifikasi lokal saat simulasi status menjadi Ditolak.
- [ ] **UI-708** — Membuat ketukan notifikasi membuka detail pesanan yang benar.
- [ ] **UI-709** — Menjaga status pesanan tetap terlihat di aplikasi ketika izin ditolak.
- [ ] **UI-710** — Membuat abstraksi agar notifikasi lokal kelak dapat diganti/ditambah FCM.

#### B. Polishing seluruh UI

- [ ] **UI-711** — Memeriksa seluruh layar terhadap token warna, tipografi, spacing, radius, ikon, tombol, daftar, dan dialog “Kantin Kampus Praktis”.
- [ ] **UI-712** — Memeriksa seluruh loading, empty, error/retry, offline, disabled, dan success state.
- [ ] **UI-713** — Memastikan tidak ada loading tanpa batas.
- [ ] **UI-714** — Memastikan tidak ada overflow pada lebar 360, 390, dan 412 dp.
- [ ] **UI-715** — Memastikan keyboard tidak menutupi input penting.
- [ ] **UI-716** — Menambahkan label semantic pada aksi dan ikon penting.
- [ ] **UI-717** — Memeriksa kontras teks normal minimal 4.5:1, target sentuh 48 × 48 dp, dan keterbacaan ketika text scale diperbesar.
- [ ] **UI-718** — Memastikan format Rupiah, waktu, dan status konsisten.
- [ ] **UI-719** — Menghapus tombol/halaman placeholder yang tidak digunakan dalam demo.
- [ ] **UI-720** — Memastikan mode demo tidak membutuhkan koneksi internet.
#### C. Skenario demo dan pengujian

- [ ] **UI-721** — Menulis skenario demo mahasiswa: cari menu secara manual sampai detail.
- [ ] **UI-722** — Menulis skenario demo AI: input kebutuhan sampai rekomendasi.
- [ ] **UI-723** — Menulis skenario demo pemesanan: keranjang sampai nomor pesanan.
- [ ] **UI-724** — Menulis skenario demo pengelola: terima pesanan sampai Siap Diambil.
- [ ] **UI-725** — Menulis skenario demo notifikasi: status berubah lalu buka detail dari notifikasi.
- [ ] **UI-726** — Menyiapkan reset dummy data agar demo dapat diulang.
- [ ] **UI-727** — Menjalankan seluruh unit dan widget test.
- [ ] **UI-728** — Menjalankan integration test untuk happy path utama jika tersedia.
- [ ] **UI-729** — Menguji permission notifikasi diberikan dan ditolak.
- [ ] **UI-730** — Menguji cold start/deep link notifikasi jika didukung implementasi.
- [ ] **UI-731** — Mengambil screenshot/video bukti setiap alur utama.
- [ ] **UI-732** — Melakukan build APK release dan memasangnya pada perangkat uji.

#### D. Visual QA final

- [ ] **UI-733** — Memastikan tidak ada warna/text style/spacing/radius utama yang hard-coded berulang di feature widget.
- [ ] **UI-734** — Memastikan foto tidak terdistorsi dan seluruh ikon memakai Material Symbols Rounded.
- [ ] **UI-735** — Melakukan visual QA side-by-side terhadap 11 layar mahasiswa, 6 layar pengelola, dan seluruh state penting pada paket mockup v2.
- [ ] **UI-736** — Memeriksa fokus coachmark/bottom sheet, pengembalian fokus, tooltip tombol ikon, dan pengumuman perubahan status penting.
- [ ] **UI-737** — Memastikan reduced motion menonaktifkan animasi scale asisten dan tidak menghilangkan informasi atau fungsi.
- [ ] **UI-738** — Memastikan grouped list, divider, dan penggunaan kartu konsisten; tidak ada regresi ke tumpukan kartu generik.

#### Branch yang disarankan

- [ ] `feat/android-notification`
- [ ] `feat/notification-permission`
- [ ] `feat/order-deep-link`
- [ ] `test/notification-fallback`
- [ ] `fix/ui-polish`
- [ ] `docs/demo-scenario`

#### Release gate `v0.7.0-beta.1`

- [ ] UI mahasiswa berjalan dari katalog/AI sampai status pesanan.
- [ ] UI pengelola berjalan dari pesanan masuk sampai pesanan selesai.
- [ ] Seluruh layar mahasiswa dan pengelola konsisten dengan [`DESIGN_SYSTEM.md`](../design/DESIGN_SYSTEM.md).
- [ ] Semua data dummy diakses melalui abstraksi repository/service.
- [ ] Notifikasi Android dapat didemonstrasikan pada emulator/perangkat.
- [ ] Penolakan permission tidak merusak alur aplikasi.
- [ ] Demo dapat dilakukan tanpa backend dan tanpa internet.
- [ ] Visual QA tidak memiliki temuan blocker/major dan bukti screenshot tersedia.
- [ ] Floating assistant, coachmark, bottom sheet, hidden routes, keyboard, sticky cart, dan reduced motion sudah divalidasi.
- [ ] Tidak ada gradien, glow, robot besar, kartu bertumpuk, atau pill dekoratif yang menyimpang dari arah visual.
- [ ] Tidak ada overflow pada lebar target; harga/total tetap terbaca saat text scale diperbesar.
- [ ] `dart format --set-exit-if-changed .` berhasil.
- [ ] `flutter analyze` berhasil tanpa error.
- [ ] `flutter test` berhasil seluruhnya.
- [ ] `flutter build apk --release` berhasil.
- [ ] Seluruh bug blocker/critical sudah ditutup.
- [ ] Semua pull request milestone sudah di-review dan di-merge.
- [ ] `CHANGELOG.md` dan petunjuk demo telah diperbarui.
- [ ] Versi `pubspec.yaml` sudah `0.7.0-beta.1+8`.
- [ ] Tag `v0.7.0-beta.1` dibuat dan di-push.

---

## 5. Checklist Wajib untuk Setiap GitHub Issue

Salin checklist berikut ke deskripsi setiap issue:

```markdown
## Tujuan
- [ ] Masalah dan hasil yang diharapkan sudah jelas

## Acceptance Criteria
- [ ] Kriteria 1
- [ ] Kriteria 2

## Pengerjaan
- [ ] Branch dibuat dari `main` terbaru
- [ ] Implementasi sesuai scope issue
- [ ] Requirement Mini-SRS dan layar/komponen mockup v2 yang terkait sudah ditentukan
- [ ] Loading/empty/error/retry/offline/disabled/success ditangani jika relevan
- [ ] Aturan visibilitas floating assistant diperiksa jika route berubah
- [ ] Test ditambahkan atau diperbarui
- [ ] Screenshot/video 390 dp dan satu lebar pembanding disiapkan jika UI berubah

## Sebelum ditutup
- [ ] Format, analyze, dan test berhasil
- [ ] Pull request sudah direview
- [ ] Perubahan sudah di-merge ke `main`
- [ ] Branch sudah dihapus
```

---

## 6. Checklist Wajib untuk Setiap Pull Request

```markdown
## Pemeriksaan pembuat PR
- [ ] PR hanya menyelesaikan satu tujuan utama
- [ ] Nama branch sesuai jenis pekerjaan
- [ ] Commit menggunakan Conventional Commits
- [ ] Tidak ada secret, `.env`, atau file build
- [ ] Tidak ada dummy data yang ditulis langsung di widget
- [ ] Tidak ada warna, text style, spacing, atau radius utama yang hard-coded berulang
- [ ] Shared component dan token “Kantin Kampus Praktis” digunakan
- [ ] Daftar memakai spacing/divider sebelum menambah kartu, border, atau shadow
- [ ] Tidak ada gradien, glow, robot besar, pill dekoratif, atau pola visual di luar baseline
- [ ] Floating assistant hanya muncul pada route dan state yang diizinkan
- [ ] Tidak ada warning/error analyzer baru
- [ ] Test relevan berhasil
- [ ] Screenshot/video UI pada 390 dp dan satu lebar pembanding dilampirkan
- [ ] Penyimpangan dari mockup dijelaskan dan disetujui
- [ ] Requirement atau issue terkait ditulis

## Pemeriksaan reviewer
- [ ] Acceptance criteria sudah terpenuhi
- [ ] Navigasi dan state tidak rusak
- [ ] Loading, empty, error/retry, offline, disabled, dan success state ditangani
- [ ] UI sesuai [`DESIGN_SYSTEM.md`](../design/DESIGN_SYSTEM.md) dan struktur mockup terpilih
- [ ] UI tetap terbaca pada lebar 360/390/412 dp dan saat text scale diperbesar
- [ ] Target sentuh minimal 48 × 48 dp dan warna bukan satu-satunya penanda status
- [ ] Fokus, keyboard, SafeArea, reduced motion, dan semantic label diperiksa jika relevan
- [ ] Fitur yang terlihat di mockup tetapi tidak ada pada Mini-SRS tidak diaktifkan diam-diam
- [ ] Tidak ada duplikasi atau coupling yang menyulitkan backend
- [ ] Nama kelas, fungsi, dan variabel mudah dipahami
- [ ] PR layak di-merge
```

---

## 7. Format Commit yang Digunakan

Contoh commit untuk setiap jenis pekerjaan:

```text
feat(catalog): add menu price filter
feat(ai): add clarification state
feat(order): add single-stall cart validation
fix(ui): prevent menu row overflow
test(order): cover invalid status transition
refactor(data): extract menu repository interface
docs(checklist): update v0.4 progress
chore(ci): run flutter analyze on pull request
```

Commit sebaiknya menjelaskan satu perubahan yang jelas. Hindari pesan seperti `update`, `fix`, `revisi`, atau `coding lagi` tanpa konteks.

---

## 8. Definition of Done Fase UI

Fase UI baru boleh dinyatakan selesai jika:

- [ ] Semua release gate `v0.1` sampai `v0.7` telah dicentang.
- [ ] Semua tag `v0.1.0-alpha.1` sampai `v0.7.0-beta.1` tersedia di repository.
- [ ] UI mahasiswa dan pengelola dapat didemonstrasikan end-to-end.
- [ ] Sebelas layar mahasiswa dan enam layar pengelola mengikuti baseline “Kantin Kampus Praktis”.
- [ ] Tidak ada token visual utama yang hard-coded berulang di feature widget.
- [ ] Visual QA terhadap mockup lulus tanpa temuan blocker/major.
- [ ] Screenshot 390 dp dan satu lebar pembanding tersedia untuk seluruh layar utama serta state penting.
- [ ] Pemeriksaan lebar 360/390/412 dp dan text scale telah dilakukan.
- [ ] Asisten Pilih Menu memiliki floating button, coachmark satu kali, bottom sheet, hasil rekomendasi, hidden routes, fallback manual, dan fake service yang teruji.
- [ ] Floating assistant tidak overlap dengan sticky cart, bottom navigation, keyboard, harga, atau aksi `Tambah`.
- [ ] Reduced motion, fokus, semantic label, loading, empty, offline, error, disabled, dan retry sudah diverifikasi.
- [ ] Grouped list dan divider digunakan secara konsisten; tidak ada regresi ke tumpukan kartu generik.
- [ ] Notifikasi lokal Android dapat didemonstrasikan.
- [ ] Semua dummy data berada di lapisan fake repository/service.
- [ ] Tidak ada widget yang bergantung langsung pada implementasi backend.
- [ ] Tidak ada API key atau secret di repository.
- [ ] Build APK release berhasil dipasang dan dijalankan.
- [ ] Bug blocker dan critical berjumlah nol.
- [ ] Roadmap, [Mini-SRS](MINI_SRS.md), README, design system, changelog, dan skenario demo konsisten.

---

## 9. Backend — To Be Continued

Pekerjaan berikut **sengaja belum dijabarkan menjadi checklist implementasi**. Checklist backend dibuat setelah backend, endpoint, autentikasi, database, dan kontrak respons disepakati.

| Versi berikutnya | Fokus sementara | Status |
|---|---|---|
| `v0.8.0-beta.1` | API client, autentikasi, secure storage, dan remote repository | **TBC — Backend belum tersedia** |
| `v0.9.0-beta.1` | AI melalui backend, validasi hasil, FCM, dan alur nyata | **TBC — Backend belum tersedia** |
| `v1.0.0-rc.1` | Feature freeze, QA end-to-end, keamanan, dan perbaikan | **TBC** |
| `v1.0.0` | Rilis baseline final | **TBC** |

### Syarat memulai `v0.8.0-beta.1`

- [ ] Backend dapat dijalankan pada environment pengembangan.
- [ ] Base URL dan pengelolaan environment sudah disepakati.
- [ ] Dokumentasi endpoint dan contoh request/response tersedia.
- [ ] Mekanisme autentikasi dan role mahasiswa/pengelola sudah disepakati.
- [ ] Daftar status/error API sudah tersedia.
- [ ] Skema data tidak bertentangan dengan model domain UI.
- [ ] Strategi AI dan FCM sudah disepakati tanpa menaruh secret di Flutter.
- [ ] Tim menyetujui checklist backend baru sebelum implementasi dimulai.

> Sampai semua syarat di atas tersedia, pertahankan `FakeRepository` dan `FakeAiRecommendationService` sebagai mode demo yang stabil.
