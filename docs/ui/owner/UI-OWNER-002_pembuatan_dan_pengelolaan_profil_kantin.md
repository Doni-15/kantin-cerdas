---
id: UI-OWNER-002
module: owner
design_status: DRAFT
revision: 2026-11-19
target: Android-first
document_type: screen-ui-spec
business_rule_refs: [OWNER-001, OWNER-002, OWNER-002A, OWNER-002B, OWNER-003, ORDER-007, ORDER-012]
---

# UI-OWNER-002 — Pembuatan dan Pengelolaan Profil Kantin

> **STATUS UI: DRAFT**. Ini spesifikasi perilaku/tampilan, BUKAN kode Flutter atau kontrak endpoint. Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, `../shared/06_STATES_LOADING_ERROR.md` dan file layar ini. Semua aturan bisnis LOCKED tetap berlaku terlepas dari status desain UI.

## Tujuan dan akses
Satu form perkantinan untuk membuat/edit profil, jadwal, estimasi persiapan, penerbitan pertama dan Buka/Tutup manual.

**Titik masuk:** Root nav Kantin, Dashboard Owner belum memiliki kantin, atau tombol kelola.

## Struktur layar — urutan visual atas → bawah
- AppBar **Buat Kantin** atau **Informasi Kantin**, tombol kembali.
- Foto kantin opsional dengan pilih/preview/simpan.
- Bagian Informasi Dasar: **Nama Kantin***, **Kampus/Universitas***, **Lokasi fisik detail*** (koreksi OWNER-001), Deskripsi opsional.
- Bagian **Jam Operasional** per hari, informatif; edit melalui panel/bagian yang dapat dibuka, tidak memenuhi form awal.
- Bagian **Estimasi Persiapan Umum** untuk order baru (OWNER-003, ORDER-012), satu input/selector yang divalidasi, tanpa pengaturan per order otomatis.
- Simpan Perubahan / Simpan & Buat Kantin sebagai aksi data profil.
- Status **Belum Diterbitkan** dengan tombol **Terbitkan Kantin** hanya ketika semua prasyarat server terpenuhi: profil wajib lengkap + minimal 1 menu Tersedia.
- Jika published: status **Diterbitkan**, kontrol Buka/Tutup manual terpisah; tidak ada Unpublish.

## Interaksi
| Elemen / tindakan | Perilaku yang diwajibkan / arah navigasi |
| --- | --- |
| Simpan profil | Menyimpan form saja; tidak otomatis menerbitkan/membuka kantin. |
| Foto | Pilih, preview, konfirmasi; foto lama aman jika gagal. |
| Jam operasional | Edit jadwal; jam tidak auto Buka/Tutup. |
| Estimasi persiapan | Simpan estimasi umum yang diberlakukan pada order yang diterima berikutnya sesuai backend. |
| Terbitkan | Backend memeriksa nama, kampus, lokasi, minimal 1 menu Tersedia; konfirmasi konsekuensi tanpa Unpublish; status awal Tutup. |
| Buka/Tutup | Owner mengubah manual setelah published; konfirmasi backend; order aktif tetap diproses. |
| Menu/Kategori | Navigasi menuju UI-OWNER-004 untuk menyiapkan minimal satu menu eligible. |

## State layar
| Kondisi | Perilaku UI |
| --- | --- |
| Owner baru | Form kosong dengan field wajib; dapat menyimpan draft bila aturan API mengizinkan. |
| draft tanpa menu Tersedia | Tombol Terbitkan disabled atau server menolak dengan pesan spesifik. |
| published Tutup | Masih tampil Customer, tidak menerima pesanan baru. |
| published Buka | Checkout hanya jika Owner aktif dan item eligible. |
| Owner nonaktif | Tidak menerima order baru meski status Buka tetap tersimpan. |
| saving error | Pertahankan form/foto lama; jangan optimistically mark published. |
| jam tidak valid | Error inline untuk waktu/hari/rentang. |

## Guard dan sumber data
- OWNER-001 wajib `kampus/universitas` walau Beranda Customer tidak menyediakan pemilihan universitas.
- OWNER-002: hanya satu kantin per Owner, publish setelah profil sah + min satu menu Tersedia.
- OWNER-002B: tidak ada unpublish manual; foto/deskripsi bukan persyaratan wajib.

## Kriteria penerimaan (UI)
- [ ] Tiga field profil wajib dan estimasi persiapan tersedia.
- [ ] Terbitkan tidak lolos tanpa menu Tersedia.
- [ ] Published mulai Tutup dan tetap terlihat saat Tutup.
- [ ] Jam informatif, bukan auto toggle.
- [ ] Form panjang nyaman untuk keyboard, Light/Dark.

## Batas / jangan ditambahkan
- Tidak ada kantin kedua, unpublish, foto wajib, publikasi otomatis, stok numerik.

## Catatan implementasi dan status keputusan
- LAYOUT DRAFT. Field Kampus/Universitas, min-menu publish, dan estimasi persiapan adalah pelengkapan dari bisnis LOCKED yang tidak tampil lengkap pada mockup lama.

**Rujukan bisnis:** OWNER-001, OWNER-002, OWNER-002A, OWNER-002B, OWNER-003, ORDER-007, ORDER-012.
