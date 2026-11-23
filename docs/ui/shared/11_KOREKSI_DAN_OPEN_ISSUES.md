# Koreksi atas mockup sebelumnya & keputusan terbuka

**Prinsip:** Koreksi aturan bisnis yang sudah berlaku **bukan** mengunci atau mengubah desain UI yang masih DRAFT. Jika suatu tambahan mengubah visual LOCKED, lakukan review user sebelum revisi layar.

## Koreksi WAJIB dari sumber bisnis terbaru

| Area / file | Temuan | Konsekuensi pada spesifikasi UI |
|---|---|---|
| Customer Detail Order, Riwayat; Owner Order | Wireframe lama hanya memiliki 5 status akhir. | Tambah **Gagal Diambil** (ORDER-013B) dari Siap Diambil, alasan Owner wajib; terminal, Belum Lunas, barcode hilang, realtime/riwayat tanpa push. |
| Owner Profil Kantin | Form sebelumnya tidak memiliki field kampus/universitas. | Tambah field wajib **Kampus/Universitas** menurut OWNER-001; Customer tetap tidak memilih kampus di Beranda. |
| Owner Publikasi | Preview hanya memeriksa nama dan lokasi. | Backend wajib menolak publish tanpa kampus/lokasi dan tanpa minimal **1 menu Tersedia** (OWNER-002). |
| Owner Kategori | Preview tidak memiliki tombol Hapus karena disebut masih usulan. | OWNER-004A **sudah LOCKED bisnis**: boleh hapus **hanya benar-benar kosong** termasuk arsip; letakkan aksi Hapus di sheet/edit mode agar clean. |
| Owner Menu | Preview mengatakan pemulihan arsip belum diputuskan. | OWNER-005 **sudah mengizinkan Pulihkan**; tindakan Pulihkan perlu tersedia di detail arsip. |
| Admin Pengguna | Preview tidak memiliki alasan nonaktif dan tombol aktifkan lagi. | ADMIN-003 **wajib alasan penonaktifan** dan **boleh reaktivasi**; kedua aksi perlu UI dan audit, tunduk guard. |
| Admin Beranda | Preview hanya menunjukkan pengajuan menunggu. | ADMIN-005 menuntut ringkasan **pengguna, pengajuan Owner, kantin, akun nonaktif**. Tata letak boleh ringkas tanpa kartu besar. |
| Keranjang/Checkout | Mockup hanya mencontohkan catatan item. | ORDER-010 juga mendukung **catatan umum pesanan opsional**. |
| AI Chat | Mockup terlalu menekankan katalog. | AI-001 juga mengizinkan **diskusi kuliner umum** saat model boleh diaktifkan; pisahkan jawaban umum vs hasil katalog terverifikasi. |

## Terbuka / perlu keputusan atau uji, JANGAN DIKLAIM FINAL

- **AUTH-005/AUTH-005A:** baseline LOCKED melarang auto-link; dokumen 04 (1) memuat **usulan amendemen** untuk Supabase automatic identity linking. Arah teknis bukan pengesahan bisnis; lakukan keputusan dan uji keamanan sebelum integrasi final.
- **AI model/Free Tier:** model bernama “Gemini 3.5 Flash-Lite” terdapat pada business spec, tetapi ketersediaan dan syarat layanan harus diverifikasi ketika integrasi; jangan menagih Rp otomatis.
- **AI pengguna <18 dan data sensitif:** validasi syarat layanan dan content filtering sebelum mengaktifkan chat AI. Fallback katalog dapat tetap aktif.
- **Google Play:** alur permintaan penghapusan akun dari app dan web perlu keputusan tersendiri sebelum distribusi; tidak otomatis disisipkan ke profil tanpa desain.
- **Catatan sama/berbeda di keranjang:** saran penggabungan per `menu+catatan` pernah dibahas, **belum LOCKED**; kontrak item identity/merge perlu ditetapkan agar UI/backend sama.
- **Status visual DRAFT:** UI-AUTH selain Login, Customer 003–011, Owner 001–008, Admin 001–005, AI-001. Tidak boleh diberi cap LOCKED hanya karena user berkata “lanjutkan”.
- **Realtime revocation** dan channel rotation menunggu uji dua perangkat, bukan proven; jangan menganggap logout menghapus semua akses live seketika tanpa backend guard.
- **Owner UI aktif saat belum terbit:** menu dapat dipersiapkan sebelum publish (prasyarat min 1 tersedia); daftar menu tidak boleh sepenuhnya diblokir oleh status draft.
- **Foto/edit email:** foto Google jika tersedia dan user confirm; perubahan email login termasuk aturan Auth aman walaupun mockup Edit Profil menampilkan email read-only. Jalurnya harus diputuskan pada integrasi.
- **Dashboard Order Owner:** rekomendasi tampilan ringkas; angka harus dari backend dan tidak boleh dianggap statistik keuangan.
