# Checklist Pengerjaan UI KantinCerdas

**Dokumen:** Checklist implementasi dan version control fase UI  
**Versi dokumen:** 1.1  
**Cakupan:** `v0.1.0-alpha.1` sampai `v0.7.0-beta.1`  
**Platform:** Android dengan Flutter  
**Mode data:** Dummy/fake repository  
**Baseline visual:** “Kantin Hangat”  
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
- Untuk perubahan visual, lampirkan screenshot implementasi pada lebar 390 dp dan bandingkan dengan mockup.
- API key, token, password, dan `.env` asli tidak boleh masuk ke Git.

Perbedaan nomor versi:

```text
pubspec.yaml : 0.3.0-alpha.1+3
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
| Arah visual | “Kantin Hangat”: oranye, krem, ramah, dan food-first |
| Warna merek | `#E85D2A` |
| Warna aksi/tombol | `#C74418` |
| Terracotta | `#9B341B` |
| Latar utama | `#FFF8EF` |
| Surface hangat | `#FDEDE2` |
| Teks utama | `#251B17` |
| Font | Plus Jakarta Sans; fallback Inter/sans-serif sistem |
| Spacing | Grid 8 dp; padding halaman 16 dp |
| Radius | 8, 12, 20, 24, dan pill |
| Ikon | Material Symbols Rounded |
| Target sentuh | Minimal 48 × 48 dp |

Layar acuan mahasiswa: **Beranda, Detail Stan, Asisten AI, Keranjang, Status Pesanan**.  
Layar acuan pengelola: **Dashboard, Pesanan Masuk, Detail Pesanan, Kelola Menu**.

> Keputusan desain sudah terkunci, tetapi checklist implementasi tetap kosong sampai perubahan benar-benar dibuat, diuji, dan di-merge ke `main`.

---

## 3. Ringkasan Pelacakan Versi

| Versi | Target hasil | Waktu | Status | Tag |
|---|---|---:|---|---|
| `v0.1.0-alpha.1` | Fondasi Flutter, Git, quality gate, dan acuan desain | Hari 1 | ⬜ | ⬜ |
| `v0.2.0-alpha.1` | Implementasi “Kantin Hangat”, app shell, dan fake data | Hari 2–3 | ⬜ | ⬜ |
| `v0.3.0-alpha.1` | Katalog, pencarian, dan filter | Hari 4–5 | ⬜ | ⬜ |
| `v0.4.0-alpha.1` | UI Asisten Pilih Menu | Hari 6–7 | ⬜ | ⬜ |
| `v0.5.0-alpha.1` | Keranjang dan pemesanan dummy | Hari 8 | ⬜ | ⬜ |
| `v0.6.0-alpha.1` | Panel pengelola stan | Hari 9 | ⬜ | ⬜ |
| `v0.7.0-beta.1` | Notifikasi Android dan demo UI lengkap | Hari 10 | ⬜ | ⬜ |

---

## 4. Checklist per Versi

## `v0.1.0-alpha.1` — Fondasi Proyek dan Version Control

**Target:** proyek dapat di-clone, dijalankan, diuji, dan dikembangkan dengan alur Git yang konsisten.  
**Versi `pubspec.yaml`:** `0.1.0-alpha.1+1`

### A. Repository dan proyek

- [x] **UI-101** — Membuat repository GitHub KantinCerdas.
- [x] **UI-102** — Membuat proyek Flutter dengan application ID yang disepakati.
- [ ] **UI-103** — Memastikan proyek dapat dijalankan pada emulator/perangkat Android.
- [x] **UI-104** — Menambahkan `.gitignore` untuk Flutter, Android, IDE, build, dan `.env`.
- [x] **UI-105** — Menambahkan `.env.example` tanpa nilai rahasia.
- [x] **UI-106** — Menambahkan `README.md` berisi cara clone, setup, run, test, dan build.
- [x] **UI-107** — Menambahkan [Mini-SRS](MINI_SRS.md), roadmap, checklist UI, dan [`DESIGN_SYSTEM.md`](../design/DESIGN_SYSTEM.md) ke repository.

### B. Struktur dan kualitas awal

- [x] **UI-108** — Menyiapkan struktur `lib/app`, `lib/core`, `lib/features`, dan `lib/shared`.
- [x] **UI-109** — Mengaktifkan aturan lint yang disepakati tim.
- [x] **UI-110** — Membuat minimal satu smoke test bawaan proyek.
- [x] **UI-111** — Menyiapkan CI untuk menjalankan format check, analyze, dan test pada pull request.
- [x] **UI-112** — Menambahkan template pull request.
- [ ] **UI-113** — Membuat label GitHub: `feature`, `bug`, `ui`, `test`, `docs`, `blocked`, dan `release`.
- [ ] **UI-114** — Membuat milestone GitHub untuk `v0.1` sampai `v0.7`.

