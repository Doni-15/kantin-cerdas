# State standar seluruh layar

| State | Aturan UI |
|---|---|
| `initial` | Jangan memalsukan hasil sukses/data sebelum fetch. |
| `loading` | Berikan indikator; tidak perlu animasi berlebihan. Jangan ganti nilai cached menjadi 0. |
| `empty` | Pesan kontekstual; berbeda dari loading dan network error. |
| `validation_error` | Ditampilkan dekat field; input tetap ada. |
| `offline` | Informasikan koneksi, retry jika aman; jangan drop draft keranjang/form. |
| `server_error` | Pesan netral dan aksi retry; tidak membocorkan SQL/token/stack trace. |
| `request_in_flight` | Cegah double-submit; tombol disabled/loading. |
| `uncertain_result` | **Bukan sukses dan bukan gagal definitif**; query status / hasil idempotency dari backend sebelum retry mutasi. |
| `permission_denied` | Penjelasan singkat dan arah keluar/reauth; server guard tetap wajib. |
| `stale_data` | Ambil ulang data sah ketika status/harga/akses berubah; jangan memaksakan hasil lama. |
| `success` | Hanya setelah backend konfirmasi (kecuali perubahan local-only seperti tab). |

## Prinsip aplikasi

- Mutasi status order, role, Buka/Tutup, publish, profil, harga, kuota dan akun harus dipastikan backend.
- Saat logout, jangan menampilkan detail akun/pesanan lama dari cache tanpa autentikasi; perhatikan kemampuan realtime sesi lama yang masih tersambung.
- Saat aplikasi kembali online, refresh data dari backend setelah sinyal realtime/FCM, bukan percaya isi push.
- Error pembacaan data sensitif tidak boleh membuka data role lain.
- Form panjang dan input chat harus tetap aman ketika keyboard muncul; tekstur scroll dan focus visible.
- Semua state diuji di Light/Dark.
