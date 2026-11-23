# Ringkasan batas MVP (non-otoritatif)

> Untuk teks resmi tiap aturan, baca spesifikasi bisnis terbaru. Ringkasan ini untuk mencegah AI menciptakan fitur yang tidak ada.

- Produk: **Kantin Cerdas**; locale `id-ID`; uang IDR rupiah bulat; timezone bisnis `Asia/Jakarta`.
- Target tahap awal: **Android**. iOS/web/desktop bukan syarat rilis Android; UI tetap dirancang adaptif jika kelak diperluas.
- Area layanan: kantin dalam area USU. **Customer tidak memilih universitas di Beranda**; field kampus/universitas pada profil Owner tetap diwajibkan OWNER-001.
- Pengguna registrasi publik hanya menjadi **Customer**; Owner diperoleh melalui review Admin; akun Admin tidak berasal dari registrasi publik.
- Pesan makanan dari satu kantin, **ambil sendiri, bayar tunai ketika mengambil**, tanpa pengiriman dan tanpa pembayaran digital.
- Kantin dapat belum terbit, terbit+Tutup, terbit+Buka. Jam operasional informatif, tidak otomatis mengubah Buka/Tutup.
- Katalog menu memiliki kategori, nama, harga, ketersediaan Tersedia/Habis, opsional deskripsi+foto, serta arsip+pulihkan.
- Keranjang satu kantin; memiliki kuantitas dan catatan item maupun catatan umum; persist per akun, validasi harga/ketersediaan ulang, checkout online idempotent.
- Status order lihat `07_STATUS_PESANAN.md`; semua status terminal tercatat, pembayaran **Lunas hanya Selesai**.
- Barcode **Code 128** untuk identifikasi pesanan, bukan konfirmasi uang atau aksi otomatis.
- Admin meninjau pengajuan Owner, mengaktif/nonaktif akun (dengan alasan wajib saat nonaktif), melihat kantin read-only; tidak memproses pesanan.
- AI Food Assistant berbasis katalog nyata; chat kuliner umum hanya jika layanan AI layak diaktifkan, fallback katalog; 10 panggilan model/user/hari, reset WIB, plafon Free Tier proyek.
- Tidak ada rating, promosi, varian/topping, stok numerik, ongkir, nomor telepon wajib, NIM/fakultas, grafik pendapatan, unpublish, hapus menu permanen, auto-timeout, atau kontrol role oleh UI.
