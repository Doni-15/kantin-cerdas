---
id: UI-CUSTOMER-001
module: customer
design_status: LOCKED
revision: 2026-11-19
target: Android-first
document_type: screen-ui-spec
business_rule_refs: [CUSTOMER-001, ORDER-007, OWNER-002A, ADMIN-003B]
---

# UI-CUSTOMER-001 — Beranda Customer

> **STATUS UI: LOCKED**. Ini spesifikasi perilaku/tampilan, BUKAN kode Flutter atau kontrak endpoint. Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, `../shared/06_STATES_LOADING_ERROR.md` dan file layar ini. Semua aturan bisnis LOCKED tetap berlaku terlepas dari status desain UI.

## Tujuan dan akses
Beranda katalog kantin yang sudah diterbitkan. Customer langsung dapat mencari makanan/kantin atau menjelajah kantin, tanpa memilih universitas.

**Titik masuk:** Login sah → root Customer; menu navigasi Beranda.

## Struktur layar — urutan visual atas → bawah
- Header tunggal **Mau makan apa hari ini?**; ikon keranjang kanan atas; **tidak** ada judul kecil Kantin Cerdas ataupun ikon Profil duplikat.
- Field pencarian ringkas **Cari makanan atau kantin...**.
- Heading **Jelajahi Kantin**, filter chip **Semua / Buka / Tutup**.
- Daftar kartu horizontal ringkas: foto opsional kiri, nama, lokasi, status Buka/Tutup; kanan affordance buka.
- Navigasi root Customer: Beranda / Cari / FAB robot / Pesanan / Profil; **FAB di tengah, sedikit terangkat, notch cekung halus, tanpa label visual**.

## Interaksi
| Elemen / tindakan | Perilaku yang diwajibkan / arah navigasi |
| --- | --- |
| Keranjang | Buka Keranjang Customer; tampilkan indikator jumlah jika ada. |
| Field pencarian | Buka Cari Global; query boleh diteruskan. |
| Filter Semua/Buka/Tutup | Ubah daftar secara lokal berdasarkan data status; Tutup tetap bisa dijelajahi. |
| Kartu Kantin | Buka UI-CUSTOMER-002 sesuai ID kantin dari data backend. |
| FAB robot | Buka UI-AI-001; `Icons.smart_toy_rounded` dan semantic label. |
| Nav bawah | Root tab yang aktif dibedakan secara halus, posisi simetris. |

## State layar
| Kondisi | Perilaku UI |
| --- | --- |
| loading | Skeleton daftar ringkas, jangan muncul 0 kantin palsu. |
| empty | Tidak ada kantin diterbitkan yang cocok; pesan sederhana. |
| offline | Kondisi data tidak tersedia, Coba Lagi; jangan palsukan buka/tutup. |
| kantin tutup | Masih ditampilkan dengan label Tutup. |
| owner nonaktif | Kantin tetap tampil jika diterbitkan; area pemesanan ditolak, info ketidaktersediaan ada pada Detail Kantin. |

## Guard dan sumber data
- Katalog hanya kantin `published`; lokasi dari profil Owner; status Buka/Tutup manual.
- Tidak ada pemilihan universitas di Beranda (CUSTOMER-001).
- Data waktu atau status tidak direkayasa dari jam operasional.

## Kriteria penerimaan (UI)
- [ ] Teks header, urutan elemen, dan empat label nav benar.
- [ ] FAB robot tidak mempunyai teks di bawahnya, terletak di notch center-docked, tidak menutupi navigasi.
- [ ] Kartu Kantin Tutup tetap bisa dibuka.
- [ ] Ukuran layar kecil, text scale, Light/Dark, SafeArea lulus.
- [ ] Keranjang dan pencarian membawa konteks akun yang sama.

## Batas / jangan ditambahkan
- Tidak ada banner AI di konten beranda, rating, diskon, kategori harga fiktif, pemilihan kampus.

## Catatan implementasi dan status keputusan
- Keputusan visual LOCKED dari diskusi 19 Nov 2026; implementasi Flutter gunakan `BottomAppBar` + `CircularNotchedRectangle` dan `centerDocked`, bukan SVG dari mockup.

**Rujukan bisnis:** CUSTOMER-001, ORDER-007, OWNER-002A, ADMIN-003B.
