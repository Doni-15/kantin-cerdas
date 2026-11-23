# Format konten dan microcopy

- Bahasa Indonesia natural, singkat, tanpa jargon teknis ke pengguna.
- IDR: `Rp15.000`, jumlah bulat, `id-ID`; jangan mengubah angka server dengan pembulatan float.
- Nomor pesanan: tampilkan persis dari backend, termasuk nol awal; contoh `KC-1042` bukan pola wajib.
- Tanggal/jam: zona Asia/Jakarta; tidak tampilkan waktu fiktif. Format tepat mengikuti komponen tanggal yang disetujui saat implementasi.
- Label STATUS resmi: `Menunggu Konfirmasi`, `Diproses`, `Siap Diambil`, `Selesai`, `Dibatalkan`, `Ditolak`, `Gagal Dipenuhi`, `Tidak Diambil`, `Gagal Diambil`.
- Penerbitan: `Belum Diterbitkan` / `Diterbitkan`; operasional: `Buka` / `Tutup`; kelayakan checkout dapat terblokir walau Buka jika Owner nonaktif.
- Menu: `Tersedia`, `Habis`, `Tidak Tersedia` (arsip di keranjang); `Diarsipkan` untuk Owner.
- Pengajuan: `Menunggu Review`, `Disetujui`, `Ditolak`.
- Label eksplisit terkunci Beranda: `Mau makan apa hari ini?`, `Jelajahi Kantin`, `Cari makanan atau kantin...`, `Semua / Buka / Tutup`; nav `Beranda / Cari / Pesanan / Profil`, FAB robot **tanpa label terlihat**.
- Contoh label halaman lain bersifat DRAFT, kecuali Auth login yang dikunci dan tersimpan di file asli `auth/02_LOGIN_UI_AUTH_001.md`.
- Kesalahan jaringan: `Koneksi bermasalah. Coba lagi.` Tidak pernah menampilkan pesan internal/token/kode SQL.
