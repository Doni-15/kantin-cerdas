# Kantin Cerdas · Arsitektur MVP Android

Edisi kerja 19 November 2026. Dokumen ini menerjemahkan spesifikasi bisnis 01–06 ke rancangan implementasi. Dokumen 08 memuat cara menguji rancangan. Dokumen 09 mencatat keputusan yang masih terbuka.

## Tujuan dan batas rilis

Mahasiswa memilih kantin di area layanan USU, memesan di Android, mengambil makanan di lokasi, dan membayar tunai. Owner menerima serta menyiapkan pesanan. Admin mengelola akun dan pengajuan Owner. Target integrasi pertama adalah satu aplikasi Flutter Android dengan navigasi per peran dan tampilan yang menyesuaikan ukuran layar. Dukungan iOS, web, dan desktop tidak menjadi syarat kelulusan MVP Android. Distribusi lewat Google Play merupakan keputusan tersendiri.

## Tanggung jawab komponen

| Komponen | Tanggung jawab | Batas akses |
|---|---|---|
| Flutter Android | Alur daftar, pemulihan sesi, katalog, draft, checkout, layar Owner dan Admin. Simpan identitas upaya checkout agar hasil dapat dicari setelah aplikasi ditutup. | Tampilan tombol mengikuti izin. Setiap tindakan tetap diperiksa server. Kunci Gemini dan kredensial pengiriman FCM hanya di server. |
| Supabase Auth | Email/password, verifikasi email, identitas Google, pemulihan dan sesi perangkat. | Linking otomatis mengikuti amendemen AUTH-005/005A. Shelf memakai ID pengguna tepercaya. Rilis Google menunggu A1–A4. |
| Dart Shelf | Memeriksa identitas, sesi, akun aktif, peran, dan kepemilikan objek. Menyediakan hasil checkout, rincian pesanan, pencarian katalog dan rekomendasi. | Harga, hak akses, nomor pesanan, dan status pembayaran ditentukan di backend. |
| PostgreSQL | Menyimpan akun aplikasi, kantin/menu, keranjang, snapshot pesanan, riwayat status, pengajuan, audit Admin, kuota harian dan antrean notifikasi. | Perubahan yang saling memengaruhi memakai transaksi dengan urutan penguncian yang sama. |
| Supabase Realtime dan FCM | Broadcast privat memberi sinyal perubahan. Worker Dart membaca antrean tersimpan dan mengirim push Android lewat FCM HTTP v1. | Setelah menerima sinyal atau tersambung kembali, aplikasi membaca ulang keadaan terbaru melalui Shelf. Rincian pesanan hanya keluar melalui akses yang sah. |
| Gemini dan pencarian katalog | Gemini membantu memahami percakapan kuliner. Backend memvalidasi kartu menu terhadap katalog saat ini. Pencarian sederhana tersedia ketika Gemini tidak dapat dipakai. | AI hanya membuka detail menu. Pengguna sendiri mengubah keranjang dan mengirim checkout. |

## Data dan batas konsistensi

Nama berikut menjelaskan isi data yang perlu disimpan. Nama tabel dan alamat API dapat ditetapkan pada implementasi.

| Data | Hubungan dan batas yang harus terjaga |
|---|---|
| Akun dan profil | Satu profil per identitas pengguna aplikasi. Simpan role, keadaan aktif, dan kelengkapan foto. Pendaftaran umum menghasilkan Customer. Hanya Admin sah yang dapat memutuskan pengajuan Owner. |
| Pengajuan Owner dan audit | Maksimal satu pengajuan menunggu per Customer. Simpan nama rencana kantin, lokasi, alasan pengajuan, keputusan, pelaksana, waktu, dan alasan penolakan. Admin hanya membutuhkan indikator pesanan aktif. |
| Kantin, kategori, dan menu | Maksimal satu kantin per Owner. Kategori dan menu terikat ke kantin yang sama. Harga berupa rupiah bulat. Status publikasi, Buka/Tutup, status akun Owner, ketersediaan menu, dan arsip diperiksa terpisah. |
| Keranjang dan upaya checkout | Draft milik satu Customer dan memuat satu kantin. Versi draft mengikat isi yang telah disetujui. Backend menyimpan ID upaya, pemilik, versi, ciri isi permintaan dan hasilnya. Satu versi keranjang hanya dapat dikonversi menjadi satu pesanan. |
| Pesanan, item, dan riwayat | Simpan Customer, kantin, nomor pesanan, jumlah, harga, catatan, estimasi terkait dan rincian saat pemesanan. Perubahan menu sesudah checkout tidak mengubah snapshot. Simpan asal dan tujuan setiap transisi, pelaksana, waktu, serta alasan bila wajib. |
| Perangkat, peristiwa, dan pengiriman | Bedakan peristiwa bisnis dari percobaan pengiriman ke tiap perangkat. ID peristiwa stabil memungkinkan penanganan duplikat. Hapus keterkaitan perangkat dengan sesi yang sudah keluar. |
| Kuota Gemini | Kunci penghitungan adalah Customer dan tanggal Asia/Jakarta. Simpan reservasi dan apakah permintaan telah dikirim atau hasil pengirimannya belum pasti. Fallback katalog tidak memerlukan reservasi. |

