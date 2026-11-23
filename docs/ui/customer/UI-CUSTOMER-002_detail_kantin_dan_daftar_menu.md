---
id: UI-CUSTOMER-002
module: customer
design_status: LOCKED
revision: 2026-11-19
target: Android-first
document_type: screen-ui-spec
business_rule_refs: [CUSTOMER-002, OWNER-001, OWNER-002A, OWNER-003, ORDER-007, OWNER-005]
---

# UI-CUSTOMER-002 — Detail Kantin dan Daftar Menu

> **STATUS UI: LOCKED**. Ini spesifikasi perilaku/tampilan, BUKAN kode Flutter atau kontrak endpoint. Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, `../shared/06_STATES_LOADING_ERROR.md` dan file layar ini. Semua aturan bisnis LOCKED tetap berlaku terlepas dari status desain UI.

## Tujuan dan akses
Halaman subnavigasi untuk membaca profil kantin yang dipilih dan menemukan menu yang bisa dilihat/dipesan.

**Titik masuk:** Kartu kantin dari Beranda atau hasil Cari Global.

## Struktur layar — urutan visual atas → bawah
- AppBar: Kembali dan ikon Keranjang kanan. **Tidak ada bottom nav**.
- Foto/header kantin singkat (opsional, placeholder netral jika kosong).
- Nama kantin, lokasi fisik, status operasional Buka/Tutup dan informasi jam operasional; informasi Owner nonaktif dipisahkan dari Buka/Tutup.
- Heading **Daftar Menu**, field **Cari menu di kantin ini** (hanya kantin tersebut).
- Filter kategori dinamis: chip **Semua** + seluruh kategori Owner yang tersedia.
- Kartu menu horizontal: foto opsional kiri, nama, harga, deskripsi bila ada, label Tersedia/Habis, tombol **Tambah** jika dapat dipesan.

## Interaksi
| Elemen / tindakan | Perilaku yang diwajibkan / arah navigasi |
| --- | --- |
| Kembali | Kembali ke Beranda/Cari yang sebelumnya membuka halaman. |
| Keranjang | Buka UI-CUSTOMER-004. |
| Cari menu | Filter nama menu di dalam kantin ini saja; bukan global. |
| Kategori | Filter menu kantin ini, `Semua` adalah pilihan UI bukan kategori database. |
| Kartu menu | Buka UI-CUSTOMER-003. |
| Tambah | Tambahkan default 1 via keranjang sah; jika kantin berbeda, dialog konfirmasi penggantian; jangan menghapus keranjang diam-diam. |
| Lihat jadwal | Tampilkan jadwal informatif, tidak mengganti status Buka/Tutup. |

## State layar
| Kondisi | Perilaku UI |
| --- | --- |
| kantin Tutup | Semua menu tetap bisa dijelajahi; tidak menerima order baru. |
| Owner nonaktif | Tampilkan pesan “Kantin sementara tidak menerima pesanan”; status Buka/Tutup tersimpan tidak ditimpa. |
| menu Habis | Label Habis; tombol tambah disabled. |
| foto absen | Placeholder sesuai tema. |
| menu kosong | Empty state menu kosong/hasil filter tidak ada. |
| gagal fetch | Retry, jangan menampilkan status palsu. |

## Guard dan sumber data
- Publikasi/Owner aktif/Buka/Tutup/menu availability semuanya divalidasi backend saat add/checkout.
- Kampus/universitas merupakan data profil Owner untuk backend, **bukan filter pemilihan kampus Customer**.
- Menu yang benar-benar archived tidak muncul di katalog aktif, tetapi item lama tetap mungkin ada di keranjang.

## Kriteria penerimaan (UI)
- [ ] Header ringkas dan bagian foto tidak memakan mayoritas viewport.
- [ ] Kantin Tutup dan Owner nonaktif dapat dibedakan.
- [ ] Cari menu hanya mencakup kantin terpilih.
- [ ] Kartu Habis tidak bisa ditambah, kartu Tersedia memicu alur keranjang yang sah.
- [ ] Light/Dark, mobile kecil, font scale, keyboard tidak overflow.

## Batas / jangan ditambahkan
- Jangan memasukkan rating, promo, ongkir, chat Owner, atau kontrol operasional Owner.

## Catatan implementasi dan status keputusan
- UI visual LOCKED, jangan ubah komposisi tanpa persetujuan. Aturan tambah menu lintas kantin mengikuti ORDER-009.

**Rujukan bisnis:** CUSTOMER-002, OWNER-001, OWNER-002A, OWNER-003, ORDER-007, OWNER-005.