### C. Latihan Git

- [x] **UI-115** — Menetapkan `main` sebagai branch utama.
- [x] **UI-116** — Menulis aturan nama branch dan Conventional Commits di `CONTRIBUTING.md` atau `README.md`.
- [ ] **UI-117** — Membuat minimal satu branch `chore/project-bootstrap`.
- [ ] **UI-118** — Membuat pull request pertama, meminta review, lalu melakukan squash merge.
- [ ] **UI-119** — Menghapus branch yang sudah di-merge.
- [x] **UI-120** — Menambahkan mockup terpilih “Kantin Hangat” untuk mahasiswa, pengelola, dan papan komponen ke dokumentasi proyek.

### Release gate `v0.1.0-alpha.1`

- [ ] Anggota lain dapat menjalankan proyek dari hasil clone tanpa file lokal pembuat proyek.
- [x] `dart format --set-exit-if-changed .` berhasil.
- [x] `flutter analyze` berhasil tanpa error.
- [x] `flutter test` berhasil.
- [x] Tidak ada secret atau `.env` asli dalam Git.
- [x] [`DESIGN_SYSTEM.md`](../design/DESIGN_SYSTEM.md) dan mockup terpilih dapat diakses seluruh anggota tim.
- [x] README menyatakan bahwa “Kantin Hangat” adalah baseline visual yang tidak diubah tanpa keputusan tim.
- [ ] Semua issue milestone `v0.1` sudah ditutup.
- [x] `CHANGELOG.md` telah diperbarui.
- [x] Versi `pubspec.yaml` sudah `0.1.0-alpha.1+1`.
- [ ] Tag `v0.1.0-alpha.1` dibuat dari commit terbaru di `main` dan di-push.

---

## `v0.2.0-alpha.1` — App Shell, Design System, dan Fake Data

**Target:** semua halaman utama bisa dinavigasi dan memiliki fondasi UI/data yang siap diganti ke backend.  
**Versi `pubspec.yaml`:** `0.2.0-alpha.1+2`

### A. Design system

- [ ] **UI-201** — Membuat token `KcColors`/`ColorScheme` dengan `#E85D2A`, `#C74418`, `#9B341B`, `#FFF8EF`, `#FDEDE2`, `#251B17`, serta warna status pada design system.
- [ ] **UI-202** — Membuat `TextTheme` Plus Jakarta Sans untuk Display, Heading, Title, Body, Label, dan Caption.
- [ ] **UI-203** — Membuat token spacing 4/8/12/16/24/32/40/48, radius 8/12/20/24/pill, serta elevation terbatas.
- [ ] **UI-204** — Membuat komponen primary, secondary, tertiary, dan destructive button dengan state pressed, focused, loading, dan disabled.
- [ ] **UI-205** — Membuat komponen search field, input, filter chip, dialog, bottom sheet, dan snackbar sesuai “Kantin Hangat”.
- [ ] **UI-206** — Membuat komponen loading, skeleton, empty, error, retry, dan success yang konsisten.
- [ ] **UI-207** — Menguji kontras, text scaling, serta target sentuh minimal 48 × 48 dp.

### B. App shell dan navigasi

- [ ] **UI-208** — Membuat splash/initial screen sederhana.
- [ ] **UI-209** — Membuat UI masuk atau pemilihan peran khusus mode demo.
- [ ] **UI-210** — Membuat shell mahasiswa dengan navigasi Beranda—Pesanan—Profil.
- [ ] **UI-211** — Membuat shell pengelola dengan navigasi Dashboard—Pesanan—Menu—Profil.
- [ ] **UI-212** — Menentukan route name/path pada satu tempat.
- [ ] **UI-213** — Menangani halaman tidak ditemukan dan navigasi kembali.
- [ ] **UI-214** — Menjaga state halaman penting ketika berpindah tab.

### C. Domain dan sumber data dummy

- [ ] **UI-215** — Membuat model domain `User`, `Stall`, `MenuItem`, `Cart`, `Order`, dan `Recommendation`.
- [ ] **UI-216** — Membuat enum untuk peran, status stan, status menu, dan status pesanan.
- [ ] **UI-217** — Membuat interface repository/service yang dibutuhkan UI.
- [ ] **UI-218** — Membuat `FakeRepository` dengan data beberapa stan dan menu yang realistis.
- [ ] **UI-219** — Menyediakan skenario dummy: sukses, loading, kosong, gagal, stan tutup, dan menu habis.
- [ ] **UI-220** — Menyediakan satu konfigurasi untuk memilih fake/remote data source tanpa mengubah widget.
- [ ] **UI-221** — Memastikan widget tidak mengimpor file JSON dummy secara langsung.

