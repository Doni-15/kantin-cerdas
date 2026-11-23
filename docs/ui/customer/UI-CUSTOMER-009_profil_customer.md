---
id: UI-CUSTOMER-009
module: customer
design_status: DRAFT
revision: 2026-11-19
target: Android-first
document_type: screen-ui-spec
business_rule_refs: [CUSTOMER-006, ADMIN-001, ADMIN-002, AUTH-003]
---

# UI-CUSTOMER-009 — Profil Customer

> **STATUS UI: DRAFT**. Ini spesifikasi perilaku/tampilan, BUKAN kode Flutter atau kontrak endpoint. Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, `../shared/06_STATES_LOADING_ERROR.md` dan file layar ini. Semua aturan bisnis LOCKED tetap berlaku terlepas dari status desain UI.

## Tujuan dan akses
Menampilkan identitas akun, pintu ke Edit Profil dan Pengaturan, status Pengajuan Owner, serta logout.

**Titik masuk:** Root nav Profil Customer.

## Struktur layar — urutan visual atas → bawah
- Header tunggal **Profil**.
- Identitas akun: foto/avatar kecil, nama, email, label role sah.
- Kelompok Akun: Edit Profil; Pengaturan.
- Kelompok Pemilik Kantin: satu kartu kontekstual **Punya kantin? / Menunggu Review / Ditolak / Disetujui**, CTA sesuai status.
- Aksi **Keluar** dengan konfirmasi.
- Root nav Customer termasuk FAB robot notch tanpa label visual.

## Interaksi
| Elemen / tindakan | Perilaku yang diwajibkan / arah navigasi |
| --- | --- |
| Edit Profil | Buka UI-CUSTOMER-011 bagian Edit Profil. |
| Pengaturan | Buka UI-CUSTOMER-011 bagian Pengaturan. |
| Ajukan Jadi Pemilik Kantin | Buka UI-CUSTOMER-010 formulir. |
| Menunggu Review | Tampilkan status; tidak dapat mengajukan duplikat pending. |
| Ditolak | Tampilkan alasan Admin dan opsi Ajukan Kembali sesuai guard. |
| Disetujui | Tampilkan Masuk Area Owner, bukan mengganti role sendiri. |
| Keluar | Dialog konfirmasi; session logout sah; halaman terlindungi tidak boleh menampilkan cache sesudahnya. |

## State layar
| Kondisi | Perilaku UI |
| --- | --- |
| foto Google tidak ada | Placeholder. |
| pengajuan pending/rejected/approved | Satu keadaan valid dari backend, tidak dibuat manual. |
| loading/error | Jangan menampilkan status “belum mengajukan” sebelum fetch selesai. |

## Guard dan sumber data
- Foto Google awal jika ada; perubahan foto memerlukan konfirmasi.
- Owner tetap dapat memakai Customer, perpindahan area bukan perubahan role DB.

## Kriteria penerimaan (UI)
- [ ] Profil ringkas tanpa dashboard statistik.
- [ ] Tiga status aplikasi Owner tepat; alasan penolakan terlihat.
- [ ] Logout konfirmasi tidak mengubah data order.

## Batas / jangan ditambahkan
- Tidak ada ganti role manual, statistik total belanja, edit role Admin/Owner.

## Catatan implementasi dan status keputusan
- LAYOUT DRAFT.

**Rujukan bisnis:** CUSTOMER-006, ADMIN-001, ADMIN-002, AUTH-003.
