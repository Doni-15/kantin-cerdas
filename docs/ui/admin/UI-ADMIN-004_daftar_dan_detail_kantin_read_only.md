---
id: UI-ADMIN-004
module: admin
design_status: DRAFT
revision: 2026-11-19
target: Android-first
document_type: screen-ui-spec
business_rule_refs: [ADMIN-004, OWNER-002, ADMIN-003B]
---

# UI-ADMIN-004 — Daftar dan Detail Kantin Read Only

> **STATUS UI: DRAFT**. Ini spesifikasi perilaku/tampilan, BUKAN kode Flutter atau kontrak endpoint. Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, `../shared/06_STATES_LOADING_ERROR.md` dan file layar ini. Semua aturan bisnis LOCKED tetap berlaku terlepas dari status desain UI.

## Tujuan dan akses
Admin memantau informasi dasar kantin tanpa kontrol publikasi, menu, Buka/Tutup atau transaksi.

**Titik masuk:** Root nav Kantin Admin.

## Struktur layar — urutan visual atas → bawah
- Header **Kantin**, field **Cari kantin atau pemilik...**.
- Satu daftar baris: foto/placeholder kecil, nama kantin, nama Owner, status Diterbitkan/Belum dan Buka/Tutup (jika published).
- Detail: AppBar kembali, foto ringkas, nama, lokasi, Owner, kampus/universitas profil (jika merupakan bagian data baca dasar yang sah), status publikasi & operasional, jam informatif, deskripsi jika ada.
- Informasi **Hanya dapat dilihat oleh Admin**, tidak ada footer tombol mutasi.

## Interaksi
| Elemen / tindakan | Perilaku yang diwajibkan / arah navigasi |
| --- | --- |
| Cari | Nama kantin atau Owner yang boleh ditampilkan Admin. |
| Buka kantin | Buka detail read-only. |
| Kembali | Daftar Kantin Admin. |

## State layar
| Kondisi | Perilaku UI |
| --- | --- |
| belum diterbitkan | Tidak tampil seolah-olah dapat dipesan oleh Customer. |
| published Tutup | Status tetap terlihat dan berbeda dari publikasi. |
| Owner nonaktif | Jika data tersedia, status akun terpisah, tidak auto mengubah status Buka/Tutup. |
| empty/error | Empty berbeda dari fetch error. |

## Guard dan sumber data
- Admin hanya boleh informasi dasar sesuai ADMIN-004.
- Tidak ada akses transaksi atau operasional bisnis.

## Kriteria penerimaan (UI)
- [ ] Tidak ada tombol Buka/Tutup, publish, edit, hapus, atau menu order.
- [ ] Kantin belum terbit bisa dibaca Admin tetapi tidak dianggap published Customer.

## Batas / jangan ditambahkan
- Tidak ada transaksi, daftar pesanan, data keuangan, edit menu.

## Catatan implementasi dan status keputusan
- LAYOUT DRAFT.

**Rujukan bisnis:** ADMIN-004, OWNER-002, ADMIN-003B.