### D. Pengujian

- [ ] **UI-222** — Membuat test untuk parsing/model domain utama.
- [ ] **UI-223** — Membuat widget test navigasi mahasiswa.
- [ ] **UI-224** — Membuat widget test navigasi pengelola.
- [ ] **UI-225** — Menguji tampilan loading, empty, error, dan success.

### E. Komponen visual bersama

- [ ] **UI-226** — Membuat shared menu card/list tile dengan foto, nama, harga, stan, ketersediaan, dan estimasi.
- [ ] **UI-227** — Membuat shared AI callout “Masih bingung?” dan komponen kartu rekomendasi.
- [ ] **UI-228** — Membuat status badge, order timeline, dan quantity stepper berdasarkan design system.
- [ ] **UI-229** — Menggunakan Material Symbols Rounded dan menghapus emoji sebagai ikon UI.
- [ ] **UI-230** — Membuat halaman/catalog internal untuk melihat seluruh komponen dan state visual.

### Branch yang disarankan

- [ ] `feat/kantin-hangat-theme`
- [ ] `feat/shared-ui-components`
- [ ] `feat/app-navigation`
- [ ] `feat/domain-models`
- [ ] `chore/fake-repository`
- [ ] `test/app-shell`

### Release gate `v0.2.0-alpha.1`

- [ ] Semua layar utama dapat dibuka walaupun isinya masih dummy.
- [ ] Mode mahasiswa dan pengelola dapat didemonstrasikan.
- [ ] Theme, komponen, dan navigation bar mengikuti [`DESIGN_SYSTEM.md`](../design/DESIGN_SYSTEM.md).
- [ ] Tidak ada warna, spacing, atau style utama yang berulang secara hard-coded.
- [ ] Tidak ada emoji yang digunakan sebagai ikon antarmuka.
- [ ] Semua tombol/input utama memiliki target sentuh minimal 48 × 48 dp.
- [ ] UI tidak overflow pada lebar 360, 390, dan 412 dp serta saat text scale diperbesar.
- [ ] Screenshot catalog komponen dan app shell pada lebar 390 dp tersedia.
- [ ] Fake data hanya diakses melalui abstraction.
- [ ] Format, analyze, dan seluruh test berhasil.
- [ ] Semua pull request milestone sudah di-review dan di-merge.
- [ ] `CHANGELOG.md` telah diperbarui.
- [ ] Versi `pubspec.yaml` sudah `0.2.0-alpha.1+2`.
- [ ] Tag `v0.2.0-alpha.1` dibuat dan di-push.

---

## `v0.3.0-alpha.1` — Katalog, Pencarian, dan Filter

**Target:** mahasiswa bisa menemukan menu secara manual tanpa AI.  
**Requirement terkait:** FR-01, FR-02, dan fallback FR-06  
**Versi `pubspec.yaml`:** `0.3.0-alpha.1+3`

### A. Daftar stan dan menu

- [ ] **UI-301** — Membuat Beranda “Kantin Hangat”: sapaan, search field, headline, kategori, “Cepat disiapkan”, dan AI callout compact.
- [ ] **UI-302** — Membuat daftar stan beserta nama, foto, status buka/tutup, dan estimasi tanpa jarak/rating/promo.
- [ ] **UI-303** — Membuat Detail Stan seperti acuan “Dapur Bu Rina”: status buka, estimasi, chip kategori, dan daftar menu.
- [ ] **UI-304** — Membuat daftar menu milik satu stan.
- [ ] **UI-305** — Menggunakan shared menu card berisi foto, nama, harga, stan, status tersedia, pedas, dan estimasi penyajian.
- [ ] **UI-306** — Membuat halaman atau bottom sheet detail menu.
- [ ] **UI-307** — Menonaktifkan aksi pemesanan saat stan tutup atau menu habis.

### B. Pencarian dan filter

- [ ] **UI-308** — Membuat pencarian berdasarkan nama menu.
- [ ] **UI-309** — Membuat filter kategori makanan/minuman.
- [ ] **UI-310** — Membuat filter rentang harga.
- [ ] **UI-311** — Membuat filter tingkat kepedasan.
- [ ] **UI-312** — Menampilkan filter aktif sebagai chip.
- [ ] **UI-313** — Menambahkan aksi hapus satu filter dan reset semua filter.
- [ ] **UI-314** — Menampilkan jumlah hasil pencarian/filter.
- [ ] **UI-315** — Menampilkan empty state ketika tidak ada menu yang cocok.
- [ ] **UI-316** — Mempertahankan query dan filter saat pengguna membuka detail lalu kembali.

