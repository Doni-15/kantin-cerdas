# Data minimum yang dibutuhkan layar (bukan kontrak endpoint)

> **Jangan membuat endpoint, RPC, SQL, atau provider Riverpod dari tabel ini.** Ini daftar field *konseptual* yang harus tersedia dari backend sesuai spesifikasi resmi. Nama field aktual mengikuti kontrak API yang kelak diverifikasi.

| Entitas tampilan | Data minimal | Catatan otorisasi dan ketidakpastian |
|---|---|---|
| Identitas Customer/Owner/Admin | ID stabil, nama, email, URL foto opsional, role, status aktif, metode login sah | Backend verifikasi token dan ID, bukan percaya email string dari klien. |
| Kantin | ID, owner, nama, kampus/univ, lokasi fisik, deskripsi/foto opsional, `published`, status `open`, jadwal | Published dan open adalah dua status terpisah; Owner nonaktif memblokir checkout tanpa mengubah keduanya. |
| Kategori | ID, kantin ID, nama, jumlah referensi menu aktif+arsip | Hitung referensi sebelum hapus; semua menu harus tepat satu kategori. |
| Menu | ID, kantin ID, kategori, nama, harga IDR bulat, status available, archived, foto/deskripsi opsional | Arsip dikecualikan dari katalog, tetapi masih ada untuk riwayat/keranjang. |
| Keranjang | Akun, kantin ID, baris item+jumlah+catatan, catatan pesanan umum, versi, snapshot harga yang dilihat | Persist per akun; tidak campur dua kantin. |
| Order | ID stabil, nomor representasi, kantin, customer, snapshot item/harga/catatan, total, status, pembayaran, alasan dan event history | Immutability; kode batang hanya untuk lookup; baca sesuai role. |
| Pengajuan Owner | ID, pemohon, nama rencana kantin, lokasi, alasan, status keputusan, alasan ditolak, indikator pesanan aktif | Admin cuma membaca indikator, bukan detail order. |
| Kuota Assistant | tanggal Jakarta, jumlah tersisa per Customer, limit proyek, availability fallback | UI tidak menghitung sebagai sumber kebenaran. |

## Perbedaan `Belum ada` vs `Error`

- Dataset kosong terverifikasi berbeda dari gagal mengambil data; jangan menyembunyikan kegagalan sebagai 0.
- Saat edit bersaing, backend boleh menolak perubahan karena konflik versi/status; UI refresh lalu tampilkan pesan.
- Bentuk enum, batas panjang, pemisahan item catatan identik, endpoint, pagination, dan urutan ID adalah bagian kontrak integrasi yang perlu ditetapkan/diuji, bukan ditarik langsung dari mockup.
