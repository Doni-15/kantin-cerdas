---
id: UI-CUSTOMER-003
module: customer
design_status: DRAFT
revision: 2026-11-19
target: Android-first
document_type: screen-ui-spec
business_rule_refs: [ORDER-009, ORDER-010, ORDER-005, OWNER-005, CUSTOMER-002]
---

# UI-CUSTOMER-003 — Detail Menu

> **STATUS UI: DRAFT**. Ini spesifikasi perilaku/tampilan, BUKAN kode Flutter atau kontrak endpoint. Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, `../shared/06_STATES_LOADING_ERROR.md` dan file layar ini. Semua aturan bisnis LOCKED tetap berlaku terlepas dari status desain UI.

## Tujuan dan akses
Menyediakan informasi lengkap dan opsi jumlah/catatan item sebelum ditambahkan ke keranjang. Visual sudah dibahas, belum secara eksplisit LOCKED.

**Titik masuk:** Kartu menu pada Detail Kantin, Cari Global, atau kartu rekomendasi Food Assistant.

## Struktur layar — urutan visual atas → bawah
- AppBar Kembali + Keranjang, tanpa root bottom nav.
- Foto menu proporsional; placeholder jika tidak ada.
- Nama, kategori, nama kantin, harga rupiah, status Tersedia/Habis; deskripsi jika disediakan Owner.
- Kontrol jumlah mulai **1**, minus berhenti di 1 untuk form Tambah Menu baru.
- Catatan **per item** opsional dengan textarea, tidak wajib.
- Total dihitung jumlah × harga terbaru yang terlihat; CTA **Tambah ke Keranjang** pada action bar bawah SafeArea.

## Interaksi
| Elemen / tindakan | Perilaku yang diwajibkan / arah navigasi |
| --- | --- |
| Jumlah +/− | Ubah jumlah tanpa membuat item tambahan sampai CTA; minus form berhenti di 1. |
| Catatan item | Simpan catatan pada item yang dipilih. |
| Tambah ke Keranjang | Validasi kantin/menu dari backend; tambah sesuai jumlah, catatan, dan aturan satu kantin. |
| Kantin lain | Tampilkan konfirmasi ganti keranjang sebelum mutasi; Batal menjaga keranjang lama. |
| Kembali | Kembali ke hasil pencarian/Detail Kantin semula. |

## State layar
| Kondisi | Perilaku UI |
| --- | --- |
| menu Habis | Tetap terlihat dengan label Habis, CTA disabled. |
| kantin Tutup | Informasi tetap terlihat, CTA disabled. |
| Owner nonaktif | Pesan tidak menerima pesanan baru, CTA disabled. |
| foto absen | Placeholder netral. |
| price stale | Refresh/validasi pada keranjang dan checkout; jangan menyimpan harga lama sebagai final. |

## Guard dan sumber data
- Harga, kategori dan ketersediaan adalah data dari backend.
- Catatan item jangan disatukan sembarang dengan catatan order umum.
- Kebijakan merge dua baris menu+catatan sama/berbeda masih terbuka, tidak mengunci skema item.

## Kriteria penerimaan (UI)
- [ ] Jumlah awal 1 dan total sesuai jumlah.
- [ ] Catatan dapat kosong.
- [ ] Tombol disabled saat menu atau kantin tidak layak checkout.
- [ ] Konfirmasi ganti kantin tidak kehilangan keranjang saat Batal.

## Batas / jangan ditambahkan
- Jangan menambah pilihan topping/ukuran, ulasan, diskon, stok numerik, metode delivery.

## Catatan implementasi dan status keputusan
- LAYOUT DRAFT. Akses langsung dari kartu menu berbeda dengan tombol Tambah cepat pada detail kantin.

**Rujukan bisnis:** ORDER-009, ORDER-010, ORDER-005, OWNER-005, CUSTOMER-002.