### C. State dan pengujian

- [ ] **UI-317** — Menangani loading, error, retry, dan data kosong untuk daftar stan.
- [ ] **UI-318** — Menangani loading, error, retry, dan data kosong untuk daftar menu.
- [ ] **UI-319** — Membuat unit test pencarian nama menu.
- [ ] **UI-320** — Membuat unit test kombinasi kategori, harga, dan kepedasan.
- [ ] **UI-321** — Membuat widget test reset filter dan empty state.
- [ ] **UI-322** — Menguji scrolling dan overflow pada layar kecil.

### D. Kesesuaian visual

- [ ] **UI-323** — Menggunakan foto makanan dengan rasio/crop konsisten serta fallback image.
- [ ] **UI-324** — Memastikan halaman tidak menampilkan delivery, jarak, rating, voucher, atau pembayaran digital.
- [ ] **UI-325** — Membandingkan screenshot Beranda dan Detail Stan lebar 390 dp dengan mockup mahasiswa.

### Branch yang disarankan

- [ ] `feat/stall-catalog`
- [ ] `feat/menu-catalog`
- [ ] `feat/menu-search`
- [ ] `feat/menu-filter`
- [ ] `test/catalog-filter`

### Release gate `v0.3.0-alpha.1`

- [ ] Pengguna dapat menemukan menu tanpa menggunakan AI.
- [ ] Search dan seluruh kombinasi filter menghasilkan data yang benar.
- [ ] Filter dapat dihapus tanpa menyisakan state lama.
- [ ] Menu habis/stan tutup tidak dapat ditambahkan ke keranjang.
- [ ] Beranda, Detail Stan, dan menu card konsisten dengan warna, tipografi, spacing, serta radius “Kantin Hangat”.
- [ ] UI lulus pemeriksaan pada lebar 360/390/412 dp dan screenshot pembanding tersedia.
- [ ] Format, analyze, dan seluruh test berhasil.
- [ ] Semua pull request milestone sudah di-review dan di-merge.
- [ ] `CHANGELOG.md` telah diperbarui.
- [ ] Versi `pubspec.yaml` sudah `0.3.0-alpha.1+3`.
- [ ] Tag `v0.3.0-alpha.1` dibuat dan di-push.

---

## `v0.4.0-alpha.1` — UI Asisten Pilih Menu

**Target:** alur AI lengkap dapat didemonstrasikan dengan respons terkontrol dari fake service.  
**Requirement terkait:** FR-03 sampai FR-06  
**Versi `pubspec.yaml`:** `0.4.0-alpha.1+4`

### A. Antarmuka asisten

- [ ] **UI-401** — Membuat AI callout compact “Masih bingung?” dengan CTA “Coba asisten” pada beranda.
- [ ] **UI-402** — Membuat halaman Asisten Pilih Menu dalam gaya “Kantin Hangat”; tidak menjadi chatbot mengambang di semua layar.
- [ ] **UI-403** — Membuat input Bahasa Indonesia dan tombol kirim.
- [ ] **UI-404** — Menambahkan suggestion chip seperti “Di bawah Rp20.000”, “Tidak pedas”, dan “Maksimal 10 menit”.
- [ ] **UI-405** — Menampilkan indikator proses ketika rekomendasi sedang disiapkan.
- [ ] **UI-406** — Menampilkan ringkasan kriteria sebagai chip: anggaran, jenis, pedas, dan waktu.
- [ ] **UI-407** — Membuat tampilan pertanyaan klarifikasi jika input belum cukup jelas.
- [ ] **UI-408** — Menjaga input pengguna saat terjadi error atau retry.

### B. Rekomendasi

- [ ] **UI-409** — Membuat kartu rekomendasi menu maksimal lima hasil.
- [ ] **UI-410** — Menampilkan alasan singkat mengapa menu direkomendasikan.
- [ ] **UI-411** — Menampilkan harga, pedas, estimasi, stan, dan ketersediaan dari data menu.
- [ ] **UI-412** — Membuat aksi buka detail menu dari rekomendasi.
- [ ] **UI-413** — Membuat aksi tambah ke keranjang dari rekomendasi.
- [ ] **UI-414** — Menampilkan kondisi tidak ada menu yang cocok.
- [ ] **UI-415** — Menyediakan tombol kembali ke pencarian/filter manual.

### C. Fake AI service dan keamanan kontrak

