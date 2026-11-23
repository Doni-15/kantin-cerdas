# Kantin Cerdas · Keputusan dan perubahan dokumentasi

19 November 2026 · Rujukan untuk pemilik proyek dan pengembang MVP Android.

Enam spesifikasi bisnis berisi 58 aturan yang telah disetujui. Persetujuan aturan, pemilihan rancangan teknis, dan keberhasilan pengujian adalah tiga hal yang dicatat sendiri. Gunakan dokumen 07 untuk rancangan dan dokumen 08 untuk hasil yang harus dibuktikan. [Percakapan sumber](https://chatgpt.com/share/6afdc1cc-ac30-83ec-b635-1a8bf4898864)

## Keputusan teknis yang menjadi acuan

| Referensi | Kedudukan | Konsekuensi implementasi |
|---|---|---|
| DB-TECH-001 | Desain disetujui | Shelf memanggil operasi atomik PostgreSQL untuk checkout. |
| DB-TECH-002 | Desain disetujui | Backend menerbitkan dan menyimpan ID upaya sebelum transaksi pesanan. Ikat hasil ke akun, isi dan versi keranjang. Satu versi hanya boleh menghasilkan satu pesanan. |
| DB-TECH-003 | Desain disetujui | Kunci baris yang relevan secara konsisten dan periksa ulang setelah terkunci. Uji persaingan antara checkout dengan perubahan harga, akses, dan operasional. |
| BARCODE-TECH-001 | Format disetujui | Code 128 untuk nomor pesanan. Uji gambar berhasil 9/9. Kompatibilitas pemindai dan layar di kantin belum diuji. |
| AUTH-005A dan AUTH-TECH-002 | Opsi A disetujui pada 20 November 2026 | Supabase menangani linking otomatis. Shelf memeriksa sesi dan mengotorisasi berdasarkan ID. Rilis menunggu A1–A4. |
| RT-TECH-001 | Broadcast + FCM menjadi arah teknis yang disepakati dalam diskusi. Penguncian formal masih terbuka | Gunakan sebagai acuan percobaan integrasi Android. |
| RT-TECH-002 | Desain disetujui | Simpan peristiwa bersama perubahan pesanan, lalu worker Dart mengirim push FCM HTTP v1 dengan percobaan ulang terbatas. |
| RT-TECH-003 | Desain disetujui | Channel privat per Customer/kantin dengan otorisasi. Hanya backend atau database yang menerbitkan sinyal, rincian diambil kembali melalui Shelf. |
| RT-TECH-004 | Android menjadi prioritas. Dokumen ini mengikuti arahan terbaru untuk memfokuskan MVP pada Android | Target kedua dan dukungan push platform lain dapat diputuskan setelah MVP Android. |
| RT-TECH-005 | Opsi rotasi topik merupakan arah uji | Buktikan penghentian pengiriman ke sesi lama dan keberlanjutan perangkat sah lainnya. |
| AI-TECH-001 | FINAL · LOCKED | Naskah persetujuan di bawah menjadi acuan kuota dan fallback. |

> Untuk Kantin Cerdas, AI-TECH-001 saya memilih A: batas maksimal 10 pemanggilan Gemini API per Customer per hari dihitung berdasarkan tanggal Asia/Jakarta dengan reset pukul 00.00 WIB; PostgreSQL mengelola reservasi kuota atomik, batas proyek Free Tier dan rate limit Google tetap diutamakan; permintaan yang sudah dikirim tetapi hasilnya tidak pasti tetap dihitung; fallback katalog tidak mengurangi kuota; tidak ada peningkatan otomatis ke layanan berbayar.

## Perubahan pada edisi dokumentasi ini

| Spesifikasi | Pembaruan dan alasannya |
|---|---|
| 01 · Order | Keterangan lama bahwa format barcode masih terbuka telah diganti dengan keputusan Code 128. ORDER-013B diamendemen menjadi Gagal Diambil, status akhir dari Siap Diambil ketika kantin gagal menyerahkan makanan. |
| 02 · Owner | Diperjelas perbedaan antara publikasi, Buka/Tutup dan kelayakan checkout ketika Owner dinonaktifkan. Ini mencegah pesanan lama ikut ditutup. |
| 03 · Customer | Diperjelas bahwa Admin memeriksa pesanan aktif saat meninjau pengajuan Owner. Jika ditolak, Customer dapat mengajukan kembali. Barcode hanya digunakan untuk identifikasi. |
| 04 · Authentication | Amendemen 20 November 2026 menyetujui linking otomatis Supabase dengan syarat keamanan provider. SMTP dan bukti A1–A4 tetap menjadi gerbang QA. |
| 05 · Admin | Diperbarui penghitungan pesanan aktif setelah Gagal Diambil, penanganan dua perubahan bersamaan, dan regresi Riverpod yang perlu diuji pada alur perubahan akses. |
| 06 · AI Food Assistant | Ditambahkan rujukan AI-TECH-001, batas kuota proyek serta syarat kelayakan audiens dan data sebelum Gemini diaktifkan. |

Untuk 37 aturan pada Order, Owner, dan Customer, percakapan sumber telah dipadankan pada pemeriksaan sebelumnya. Dokumen menandai bagian yang masih berupa ringkasan atau petikan kandidat. Arsip verbatim dengan hash tersedia untuk 21 persetujuan pada Authentication, Admin, dan AI. Penyuntingan ini mempertahankan teks persetujuan tersebut.

## Amendemen disetujui · ORDER-013B

19 November 2026. Pemilik proyek memberi arahan berikut setelah meninjau usulan penutupan pesanan yang gagal diserahkan.

> buat saja gagal diambil seperti state lain

**Keputusan berlaku.** Gagal Diambil menjadi status akhir dari Siap Diambil untuk kegagalan penyerahan oleh kantin. Owner kantin mengisi alasan dan mengonfirmasi. Pembayaran tetap Belum Lunas. Customer dan Owner melihat status serta alasan di riwayat. Pesanan keluar dari daftar aktif dan barcode berhenti tampil. Tidak Diambil tetap digunakan ketika Customer tidak mengambil. Keputusan ini menggantikan penanganan manual di luar aplikasi yang sebelumnya tercatat di ORDER-013B.

**Pemberitahuan dan bukti.** Mengikuti ORDER-017A, Gagal Diambil menggunakan realtime dan riwayat tanpa push khusus. Uji integrasi O4 pada dokumen 08 masih menunggu implementasi Android dan backend.

## Isu yang memerlukan keputusan atau bukti

### Sebelum rilis Auth · Bukti penautan Supabase

Pemilik proyek menyetujui Opsi A melalui [KC-AUTH-AMEND-2026-11-20-01](Kantin_Cerdas_AUTH_005A_Amendment_Final/AMENDEMEN_AUTH_005_005A_2026-11-20.md) pada 20 November 2026. Linking yang sah memakai ID Supabase yang sama. Uji A1–A4 pada QA hosted dan catat ID, jumlah profil/identitas/sesi, role serta kepemilikan. Jika provider gagal memenuhi invarian, pertahankan Google nonaktif untuk rilis dan eskalasi hasil.

### Sebelum pilot dengan notifikasi · Akses setelah logout

Simpan hanya sinyal minimal pada channel privat dan push. Arah uji rotasi topik perlu memastikan transaksi pencabutan dan pergantian tujuan pengiriman konsisten. Jangan biarkan antrean lama menerbitkan data baru kepada tujuan lama. Uji dua HP dengan akun sama, satu logout, satu masih sah. Shelf harus memeriksa sesi dan kepemilikan ketika detail diminta. [Cache otorisasi Realtime](https://supabase.com/docs/guides/realtime/authorization) · [Sesi pengguna](https://supabase.com/docs/guides/auth/sessions)

### Sebelum Gemini digunakan mahasiswa · Audiens, isi pesan, dan kuota

Verifikasi audiens aktual Kantin Cerdas terhadap syarat usia layanan Google, termasuk larangan untuk aplikasi yang ditujukan kepada atau mungkin diakses pengguna di bawah 18 tahun. Pada layanan gratis, data pribadi, rahasia, atau sensitif tidak boleh dikirim. Teks bebas pengguna juga dapat berisi data tersebut. Verifikasi cara aplikasi menangani masukan itu sebelum pengiriman, model yang tersedia, kuota proyek, dan konfigurasi tanpa peningkatan otomatis ke layanan berbayar. Jika syarat belum terpenuhi, jalankan pencarian katalog. Chat kuliner umum menunggu aktivasi Gemini. Target Rp0 pada spesifikasi berlaku untuk biaya tambahan Gemini API. [Ketentuan](https://ai.google.dev/gemini-api/terms) · [Harga](https://ai.google.dev/gemini-api/docs/pricing) · [Batas proyek](https://ai.google.dev/gemini-api/docs/rate-limits)

### Jika didistribusikan lewat Google Play · Permintaan penghapusan akun

Aplikasi yang memungkinkan pembuatan akun harus menyediakan cara memulai permintaan penghapusan dari aplikasi dan dari sumber web. Aturan Admin saat ini hanya mengatur dashboard Admin. Sebelum publikasi, tentukan alur pengguna, penanganan pesanan aktif, data yang dihapus, data yang perlu dipertahankan dengan alasan sah, serta penjelasan kepada pengguna. Perubahan produk ini memerlukan keputusan tersendiri. [Ketentuan penghapusan akun Google Play](https://support.google.com/googleplay/android-developer/answer/13327111)
