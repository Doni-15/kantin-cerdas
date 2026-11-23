---
id: UI-ADMIN-005
module: admin
design_status: DRAFT
revision: 2026-11-19
target: Android-first
document_type: screen-ui-spec
business_rule_refs: [ADMIN-005, AUTH-003, AUTH-004, AUTH-005]
---

# UI-ADMIN-005 — Akun Admin dan Pengaturan

> **STATUS UI: DRAFT**. Ini spesifikasi perilaku/tampilan, BUKAN kode Flutter atau kontrak endpoint. Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, `../shared/06_STATES_LOADING_ERROR.md` dan file layar ini. Semua aturan bisnis LOCKED tetap berlaku terlepas dari status desain UI.

## Tujuan dan akses
Identitas admin, tema aplikasi, keamanan login yang sah, Tentang, dan logout dengan konfirmasi.

**Titik masuk:** Ikon akun di kanan header Dashboard Admin.

## Struktur layar — urutan visual atas → bawah
- Akun Admin: AppBar kembali, avatar kecil, nama/email/label Admin; baris **Pengaturan / Tentang Aplikasi / Keluar** dengan divider minimalis.
- Pengaturan: pilihan tema **Ikuti sistem / Mode Terang / Mode Gelap**; pengelolaan password mengikuti metode login aktual.
- Logout confirmation sheet, bukan tombol logout langsung tanpa peringatan.

## Interaksi
| Elemen / tindakan | Perilaku yang diwajibkan / arah navigasi |
| --- | --- |
| Pengaturan | Buka halaman pengaturan, tidak perlu root nav. |
| Tema | Preferensi local/system, bukan kebijakan role. |
| Atur Ulang Password | Jika akun email/password, gunakan alur Auth reset aman; akun Google-only dikelola Google. |
| Logout | Konfirmasi; akhiri sesi perangkat saat ini dan hentikan akses data terlindungi sesuai backend. |
| Tentang | Tampilkan versi aplikasi dari metadata build, bukan angka contoh. |

## State layar
| Kondisi | Perilaku UI |
| --- | --- |
| method Google-only | Tidak buat password lokal; tampilkan informasi. |
| logout gagal/uncertain | Pastikan token/session & akses benar-benar tak dipakai sebelum membuka halaman terproteksi. |
| avatar missing | Fallback. |
| tema sistem | Mengikuti brightness perangkat. |

## Guard dan sumber data
- Metode login ditentukan Auth, **bukan** segmented selector yang dapat diubah Admin di aplikasi nyata.
- Akun Admin tidak dibuat melalui pendaftaran publik.

## Kriteria penerimaan (UI)
- [ ] Tidak ada tombol ubah role Admin.
- [ ] Pengaturan tema konsisten lintas semua area.
- [ ] Logout memerlukan konfirmasi.

## Batas / jangan ditambahkan
- Tidak ada dashboard security analytics atau izin admin granular baru.

## Catatan implementasi dan status keputusan
- LAYOUT DRAFT. Jika edit nama/foto Admin diperlukan, reuse Auth profile menurut izin; jangan mengarang aksi baru.

**Rujukan bisnis:** ADMIN-005, AUTH-003, AUTH-004, AUTH-005.