- [ ] **UI-416** — Membuat interface `AiRecommendationService` yang tidak bergantung pada widget.
- [ ] **UI-417** — Membuat `FakeAiRecommendationService` dengan beberapa skenario prompt.
- [ ] **UI-418** — Memastikan hasil fake AI hanya mengembalikan `menuId` yang ada.
- [ ] **UI-419** — Memvalidasi ulang nama, harga, stok, dan estimasi dari repository, bukan teks AI.
- [ ] **UI-420** — Membuat simulasi timeout, error, dan retry.
- [ ] **UI-421** — Memastikan tidak ada API key atau pemanggilan AI nyata di aplikasi.
- [ ] **UI-422** — Memastikan AI tidak dapat membuat pesanan otomatis.

### D. Pengujian

- [ ] **UI-423** — Menguji prompt “Rp20.000, tidak pedas, maksimal 10 menit”.
- [ ] **UI-424** — Menguji input ambigu menghasilkan klarifikasi.
- [ ] **UI-425** — Menguji `menuId` tidak valid tidak ditampilkan.
- [ ] **UI-426** — Menguji kegagalan AI tetap memberi akses ke filter manual.
- [ ] **UI-427** — Menguji input dengan keyboard dan layar kecil tidak overflow.
- [ ] **UI-428** — Membandingkan screenshot halaman Asisten AI lebar 390 dp dengan mockup mahasiswa.
- [ ] **UI-429** — Memastikan panel AI, chip kriteria, kartu rekomendasi, dan CTA hanya memakai shared component/token.

### Branch yang disarankan

- [ ] `feat/ai-assistant-ui`
- [ ] `feat/ai-criteria-summary`
- [ ] `feat/ai-clarification-state`
- [ ] `feat/ai-recommendation-card`
- [ ] `feat/ai-fallback`
- [ ] `test/ai-assistant-ui`

### Release gate `v0.4.0-alpha.1`

- [ ] Prompt lengkap menghasilkan rekomendasi dummy yang sesuai.
- [ ] Prompt ambigu menghasilkan pertanyaan klarifikasi.
- [ ] Rekomendasi hanya memakai menu yang tersedia di fake repository.
- [ ] Error, timeout, retry, empty, dan success state dapat didemonstrasikan.
- [ ] Tidak ada secret atau API key AI di source code.
- [ ] AI callout tidak menutupi katalog dan halaman AI tidak memperkenalkan fitur di luar scope.
- [ ] Screenshot halaman AI sesuai hierarki visual “Kantin Hangat”.
- [ ] Format, analyze, dan seluruh test berhasil.
- [ ] Semua pull request milestone sudah di-review dan di-merge.
- [ ] `CHANGELOG.md` telah diperbarui.
- [ ] Versi `pubspec.yaml` sudah `0.4.0-alpha.1+4`.
- [ ] Tag `v0.4.0-alpha.1` dibuat dan di-push.

---

## `v0.5.0-alpha.1` — Keranjang dan Pemesanan Dummy

**Target:** mahasiswa dapat menyelesaikan alur pemesanan satu stan menggunakan data lokal.  
**Requirement terkait:** FR-07 dan FR-08  
**Versi `pubspec.yaml`:** `0.5.0-alpha.1+5`

### A. Keranjang

- [ ] **UI-501** — Membuat state keranjang yang tidak disimpan langsung di widget halaman.
- [ ] **UI-502** — Menambahkan item dari katalog, detail, dan rekomendasi AI.
- [ ] **UI-503** — Menambah dan mengurangi jumlah item.
- [ ] **UI-504** — Menghapus satu item dan mengosongkan keranjang.
- [ ] **UI-505** — Menghitung subtotal per item dan total keseluruhan.
- [ ] **UI-506** — Menampilkan empty state keranjang.
- [ ] **UI-507** — Mencegah pencampuran menu dari stan berbeda.
- [ ] **UI-508** — Menampilkan dialog pilihan saat pengguna mencoba menambah menu dari stan lain.
- [ ] **UI-509** — Memeriksa ulang status stan, stok, harga, dan estimasi melalui fake repository.

### B. Konfirmasi dan status pesanan

- [ ] **UI-510** — Membuat halaman ringkasan pesanan.
- [ ] **UI-511** — Menampilkan informasi “Bayar di konter” tanpa biaya tambahan yang tidak dijelaskan.
- [ ] **UI-512** — Menampilkan konfirmasi akhir sebelum pesanan dibuat.
- [ ] **UI-513** — Membuat nomor pesanan dummy yang mudah dibaca.
- [ ] **UI-514** — Membuat halaman sukses pemesanan.
- [ ] **UI-515** — Membuat daftar pesanan aktif mahasiswa.
- [ ] **UI-516** — Membuat Detail Pesanan dengan timeline vertikal mengikuti warna status design system.
- [ ] **UI-517** — Mendukung status Menunggu Konfirmasi, Diproses, Siap Diambil, Selesai, dan Ditolak.
- [ ] **UI-518** — Menampilkan alasan ketika pesanan ditolak.
- [ ] **UI-519** — Menyediakan kontrol simulasi status hanya untuk mode demo/debug.

