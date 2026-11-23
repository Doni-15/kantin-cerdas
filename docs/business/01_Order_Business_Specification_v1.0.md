# Order Business Specification v1.0

**Produk:** Kantin Cerdas · **Status keputusan bisnis:** FINAL · LOCKED · **Versi baseline:** 1.0

**Cakupan:** Mengatur keseluruhan perjalanan pesanan: pembentukan, validasi checkout, transisi status, pembayaran tunai saat pengambilan, bukti pengambilan, realtime, dan riwayat.

> **Sumber keputusan.** Pemeriksaan percakapan sebelumnya memadankan 20 aturan modul ini dengan pesan pengguna. Pesan amendemen ORDER-013B dikutip lengkap di bawah. Naskah lengkap 19 aturan lain belum ditranskripsi verbatim di berkas ini. [Percakapan keputusan Kantin Cerdas](https://chatgpt.com/share/6afdc1cc-ac30-83ec-b635-1a8bf4898864)

## Catatan implementasi Android · 19 November 2026

**Pengambilan.** BARCODE-TECH-001 menetapkan Code 128. Pada pengujian format, sembilan gambar terbaca dengan nomor yang sesuai. Pemindaian antarperangkat di lokasi mengikuti P1 di dokumen 08.

**Gagal serah setelah siap.** Jika kantin tidak dapat menyerahkan makanan yang sudah Siap Diambil, Owner dapat mengonfirmasi Gagal Diambil dengan alasan. Pesanan keluar dari daftar aktif, masuk riwayat, dan tetap belum lunas.

## Ikhtisar modul (penjelasan, bukan naskah persetujuan)

Mengatur keseluruhan perjalanan pesanan: pembentukan, validasi checkout, transisi status, pembayaran tunai saat pengambilan, bukti pengambilan, realtime, dan riwayat.

- **Alur dan prinsip:** Status pesanan: Menunggu Konfirmasi → Diproses → Siap Diambil → Selesai (Lunas). Jalur terminal khusus: Dibatalkan, Ditolak, Gagal Dipenuhi, Tidak Diambil, Gagal Diambil. Perubahan harus mengikuti hak peran dan status asal yang ditetapkan.
- **Batas cakupan:** Customer memesan dari satu kantin; Owner menyiapkan, mengonfirmasi, dan menyerahkan makanan; pembayaran dilakukan tunai ketika pengambilan. Tidak ada pengiriman, COD kurir, atau pembayaran online.

## Daftar keputusan yang dikunci

| ID | Topik | Status | Naskah verbatim |
|---|---|---|---|
| [ORDER-001](#order-001) | Pembatalan oleh Customer sebelum konfirmasi | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [ORDER-002](#order-002) | Pesanan tidak diambil | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [ORDER-003](#order-003) | Penolakan pesanan oleh Owner | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [ORDER-004](#order-004) | Penyelesaian tunai saat serah terima | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [ORDER-005](#order-005) | Perubahan harga sebelum checkout | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [ORDER-006](#order-006) | Item Habis di dalam keranjang | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [ORDER-007](#order-007) | Buka/Tutup kantin secara manual | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [ORDER-008](#order-008) | Checkout online dan idempotensi | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [ORDER-009](#order-009) | Satu kantin per keranjang dan pesanan | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [ORDER-010](#order-010) | Jumlah item, catatan, dan keranjang tersimpan | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [ORDER-011](#order-011) | Snapshot pesanan tidak dapat diedit | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [ORDER-012](#order-012) | Estimasi persiapan dan status Siap Diambil | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [ORDER-013](#order-013) | Gagal Dipenuhi setelah penerimaan | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [ORDER-013A](#order-013a) | Batas status Gagal Dipenuhi | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [ORDER-013B](#order-013b) | Gagal Diambil setelah Siap Diambil | **FINAL · LOCKED (diamendemen)** | Pesan amendemen tercantum |
| [ORDER-014](#order-014) | Syarat penandaan Tidak Diambil | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [ORDER-015](#order-015) | Bukti pengambilan dengan barcode | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [ORDER-016](#order-016) | Pesanan pending tanpa timeout otomatis | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [ORDER-017](#order-017) | Sinkronisasi realtime dan push penting | **FINAL · LOCKED** | Belum ditranskripsi lengkap |
| [ORDER-017A](#order-017a) | Tujuh kejadian notifikasi push | **FINAL · LOCKED** | Belum ditranskripsi lengkap |

---

## Rincian per aturan

<a id="order-001"></a>

### ORDER-001 — Pembatalan oleh Customer sebelum konfirmasi

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Customer boleh membatalkan pesanan miliknya hanya ketika berstatus **Menunggu Konfirmasi** dan belum diterima Owner.

**Rincian perilaku yang tercakup:**

- Tindakan pembatalan berasal dari Customer pemilik pesanan.
- Jika Owner lebih dulu menerima, pembatalan Customer tidak boleh berhasil.
- Pemeriksaan status dan perubahan status dilakukan secara atomik agar dua tindakan yang bersamaan tidak sama-sama berhasil.

**Batasan yang harus dijaga:** Tidak ada pembatalan Customer setelah pesanan masuk **Diproses** atau **Siap Diambil**.

**Keterkaitan aturan:** ORDER-003, ORDER-011, ORDER-016, ORDER-017.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Simulasikan Customer membatalkan bersamaan dengan Owner menerima; hanya satu perubahan status yang boleh menang.

---

<a id="order-002"></a>

### ORDER-002 — Pesanan tidak diambil

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Owner dapat secara manual menandai pesanan sebagai **Tidak Diambil**. Pesanan tersebut tidak dibayar dan tetap tercatat dalam riwayat.

**Rincian perilaku yang tercakup:**

- Tidak Diambil merupakan status terminal; pesanan tidak kembali ke status aktif.
- Riwayat pesanan tetap dapat dibuka untuk menunjukkan kejadian yang sebenarnya.
- Tidak ada penalti atau sanksi otomatis terhadap Customer dalam MVP.

**Batasan yang harus dijaga:** Tidak ada perubahan otomatis menjadi Lunas, Selesai, maupun penghapusan riwayat.

**Keterkaitan aturan:** ORDER-014, ORDER-004, CUSTOMER-006.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Setelah ditandai Tidak Diambil, pastikan status pembayaran belum lunas dan record tetap terlihat di riwayat.

---

<a id="order-003"></a>

### ORDER-003 — Penolakan pesanan oleh Owner

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Owner boleh menolak pesanan yang masih **Menunggu Konfirmasi**, dan **alasan penolakan wajib** serta terlihat oleh Customer.

**Rincian perilaku yang tercakup:**

- Penolakan dilakukan sebelum Owner menerima pesanan.
- Status yang ditolak menjadi status akhir dan belum dibayar.
- Customer dapat membaca alasan pada detail/riwayat pesanan.

**Batasan yang harus dijaga:** Tidak boleh menolak pesanan yang telah diterima dengan menyalahgunakan jalur penolakan pending.

**Keterkaitan aturan:** ORDER-001, ORDER-013, CUSTOMER-005.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Tolak permintaan tanpa alasan; terima alasan yang valid hanya ketika status masih Menunggu Konfirmasi.

---

<a id="order-004"></a>

### ORDER-004 — Penyelesaian tunai saat serah terima

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Owner menyelesaikan pesanan melalui satu tombol **Selesaikan Pesanan** dari status **Siap Diambil**, hanya setelah **uang tunai diterima dan makanan diserahkan**.

**Rincian perilaku yang tercakup:**

- Sebelum konfirmasi akhir, tampilkan dialog konfirmasi tindakan.
- Perubahan status **Selesai** dan pembayaran **Lunas** harus terjadi dalam satu operasi atomik.
- Customer tetap mengambil pesanan sendiri dan membayar langsung kepada Owner.

**Batasan yang harus dijaga:** Barcode, tindakan memindai, dan sekadar kesiapan makanan tidak boleh menyelesaikan pesanan otomatis.

**Keterkaitan aturan:** ORDER-015, ORDER-014, ORDER-017A.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Coba menyelesaikan pesanan tanpa kondisi serah-terima; uji bahwa status Selesai dan Lunas tidak dapat terpisah.

---

<a id="order-005"></a>

### ORDER-005 — Perubahan harga sebelum checkout

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Jika harga item keranjang berubah sebelum checkout, tampilkan harga lama dan harga baru serta minta **konfirmasi ulang secara eksplisit**.

**Rincian perilaku yang tercakup:**

- Backend menentukan harga terbaru yang sah pada saat checkout.
- Harga pada pesanan yang berhasil dibuat disimpan sebagai snapshot dan tidak berubah mengikuti pembaruan menu.
- Customer tidak boleh dibuat membayar harga baru secara diam-diam.

**Batasan yang harus dijaga:** AI dan tampilan lokal tidak menetapkan harga final secara mandiri.

**Keterkaitan aturan:** ORDER-008, ORDER-011, AI-002, AI-004.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Ubah harga setelah item ada di keranjang; checkout harus tertahan hingga perubahan dikonfirmasi.

---

<a id="order-006"></a>

### ORDER-006 — Item Habis di dalam keranjang

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Jika item dalam keranjang berubah menjadi **Habis**, item tetap terlihat dengan label Habis dan **seluruh checkout diblokir** sampai Customer mengambil tindakan.

**Rincian perilaku yang tercakup:**

- Customer secara manual menghapus atau mengganti item bermasalah.
- Sistem tidak menghapus item Habis diam-diam.
- Kondisi harus diperiksa kembali menggunakan backend.

**Batasan yang harus dijaga:** Item Habis tidak boleh tetap diproses sebagai item yang dapat dipesan.

**Keterkaitan aturan:** OWNER-005, OWNER-005A, ORDER-008.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Ubah satu dari beberapa item menjadi Habis; verifikasi bahwa item tetap terlihat dan checkout tidak dapat diselesaikan.

---

<a id="order-007"></a>

### ORDER-007 — Buka/Tutup kantin secara manual

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Owner menentukan **Buka/Tutup** sendiri. **Tutup** hanya mencegah pesanan baru dan tidak membatalkan keranjang tersimpan atau pesanan yang sudah berjalan.

**Rincian perilaku yang tercakup:**

- Pesanan yang masuk sebelum penutupan tetap harus ditangani menurut alurnya.
- Jam operasional informatif tidak otomatis mengubah Buka/Tutup.
- Kantin yang Tutup tetap bisa dilihat sesuai aturan Customer dan Owner.

**Batasan yang harus dijaga:** Tidak ada penutupan otomatis berdasarkan jam atau perubahan order otomatis saat Tutup.

**Keterkaitan aturan:** OWNER-003, OWNER-002B, CUSTOMER-001, ADMIN-003B.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Tutup kantin dengan pesanan aktif; pastikan pesanan lama tetap ada dan checkout baru ditolak.

---

<a id="order-008"></a>

### ORDER-008 — Checkout online dan idempotensi

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Checkout hanya dapat dikirim ketika online, dengan **ID idempotensi stabil per satu upaya pesanan logis** yang dijaga oleh backend/database.

**Rincian perilaku yang tercakup:**

- ID yang sama digunakan saat retry, termasuk setelah aplikasi ditutup atau dibuka ulang.
- Jika hasil respons tidak pasti, aplikasi mencari hasil checkout menggunakan identitas pengiriman yang sama, bukan membuat pesanan baru.
- Keranjang tetap tersimpan sampai keberhasilan checkout telah dipastikan.

**Batasan yang harus dijaga:** Tidak ada antrean checkout offline maupun pembuatan pesanan duplikat dari retry.

**Keterkaitan aturan:** ORDER-005, ORDER-006, ORDER-009.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Putus koneksi setelah server sukses tetapi sebelum respons diterima; retry tetap menghasilkan tepat satu pesanan.

---

<a id="order-009"></a>

### ORDER-009 — Satu kantin per keranjang dan pesanan

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Satu keranjang dan satu pesanan hanya berisi menu dari **satu kantin**.

**Rincian perilaku yang tercakup:**

- Jika Customer memilih item kantin berbeda, aplikasi harus meminta konfirmasi penggantian seluruh isi keranjang.
- Jika konfirmasi dibatalkan, keranjang lama tetap utuh.
- Jika disetujui, penggantian dilakukan secara eksplisit tanpa mencampur kantin.

**Batasan yang harus dijaga:** Tidak ada checkout lintas kantin dalam satu pesanan.

**Keterkaitan aturan:** ORDER-010, ORDER-008, AI-005.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Tambah menu dari kantin kedua pada keranjang berisi kantin pertama; periksa kedua opsi konfirmasi.

---

<a id="order-010"></a>

### ORDER-010 — Jumlah item, catatan, dan keranjang tersimpan

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Item baru masuk keranjang dengan kuantitas awal **1**, dapat ditambah/kurangi; penurunan dari **1 menjadi 0 menghapus item**.

**Rincian perilaku yang tercakup:**

- Draft keranjang tersimpan per akun.
- Catatan per item dan catatan umum untuk satu pesanan bersifat opsional.
- Pengeditan kuantitas dan catatan dilakukan sebelum pesanan dibuat.

**Batasan yang harus dijaga:** Tidak ada persyaratan catatan wajib untuk item maupun pesanan.

**Keterkaitan aturan:** ORDER-009, ORDER-011, CUSTOMER-004.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Periksa kuantitas default, pengurangan 1→0, dan pemulihan draft saat pengguna membuka aplikasi kembali.

---

<a id="order-011"></a>

### ORDER-011 — Snapshot pesanan tidak dapat diedit

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Setelah pesanan dibuat, rincian item, kuantitas, harga, dan catatan **tidak dapat diedit** baik oleh Customer maupun Owner.

**Rincian perilaku yang tercakup:**

- Data pesanan merupakan snapshot saat pembuatan.
- Jika ingin memperbaiki pesanan yang masih pending, Customer membatalkan sesuai ORDER-001 lalu membuat pesanan baru.
- Perubahan menu Owner setelah checkout tidak mengubah isi pesanan lama.

**Batasan yang harus dijaga:** Tidak ada tombol edit item atau harga pada pesanan yang sudah dibuat.

**Keterkaitan aturan:** ORDER-001, ORDER-005, OWNER-005.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Ubah menu, harga, dan catatan setelah checkout; snapshot pesanan terdahulu harus identik.

---

<a id="order-012"></a>

### ORDER-012 — Estimasi persiapan dan status Siap Diambil

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Owner mengatur estimasi waktu persiapan umum; saat menerima pesanan estimasi tersebut diterapkan, sedangkan status **Siap Diambil** ditetapkan **manual** oleh Owner.

**Rincian perilaku yang tercakup:**

- Estimasi adalah informasi bagi Customer, bukan penghitung mundur yang memaksa transisi status.
- Owner dapat mengubah pengaturan estimasi umum untuk pesanan berikutnya sesuai kebijakan.
- Perubahan status Siap Diambil membutuhkan tindakan Owner.

**Batasan yang harus dijaga:** Tidak ada perubahan status otomatis hanya karena waktu estimasi berlalu.

**Keterkaitan aturan:** OWNER-003, ORDER-017, CUSTOMER-005.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Lewatkan waktu estimasi tanpa tindakan Owner; pesanan tidak boleh otomatis menjadi Siap Diambil.

---

<a id="order-013"></a>

### ORDER-013 — Gagal Dipenuhi setelah penerimaan

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Owner dapat menetapkan **Gagal Dipenuhi** dengan alasan wajib; status menjadi akhir, belum dibayar, dan alasan diketahui Customer.

**Rincian perilaku yang tercakup:**

- Jalur ini untuk pesanan yang telah diterima dan sedang diproses.
- Alasan kegagalan disimpan bersama kejadian pesanan.
- Status terminal tidak dapat kembali ke alur aktif.

**Batasan yang harus dijaga:** Tidak digunakan untuk pesanan yang sudah Siap Diambil; detailnya diperjelas oleh ORDER-013A.

**Keterkaitan aturan:** ORDER-013A, ORDER-013B, ORDER-003.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Gagal Dipenuhi harus meminta alasan dan menghasilkan status terminal yang tidak Lunas.

---

<a id="order-013a"></a>

### ORDER-013A — Batas status Gagal Dipenuhi

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Tindakan **Gagal Dipenuhi hanya boleh dari status Diproses**, bukan dari **Siap Diambil**.

**Rincian perilaku yang tercakup:**

- Aturan ini memperjelas ORDER-013.
- Backend harus memvalidasi status asal untuk menghindari penggunaan status yang salah.
- Pesanan yang Siap Diambil tetap memiliki jalur tersendiri menurut aturan yang telah disetujui.

**Batasan yang harus dijaga:** Tidak boleh menyediakan tindakan Gagal Dipenuhi dari Siap Diambil.

**Keterkaitan aturan:** ORDER-013, ORDER-013B, ORDER-014.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Coba melakukan transisi Siap Diambil→Gagal Dipenuhi; pastikan ditolak.

---

<a id="order-013b"></a>

### ORDER-013B — Gagal Diambil setelah Siap Diambil

**Status aturan bisnis: FINAL · LOCKED setelah amendemen 19 November 2026.**

**Pesan persetujuan amendemen — verbatim**

> buat saja gagal diambil seperti state lain

**Aturan yang berlaku.** Jika pihak kantin tidak dapat menyerahkan makanan setelah pesanan berstatus **Siap Diambil**, hanya Owner kantin terkait yang dapat memilih **Gagal Diambil**. Owner wajib mengisi alasan dan mengonfirmasi tindakan. Contohnya, makanan rusak sesudah ditandai siap dan kantin tidak dapat menyediakan pengganti.

- Backend memeriksa status asal saat menyimpan. Dalam satu transaksi, catat status akhir, alasan, pelaksana, dan waktu. Pembayaran tetap **Belum Lunas**.
- Pesanan keluar dari daftar aktif Customer dan Owner. Status serta alasan muncul pada timeline dan riwayat keduanya. Barcode pengambilan tidak lagi ditampilkan.
- Status akhir tidak dapat diubah lagi. Pemindaian barcode, lewatnya estimasi, dan ketidakhadiran Customer tidak memicu Gagal Diambil. Ketidakhadiran Customer ditangani melalui **Tidak Diambil**. Kegagalan ketika masih Diproses mengikuti **Gagal Dipenuhi**.
- Admin dapat menilai kembali indikator pesanan aktif saat ada permintaan pengelolaan akun. Pesanan lain yang masih aktif tetap dihitung. Tidak ada promosi atau penonaktifan otomatis.
- Perubahan disampaikan melalui realtime dan riwayat. Matriks tujuh kejadian push pada ORDER-017A tetap menjadi acuan.

**Keterkaitan aturan:** ORDER-004, ORDER-013A, ORDER-014, ORDER-017A, CUSTOMER-005, CUSTOMER-006A, ADMIN-003A.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Dari Siap Diambil, tolak tindakan tanpa alasan atau oleh pengguna yang tidak berwenang. Setelah konfirmasi Owner yang sah, pastikan hanya satu status akhir tersimpan dan pembayaran tetap Belum Lunas. Periksa riwayat, barcode dan indikator aktif pada kedua akun.

---

<a id="order-014"></a>

### ORDER-014 — Syarat penandaan Tidak Diambil

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Owner hanya dapat menandai **Tidak Diambil** secara manual dari status **Siap Diambil**, disertai konfirmasi eksplisit.

**Rincian perilaku yang tercakup:**

- Tidak ada syarat minimum lamanya menunggu.
- Tidak ada timeout otomatis.
- Status menjadi akhir, pembayaran belum lunas, dan histori tetap tersimpan.

**Batasan yang harus dijaga:** Tidak boleh menandai Tidak Diambil dari status lain ataupun berdasarkan timer.

**Keterkaitan aturan:** ORDER-002, ORDER-004, ORDER-013B.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Coba tindakan dari Diproses dan setelah berbagai durasi tunggu; hanya Siap Diambil yang memenuhi kondisi status.

---

<a id="order-015"></a>

### ORDER-015 — Bukti pengambilan dengan barcode

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Halaman pengambilan menampilkan nomor pesanan, detail yang diperlukan, dan **barcode** untuk membantu identifikasi oleh kantin.

**Rincian perilaku yang tercakup:**

- Barcode dapat dipindai dengan perangkat kompatibel atau pesanan dicari secara manual melalui nomor pesanan.
- Tujuan barcode hanya menunjukkan identitas/referensi pesanan.
- BARCODE-TECH-001 menetapkan format Code 128. Kompatibilitas pemindai dan layar Android di lokasi masih perlu diuji.

**Batasan yang harus dijaga:** Memindai barcode tidak melakukan pembayaran atau penyelesaian pesanan otomatis.

**Keterkaitan aturan:** ORDER-004, CUSTOMER-005.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Pemindaian atau input manual hanya membuka/mengidentifikasi pesanan tanpa mengubah status ataupun pembayaran.

---

<a id="order-016"></a>

### ORDER-016 — Pesanan pending tanpa timeout otomatis

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Pesanan **Menunggu Konfirmasi** dapat tetap menunggu tanpa batas waktu otomatis sampai Customer membatalkan atau Owner menerima/menolak.

**Rincian perilaku yang tercakup:**

- Tidak ada auto-accept, auto-reject, atau auto-cancel.
- Status pending tetap ditampilkan apa adanya.
- Transisi dipicu tindakan Customer/Owner sesuai hak masing-masing.

**Batasan yang harus dijaga:** Sistem tidak mengubah status karena pesanan telah lama menunggu.

**Keterkaitan aturan:** ORDER-001, ORDER-003, ORDER-017.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Biarkan pending melewati berbagai waktu; tidak boleh muncul transisi otomatis.

---

<a id="order-017"></a>

### ORDER-017 — Sinkronisasi realtime dan push penting

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Status dan informasi pesanan disinkronkan secara realtime antara Customer dan Owner, ditambah notifikasi push untuk kejadian penting.

**Rincian perilaku yang tercakup:**

- Backend adalah sumber kebenaran, bukan notifikasi.
- Saat koneksi pulih, aplikasi memuat ulang keadaan terbaru.
- Push bersifat best-effort; kegagalan pengiriman tidak membatalkan perubahan status yang sah.

**Batasan yang harus dijaga:** Notifikasi tidak boleh dijadikan bukti tunggal bahwa sebuah transaksi sudah berubah status.

**Keterkaitan aturan:** ORDER-017A, CUSTOMER-005, OWNER-006.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Putuskan jaringan, ubah status dari pihak lain, sambungkan kembali; tampilan memuat status backend yang benar.

---

<a id="order-017a"></a>

### ORDER-017A — Tujuh kejadian notifikasi push

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> **Rujukan persetujuan.** Keputusan telah dipadankan dengan percakapan. Bagian berikut merangkum keputusan. Naskah lengkap pesan pengguna belum ditranskripsi di sini.

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Push dikirim untuk **7 kejadian tertentu**: pesanan baru ke Owner; pembatalan Customer ke Owner; dan ke Customer untuk diterima, ditolak, siap diambil, gagal dipenuhi, serta tidak diambil.

**Rincian perilaku yang tercakup:**

- Perubahan **Selesai** dan **Gagal Diambil** tersedia melalui realtime dan riwayat, **tanpa push** khusus.
- Tidak ada notifikasi operasional pesanan kepada Admin.
- Kegagalan push tidak menghalangi status sebenarnya.

**Batasan yang harus dijaga:** Tidak menambah event push baru sebagai aturan FINAL tanpa persetujuan terpisah.

**Keterkaitan aturan:** ORDER-017, ORDER-004, ADMIN-005.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Uji matriks ketujuh event, pastikan Selesai dan Gagal Diambil tidak memicu push dan Admin tidak menerima push transaksi.

---

## Pemeriksaan konsistensi modul

- **Keutuhan status:** alur normal dan status terminal memiliki batas transisi yang berbeda; klaim status harus mengikuti tindakan yang benar.
- **Snapshot:** harga dan isi pesanan yang telah terbentuk tidak berubah mengikuti menu.
- **ORDER-013B.** Gagal Diambil menutup kasus gagal serah oleh kantin dari Siap Diambil dan menjaga pembayaran tetap belum lunas.
- **Kelayakan checkout:** harga, publikasi, Buka/Tutup, status Owner, status menu, dan idempotensi diperiksa oleh backend.
- **Operasional Owner/Customer:** Admin tidak mengambil alih detail transaksi atau pembayaran.

---

## Perlindungan integritas keputusan

1. **FINAL · LOCKED** adalah status keputusan bisnis, **bukan** klaim bahwa seluruh kutipan aslinya telah tersedia dalam dokumen ini.
2. Bagian berlabel **NASKAH PERSETUJUAN ASLI — VERBATIM** hanya memuat kalimat yang dapat diverifikasi langsung melalui sumber persetujuan yang tersedia. Kalimat ditulis satu baris tanpa koreksi ejaan atau tanda baca.
3. Bagian **Ringkasan operasional**, **Penjabaran**, **Batasan**, dan **Skenario pemeriksaan** adalah penjelasan dari keputusan, **bukan teks verbatim dan bukan amendemen**. Jika penjabaran kurang tepat, sumber persetujuan asli yang berlaku.
4. Aturan FINAL tidak boleh diganti, digabung, dinomori ulang, atau diubah berdasarkan preferensi teknis. Hal baru hanya boleh diajukan sebagai DRAFT/amendemen terpisah melalui persetujuan pengguna.
5. Status spesifikasi ini tidak menyatakan kode, API, database, atau deployment telah dibangun dan diuji.

## Status akhir modul

- **Jumlah aturan:** 20 FINAL · LOCKED.
- **Keputusan yang telah dipadankan dengan percakapan:** 20.
- **Pesan amendemen yang dikutip lengkap:** 1 (ORDER-013B). Naskah 19 aturan lain belum ditranskripsi lengkap.
- **Pelaksanaan kode/repository:** Tidak dilakukan pada pembuatan dokumen ini.
- **Catatan sumber.** Edisi awal menggunakan arsip audit 18 November 2026. Edisi ini juga merujuk pada percakapan asli. [Percakapan keputusan Kantin Cerdas](https://chatgpt.com/share/6afdc1cc-ac30-83ec-b635-1a8bf4898864)
