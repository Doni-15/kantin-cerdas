---
id: UI-CUSTOMER-004
module: customer
design_status: DRAFT
revision: 2026-11-19
target: Android-first
document_type: screen-ui-spec
business_rule_refs: [ORDER-005, ORDER-006, ORDER-008, ORDER-009, ORDER-010, OWNER-005A]
---

# UI-CUSTOMER-004 — Keranjang

> **STATUS UI: DRAFT**. Ini spesifikasi perilaku/tampilan, BUKAN kode Flutter atau kontrak endpoint. Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, `../shared/06_STATES_LOADING_ERROR.md` dan file layar ini. Semua aturan bisnis LOCKED tetap berlaku terlepas dari status desain UI.

## Tujuan dan akses
Memungkinkan Customer memeriksa serta menyunting item keranjang satu kantin dan memperbaiki blocker sebelum checkout.

**Titik masuk:** Ikon keranjang pada Beranda, Detail Kantin atau Detail Menu.

## Struktur layar — urutan visual atas → bawah
- Header Kembali + **Keranjang**, tidak root bottom nav.
- Identitas satu kantin sekali di atas daftar; tidak berulang di setiap item.
- Baris item ringkas: foto/placeholder, nama, harga saat ini, pengatur jumlah, catatan per item (edit inline).
- Field catatan umum **opsional** untuk satu pesanan, terpisah dari catatan item (koreksi ORDER-010).
- Peringatan dekat item saat Habis, Diarsipkan/Tidak Tersedia, atau harga berubah; lama dan baru terlihat.
- Ringkasan Subtotal + informasi pembayaran tunai di bawah; CTA **Lanjut ke Checkout** jika syarat terpenuhi.

## Interaksi
| Elemen / tindakan | Perilaku yang diwajibkan / arah navigasi |
| --- | --- |
| Minus saat jumlah=1 | Hapus baris item ketika diturunkan ke 0; perbarui ringkasan. |
| Plus | Tambah kuantitas hanya ketika menu dapat dipesan. |
| Ubah catatan item | Edit tanpa menghapus catatan lain. |
| Catatan umum | Simpan ke draft order terpisah, tidak menggantikan catatan item. |
| Harga berubah | Tampilkan harga lama/baru, minta persetujuan eksplisit sesuai versi sebelum checkout. |
| Item bermasalah | Customer menghapus/mengganti secara manual; tidak auto-delete. |
| Lanjut ke Checkout | Buka UI-CUSTOMER-005 setelah validasi backend/cache yang sah. |

## State layar
| Kondisi | Perilaku UI |
| --- | --- |
| kosong | Pesan Keranjang masih kosong; aksi Jelajahi Kantin. |
| Habis | Baris tetap ada, label Habis, seluruh checkout blocked. |
| Diarsipkan | Baris tetap ada, label Tidak Tersedia, seluruh checkout blocked. |
| harga berubah | Persetujuan harga lama→baru diperlukan. |
| kantin tutup/Owner nonaktif | Draft tetap ada; checkout blocked. |
| offline | Draft tetap tersedia; checkout online tidak bisa dijalankan. |
| uncertain mutasi | Pertahankan versi lokal sampai backend mengonfirmasi hasil. |

## Guard dan sumber data
- Persist draft per akun dan versi; satu kantin aktif per keranjang.
- Harga final ditentukan server saat checkout; UI tidak dipercaya sebagai total final.
- Snapshot order selesai tidak berubah ketika keranjang atau menu diubah.

## Kriteria penerimaan (UI)
- [ ] Jumlah 1→0 menghapus, jumlah tidak negatif.
- [ ] Catatan item dan catatan umum sama-sama opsional.
- [ ] Harga baru perlu persetujuan, item Habis/arsip memblokir checkout.
- [ ] Gagal koneksi tidak menghilangkan draft.
- [ ] Keranjang dari kantin lain tidak tercampur.

## Batas / jangan ditambahkan
- Tidak ada pajak/biaya layanan/ongkir atau metode pembayaran baru tanpa aturan resmi.

## Catatan implementasi dan status keputusan
- LAYOUT DRAFT; penggabungan baris menu dengan catatan identik belum disahkan.

**Rujukan bisnis:** ORDER-005, ORDER-006, ORDER-008, ORDER-009, ORDER-010, OWNER-005A.
