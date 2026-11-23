---
id: UI-OWNER-008
module: owner
design_status: DRAFT
revision: 2026-11-19
target: Android-first
document_type: screen-ui-spec
business_rule_refs: [AUTH-003, AUTH-005, CUSTOMER-006, OWNER-002]
---

# UI-OWNER-008 — Akun Owner dan Beralih ke Customer

> **STATUS UI: DRAFT**. Ini spesifikasi perilaku/tampilan, BUKAN kode Flutter atau kontrak endpoint. Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, `../shared/06_STATES_LOADING_ERROR.md` dan file layar ini. Semua aturan bisnis LOCKED tetap berlaku terlepas dari status desain UI.

## Tujuan dan akses
Identitas Owner yang sama dengan akun Customer, pengaturan bersama, dan perpindahan area tanpa logout.

**Titik masuk:** Ikon akun pada Dashboard Owner.

## Struktur layar — urutan visual atas → bawah
- AppBar **Akun Owner** + tombol kembali.
- Avatar/foto kecil, nama, email, label Pemilik Kantin.
- Daftar minimalis: Informasi Akun, Pengaturan.
- CTA **Beralih ke Customer**; akses Keluar melalui alur bersama jika diperlukan.
- Di Customer yang sah, tombol **Masuk Area Owner** dapat mengembalikan ke shell Owner.

## Interaksi
| Elemen / tindakan | Perilaku yang diwajibkan / arah navigasi |
| --- | --- |
| Beralih Customer | Ganti shell UI ke Customer, satu sesi dan satu ID akun; tidak mengubah role database. |
| Beralih Owner | Backend cek role Owner dan status aktif sebelum membuka shell. |
| Informasi/Pengaturan | Gunakan komponen profil Auth/Customer bersama sesuai izin. |
| Keluar | Logout satu sesi perangkat dengan konfirmasi. |

## State layar
| Kondisi | Perilaku UI |
| --- | --- |
| role tidak sah lagi | Blok masuk Owner, tampilkan pesan izin. |
| offline | Jangan klaim role berubah; batasi tindakan sensitif. |
| foto absen | Avatar fallback. |

## Guard dan sumber data
- Owner dapat menjadi Customer biasa untuk memesan; peran bukan akun login terpisah.
- Admin role berbeda; jangan menawarkan switch Admin tanpa otorisasi.

## Kriteria penerimaan (UI)
- [ ] Switch antar shell tidak membuat dua akun.
- [ ] Kedua shell tetap memeriksa akses sah dari backend.

## Batas / jangan ditambahkan
- Tidak ada logout paksa saat berpindah area.

## Catatan implementasi dan status keputusan
- LAYOUT DRAFT.

**Rujukan bisnis:** AUTH-003, AUTH-005, CUSTOMER-006, OWNER-002.
