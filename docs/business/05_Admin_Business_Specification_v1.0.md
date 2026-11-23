# Admin Business Specification v1.0

**Produk:** Kantin Cerdas · **Status keputusan bisnis:** FINAL · LOCKED · **Versi baseline:** 1.0

**Cakupan:** Mengatur pengajuan Owner, review manual, pengelolaan status akun, pengaman pesanan aktif, keterpesanan kantin saat Owner nonaktif, pengawasan read-only, dan dashboard administratif.

> **Status verifikasi teks:** 7/7 persetujuan asli tersedia verbatim dan telah diverifikasi SHA-256. Status FINAL dari semua aturan tidak berubah.

## Catatan implementasi Android · 19 November 2026

**Operasi akun dengan pesanan aktif.** Pesanan yang telah berstatus Gagal Diambil (ORDER-013B) dikeluarkan dari indikator pesanan aktif. Jika pengguna masih memiliki pesanan aktif lain, perlindungan tetap berlaku. Tindakan akun memerlukan permintaan dan pemeriksaan baru. Pada penonaktifan atau persetujuan Owner, baca keadaan terbaru dalam transaksi yang juga mengendalikan checkout. Lindungi Admin aktif terakhir ketika dua permintaan datang bersamaan. Uji akses dan riwayat melalui M1 pada dokumen 08.

**Regresi Android.** Pada implementasi terdahulu, AdminMutationController membaca adminMutationProvider yang mengamati controller yang sama. Uji M2 memeriksa bahwa tindakan sah dari tombol Admin mencapai backend dan UI menampilkan hasilnya.

## Ikhtisar modul (penjelasan, bukan naskah persetujuan)

Mengatur pengajuan Owner, review manual, pengelolaan status akun, pengaman pesanan aktif, keterpesanan kantin saat Owner nonaktif, pengawasan read-only, dan dashboard administratif.

- **Alur dan prinsip:** Admin bertanggung jawab pada administrasi akun, bukan transaksi operasional. Pengajuan Owner memiliki keputusan manual dengan alasan penolakan wajib; Admin hanya mengakses indikator pesanan aktif saat pemeriksaan yang disetujui.
- **Batas cakupan:** Tidak ada akses Admin ke detail pesanan, harga/menu yang dapat diedit, operasi kantin, pembayaran, dashboard transaksi, atau keuangan.

## Daftar keputusan yang dikunci