### C. Pengujian

- [ ] **UI-520** — Menguji perhitungan total untuk beberapa item dan perubahan jumlah.
- [ ] **UI-521** — Menguji larangan keranjang lintas stan.
- [ ] **UI-522** — Menguji menu habis atau perubahan harga sebelum konfirmasi.
- [ ] **UI-523** — Menguji seluruh transisi status yang valid.
- [ ] **UI-524** — Menguji transisi status yang tidak valid ditolak.
- [ ] **UI-525** — Membuat widget test alur katalog sampai sukses pemesanan.

### D. Kesesuaian visual

- [ ] **UI-526** — Menampilkan sticky cart bar di atas bottom navigation ketika keranjang berisi item.
- [ ] **UI-527** — Menguji bahwa subtotal sama dengan total ketika tidak ada biaya tambahan.
- [ ] **UI-528** — Membandingkan screenshot Keranjang dan Status Pesanan lebar 390 dp dengan mockup mahasiswa.

### Branch yang disarankan

- [ ] `feat/single-stall-cart`
- [ ] `feat/order-confirmation`
- [ ] `feat/order-success`
- [ ] `feat/order-status`
- [ ] `test/order-flow`

### Release gate `v0.5.0-alpha.1`

- [ ] Total tetap benar setelah tambah, kurang, dan hapus item.
- [ ] Subtotal sama dengan total apabila tidak ada biaya lain yang ditampilkan.
- [ ] Pengguna tidak dapat mencampur menu dari dua stan.
- [ ] Menu yang sudah habis tidak dapat dikonfirmasi.
- [ ] Alur katalog → keranjang → konfirmasi → nomor pesanan berjalan tanpa backend.
- [ ] Semua status pesanan dapat disimulasikan secara valid.
- [ ] Sticky cart bar, quantity stepper, tombol aksi, dan timeline menggunakan shared component “Kantin Hangat”.
- [ ] Screenshot Keranjang dan Status Pesanan sesuai acuan visual.
- [ ] Format, analyze, dan seluruh test berhasil.
- [ ] Semua pull request milestone sudah di-review dan di-merge.
- [ ] `CHANGELOG.md` telah diperbarui.
- [ ] Versi `pubspec.yaml` sudah `0.5.0-alpha.1+5`.
- [ ] Tag `v0.5.0-alpha.1` dibuat dan di-push.

---

## `v0.6.0-alpha.1` — Panel Pengelola Stan

**Target:** pengelola dapat mengelola kondisi stan, menu, dan pesanan melalui UI dummy.  
**Requirement terkait:** FR-09  
**Versi `pubspec.yaml`:** `0.6.0-alpha.1+6`

### A. Dashboard dan menu

- [ ] **UI-601** — Membuat Dashboard “Kantin Hangat” berisi status stan, ringkasan antrean, dan daftar “Perlu tindakan”.
- [ ] **UI-602** — Membuat aksi ubah status stan buka/tutup.
- [ ] **UI-603** — Membuat Kelola Menu dengan foto, harga, estimasi, dan switch tersedia/habis.
- [ ] **UI-604** — Membuat aksi ubah menu tersedia/habis.
- [ ] **UI-605** — Membuat aksi ubah estimasi waktu penyajian.
- [ ] **UI-606** — Menampilkan konfirmasi dan feedback untuk setiap perubahan.
- [ ] **UI-607** — Memastikan pengelola dummy hanya melihat data stannya sendiri.

### B. Pengelolaan pesanan

- [ ] **UI-608** — Membuat Pesanan Masuk dengan informasi nomor, mahasiswa, jumlah item, total, dan waktu tunggu.
- [ ] **UI-609** — Membuat filter/tab Baru, Diproses, dan Siap.
- [ ] **UI-610** — Membuat Detail Pesanan berisi item, catatan, total, label bayar di konter, dan aksi status.
- [ ] **UI-611** — Membuat aksi terima pesanan.
- [ ] **UI-612** — Membuat aksi tolak pesanan dan input alasan wajib.
- [ ] **UI-613** — Membuat aksi ubah status ke Diproses, Siap Diambil, dan Selesai.
- [ ] **UI-614** — Menonaktifkan aksi yang tidak sesuai dengan status saat ini.
- [ ] **UI-615** — Menampilkan dialog konfirmasi untuk perubahan status penting.
- [ ] **UI-616** — Memastikan perubahan pada mode pengelola terlihat pada mode mahasiswa melalui fake repository yang sama.

