# Mini Software Requirements Specification (Mini-SRS)

## KantinCerdas

| Informasi | Nilai |
| --- | --- |
| Versi dokumen | 1.0 |
| Status | Baseline kebutuhan produk |
| Target produk | Aplikasi Android pre-order “Pesan & Ambil” |
| Target baseline | `v1.0.0` |
| Baseline fondasi | `v0.1.0-alpha.1` |
| Tanggal | 4 September 2026 |

`v0.1.0-alpha.2` adalah pemutakhiran maintenance atas fondasi tersebut dan
tidak mengubah kebutuhan, aktor, alur, atau scope produk pada Mini-SRS ini.

Dokumen ini mendefinisikan **apa yang harus dilakukan sistem** dan batas kualitas yang harus dipenuhi. Detail arsitektur, struktur kelas, endpoint, database, dan pilihan package ditetapkan pada tahap desain atau implementasi dan bukan bagian dari Mini-SRS ini.

## 1. Tujuan

KantinCerdas bertujuan membantu mahasiswa memilih serta memesan makanan sebelum tiba di kantin, sekaligus membantu pengelola stan mengelola ketersediaan menu dan status pesanan.

Versi awal menggunakan data dummy agar seluruh alur UI dapat didemonstrasikan tanpa backend. Integrasi backend dilakukan kemudian tanpa mengubah kebutuhan produk utama.

## 2. Pemangku Kepentingan dan Pengguna

### 2.1 Mahasiswa

Mahasiswa membutuhkan informasi menu, harga, ketersediaan, dan estimasi waktu yang jelas agar dapat memilih makanan serta mengurangi waktu antre.

### 2.2 Pengelola stan

Pengelola membutuhkan cara sederhana untuk memperbarui kondisi stan dan menu, menerima atau menolak pesanan, serta memberi tahu mahasiswa ketika pesanan siap.

### 2.3 Institusi atau dosen pengampu

Institusi atau dosen membutuhkan aplikasi yang dapat didemonstrasikan, memiliki kebutuhan yang dapat ditelusuri, menggunakan AI secara relevan, dan memanfaatkan kemampuan perangkat Android.

## 3. Masalah yang Diselesaikan

- Mahasiswa belum mengetahui ketersediaan menu sebelum mendatangi stan.
- Antrean dan waktu tunggu sulit diperkirakan.
- Mahasiswa dapat kesulitan memilih menu berdasarkan anggaran, preferensi, dan waktu yang tersedia.
- Pengelola stan memerlukan alur terstruktur untuk merespons serta memperbarui status pesanan.
- Informasi status pesanan perlu disampaikan tanpa mengharuskan mahasiswa terus membuka aplikasi.

## 4. Ruang Lingkup

Baseline produk mencakup:

- satu kantin pada satu kampus;
- beberapa stan yang telah terdaftar;
- katalog, pencarian, dan filter menu;
- Asisten Pilih Menu berbasis AI;
- keranjang yang hanya memuat menu dari satu stan;
- pesanan untuk pengambilan pada hari yang sama;
- pembayaran langsung di konter;
- pengelolaan stan, menu, dan status pesanan;
- notifikasi Android ketika pesanan ditolak atau siap diambil.

Baseline produk tidak mencakup:

- pengantaran;
- GPS atau peta;
- pembayaran digital;
- promo atau voucher;
- rating atau ulasan;
- pemesanan untuk hari lain;
- pendaftaran stan secara mandiri;
- dukungan banyak kampus;
- analitik penjualan lanjutan.

## 5. Kebutuhan Fungsional

### FR-01 — Katalog stan dan menu

Sistem harus menampilkan stan yang terdaftar beserta status buka atau tutup, daftar menu, foto, harga, ketersediaan, dan estimasi waktu penyajian.

### FR-02 — Pencarian dan filter

Sistem harus memungkinkan mahasiswa mencari serta memfilter menu berdasarkan kata kunci, kategori, rentang harga, ketersediaan, dan karakteristik relevan yang tersedia pada data.

### FR-03 — Input kebutuhan kepada Asisten Pilih Menu

Sistem harus menerima kebutuhan mahasiswa dalam bahasa alami, termasuk anggaran, preferensi rasa, pantangan, dan batas waktu tunggu.

### FR-04 — Rekomendasi menu

Sistem harus memberikan rekomendasi hanya dari menu yang tersedia pada katalog aktif dan menjelaskan kecocokan rekomendasi terhadap kriteria mahasiswa.

### FR-05 — Klarifikasi input ambigu

Sistem harus meminta klarifikasi ketika kebutuhan mahasiswa belum cukup jelas untuk menghasilkan rekomendasi yang dapat dipertanggungjawabkan.

### FR-06 — Fallback pencarian manual

