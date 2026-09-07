# Roadmap Implementasi — KantinCerdas

**Target akhir: KantinCerdasv1.0.0 — Flutter UI Demo**  
**Baseline: KC-DS-20260906 — LOCKED**  
**Tanggal: 6 September 2026 · Semua versi masih target, belum dirilis.**

Roadmap ini memecah 88 referensi menjadi **644 task yang dapat ditugaskan sendiri-sendiri**: 525 task referensi desain dan 119 task engineering/data/logika/QA/rilis. Satu anggota dapat mengambil tugas tombol pencarian tanpa mengambil seluruh halaman Beranda. Tidak ada nama anggota, nomor Issue, atau status selesai yang dikarang.

Gunakan [SRS_KantinCerdasv1.0.0.md](SRS_KantinCerdasv1.0.0.md) untuk aturan bisnis dan acceptance lengkap. Gunakan [README.md](../README.md) untuk orientasi repository. Bagian per-screen pada SRS memakai nomor subrequirement yang sama dengan nomor task layar, sehingga `KC-M01-02` dapat ditelusuri ke `FR-M01.02`.

## Cara memakai roadmap bersama teman

1. Pilih **satu task**, periksa dependensi bagian, lalu isi PIC sebelum mulai agar tidak diambil dua orang.
2. Buat GitHub Issue dengan judul `[KC-M01-02] Menambahkan kolom pencarian beranda` dan milestone versi yang tertera.
3. Isi tautan Issue pada task. Ubah `Status: TODO` menjadi `IN_PROGRESS`.
4. Buat branch singkat, misalnya `feat/kc-m01-02-home-search`.
5. Kerjakan aksi yang ditugaskan. Pakai komponen bersama yang sudah ada; jangan mendesain ulang.
6. Buka PR, tautkan Issue dan task ID, lalu ubah status menjadi `IN_REVIEW`.
7. Reviewer memeriksa kriteria selesai, aturan bisnis terkait, dan screenshot bila tampilan berubah.
8. Setelah merge dan pemeriksaan lulus, ubah menjadi `DONE` dan centang `[x]`. Jika menunggu keputusan, gunakan `BLOCKED` dan tulis D-ID.

**PIC** adalah satu orang yang bertanggung jawab; teman lain boleh membantu. **Issue** berisi uraian kerja aktual, **PR** berisi perubahan yang direview. Isi `—` berarti belum ditugaskan/belum dibuat, bukan informasi hilang yang harus ditebak.

