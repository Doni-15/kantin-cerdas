# Status Order resmi dan transisi

**Rujukan:** ORDER-001–ORDER-017A, termasuk ORDER-013B yang diamendemen **19 November 2026**. Semua perubahan atomik dan diaudit backend.

| Status saat ini | Pelaku | Aksi | Status hasil | Konsekuensi pembayaran / UI |
|---|---|---|---|---|
| Menunggu Konfirmasi | Customer | Batalkan | Dibatalkan | Terminal, Belum Lunas |
| Menunggu Konfirmasi | Owner | Terima | Diproses | Estimasi persiapan umum diterapkan |
| Menunggu Konfirmasi | Owner | Tolak + alasan wajib | Ditolak | Terminal, Belum Lunas; alasan ke Customer |
| Diproses | Owner | Tandai Siap Diambil | Siap Diambil | Barcode Code 128 mulai tampil di Customer |
| Diproses | Owner | Gagal Dipenuhi + alasan wajib | Gagal Dipenuhi | Terminal, Belum Lunas |
| Siap Diambil | Owner | Konfirmasi uang tunai diterima **dan** makanan diserahkan | Selesai | Terminal dan Lunas **bersamaan** |
| Siap Diambil | Owner | Konfirmasi tidak diambil | Tidak Diambil | Terminal, Belum Lunas; tanpa penalti otomatis |
| Siap Diambil | Owner | **Gagal Diambil** + alasan wajib | Gagal Diambil | Terminal, Belum Lunas; masalah penyerahan di pihak kantin |

## Aturan turunan UI

- **Aktif:** Menunggu Konfirmasi, Diproses, Siap Diambil.
- **Riwayat/terminal:** Selesai, Dibatalkan, Ditolak, Gagal Dipenuhi, Tidak Diambil, Gagal Diambil.
- **Barcode tampak HANYA selama `Siap Diambil`**. Saat Selesai atau terminal lain, barcode disembunyikan.
- Pemindaian Code 128 **hanya mencari pesanan** dan memerlukan otorisasi Owner; tidak menyelesaikan pesanan ataupun mencatat tunai.
- Tidak ada auto cancel, auto accept, auto siap, auto tidak diambil, atau countdown pemicu status.
- `Gagal Dipenuhi` **hanya dari Diproses**; `Gagal Diambil` **hanya dari Siap Diambil**; `Tidak Diambil` hanya jika Customer tidak mengambil.
- Estimasi waktu persiapan informatif, bukan waktu pasti atau cron perubahan status.
- Status pembayaran bukan sekadar inferensi CSS; tampilkan `Lunas` hanya untuk `Selesai`, status lainnya `Belum Lunas` (untuk transaksi belum dibayar); copy untuk terminal dapat menjelaskan tidak ada pembayaran.

## Tujuh kejadian push (ORDER-017A)

1. Pesanan baru → Owner.
2. Customer membatalkan → Owner.
3. Pesanan diterima → Customer.
4. Pesanan ditolak → Customer.
5. Pesanan siap diambil → Customer.
6. Pesanan gagal dipenuhi → Customer.
7. Pesanan tidak diambil → Customer.

`Selesai` dan `Gagal Diambil` **tidak punya push khusus** di MVP; tetap via realtime, refresh, dan riwayat. FCM best effort; kegagalannya bukan kegagalan transaksi.