Sistem harus tetap menyediakan katalog, pencarian, dan filter manual ketika layanan AI gagal, melewati batas waktu, atau tidak menemukan rekomendasi.

### FR-07 — Keranjang satu stan

Sistem harus memungkinkan mahasiswa menambah, mengurangi, dan menghapus item; menghitung subtotal dan total; serta mencegah menu dari stan berbeda berada dalam satu keranjang.

### FR-08 — Pembuatan dan pemantauan pesanan

Sistem harus memungkinkan mahasiswa mengonfirmasi pesanan untuk pengambilan pada hari yang sama, menampilkan ketentuan pembayaran di konter, menghasilkan nomor pesanan, dan menampilkan status serta alasan penolakan jika ada.

Status pesanan baseline adalah:

```text
Menunggu Konfirmasi → Diproses → Siap Diambil → Selesai
                    ↘ Ditolak
```

### FR-09 — Pengelolaan stan dan pesanan

Sistem harus memungkinkan pengelola:

- melihat hanya data stan yang menjadi tanggung jawabnya;
- mengubah status buka atau tutup;
- mengubah ketersediaan menu dan estimasi waktu;
- menerima atau menolak pesanan;
- mewajibkan alasan ketika menolak pesanan;
- memperbarui pesanan hanya melalui transisi status yang valid.

### FR-10 — Notifikasi status pesanan

Sistem harus menampilkan notifikasi Android ketika pesanan ditolak atau siap diambil. Ketukan pada notifikasi harus membuka detail pesanan yang sesuai. Penolakan izin notifikasi tidak boleh menghilangkan status pesanan di dalam aplikasi.

## 6. Kebutuhan Nonfungsional

### NFR-01 — Usability dan aksesibilitas

- UI harus dapat digunakan pada lebar 360, 390, dan 412 dp tanpa overflow.
- Target sentuh aksi utama minimal 48 × 48 dp.
- Teks normal menargetkan rasio kontras minimal 4.5:1.
- Informasi penting tidak boleh dibedakan hanya menggunakan warna.
- UI harus tetap terbaca ketika skala teks Android diperbesar.

### NFR-02 — Performa

- Interaksi lokal pada mode dummy harus memberi respons visual paling lambat 300 ms.
- Layar utama dengan data dummy harus tampil paling lambat 2 detik pada perangkat uji yang disepakati.
- Permintaan AI harus memiliki batas waktu; setelah batas tersebut pengguna diarahkan ke fallback manual.

### NFR-03 — Keandalan

- Operasi asinkron harus memiliki state loading, berhasil, kosong, gagal, dan retry jika relevan.
- Aplikasi tidak boleh berhenti pada loading tanpa batas.
- Kegagalan AI atau jaringan tidak boleh menutup akses ke katalog manual.
- Data demo harus dapat dikembalikan ke kondisi awal agar skenario presentasi dapat diulang.

### NFR-04 — Keamanan

- Secret, API key, password, token, dan signing key tidak boleh disimpan dalam source code.
- Layanan AI yang membutuhkan secret harus dipanggil melalui backend, bukan langsung menggunakan secret di aplikasi.
- Backend kelak harus menegakkan autentikasi, otorisasi peran, dan kepemilikan data secara mandiri.
- Komunikasi dengan backend production harus menggunakan transport terenkripsi.

### NFR-05 — Privasi

- Sistem hanya boleh menyimpan data yang diperlukan untuk akun, preferensi, dan pemrosesan pesanan.
- Secret, token, isi autentikasi, dan data pribadi tidak boleh ditulis ke log.
- Baseline tidak meminta lokasi, kontak, kamera, atau permission lain yang tidak diperlukan.

### NFR-06 — Maintainability dan integrasi

- UI tidak boleh bergantung langsung pada sumber data dummy atau implementasi backend tertentu.
- Peralihan dari mode dummy ke backend harus dilakukan melalui konfigurasi dan penggantian implementasi data, tanpa merombak layar utama.
- Model status dan aturan bisnis harus memiliki satu sumber kebenaran yang dapat diuji.

### NFR-07 — Kompatibilitas dan demo

- Target utama adalah Android.
- Mode demo UI harus dapat berjalan tanpa backend dan tanpa koneksi internet.
- Fitur nyata yang membutuhkan backend atau AI boleh memerlukan internet setelah integrasi dilakukan.

## 7. Kemampuan Perangkat Mobile

| Kemampuan | Penggunaan |
| --- | --- |
| Internet | Mengakses backend, sinkronisasi pesanan, dan layanan AI pada tahap integrasi |
| Notifikasi Android | Memberi tahu status Ditolak dan Siap Diambil |
| Deep link internal | Membuka detail pesanan dari notifikasi |
| Penyimpanan lokal terbatas | Menyimpan konfigurasi nonrahasia dan state demo jika diperlukan |
| Kamera | Tidak digunakan pada baseline |
| GPS/lokasi | Tidak digunakan pada baseline |

