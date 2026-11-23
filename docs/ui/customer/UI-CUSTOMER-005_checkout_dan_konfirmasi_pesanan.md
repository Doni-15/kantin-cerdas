---
id: UI-CUSTOMER-005
module: customer
design_status: DRAFT
revision: 2026-11-19
target: Android-first
document_type: screen-ui-spec
business_rule_refs: [ORDER-004, ORDER-005, ORDER-006, ORDER-008, ORDER-009, ORDER-010, ORDER-011, CUSTOMER-004]
---

# UI-CUSTOMER-005 — Checkout dan Konfirmasi Pesanan

> **STATUS UI: DRAFT**. Ini spesifikasi perilaku/tampilan, BUKAN kode Flutter atau kontrak endpoint. Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, `../shared/06_STATES_LOADING_ERROR.md` dan file layar ini. Semua aturan bisnis LOCKED tetap berlaku terlepas dari status desain UI.

## Tujuan dan akses
Konfirmasi final item, kantin, lokasi pengambilan, metode pembayaran tunai, catatan dan total sebelum membuat order idempotent.

**Titik masuk:** Keranjang yang lolos seluruh guard.

## Struktur layar — urutan visual atas → bawah
- AppBar Kembali + **Checkout**.
- Nama kantin dan instruksi singkat untuk memeriksa pesanan.
- Ringkasan read-only item + qty + harga snapshot calon checkout + catatan item & catatan umum.
- Pengambilan: **Ambil langsung di kantin** + lokasi Owner.
- Pembayaran: **Bayar tunai saat mengambil makanan**.
- Total akhir dan CTA tunggal **Kirim Pesanan** di action bar bawah.

## Interaksi
| Elemen / tindakan | Perilaku yang diwajibkan / arah navigasi |
| --- | --- |
| Kembali | Kembali ke Keranjang untuk edit qty, catatan, harga. |
| Harga berubah | Tampilkan harga lama/baru, minta konfirmasi ulang harga/version. |
| Kirim Pesanan | Kirim online, pakai ID checkout stabil yang diterbitkan/disimpan backend; cegah submit ganda. |
| Sukses terverifikasi | Buka UI-CUSTOMER-006 status Menunggu Konfirmasi, bukan Lunas. |
| Respons tidak pasti | Tampilkan pemeriksaan hasil; retry/recovery ID yang sama; **tidak** membuat pesanan baru. |

## State layar
| Kondisi | Perilaku UI |
| --- | --- |
| item Habis/arsip | Blocked dan diarahkan memperbaiki item di Keranjang. |
| kantin Tutup/Owner nonaktif | Blocked, draft tersimpan. |
| harga berubah | Blocked sampai persetujuan terbaru. |
| offline | Kirim disabled, bukan queue offline yang menimbulkan duplikat. |
| loading | Tombol disabled dan indikator in-flight. |
| uncertain | Status belum pasti, cek backend dengan ID logis yang sama. |
| success | Order dibuat 1 kali, keranjang bersihkan hanya setelah konfirmasi sukses sesuai kontrak backend. |

## Guard dan sumber data
- Checkout server atomik (PostgreSQL) dengan idempotency stabil per logical attempt; bukan UX click-only.
- Tidak ada mutasi order snapshot setelah dibuat.
- Tidak mengarang nomor pesanan atau waktu berdasarkan perangkat.

## Kriteria penerimaan (UI)
- [ ] Checkout tidak memiliki input jumlah ulang.
- [ ] Pembayaran tunai dan lokasi pengambilan jelas, tidak ada delivery.
- [ ] Double tap, timeout, restart dan retry tidak menyebabkan 2 order.
- [ ] Respons tidak pasti tidak disebut “gagal” atau “sukses” tanpa bukti.

## Batas / jangan ditambahkan
- Tidak ada transfer bank, QRIS, alamat kirim, promo, ongkos pengantaran, tombol bayar sekarang.

## Catatan implementasi dan status keputusan
- LAYOUT DRAFT; nama API/ID idempotency tidak diputuskan UI.

**Rujukan bisnis:** ORDER-004, ORDER-005, ORDER-006, ORDER-008, ORDER-009, ORDER-010, ORDER-011, CUSTOMER-004.
