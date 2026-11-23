# Owner Business Specification v1.0

**Produk:** Kantin Cerdas · **Status keputusan bisnis:** FINAL · LOCKED · **Versi baseline:** 1.0

**Cakupan:** Mengatur satu kantin per Owner, profil dan publikasi, jam informatif, kategori dan menu, pengarsipan, serta dashboard operasional pesanan.

> **Sumber keputusan.** Pemeriksaan percakapan sebelumnya memadankan 10 aturan modul ini dengan pesan pengguna. Naskah lengkapnya belum ditranskripsi verbatim di berkas ini. [Percakapan keputusan Kantin Cerdas](https://chatgpt.com/share/6afdc1cc-ac30-83ec-b635-1a8bf4898864)

## Catatan implementasi Android · 19 November 2026

**Kantin terlihat dan dapat menerima pesanan.** Kantin terbit yang ditutup atau milik Owner nonaktif tetap terlihat. Backend menolak checkout baru sambil mempertahankan draft serta pesanan yang telah tersimpan. Status publikasi dan Buka/Tutup tidak berubah otomatis. Uji kondisi tersebut bersama ADMIN-003B dan ORDER-007, termasuk bila penutupan terjadi bersamaan dengan checkout (K3 pada dokumen 08).

## Ikhtisar modul (penjelasan, bukan naskah persetujuan)

Mengatur satu kantin per Owner, profil dan publikasi, jam informatif, kategori dan menu, pengarsipan, serta dashboard operasional pesanan.

- **Alur dan prinsip:** Kantin diterbitkan oleh Owner ketika prasyarat terpenuhi; publikasi tidak otomatis dicabut. Buka/Tutup ditentukan Owner secara manual dan terpisah dari keterpesanan berdasarkan data menu serta status akun.
- **Batas cakupan:** Owner tidak menerima fitur penghapusan permanen menu, unpublish kantin MVP, atau dashboard statistik keuangan.

## Daftar keputusan yang dikunci

| ID | Topik | Status | Naskah verbatim |
|---|---|---|---|
| [OWNER-001](#owner-001) | Profil wajib dan opsional kantin | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [OWNER-002](#owner-002) | Satu Owner satu kantin dan publikasi awal | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [OWNER-002A](#owner-002a) | Visibilitas kantin terbit saat menu tidak dapat dipesan | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [OWNER-002B](#owner-002b) | Tidak ada unpublish manual pada MVP | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [OWNER-003](#owner-003) | Jam operasional informatif dan estimasi persiapan | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [OWNER-004](#owner-004) | Kategori menu standar dan kustom | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [OWNER-004A](#owner-004a) | Kategori hanya boleh dihapus jika benar-benar kosong | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [OWNER-005](#owner-005) | Data menu, status, arsip dan pemulihan | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [OWNER-005A](#owner-005a) | Menu diarsipkan saat masih di keranjang | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [OWNER-006](#owner-006) | Dashboard Owner operasional | **FINAL · LOCKED** | Belum ditranskripsi lengkap |

---

## Rincian per aturan

<a id="owner-001"></a>

### OWNER-001 — Profil wajib dan opsional kantin

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Profil kantin mewajibkan **nama kantin, kampus/universitas, dan lokasi fisik detail di dalam area layanan**; deskripsi dan foto kantin opsional.

**Rincian perilaku yang tercakup:**

- Lokasi menjelaskan posisi yang dapat dikenali untuk pengambilan makanan.
- Kewajiban atribut kampus pada profil tidak berarti Customer harus memilih universitas di beranda.
- Ketentuan wilayah layanan USU tidak membenarkan perubahan diam-diam terhadap daftar field OWNER-001.

**Batasan yang harus dijaga:** Deskripsi maupun foto tidak boleh dijadikan syarat wajib baru.

**Keterkaitan aturan:** CUSTOMER-001, OWNER-002.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Validasi publish dengan nama/kampus/lokasi yang lengkap serta deskripsi/foto kosong.

---

<a id="owner-002"></a>

### OWNER-002 — Satu Owner satu kantin dan publikasi awal

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Satu akun Owner hanya boleh membuat **satu kantin**, setelah role Owner disetujui Admin.

**Rincian perilaku yang tercakup:**

- Owner dapat menerbitkan kantin secara manual setelah data profil wajib lengkap dan minimal satu menu berstatus tersedia.
- Saat pertama diterbitkan, status kantin adalah **Tutup**.
- Kantin yang diterbitkan tetap terlihat meskipun belum Buka.

**Batasan yang harus dijaga:** Tidak ada pembuatan kantin kedua oleh Owner yang sama dalam MVP.

**Keterkaitan aturan:** OWNER-001, OWNER-005, OWNER-002A, OWNER-002B.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Coba publish tanpa profil wajib/menunya belum tersedia; pastikan tidak lolos, dan publish sah dimulai Tutup.

---

<a id="owner-002a"></a>

### OWNER-002A — Visibilitas kantin terbit saat menu tidak dapat dipesan

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Kantin yang sudah diterbitkan tetap terlihat walaupun semua menu **Habis** atau diarsipkan.

**Rincian perilaku yang tercakup:**

- Tidak ada unpublish otomatis.
- Tidak ada Buka/Tutup otomatis karena semua menu tidak tersedia.
- Checkout tetap tidak mungkin tanpa menu yang dapat dipesan.

**Batasan yang harus dijaga:** Visibilitas katalog tidak sama dengan kelayakan menerima pesanan.

**Keterkaitan aturan:** OWNER-002, OWNER-002B, ORDER-006.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Jadikan seluruh menu Habis/arsip; kantin tetap muncul, tetapi tidak ada item yang bisa di-checkout.

---

<a id="owner-002b"></a>

### OWNER-002B — Tidak ada unpublish manual pada MVP

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Owner **tidak dapat membatalkan publikasi** kantin yang sudah diterbitkan melalui aplikasi MVP.

**Rincian perilaku yang tercakup:**

- Owner menggunakan Buka/Tutup untuk menghentikan pesanan baru.
- Profil kantin tetap dapat dilihat Customer sesuai kebijakan publikasi.
- Aturan akun Owner nonaktif tidak mengubah publikasi otomatis.

**Batasan yang harus dijaga:** Tidak menambahkan tombol Unpublish setelah publish.

**Keterkaitan aturan:** OWNER-002A, ORDER-007, ADMIN-003B.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Kantin sudah publish kemudian Tutup; tetap tampil, dan tidak muncul aksi unpublish.

---

<a id="owner-003"></a>

### OWNER-003 — Jam operasional informatif dan estimasi persiapan

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Owner mengatur jam operasional **per hari dalam seminggu** untuk informasi, serta estimasi persiapan fleksibel dengan batas minimum dan maksimum.

**Rincian perilaku yang tercakup:**

- Status Buka/Tutup tetap diubah manual.
- Jam informasi tidak mengubah status kantin otomatis.
- Estimasi dipakai saat order diterima sesuai ORDER-012.

**Batasan yang harus dijaga:** Tidak ada auto-opening atau auto-closing berdasarkan jam operasional.

**Keterkaitan aturan:** ORDER-007, ORDER-012.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Atur jam operasional lalu lewati jadwal; status Buka/Tutup tidak berubah tanpa tindakan Owner.

---

<a id="owner-004"></a>

### OWNER-004 — Kategori menu standar dan kustom

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Kategori awal: **Makanan, Minuman, Camilan**. Owner dapat menambah dan mengelola kategori milik kantinnya.

**Rincian perilaku yang tercakup:**

- Setiap menu tepat berada dalam satu kategori.
- Pengelolaan kategori tidak boleh memengaruhi kategori milik kantin lain.
- Penghapusan kategori mengikuti OWNER-004A.

**Batasan yang harus dijaga:** Tidak ada menu tanpa kategori dalam data yang dianggap sah.

**Keterkaitan aturan:** OWNER-004A, OWNER-005.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Tambah kategori sendiri dan pastikan setiap menu masih menunjuk tepat ke satu kategori yang sah.

---

<a id="owner-004a"></a>

### OWNER-004A — Kategori hanya boleh dihapus jika benar-benar kosong

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Kategori hanya dapat dihapus jika **tidak mempunyai menu apa pun**, termasuk menu yang diarsipkan.

**Rincian perilaku yang tercakup:**

- Owner harus memindahkan semua menu terkait secara manual ke kategori lain di kantin yang sama sebelum menghapus.
- Sistem tidak memindahkan menu otomatis.
- Menu tidak terhapus akibat penghapusan kategori.

**Batasan yang harus dijaga:** Tidak boleh menghapus kategori yang masih direferensikan menu aktif atau arsip.

**Keterkaitan aturan:** OWNER-004, OWNER-005.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Coba hapus kategori yang hanya berisi menu arsip; tindakan harus ditolak sampai menu dipindahkan.

---

<a id="owner-005"></a>

### OWNER-005 — Data menu, status, arsip dan pemulihan

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Menu wajib mempunyai **nama, kategori, harga rupiah bulat, dan status Tersedia/Habis**; deskripsi dan foto opsional.

**Rincian perilaku yang tercakup:**

- Owner dapat mengarsipkan dan mengembalikan menu.
- Tidak ada penghapusan permanen menu dari antarmuka Owner.
- Order yang pernah dibuat tetap mempertahankan snapshot item dan harga lama.

**Batasan yang harus dijaga:** Tidak ada inventaris stok numerik wajib; tidak boleh mengubah snapshot pesanan lama ketika mengubah menu.

**Keterkaitan aturan:** ORDER-005, ORDER-011, OWNER-005A.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Arsip menu dan ubah harganya; periksa menu tidak hilang dari order yang sudah dibuat.

---

<a id="owner-005a"></a>

### OWNER-005A — Menu diarsipkan saat masih di keranjang

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Jika menu yang tersimpan pada keranjang Customer diarsipkan Owner, item tetap muncul dengan label **Tidak Tersedia** dan **memblokir seluruh checkout**.

**Rincian perilaku yang tercakup:**

- Customer harus menghapus atau mengganti item secara manual.
- Tidak ada penghapusan item otomatis.
- Saat menu dipulihkan, harga dan ketersediaan harus divalidasi ulang sebelum checkout.

**Batasan yang harus dijaga:** Pemulihan arsip tidak menjamin harga/status lama tetap berlaku.

**Keterkaitan aturan:** ORDER-005, ORDER-006, OWNER-005.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Arsip item keranjang, periksa label dan blok checkout; pulihkan lalu validasi ulang dengan harga terbaru.

---

<a id="owner-006"></a>

### OWNER-006 — Dashboard Owner operasional

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Dashboard Owner berfokus pada tiga kelompok pesanan aktif: **Menunggu Konfirmasi, Diproses, Siap Diambil**.

**Rincian perilaku yang tercakup:**

- Tampilkan jumlah per status, sinkronisasi realtime, detail pesanan dan tindakan yang diizinkan menurut status.
- Dari Siap Diambil, Owner dapat memilih Gagal Diambil jika kantin tidak dapat menyerahkan makanan. Minta alasan dan konfirmasi. Setelah tersimpan, pindahkan pesanan ke riwayat Owner, tampilkan alasan dan pembayaran Belum Lunas.
- Sediakan pintasan menuju menu dan pengaturan kantin.
- Riwayat pesanan disediakan secara terpisah.

**Batasan yang harus dijaga:** Tidak ada dashboard keuangan, pendapatan, atau statistik penjualan untuk Owner MVP.

**Keterkaitan aturan:** ORDER-017, ORDER-004, ORDER-003.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Hitung jumlah aktif per status dan pastikan tidak muncul fitur analitik keuangan.

---

## Pemeriksaan konsistensi modul

- **Publikasi ≠ Buka/Tutup:** kantin dapat diterbitkan namun Tutup, dan tetap terlihat saat menu tak tersedia.
- **Kelayakan checkout ≠ status tersimpan:** Owner nonaktif memblokir pesanan baru menurut ADMIN-003B, tanpa mengubah status Buka/Tutup.
- **Menu terarsip:** referensi pada keranjang dan riwayat pesanan dipertahankan menurut aturan.
- **Kampus/lokasi:** kewajiban field OWNER-001 tidak berarti beranda Customer harus menampilkan pemilihan universitas.

---

## Perlindungan integritas keputusan

1. **FINAL · LOCKED** adalah status keputusan bisnis, **bukan** klaim bahwa seluruh kutipan aslinya telah tersedia dalam dokumen ini.
2. Bagian berlabel **NASKAH PERSETUJUAN ASLI — VERBATIM** hanya memuat kalimat yang dapat diverifikasi langsung melalui sumber persetujuan yang tersedia. Kalimat ditulis satu baris tanpa koreksi ejaan atau tanda baca.
3. Bagian **Ringkasan operasional**, **Penjabaran**, **Batasan**, dan **Skenario pemeriksaan** adalah penjelasan dari keputusan, **bukan teks verbatim dan bukan amendemen**. Jika penjabaran kurang tepat, sumber persetujuan asli yang berlaku.
4. Aturan FINAL tidak boleh diganti, digabung, dinomori ulang, atau diubah berdasarkan preferensi teknis. Hal baru hanya boleh diajukan sebagai DRAFT/amendemen terpisah melalui persetujuan pengguna.
5. Status spesifikasi ini tidak menyatakan kode, API, database, atau deployment telah dibangun dan diuji.

## Status akhir modul

- **Jumlah aturan:** 10 FINAL · LOCKED.
- **Keputusan yang telah dipadankan dengan percakapan:** 10.
- **Naskah persetujuan yang belum ditranskripsi lengkap dalam modul:** 10.
- **Pelaksanaan kode/repository:** Tidak dilakukan pada pembuatan dokumen ini.
- **Catatan sumber.** Edisi awal menggunakan arsip audit 18 November 2026. Edisi ini juga merujuk pada percakapan asli. [Percakapan keputusan Kantin Cerdas](https://chatgpt.com/share/6afdc1cc-ac30-83ec-b635-1a8bf4898864)