### C. Pengujian

- [ ] **UI-617** — Menguji pembatasan data berdasarkan stan/peran dummy.
- [ ] **UI-618** — Menguji alasan penolakan wajib diisi.
- [ ] **UI-619** — Menguji transisi status valid dan tidak valid.
- [ ] **UI-620** — Menguji perubahan ketersediaan menu tampil pada katalog mahasiswa.
- [ ] **UI-621** — Membuat widget test alur pesanan masuk sampai selesai.

### D. Kesesuaian visual

- [ ] **UI-622** — Membuat navigation bar pengelola: Dashboard—Pesanan—Menu—Profil.
- [ ] **UI-623** — Memastikan UI pengelola memakai token dan shared component yang sama dengan UI mahasiswa.
- [ ] **UI-624** — Memastikan tidak ada grafik penjualan, promo, multi-stan, delivery, atau fitur di luar baseline.
- [ ] **UI-625** — Membandingkan screenshot empat layar pengelola dengan mockup pada lebar 390 dp.

### Branch yang disarankan

- [ ] `feat/vendor-dashboard`
- [ ] `feat/stall-operating-status`
- [ ] `feat/menu-availability`
- [ ] `feat/vendor-order-status`
- [ ] `test/vendor-flow`

### Release gate `v0.6.0-alpha.1`

- [ ] Pengelola hanya melihat dan mengubah data stannya.
- [ ] Pesanan dapat diterima, ditolak, diproses, disiapkan, dan diselesaikan.
- [ ] Transisi status yang tidak valid tidak dapat dilakukan.
- [ ] Perubahan dummy terlihat konsisten di UI mahasiswa dan pengelola.
- [ ] Dashboard, Pesanan Masuk, Detail Pesanan, dan Kelola Menu sesuai mockup “Kantin Hangat”.
- [ ] Navigation bar dan seluruh status pengelola memakai design system yang sama dengan mahasiswa.
- [ ] Format, analyze, dan seluruh test berhasil.
- [ ] Semua pull request milestone sudah di-review dan di-merge.
- [ ] `CHANGELOG.md` telah diperbarui.
- [ ] Versi `pubspec.yaml` sudah `0.6.0-alpha.1+6`.
- [ ] Tag `v0.6.0-alpha.1` dibuat dan di-push.

---

## `v0.7.0-beta.1` — Notifikasi Android dan Demo UI Lengkap

**Target:** seluruh UI dapat didemonstrasikan end-to-end tanpa backend dan menggunakan satu Android API.  
**Requirement terkait:** FR-10 dan pemetaan komponen Android  
**Versi `pubspec.yaml`:** `0.7.0-beta.1+7`

### A. Notifikasi lokal Android

- [ ] **UI-701** — Menentukan pesan notifikasi untuk status Siap Diambil dan Ditolak.
- [ ] **UI-702** — Membuat `NotificationChannel` untuk status pesanan.
- [ ] **UI-703** — Menambahkan permission notifikasi yang diperlukan pada Android.
- [ ] **UI-704** — Meminta `POST_NOTIFICATIONS` hanya pada Android 13 atau lebih baru.
- [ ] **UI-705** — Menjelaskan manfaat notifikasi sebelum meminta izin jika diperlukan.
- [ ] **UI-706** — Menampilkan notifikasi lokal saat simulasi status menjadi Siap Diambil.
- [ ] **UI-707** — Menampilkan notifikasi lokal saat simulasi status menjadi Ditolak.
- [ ] **UI-708** — Membuat ketukan notifikasi membuka detail pesanan yang benar.
- [ ] **UI-709** — Menjaga status pesanan tetap terlihat di aplikasi ketika izin ditolak.
- [ ] **UI-710** — Membuat abstraction agar notifikasi lokal kelak dapat diganti/ditambah FCM.

### B. Polishing seluruh UI

