---
id: UI-CUSTOMER-011
module: customer
design_status: DRAFT
revision: 2026-11-19
target: Android-first
document_type: screen-ui-spec
business_rule_refs: [AUTH-005, AUTH-005A, AUTH-004, CUSTOMER-006]
---

# UI-CUSTOMER-011 — Edit Profil dan Pengaturan Akun

> **STATUS UI: DRAFT**. Ini spesifikasi perilaku/tampilan, BUKAN kode Flutter atau kontrak endpoint. Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, `../shared/06_STATES_LOADING_ERROR.md` dan file layar ini. Semua aturan bisnis LOCKED tetap berlaku terlepas dari status desain UI.

## Tujuan dan akses
Dua subhalaman sederhana yang dapat dipisah route oleh implementasi, bukan satu form padat: Edit Profil dan Pengaturan.

**Titik masuk:** Profil Customer → Edit Profil atau Pengaturan.

## Struktur layar — urutan visual atas → bawah
- Edit Profil: AppBar Kembali; foto profil bulat + **Ubah Foto**; input **Nama lengkap**; Email read-only sebagai identitas di layar ini; CTA Simpan Perubahan.
- Pengaturan: AppBar Kembali; tema **Ikuti sistem / Mode Terang / Mode Gelap**; keamanan akun sesuai metode login; informasi notifikasi/versi sederhana.
- Jika pengguna Google-only, beri penjelasan pengelolaan password melalui Google; jika email/password, akses tautan reset aman.

## Interaksi
| Elemen / tindakan | Perilaku yang diwajibkan / arah navigasi |
| --- | --- |
| Ubah Foto | Pilih foto, preview, lalu konfirmasi sebelum simpan; Batal mempertahankan foto lama. |
| Nama | Validasi dan simpan lewat backend; hasil hanya sukses setelah server. |
| Tema | Perubahan preferensi aplikasi local; Sistem mengikuti device. |
| Atur Ulang Password | Alur AUTH-004 untuk email/password. |
| Email | Read-only di Edit Profil; perubahan email login melalui alur Auth aman **terpisah** jika disediakan kontrak. |
| Kembali | Kembali Profil tanpa kehilangan data yang sudah disimpan. |

## State layar
| Kondisi | Perilaku UI |
| --- | --- |
| foto upload gagal | Pertahankan foto lama. |
| Google photo unavailable | Avatar placeholder. |
| form tak berubah | Simpan disabled. |
| offline | Simpan gagal menjaga input. |
| method Google-only | Tidak membuat password lokal secara otomatis. |

## Guard dan sumber data
- AUTH-005 baseline mengizinkan perubahan email/password melalui verifikasi aman; jangan menganggap read-only field berarti fitur itu dilarang.
- Status identity linking Supabase AUTH-005/AUTH-005A masih usulan amendemen, bukan diputuskan UI ini.

## Kriteria penerimaan (UI)
- [ ] Foto baru meminta konfirmasi.
- [ ] Nama dapat diubah dan form tidak menghapus perubahan saat gagal.
- [ ] Tema sistem/terang/gelap konsisten global.
- [ ] Metode login tidak dapat diubah melalui segmented simulasi.

## Batas / jangan ditambahkan
- Tidak ada nomor telepon/NIM/fakultas, pengaturan multi-role, fitur reset password Admin.

## Catatan implementasi dan status keputusan
- LAYOUT DRAFT. Jika perubahan email dibutuhkan pengguna, rancang alur aman berdasar bisnis Auth sebelum implementasi.

**Rujukan bisnis:** AUTH-005, AUTH-005A, AUTH-004, CUSTOMER-006.
