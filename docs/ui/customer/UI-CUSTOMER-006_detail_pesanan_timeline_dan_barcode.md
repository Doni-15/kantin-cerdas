---
id: UI-CUSTOMER-006
module: customer
design_status: DRAFT
revision: 2026-11-19
target: Android-first
document_type: screen-ui-spec
business_rule_refs: [CUSTOMER-005, ORDER-001, ORDER-004, ORDER-013, ORDER-013B, ORDER-015, ORDER-016]
---

# UI-CUSTOMER-006 — Detail Pesanan Timeline dan Barcode

> **STATUS UI: DRAFT**. Ini spesifikasi perilaku/tampilan, BUKAN kode Flutter atau kontrak endpoint. Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, `../shared/06_STATES_LOADING_ERROR.md` dan file layar ini. Semua aturan bisnis LOCKED tetap berlaku terlepas dari status desain UI.

## Tujuan dan akses
Satu tampilan untuk status terkini, riwayat transisi, ringkasan snapshot, lokasi serta status pembayaran.

**Titik masuk:** Checkout sukses backend atau tab Pesanan / Riwayat.

## Struktur layar — urutan visual atas → bawah
- AppBar **Detail Pesanan**, nomor pesanan asli di bagian atas.
- Status utama (teks jelas) + deskripsi singkat.
- Timeline vertikal hanya untuk kejadian yang benar-benar tercatat backend, urutan sesuai event; tidak membuat timestamp palsu.
- Jika `Siap Diambil`, tampilkan kartu **Barcode Code128** dan nomor pesanan; di status lain sembunyikan.
- Alasan jika Ditolak, Gagal Dipenuhi, **Gagal Diambil**.
- Ringkasan snapshot item, harga, jumlah, catatan per item & umum; total.
- Pengambilan, lokasi, metode tunai, status Belum Lunas/Lunas.
- Jika Menunggu Konfirmasi, tombol Batalkan dengan konfirmasi.

## Interaksi
| Elemen / tindakan | Perilaku yang diwajibkan / arah navigasi |
| --- | --- |
| Batalkan | Hanya Customer pemilik order, dari Menunggu Konfirmasi; konfirmasi, lalu backend atomik. |
| Barcode | Tampilkan Code 128 untuk lookup; nomor pesanan juga teks yang bisa ditunjukkan; tidak ada “Bayar”. |
| Riwayat | Status terminal tampil untuk audit tanpa operasi edit. |
| Kembali | Kembali tab Pesanan atau tujuan checkout yang sah. |

## State layar
| Kondisi | Perilaku UI |
| --- | --- |
| pending | Menunggu Konfirmasi, tombol Batal (sampai Owner lebih dulu menerima). |
| Diproses | Perkiraan persiapan dari Owner jika ada, tanpa countdown state transition. |
| Siap Diambil | Barcode+nomor muncul. |
| Selesai | Lunas, barcode hilang. |
| Dibatalkan/Ditolak/Gagal Dipenuhi/Tidak Diambil | Status terminal, tanpa barcode; alasan ditampilkan jika disyaratkan. |
| Gagal Diambil | **Terminal dari Siap Diambil**, alasan wajib oleh Owner, Belum Lunas, **barcode hilang**. |
| offline/stale | Data cached dibedakan dari status terbaru, refresh saat online. |

## Guard dan sumber data
- Timeline bukan status yang ditebak dari push; event backend adalah sumber kebenaran.
- Barcode Code128 hanya saat Siap Diambil, scan tidak auto-complete.
- Seluruh enam status terminal harus dikenal, termasuk Gagal Diambil.

## Kriteria penerimaan (UI)
- [ ] Semua status aktif+terminal terwakili di UI.
- [ ] Gagal Diambil menampilkan alasan, riwayat, Belum Lunas, tanpa barcode.
- [ ] Status Selesai hanya Lunas.
- [ ] Pembatalan setelah Diproses ditolak backend dan UI refresh.

## Batas / jangan ditambahkan
- Tidak ada tombol Customer menandai Selesai, transfer tunai digital, pelacakan kurir.

## Catatan implementasi dan status keputusan
- LAYOUT DRAFT; koreksi Gagal Diambil dari dokumen bisnis 19 Nov, tidak tercantum di sketsa chat lama.

**Rujukan bisnis:** CUSTOMER-005, ORDER-001, ORDER-004, ORDER-013, ORDER-013B, ORDER-015, ORDER-016.