- [ ] **UI-711** — Memeriksa seluruh layar terhadap token warna, tipografi, spacing, radius, ikon, tombol, dan dialog “Kantin Hangat”.
- [ ] **UI-712** — Memeriksa seluruh loading, empty, error, retry, dan success state.
- [ ] **UI-713** — Memastikan tidak ada loading tanpa batas.
- [ ] **UI-714** — Memastikan tidak ada overflow pada lebar 360, 390, dan 412 dp.
- [ ] **UI-715** — Memastikan keyboard tidak menutupi input penting.
- [ ] **UI-716** — Menambahkan label semantic pada aksi dan ikon penting.
- [ ] **UI-717** — Memeriksa kontras teks normal minimal 4.5:1, target sentuh 48 × 48 dp, dan keterbacaan ketika text scale diperbesar.
- [ ] **UI-718** — Memastikan format Rupiah, waktu, dan status konsisten.
- [ ] **UI-719** — Menghapus tombol/halaman placeholder yang tidak digunakan dalam demo.
- [ ] **UI-720** — Memastikan mode demo tidak membutuhkan koneksi internet.

### C. Skenario demo dan pengujian

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

### D. Visual QA final

- [ ] **UI-733** — Memastikan tidak ada warna/text style/spacing/radius utama yang hard-coded berulang di feature widget.
- [ ] **UI-734** — Memastikan foto tidak terdistorsi dan seluruh ikon memakai Material Symbols Rounded.
- [ ] **UI-735** — Melakukan visual QA dengan screenshot side-by-side terhadap seluruh mockup mahasiswa dan pengelola.

### Branch yang disarankan

- [ ] `feat/android-notification`
- [ ] `feat/notification-permission`
- [ ] `feat/order-deep-link`
- [ ] `test/notification-fallback`
- [ ] `fix/ui-polish`
- [ ] `docs/demo-scenario`

### Release gate `v0.7.0-beta.1`

- [ ] UI mahasiswa berjalan dari katalog/AI sampai status pesanan.
- [ ] UI pengelola berjalan dari pesanan masuk sampai pesanan selesai.
- [ ] Seluruh layar mahasiswa dan pengelola konsisten dengan [`DESIGN_SYSTEM.md`](../design/DESIGN_SYSTEM.md).
- [ ] Semua data dummy diakses melalui repository/service abstraction.
- [ ] Notifikasi Android dapat didemonstrasikan pada emulator/perangkat.
- [ ] Penolakan permission tidak merusak alur aplikasi.
- [ ] Demo dapat dilakukan tanpa backend dan tanpa internet.
- [ ] Visual QA tidak memiliki temuan blocker/major dan bukti screenshot tersedia.
- [ ] Tidak ada overflow pada lebar target; harga/total tetap terbaca saat text scale diperbesar.
- [ ] `dart format --set-exit-if-changed .` berhasil.
- [ ] `flutter analyze` berhasil tanpa error.
- [ ] `flutter test` berhasil seluruhnya.
- [ ] `flutter build apk --release` berhasil.
- [ ] Seluruh bug blocker/critical sudah ditutup.
- [ ] Semua pull request milestone sudah di-review dan di-merge.
- [ ] `CHANGELOG.md` dan petunjuk demo telah diperbarui.
- [ ] Versi `pubspec.yaml` sudah `0.7.0-beta.1+7`.
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
- [ ] Acuan layar/komponen pada design system sudah ditentukan
- [ ] Loading/error/empty/success ditangani jika relevan
- [ ] Test ditambahkan atau diperbarui
- [ ] Screenshot/video hasil lebar 390 dp disiapkan

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
- [ ] Shared component dan token “Kantin Hangat” digunakan
- [ ] Tidak ada warning/error analyzer baru
- [ ] Test relevan berhasil
- [ ] Screenshot/video UI dan acuan mockup dilampirkan
- [ ] Penyimpangan dari mockup dijelaskan dan disetujui
- [ ] Requirement atau issue terkait ditulis

## Pemeriksaan reviewer
- [ ] Acceptance criteria sudah terpenuhi
- [ ] Navigasi dan state tidak rusak
- [ ] Loading, error, empty, dan success state ditangani
- [ ] UI sesuai [`DESIGN_SYSTEM.md`](../design/DESIGN_SYSTEM.md) dan struktur mockup terpilih
- [ ] UI tetap terbaca pada lebar 360/390/412 dp dan saat text scale diperbesar
- [ ] Target sentuh minimal 48 × 48 dp dan warna bukan satu-satunya penanda status
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
fix(ui): prevent menu card overflow
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
- [ ] Seluruh layar mahasiswa dan pengelola mengikuti baseline “Kantin Hangat”.
- [ ] Tidak ada token visual utama yang hard-coded berulang di feature widget.
- [ ] Visual QA terhadap mockup lulus tanpa temuan blocker/major.
- [ ] Screenshot lebar 390 dp tersedia untuk seluruh layar utama.
- [ ] Pemeriksaan lebar 360/390/412 dp dan text scale telah dilakukan.
- [ ] Asisten Pilih Menu memiliki alur lengkap menggunakan fake service.
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
