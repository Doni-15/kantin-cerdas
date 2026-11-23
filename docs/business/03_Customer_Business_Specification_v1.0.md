# Customer Business Specification v1.0

**Produk:** Kantin Cerdas · **Status keputusan bisnis:** FINAL · LOCKED · **Versi baseline:** 1.0

**Cakupan:** Mengatur beranda dan pencarian kantin/menu, detail, keranjang dan checkout, pelacakan pesanan, riwayat, profil, serta pengajuan role Owner.

> **Sumber keputusan.** Pemeriksaan percakapan sebelumnya memadankan 7 aturan modul ini dengan pesan pengguna. Naskah lengkapnya belum ditranskripsi verbatim di berkas ini. [Percakapan keputusan Kantin Cerdas](https://chatgpt.com/share/6afdc1cc-ac30-83ec-b635-1a8bf4898864)

## Catatan implementasi Android · 19 November 2026

**Waktu pemeriksaan pengajuan.** Pada saat Admin meninjau pengajuan Owner, periksa keadaan akun dan indikator pesanan aktif terkini. Jika masih ada pesanan aktif, Admin menolak dengan alasan. Setelah semua pesanan terminal, Customer boleh mengajukan kembali. Tidak ada promosi terjadwal.

**Pengambilan.** Code 128 hanya ditampilkan pada Siap Diambil. Pencarian manual atau pemindaian membuka identitas pesanan. Pembayaran tunai dan serah terima tetap memerlukan konfirmasi Owner (O3 dan P1 pada dokumen 08).

## Ikhtisar modul (penjelasan, bukan naskah persetujuan)

Mengatur beranda dan pencarian kantin/menu, detail, keranjang dan checkout, pelacakan pesanan, riwayat, profil, serta pengajuan role Owner.

- **Alur dan prinsip:** Customer menjelajahi kantin terbit dalam cakupan layanan tanpa memilih universitas. Pencarian utama menggabungkan pencarian nama kantin dan menu; transaksi tetap satu kantin per keranjang dan bayar tunai saat diambil.
- **Batas cakupan:** Antarmuka Customer tidak menampilkan pemilihan universitas/kampus; lokus layanan USU dan sekitarnya tetap menjadi konteks platform.

## Daftar keputusan yang dikunci

| ID | Topik | Status | Naskah verbatim |
|---|---|---|---|
| [CUSTOMER-001](#customer-001) | Beranda daftar kantin tanpa pemilihan universitas | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [CUSTOMER-002](#customer-002) | Halaman detail kantin | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [CUSTOMER-003](#customer-003) | Pencarian utama lintas kantin dan makanan | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [CUSTOMER-004](#customer-004) | Keranjang, checkout, dan pembayaran tunai | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [CUSTOMER-005](#customer-005) | Detail pesanan dan barcode pengambilan | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [CUSTOMER-006](#customer-006) | Pesanan aktif, riwayat, dan profil Customer | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [CUSTOMER-006A](#customer-006a) | Penolakan pengajuan Owner saat masih ada pesanan aktif | **FINAL · LOCKED** | Belum ditranskripsi lengkap |

---

## Rincian per aturan

<a id="customer-001"></a>

### CUSTOMER-001 — Beranda daftar kantin tanpa pemilihan universitas

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Petikan kandidat dari edisi awal. Ejaan dan kelengkapan petikan belum disertifikasi verbatim.**

> Customer langsung melihat daftar kantin yang telah diterbitkan dalam cakupan layanan Kantin Cerdas, tanpa memilih universitas. Beranda menyediakan pencarian kantin dan filter status Buka/Tutup. Kantin Tutup tetap terlihat dan menunya dapat dilihat, tetapi tidak menerima pesanan baru.

> Kantin Cerdas hanya berfokus pada lingkungan USU dan sekitarnya, tanpa pemilihan universitas. Customer langsung melihat kantin diterbitkan, dapat mencari dan memfilter Buka/Tutup. Gunakan bahasa beranda yang natural seperti Jelajahi Kantin tanpa label lokasi yang kaku.


**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Customer langsung melihat kantin yang telah diterbitkan dalam cakupan layanan Kantin Cerdas tanpa memilih universitas.

**Rincian perilaku yang tercakup:**

- Beranda menyediakan pencarian kantin dan filter Buka/Tutup.
- Kantin Tutup tetap terlihat dan menu tetap bisa dilihat, tetapi tidak menerima pesanan baru.
- Bahasa antarmuka dibuat natural seperti “Jelajahi Kantin” dan “Mau makan apa hari ini?”, bukan label lokasi kampus yang kaku.

**Batasan yang harus dijaga:** Tidak ada pemilihan universitas atau filter kampus pada beranda Customer; wilayah layanan tetap difokuskan di USU dan sekitarnya.

**Keterkaitan aturan:** OWNER-001, ORDER-007, ADMIN-003B.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Buka beranda: kantin diterbitkan muncul, termasuk Tutup; tidak ada pemilihan universitas.

---

<a id="customer-002"></a>

### CUSTOMER-002 — Halaman detail kantin

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Petikan kandidat dari edisi awal. Ejaan dan kelengkapan petikan belum disertifikasi verbatim.**

> Untuk Kantin Cerdas, CUSTOMER-002 saya memilih A: halaman detail kantin menampilkan profil, lokasi, status, jam operasional, kategori, serta menu dengan pencarian nama menu di dalam kantin.


**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Detail kantin menampilkan informasi **profil, lokasi, status, jam operasional, kategori, dan daftar menu**, dengan pencarian nama menu di dalam kantin.

**Rincian perilaku yang tercakup:**

- Jam adalah informasi, bukan pemicu perubahan Buka/Tutup.
- Ketersediaan menu mengikuti data Owner.
- Navigasi tetap mempertahankan konteks satu kantin.

**Batasan yang harus dijaga:** Pencarian dalam halaman kantin tidak dicampur dengan pencarian seluruh aplikasi.

**Keterkaitan aturan:** OWNER-003, OWNER-004, OWNER-005.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Cari menu dalam detail satu kantin; hasil tidak boleh mengambil menu kantin lain.

---

<a id="customer-003"></a>

### CUSTOMER-003 — Pencarian utama lintas kantin dan makanan

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Petikan kandidat dari edisi awal. Ejaan dan kelengkapan petikan belum disertifikasi verbatim.**

> Untuk Kantin Cerdas, CUSTOMER-003 saya memilih A: satu pencarian utama untuk nama kantin dan nama makanan dengan hasil terpisah Kantin dan Menu, mencakup seluruh kantin yang sudah diterbitkan, menampilkan harga, ketersediaan dan status Buka/Tutup.


**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Satu pencarian utama menerima nama kantin maupun nama makanan; hasil dipisahkan dalam kelompok **Kantin** dan **Menu**.

**Rincian perilaku yang tercakup:**

- Pencarian meliputi seluruh kantin yang telah diterbitkan.
- Hasil menu menampilkan harga dan ketersediaan.
- Hasil juga menunjukkan status Buka/Tutup kantin.

**Batasan yang harus dijaga:** Pencarian bukan janji bahwa semua hasil dapat dipesan; status harus ditampilkan secara benar.

**Keterkaitan aturan:** CUSTOMER-001, AI-002, OWNER-005.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Masukkan kata yang cocok dengan nama kantin dan menu; verifikasi dua kelompok hasil berbeda.

---

<a id="customer-004"></a>

### CUSTOMER-004 — Keranjang, checkout, dan pembayaran tunai

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Petikan kandidat dari edisi awal. Ejaan dan kelengkapan petikan belum disertifikasi verbatim.**

> Untuk Kantin Cerdas, CUSTOMER-004 saya memilih A: keranjang untuk mengelola item dan catatan, halaman checkout terpisah untuk konfirmasi ringkasan dan pembayaran tunai, lalu kirim pesanan dan lihat status.


**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Customer mengelola item dan catatan pada halaman **Keranjang**, lalu memakai halaman **Checkout terpisah** untuk konfirmasi ringkasan dan pembayaran tunai sebelum mengirim pesanan.

**Rincian perilaku yang tercakup:**

- Setelah berhasil mengirim, Customer dapat melihat status pesanan.
- Jumlah dan catatan mengikuti aturan ORDER-010.
- Pemeriksaan harga dan ketersediaan sebelum checkout tetap berlaku.

**Batasan yang harus dijaga:** Tidak ada checkout otomatis oleh AI, pembayaran online, atau pengantaran.

**Keterkaitan aturan:** ORDER-005 sampai ORDER-011, AI-005.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Lakukan perjalanan lengkap keranjang→checkout→pesanan; pembayaran tetap berlabel tunai.

---

<a id="customer-005"></a>

### CUSTOMER-005 — Detail pesanan dan barcode pengambilan

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Petikan kandidat dari edisi awal. Ejaan dan kelengkapan petikan belum disertifikasi verbatim.**

> Untuk Kantin Cerdas, CUSTOMER-005 saya memilih A: satu halaman detail pesanan berisi timeline realtime, ringkasan, status pembayaran, lokasi dan nomor pesanan; barcode pengambilan muncul hanya ketika Siap Diambil.


**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Satu halaman detail pesanan berisi **timeline realtime, ringkasan, status pembayaran, lokasi pengambilan, dan nomor pesanan**.

**Rincian perilaku yang tercakup:**

- Barcode pengambilan hanya muncul ketika status **Siap Diambil**.
- Timeline bersumber dari status backend yang sah.
- Customer dapat memahami kapan harus datang dan menunjukkan bukti pengambilan.

**Batasan yang harus dijaga:** Barcode tidak otomatis melunasi atau menyelesaikan pesanan.

**Keterkaitan aturan:** ORDER-015, ORDER-017, ORDER-004.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Lihat detail di status pending, diproses, siap dan selesai; barcode hanya muncul saat Siap Diambil.

---

<a id="customer-006"></a>

### CUSTOMER-006 — Pesanan aktif, riwayat, dan profil Customer

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Petikan kandidat dari edisi awal. Ejaan dan kelengkapan petikan belum disertifikasi verbatim.**

> Untuk Kantin Cerdas, CUSTOMER-006 saya memilih A: Pesanan Aktif dan Riwayat terpisah, semua status akhir tetap tersimpan dan detail dapat dibuka; profil sederhana mencakup informasi akun, pengelolaan nama/foto, pengajuan Owner, pengaturan dasar, serta logout.


**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Halaman **Pesanan Aktif** dan **Riwayat** terpisah; semua status terminal tetap disimpan dan detailnya dapat dibuka.

**Rincian perilaku yang tercakup:**

- Profil sederhana memuat informasi akun, pengelolaan nama/foto, pengajuan Owner, pengaturan dasar, dan logout.
- Status aktif bukan bagian dari riwayat terminal sampai benar-benar berakhir.
- Informasi profil mengikuti kebijakan Authentication.

**Batasan yang harus dijaga:** Semua status akhir tetap tersedia di riwayat. Untuk Gagal Diambil, tampilkan alasan dari Owner, waktu dan pembayaran Belum Lunas. Hentikan tampilan barcode dan keluarkan pesanan dari daftar aktif. Pesanan terminal ini tidak dihitung saat Admin meninjau pengajuan Owner.

**Keterkaitan aturan:** CUSTOMER-006A, AUTH-005, ORDER-002.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Setiap status terminal tetap muncul di Riwayat dan halaman detail dapat dibuka.

---

<a id="customer-006a"></a>

### CUSTOMER-006A — Penolakan pengajuan Owner saat masih ada pesanan aktif

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Petikan kandidat dari edisi awal. Ejaan dan kelengkapan petikan belum disertifikasi verbatim.**

> simple aja bilang, kan admin bisa check usernya siapa. Kalau masih ada pesanan ya tugas admin memnolak alasannya masih ada pesanan gitu, gk usah di tambahin logic susah nanti


**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Jika Customer mengajukan menjadi Owner saat masih mempunyai pesanan aktif, **Admin menolak pengajuan** dengan alasan yang menyebutkan masih ada pesanan aktif.

**Rincian perilaku yang tercakup:**

- Admin cukup melihat identitas akun dan indikator ada/tidaknya pesanan aktif, tanpa rincian transaksi.
- Setelah tidak memiliki pesanan aktif, Customer boleh mengajukan kembali.
- Pesanan terminal dalam riwayat tidak menghalangi pengajuan.

**Batasan yang harus dijaga:** Tidak ada status pengajuan ditunda atau perubahan role otomatis setelah pesanan selesai.

**Keterkaitan aturan:** ADMIN-002, ADMIN-003A, ORDER-016.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Ajukan Owner ketika ada satu pesanan aktif; Admin wajib menolak dengan alasan, bukan menunda aktivasi.

---

## Pemeriksaan konsistensi modul

- **Cakupan wilayah:** beranda langsung menampilkan kantin diterbitkan di USU dan sekitarnya, tanpa pemilihan universitas.
- **Harga dan status:** hasil pencarian bukan jaminan bahwa checkout selalu dapat dilakukan.
- **Pengajuan Owner:** Admin menolak pengajuan saat masih ada pesanan aktif, tanpa mengakses detail transaksi.
- **Barcode dan pembayaran:** barcode hanya bukti identifikasi, sedangkan pelunasan dilakukan tunai pada serah-terima.

---

## Perlindungan integritas keputusan

1. **FINAL · LOCKED** adalah status keputusan bisnis, **bukan** klaim bahwa seluruh kutipan aslinya telah tersedia dalam dokumen ini.
2. Bagian berlabel **NASKAH PERSETUJUAN ASLI — VERBATIM** hanya memuat kalimat yang dapat diverifikasi langsung melalui sumber persetujuan yang tersedia. Kalimat ditulis satu baris tanpa koreksi ejaan atau tanda baca.
3. Bagian **Ringkasan operasional**, **Penjabaran**, **Batasan**, dan **Skenario pemeriksaan** adalah penjelasan dari keputusan, **bukan teks verbatim dan bukan amendemen**. Jika penjabaran kurang tepat, sumber persetujuan asli yang berlaku.
4. Aturan FINAL tidak boleh diganti, digabung, dinomori ulang, atau diubah berdasarkan preferensi teknis. Hal baru hanya boleh diajukan sebagai DRAFT/amendemen terpisah melalui persetujuan pengguna.
5. Status spesifikasi ini tidak menyatakan kode, API, database, atau deployment telah dibangun dan diuji.

## Status akhir modul

- **Jumlah aturan:** 7 FINAL · LOCKED.
- **Keputusan yang telah dipadankan dengan percakapan:** 7.
- **Naskah persetujuan yang belum ditranskripsi lengkap dalam modul:** 7.
- **Pelaksanaan kode/repository:** Tidak dilakukan pada pembuatan dokumen ini.
- **Catatan sumber.** Edisi awal menggunakan arsip audit 18 November 2026. Edisi ini juga merujuk pada percakapan asli. [Percakapan keputusan Kantin Cerdas](https://chatgpt.com/share/6afdc1cc-ac30-83ec-b635-1a8bf4898864)