| Status | Kapan dipakai | Checklist |
| --- | --- | --- |
| ![TODO](https://img.shields.io/badge/TODO-6B7280?style=flat-square) | Belum dimulai | ![TODO](https://img.shields.io/badge/%5BTODO%5D-6B7280?style=flat-square) |
| ![IN_PROGRESS](https://img.shields.io/badge/IN_PROGRESS-A16207?style=flat-square) | Sedang dikerjakan | ![DONE](https://img.shields.io/badge/%5BIN_PROGRESS%5D-A16207?style=flat-square) |
| ![BLOCKED](https://img.shields.io/badge/BLOCKED-B91C1C?style=flat-square) | Menunggu dependensi atau keputusan | ![BLOCKED](https://img.shields.io/badge/%5BBLOCKED%5D-B91C1C?style=flat-square) |
| ![IN_REVIEW](https://img.shields.io/badge/IN_REVIEW-7E22CE?style=flat-square) | PR menunggu pemeriksaan | ![IN_REVIEW](https://img.shields.io/badge/%5BIN_REVIEW%5D-7E22CE?style=flat-square) |
| ![DONE](https://img.shields.io/badge/DONE-166534?style=flat-square) | Sudah merge dan kriteria selesai terpenuhi | ![DONE](https://img.shields.io/badge/%5BDONE%5D-166534?style=flat-square) |

Untuk laporan kemajuan versi, hitung `DONE / seluruh task milestone × 100%`. Task BLOCKED tetap masuk penyebut. Jumlah task bukan estimasi jam atau persentase bobot usaha: tombol sederhana dan logika idempotency tidak memiliki biaya yang sama.

## Granularitas dan dependensi

- Satu task menghasilkan satu kontrol, satu perilaku, satu model, satu aturan, atau satu bukti pemeriksaan yang jelas.
- Tidak ada task “mengerjakan seluruh halaman Beranda beserta semua tombol”. Halaman adalah judul pengelompokan.
- Membangun komponen bersama dan memasangnya di halaman adalah tugas berbeda. Jangan menduplikasi widget karena task dikerjakan anggota berbeda.
- Urutan dalam satu bagian adalah panduan, bukan klaim semua task harus serial. Ambil task setelah komponen/model yang dipakainya tersedia.
- Dependensi tingkat bagian tercantum di setiap kelompok. Jika implementasi menemukan dependensi task yang lebih spesifik, tambahkan ID pada `Dependensi tambahan` di Issue.
- Untuk task layar: model/komponen didahulukan; render kontrol sebelum menghubungkan callback; handler repository sebelum mengklaim interaksi lulus; screenshot setelah komposisi tersedia.
- S dan Q adalah varian dari halaman yang sama. Jangan membuat 88 class screen yang masing-masing menyimpan cart/order sendiri.
- Tugas D-ID membutuhkan keputusan manusia yang ditulis, bukan pekerjaan mengubah gambar secara sepihak. Tim boleh menyelesaikannya lebih awal dari milestone QA untuk membuka task yang bergantung padanya.

## Conventional Commits

```text
feat: add menu search interface
fix: correct cart total calculation
docs: clarify preorder scope
chore: configure Flutter CI
test: add order status widget test
```

Contoh di atas dipertahankan sesuai permintaan pengguna. Untuk perubahan workflow CI berikutnya, tim menggunakan `ci` agar dapat dibedakan dari pemeliharaan umum `chore`.

| Jenis | Pemakaian |
| --- | --- |
| feat | Fitur/perilaku baru |
| fix | Perbaikan bug |
| docs | Perubahan dokumentasi |
| style | Format tanpa mengubah perilaku |
| refactor | Restrukturisasi tanpa fitur baru atau perbaikan bug |
| test | Menambah/mengubah test |
| chore | Konfigurasi dan pemeliharaan umum |
| ci | Perubahan workflow CI |

Format: `type(optional-scope): deskripsi singkat`. Scope opsional dapat berupa `catalog`, `cart`, `orders`, `manager`, atau `design-system`. Pakai kalimat deskriptif; `feat: update` terlalu kabur. Perubahan layout/perilaku bukan otomatis `style`; perbaikan tampilan yang salah adalah `fix`, penambahan UI adalah `feat`.

```text
feat(catalog): add home search field

Task: KC-M01-02
Refs: #<nomor-issue>
```

Nomor Issue adalah placeholder yang diisi setelah dibuat. Satu task idealnya satu PR kecil; beberapa task yang tidak dapat diuji terpisah boleh satu PR dengan semua ID dicantumkan. Satu commit tidak wajib sama dengan satu patch file. Conventional Commits mengatur pesan commit; **tidak berarti setiap `feat` harus membuat tag rilis baru**. Format standar merujuk [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/).

## Aturan versi dan rilis

| Elemen | Contoh | Arti |
| --- | --- | --- |
| Nama milestone/tag proyek | `KantinCerdasv0.4.0` | Milestone cart demo |
| Nilai version aplikasi | `0.4.0+4` | Contoh versi + build number pada pubspec; angka build harus benar-benar naik |
| Versi dokumen | `1.0` | Edisi SRS/roadmap; tidak menyatakan aplikasi v1 telah jadi |
| Baseline desain | `KC-DS-20260906` | Tetap sama selama desain locked |

- `0.x.0`: milestone pengembangan awal dengan scope bertahap. Halaman yang terhubung ke milestone berikutnya belum dianggap flow lengkap.
- `0.x.1`, `0.x.2`: perbaikan pada milestone yang sudah dirilis, bila diperlukan; tidak dijadwalkan sebagai fitur baru.
- `1.0.0`: seluruh scope UI demo selesai, keputusan yang menghalangi sudah ditutup, dan gate rilis terpenuhi.
- Sesudah 1.0.0, perubahan kompatibel dapat menjadi minor; bug fix menjadi patch; perubahan yang merusak kontrak yang disepakati menjadi major. Backend tidak otomatis diberi versi 2.0.0 sebelum scope dan dampaknya diketahui.
- Tag hanya dibuat dari commit yang diverifikasi. Tag yang sudah dipublikasikan tidak dipindahkan; koreksi mendapat versi baru.

Kebijakan major/minor/patch diadaptasi dari [Semantic Versioning](https://semver.org/); prefix `KantinCerdas` adalah pilihan penamaan tag tim.

## Template Issue yang bisa disalin

```markdown
## Identitas
Task ID: KC-M01-02
Judul: Menambahkan kolom pencarian beranda
Milestone: KantinCerdasv0.2.0
PIC: <nama anggota>
Reviewer: <nama teman>
Status: TODO
Desain: M01
Requirement: FR-M01.02
Dependensi tambahan: <task ID atau tidak ada>

## Tujuan
Pengguna dapat membuka pencarian dari Beranda.

## Batas pekerjaan
Memasang field pencarian sesuai baseline dan menghubungkan route M04.

## Kriteria selesai
- [ ] Teks, ikon, ukuran, dan posisi mengikuti M01.
- [ ] Tap membuka M04 dengan fokus field.
- [ ] Kembali mempertahankan state Beranda dan cart.
- [ ] Screenshot diperiksa pada viewport baseline.

## Bukti
PR: <tautan>
Screenshot: <tautan>
Pemeriksaan yang dijalankan: <perintah atau langkah manual dan hasil aktual>
Keputusan/blocker: <D-ID bila ada>
```

## Template PR yang bisa disalin

```markdown
## Masalah dan perubahan
<Mengapa task dibutuhkan dan apa yang kini dapat dilakukan pengguna.>

## Pelacakan
Task: <task ID>
Issue: <tautan>
Milestone: <versi>
Desain: <ID layar>

## Pemeriksaan
<Pemeriksaan aktual, hasil, serta screenshot sebelum/sesudah bila relevan.>

## Catatan reviewer
<Keputusan teknis, batas, atau dependensi yang benar-benar relevan.>
```

## Definition of Done setiap task

Kriteria selesai spesifik di task terpenuhi; state berasal dari sumber yang tepat; kasus tepi yang relevan ditangani; baseline tidak berubah; kode mengikuti konvensi proyek; format/analyzer dan test relevan lulus; bukti visual tersedia untuk perubahan UI; PR telah direview dan merge. Task dokumentasi tidak membutuhkan test Flutter, tetapi tautan, ID, dan isi harus diperiksa. Task tombol sederhana tidak membutuhkan test yang hanya mengulang label implementasi.

## Ringkasan milestone

| Target versi | Fokus | Referensi utama | Task |
| --- | --- | --- | ---: |
| [KantinCerdasv0.1.0](#release-0-1-0) | Fondasi Flutter, data dummy, dan design system | F00 | 91 |
| [KantinCerdasv0.2.0](#release-0-2-0) | Katalog mahasiswa | M01, M04–M06, M08 | 51 |
| [KantinCerdasv0.3.0](#release-0-3-0) | Asisten dan rekomendasi dummy | M02, M10–M13, M15–M16 | 36 |
| [KantinCerdasv0.4.0](#release-0-4-0) | Keranjang dan integrasi lintas katalog | M03, M07, M09, M14, M17–M23 | 77 |
| [KantinCerdasv0.5.0](#release-0-5-0) | Checkout dan pesanan mahasiswa | M24–M35 | 80 |
| [KantinCerdasv0.6.0](#release-0-6-0) | Dashboard dan order pengelola | P01–P14 | 99 |
| [KantinCerdasv0.7.0](#release-0-7-0) | Menu, pengaturan, profil, dan pendukung | M36–M37, P15–P18, U01–U09 | 82 |
| [KantinCerdasv0.8.0](#release-0-8-0) | Kondisi sistem dan pemulihan | S01–S17 | 70 |
| [KantinCerdasv0.9.0](#release-0-9-0) | Responsif, aksesibilitas, dan verifikasi | Q01–Q06 + review seluruh referensi | 46 |
| [KantinCerdasv1.0.0](#release-1-0-0) | Flutter UI Demo lengkap | Seluruh scope | 12 |


## Checklist detail per versi

Semua kotak di bawah sengaja belum dicentang. Target versi pada setiap kelompok berlaku untuk **seluruh task di dalamnya**. Pengelompokan layar mengikuti nomor referensi asli, bukan usulan desain baru.


<a id="release-0-1-0"></a>

## KantinCerdasv0.1.0 — Fondasi Flutter, data dummy, dan design system

**Target:** 91 task · **Gate milestone:** Komponen/model tersedia, kedua entry point membuka shell, perintah kualitas scaffold dapat dijalankan.

### ENG — Bootstrap proyek dan kerja tim

**Versi:** KantinCerdasv0.1.0 · **Dependensi bagian:** Tidak ada; mulai dari paket dokumen ini.

- ![DONE](https://img.shields.io/badge/%5BDONE%5D-166534?style=flat-square) **KC-ENG-01** · `chore` · Membuat proyek Flutter Android
  - **Selesai jika:** pubspec.yaml dan struktur Android tersedia; nama aplikasi KantinCerdas.
  - PIC: Doni · Status: ![DONE](https://img.shields.io/badge/DONE-166534?style=flat-square) · Issue: #1 · PR: #1

- ![DONE](https://img.shields.io/badge/%5BDONE%5D-166534?style=flat-square) **KC-ENG-02** · `chore` · Memilih dan mencatat Flutter SDK
  - **Selesai jika:** Versi konkret berhasil menjalankan proyek awal; pin dicatat dalam repository.
  - PIC: Doni · Status: ![DONE](https://img.shields.io/badge/DONE-166534?style=flat-square) · Issue: #5 · PR: #5

- [x] **KC-ENG-03** · `chore` · Menyimpan pubspec.lock aplikasi
  - **Selesai jika:** Resolusi dependency aplikasi tercatat dan tidak diabaikan Git.
  - PIC: Doni · Status: ![DONE](https://img.shields.io/badge/DONE-166534?style=flat-square)  · Issue: — · PR: —

- [x] **KC-ENG-04** · `chore` · Menyiapkan flutter_lints
  - **Selesai jika:** flutter analyze dapat dijalankan pada scaffold.
  - PIC: Doni · Status: ![DONE](https://img.shields.io/badge/DONE-166534?style=flat-square)  · Issue: — · PR: —

- [x] **KC-ENG-05** · `chore` · Menyiapkan gitignore Flutter
  - **Selesai jika:** Build output dan konfigurasi mesin tidak dilacak.
  - PIC: Doni · Status: ![DONE](https://img.shields.io/badge/DONE-166534?style=flat-square)  · Issue: — · PR: —

- ![DONE](https://img.shields.io/badge/%5BDONE%5D-166534?style=flat-square) **KC-ENG-06** · `docs` · Menempatkan SRS di folder docs repository
  - **Selesai jika:** SRS.md dapat dibaca dan tautan relatifnya benar.
  - PIC: Doni · Status: ![DONE](https://img.shields.io/badge/DONE-166534?style=flat-square) · Issue: #2 · PR: #2

- ![DONE](https://img.shields.io/badge/%5BDONE%5D-166534?style=flat-square) **KC-ENG-07** · `docs` · Menempatkan ROADMAP folder docs repository
  - **Selesai jika:** Task ID tetap utuh saat dimigrasikan ke Issues.
  - PIC: Doni · Status: ![DONE](https://img.shields.io/badge/DONE-166534?style=flat-square)  · Issue: #3 · PR: #3

- ![DONE](https://img.shields.io/badge/%5BDONE%5D-166534?style=flat-square) **KC-ENG-08** · `docs` · Menempatkan README root repository
  - **Selesai jika:** Status proyek disesuaikan dengan implementasi aktual.
  - PIC: — · Status: ![DONE](https://img.shields.io/badge/DONE-166534?style=flat-square)  · Issue: #4 · PR: #4

- [ ] **KC-ENG-09** · `chore` · Menyalin baseline desain immutable
  - **Selesai jika:** 107 file sumber sesuai hash manifest.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-ENG-10** · `chore` · Membuat entry point mahasiswa
  - **Selesai jika:** main_student.dart membuka shell mahasiswa dengan fake session.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-ENG-11** · `chore` · Membuat entry point pengelola
  - **Selesai jika:** main_manager.dart membuka shell pengelola dengan fake session.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-ENG-12** · `refactor` · Menyiapkan composition root
  - **Selesai jika:** Repository diinjeksi melalui constructor.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-ENG-13** · `feat` · Membuat state session demo
  - **Selesai jika:** Peran dan scope pengguna dapat dibaca tanpa backend.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-ENG-14** · `feat` · Membuat route registry
  - **Selesai jika:** Route dan parameter ID terpusat; unknown ID ditangani sesuai D-09.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-ENG-15** · `ci` · Menambahkan pemeriksaan format
  - **Selesai jika:** CI gagal jika dart format menemukan perubahan format.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-ENG-16** · `ci` · Menambahkan pemeriksaan analyzer
  - **Selesai jika:** CI menjalankan flutter analyze pada SDK yang dipin.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-ENG-17** · `ci` · Menambahkan job pengujian
  - **Selesai jika:** CI menjalankan test yang tersedia tanpa membuat klaim coverage palsu.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-ENG-18** · `ci` · Menambahkan build Android demo
  - **Selesai jika:** Job membangun debug APK untuk kedua entry point dari commit PR.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-ENG-19** · `chore` · Membuat template Issue tugas
  - **Selesai jika:** Field task ID, milestone, PIC, acceptance, dependensi tersedia.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-ENG-20** · `chore` · Membuat template PR
  - **Selesai jika:** Ada task ID, perubahan, verifikasi, dan screenshot untuk perubahan UI.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-ENG-21** · `chore` · Membuat milestone versi
  - **Selesai jika:** Milestone 0.1.0 sampai 1.0.0 sesuai roadmap; belum berarti tag dibuat.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-ENG-22** · `chore` · Menyiapkan aturan review tim
  - **Selesai jika:** PR ke main dengan satu reviewer rekan; kemampuan GitHub diperiksa saat repository tersedia.
  - PIC: — · Status: TODO · Issue: — · PR: —

### DATA — Model, fixture, dan repository dummy

**Versi:** KantinCerdasv0.1.0 · **Dependensi bagian:** KC-ENG-01, KC-ENG-12; dapat paralel secara pembagian anggota dengan F00.

- [ ] **KC-DATA-01** · `feat` · Membuat model UserProfile
  - **Selesai jika:** Role mahasiswa/pengelola dan stallId dimodelkan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-DATA-02** · `feat` · Membuat model Stall
  - **Selesai jika:** Status manual terpisah dari jadwal informasi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-DATA-03** · `feat` · Membuat model MenuItem
  - **Selesai jika:** Harga integer dan availability enum tersedia.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-DATA-04** · `feat` · Membuat model CatalogFilter
  - **Selesai jika:** Query, kategori, harga, waktu, availability, scope stan tersedia.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-DATA-05** · `feat` · Membuat model CartLine
  - **Selesai jika:** Quantity positif dan catatan item terpisah.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-DATA-06** · `feat` · Membuat model Cart
  - **Selesai jika:** StallId tunggal, catatan order, revision tersedia.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-DATA-07** · `feat` · Membuat model Order
  - **Selesai jika:** Snapshot item, pembayaran, waktu event, version tersedia.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-DATA-08** · `feat` · Membuat enum status order
  - **Selesai jika:** Lima status bisnis dipisah dari status submission.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-DATA-09** · `feat` · Membuat model Submission
  - **Selesai jika:** ID, revision, snapshot, hasil unknown dapat direpresentasikan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-DATA-10** · `feat` · Membuat model preferensi
  - **Selesai jika:** Harga, waktu, dan selera sesuai A-06.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-DATA-11** · `feat` · Membuat hasil operasi terstruktur
  - **Selesai jika:** Success, empty, offline, known failure, unknown, conflict dapat dibedakan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-DATA-12** · `feat` · Membuat clock demo
  - **Selesai jika:** Waktu fixture dapat dikunci dan diganti test.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-DATA-13** · `feat` · Membuat scheduler latensi dummy
  - **Selesai jika:** Delay dapat dikontrol tanpa sleep nyata pada unit test.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-DATA-14** · `feat` · Membuat DemoStore
  - **Selesai jika:** Satu state bersama untuk repository fake dalam satu proses.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-DATA-15** · `feat` · Menambahkan fixture katalog delapan menu
  - **Selesai jika:** Nama, harga, status, stan, aset cocok dengan SRS.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-DATA-16** · `feat` · Menambahkan fixture profil demo
  - **Selesai jika:** Doni dan Bu Rina tidak memerlukan kredensial.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-DATA-17** · `feat` · Menambahkan fixture antrean awal
  - **Selesai jika:** Enam order aktif cocok dengan P04–P06.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-DATA-18** · `feat` · Menambahkan fixture selesai untuk dashboard
  - **Selesai jika:** 18 order completed tambahan membuat agregasi 24 konsisten.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-DATA-19** · `feat` · Menambahkan fixture riwayat terpisah
  - **Selesai jika:** KC-019 dan KC-018 tidak menggandakan status KC-027.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-DATA-20** · `feat` · Membuat registry skenario
  - **Selesai jika:** Semua 88 ID memiliki key screen_<ID> dan kondisi terukur.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-DATA-21** · `feat` · Membuat reset fixture
  - **Selesai jika:** Reset mengembalikan seed awal dan membuang operasi/undo sebelumnya.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-DATA-22** · `feat` · Membuat gateway izin dummy
  - **Selesai jika:** Unknown, granted, denied bisa disimulasikan tanpa plugin OS.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-DATA-23** · `feat` · Membuat controller koneksi dummy
  - **Selesai jika:** Offline UI dapat dipicu independen dari jaringan nyata.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-DATA-24** · `feat` · Membuat formatter rupiah
  - **Selesai jika:** 18000 tampil Rp18.000, 30000 tampil Rp30.000, tanpa double.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-DATA-25** · `feat` · Membuat formatter waktu demo
  - **Selesai jika:** HH.mm dan tanggal riwayat mengikuti injected clock.
  - PIC: — · Status: TODO · Issue: — · PR: —

### F00 — Fondasi visual dan komponen

**Versi:** KantinCerdasv0.1.0 · **Requirement:** FR-F00 · **[Referensi PNG](../design/baseline/screens/F00_fondasi_visual_dan_komponen.png)**

**Dependensi bagian:** Scaffold ENG; nilai sumber CSS dan F00; D-03 pada metrik konflik.

**Kondisi:** Referensi bersama seluruh layar; bukan halaman pengguna. **Hasil bagian:** Komponen Flutter dapat dipakai ulang tanpa mengganti identitas visual.

- [ ] **KC-F00-01** · `feat` · Mendaftarkan token background
  - **Selesai jika:** Warna latar #FAFAF8 tersedia dalam tema.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-02** · `feat` · Mendaftarkan token surface
  - **Selesai jika:** Warna permukaan #FFFFFF tersedia dalam tema.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-03** · `feat` · Mendaftarkan token surface alternatif
  - **Selesai jika:** Warna #F7F3F0 tersedia dalam tema.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-04** · `feat` · Mendaftarkan token brand
  - **Selesai jika:** Warna #E85D2A dipakai untuk identitas dan FAB.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-05** · `feat` · Mendaftarkan token action
  - **Selesai jika:** Warna #C74418 dipakai untuk aksi utama.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-06** · `feat` · Mendaftarkan token active
  - **Selesai jika:** Warna #9B341B dipakai untuk penanda aktif.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-07** · `feat` · Mendaftarkan token teks
  - **Selesai jika:** Teks utama #251B17 dan sekunder #6D5A50 dapat dirujuk dengan nama semantik.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-08** · `feat` · Mendaftarkan token outline
  - **Selesai jika:** Garis pembatas menggunakan #DDD6D1.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-09** · `feat` · Mendaftarkan token status
  - **Selesai jika:** Pasangan warna teks/latar setiap status mengikuti tabel token SRS.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-10** · `feat` · Mendaftarkan font Plus Jakarta Sans
  - **Selesai jika:** Lima berkas font lokal dikenali sebagai bobot 400, 500, 600, 700, 800.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-11** · `feat` · Mendaftarkan skala tipografi
  - **Selesai jika:** Gaya F00 dan gaya spesifik layar dipisahkan sesuai catatan konflik D-03.
  - PIC: — · Status: BLOCKED · Issue: — · PR: — · Blocker: D-03

- [ ] **KC-F00-12** · `feat` · Mendaftarkan token jarak
  - **Selesai jika:** Grid 8 dp, padding halaman 16 dp, serta pengecualian CSS tercatat.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-13** · `feat` · Mendaftarkan token radius
  - **Selesai jika:** Radius input/tombol 12 dp dan radius atas sheet 24 dp tersedia.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-14** · `feat` · Membuat ikon bersama
  - **Selesai jika:** Bentuk glyph mengikuti SVG app.js, tanpa mengganti keluarga ikon.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-15** · `feat` · Membuat tombol primary
  - **Selesai jika:** Tampilan normal mengikuti F00 dan callback menerima aksi pemanggil.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-16** · `feat` · Membuat tombol secondary
  - **Selesai jika:** Outline dan warna mengikuti F00.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-17** · `feat` · Membuat tombol ghost
  - **Selesai jika:** Aksi sekunder tanpa latar mengikuti sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-18** · `feat` · Membuat tombol destructive
  - **Selesai jika:** Warna merah hanya dipakai untuk tindakan destruktif.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-19** · `feat` · Membuat state disabled tombol
  - **Selesai jika:** Tap tidak memanggil callback ketika disabled.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-20** · `feat` · Membuat state loading tombol
  - **Selesai jika:** Tap ganda dicegah dan label proses ditampilkan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-21** · `feat` · Membuat tombol ikon
  - **Selesai jika:** Nama aksesibel tersedia; area sentuh mengikuti keputusan D-03.
  - PIC: — · Status: BLOCKED · Issue: — · PR: — · Blocker: D-03

- [ ] **KC-F00-22** · `feat` · Membuat input catatan
  - **Selesai jika:** Label tetap ada ketika field berisi teks dan fokus mengikuti sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-23** · `feat` · Membuat chip pilihan
  - **Selesai jika:** State selected menampilkan warna dan tanda centang bila ada di sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-24** · `feat` · Membuat radio pilihan
  - **Selesai jika:** Hanya satu nilai terpilih dalam satu kelompok.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-25** · `feat` · Membuat switch
  - **Selesai jika:** Status aktif dan nonaktif memiliki semantics yang benar.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-26** · `feat` · Membuat badge status
  - **Selesai jika:** Teks status selalu tampil sehingga arti tidak bergantung pada warna.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-27** · `feat` · Membuat row menu
  - **Selesai jika:** Foto, nama, metadata, harga, badge, dan slot aksi mengikuti sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-28** · `feat` · Membuat kontrol jumlah
  - **Selesai jika:** Tombol minus dan plus menerima callback terpisah.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-29** · `feat` · Membuat row stan
  - **Selesai jika:** Nama, lokasi, status, foto, dan arah navigasi mengikuti sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-30** · `feat` · Membuat row pesanan
  - **Selesai jika:** Kode, pemilik/stan, jumlah, nilai, dan status dapat dikonfigurasi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-31** · `feat` · Membuat banner informasi
  - **Selesai jika:** Ikon, judul, isi, dan slot aksi dapat digunakan ulang.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-32** · `feat` · Membuat banner kegagalan
  - **Selesai jika:** Pesan dan aksi pemulihan mengikuti sumber tanpa menghapus konten lama.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-33** · `feat` · Membuat bottom sheet
  - **Selesai jika:** Handle, header, tombol tutup, overlay, dan insets keyboard tersedia.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-34** · `feat` · Membuat dialog konfirmasi
  - **Selesai jika:** Aksi batal dan konfirmasi dibedakan serta dapat diakses lewat Back.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-35** · `feat` · Membuat snackbar undo
  - **Selesai jika:** Callback pemulihan diberikan pemanggil; durasi mengikuti BR-06.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-36** · `feat` · Membuat skeleton row
  - **Selesai jika:** Placeholder mengikuti proporsi S01/S09.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-37** · `feat` · Membuat placeholder foto
  - **Selesai jika:** Kegagalan foto tidak mengubah ukuran row.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-38** · `feat` · Membuat sticky cart
  - **Selesai jika:** Jumlah porsi, total, nama stan, dan aksi keranjang menerima data state.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-39** · `feat` · Membuat FAB asisten
  - **Selesai jika:** Ukuran visual 56 dp dan glyph mengikuti sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-40** · `feat` · Membuat coachmark asisten
  - **Selesai jika:** Callout dan tombol tutup mengikuti M02.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-41** · `feat` · Membuat footer CTA
  - **Selesai jika:** Total dan tombol tidak tertutup safe area perangkat.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-42** · `feat` · Membuat timeline status
  - **Selesai jika:** Tahap dan waktu berasal dari event pesanan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-43** · `feat` · Membuat navigasi mahasiswa
  - **Selesai jika:** Tiga destinasi persis Beranda, Pesanan, Profil.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-F00-44** · `feat` · Membuat navigasi pengelola
  - **Selesai jika:** Empat destinasi persis Dashboard, Pesanan, Menu, Profil.
  - PIC: — · Status: TODO · Issue: — · PR: —


<a id="release-0-2-0"></a>

## KantinCerdasv0.2.0 — Katalog mahasiswa

**Target:** 51 task · **Gate milestone:** Pencarian/filter/detail dapat ditelusuri. Aksi cart penuh menunggu 0.4.0.

### M01 — Beranda, kunjungan kembali

**Versi:** KantinCerdasv0.2.0 · **Requirement:** FR-M01 · **[Referensi PNG](../design/baseline/screens/M01_beranda_kunjungan_kembali.png)**

**Dependensi bagian:** KC-ENG-10; KC-ENG-14; model/fixture DATA; komponen F00.

**Kondisi:** Aplikasi dibuka sebagai mahasiswa; katalog dummy tersedia, cart kosong. **Hasil bagian:** Pengguna dapat menelusuri menu, stan, pencarian, dan destinasi utama.

- [ ] **KC-M01-01** · `feat` · Menampilkan sapaan beranda
  - **Selesai jika:** Kantin Kampus, Halo Doni, dan judul mengikuti fixture M01.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M01-02** · `feat` · Menambahkan kolom pencarian beranda
  - **Selesai jika:** Tap membuka M04 dengan fokus pencarian.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M01-03** · `feat` · Menambahkan chip Semua
  - **Selesai jika:** Memilihnya menghapus pembatas kategori.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M01-04** · `feat` · Menambahkan chip Nasi
  - **Selesai jika:** Memilihnya menyaring kategori Nasi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M01-05** · `feat` · Menambahkan chip Mi
  - **Selesai jika:** Memilihnya menyaring kategori Mi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M01-06** · `feat` · Menambahkan chip Camilan
  - **Selesai jika:** Kategori tanpa data menghasilkan daftar kosong tanpa menu rekaan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M01-07** · `feat` · Menambahkan chip Minuman
  - **Selesai jika:** Memilihnya hanya menampilkan minuman.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M01-08** · `feat` · Menampilkan bagian Cepat jadi
  - **Selesai jika:** Fixture awal menampilkan Nasi Ayam Sambal Matah dan Mi Gomak.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M01-09** · `feat` · Menambahkan tombol Lihat semua
  - **Selesai jika:** Membuka daftar pencarian dengan batas waktu 10 menit; keputusan A-04.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M01-10** · `feat` · Menghubungkan row menu ke detail
  - **Selesai jika:** Tap isi row membuka M08 untuk menu terpilih.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M01-11** · `feat` · Menghubungkan tombol Tambah
  - **Selesai jika:** Menambahkan satu porsi; memilih stan lain memakai aturan BR-01.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M01-12** · `feat` · Menampilkan daftar stan buka
  - **Selesai jika:** Dapur Bu Rina, Kedai Pak Ucok, Warung Sinta beserta bloknya tampil.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M01-13** · `feat` · Menghubungkan row stan ke detail
  - **Selesai jika:** Tap membuka M06 untuk stan terpilih.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M01-14** · `feat` · Menghubungkan tombol Beranda
  - **Selesai jika:** Destinasi aktif tetap Beranda tanpa menumpuk route.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M01-15** · `feat` · Menghubungkan tombol Pesanan
  - **Selesai jika:** Tap membuka M29 tanpa menghapus keranjang.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M01-16** · `feat` · Menghubungkan tombol Profil
  - **Selesai jika:** Tap membuka M36 tanpa menghapus keranjang.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M01-17** · `feat` · Menghubungkan FAB asisten
  - **Selesai jika:** Tap membuka M10 dan mempertahankan konteks beranda.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M04 — Hasil pencarian

**Versi:** KantinCerdasv0.2.0 · **Requirement:** FR-M04 · **[Referensi PNG](../design/baseline/screens/M04_hasil_pencarian.png)**

**Dependensi bagian:** M01; CatalogRepository dan CatalogFilter DATA.

**Kondisi:** Pencarian dibuka dari beranda; fixture kata ayam. **Hasil bagian:** Hasil diperbarui dari katalog lokal sesuai query dan filter yang diterapkan.

- [ ] **KC-M04-01** · `feat` · Menambahkan tombol kembali pencarian
  - **Selesai jika:** Kembali ke sumber tanpa kehilangan cart.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M04-02** · `feat` · Menambahkan field query pencarian
  - **Selesai jika:** Pencarian nama menu/stan memakai trim dan pencocokan tanpa membedakan huruf besar.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M04-03** · `feat` · Menambahkan tombol hapus query
  - **Selesai jika:** Field menjadi kosong dan hasil dihitung ulang.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M04-04** · `feat` · Menampilkan chip filter aktif
  - **Selesai jika:** Fixture Maks. Rp20.000 mengikuti filter yang sudah diterapkan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M04-05** · `feat` · Menambahkan tombol Filter
  - **Selesai jika:** Tap membuka M05 dengan salinan filter aktif.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M04-06** · `feat` · Menampilkan jumlah hasil
  - **Selesai jika:** Fixture awal menghasilkan tiga menu; nilai dihitung dari hasil.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M04-07** · `feat` · Menampilkan hasil menu tersedia
  - **Selesai jika:** Ayam sambal matah dan ayam geprek dapat ditambahkan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M04-08** · `feat` · Menampilkan hasil menu habis
  - **Selesai jika:** Nasi Ayam Kecap tetap terlihat pada fixture M04 dengan tombol Tidak tersedia.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M04-09** · `feat` · Menghubungkan item pencarian ke detail
  - **Selesai jika:** Menu yang dibuka sesuai ID item, bukan selalu ayam sambal matah.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M05 — Filter pencarian

**Versi:** KantinCerdasv0.2.0 · **Requirement:** FR-M05 · **[Referensi PNG](../design/baseline/screens/M05_filter_pencarian.png)**

**Dependensi bagian:** M04; komponen sheet/chip/radio F00.

**Kondisi:** Sheet filter dibuka di atas M04. **Hasil bagian:** Filter berubah hanya setelah diterapkan.

- [ ] **KC-M05-01** · `feat` · Menambahkan kelompok batas harga filter
  - **Selesai jika:** Pilihan Rp15.000, Rp20.000, Tanpa batas bersifat single-select.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M05-02** · `feat` · Menambahkan kelompok waktu tunggu filter
  - **Selesai jika:** Pilihan 10 menit, 20 menit, Tanpa batas bersifat single-select.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M05-03** · `feat` · Menambahkan pilihan hanya menu tersedia
  - **Selesai jika:** Nilai boolean tersimpan dalam draft filter; konflik snapshot D-05 dicatat.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M05-04** · `feat` · Menghubungkan tombol Terapkan filter
  - **Selesai jika:** Draft menjadi filter aktif; sheet tutup; daftar dan jumlah hasil diperbarui.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M05-05** · `feat` · Menghubungkan tombol Reset filter
  - **Selesai jika:** Draft kembali tanpa batas harga/waktu dan semua status; belum diterapkan sampai CTA ditekan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M05-06** · `feat` · Menghubungkan tombol tutup filter
  - **Selesai jika:** Draft dibuang dan hasil sebelumnya tidak berubah.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M06 — Detail stan buka

**Versi:** KantinCerdasv0.2.0 · **Requirement:** FR-M06 · **[Referensi PNG](../design/baseline/screens/M06_detail_stan_buka.png)**

**Dependensi bagian:** M01/M04; fixture stan/menu DATA.

**Kondisi:** Mahasiswa memilih stan yang buka. **Hasil bagian:** Katalog dibatasi pada stan yang dipilih.

- [ ] **KC-M06-01** · `feat` · Menambahkan tombol kembali detail stan
  - **Selesai jika:** Kembali ke daftar sebelumnya.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M06-02** · `feat` · Menampilkan foto stan
  - **Selesai jika:** Aset stan-bu-rina.jpg digunakan pada fixture Bu Rina.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M06-03** · `feat` · Menampilkan identitas stan
  - **Selesai jika:** Nama, lokasi Blok A, deskripsi, estimasi, dan badge Buka sesuai sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M06-04** · `feat` · Menambahkan pencarian dalam stan
  - **Selesai jika:** Query tidak menghasilkan menu milik stan lain.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M06-05** · `feat` · Menambahkan chip Semua dalam stan
  - **Selesai jika:** Semua kategori stan ditampilkan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M06-06** · `feat` · Menambahkan chip Makanan
  - **Selesai jika:** Hanya item makanan stan ditampilkan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M06-07** · `feat` · Menambahkan chip Minuman dalam stan
  - **Selesai jika:** Hanya minuman stan ditampilkan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M06-08** · `feat` · Menampilkan daftar menu stan
  - **Selesai jika:** Lima menu Bu Rina tersedia dalam data dan dapat dijangkau dengan scroll.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M06-09** · `feat` · Menghubungkan tombol Tambah pada stan
  - **Selesai jika:** Satu porsi masuk cart dan row berubah ke kontrol jumlah.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M06-10** · `feat` · Menghubungkan foto atau nama menu ke detail
  - **Selesai jika:** M08 memakai ID menu terpilih.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M06-11** · `feat` · Menghubungkan FAB dari detail stan
  - **Selesai jika:** Asisten tetap mengetahui cart dan konteks stan.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M08 — Detail menu

**Versi:** KantinCerdasv0.2.0 · **Requirement:** FR-M08 · **[Referensi PNG](../design/baseline/screens/M08_detail_menu.png)**

**Dependensi bagian:** M06/M04; model MenuItem dan input F00.

**Kondisi:** Mahasiswa membuka menu tersedia. **Hasil bagian:** Detail menyediakan draft jumlah/catatan; commit cart diselesaikan pada v0.4.0.

- [ ] **KC-M08-01** · `feat` · Menambahkan tombol kembali detail menu
  - **Selesai jika:** Draft yang belum ditambahkan tidak mengubah cart.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M08-02** · `feat` · Menampilkan foto besar menu
  - **Selesai jika:** Fixture memakai nasi-ayam-sambal-matah.jpg.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M08-03** · `feat` · Menampilkan informasi menu
  - **Selesai jika:** Nama, stan, estimasi, ketersediaan, harga, deskripsi mengikuti menu terpilih.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M08-04** · `feat` · Menambahkan input catatan item
  - **Selesai jika:** Opsional, nilai dipertahankan selama detail aktif.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M08-05** · `feat` · Menambahkan tombol plus jumlah detail
  - **Selesai jika:** Draft bertambah satu; harga total draft ikut berubah.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M08-06** · `feat` · Menambahkan tombol minus jumlah detail
  - **Selesai jika:** Draft minimal satu dan tidak menghapus item cart yang sudah ada.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M08-07** · `feat` · Menampilkan total draft detail
  - **Selesai jika:** Jumlah dikali harga integer rupiah.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M08-08** · `feat` · Menambahkan tombol Tambah ke keranjang
  - **Selesai jika:** Komponen siap menerima handler CartRepository pada milestone v0.4.0.
  - PIC: — · Status: TODO · Issue: — · PR: —


<a id="release-0-3-0"></a>

## KantinCerdasv0.3.0 — Asisten dan rekomendasi dummy

**Target:** 36 task · **Gate milestone:** Input, klarifikasi, sukses, kosong, retry/manual search dapat didemokan.

### M02 — Pengenalan asisten

**Versi:** KantinCerdasv0.3.0 · **Requirement:** FR-M02 · **[Referensi PNG](../design/baseline/screens/M02_pengenalan_asisten.png)**

**Dependensi bagian:** M01 dan F00 coachmark/FAB.

**Kondisi:** Mahasiswa pertama kali melihat asisten dalam sesi demo. **Hasil bagian:** Coachmark dapat ditutup tanpa menghalangi pemesanan.

- [ ] **KC-M02-01** · `feat` · Menampilkan teks pengenalan asisten
  - **Selesai jika:** Bingung pilih? dan Aku bantu cari menu. mengikuti referensi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M02-02** · `feat` · Menambahkan tombol tutup coachmark
  - **Selesai jika:** Tap menyembunyikan callout tanpa membuka asisten.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M02-03** · `feat` · Menyimpan status coachmark sesi
  - **Selesai jika:** Navigasi kembali tidak menampilkan callout yang telah ditutup; restart mereset sesuai A-02.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M02-04** · `feat` · Menempatkan coachmark di dekat FAB
  - **Selesai jika:** Tidak menutupi tombol navigasi atau sticky cart.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M10 — Asisten pilih menu

**Versi:** KantinCerdasv0.3.0 · **Requirement:** FR-M10 · **[Referensi PNG](../design/baseline/screens/M10_asisten_pilih_menu.png)**

**Dependensi bagian:** M01; RecommendationRepository; komponen sheet F00.

**Kondisi:** FAB asisten dipilih; mode online simulasi aktif. **Hasil bagian:** Asisten dummy menghasilkan rekomendasi deterministik.

- [ ] **KC-M10-01** · `feat` · Menambahkan tombol tutup asisten
  - **Selesai jika:** Sheet tutup dan konteks halaman asal tetap tersedia.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M10-02** · `feat` · Menambahkan pilihan harga asisten
  - **Selesai jika:** Rp15.000, Rp20.000, Tanpa batas dapat dipilih.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M10-03** · `feat` · Menambahkan pilihan waktu asisten
  - **Selesai jika:** 10 menit, 20 menit, Tanpa batas dapat dipilih.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M10-04** · `feat` · Menambahkan pilihan selera asisten
  - **Selesai jika:** Tidak pedas, Pakai nasi, Berkuah mengikuti sumber dan aturan A-06.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M10-05** · `feat` · Menambahkan input kebutuhan tambahan
  - **Selesai jika:** Teks bebas disimpan sebagai input dummy; tidak dikirim ke AI eksternal.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M10-06** · `feat` · Menghubungkan tombol Cari rekomendasi
  - **Selesai jika:** Query lengkap membuka M13; fixture ambigu membuka M12.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M10-07** · `feat` · Menghubungkan tombol Nanti saja
  - **Selesai jika:** Menutup sheet tanpa membuat pesanan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M10-08** · `feat` · Mengisi pilihan awal dari preferensi
  - **Selesai jika:** Nilai terakhir yang tersimpan dalam sesi mengisi draft asisten.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M11 — Asisten dengan keyboard

**Versi:** KantinCerdasv0.3.0 · **Requirement:** FR-M11 · **[Referensi PNG](../design/baseline/screens/M11_asisten_dengan_keyboard.png)**

**Dependensi bagian:** M10; dukungan input/fokus Flutter.

**Kondisi:** Field kebutuhan tambahan memperoleh fokus. **Hasil bagian:** Input dan aksi utama tetap dapat dijangkau ketika keyboard terbuka.

- [ ] **KC-M11-01** · `feat` · Memfokuskan input kebutuhan
  - **Selesai jika:** Keyboard perangkat asli terbuka pada Flutter.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M11-02** · `feat` · Menyesuaikan inset sheet asisten
  - **Selesai jika:** Sheet mengikuti tinggi keyboard tanpa menyalin gambar keyboard HTML.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M11-03** · `feat` · Mempertahankan teks saat keyboard ditutup
  - **Selesai jika:** Input Ingin makan sebelum kelas tidak hilang.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M11-04** · `feat` · Membuat isi sheet asisten dapat digulir
  - **Selesai jika:** Aksi Cari rekomendasi dan Nanti saja dapat dijangkau; lihat D-02.
  - PIC: — · Status: BLOCKED · Issue: — · PR: — · Blocker: D-02

### M12 — Asisten meminta klarifikasi

**Versi:** KantinCerdasv0.3.0 · **Requirement:** FR-M12 · **[Referensi PNG](../design/baseline/screens/M12_asisten_meminta_klarifikasi.png)**

**Dependensi bagian:** M10; hasil clarificationNeeded.

**Kondisi:** Skenario ambigu: Yang murah dan cepat. **Hasil bagian:** Klarifikasi melengkapi query tanpa menghapus kebutuhan sebelumnya.

- [ ] **KC-M12-01** · `feat` · Menampilkan ringkasan kebutuhan ambigu
  - **Selesai jika:** Teks Yang murah dan cepat mengikuti fixture.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M12-02** · `feat` · Menampilkan pertanyaan batas harga
  - **Selesai jika:** Pertanyaan sesuai referensi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M12-03** · `feat` · Menambahkan pilihan harga klarifikasi
  - **Selesai jika:** Satu batas harga dapat dipilih.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M12-04** · `feat` · Menghubungkan tombol Tampilkan rekomendasi
  - **Selesai jika:** Harga baru digabungkan dengan kebutuhan lama dan membuka M13.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M12-05** · `feat` · Menghubungkan tombol Ubah kebutuhan
  - **Selesai jika:** Kembali ke M10 dengan draft terisi.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M13 — Hasil rekomendasi

**Versi:** KantinCerdasv0.3.0 · **Requirement:** FR-M13 · **[Referensi PNG](../design/baseline/screens/M13_hasil_rekomendasi.png)**

**Dependensi bagian:** M10; hasil matches.

**Kondisi:** Asisten dummy berhasil menemukan kandidat. **Hasil bagian:** Hasil tetap dapat ditelusuri dan dipilih secara manual.

- [ ] **KC-M13-01** · `feat` · Menambahkan tombol kembali rekomendasi
  - **Selesai jika:** Kembali ke halaman pemanggil.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M13-02** · `feat` · Menampilkan ringkasan pilihan rekomendasi
  - **Selesai jika:** Batas harga dan waktu berasal dari query aktif.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M13-03** · `feat` · Menghubungkan ikon edit rekomendasi
  - **Selesai jika:** Membuka M10 dengan pilihan aktif.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M13-04** · `feat` · Menghubungkan tombol Ubah pilihan
  - **Selesai jika:** Membuka draft yang sama seperti ikon edit.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M13-05** · `feat` · Menampilkan tiga kandidat fixture
  - **Selesai jika:** Ayam sambal matah, telur dadar, Mi Gomak tampil dalam urutan fixture.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M13-06** · `feat` · Menghubungkan kandidat ke detail menu
  - **Selesai jika:** Tap isi row membuka detail kandidat.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M13-07** · `feat` · Menyediakan callback Tambah rekomendasi
  - **Selesai jika:** Menggunakan handler cart bersama ketika milestone v0.4.0 siap.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M15 — Asisten gagal

**Versi:** KantinCerdasv0.3.0 · **Requirement:** FR-M15 · **[Referensi PNG](../design/baseline/screens/M15_asisten_gagal.png)**

**Dependensi bagian:** M10; hasil failure.

**Kondisi:** Repository asisten mengembalikan kegagalan yang diketahui. **Hasil bagian:** Pengguna bisa retry atau memakai pencarian manual.

- [ ] **KC-M15-01** · `feat` · Menampilkan banner asisten gagal
  - **Selesai jika:** Pesan Asisten sedang bermasalah mengikuti sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M15-02** · `feat` · Mempertahankan pilihan saat asisten gagal
  - **Selesai jika:** Harga, waktu, selera, teks tidak kembali ke default.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M15-03** · `feat` · Menghubungkan tombol Coba lagi asisten
  - **Selesai jika:** Memanggil ulang query yang sama satu kali per tap.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M15-04** · `feat` · Menghubungkan tombol Cari menu sendiri
  - **Selesai jika:** Membuka M04 dengan filter harga/waktu yang sesuai.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M16 — Rekomendasi kosong

**Versi:** KantinCerdasv0.3.0 · **Requirement:** FR-M16 · **[Referensi PNG](../design/baseline/screens/M16_rekomendasi_kosong.png)**

**Dependensi bagian:** M13; hasil empty.

**Kondisi:** Asisten berhasil tetapi kandidat berjumlah nol. **Hasil bagian:** Tidak ada rekomendasi rekaan; pilihan dapat diubah.

- [ ] **KC-M16-01** · `feat` · Menampilkan empty state rekomendasi
  - **Selesai jika:** Pesan Belum ada menu yang cocok mengikuti sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M16-02** · `feat` · Menampilkan saran melonggarkan kriteria
  - **Selesai jika:** Harga atau waktu dapat disesuaikan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M16-03** · `feat` · Menghubungkan Ubah pilihan pada hasil kosong
  - **Selesai jika:** Kembali ke draft asisten tanpa kehilangan input.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M16-04** · `feat` · Menghubungkan Lihat semua menu
  - **Selesai jika:** Membuka katalog tanpa pembatas rekomendasi.
  - PIC: — · Status: TODO · Issue: — · PR: —


<a id="release-0-4-0"></a>

## KantinCerdasv0.4.0 — Keranjang dan integrasi lintas katalog

**Target:** 77 task · **Gate milestone:** Cart satu stan, jumlah, catatan, undo, dan availability konsisten.

### LOGIC — Aturan cart bersama

**Versi:** KantinCerdasv0.4.0 · **Dependensi bagian:** Model DATA, komponen F00, katalog 0.2.0.

- [ ] **KC-LOGIC-01** · `feat` · Menegakkan invariant satu stan
  - **Selesai jika:** Repository menolak mutasi lintas stan tanpa replace terkonfirmasi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-LOGIC-02** · `feat` · Menegakkan kalkulasi quantity cart
  - **Selesai jika:** Line quantity positif; jumlah porsi dihitung dari quantity.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-LOGIC-03** · `feat` · Menegakkan kalkulasi total cart
  - **Selesai jika:** Total berasal dari unitPriceRupiah kali quantity.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-LOGIC-04** · `feat` · Menegakkan aturan catatan satu line
  - **Selesai jika:** Catatan order dan item tidak saling menimpa.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-LOGIC-05** · `feat` · Menambahkan revision cart
  - **Selesai jika:** Setiap mutasi menaikkan revision untuk guard submit/undo.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-LOGIC-06** · `feat` · Membuat snapshot undo cart
  - **Selesai jika:** Expiry lima detik dan invalidasi ganti stan bekerja.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-LOGIC-07** · `feat` · Membuat validasi availability cart
  - **Selesai jika:** Item invalid teridentifikasi dengan alasan sebelum checkout.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-LOGIC-08** · `test` · Menguji total cart normal dan besar
  - **Selesai jika:** Rp30.000 dan Rp94.000 diverifikasi dari fixture.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-LOGIC-09** · `test` · Menguji batal dan setuju ganti stan
  - **Selesai jika:** Batal menjaga seluruh state; setuju tidak menyisakan line lama.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-LOGIC-10** · `test` · Menguji undo dan expiry
  - **Selesai jika:** Pulih sebelum expiry; tidak pulih sesudah expiry atau ganti stan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-LOGIC-11** · `test` · Menguji catatan dan minimum quantity
  - **Selesai jika:** Catatan line benar; minus tidak menyimpan nilai negatif.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M03 — Beranda dengan cart

**Versi:** KantinCerdasv0.4.0 · **Requirement:** FR-M03 · **[Referensi PNG](../design/baseline/screens/M03_beranda_dengan_cart.png)**

**Dependensi bagian:** M01 dan LOGIC; cart fixture dua porsi.

**Kondisi:** M01 dengan dua porsi dari Dapur Bu Rina di cart. **Hasil bagian:** Beranda mencerminkan state keranjang yang sama.

- [ ] **KC-M03-01** · `feat` · Menampilkan jumlah item di row beranda
  - **Selesai jika:** Nasi Ayam Sambal Matah menunjukkan jumlah satu dari cart.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M03-02** · `feat` · Menghubungkan tombol plus row beranda
  - **Selesai jika:** Jumlah menu dan total cart meningkat satu kali per tap.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M03-03** · `feat` · Menghubungkan tombol minus row beranda
  - **Selesai jika:** Jumlah berkurang sesuai BR-04; tidak menjadi negatif.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M03-04** · `feat` · Menampilkan sticky cart beranda
  - **Selesai jika:** Fixture menampilkan 2 porsi, Rp30.000, Dapur Bu Rina.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M03-05** · `feat` · Menghubungkan tombol Lihat keranjang beranda
  - **Selesai jika:** Tap membuka M17.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M03-06** · `feat` · Menggeser posisi FAB ketika cart tampil
  - **Selesai jika:** FAB mengikuti referensi di atas sticky cart.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M07 — Detail stan dengan cart

**Versi:** KantinCerdasv0.4.0 · **Requirement:** FR-M07 · **[Referensi PNG](../design/baseline/screens/M07_detail_stan_dengan_cart.png)**

**Dependensi bagian:** M06 dan LOGIC.

**Kondisi:** M06 dengan keranjang Bu Rina yang terisi. **Hasil bagian:** Jumlah di katalog stan dan cart selalu konsisten.

- [ ] **KC-M07-01** · `feat` · Menampilkan jumlah ayam pada detail stan
  - **Selesai jika:** Fixture ayam menunjukkan satu porsi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M07-02** · `feat` · Menampilkan jumlah telur pada detail stan
  - **Selesai jika:** Fixture telur menunjukkan satu porsi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M07-03** · `feat` · Menghubungkan perubahan jumlah dari detail stan
  - **Selesai jika:** Perubahan diteruskan ke CartRepository yang sama.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M07-04** · `feat` · Menampilkan sticky cart detail stan
  - **Selesai jika:** Jumlah dua porsi dan total Rp30.000 mengikuti state.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M07-05** · `feat` · Menghubungkan tombol keranjang detail stan
  - **Selesai jika:** Tap membuka M17.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M07-06** · `feat` · Menempatkan FAB detail stan di atas cart
  - **Selesai jika:** Tidak bertumpuk dengan CTA cart.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M09 — Menu berhasil ditambahkan

**Versi:** KantinCerdasv0.4.0 · **Requirement:** FR-M09 · **[Referensi PNG](../design/baseline/screens/M09_menu_berhasil_ditambahkan.png)**

**Dependensi bagian:** M08 dan LOGIC.

**Kondisi:** Draft M08 berhasil dimasukkan; fixture sebelumnya sudah memiliki satu telur. **Hasil bagian:** Feedback tambah ditampilkan dan cart menjadi dua porsi.

- [ ] **KC-M09-01** · `feat` · Menghubungkan submit draft detail ke cart
  - **Selesai jika:** Jumlah dan catatan yang dikirim sama dengan draft M08.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M09-02** · `feat` · Menampilkan banner Menu ditambahkan
  - **Selesai jika:** Pesan menunjukkan satu porsi menu ini di cart untuk fixture.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M09-03** · `feat` · Menambahkan tombol Tambah lagi
  - **Selesai jika:** Menambahkan jumlah draft yang sama sekali lagi sesuai A-05.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M09-04** · `feat` · Menampilkan sticky cart setelah tambah
  - **Selesai jika:** Fixture total menjadi Rp30.000 dari ayam dan telur.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M09-05** · `feat` · Menghubungkan tombol Lihat keranjang setelah tambah
  - **Selesai jika:** Tap membuka isi cart terbaru.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M14 — Rekomendasi dengan cart

**Versi:** KantinCerdasv0.4.0 · **Requirement:** FR-M14 · **[Referensi PNG](../design/baseline/screens/M14_rekomendasi_dengan_cart.png)**

**Dependensi bagian:** M13 dan LOGIC.

**Kondisi:** Rekomendasi dibuka saat cart Bu Rina terisi. **Hasil bagian:** Pilihan rekomendasi menghormati batas satu stan.

- [ ] **KC-M14-01** · `feat` · Menampilkan banner stan cart di rekomendasi
  - **Selesai jika:** Dapur Bu Rina, 2 porsi, Rp30.000 sesuai fixture.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M14-02** · `feat` · Menghubungkan kontrol jumlah rekomendasi
  - **Selesai jika:** Perubahan ayam/telur memperbarui seluruh cart.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M14-03** · `feat` · Menampilkan sticky cart rekomendasi
  - **Selesai jika:** Footer standalone mengikuti M14 tanpa bottom navigation.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M14-04** · `feat` · Menghubungkan tombol keranjang rekomendasi
  - **Selesai jika:** Tap membuka M17.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M14-05** · `feat` · Mencegat tambah kandidat stan berbeda
  - **Selesai jika:** Mi Gomak memunculkan M21 sebelum cart berubah.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M17 — Keranjang dua porsi

**Versi:** KantinCerdasv0.4.0 · **Requirement:** FR-M17 · **[Referensi PNG](../design/baseline/screens/M17_keranjang_dua_porsi.png)**

**Dependensi bagian:** LOGIC; CartRepository; F00 row/quantity/footer.

**Kondisi:** Cart berisi satu ayam Rp18.000 dan satu telur Rp12.000. **Hasil bagian:** Cart menjadi sumber ringkasan yang konsisten sebelum checkout.

- [ ] **KC-M17-01** · `feat` · Menambahkan tombol kembali keranjang
  - **Selesai jika:** Kembali ke asal; cart tetap tersimpan dalam sesi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M17-02** · `feat` · Menampilkan nama stan keranjang
  - **Selesai jika:** Hanya satu stan tampil.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M17-03** · `feat` · Menampilkan item ayam keranjang
  - **Selesai jika:** Foto, harga, jumlah, catatan Sambal dipisah berasal dari cart.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M17-04** · `feat` · Menampilkan item telur keranjang
  - **Selesai jika:** Foto, harga, jumlah berasal dari cart.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M17-05** · `feat` · Menghubungkan tombol plus item cart
  - **Selesai jika:** Satu porsi ditambahkan pada item yang benar.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M17-06** · `feat` · Menghubungkan tombol minus item cart
  - **Selesai jika:** Mengikuti minimum dan penghapusan BR-04.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M17-07** · `feat` · Menghubungkan tombol Ubah catatan item
  - **Selesai jika:** Membuka M18 untuk line ID yang dipilih.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M17-08** · `feat` · Menghubungkan tombol Hapus item
  - **Selesai jika:** Menghapus line terpilih dan memunculkan M19.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M17-09** · `feat` · Menghubungkan tombol Kosongkan
  - **Selesai jika:** Membuka M20 tanpa mengosongkan langsung.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M17-10** · `feat` · Menambahkan input catatan pesanan
  - **Selesai jika:** Bungkus terpisah tersimpan terpisah dari catatan item.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M17-11** · `feat` · Menghitung subtotal cart
  - **Selesai jika:** Jumlah harga dikali quantity seluruh item valid; fixture Rp30.000.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M17-12** · `feat` · Menghitung jumlah porsi cart
  - **Selesai jika:** Jumlah quantity adalah dua, bukan jumlah jenis sebagai aturan umum.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M17-13** · `feat` · Menampilkan keterangan tunai
  - **Selesai jika:** Tunai saat mengambil di stan tetap tampil.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M17-14** · `feat` · Menghubungkan Lanjut konfirmasi
  - **Selesai jika:** Cart valid membuka M24 pada v0.5.0; cart tidak valid masuk M23.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M18 — Edit catatan item

**Versi:** KantinCerdasv0.4.0 · **Requirement:** FR-M18 · **[Referensi PNG](../design/baseline/screens/M18_edit_catatan_item.png)**

**Dependensi bagian:** M17; snapshot draft line.

**Kondisi:** Ubah catatan dipilih pada satu item keranjang. **Hasil bagian:** Hanya catatan item terpilih yang dapat berubah.

- [ ] **KC-M18-01** · `feat` · Menampilkan judul sheet catatan
  - **Selesai jika:** Nama menu berasal dari line cart terpilih.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M18-02** · `feat` · Mengisi field dengan catatan lama
  - **Selesai jika:** Catatan opsional dapat dikosongkan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M18-03** · `feat` · Menghubungkan Simpan catatan
  - **Selesai jika:** Draft menggantikan catatan line yang tepat lalu sheet ditutup.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M18-04** · `feat` · Menghubungkan Batal catatan
  - **Selesai jika:** Draft dibuang; catatan lama tetap.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M18-05** · `feat` · Menghubungkan tombol tutup catatan
  - **Selesai jika:** Efek sama seperti Batal.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M18-06** · `feat` · Menyesuaikan sheet catatan terhadap keyboard
  - **Selesai jika:** Input dan Simpan dapat dijangkau tanpa overflow.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M19 — Hapus item dengan undo

**Versi:** KantinCerdasv0.4.0 · **Requirement:** FR-M19 · **[Referensi PNG](../design/baseline/screens/M19_hapus_item_dengan_undo.png)**

**Dependensi bagian:** M17; snapshot undo LOGIC.

**Kondisi:** Satu telur dihapus dari cart dua porsi. **Hasil bagian:** Cart satu ayam bernilai Rp18.000; undo tersedia.

- [ ] **KC-M19-01** · `feat` · Menyimpan snapshot item terhapus
  - **Selesai jika:** Snapshot mencakup line ID, quantity, catatan, dan posisi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M19-02** · `feat` · Memperbarui total setelah penghapusan
  - **Selesai jika:** Fixture total berubah dari Rp30.000 menjadi Rp18.000.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M19-03** · `feat` · Menampilkan snackbar item terhapus
  - **Selesai jika:** Nama item yang benar ditampilkan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M19-04** · `feat` · Menghubungkan tombol Urungkan
  - **Selesai jika:** Item pulih utuh selama jendela undo masih valid.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M19-05** · `feat` · Mengakhiri undo yang kedaluwarsa
  - **Selesai jika:** Undo lama tidak memulihkan item setelah cart diganti stan atau checkout.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M20 — Konfirmasi kosongkan cart

**Versi:** KantinCerdasv0.4.0 · **Requirement:** FR-M20 · **[Referensi PNG](../design/baseline/screens/M20_konfirmasi_kosongkan_cart.png)**

**Dependensi bagian:** M17; F00 dialog.

**Kondisi:** Kosongkan dipilih pada cart terisi. **Hasil bagian:** Cart berubah hanya setelah konfirmasi.

- [ ] **KC-M20-01** · `feat` · Menampilkan ringkasan pengosongan
  - **Selesai jika:** Jumlah porsi dan stan sesuai cart saat dialog dibuka.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M20-02** · `feat` · Menghubungkan Tetap simpan
  - **Selesai jika:** Dialog tutup tanpa mutasi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M20-03** · `feat` · Menghubungkan Kosongkan pada dialog
  - **Selesai jika:** Semua line dan catatan pesanan dibersihkan; tampil M22.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M20-04** · `feat` · Menangani Back pada dialog pengosongan
  - **Selesai jika:** Efek sama seperti Tetap simpan.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M21 — Ganti stan

**Versi:** KantinCerdasv0.4.0 · **Requirement:** FR-M21 · **[Referensi PNG](../design/baseline/screens/M21_ganti_stan.png)**

**Dependensi bagian:** LOGIC; callback tambah M14/M01/M06.

**Kondisi:** Pengguna menambah Mi Gomak sementara cart berasal dari Bu Rina. **Hasil bagian:** Perpindahan stan merupakan transaksi cart yang terkonfirmasi.

- [ ] **KC-M21-01** · `feat` · Menampilkan ringkasan cart lama pada dialog
  - **Selesai jika:** Dua porsi Bu Rina Rp30.000 terlihat.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M21-02** · `feat` · Menampilkan kandidat stan baru pada dialog
  - **Selesai jika:** Mi Gomak Pak Ucok Rp15.000 terlihat.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M21-03** · `feat` · Menghubungkan Tetap di Bu Rina
  - **Selesai jika:** Cart lama dan catatan tetap utuh.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M21-04** · `feat` · Menghubungkan Ganti ke Pak Ucok
  - **Selesai jika:** Cart lama diganti satu kandidat baru secara atomik.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M21-05** · `feat` · Membatalkan undo cart lama setelah ganti stan
  - **Selesai jika:** Urungkan sebelumnya tidak dapat menghasilkan cart multi-stan.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M22 — Keranjang kosong

**Versi:** KantinCerdasv0.4.0 · **Requirement:** FR-M22 · **[Referensi PNG](../design/baseline/screens/M22_keranjang_kosong.png)**

**Dependensi bagian:** M17 dan state cart kosong.

**Kondisi:** Cart tidak memiliki line. **Hasil bagian:** Pengguna diarahkan kembali memilih menu.

- [ ] **KC-M22-01** · `feat` · Menampilkan ikon keranjang kosong
  - **Selesai jika:** Ikon dan komposisi mengikuti M22.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M22-02** · `feat` · Menampilkan pesan keranjang kosong
  - **Selesai jika:** Tidak ada footer total nol atau tombol checkout aktif.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M22-03** · `feat` · Menghubungkan tombol Cari menu dari cart
  - **Selesai jika:** Membuka Beranda.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M22-04** · `feat` · Menyembunyikan sticky cart di halaman lain
  - **Selesai jika:** Cart kosong tidak meninggalkan bar atau jumlah lama.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M23 — Ketersediaan berubah

**Versi:** KantinCerdasv0.4.0 · **Requirement:** FR-M23 · **[Referensi PNG](../design/baseline/screens/M23_ketersediaan_berubah.png)**

**Dependensi bagian:** M17; CartValidator LOGIC.

**Kondisi:** Validasi ulang menemukan telur berubah menjadi Habis. **Hasil bagian:** Checkout diblokir sampai perubahan ditinjau.

- [ ] **KC-M23-01** · `feat` · Menampilkan banner ketersediaan berubah
  - **Selesai jika:** Item invalid tetap terlihat agar perubahan dapat dipahami.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M23-02** · `feat` · Menandai line telur sebagai habis
  - **Selesai jika:** Quantity lama tidak otomatis diubah.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M23-03** · `feat` · Menghitung total menu tersedia
  - **Selesai jika:** Fixture valid subtotal Rp18.000; cart masih memuat dua porsi sampai penghapusan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M23-04** · `feat` · Menonaktifkan CTA checkout saat invalid
  - **Selesai jika:** Tap Tinjau perubahan tidak membuat pesanan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M23-05** · `feat` · Menghubungkan Hapus menu habis
  - **Selesai jika:** Semua line invalid dihapus dan total/jumlah dihitung ulang.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M23-06** · `feat` · Menangani semua item menjadi habis
  - **Selesai jika:** Penghapusan semua invalid mengarah ke M22.
  - PIC: — · Status: TODO · Issue: — · PR: —


<a id="release-0-5-0"></a>

## KantinCerdasv0.5.0 — Checkout dan pesanan mahasiswa

**Target:** 80 task · **Gate milestone:** Create/lookup/retry tanpa duplikasi serta lima status detail tersedia.

### SUBMIT — Keandalan pengiriman pesanan

**Versi:** KantinCerdasv0.5.0 · **Dependensi bagian:** LOGIC selesai; model Order/Submission DATA.

- [ ] **KC-SUBMIT-01** · `feat` · Membuat submit coordinator
  - **Selesai jika:** Snapshot dan submission ID hidup di luar halaman checkout.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-SUBMIT-02** · `feat` · Membuat create order fake idempotent
  - **Selesai jika:** ID sama dan snapshot sama mengembalikan order sama.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-SUBMIT-03** · `feat` · Membuat lookup submission fake
  - **Selesai jika:** Found, confirmed-not-created, unresolved dapat dibedakan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-SUBMIT-04** · `feat` · Membuat skenario lost response after commit
  - **Selesai jika:** Order tersimpan walau create memberi unknown.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-SUBMIT-05** · `feat` · Membuat skenario unknown sebelum kepastian commit
  - **Selesai jika:** Lookup belum pasti tidak memberi retry create otomatis.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-SUBMIT-06** · `feat` · Menambahkan guard clear cart revision
  - **Selesai jika:** Sukses submission lama tidak menghapus cart revision baru.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-SUBMIT-07** · `test` · Menguji tap ganda submit
  - **Selesai jika:** Satu logical submission dan satu order tersimpan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-SUBMIT-08** · `test` · Menguji lookup setelah respons hilang
  - **Selesai jika:** KC order yang sama ditemukan tanpa create kedua.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-SUBMIT-09** · `test` · Menguji hasil lookup tetap unknown
  - **Selesai jika:** Tidak membuat order tambahan atau menghapus cart.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-SUBMIT-10** · `test` · Menguji known failure lalu retry
  - **Selesai jika:** Snapshot/catatan bertahan dan retry sukses tepat sekali.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M24 — Konfirmasi pesanan

**Versi:** KantinCerdasv0.5.0 · **Requirement:** FR-M24 · **[Referensi PNG](../design/baseline/screens/M24_konfirmasi_pesanan.png)**

**Dependensi bagian:** M17/M23; SUBMIT coordinator.

**Kondisi:** Cart valid diteruskan ke konfirmasi. **Hasil bagian:** Pesanan hanya dibuat melalui CTA eksplisit.

- [ ] **KC-M24-01** · `feat` · Menambahkan tombol kembali konfirmasi
  - **Selesai jika:** Cart dan catatan tetap utuh.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M24-02** · `feat` · Menampilkan lokasi pengambilan
  - **Selesai jika:** Nama stan dan blok berasal dari cart.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M24-03** · `feat` · Menampilkan ringkasan item checkout
  - **Selesai jika:** Quantity, harga, catatan item, dan total sama dengan cart.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M24-04** · `feat` · Menampilkan metode pembayaran checkout
  - **Selesai jika:** Tunai di konter; tidak ada QRIS atau pilihan pembayaran baru.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M24-05** · `feat` · Menampilkan estimasi penyajian checkout
  - **Selesai jika:** Rentang berlaku setelah pesanan diterima pengelola.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M24-06** · `feat` · Memvalidasi ulang cart sebelum submit
  - **Selesai jika:** Stan buka dan semua menu tersedia; perubahan diarahkan ke aturan BR-07.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M24-07** · `feat` · Menghubungkan tombol Buat pesanan
  - **Selesai jika:** Satu submission ID dibuat dan state berpindah ke M25.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M25 — Membuat pesanan

**Versi:** KantinCerdasv0.5.0 · **Requirement:** FR-M25 · **[Referensi PNG](../design/baseline/screens/M25_membuat_pesanan.png)**

**Dependensi bagian:** M24; SUBMIT idempotency.

**Kondisi:** Operasi create order dummy sedang berjalan. **Hasil bagian:** Permintaan ganda dicegah sampai hasil operasi diketahui.

- [ ] **KC-M25-01** · `feat` · Menampilkan label Membuat pesanan
  - **Selesai jika:** Indikator proses berada di CTA sesuai sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M25-02** · `feat` · Mengunci CTA selama submit
  - **Selesai jika:** Tap berulang tidak menambah operasi baru.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M25-03** · `feat` · Mempertahankan snapshot submission
  - **Selesai jika:** Isi permintaan tidak berubah walaupun state katalog berubah.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M25-04** · `feat` · Mengarahkan hasil submit
  - **Selesai jika:** Sukses ke M28, pasti gagal ke M26, tidak diketahui ke M27.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M25-05** · `feat` · Menangani Back saat submit
  - **Selesai jika:** Halaman boleh ditinggalkan tetapi operation tetap dilacak; tidak ada submit kedua otomatis.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M26 — Pesanan belum terkirim

**Versi:** KantinCerdasv0.5.0 · **Requirement:** FR-M26 · **[Referensi PNG](../design/baseline/screens/M26_pesanan_belum_terkirim.png)**

**Dependensi bagian:** M25; knownFailure.

**Kondisi:** Fake repository memastikan pesanan belum dibuat. **Hasil bagian:** Retry aman dilakukan tanpa kehilangan cart.

- [ ] **KC-M26-01** · `feat` · Menampilkan banner Pesanan belum terkirim
  - **Selesai jika:** Pesan tidak dipakai untuk hasil yang belum diketahui.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M26-02** · `feat` · Mempertahankan cart setelah gagal kirim
  - **Selesai jika:** Quantity, catatan, dan total tetap.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M26-03** · `feat` · Menghubungkan Coba kirim lagi
  - **Selesai jika:** Mengulang logical submission yang sama setelah validasi; tidak menciptakan duplikat.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M26-04** · `feat` · Mencegah retry saat offline simulasi
  - **Selesai jika:** Operasi tidak dipanggil sampai koneksi simulasi pulih.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M27 — Hasil pengiriman belum diketahui

**Versi:** KantinCerdasv0.5.0 · **Requirement:** FR-M27 · **[Referensi PNG](../design/baseline/screens/M27_hasil_pengiriman_belum_diketahui.png)**

**Dependensi bagian:** M25; SUBMIT lookup.

**Kondisi:** Respons hilang setelah create order mungkin telah diterima. **Hasil bagian:** Status submission diperiksa sebelum pengguna mengirim lagi.

- [ ] **KC-M27-01** · `feat` · Menampilkan banner hasil belum diketahui
  - **Selesai jika:** Copy Memeriksa pesananmu mengikuti referensi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M27-02** · `feat` · Mengganti CTA menjadi Periksa status pengiriman
  - **Selesai jika:** Tidak tersedia CTA yang langsung membuat pesanan kedua.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M27-03** · `feat` · Menghubungkan pemeriksaan submission
  - **Selesai jika:** Pencarian menggunakan submission ID sebelumnya.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M27-04** · `feat` · Menangani hasil pemeriksaan ditemukan
  - **Selesai jika:** Buka M28 dengan order ID yang sama dan kosongkan cart sekali.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M27-05** · `feat` · Menangani hasil pemeriksaan dipastikan tidak dibuat
  - **Selesai jika:** Buka M26; retry memakai logical submission yang sama.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M27-06** · `feat` · Menangani pemeriksaan masih tidak pasti
  - **Selesai jika:** Tetap M27, cart dan submission ID tidak dihapus.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M28 — Pesanan berhasil

**Versi:** KantinCerdasv0.5.0 · **Requirement:** FR-M28 · **[Referensi PNG](../design/baseline/screens/M28_pesanan_berhasil.png)**

**Dependensi bagian:** M25/M27; order sukses terkonfirmasi.

**Kondisi:** Pesanan berhasil tersimpan dalam repository dummy. **Hasil bagian:** Bukti pemesanan tersedia dan pengguna dapat memantau status.

- [ ] **KC-M28-01** · `feat` · Menampilkan pesan Pesanan dibuat
  - **Selesai jika:** Badge awal Menunggu konfirmasi tampil.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M28-02** · `feat` · Menampilkan kode pesanan sukses
  - **Selesai jika:** Fixture KC-027; pesanan berikutnya memakai kode unik.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M28-03** · `feat` · Menampilkan ringkasan sukses
  - **Selesai jika:** Stan, blok, waktu, jumlah, total, tunai sesuai snapshot order.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M28-04** · `feat` · Mengosongkan cart setelah sukses terkonfirmasi
  - **Selesai jika:** Hanya cart yang berasal dari submission tersebut dibersihkan sekali.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M28-05** · `feat` · Menghubungkan tombol Pantau pesanan
  - **Selesai jika:** Membuka M31 untuk ID pesanan yang dibuat.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M28-06** · `feat` · Menghubungkan Kembali ke beranda
  - **Selesai jika:** Membuka M01 tanpa menghapus pesanan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M28-07** · `feat` · Memicu pengenalan notifikasi secara kontekstual
  - **Selesai jika:** U01 dapat muncul sekali sesuai skenario, bukan menghalangi keberhasilan order.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M29 — Pesanan aktif

**Versi:** KantinCerdasv0.5.0 · **Requirement:** FR-M29 · **[Referensi PNG](../design/baseline/screens/M29_pesanan_aktif.png)**

**Dependensi bagian:** OrderRepository; M28.

**Kondisi:** Tab Pesanan mahasiswa dibuka. **Hasil bagian:** Daftar aktif hanya memuat pesanan mahasiswa yang masih berjalan.

- [ ] **KC-M29-01** · `feat` · Menghubungkan tab Aktif
  - **Selesai jika:** Menampilkan waiting, processing, ready milik mahasiswa aktif.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M29-02** · `feat` · Menghubungkan tab Riwayat
  - **Selesai jika:** Membuka M30.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M29-03** · `feat` · Menampilkan row pesanan aktif
  - **Selesai jika:** Kode, stan, jumlah, total, status berasal dari repository.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M29-04** · `feat` · Menghubungkan Lihat detail pesanan aktif
  - **Selesai jika:** Membuka M31/M32/M33 menurut status aktual.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M29-05** · `feat` · Menampilkan banner menunggu konfirmasi
  - **Selesai jika:** Waktu dibuat sesuai order aktif.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M29-06** · `feat` · Memperbarui daftar saat event order berubah
  - **Selesai jika:** Order terminal keluar dari Aktif tanpa duplikasi.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M30 — Riwayat mahasiswa

**Versi:** KantinCerdasv0.5.0 · **Requirement:** FR-M30 · **[Referensi PNG](../design/baseline/screens/M30_riwayat_mahasiswa.png)**

**Dependensi bagian:** M29 dan fixture riwayat.

**Kondisi:** Tab Riwayat mahasiswa dipilih. **Hasil bagian:** Pesanan selesai dan ditolak dapat dibaca kembali.

- [ ] **KC-M30-01** · `feat` · Menampilkan daftar riwayat mahasiswa
  - **Selesai jika:** Hanya order terminal milik pengguna yang tampil.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M30-02** · `feat` · Menampilkan waktu pada row riwayat
  - **Selesai jika:** Fixture KC-027 selesai 12.20 dan KC-019 tanggal 3 Sep.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M30-03** · `feat` · Menghubungkan row riwayat ke detail
  - **Selesai jika:** Selesai membuka M34; ditolak membuka M35.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M30-04** · `feat` · Menghubungkan tab Aktif dari riwayat
  - **Selesai jika:** Kembali ke M29.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M30-05** · `feat` · Menangani riwayat tanpa data
  - **Selesai jika:** Gunakan varian kosong studentOrders(history:true, empty:true) dalam sumber; tanpa tombol pemesanan ulang baru.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M31 — Menunggu konfirmasi

**Versi:** KantinCerdasv0.5.0 · **Requirement:** FR-M31 · **[Referensi PNG](../design/baseline/screens/M31_menunggu_konfirmasi.png)**

**Dependensi bagian:** M29; model Order/Event dan timeline F00.

**Kondisi:** Detail order berstatus Menunggu konfirmasi dipilih. **Hasil bagian:** Status Menunggu konfirmasi terlihat konsisten dengan order yang sama.

- [ ] **KC-M31-01** · `feat` · Menampilkan header status Menunggu konfirmasi
  - **Selesai jika:** Label status, order ID, dan stan berasal dari order.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M31-02** · `feat` · Menampilkan pesan status Menunggu konfirmasi
  - **Selesai jika:** Belum ada tahap diproses yang ditandai selesai.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M31-03** · `feat` · Menampilkan timeline Menunggu konfirmasi
  - **Selesai jika:** Hanya event yang sudah terjadi memiliki waktu dan penanda selesai.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M31-04** · `feat` · Menampilkan ringkasan pada status Menunggu konfirmasi
  - **Selesai jika:** Total dan item menggunakan snapshot, tidak mengikuti harga katalog baru.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M31-05** · `feat` · Menampilkan waktu pembaruan Menunggu konfirmasi
  - **Selesai jika:** lastSyncedAt dibedakan dari waktu perpindahan status.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M31-06** · `feat` · Menghubungkan kembali dari status Menunggu konfirmasi
  - **Selesai jika:** Kembali ke tab asal tanpa mengubah order.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M32 — Pesanan diproses

**Versi:** KantinCerdasv0.5.0 · **Requirement:** FR-M32 · **[Referensi PNG](../design/baseline/screens/M32_pesanan_diproses.png)**

**Dependensi bagian:** M31; fixture processing.

**Kondisi:** Detail order berstatus Diproses dipilih. **Hasil bagian:** Status Diproses terlihat konsisten dengan order yang sama.

- [ ] **KC-M32-01** · `feat` · Menampilkan header status Diproses
  - **Selesai jika:** Label status, order ID, dan stan berasal dari order.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M32-02** · `feat` · Menampilkan pesan status Diproses
  - **Selesai jika:** Estimasi dihitung sejak acceptedAt; fixture diterima 12.07.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M32-03** · `feat` · Menampilkan timeline Diproses
  - **Selesai jika:** Hanya event yang sudah terjadi memiliki waktu dan penanda selesai.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M32-04** · `feat` · Menampilkan ringkasan pada status Diproses
  - **Selesai jika:** Total dan item menggunakan snapshot, tidak mengikuti harga katalog baru.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M32-05** · `feat` · Menampilkan waktu pembaruan Diproses
  - **Selesai jika:** lastSyncedAt dibedakan dari waktu perpindahan status.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M32-06** · `feat` · Menghubungkan kembali dari status Diproses
  - **Selesai jika:** Kembali ke tab asal tanpa mengubah order.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M33 — Siap diambil

**Versi:** KantinCerdasv0.5.0 · **Requirement:** FR-M33 · **[Referensi PNG](../design/baseline/screens/M33_siap_diambil.png)**

**Dependensi bagian:** M31; fixture ready.

**Kondisi:** Detail order berstatus Siap diambil dipilih. **Hasil bagian:** Status Siap diambil terlihat konsisten dengan order yang sama.

- [ ] **KC-M33-01** · `feat` · Menampilkan header status Siap diambil
  - **Selesai jika:** Label status, order ID, dan stan berasal dari order.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M33-02** · `feat` · Menampilkan pesan status Siap diambil
  - **Selesai jika:** Kode KC-027 ditonjolkan dan instruksi bayar Rp30.000 tampil.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M33-03** · `feat` · Menampilkan timeline Siap diambil
  - **Selesai jika:** Hanya event yang sudah terjadi memiliki waktu dan penanda selesai.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M33-04** · `feat` · Menampilkan ringkasan pada status Siap diambil
  - **Selesai jika:** Total dan item menggunakan snapshot, tidak mengikuti harga katalog baru.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M33-05** · `feat` · Menampilkan waktu pembaruan Siap diambil
  - **Selesai jika:** lastSyncedAt dibedakan dari waktu perpindahan status.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M33-06** · `feat` · Menghubungkan kembali dari status Siap diambil
  - **Selesai jika:** Kembali ke tab asal tanpa mengubah order.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M34 — Pesanan selesai

**Versi:** KantinCerdasv0.5.0 · **Requirement:** FR-M34 · **[Referensi PNG](../design/baseline/screens/M34_pesanan_selesai.png)**

**Dependensi bagian:** M31; fixture completed.

**Kondisi:** Detail order berstatus Selesai dipilih. **Hasil bagian:** Status Selesai terlihat konsisten dengan order yang sama.

- [ ] **KC-M34-01** · `feat` · Menampilkan header status Selesai
  - **Selesai jika:** Label status, order ID, dan stan berasal dari order.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M34-02** · `feat` · Menampilkan pesan status Selesai
  - **Selesai jika:** Timeline lengkap dan pesan sudah diambil serta dibayar tampil.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M34-03** · `feat` · Menampilkan timeline Selesai
  - **Selesai jika:** Hanya event yang sudah terjadi memiliki waktu dan penanda selesai.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M34-04** · `feat` · Menampilkan ringkasan pada status Selesai
  - **Selesai jika:** Total dan item menggunakan snapshot, tidak mengikuti harga katalog baru.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M34-05** · `feat` · Menampilkan waktu pembaruan Selesai
  - **Selesai jika:** lastSyncedAt dibedakan dari waktu perpindahan status.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M34-06** · `feat` · Menghubungkan kembali dari status Selesai
  - **Selesai jika:** Kembali ke tab asal tanpa mengubah order.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M35 — Pesanan ditolak

**Versi:** KantinCerdasv0.5.0 · **Requirement:** FR-M35 · **[Referensi PNG](../design/baseline/screens/M35_pesanan_ditolak.png)**

**Dependensi bagian:** M31; fixture rejected; D-06.

**Kondisi:** Detail order berstatus Ditolak dipilih. **Hasil bagian:** Status Ditolak terlihat konsisten dengan order yang sama.

- [ ] **KC-M35-01** · `feat` · Menampilkan header status Ditolak
  - **Selesai jika:** Label status, order ID, dan stan berasal dari order.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M35-02** · `feat` · Menampilkan pesan status Ditolak
  - **Selesai jika:** Alasan penolakan tampil, tidak ada tagihan; catatan konflik D-06 berlaku.
  - PIC: — · Status: BLOCKED · Issue: — · PR: — · Blocker: D-06

- [ ] **KC-M35-03** · `feat` · Menampilkan timeline Ditolak
  - **Selesai jika:** Hanya event yang sudah terjadi memiliki waktu dan penanda selesai.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M35-04** · `feat` · Menampilkan ringkasan pada status Ditolak
  - **Selesai jika:** Total dan item menggunakan snapshot, tidak mengikuti harga katalog baru.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M35-05** · `feat` · Menampilkan waktu pembaruan Ditolak
  - **Selesai jika:** lastSyncedAt dibedakan dari waktu perpindahan status.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M35-06** · `feat` · Menghubungkan kembali dari status Ditolak
  - **Selesai jika:** Kembali ke tab asal tanpa mengubah order.
  - PIC: — · Status: TODO · Issue: — · PR: —


<a id="release-0-6-0"></a>

## KantinCerdasv0.6.0 — Dashboard dan order pengelola

**Target:** 99 task · **Gate milestone:** Transisi sah dan dashboard konsisten; D-04 dicatat sebagai gate yang belum boleh dianggap lulus.

### STATE — Transisi order dan agregasi pengelola

**Versi:** KantinCerdasv0.6.0 · **Dependensi bagian:** SUBMIT dan dataset antrean tersedia.

- [ ] **KC-STATE-01** · `feat` · Membuat transition guard order
  - **Selesai jika:** Hanya transisi pada tabel SRS bagian 7.1 diizinkan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-STATE-02** · `feat` · Menambahkan expectedVersion guard
  - **Selesai jika:** Update dari state usang menghasilkan conflict, bukan overwrite.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-STATE-03** · `feat` · Membuat event timeline order
  - **Selesai jika:** Waktu setiap transisi dicatat sekali.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-STATE-04** · `feat` · Membuat transaksi complete dan pembayaran
  - **Selesai jika:** Completed dan cashReceived diperbarui atomik.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-STATE-05** · `feat` · Membuat agregasi dashboard harian
  - **Selesai jika:** 24, 3, 2, 1, 18 diturunkan dari dataset dan clock demo.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-STATE-06** · `feat` · Membuat sorting antrean deterministik
  - **Selesai jika:** Waktu sama memakai sequence sehingga order tidak lompat.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-STATE-07** · `feat` · Membatasi scope order menurut peran
  - **Selesai jika:** Mahasiswa hanya order sendiri; pengelola hanya stan sendiri.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-STATE-08** · `test` · Menguji transisi order sah
  - **Selesai jika:** Waiting, processing, ready, completed menghasilkan event/pembayaran benar.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-STATE-09** · `test` · Menguji penolakan dan transisi ilegal
  - **Selesai jika:** Reject waiting sah; reject completed dan lompat waiting ke completed ditolak.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-STATE-10** · `test` · Menguji conflict version
  - **Selesai jika:** Mutasi kedua dari version usang tidak mengubah data terbaru.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-STATE-11** · `test` · Menguji tutup stan dengan antrean aktif
  - **Selesai jika:** Create baru diblokir; order lama tetap dapat diselesaikan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-STATE-12** · `test` · Menguji snapshot historis
  - **Selesai jika:** Harga/ketersediaan katalog baru tidak mengubah total order lama.
  - PIC: — · Status: TODO · Issue: — · PR: —

### P01 — Dashboard pengelola

**Versi:** KantinCerdasv0.6.0 · **Requirement:** FR-P01 · **[Referensi PNG](../design/baseline/screens/P01_dashboard_pengelola.png)**

**Dependensi bagian:** KC-ENG-11; STATE agregasi; fixture antrean DATA.

**Kondisi:** Aplikasi dijalankan sebagai pengelola Bu Rina. **Hasil bagian:** Dashboard menampilkan ringkasan dan pintasan tindakan stan sendiri.

- [ ] **KC-P01-01** · `feat` · Menampilkan sapaan pengelola
  - **Selesai jika:** Nama Bu Rina dan Dapur Bu Rina sesuai profil.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P01-02** · `feat` · Menampilkan status buka dashboard
  - **Selesai jika:** Nilai berasal dari StallRepository.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P01-03** · `feat` · Menghubungkan switch tutup dashboard
  - **Selesai jika:** Memunculkan P02 sebelum mengubah status.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P01-04** · `feat` · Menampilkan angka total pesanan hari ini
  - **Selesai jika:** Fixture 24 berasal dari agregasi dataset hari demo.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P01-05** · `feat` · Menampilkan angka pesanan menunggu
  - **Selesai jika:** Fixture tiga berasal dari order waiting.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P01-06** · `feat` · Menampilkan angka pesanan diproses
  - **Selesai jika:** Fixture dua berasal dari order processing.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P01-07** · `feat` · Menampilkan angka pesanan siap
  - **Selesai jika:** Fixture satu berasal dari order ready.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P01-08** · `feat` · Menampilkan jumlah selesai hari ini
  - **Selesai jika:** Fixture 18 menghasilkan konsistensi 24 = 3 + 2 + 1 + 18.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P01-09** · `feat` · Menghubungkan Lihat pesanan dashboard
  - **Selesai jika:** Membuka P04.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P01-10** · `feat` · Menghubungkan Kelola menu dashboard
  - **Selesai jika:** Membuka P15 dengan filter Habis; aktif pada v0.7.0.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P01-11** · `feat` · Menampilkan antrean terbaru
  - **Selesai jika:** KC-027, KC-028, KC-029 tersusun sesuai waktu dan urutan tie-break.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P01-12** · `feat` · Menghubungkan detail antrean dashboard
  - **Selesai jika:** Membuka detail ID order yang dipilih.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P01-13** · `feat` · Menghubungkan tombol Dashboard
  - **Selesai jika:** Tidak menumpuk route dashboard.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P01-14** · `feat` · Menghubungkan tombol Pesanan pengelola
  - **Selesai jika:** Membuka P04.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P01-15** · `feat` · Menghubungkan tombol Menu pengelola
  - **Selesai jika:** Membuka P15 ketika milestone v0.7.0 tersedia.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P01-16** · `feat` · Menghubungkan tombol Profil pengelola
  - **Selesai jika:** Membuka P18 ketika milestone v0.7.0 tersedia.
  - PIC: — · Status: TODO · Issue: — · PR: —

### P02 — Dialog menutup stan

**Versi:** KantinCerdasv0.6.0 · **Requirement:** FR-P02 · **[Referensi PNG](../design/baseline/screens/P02_dialog_menutup_stan.png)**

**Dependensi bagian:** P01; StallRepository.

**Kondisi:** Switch buka dimatikan dari dashboard. **Hasil bagian:** Menutup stan tidak membatalkan antrean aktif.

- [ ] **KC-P02-01** · `feat` · Menampilkan dialog tutup stan
  - **Selesai jika:** Copy menjelaskan pesanan baru diblokir dan pesanan lama tetap ditangani.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P02-02** · `feat` · Menghitung antrean aktif dialog
  - **Selesai jika:** Waiting + processing + ready menghasilkan enam pada fixture.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P02-03** · `feat` · Menghubungkan Tetap buka
  - **Selesai jika:** Tidak ada mutasi status stan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P02-04** · `feat` · Menghubungkan Tutup stan
  - **Selesai jika:** Set isOpen false setelah sukses repository; tampil P03.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P02-05** · `feat` · Mempertahankan order saat stan ditutup
  - **Selesai jika:** Enam order aktif tetap berada dalam repository.
  - PIC: — · Status: TODO · Issue: — · PR: —

### P03 — Dashboard stan tutup

**Versi:** KantinCerdasv0.6.0 · **Requirement:** FR-P03 · **[Referensi PNG](../design/baseline/screens/P03_dashboard_stan_tutup.png)**

**Dependensi bagian:** P02; shared state stan.

**Kondisi:** Stan telah ditutup secara manual. **Hasil bagian:** Antrean lama tetap dikelola dan stan dapat dibuka kembali.

- [ ] **KC-P03-01** · `feat` · Menampilkan label Stan tutup
  - **Selesai jika:** Keterangan Tidak menerima pesanan baru mengikuti sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P03-02** · `feat` · Menampilkan switch tutup
  - **Selesai jika:** State switch sesuai isOpen false.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P03-03** · `feat` · Menghubungkan switch buka kembali
  - **Selesai jika:** Sukses mengubah isOpen true dan kembali ke P01.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P03-04** · `feat` · Mempertahankan pintasan pesanan saat tutup
  - **Selesai jika:** P04/P05/P06 tetap dapat dibuka.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P03-05** · `feat` · Menyebarkan status tutup ke katalog mahasiswa
  - **Selesai jika:** S06 muncul pada repository demo bersama; create order baru ditolak.
  - PIC: — · Status: TODO · Issue: — · PR: —

### P04 — Pesanan baru

**Versi:** KantinCerdasv0.6.0 · **Requirement:** FR-P04 · **[Referensi PNG](../design/baseline/screens/P04_pesanan_baru.png)**

**Dependensi bagian:** P01; STATE scope/sorting.

**Kondisi:** Tab Baru pengelola dipilih. **Hasil bagian:** Antrean Baru milik stan sendiri tampil.

- [ ] **KC-P04-01** · `feat` · Mengaktifkan tab Baru
  - **Selesai jika:** Indikator tab sesuai destinasi dan badge jumlah dihitung dari repository.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P04-02** · `feat` · Menyaring order pada tab Baru
  - **Selesai jika:** Hanya status waiting pada stan pengelola yang muncul.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P04-03** · `feat` · Menampilkan data fixture tab Baru
  - **Selesai jika:** KC-027, KC-028, KC-029 tampil dengan jumlah, nilai, waktu, serta nama yang sesuai.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P04-04** · `feat` · Mengurutkan antrean Baru
  - **Selesai jika:** Urutan menggunakan aturan BR-12 dan tie-break sequence yang stabil.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P04-05** · `feat` · Menghubungkan Lihat detail tab Baru
  - **Selesai jika:** Buka detail order yang dipilih dengan status aktual.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P04-06** · `feat` · Memperbarui badge tab Baru
  - **Selesai jika:** Mutasi order pada repository memperbarui hitungan tanpa reload aplikasi.
  - PIC: — · Status: TODO · Issue: — · PR: —

### P05 — Pesanan diproses

**Versi:** KantinCerdasv0.6.0 · **Requirement:** FR-P05 · **[Referensi PNG](../design/baseline/screens/P05_pesanan_diproses.png)**

**Dependensi bagian:** P04; state processing.

**Kondisi:** Tab Diproses pengelola dipilih. **Hasil bagian:** Antrean Diproses milik stan sendiri tampil.

- [ ] **KC-P05-01** · `feat` · Mengaktifkan tab Diproses
  - **Selesai jika:** Indikator tab sesuai destinasi dan badge jumlah dihitung dari repository.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P05-02** · `feat` · Menyaring order pada tab Diproses
  - **Selesai jika:** Hanya status processing pada stan pengelola yang muncul.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P05-03** · `feat` · Menampilkan data fixture tab Diproses
  - **Selesai jika:** KC-025, KC-026 tampil dengan jumlah, nilai, waktu, serta nama yang sesuai.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P05-04** · `feat` · Mengurutkan antrean Diproses
  - **Selesai jika:** Urutan menggunakan aturan BR-12 dan tie-break sequence yang stabil.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P05-05** · `feat` · Menghubungkan Lihat detail tab Diproses
  - **Selesai jika:** Buka detail order yang dipilih dengan status aktual.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P05-06** · `feat` · Memperbarui badge tab Diproses
  - **Selesai jika:** Mutasi order pada repository memperbarui hitungan tanpa reload aplikasi.
  - PIC: — · Status: TODO · Issue: — · PR: —

### P06 — Pesanan siap

**Versi:** KantinCerdasv0.6.0 · **Requirement:** FR-P06 · **[Referensi PNG](../design/baseline/screens/P06_pesanan_siap.png)**

**Dependensi bagian:** P04; state ready.

**Kondisi:** Tab Siap pengelola dipilih. **Hasil bagian:** Antrean Siap milik stan sendiri tampil.

- [ ] **KC-P06-01** · `feat` · Mengaktifkan tab Siap
  - **Selesai jika:** Indikator tab sesuai destinasi dan badge jumlah dihitung dari repository.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P06-02** · `feat` · Menyaring order pada tab Siap
  - **Selesai jika:** Hanya status ready pada stan pengelola yang muncul.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P06-03** · `feat` · Menampilkan data fixture tab Siap
  - **Selesai jika:** KC-024 tampil dengan jumlah, nilai, waktu, serta nama yang sesuai.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P06-04** · `feat` · Mengurutkan antrean Siap
  - **Selesai jika:** Urutan menggunakan aturan BR-12 dan tie-break sequence yang stabil.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P06-05** · `feat` · Menghubungkan Lihat detail tab Siap
  - **Selesai jika:** Buka detail order yang dipilih dengan status aktual.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P06-06** · `feat` · Memperbarui badge tab Siap
  - **Selesai jika:** Mutasi order pada repository memperbarui hitungan tanpa reload aplikasi.
  - PIC: — · Status: TODO · Issue: — · PR: —

### P07 — Riwayat pengelola

**Versi:** KantinCerdasv0.6.0 · **Requirement:** FR-P07 · **[Referensi PNG](../design/baseline/screens/P07_riwayat_pengelola.png)**

**Dependensi bagian:** P04; fixture riwayat.

**Kondisi:** Pengelola memilih Riwayat. **Hasil bagian:** Riwayat stan berisi order selesai atau ditolak.

- [ ] **KC-P07-01** · `feat` · Menghubungkan tab Riwayat pengelola
  - **Selesai jika:** Indikator aktif sesuai referensi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P07-02** · `feat` · Menambahkan chip Semua riwayat
  - **Selesai jika:** Menampilkan selesai dan ditolak dari stan sendiri.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P07-03** · `feat` · Menambahkan chip Selesai riwayat
  - **Selesai jika:** Menyaring status completed.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P07-04** · `feat` · Menambahkan chip Ditolak riwayat
  - **Selesai jika:** Menyaring status rejected.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P07-05** · `feat` · Menampilkan row riwayat pengelola
  - **Selesai jika:** KC-027 selesai dan KC-018 ditolak mengikuti fixture riwayat terpisah.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P07-06** · `feat` · Menghubungkan detail riwayat pengelola
  - **Selesai jika:** Selesai membuka P12; ditolak membuka P14.
  - PIC: — · Status: TODO · Issue: — · PR: —

### P08 — Detail pesanan baru

**Versi:** KantinCerdasv0.6.0 · **Requirement:** FR-P08 · **[Referensi PNG](../design/baseline/screens/P08_detail_pesanan_baru.png)**

**Dependensi bagian:** P04; STATE transition guard; D-04 untuk kontrol edit.

**Kondisi:** Order baru KC-027 dibuka pengelola stan terkait. **Hasil bagian:** Pengelola dapat menerima atau memulai penolakan.

- [ ] **KC-P08-01** · `feat` · Menampilkan identitas order baru
  - **Selesai jika:** Kode, nama Doni, dibuat 12.05, dan Menunggu konfirmasi sesuai data.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P08-02** · `feat` · Menampilkan snapshot item order baru
  - **Selesai jika:** Ayam dan telur beserta catatan, harga, quantity sesuai pesanan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P08-03** · `feat` · Menampilkan catatan pesanan pengelola
  - **Selesai jika:** Bungkus terpisah berasal dari snapshot.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P08-04** · `feat` · Menampilkan pembayaran belum dibayar
  - **Selesai jika:** Total Rp30.000 dengan tunai saat mengambil.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P08-05** · `docs` · Mencatat kontrol edit pada detail order
  - **Selesai jika:** Kontrol Ubah catatan, Hapus, minus, plus masuk keputusan D-04; tidak diberi mutasi diam-diam.
  - PIC: — · Status: BLOCKED · Issue: — · PR: — · Blocker: D-04

- [ ] **KC-P08-06** · `feat` · Menghubungkan tombol Tolak order baru
  - **Selesai jika:** Membuka P13 tanpa mengubah status lebih dahulu.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P08-07** · `feat` · Menghubungkan Terima & siapkan
  - **Selesai jika:** Hanya waiting dapat berubah ke processing; sukses menampilkan P09.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P08-08** · `feat` · Mencegah penerimaan ganda
  - **Selesai jika:** Satu operasi aktif per order; retry tidak menggandakan event accepted.
  - PIC: — · Status: TODO · Issue: — · PR: —

### P09 — Detail pesanan diproses

**Versi:** KantinCerdasv0.6.0 · **Requirement:** FR-P09 · **[Referensi PNG](../design/baseline/screens/P09_detail_pesanan_diproses.png)**

**Dependensi bagian:** P08; STATE transisi processing.

**Kondisi:** Order telah diterima pengelola. **Hasil bagian:** Order dapat ditandai siap setelah penyiapan.

- [ ] **KC-P09-01** · `feat` · Menampilkan status Diproses pengelola
  - **Selesai jika:** Badge dan acceptedAt sesuai event.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P09-02** · `feat` · Mempertahankan snapshot order diproses
  - **Selesai jika:** Item, harga, quantity, catatan tidak dihitung ulang dari katalog.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P09-03** · `feat` · Menambahkan tombol Tandai siap diambil
  - **Selesai jika:** CTA sesuai sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P09-04** · `feat` · Menghubungkan transisi ke siap
  - **Selesai jika:** Hanya processing dapat berubah ke ready; sukses membuka P10.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P09-05** · `feat` · Menangani gagal transisi siap
  - **Selesai jika:** Order tetap processing dan menampilkan S16 pada milestone v0.8.0.
  - PIC: — · Status: TODO · Issue: — · PR: —

### P10 — Detail siap diambil

**Versi:** KantinCerdasv0.6.0 · **Requirement:** FR-P10 · **[Referensi PNG](../design/baseline/screens/P10_detail_siap_diambil.png)**

**Dependensi bagian:** P09; STATE transisi ready.

**Kondisi:** Order siap diambil. **Hasil bagian:** Pengelola mencocokkan kode sebelum konfirmasi penyerahan.

- [ ] **KC-P10-01** · `feat` · Menampilkan banner siap pengelola
  - **Selesai jika:** KC-027 dan instruksi mencocokkan nomor tampil.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P10-02** · `feat` · Menampilkan waktu siap pengelola
  - **Selesai jika:** Fixture readyAt 12.15.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P10-03** · `feat` · Menampilkan pembayaran belum dibayar saat siap
  - **Selesai jika:** Status tunai belum diterima tidak berubah otomatis.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P10-04** · `feat` · Menghubungkan Selesaikan pesanan
  - **Selesai jika:** Membuka P11; belum membuat status completed.
  - PIC: — · Status: TODO · Issue: — · PR: —

### P11 — Konfirmasi penyerahan

**Versi:** KantinCerdasv0.6.0 · **Requirement:** FR-P11 · **[Referensi PNG](../design/baseline/screens/P11_konfirmasi_penyerahan.png)**

**Dependensi bagian:** P10; STATE complete atomik.

**Kondisi:** CTA penyelesaian ditekan pada order ready. **Hasil bagian:** Selesai berarti makanan diserahkan dan tunai diterima.

- [ ] **KC-P11-01** · `feat` · Menampilkan nomor order dalam dialog penyerahan
  - **Selesai jika:** Kode sesuai order yang sedang ditangani.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P11-02** · `feat` · Menampilkan nilai tunai dalam dialog
  - **Selesai jika:** Rp30.000 dan nama Doni mengikuti snapshot.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P11-03** · `feat` · Menghubungkan Belum selesai
  - **Selesai jika:** Dialog ditutup; status tetap ready.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P11-04** · `feat` · Menghubungkan Ya, selesaikan
  - **Selesai jika:** Status completed dan payment cashReceived berubah dalam satu operasi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P11-05** · `feat` · Mencegah konfirmasi penyerahan berulang
  - **Selesai jika:** Klik ganda menghasilkan satu completed event.
  - PIC: — · Status: TODO · Issue: — · PR: —

### P12 — Detail pesanan selesai

**Versi:** KantinCerdasv0.6.0 · **Requirement:** FR-P12 · **[Referensi PNG](../design/baseline/screens/P12_detail_pesanan_selesai.png)**

**Dependensi bagian:** P11; D-04 untuk treatment kontrol historis.

**Kondisi:** Penyelesaian pesanan berhasil. **Hasil bagian:** Riwayat menunjukkan hasil final penyerahan dan pembayaran.

- [ ] **KC-P12-01** · `feat` · Menampilkan status Selesai pengelola
  - **Selesai jika:** Waktu completedAt fixture 12.20.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P12-02** · `feat` · Menampilkan Tunai diterima
  - **Selesai jika:** Nilai pembayaran sesuai order selesai.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P12-03** · `feat` · Mempertahankan total historis
  - **Selesai jika:** Harga katalog baru tidak mengubah total order.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P12-04** · `feat` · Menghubungkan Kembali ke pesanan selesai
  - **Selesai jika:** Membuka P07 dengan order tersebut tersedia.
  - PIC: — · Status: TODO · Issue: — · PR: —

### P13 — Konfirmasi penolakan

**Versi:** KantinCerdasv0.6.0 · **Requirement:** FR-P13 · **[Referensi PNG](../design/baseline/screens/P13_konfirmasi_penolakan.png)**

**Dependensi bagian:** P08; enum rejectionReason.

**Kondisi:** Tolak dipilih untuk order waiting. **Hasil bagian:** Alasan penolakan dicatat dan terlihat oleh mahasiswa.

- [ ] **KC-P13-01** · `feat` · Menampilkan ringkasan order pada sheet tolak
  - **Selesai jika:** Kode, nama, porsi, total mengikuti snapshot.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P13-02** · `feat` · Menambahkan alasan Menu tidak tersedia
  - **Selesai jika:** Radio memilih satu alasan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P13-03** · `feat` · Menambahkan alasan Stan tidak dapat memproses
  - **Selesai jika:** Radio memilih satu alasan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P13-04** · `feat` · Menambahkan alasan Lainnya
  - **Selesai jika:** Gunakan enum other tanpa field baru; perluasan teks bebas masuk keputusan A-09.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P13-05** · `feat` · Menghubungkan Tolak pesanan pada sheet
  - **Selesai jika:** Status waiting menjadi rejected dengan alasan terpilih.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P13-06** · `feat` · Menghubungkan Batal penolakan
  - **Selesai jika:** Sheet ditutup tanpa perubahan order.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P13-07** · `feat` · Menghubungkan tombol tutup penolakan
  - **Selesai jika:** Efek sama seperti Batal.
  - PIC: — · Status: TODO · Issue: — · PR: —

### P14 — Detail pesanan ditolak

**Versi:** KantinCerdasv0.6.0 · **Requirement:** FR-P14 · **[Referensi PNG](../design/baseline/screens/P14_detail_pesanan_ditolak.png)**

**Dependensi bagian:** P13; D-04.

**Kondisi:** Penolakan order telah tersimpan. **Hasil bagian:** Order ditolak tidak ditagihkan dan tidak diproses.

- [ ] **KC-P14-01** · `feat` · Menampilkan status Ditolak pengelola
  - **Selesai jika:** Waktu penolakan sesuai event.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P14-02** · `feat` · Menampilkan alasan penolakan pengelola
  - **Selesai jika:** Alasan sama dengan yang dibaca mahasiswa.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P14-03** · `feat` · Menampilkan Tidak ditagihkan
  - **Selesai jika:** paymentStatus notCharged untuk order rejected.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P14-04** · `feat` · Menghubungkan Kembali ke pesanan ditolak
  - **Selesai jika:** Membuka P07 dengan order rejected.
  - PIC: — · Status: TODO · Issue: — · PR: —


<a id="release-0-7-0"></a>

## KantinCerdasv0.7.0 — Menu, pengaturan, profil, dan pendukung

**Target:** 82 task · **Gate milestone:** Preferensi, setting, availability, profil dan pendukung tersedia; interaksi tanpa desain menunggu keputusan.

### M36 — Profil mahasiswa

**Versi:** KantinCerdasv0.7.0 · **Requirement:** FR-M36 · **[Referensi PNG](../design/baseline/screens/M36_profil_mahasiswa.png)**

**Dependensi bagian:** Shell mahasiswa; UserProfile DATA.

**Kondisi:** Mahasiswa membuka Profil. **Hasil bagian:** Profil demo menjadi pintu ke preferensi dan bantuan.

- [ ] **KC-M36-01** · `feat` · Menampilkan identitas mahasiswa
  - **Selesai jika:** Avatar D, Doni, doni@example.com, dan Mode demo tampil.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M36-02** · `feat` · Menghubungkan row Riwayat pesanan profil
  - **Selesai jika:** Membuka M30.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M36-03** · `feat` · Menghubungkan row Preferensi makanan
  - **Selesai jika:** Membuka M37.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M36-04** · `feat` · Menghubungkan row Notifikasi mahasiswa
  - **Selesai jika:** Membuka U02/U03 sesuai izin simulasi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M36-05** · `feat` · Menghubungkan row Bantuan mahasiswa
  - **Selesai jika:** Membuka U04.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M36-06** · `feat` · Menghubungkan row Tentang mahasiswa
  - **Selesai jika:** Membuka U05.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M36-07** · `feat` · Menghubungkan row Keluar mahasiswa
  - **Selesai jika:** Membuka U07.
  - PIC: — · Status: TODO · Issue: — · PR: —

### M37 — Preferensi makanan

**Versi:** KantinCerdasv0.7.0 · **Requirement:** FR-M37 · **[Referensi PNG](../design/baseline/screens/M37_preferensi_makanan.png)**

**Dependensi bagian:** M36; PreferencesRepository.

**Kondisi:** Preferensi makanan dibuka dari Profil. **Hasil bagian:** Preferensi sesi tersimpan hanya melalui CTA simpan.

- [ ] **KC-M37-01** · `feat` · Menampilkan penjelasan preferensi
  - **Selesai jika:** Copy mengikuti sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M37-02** · `feat` · Menambahkan chip selera preferensi
  - **Selesai jika:** Pedas, Tidak pedas, Berkuah, Pakai nasi mengikuti A-06.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M37-03** · `feat` · Menambahkan radio harga preferensi
  - **Selesai jika:** Pilihan 15000, 20000, tanpa batas bersifat tunggal.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M37-04** · `feat` · Menambahkan radio waktu preferensi
  - **Selesai jika:** Pilihan 10, 20, tanpa batas bersifat tunggal.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M37-05** · `feat` · Menghubungkan Simpan preferensi
  - **Selesai jika:** Draft masuk PreferencesRepository; sukses memicu U09.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-M37-06** · `feat` · Memulihkan preferensi ketika dibuka kembali
  - **Selesai jika:** Dalam sesi sama nilai tersimpan tampil; Back sebelum simpan membuang draft.
  - PIC: — · Status: TODO · Issue: — · PR: —

### P15 — Kelola menu

**Versi:** KantinCerdasv0.7.0 · **Requirement:** FR-P15 · **[Referensi PNG](../design/baseline/screens/P15_kelola_menu.png)**

**Dependensi bagian:** P01; StallRepository availability; komponen menu F00.

**Kondisi:** Pengelola membuka Menu. **Hasil bagian:** Ketersediaan lima menu Bu Rina dapat dikelola.

- [ ] **KC-P15-01** · `feat` · Menambahkan pencarian menu pengelola
  - **Selesai jika:** Query hanya mencari menu stan miliknya.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P15-02** · `feat` · Menambahkan filter Semua menu pengelola
  - **Selesai jika:** Menampilkan lima menu fixture.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P15-03** · `feat` · Menambahkan filter Tersedia pengelola
  - **Selesai jika:** Hanya status available muncul.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P15-04** · `feat` · Menambahkan filter Habis pengelola
  - **Selesai jika:** Sayur Asem dan Nasi Ayam Kecap tampil pada fixture.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P15-05** · `feat` · Menampilkan daftar menu pengelola
  - **Selesai jika:** Nama, foto, harga, status, estimasi mengikuti data.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P15-06** · `feat` · Menghubungkan switch ketersediaan menu
  - **Selesai jika:** Satu menu berubah tersedia/habis lewat repository.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P15-07** · `feat` · Mencegah update ketersediaan bersamaan pada item sama
  - **Selesai jika:** Tap cepat tidak menghasilkan respons lama yang menimpa nilai baru.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P15-08** · `feat` · Memperbarui katalog setelah perubahan menu
  - **Selesai jika:** Mahasiswa membaca status baru dari store demo bersama.
  - PIC: — · Status: TODO · Issue: — · PR: —

### P16 — Gagal ubah ketersediaan

**Versi:** KantinCerdasv0.7.0 · **Requirement:** FR-P16 · **[Referensi PNG](../design/baseline/screens/P16_gagal_ubah_ketersediaan.png)**

**Dependensi bagian:** P15; knownFailure availability.

**Kondisi:** Perubahan Sayur Asem dari Habis ke Tersedia gagal. **Hasil bagian:** Nilai lama tetap berlaku dan retry tersedia pada row yang gagal.

- [ ] **KC-P16-01** · `feat` · Memulihkan switch setelah update gagal
  - **Selesai jika:** Sayur Asem tetap Habis.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P16-02** · `feat` · Menampilkan pesan inline perubahan gagal
  - **Selesai jika:** Status belum berubah tampil pada item yang gagal.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P16-03** · `feat` · Menghubungkan Coba lagi ketersediaan
  - **Selesai jika:** Mengirim target nilai yang gagal, bukan membalik status tanpa konteks.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P16-04** · `feat` · Menghapus pesan setelah update berhasil
  - **Selesai jika:** Badge dan switch mengikuti nilai baru.
  - PIC: — · Status: TODO · Issue: — · PR: —

### P17 — Pengaturan stan

**Versi:** KantinCerdasv0.7.0 · **Requirement:** FR-P17 · **[Referensi PNG](../design/baseline/screens/P17_pengaturan_stan.png)**

**Dependensi bagian:** P18; StallRepository; P02 untuk konfirmasi tutup.

**Kondisi:** Pengelola membuka Pengaturan stan. **Hasil bagian:** Hanya status manual dan estimasi yang dapat disimpan.

- [ ] **KC-P17-01** · `feat` · Menampilkan foto pengaturan stan
  - **Selesai jika:** Aset Bu Rina mengikuti sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P17-02** · `feat` · Menampilkan identitas stan hanya baca
  - **Selesai jika:** Nama, deskripsi, dan lokasi tidak memiliki editor baru.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P17-03** · `feat` · Menambahkan switch status manual dalam draft
  - **Selesai jika:** Belum mengubah repository sampai Simpan perubahan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P17-04** · `feat` · Menambahkan pilihan estimasi 5–10 menit
  - **Selesai jika:** Nilai dapat dipilih sebagai draft.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P17-05** · `feat` · Menambahkan pilihan estimasi 10–15 menit
  - **Selesai jika:** Nilai dapat dipilih sebagai draft.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P17-06** · `feat` · Menambahkan pilihan estimasi 15–20 menit
  - **Selesai jika:** Nilai dapat dipilih sebagai draft.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P17-07** · `feat` · Menampilkan jadwal informasi
  - **Selesai jika:** Senin–Jumat 08.00–16.00 hanya informasi, bukan scheduler.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P17-08** · `feat` · Menghubungkan Simpan perubahan
  - **Selesai jika:** Draft disimpan atomik; menutup stan memakai konfirmasi P02 sesuai A-10.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P17-09** · `feat` · Membuang draft pengaturan saat kembali
  - **Selesai jika:** Data tersimpan tidak berubah tanpa Simpan.
  - PIC: — · Status: TODO · Issue: — · PR: —

### P18 — Profil pengelola

**Versi:** KantinCerdasv0.7.0 · **Requirement:** FR-P18 · **[Referensi PNG](../design/baseline/screens/P18_profil_pengelola.png)**

**Dependensi bagian:** Shell pengelola; UserProfile DATA.

**Kondisi:** Pengelola membuka Profil. **Hasil bagian:** Profil demo memberi akses ke pengaturan dan informasi.

- [ ] **KC-P18-01** · `feat` · Menampilkan identitas pengelola
  - **Selesai jika:** Avatar BR, Bu Rina, Dapur Bu Rina, rina@example.com, Mode demo.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P18-02** · `feat` · Menghubungkan row Data akun
  - **Selesai jika:** Membuka U06.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P18-03** · `feat` · Menghubungkan row Pengaturan stan
  - **Selesai jika:** Membuka P17.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P18-04** · `feat` · Menghubungkan row Notifikasi pengelola
  - **Selesai jika:** Membuka U02/U03 sesuai izin dummy.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P18-05** · `feat` · Menghubungkan row Bantuan pengelola
  - **Selesai jika:** Membuka U04.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P18-06** · `feat` · Menghubungkan row Tentang pengelola
  - **Selesai jika:** Membuka U05.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-P18-07** · `feat` · Menghubungkan row Keluar pengelola
  - **Selesai jika:** Memakai dialog U07 yang sama.
  - PIC: — · Status: TODO · Issue: — · PR: —

### U01 — Penjelasan notifikasi

**Versi:** KantinCerdasv0.7.0 · **Requirement:** FR-U01 · **[Referensi PNG](../design/baseline/screens/U01_penjelasan_notifikasi.png)**

**Dependensi bagian:** M28; gateway izin dummy DATA.

**Kondisi:** Sesudah order berhasil atau konteks notifikasi dibuka. **Hasil bagian:** Permintaan izin dummy tidak menghalangi alur Pesanan.

- [ ] **KC-U01-01** · `feat` · Menampilkan sheet penjelasan notifikasi
  - **Selesai jika:** Alasan menerima kabar status sesuai sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U01-02** · `feat` · Menghubungkan Aktifkan notifikasi
  - **Selesai jika:** Memanggil NotificationPermissionGateway fake dengan hasil skenario granted/denied.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U01-03** · `feat` · Menghubungkan Nanti saja notifikasi
  - **Selesai jika:** Sheet ditutup dan order sukses tetap tersedia.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U01-04** · `feat` · Menghubungkan tombol tutup izin
  - **Selesai jika:** Tidak dianggap sebagai persetujuan izin.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U01-05** · `feat` · Menampilkan alternatif memantau manual
  - **Selesai jika:** Status tetap dapat dilihat pada Pesanan.
  - PIC: — · Status: TODO · Issue: — · PR: —

### U02 — Izin notifikasi ditolak

**Versi:** KantinCerdasv0.7.0 · **Requirement:** FR-U02 · **[Referensi PNG](../design/baseline/screens/U02_izin_notifikasi_ditolak.png)**

**Dependensi bagian:** U01; state denied.

**Kondisi:** Izin notifikasi simulasi denied. **Hasil bagian:** Pengguna mengetahui izin nonaktif dan dapat memantau secara manual.

- [ ] **KC-U02-01** · `feat` · Menampilkan status notifikasi ditolak
  - **Selesai jika:** Tidak mengklaim izin perangkat sungguhan dalam dokumentasi demo.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U02-02** · `feat` · Menghubungkan Buka pengaturan perangkat
  - **Selesai jika:** Gateway fake menyimulasikan kunjungan pengaturan; tidak meminta izin OS pada scope sekarang.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U02-03** · `feat` · Memuat ulang hasil izin setelah kembali
  - **Selesai jika:** Skenario granted membuka U03; denied tetap U02.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U02-04** · `feat` · Menampilkan petunjuk Pesanan
  - **Selesai jika:** Penolakan izin tidak memblokir pemesanan.
  - PIC: — · Status: TODO · Issue: — · PR: —

### U03 — Notifikasi aktif

**Versi:** KantinCerdasv0.7.0 · **Requirement:** FR-U03 · **[Referensi PNG](../design/baseline/screens/U03_notifikasi_aktif.png)**

**Dependensi bagian:** U01; state granted; PreferencesRepository.

**Kondisi:** Izin dummy granted. **Hasil bagian:** Pengaturan aplikasi terpisah dari status izin dummy.

- [ ] **KC-U03-01** · `feat` · Menampilkan label notifikasi aktif
  - **Selesai jika:** Status berasal dari gateway, bukan teks hardcode terpisah.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U03-02** · `feat` · Menambahkan switch notifikasi aplikasi
  - **Selesai jika:** Mengubah enabled di PreferencesRepository dalam sesi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U03-03** · `feat` · Mencegah pengiriman event notifikasi ketika nonaktif
  - **Selesai jika:** Event order tetap memperbarui halaman Pesanan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U03-04** · `feat` · Menghubungkan kembali notifikasi aktif
  - **Selesai jika:** Kembali ke profil sesuai peran.
  - PIC: — · Status: TODO · Issue: — · PR: —

### U04 — Bantuan

**Versi:** KantinCerdasv0.7.0 · **Requirement:** FR-U04 · **[Referensi PNG](../design/baseline/screens/U04_bantuan.png)**

**Dependensi bagian:** M36/P18; D-07 untuk interaksi isi bantuan.

**Kondisi:** Bantuan dibuka melalui profil. **Hasil bagian:** Lima topik bantuan tercantum; detail yang belum didesain dilacak.

- [ ] **KC-U04-01** · `feat` · Menampilkan pengantar Bantuan
  - **Selesai jika:** Copy mengikuti sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U04-02** · `feat` · Menambahkan row Cara memesan
  - **Selesai jika:** Interaksi detail mengikuti keputusan D-07 sebelum dinyatakan selesai.
  - PIC: — · Status: BLOCKED · Issue: — · PR: — · Blocker: D-07

- [ ] **KC-U04-03** · `feat` · Menambahkan row Mengambil dan membayar
  - **Selesai jika:** Interaksi detail mengikuti keputusan D-07.
  - PIC: — · Status: BLOCKED · Issue: — · PR: — · Blocker: D-07

- [ ] **KC-U04-04** · `feat` · Menambahkan row Pesanan ditolak
  - **Selesai jika:** Interaksi detail mengikuti keputusan D-07.
  - PIC: — · Status: BLOCKED · Issue: — · PR: — · Blocker: D-07

- [ ] **KC-U04-05** · `feat` · Menambahkan row Koneksi terputus
  - **Selesai jika:** Interaksi detail mengikuti keputusan D-07.
  - PIC: — · Status: BLOCKED · Issue: — · PR: — · Blocker: D-07

- [ ] **KC-U04-06** · `feat` · Menambahkan row Menggunakan asisten
  - **Selesai jika:** Interaksi detail mengikuti keputusan D-07.
  - PIC: — · Status: BLOCKED · Issue: — · PR: — · Blocker: D-07

- [ ] **KC-U04-07** · `feat` · Menampilkan banner satu stan pada bantuan
  - **Selesai jika:** Instruksi ambil dan bayar tunai mengikuti sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

### U05 — Tentang KantinCerdas

**Versi:** KantinCerdasv0.7.0 · **Requirement:** FR-U05 · **[Referensi PNG](../design/baseline/screens/U05_tentang_kantincerdas.png)**

**Dependensi bagian:** M36/P18.

**Kondisi:** Tentang dibuka melalui profil. **Hasil bagian:** Aplikasi dinyatakan sebagai versi demo.

- [ ] **KC-U05-01** · `feat` · Menampilkan nama produk Tentang
  - **Selesai jika:** KantinCerdas sesuai sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U05-02** · `feat` · Menampilkan tagline Tentang
  - **Selesai jika:** Pilih lebih cepat, makan lebih tenang.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U05-03** · `feat` · Menampilkan deskripsi singkat produk
  - **Selesai jika:** Pilih menu, pesan lebih awal, ambil dan bayar di kantin.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U05-04** · `feat` · Menampilkan label Versi demo
  - **Selesai jika:** Tidak menggantinya dengan klaim layanan produksi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U05-05** · `feat` · Menampilkan pernyataan data contoh
  - **Selesai jika:** Nama, menu, dan pesanan dijelaskan sebagai contoh.
  - PIC: — · Status: TODO · Issue: — · PR: —

### U06 — Data akun pengelola

**Versi:** KantinCerdasv0.7.0 · **Requirement:** FR-U06 · **[Referensi PNG](../design/baseline/screens/U06_data_akun_pengelola.png)**

**Dependensi bagian:** P18; UserProfile.

**Kondisi:** Data akun dibuka pengelola. **Hasil bagian:** Identitas demo bersifat hanya baca.

- [ ] **KC-U06-01** · `feat` · Menampilkan label Akun demo
  - **Selesai jika:** Sesuai referensi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U06-02** · `feat` · Menampilkan nama akun pengelola
  - **Selesai jika:** Bu Rina dari profil aktif.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U06-03** · `feat` · Menampilkan email akun pengelola
  - **Selesai jika:** rina@example.com dari profil aktif.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U06-04** · `feat` · Menampilkan peran akun
  - **Selesai jika:** Pengelola ditampilkan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U06-05** · `feat` · Menampilkan stan akun
  - **Selesai jika:** Dapur Bu Rina ditampilkan tanpa editor.
  - PIC: — · Status: TODO · Issue: — · PR: —

### U07 — Konfirmasi keluar

**Versi:** KantinCerdasv0.7.0 · **Requirement:** FR-U07 · **[Referensi PNG](../design/baseline/screens/U07_konfirmasi_keluar.png)**

**Dependensi bagian:** M36/P18; SessionRepository; D-08 untuk tujuan akhir.

**Kondisi:** Keluar dipilih pada profil. **Hasil bagian:** Sesi dummy dapat diakhiri tanpa menyiratkan autentikasi backend.

- [ ] **KC-U07-01** · `feat` · Menampilkan dialog keluar
  - **Selesai jika:** Copy dan dua aksi sesuai sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U07-02** · `feat` · Menghubungkan Batal keluar
  - **Selesai jika:** Profil dan seluruh state sesi tetap.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U07-03** · `feat` · Menghubungkan konfirmasi Keluar
  - **Selesai jika:** SessionRepository dihapus; data privat sesi dan draft dibersihkan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U07-04** · `docs` · Menentukan tujuan setelah logout
  - **Selesai jika:** D-08 harus diputuskan; jangan menambah layar login tanpa baseline.
  - PIC: — · Status: BLOCKED · Issue: — · PR: — · Blocker: D-08

### U08 — Simpan pengaturan gagal

**Versi:** KantinCerdasv0.7.0 · **Requirement:** FR-U08 · **[Referensi PNG](../design/baseline/screens/U08_simpan_pengaturan_gagal.png)**

**Dependensi bagian:** P17; knownFailure settings.

**Kondisi:** Simpan pengaturan stan gagal pada fake repository. **Hasil bagian:** Draft tetap tersedia untuk retry.

- [ ] **KC-U08-01** · `feat` · Menampilkan banner perubahan belum tersimpan
  - **Selesai jika:** Copy sesuai sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U08-02** · `feat` · Mempertahankan draft setelah gagal simpan
  - **Selesai jika:** Status dan estimasi pilihan pengguna tidak kembali ke nilai lama di form.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U08-03** · `feat` · Mempertahankan nilai repository lama
  - **Selesai jika:** Katalog mahasiswa tidak melihat draft yang gagal.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U08-04** · `feat` · Menghubungkan Coba simpan lagi
  - **Selesai jika:** Menyimpan draft yang sama secara atomik.
  - PIC: — · Status: TODO · Issue: — · PR: —

### U09 — Preferensi tersimpan

**Versi:** KantinCerdasv0.7.0 · **Requirement:** FR-U09 · **[Referensi PNG](../design/baseline/screens/U09_preferensi_tersimpan.png)**

**Dependensi bagian:** M37; sukses save.

**Kondisi:** Simpan preferensi berhasil. **Hasil bagian:** Feedback hanya muncul sesudah nilai benar-benar masuk repository.

- [ ] **KC-U09-01** · `feat` · Menampilkan snackbar Preferensi disimpan
  - **Selesai jika:** Teks dan ikon sesuai sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U09-02** · `feat` · Mempertahankan nilai preferensi tersimpan
  - **Selesai jika:** Buka ulang M37 menampilkan nilai baru.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-U09-03** · `feat` · Menerapkan preferensi pada pembukaan asisten berikutnya
  - **Selesai jika:** M10 menerima default dari nilai terbaru.
  - PIC: — · Status: TODO · Issue: — · PR: —


<a id="release-0-8-0"></a>

## KantinCerdasv0.8.0 — Kondisi sistem dan pemulihan

**Target:** 70 task · **Gate milestone:** Loading/empty/error/offline bisa direproduksi; data lama dan draft terjaga.

### RECOVERY — Penanganan error dan state tambahan

**Versi:** KantinCerdasv0.8.0 · **Dependensi bagian:** Seluruh fitur happy path 0.2.0–0.7.0 tersedia.

- [ ] **KC-RECOVERY-01** · `feat` · Menangani respons pencarian usang
  - **Selesai jika:** Hasil query lama tidak mengganti hasil query terbaru.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-RECOVERY-02** · `feat` · Menangani error tanpa acuan khusus
  - **Selesai jika:** State error terstruktur tersedia; presentasi mengikuti keputusan D-09.
  - PIC: — · Status: BLOCKED · Issue: — · PR: — · Blocker: D-09

- [ ] **KC-RECOVERY-03** · `feat` · Membersihkan listener saat dispose
  - **Selesai jika:** Navigasi selama delay tidak menghasilkan exception lifecycle.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-RECOVERY-04** · `test` · Menguji offline mahasiswa
  - **Selesai jika:** Baca cache sah; create/asisten tidak dipanggil.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-RECOVERY-05** · `test` · Menguji offline pengelola
  - **Selesai jika:** Semua mutasi dicegah, snapshot tetap terbaca.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-RECOVERY-06** · `test` · Menguji gagal simpan preferensi/pengaturan
  - **Selesai jika:** Draft bertahan dan persisted state tidak berubah saat gagal.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-RECOVERY-07** · `test` · Menguji perubahan availability gagal
  - **Selesai jika:** Rollback dan retry intent konsisten.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-RECOVERY-08** · `test` · Menguji filter applied dan draft
  - **Selesai jika:** Cancel tidak mengubah applied; Terapkan benar-benar mengecualikan habis.
  - PIC: — · Status: TODO · Issue: — · PR: —

### S01 — Loading Beranda

**Versi:** KantinCerdasv0.8.0 · **Requirement:** FR-S01 · **[Referensi PNG](../design/baseline/screens/S01_loading_beranda.png)**

**Dependensi bagian:** M01; controller skenario DATA; RECOVERY.

**Kondisi:** Beranda mulai memuat tanpa data. **Hasil bagian:** Katalog sukses membuka M01; gagal membuka S10.

- [ ] **KC-S01-01** · `feat` · Menampilkan skeleton header beranda
  - **Selesai jika:** Proporsi mengikuti S01.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S01-02** · `feat` · Menampilkan skeleton pencarian beranda
  - **Selesai jika:** Tidak menerima input sebelum katalog siap.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S01-03** · `feat` · Menampilkan skeleton row katalog
  - **Selesai jika:** Tidak bercampur spinner layar penuh.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S01-04** · `feat` · Mempertahankan navigasi selama loading beranda
  - **Selesai jika:** Pengguna dapat berpindah tab tanpa crash.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S01-05** · `feat` · Membuang respons loading usang
  - **Selesai jika:** Respons permintaan lama tidak menimpa state terbaru.
  - PIC: — · Status: TODO · Issue: — · PR: —

### S02 — Hasil pencarian kosong

**Versi:** KantinCerdasv0.8.0 · **Requirement:** FR-S02 · **[Referensi PNG](../design/baseline/screens/S02_hasil_pencarian_kosong.png)**

**Dependensi bagian:** M04; controller skenario DATA; RECOVERY.

**Kondisi:** Query sushi tidak menemukan menu. **Hasil bagian:** Pengguna bisa mengubah query atau menghapus filter.

- [ ] **KC-S02-01** · `feat` · Menampilkan empty state pencarian
  - **Selesai jika:** Menu tidak ditemukan dan panduan pemulihan mengikuti sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S02-02** · `feat` · Menghubungkan Ubah kata pencarian
  - **Selesai jika:** Fokus kembali ke field query yang masih berisi sushi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S02-03** · `feat` · Menghubungkan Hapus filter hasil kosong
  - **Selesai jika:** Filter aktif dihapus dan hasil dihitung ulang; query tetap.
  - PIC: — · Status: TODO · Issue: — · PR: —

### S03 — Offline dengan data

**Versi:** KantinCerdasv0.8.0 · **Requirement:** FR-S03 · **[Referensi PNG](../design/baseline/screens/S03_offline_dengan_data.png)**

**Dependensi bagian:** M03; controller skenario DATA; RECOVERY.

**Kondisi:** Offline simulasi dengan cache katalog. **Hasil bagian:** Cache dapat dibaca; operasi yang memerlukan hasil baru diblokir.

- [ ] **KC-S03-01** · `feat` · Menampilkan banner offline dengan cache
  - **Selesai jika:** Waktu data terakhir 12.02 tampil pada fixture.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S03-02** · `feat` · Mengganti placeholder pencarian offline
  - **Selesai jika:** Cari di data tersimpan sesuai sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S03-03** · `feat` · Menampilkan status stan sebagai data terakhir
  - **Selesai jika:** Tidak menyatakan status cache sebagai keadaan live.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S03-04** · `feat` · Menyembunyikan FAB saat offline
  - **Selesai jika:** Asisten tidak dipanggil.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S03-05** · `feat` · Memblokir submit pesanan saat offline
  - **Selesai jika:** Cart lokal tetap dapat dibaca/diedit sesuai BR-15.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S03-06** · `feat` · Menghubungkan Coba lagi katalog offline
  - **Selesai jika:** Keberhasilan refresh memperbarui cache dan lastSyncedAt.
  - PIC: — · Status: TODO · Issue: — · PR: —

### S04 — Offline tanpa data

**Versi:** KantinCerdasv0.8.0 · **Requirement:** FR-S04 · **[Referensi PNG](../design/baseline/screens/S04_offline_tanpa_data.png)**

**Dependensi bagian:** M01; controller skenario DATA; RECOVERY.

**Kondisi:** Offline simulasi tanpa cache. **Hasil bagian:** Tidak ada data buatan tambahan untuk menggantikan kegagalan.

- [ ] **KC-S04-01** · `feat` · Menampilkan empty state offline tanpa data
  - **Selesai jika:** Pesan Belum ada data yang bisa ditampilkan sesuai sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S04-02** · `feat` · Menghubungkan Coba lagi offline tanpa cache
  - **Selesai jika:** Memuat katalog setelah skenario koneksi pulih.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S04-03** · `feat` · Mempertahankan navigasi tanpa cache
  - **Selesai jika:** Profil dan Pesanan tetap dapat dibuka sesuai state masing-masing.
  - PIC: — · Status: TODO · Issue: — · PR: —

### S05 — Gagal memuat Pesanan

**Versi:** KantinCerdasv0.8.0 · **Requirement:** FR-S05 · **[Referensi PNG](../design/baseline/screens/S05_gagal_memuat_pesanan.png)**

**Dependensi bagian:** P04; controller skenario DATA; RECOVERY.

**Kondisi:** Daftar pesanan pengelola gagal dimuat. **Hasil bagian:** Retry dan kembali ke dashboard tersedia.

- [ ] **KC-S05-01** · `feat` · Menampilkan gagal memuat pesanan pengelola
  - **Selesai jika:** S05 dipetakan ke pengelola sesuai app.js, bukan diasumsikan mahasiswa.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S05-02** · `feat` · Menghubungkan Coba lagi pesanan pengelola
  - **Selesai jika:** Query mempertahankan tab aktif.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S05-03** · `feat` · Menghubungkan Kembali ke dashboard saat gagal
  - **Selesai jika:** Membuka P01/P03 sesuai status stan.
  - PIC: — · Status: TODO · Issue: — · PR: —

### S06 — Detail stan tutup

**Versi:** KantinCerdasv0.8.0 · **Requirement:** FR-S06 · **[Referensi PNG](../design/baseline/screens/S06_detail_stan_tutup.png)**

**Dependensi bagian:** M06; controller skenario DATA; RECOVERY.

**Kondisi:** Mahasiswa membuka stan tutup. **Hasil bagian:** Menu dapat dilihat tetapi tidak dapat dipesan dari stan ini.

- [ ] **KC-S06-01** · `feat` · Menampilkan badge Tutup detail stan
  - **Selesai jika:** Nilai berasal dari isOpen false.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S06-02** · `feat` · Menampilkan banner stan tidak menerima pesanan
  - **Selesai jika:** Copy mengikuti sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S06-03** · `feat` · Menghilangkan aksi tambah di katalog stan tutup
  - **Selesai jika:** Tidak ada mutasi tambah melalui row.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S06-04** · `feat` · Menonaktifkan pemesanan dari detail menu stan tutup
  - **Selesai jika:** Guard berlaku walaupun route M08 dibuka langsung.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S06-05** · `feat` · Mempertahankan pencarian stan tutup
  - **Selesai jika:** Katalog masih dapat ditelusuri.
  - PIC: — · Status: TODO · Issue: — · PR: —

### S07 — Detail menu habis

**Versi:** KantinCerdasv0.8.0 · **Requirement:** FR-S07 · **[Referensi PNG](../design/baseline/screens/S07_detail_menu_habis.png)**

**Dependensi bagian:** M08; controller skenario DATA; RECOVERY.

**Kondisi:** Detail menu dengan availability habis. **Hasil bagian:** Mahasiswa diarahkan ke menu lain pada stan sama.

- [ ] **KC-S07-01** · `feat` · Menampilkan badge Habis detail menu
  - **Selesai jika:** Fixture ayam dibuat habis khusus skenario ini.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S07-02** · `feat` · Menampilkan banner menu sedang habis
  - **Selesai jika:** Tidak ada tombol Tambah ke keranjang aktif.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S07-03** · `feat` · Menghubungkan Lihat menu lain dari stan ini
  - **Selesai jika:** Kembali ke katalog stan menu tersebut.
  - PIC: — · Status: TODO · Issue: — · PR: —

### S08 — Pembaruan status gagal

**Versi:** KantinCerdasv0.8.0 · **Requirement:** FR-S08 · **[Referensi PNG](../design/baseline/screens/S08_pembaruan_status_gagal.png)**

**Dependensi bagian:** M32; controller skenario DATA; RECOVERY.

**Kondisi:** Refresh status mahasiswa gagal setelah data pernah dimuat. **Hasil bagian:** Status terakhir tetap terlihat.

- [ ] **KC-S08-01** · `feat` · Menampilkan banner pembaruan status gagal
  - **Selesai jika:** Copy Status belum dapat diperbarui sesuai sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S08-02** · `feat` · Mempertahankan timeline cache mahasiswa
  - **Selesai jika:** Status tetap Diproses dan data tidak dihapus.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S08-03** · `feat` · Menampilkan waktu sinkronisasi terakhir
  - **Selesai jika:** Fixture 12.08 tidak diperbarui ketika refresh gagal.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S08-04** · `feat` · Menghubungkan Muat ulang status
  - **Selesai jika:** Keberhasilan mengganti status dari repository.
  - PIC: — · Status: TODO · Issue: — · PR: —

### S09 — Loading daftar pesanan

**Versi:** KantinCerdasv0.8.0 · **Requirement:** FR-S09 · **[Referensi PNG](../design/baseline/screens/S09_loading_daftar_pesanan.png)**

**Dependensi bagian:** M29; controller skenario DATA; RECOVERY.

**Kondisi:** Daftar order mahasiswa mulai dimuat. **Hasil bagian:** Skeleton diganti data atau empty state setelah operasi berakhir.

- [ ] **KC-S09-01** · `feat` · Menampilkan skeleton daftar pesanan
  - **Selesai jika:** Tiga placeholder mengikuti referensi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S09-02** · `feat` · Mempertahankan tab Aktif dan Riwayat saat loading
  - **Selesai jika:** Tab tetap terlihat.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S09-03** · `feat` · Menyelesaikan loading order
  - **Selesai jika:** Sukses berisi data ke M29; kosong ke S12; error sesuai keputusan D-09.
  - PIC: — · Status: TODO · Issue: — · PR: —

### S10 — Gagal memuat katalog

**Versi:** KantinCerdasv0.8.0 · **Requirement:** FR-S10 · **[Referensi PNG](../design/baseline/screens/S10_gagal_memuat_katalog.png)**

**Dependensi bagian:** M01; controller skenario DATA; RECOVERY.

**Kondisi:** Katalog gagal dimuat tanpa data sebelumnya. **Hasil bagian:** Pengguna dapat mencoba kembali.

- [ ] **KC-S10-01** · `feat` · Menampilkan pesan katalog gagal
  - **Selesai jika:** Menu belum dapat dimuat sesuai sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S10-02** · `feat` · Menghubungkan Coba lagi katalog gagal
  - **Selesai jika:** Satu request aktif dan skeleton S01 selama percobaan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S10-03** · `feat` · Mempertahankan bottom navigation saat katalog gagal
  - **Selesai jika:** Destinasi mahasiswa tetap dapat digunakan.
  - PIC: — · Status: TODO · Issue: — · PR: —

### S11 — Stan belum memiliki menu

**Versi:** KantinCerdasv0.8.0 · **Requirement:** FR-S11 · **[Referensi PNG](../design/baseline/screens/S11_stan_belum_memiliki_menu.png)**

**Dependensi bagian:** M06; controller skenario DATA; RECOVERY.

**Kondisi:** Stan buka tetapi tidak memiliki menu. **Hasil bagian:** Pengguna dapat mencari stan lain.

- [ ] **KC-S11-01** · `feat` · Menampilkan pesan stan tanpa menu
  - **Selesai jika:** Tidak disamakan dengan menu sedang habis.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S11-02** · `feat` · Menghubungkan Lihat stan lain
  - **Selesai jika:** Membuka daftar stan di Beranda.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S11-03** · `feat` · Menjaga identitas stan pada empty state
  - **Selesai jika:** Foto, nama, lokasi, dan status tetap terlihat.
  - PIC: — · Status: TODO · Issue: — · PR: —

### S12 — Pesanan mahasiswa kosong

**Versi:** KantinCerdasv0.8.0 · **Requirement:** FR-S12 · **[Referensi PNG](../design/baseline/screens/S12_pesanan_mahasiswa_kosong.png)**

**Dependensi bagian:** M29; controller skenario DATA; RECOVERY.

**Kondisi:** Daftar pesanan mahasiswa sukses dengan nol order aktif. **Hasil bagian:** Pengguna diarahkan memilih menu.

- [ ] **KC-S12-01** · `feat` · Menampilkan pesan Belum ada pesanan aktif
  - **Selesai jika:** Tab Aktif tetap terpilih.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S12-02** · `feat` · Menghubungkan Cari menu dari pesanan kosong
  - **Selesai jika:** Membuka Beranda.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S12-03** · `feat` · Mempertahankan tab Riwayat saat aktif kosong
  - **Selesai jika:** Riwayat dapat dibaca walaupun Aktif nol.
  - PIC: — · Status: TODO · Issue: — · PR: —

### S13 — Antrean pengelola kosong

**Versi:** KantinCerdasv0.8.0 · **Requirement:** FR-S13 · **[Referensi PNG](../design/baseline/screens/S13_antrean_pengelola_kosong.png)**

**Dependensi bagian:** P04; controller skenario DATA; RECOVERY.

**Kondisi:** Antrean baru pengelola sukses dengan nol order. **Hasil bagian:** Tidak ada error atau pesanan rekaan.

- [ ] **KC-S13-01** · `feat` · Menampilkan pesan Belum ada pesanan baru
  - **Selesai jika:** Copy mengikuti S13.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S13-02** · `feat` · Menghitung badge Baru dari data kosong
  - **Selesai jika:** Menjadi nol pada mode interaktif; konflik snapshot D-10 dicatat.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S13-03** · `feat` · Mempertahankan akses tab lain saat antrean kosong
  - **Selesai jika:** Diproses, Siap, Riwayat tetap dapat dibuka.
  - PIC: — · Status: TODO · Issue: — · PR: —

### S14 — Filter menu kosong

**Versi:** KantinCerdasv0.8.0 · **Requirement:** FR-S14 · **[Referensi PNG](../design/baseline/screens/S14_filter_menu_kosong.png)**

**Dependensi bagian:** P15; controller skenario DATA; RECOVERY.

**Kondisi:** Filter menu pengelola menghasilkan nol item. **Hasil bagian:** Reset filter memulihkan daftar.

- [ ] **KC-S14-01** · `feat` · Menampilkan empty state filter pengelola
  - **Selesai jika:** Pesan sesuai sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S14-02** · `feat` · Menghubungkan Reset filter pengelola
  - **Selesai jika:** Query dikosongkan dan filter status menjadi Semua sesuai A-11.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S14-03** · `feat` · Mempertahankan state query ketika belum direset
  - **Selesai jika:** Input tidak hilang hanya karena hasil nol.
  - PIC: — · Status: TODO · Issue: — · PR: —

### S15 — Foto makanan gagal

**Versi:** KantinCerdasv0.8.0 · **Requirement:** FR-S15 · **[Referensi PNG](../design/baseline/screens/S15_foto_makanan_gagal.png)**

**Dependensi bagian:** M04; controller skenario DATA; RECOVERY.

**Kondisi:** Satu aset foto menu gagal dibaca. **Hasil bagian:** Kegagalan gambar tidak memblokir item.

- [ ] **KC-S15-01** · `feat` · Menampilkan placeholder foto gagal
  - **Selesai jika:** Slot gambar tetap 88 dp pada baseline normal.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S15-02** · `feat` · Mempertahankan informasi menu saat foto gagal
  - **Selesai jika:** Nama, harga, badge tetap tampil.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S15-03** · `feat` · Mempertahankan aksi tambah saat foto gagal
  - **Selesai jika:** Menu available tetap dapat ditambahkan.
  - PIC: — · Status: TODO · Issue: — · PR: —

### S16 — Gagal ubah status

**Versi:** KantinCerdasv0.8.0 · **Requirement:** FR-S16 · **[Referensi PNG](../design/baseline/screens/S16_gagal_ubah_status.png)**

**Dependensi bagian:** P09; controller skenario DATA; RECOVERY.

**Kondisi:** Transisi processing ke ready gagal. **Hasil bagian:** Status lama tetap berlaku dan retry eksplisit tersedia.

- [ ] **KC-S16-01** · `feat` · Menampilkan banner Status belum berubah
  - **Selesai jika:** Pesanan tetap Diproses sesuai referensi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S16-02** · `feat` · Mengganti label CTA retry siap
  - **Selesai jika:** Coba tandai siap diambil mengikuti sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S16-03** · `feat` · Menghubungkan retry perubahan status
  - **Selesai jika:** Expected status/version mencegah transisi dari data usang.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S16-04** · `feat` · Mencegah sukses palsu saat status gagal
  - **Selesai jika:** Mahasiswa dan dashboard tetap melihat status lama.
  - PIC: — · Status: TODO · Issue: — · PR: —

### S17 — Pengelola offline

**Versi:** KantinCerdasv0.8.0 · **Requirement:** FR-S17 · **[Referensi PNG](../design/baseline/screens/S17_pengelola_offline.png)**

**Dependensi bagian:** P04; controller skenario DATA; RECOVERY.

**Kondisi:** Pengelola offline dengan cache order. **Hasil bagian:** Antrean hanya baca sampai simulasi online pulih.

- [ ] **KC-S17-01** · `feat` · Menampilkan banner offline pengelola
  - **Selesai jika:** Data terakhir 12.06 sesuai fixture.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S17-02** · `feat` · Mempertahankan daftar antrean cache
  - **Selesai jika:** Nama, waktu, jumlah masih dapat dibaca.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S17-03** · `feat` · Memblokir mutasi order saat offline
  - **Selesai jika:** Terima, Tolak, Tandai siap, Selesaikan tidak memanggil repository mutasi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S17-04** · `feat` · Memblokir mutasi stan saat offline
  - **Selesai jika:** Update isOpen, availability, dan settings tidak dijalankan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-S17-05** · `feat` · Menghubungkan Coba lagi pengelola offline
  - **Selesai jika:** Refresh memuat snapshot terbaru sebelum mengaktifkan kembali mutasi.
  - PIC: — · Status: TODO · Issue: — · PR: —


<a id="release-0-9-0"></a>

## KantinCerdasv0.9.0 — Responsif, aksesibilitas, dan verifikasi

**Target:** 46 task · **Gate milestone:** Keputusan pending ditutup, bukti 88 referensi terkumpul, alur kritis diuji.

### Q01 — Beranda cart — 360 dp

**Versi:** KantinCerdasv0.9.0 · **Requirement:** FR-Q01 · **[Referensi PNG](../design/baseline/screens/Q01_beranda_cart_360_dp.png)**

**Dependensi bagian:** M03; golden environment QA.

**Kondisi:** M03 pada viewport 360 × 800 dp. **Hasil bagian:** Konten beranda dan cart tetap dapat dioperasikan di layar sempit.

- [ ] **KC-Q01-01** · `test` · Mengatur viewport uji Q01
  - **Selesai jika:** Golden memakai 360 × 800 logical pixels dengan text scale 1.0.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-Q01-02** · `feat` · Menyesuaikan row menu pada 360 dp
  - **Selesai jika:** Kontrol jumlah berpindah mengikuti sumber tanpa overflow horizontal.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-Q01-03** · `test` · Memeriksa sticky cart pada 360 dp
  - **Selesai jika:** Nilai total dan tombol keranjang tetap terbaca.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-Q01-04** · `test` · Memeriksa FAB pada 360 dp
  - **Selesai jika:** Tidak menutupi CTA cart atau navigasi.
  - PIC: — · Status: TODO · Issue: — · PR: —

### Q02 — Detail stan — 412 dp

**Versi:** KantinCerdasv0.9.0 · **Requirement:** FR-Q02 · **[Referensi PNG](../design/baseline/screens/Q02_detail_stan_412_dp.png)**

**Dependensi bagian:** M07; golden environment QA.

**Kondisi:** M07 pada viewport 412 × 915 dp. **Hasil bagian:** Detail stan tetap sesuai komposisi referensi lebar.

- [ ] **KC-Q02-01** · `test` · Mengatur viewport uji Q02
  - **Selesai jika:** Golden memakai 412 × 915 logical pixels.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-Q02-02** · `feat` · Menyesuaikan hero stan pada 412 dp
  - **Selesai jika:** Crop mengikuti sumber tanpa distorsi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-Q02-03** · `test` · Memeriksa row stan pada 412 dp
  - **Selesai jika:** Informasi dan jumlah tetap sejajar.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-Q02-04** · `test` · Memeriksa footer stan pada 412 dp
  - **Selesai jika:** Cart, FAB, navigasi, safe area tidak bertumpuk.
  - PIC: — · Status: TODO · Issue: — · PR: —

### Q03 — Beranda teks 150%

**Versi:** KantinCerdasv0.9.0 · **Requirement:** FR-Q03 · **[Referensi PNG](../design/baseline/screens/Q03_beranda_teks_150.png)**

**Dependensi bagian:** M03/S01; D-01/D-03.

**Kondisi:** Target beranda pada text scale 150%; PNG sumber justru identik S01. **Hasil bagian:** Pengujian text scale berjalan; kelulusan visual menunggu D-01.

- [ ] **KC-Q03-01** · `docs` · Mencatat konflik gambar Q03
  - **Selesai jika:** Hash duplikat S01 dicatat tanpa menimpa gambar sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-Q03-02** · `test` · Mengatur uji teks 150 persen beranda
  - **Selesai jika:** TextScaler sistem disetel 1.5 pada fixture M03.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-Q03-03** · `test` · Memeriksa akses konten beranda pada teks besar
  - **Selesai jika:** Tidak mengecilkan font untuk memaksa cocok; semua konten dapat digulir.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-Q03-04** · `docs` · Menentukan referensi golden Q03
  - **Selesai jika:** BLOCKED oleh D-01 sampai pemilik desain menetapkan acuan.
  - PIC: — · Status: BLOCKED · Issue: — · PR: — · Blocker: D-01

### Q04 — Rekomendasi teks panjang

**Versi:** KantinCerdasv0.9.0 · **Requirement:** FR-Q04 · **[Referensi PNG](../design/baseline/screens/Q04_rekomendasi_teks_panjang.png)**

**Dependensi bagian:** M14; D-03 dan golden environment.

**Kondisi:** M14 dengan nama menu panjang di 360 × 800 dp dan teks besar. **Hasil bagian:** Nama panjang tetap terbaca dan aksi dapat dijangkau.

- [ ] **KC-Q04-01** · `feat` · Menambahkan fixture nama menu panjang
  - **Selesai jika:** Nasi Ayam Sambal Matah dengan Lalapan Segar sesuai sumber.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-Q04-02** · `test` · Mengatur uji viewport Q04
  - **Selesai jika:** 360 × 800 dp, text scale 1.5; catat perbedaan CSS manual dalam D-03.
  - PIC: — · Status: BLOCKED · Issue: — · PR: — · Blocker: D-03

- [ ] **KC-Q04-03** · `feat` · Membuat nama kandidat membungkus
  - **Selesai jika:** Tidak terpotong dengan ellipsis yang menyembunyikan informasi utama.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-Q04-04** · `test` · Memeriksa kontrol jumlah kandidat panjang
  - **Selesai jika:** Tombol tetap dapat dijangkau dengan scroll.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-Q04-05** · `test` · Memeriksa footer rekomendasi teks panjang
  - **Selesai jika:** Total dan aksi tetap terlihat tanpa overlay konten penting.
  - PIC: — · Status: TODO · Issue: — · PR: —

### Q05 — Keranjang delapan porsi

**Versi:** KantinCerdasv0.9.0 · **Requirement:** FR-Q05 · **[Referensi PNG](../design/baseline/screens/Q05_keranjang_delapan_porsi.png)**

**Dependensi bagian:** M17; fixture delapan porsi.

**Kondisi:** Cart berisi delapan porsi, empat jenis menu. **Hasil bagian:** Total Rp94.000 dan seluruh catatan dapat diperiksa.

- [ ] **KC-Q05-01** · `feat` · Menambahkan fixture delapan porsi
  - **Selesai jika:** Ayam 3, telur 2, teh 2, sayur 1; sayur available khusus skenario.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-Q05-02** · `feat` · Menghitung total fixture besar
  - **Selesai jika:** 54000 + 24000 + 10000 + 6000 = 94000.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-Q05-03** · `feat` · Menghitung label porsi dan jenis
  - **Selesai jika:** 8 porsi dan 4 jenis menu tampil.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-Q05-04** · `feat` · Membungkus catatan item panjang
  - **Selesai jika:** Catatan ayam dan teh tidak menutup kontrol lain.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-Q05-05** · `feat` · Membuat cart panjang dapat digulir
  - **Selesai jika:** Item terakhir dan catatan pesanan dapat dijangkau di atas footer.
  - PIC: — · Status: TODO · Issue: — · PR: —

### Q06 — Cart dengan keyboard

**Versi:** KantinCerdasv0.9.0 · **Requirement:** FR-Q06 · **[Referensi PNG](../design/baseline/screens/Q06_cart_dengan_keyboard.png)**

**Dependensi bagian:** M17; D-02 dan keyboard test.

**Kondisi:** Input catatan cart aktif pada viewport 360 × 800 dp. **Hasil bagian:** Keyboard tidak menghilangkan draft; koreksi crop menunggu D-02.

- [ ] **KC-Q06-01** · `test` · Mengatur uji keyboard Q06
  - **Selesai jika:** Viewport logical 360 × 800 dengan insets keyboard nyata/simulasi uji.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-Q06-02** · `feat` · Mempertahankan catatan cart selama fokus
  - **Selesai jika:** Teks panjang sesuai fixture tidak hilang.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-Q06-03** · `feat` · Menyembunyikan footer cart saat keyboard aktif
  - **Selesai jika:** Mengikuti sumber yang tidak merender footer pada Q06.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-Q06-04** · `feat` · Memulihkan footer setelah keyboard ditutup
  - **Selesai jika:** Total dan Lanjut konfirmasi kembali dengan nilai terbaru.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-Q06-05** · `test` · Memeriksa lebar konten Q06
  - **Selesai jika:** Tidak menjadikan crop 390 ke 360 sebagai perilaku aplikasi; kelulusan visual bergantung D-02.
  - PIC: — · Status: BLOCKED · Issue: — · PR: — · Blocker: D-02

### QA — Review visual, integrasi, dan keputusan

**Versi:** KantinCerdasv0.9.0 · **Dependensi bagian:** Semua varian S tersedia; screen Q disiapkan pada milestone ini.

- [ ] **KC-QA-01** · `docs` · Menutup keputusan D-01 Q03
  - **Selesai jika:** Acuan Q03 yang sah dicatat oleh pemilik desain.
  - PIC: — · Status: BLOCKED · Issue: — · PR: — · Blocker: D-01

- [ ] **KC-QA-02** · `docs` · Menutup keputusan D-02 crop dan keyboard
  - **Selesai jika:** Perilaku/layout final disetujui tanpa menimpa baseline lama.
  - PIC: — · Status: BLOCKED · Issue: — · PR: — · Blocker: D-02

- [ ] **KC-QA-03** · `docs` · Menutup keputusan D-03 tipografi dan target sentuh
  - **Selesai jika:** Pengecualian per komponen ditetapkan.
  - PIC: — · Status: BLOCKED · Issue: — · PR: — · Blocker: D-03

- [ ] **KC-QA-04** · `docs` · Menutup keputusan D-04 kontrol detail pengelola
  - **Selesai jika:** Perilaku dan treatment kontrol final dinyatakan jelas.
  - PIC: — · Status: BLOCKED · Issue: — · PR: — · Blocker: D-04

- [ ] **KC-QA-05** · `docs` · Menutup keputusan D-06 footer ditolak
  - **Selesai jika:** Instruksi final konsisten dengan tidak ditagihkan.
  - PIC: — · Status: BLOCKED · Issue: — · PR: — · Blocker: D-06

- [ ] **KC-QA-06** · `docs` · Menutup keputusan D-07 isi bantuan
  - **Selesai jika:** Tujuan tap lima row bantuan memiliki acuan.
  - PIC: — · Status: BLOCKED · Issue: — · PR: — · Blocker: D-07

- [ ] **KC-QA-07** · `docs` · Menutup keputusan D-08 tujuan logout
  - **Selesai jika:** Tidak ada route login baru tanpa keputusan.
  - PIC: — · Status: BLOCKED · Issue: — · PR: — · Blocker: D-08

- [ ] **KC-QA-08** · `docs` · Menutup keputusan D-09 error tambahan
  - **Selesai jika:** Pesan dan posisi error yang belum tergambar disepakati.
  - PIC: — · Status: BLOCKED · Issue: — · PR: — · Blocker: D-09

- [ ] **KC-QA-09** · `test` · Menyiapkan lingkungan golden tetap
  - **Selesai jika:** SDK, font, locale, clock, viewport dikunci.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-QA-10** · `test` · Membuat golden komponen F00
  - **Selesai jika:** Komponen yang dipakai banyak layar terlindungi regresi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-QA-11** · `test` · Membuat golden cart dan checkout
  - **Selesai jika:** Kasus dua porsi, availability berubah, unknown tercakup.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-QA-12** · `test` · Memeriksa semantics aksi utama
  - **Selesai jika:** Nama tombol dan status disabled/selected benar.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-QA-13** · `test` · Menjalankan journey order sampai selesai
  - **Selesai jika:** AT-06 terbukti dalam satu DemoStore lintas peran.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-QA-14** · `test` · Menjalankan journey order ditolak
  - **Selesai jika:** AT-07 terbukti dengan alasan yang sama pada kedua peran.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-QA-15** · `test` · Menjalankan journey recovery submission
  - **Selesai jika:** AT-08 sampai AT-10 terbukti tanpa duplikasi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-QA-16** · `test` · Memeriksa seluruh 88 referensi
  - **Selesai jika:** Setiap ID memiliki bukti visual dan hasil PASS/BLOCKED/FAIL, bukan klaim agregat kosong.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-QA-17** · `test` · Memeriksa penggunaan tanpa jaringan nyata
  - **Selesai jika:** Font, foto, fixture normal tetap dimuat lokal.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-QA-18** · `test` · Memeriksa TalkBack pada alur utama
  - **Selesai jika:** Pilih menu, cart, buat order, pantau dapat dinavigasi.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-QA-19** · `test` · Memeriksa lifecycle saat operasi tertunda
  - **Selesai jika:** Back/pindah tab selama delay tidak crash atau menghapus state baru.
  - PIC: — · Status: TODO · Issue: — · PR: —


<a id="release-1-0-0"></a>

## KantinCerdasv1.0.0 — Flutter UI Demo lengkap

**Target:** 12 task · **Gate milestone:** Tidak ada blocker wajib; build demo dan smoke test lulus sebelum tag dibuat.

### REL — Rilis lengkap Flutter UI Demo

**Versi:** KantinCerdasv1.0.0 · **Dependensi bagian:** Seluruh milestone sebelumnya selesai dan keputusan visual/fungsional yang menghalangi sudah ditutup.

- [ ] **KC-REL-01** · `docs` · Memeriksa status seluruh task
  - **Selesai jika:** Tidak ada TODO/BLOCKED wajib yang disamarkan sebagai selesai.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-REL-02** · `docs` · Memperbarui README sesuai implementasi aktual
  - **Selesai jika:** Perintah run telah diuji dan scope dummy dinyatakan jelas.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-REL-03** · `docs` · Menulis catatan rilis demo
  - **Selesai jika:** Daftar kemampuan, keterbatasan, versi SDK, dan bukti pengujian tersedia.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-REL-04** · `chore` · Menetapkan versi aplikasi 1.0.0
  - **Selesai jika:** pubspec menggunakan 1.0.0+<buildNumber> dengan build number naik.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-REL-05** · `chore` · Memeriksa hash baseline akhir
  - **Selesai jika:** Sumber locked sesuai manifest; keputusan tambahan terarsip terpisah.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-REL-06** · `ci` · Menjalankan quality gate akhir
  - **Selesai jika:** Format, analyze, unit/widget/integration yang diwajibkan lulus.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-REL-07** · `chore` · Membangun APK demo mahasiswa
  - **Selesai jika:** Artifact dibuat dari commit calon rilis untuk entry point mahasiswa.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-REL-08** · `chore` · Membangun APK demo pengelola
  - **Selesai jika:** Artifact dibuat dari commit yang sama untuk entry point pengelola.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-REL-09** · `test` · Melakukan smoke test APK demo
  - **Selesai jika:** Aplikasi terpasang dan alur kritis berjalan pada target Android yang dicatat.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-REL-10** · `chore` · Memeriksa kesiapan distribusi aset
  - **Selesai jika:** Sumber dan hak penggunaan font/foto dicatat sebelum distribusi publik.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-REL-11** · `chore` · Membuat tag KantinCerdasv1.0.0
  - **Selesai jika:** Hanya pada commit yang telah lolos gate; tag tidak dipindahkan setelah dipublikasikan.
  - PIC: — · Status: TODO · Issue: — · PR: —

- [ ] **KC-REL-12** · `docs` · Mencatat backlog backend terpisah
  - **Selesai jika:** Tidak mengklaim integrasi API/AI/push/payment sudah tersedia.
  - PIC: — · Status: TODO · Issue: — · PR: —


## Sesudah demo: backlog backend yang belum dijadwalkan

Bagian ini bukan janji fitur atau versi. Setelah UI demo selesai, tim perlu menyepakati autentikasi/peran server, kontrak API, database, validasi harga/availability, idempotency create order, status concurrency, persistensi, sinkronisasi antardevice, error mapping, serta kebutuhan AI dan push. Pecah pekerjaan menjadi task baru setelah pilihan backend jelas. Tidak ada implementasi backend dalam 644 task tahap ini.
