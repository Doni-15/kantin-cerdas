---
id: UI-OWNER-004
module: owner
design_status: DRAFT
revision: 2026-11-19
target: Android-first
document_type: screen-ui-spec
business_rule_refs: [OWNER-004, OWNER-005, OWNER-005A, OWNER-002, ORDER-005, ORDER-011]
---

# UI-OWNER-004 — Daftar Menu Tambah Edit dan Arsip

> **STATUS UI: DRAFT**. Ini spesifikasi perilaku/tampilan, BUKAN kode Flutter atau kontrak endpoint. Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, `../shared/06_STATES_LOADING_ERROR.md` dan file layar ini. Semua aturan bisnis LOCKED tetap berlaku terlepas dari status desain UI.

## Tujuan dan akses
Mengelola menu aktif/arsip dengan daftar bersih dan halaman form terpisah; FAB `+` mengambang kanan bawah.

**Titik masuk:** Root nav Menu Owner.

## Struktur layar — urutan visual atas → bawah
- Header tunggal **Menu**, TANPA tombol Tambah di header.
- Field Cari menu; dua tab **Menu Aktif / Arsip** dengan underline tipis.
- Satu permukaan list rows: foto kecil, nama, kategori, harga, Tersedia/Habis atau Diarsipkan, chevron; divider tipis.
- Tautan/row **Kategori Menu** ke UI-OWNER-003.
- FAB bulat **`+`** ~56dp pada kanan bawah, melayang di atas nav; hanya tampil di daftar Menu Aktif.
- Form Tambah/Edit menu sebagai HALAMAN sendiri: Foto opsional; Nama Menu*; Kategori*; Harga rupiah bulat*; Deskripsi opsional; Tersedia/Habis; CTA Simpan.
- Edit menu aktif menyediakan **Arsipkan** dengan konfirmasi.
- Detail menu arsip read-only dengan aksi **Pulihkan** setelah konfirmasi, bukan hapus permanen.

## Interaksi
| Elemen / tindakan | Perilaku yang diwajibkan / arah navigasi |
| --- | --- |
| FAB + | Buka Tambah Menu, tidak menutup item/area safe navigation. |
| Baris menu aktif | Buka Edit Menu. |
| Baris arsip | Buka Detail Arsip dengan aksi Pulihkan. |
| Simpan | Validasi nama, satu kategori valid, harga integer >0 (batas backend), status. |
| Tersedia/Habis | Ubah manual; tidak menurunkan stok otomatis. |
| Arsipkan | Konfirmasi; tidak muncul di katalog aktif, item lama keranjang menjadi Tidak Tersedia dan blok checkout. |
| Pulihkan | Mengembalikan dari arsip, periksa harga dan status lagi; bukan menjamin langsung dapat dipesan. |
| Kategori Menu | Buka UI-OWNER-003. |

## State layar
| Kondisi | Perilaku UI |
| --- | --- |
| menu kosong | Empty state, FAB tetap bisa menambah menu pertama sebelum publish. |
| Habis | Tampil di katalog Customer sebagai Habis, tidak dapat order baru. |
| Arsip | Tidak tampil di katalog aktif Customer; snapshot order lama tetap ada. |
| foto opsional/gagal | Placeholder dan pertahankan foto lama jika upload gagal. |
| saving error | Form tidak dikosongkan. |
| draft kantin | Owner dapat mempersiapkan menu sebelum publish untuk memenuhi OWNER-002. |

## Guard dan sumber data
- Harga IDR integer tidak mengubah snapshot order yang sudah dibuat.
- Pilihan kategori dari backend, bukan tiga string statis di app.
- Restore menu dari arsip adalah hak OWNER-005 yang terkunci, walaupun mockup lama belum memuat tombolnya.

## Kriteria penerimaan (UI)
- [ ] FAB kanan bawah bukan header, tidak tampil di form.
- [ ] Restore tersedia pada Arsip dengan backend check.
- [ ] Menu Habis vs Arsip berbeda jelas.
- [ ] Form tidak memuat topping, stok numerik, atau promo.

## Batas / jangan ditambahkan
- Tidak ada hapus permanen, stock auto, multi-kantin Owner, CTA Tambah di appbar.

## Catatan implementasi dan status keputusan
- LAYOUT DRAFT; perubahan FAB disetujui sebagai arah visual, bukan permintaan LOCK.

**Rujukan bisnis:** OWNER-004, OWNER-005, OWNER-005A, OWNER-002, ORDER-005, ORDER-011.