## Alur implementasi per fitur

### 1. Pendaftaran dan pemulihan

Langkah pertama menerima nama, email, dan password atau identitas Google. Langkah kedua melengkapi foto wajib. Gunakan foto Google jika tersedia dan minta konfirmasi saat diganti. Simpan kemajuan agar pengguna yang menutup aplikasi dapat melanjutkan. Sebelum pemesanan, periksa verifikasi identitas yang dipersyaratkan dan kelengkapan pendaftaran. Reset email hanya untuk akun password. Akun khusus Google dipulihkan melalui Google. Logout berlaku pada perangkat saat ini.

Siapkan SMTP untuk alamat mahasiswa di luar tim dan tautan Android untuk verifikasi, reset, serta ganti email. Uji penautan yang sah, identitas belum terverifikasi dan race pada proyek Supabase QA. Lihat A1–A4 pada dokumen 08. [Identity linking](https://supabase.com/docs/guides/auth/auth-identity-linking) · [SMTP](https://supabase.com/docs/guides/auth/auth-smtp) · [Sesi](https://supabase.com/docs/guides/auth/sessions)

### 2. Persetujuan Owner dan katalog

Customer mengajukan diri dari profil. Saat Admin meninjau, periksa kembali pesanan aktif. Jika ada, tolak dengan alasan. Customer dapat mengajukan kembali setelah semua pesanan mencapai status akhir. Jika disetujui, Owner membuat kantinnya sendiri. Publikasi awal mensyaratkan nama, kampus, lokasi detail serta minimal satu menu tersedia. Kantin terbit pertama kali dalam keadaan Tutup. Owner membuka atau menutup secara manual.

Beranda menampilkan kantin terbit. Pencarian menampilkan hasil Kantin dan Menu secara terpisah. Kantin terbit tetap terlihat saat tutup, Owner nonaktif, atau semua menu habis/diarsipkan. Backend memeriksa kelayakan pemesanan setiap kali checkout. Kategori yang masih mempunyai menu, termasuk arsip, tidak dapat dihapus.

### 3. Checkout tunai dan pemulihan setelah koneksi putus

1. Customer meninjau item, jumlah, catatan, harga, kantin dan metode tunai. Jika mengganti kantin, minta konfirmasi sebelum mengganti seluruh draft.
2. Saat online, Shelf menerbitkan dan menyimpan ID upaya checkout sebelum transaksi pembuatan pesanan. Android menyimpannya bersama versi draft. Saat hasil belum pasti, gunakan ID tersebut untuk mencari hasil.
3. Dalam satu transaksi PostgreSQL, kunci baris yang relevan dengan urutan konsisten, lalu baca ulang akun, kantin, draft, dan item. Periksa pemilik, versi draft, harga, ketersediaan, arsip serta status operasional. Permintaan yang menggunakan ID lama untuk isi berbeda harus ditolak.
4. Jika harga berubah, kembalikan harga lama dan terbaru untuk konfirmasi Customer. Item Habis atau diarsipkan memblokir seluruh checkout sampai Customer memperbaiki draft. Lepaskan kunci sebelum menunggu masukan pengguna.
5. Jika valid, simpan satu pesanan, snapshot, status awal dan peristiwa pengiriman dalam transaksi yang sama. Dua perangkat dengan ID berbeda untuk versi draft yang sama tidak boleh menghasilkan dua pesanan.
6. Setelah transaksi tersimpan, kembalikan nomor pesanan. Jika jawabannya terputus, cari atau ulangi upaya dengan ID yang sama. Saat offline aplikasi tidak memulai atau mengirim checkout otomatis setelah tersambung.

Penguncian yang sama juga mengikat penutupan kantin, arsip atau perubahan harga, penonaktifan akun, dan promosi Customer. Contohnya, bila checkout tersimpan dahulu, Admin melihat pesanan aktif sehingga penonaktifan ditolak. Bila akun sudah nonaktif dahulu, checkout ditolak. [Transaksi PostgreSQL](https://www.postgresql.org/docs/current/tutorial-transactions.html) · [Penguncian](https://www.postgresql.org/docs/current/explicit-locking.html)

### 4. Operasional pesanan dan pengambilan

| Status asal | Pelaksana dan tindakan sah | Hasil |
|---|---|---|
| Menunggu Konfirmasi | Customer membatalkan, Owner menolak dengan alasan, atau Owner menerima | Dibatalkan, Ditolak, atau Diproses. Tanpa tindakan, status tetap menunggu. |
| Diproses | Owner menandai siap atau mencatat gagal dengan alasan | Siap Diambil atau Gagal Dipenuhi. Estimasi persiapan tidak memicu transisi. |
| Siap Diambil | Owner mengonfirmasi serah terima dan penerimaan tunai, ketidakhadiran Customer, atau kegagalan penyerahan oleh kantin. Untuk kegagalan kantin, Owner wajib mencatat alasan. | Selesai dan Lunas dalam satu transaksi, Tidak Diambil bila Customer tidak mengambil, atau Gagal Diambil bila kantin gagal menyerahkan. Kedua status terakhir tetap belum lunas. |
| Status akhir | Customer atau Owner yang berhak membuka riwayat | Rincian pesanan tetap dapat dibaca. |

Tampilkan barcode Code 128 di detail Customer hanya saat Siap Diambil. Simpan nomor sebagai teks agar nol awal dipertahankan. Pemindaian dan pencarian nomor manual hanya mengidentifikasi pesanan milik kantin terkait. Saat Gagal Diambil tersimpan, batasi ke satu transisi akhir, simpan alasan di riwayat, perbarui indikator aktif, dan sembunyikan barcode. [Format pemindai Android](https://developers.google.com/ml-kit/vision/barcode-scanning/android)

### 5. Peristiwa realtime dan notifikasi Android

| Penerima | Peristiwa push yang disepakati |
|---|---|
| Owner kantin terkait | Pesanan baru dan pembatalan oleh Customer |
| Customer pemilik pesanan | Pesanan diterima, ditolak, siap diambil, gagal dipenuhi, dan tidak diambil |
| Admin | Tidak menerima push transaksi |

Selesai dan Gagal Diambil diperbarui melalui realtime dan riwayat tanpa push khusus. Worker mengirim setelah transaksi pesanan selesai. Catat hasil pengiriman dan batasi percobaan ulang. Kegagalan FCM tidak membatalkan pesanan. Aplikasi membaca kembali status saat dibuka walau pengguna menolak notifikasi. Uji sesi lama yang masih tersambung setelah pencabutan akses. Supabase menyimpan evaluasi kebijakan channel selama koneksi, sehingga solusi rotasi topik masih perlu dibuktikan. [Otorisasi Realtime](https://supabase.com/docs/guides/realtime/authorization) · [FCM Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages)

### 6. Food Assistant dan kegagalan layanan

Ambil menu serta harga dari katalog. Untuk rekomendasi yang dapat dipesan, periksa publikasi, Buka/Tutup, Owner aktif, menu tersedia dan tidak diarsipkan. Anggaran maksimum bersifat mengikat. Menu yang tidak tersedia boleh dijelaskan jika diminta dengan label yang jelas. Jangan membuat klaim pasti tentang alergen, kandungan, nutrisi, atau sertifikasi tanpa data terverifikasi.

Backend melakukan reservasi kuota secara atomik sebelum mengirim permintaan. Batas individu adalah 10 per tanggal Asia/Jakarta, dengan batas proyek Google tetap berlaku. Jika kuota habis, jawaban tidak valid, atau layanan gagal, gunakan pencarian katalog dan jelaskan bahwa percakapan kuliner umum sementara tidak tersedia. Checkout tetap berfungsi secara mandiri. Ketentuan usia audiens dan data yang dapat dikirim harus dituntaskan sebelum aktivasi Gemini untuk pengguna nyata. [Kuota](https://ai.google.dev/gemini-api/docs/rate-limits) · [Ketentuan Gemini](https://ai.google.dev/gemini-api/terms)

## Urutan integrasi

Buktikan Auth pada Android, lalu selesaikan satu alur vertikal dari pendaftaran sampai pelanggan menerima riwayat pesanan tunai. Lengkapi antarmuka dan backend bersama pada setiap tahap. Berikutnya uji konflik transaksi, pencabutan sesi, push Android, dan pemindaian layar di dua perangkat. Aktifkan Gemini setelah ketentuan dan kuota proyek aktual terverifikasi. Catat hasil aktual pada dokumen 08.