Notifikasi Android menjadi kemampuan perangkat yang memenuhi kebutuhan penggunaan API Android pada proyek ini.

## 8. Data yang Diperlukan

| Entitas | Data minimum |
| --- | --- |
| Pengguna | ID, nama tampilan, peran |
| Stan | ID, nama, deskripsi, status buka/tutup, estimasi |
| Menu | ID, stan, nama, deskripsi, foto, kategori, harga, ketersediaan, atribut preferensi |
| Preferensi sementara | Anggaran, rasa, pantangan, batas waktu |
| Keranjang | Stan, item, jumlah, subtotal, total |
| Pesanan | Nomor, pengguna, stan, item, total, waktu, status, alasan penolakan |
| Riwayat status | Pesanan, status, waktu perubahan |
| Rekomendasi | Kriteria, menu yang dirujuk, alasan kecocokan |

Data pembayaran digital, koordinat lokasi, kontak perangkat, dan data biometrik tidak termasuk dalam baseline.

## 9. Aturan Bisnis

- Satu keranjang dan satu pesanan hanya boleh berisi menu dari satu stan.
- Pesanan hanya berlaku untuk pengambilan pada hari yang sama.
- Pembayaran dilakukan di konter; subtotal sama dengan total jika tidak ada biaya lain yang ditampilkan.
- Menu habis tidak boleh dikonfirmasi sebagai pesanan.
- Pengelola hanya boleh mengubah data stannya sendiri.
- Pesanan yang ditolak wajib memiliki alasan.
- Perubahan status harus mengikuti transisi yang telah ditetapkan.
- Rekomendasi AI tidak boleh mengarang menu yang tidak tersedia pada data aplikasi.

## 10. Antarmuka Eksternal

### 10.1 Antarmuka pengguna

Aplikasi menyediakan UI mahasiswa dan UI pengelola dalam aplikasi Android yang sama. Pemisahan akses pada mode demo harus terlihat jelas dan tidak boleh diklaim sebagai autentikasi production.

### 10.2 Backend API

Kontrak endpoint, autentikasi, format error, dan skema respons ditetapkan sebelum milestone integrasi backend. Sampai saat itu, UI menggunakan implementasi data dummy melalui kontrak yang dapat diganti.

### 10.3 Layanan AI

AI digunakan untuk memahami kriteria dan membantu memilih menu. Hasil AI harus divalidasi terhadap katalog aktif sebelum ditampilkan.

### 10.4 Android notification service

Aplikasi menggunakan notification channel khusus status pesanan dan meminta permission hanya pada versi Android yang memerlukannya.

## 11. Kriteria Penerimaan Produk

Baseline UI dinyatakan siap didemonstrasikan apabila:

- alur mahasiswa dari katalog atau AI sampai status pesanan dapat dijalankan;
- alur pengelola dari pesanan masuk sampai selesai dapat dijalankan;
- mode demo tidak membutuhkan backend;
- notifikasi Android dapat diperagakan;
- seluruh state penting memiliki perilaku gagal dan pemulihan yang jelas;
- seluruh test, analyzer, format check, dan build release berhasil;
- tidak ada secret atau data production dalam repository.

## 12. Ketertelusuran ke Roadmap

| Kebutuhan | Milestone utama |
| --- | --- |
| Fondasi dokumen, CI, dan proyek | `v0.1.0-alpha.1` |
| Struktur UI, komponen, dan sumber data dummy | `v0.2.0-alpha.1` |
| FR-01, FR-02, dan fallback FR-06 | `v0.3.0-alpha.1` |
| FR-03 sampai FR-06 | `v0.4.0-alpha.1` |
| FR-07 dan FR-08 | `v0.5.0-alpha.1` |
| FR-09 | `v0.6.0-alpha.1` |
| FR-10 dan demo UI lengkap | `v0.7.0-beta.1` |
| Backend dan autentikasi nyata | `v0.8.0-beta.1` |
| AI melalui backend dan notifikasi end-to-end | `v0.9.0-beta.1` |
| Validasi seluruh FR/NFR | `v1.0.0-rc.1` dan `v1.0.0` |

## 13. Asumsi dan Ketergantungan

- Data stan dan menu disediakan oleh pihak yang berwenang.
- Mahasiswa dan pengelola memiliki perangkat Android yang didukung.
- Backend, autentikasi nyata, dan provider AI belum menjadi bagian dari fondasi
  `v0.1`.
- Keputusan baru yang mengubah aktor, alur utama, atau scope wajib memperbarui Mini-SRS sebelum implementasi.