| ID | Topik | Status | Naskah verbatim |
|---|---|---|---|
| [ADMIN-001](#admin-001) | Form pengajuan Owner yang ringkas | **FINAL · LOCKED** | Terverifikasi |
| [ADMIN-002](#admin-002) | Review manual pengajuan Owner | **FINAL · LOCKED** | Terverifikasi |
| [ADMIN-003](#admin-003) | Aktif/nonaktif akun dan riwayat tindakan | **FINAL · LOCKED** | Terverifikasi |
| [ADMIN-003A](#admin-003a) | Larangan penonaktifan saat ada pesanan aktif | **FINAL · LOCKED** | Terverifikasi |
| [ADMIN-003B](#admin-003b) | Owner nonaktif dan kelayakan checkout kantin | **FINAL · LOCKED** | Terverifikasi |
| [ADMIN-004](#admin-004) | Pengawasan data dasar kantin read-only | **FINAL · LOCKED** | Terverifikasi |
| [ADMIN-005](#admin-005) | Dashboard Admin dan perlindungan akses | **FINAL · LOCKED** | Terverifikasi |

---

## Rincian per aturan

<a id="admin-001"></a>

### ADMIN-001 — Form pengajuan Owner yang ringkas

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> Untuk Kantin Cerdas, ADMIN-001 saya memilih A: pengajuan menjadi Owner menggunakan nama rencana kantin, rencana lokasi usaha, dan alasan singkat; identitas berasal dari akun Customer; tidak perlu foto atau dokumen tambahan.

**SHA-256 naskah persetujuan UTF-8 (tanpa penanda kutipan atau newline):** `9d1131d438e15da4d914b5cf4738b3c37666a8b3127548543d2720d44119e5b8`

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Customer mengajukan menjadi Owner dengan nama rencana kantin, lokasi usaha yang direncanakan, dan alasan singkat; identitas diambil dari akun Customer.

**Rincian perilaku yang tercakup:**

- Tidak wajib foto lokasi atau dokumen pendukung.
- Pengajuan bukan pembuatan atau publikasi kantin.
- Setelah persetujuan role, Owner membuat kantinnya sesuai aturan OWNER.

**Batasan yang harus dijaga:** Tidak menambahkan KTP, perizinan, atau foto sebagai syarat pengajuan tanpa keputusan baru.

**Keterkaitan aturan:** CUSTOMER-006, OWNER-001, OWNER-002.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Form hanya memerlukan tiga input rencana usaha, sementara identitas akun terisi dari autentikasi.

---

<a id="admin-002"></a>

### ADMIN-002 — Review manual pengajuan Owner

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> Untuk Kantin Cerdas, ADMIN-002 saya memilih A: review pengajuan Owner dilakukan manual oleh Admin dengan status Menunggu Review, Disetujui, atau Ditolak; penolakan wajib alasan; satu pengajuan menunggu per Customer; pengajuan ulang boleh setelah ditolak; Admin memeriksa indikator pesanan aktif tanpa melihat detail transaksi.

**SHA-256 naskah persetujuan UTF-8 (tanpa penanda kutipan atau newline):** `42eaeaf01bdb13b80d095d54025bf88fe6226787f519bb839c9138b361fceea9`

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Admin meninjau pengajuan dengan tiga status: **Menunggu Review**, **Disetujui**, atau **Ditolak**; penolakan memerlukan alasan.

**Rincian perilaku yang tercakup:**

- Maksimal satu pengajuan menunggu review per Customer.
- Setelah ditolak, Customer boleh mengajukan ulang.
- Admin hanya memeriksa indikator pesanan aktif, tidak memperoleh detail transaksi.

**Batasan yang harus dijaga:** Tidak ada status review bertingkat, revisi wajib, atau aktivasi role otomatis yang tertunda.

**Keterkaitan aturan:** CUSTOMER-006A, ADMIN-001, AUTH-003.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Ajukan dua pengajuan pending dan coba menyetujui pemohon yang masih memiliki pesanan aktif; pastikan aturan tetap ditegakkan.

---

<a id="admin-003"></a>

### ADMIN-003 — Aktif/nonaktif akun dan riwayat tindakan

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> Untuk Kantin Cerdas, ADMIN-003 saya memilih A: Admin dapat melihat informasi dasar akun, menonaktifkan dengan alasan wajib dan mengaktifkan kembali; setiap tindakan dicatat; tidak ada penghapusan akun dari dashboard Admin untuk MVP.

**SHA-256 naskah persetujuan UTF-8 (tanpa penanda kutipan atau newline):** `6992f9c332505967df301fe791895562a48c8b2aeee639d78169565e8cb2dcd8`

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Admin dapat membaca informasi dasar akun, menonaktifkan dengan alasan wajib, mengaktifkan kembali, dan setiap tindakan dicatat.

**Rincian perilaku yang tercakup:**

- Tidak ada fasilitas penghapusan akun dalam dashboard Admin MVP.
- Pemeriksaan kewenangan Admin dan status akun berlaku sebelum tindakan.
- Penonaktifan Customer/Owner tunduk pada ADMIN-003A.

**Batasan yang harus dijaga:** Admin tidak boleh melihat password/token ataupun memperlakukan penonaktifan sebagai penghapusan riwayat.

**Keterkaitan aturan:** AUTH-003, ADMIN-003A, ADMIN-005.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Coba menonaktifkan tanpa alasan, mengaktifkan kembali, dan mencari jejak keputusan Admin.

---

<a id="admin-003a"></a>

### ADMIN-003A — Larangan penonaktifan saat ada pesanan aktif

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> Untuk Kantin Cerdas, ADMIN-003A saya memilih A: penonaktifan Customer atau Owner ditolak jika masih memiliki pesanan aktif; Admin hanya melihat indikator tanpa detail transaksi; penonaktifan dapat dilakukan setelah semua pesanan berstatus akhir, tanpa penundaan otomatis.

**SHA-256 naskah persetujuan UTF-8 (tanpa penanda kutipan atau newline):** `c3e30436eab1e0ee6694fd9d9ecca5c251a0fa555247289b48fd369d569682cf`

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Penonaktifan Customer atau Owner ditolak ketika masih memiliki pesanan aktif; Admin hanya melihat indikator agregat ada/tidaknya.

**Rincian perilaku yang tercakup:**

- Setelah semua pesanan terkait mencapai status akhir, penonaktifan boleh dilakukan.
- Tidak ada penjadwalan penonaktifan otomatis.
- Admin tidak perlu mengetahui isi transaksi yang menyebabkan penolakan.

**Batasan yang harus dijaga:** Tidak boleh membatalkan/mengubah pesanan untuk memudahkan penonaktifan.

**Keterkaitan aturan:** ORDER-013B, ORDER-014, ADMIN-003.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Akun dengan pesanan Menunggu Konfirmasi, Diproses, atau Siap Diambil tidak dapat dinonaktifkan.

---

<a id="admin-003b"></a>

### ADMIN-003B — Owner nonaktif dan kelayakan checkout kantin

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> Untuk Kantin Cerdas, ADMIN-003B saya memilih A: ketika akun Owner nonaktif, kantinnya tidak dapat menerima pesanan baru meskipun masih berstatus Buka; status Buka/Tutup dan publikasi tidak diubah otomatis; Customer diberi informasi kantin sementara tidak menerima pesanan .

**SHA-256 naskah persetujuan UTF-8 (tanpa penanda kutipan atau newline):** `464881419e0bda639f47676bd1db07608d4d73efe42ca33c5fb4e9188b96899d`

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Ketika Owner nonaktif, kantinnya tidak menerima pesanan baru sekalipun status tersimpan masih Buka.

**Rincian perilaku yang tercakup:**

- Status Buka/Tutup tidak diubah otomatis.
- Publikasi kantin tidak diubah otomatis.
- Customer mendapat informasi bahwa kantin sementara tidak menerima pesanan.

**Batasan yang harus dijaga:** Larangan checkout tidak memberikan Admin kemampuan mengubah Buka/Tutup dan tidak menghapus kantin dari katalog.

**Keterkaitan aturan:** ORDER-007, OWNER-002B, ADMIN-004.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Nonaktifkan Owner dengan kantin Buka dan tanpa pesanan aktif; kantin tetap ditampilkan tetapi checkout ditolak.

---

<a id="admin-004"></a>

### ADMIN-004 — Pengawasan data dasar kantin read-only

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> Untuk Kantin Cerdas, ADMIN-004 saya memilih A: Admin dapat melihat daftar dan informasi dasar kantin secara read-only, termasuk pemilik, lokasi, status publikasi dan Buka/Tutup; Admin tidak dapat mengedit profil, menu, harga, publikasi, operasional, maupun pesanan.

**SHA-256 naskah persetujuan UTF-8 (tanpa penanda kutipan atau newline):** `23eefd27002f96dcaa74f3a96a70091b90d9faf4d402eb39f3e317f7f71f93d6`

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Admin dapat membaca daftar dan informasi dasar kantin, termasuk Owner, lokasi, publikasi, dan Buka/Tutup.

**Rincian perilaku yang tercakup:**

- Akses hanya-baca untuk informasi yang ditentukan.
- Admin tidak mengedit profil, menu, harga, publikasi, atau operasional.
- Admin tidak mengakses rincian pesanan.

**Batasan yang harus dijaga:** Tidak ada aksi Edit Kantin, Atur Harga, Unpublish, Buka/Tutup, maupun Kelola Order pada antarmuka Admin.

**Keterkaitan aturan:** OWNER-002, ORDER-007, ADMIN-005.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Verifikasi antarmuka dan backend menolak semua upaya modifikasi kantin oleh Admin.

---

<a id="admin-005"></a>

### ADMIN-005 — Dashboard Admin dan perlindungan akses

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> Untuk Kantin Cerdas, ADMIN-005 saya memilih A: Dashboard Admin menampilkan ringkasan pengguna, pengajuan Owner, kantin, dan akun nonaktif; akses hanya untuk Admin yang sah dan aktif; tindakan penting tercatat; akun Admin tidak dibuat melalui pendaftaran umum; akun Admin aktif terakhir dilindungi; tidak ada dashboard transaksi atau keuangan.

**SHA-256 naskah persetujuan UTF-8 (tanpa penanda kutipan atau newline):** `4f15a9cceb22d6050682e9dac856fa6f13621cae998c39719e1f65f00b12fba6`

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Dashboard Admin berisi ringkasan pengguna, pengajuan Owner, kantin, dan akun nonaktif; akses hanya untuk Admin yang sah dan aktif.

**Rincian perilaku yang tercakup:**

- Tindakan penting dicatat.
- Akun Admin tidak dibuat lewat registrasi publik.
- Admin aktif terakhir dilindungi agar akses administrasi tidak habis.

**Batasan yang harus dijaga:** Tidak ada dashboard transaksi atau keuangan dan tidak ada peran Admin sebagai pengelola pesanan.

**Keterkaitan aturan:** ADMIN-003, ADMIN-004, AUTH-003.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Pastikan user non-Admin ditolak, Admin nonaktif tidak bisa bertindak, dan Admin terakhir tidak bisa dinonaktifkan.

---

## Pemeriksaan konsistensi modul

- **Hak administratif terbatas:** tidak ada mutasi pesanan, menu, harga, publikasi, atau status Buka/Tutup oleh Admin.
- **Pengaman pesanan aktif:** larangan penonaktifan memiliki prioritas sebelum status akun diubah.
- **Owner nonaktif:** jangan menerima checkout baru; pertahankan publikasi dan Buka/Tutup yang tersimpan.
- **Akun Admin terakhir:** tidak boleh terjadi penghapusan seluruh kemampuan administrasi.

---

## Perlindungan integritas keputusan

1. **FINAL · LOCKED** adalah status keputusan bisnis, **bukan** klaim bahwa seluruh kutipan aslinya telah tersedia dalam dokumen ini.
2. Bagian berlabel **NASKAH PERSETUJUAN ASLI — VERBATIM** hanya memuat kalimat yang dapat diverifikasi langsung melalui sumber persetujuan yang tersedia. Kalimat ditulis satu baris tanpa koreksi ejaan atau tanda baca.
3. Bagian **Ringkasan operasional**, **Penjabaran**, **Batasan**, dan **Skenario pemeriksaan** adalah penjelasan dari keputusan, **bukan teks verbatim dan bukan amendemen**. Jika penjabaran kurang tepat, sumber persetujuan asli yang berlaku.
4. Aturan FINAL tidak boleh diganti, digabung, dinomori ulang, atau diubah berdasarkan preferensi teknis. Hal baru hanya boleh diajukan sebagai DRAFT/amendemen terpisah melalui persetujuan pengguna.
5. Status spesifikasi ini tidak menyatakan kode, API, database, atau deployment telah dibangun dan diuji.

## Status akhir modul

- **Jumlah aturan:** 7 FINAL · LOCKED.
- **Persetujuan asli yang sudah diverifikasi:** 7.
- **Persetujuan asli yang masih harus diverifikasi:** 0.
- **Pelaksanaan kode/repository:** Tidak dilakukan pada pembuatan dokumen ini.
- **Catatan sumber.** Edisi awal menggunakan arsip audit 18 November 2026. Edisi ini juga merujuk pada percakapan asli. [Percakapan keputusan Kantin Cerdas](https://chatgpt.com/share/6afdc1cc-ac30-83ec-b635-1a8bf4898864)
