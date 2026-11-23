---
id: UI-CUSTOMER-010
module: customer
design_status: DRAFT
revision: 2026-11-19
target: Android-first
document_type: screen-ui-spec
business_rule_refs: [ADMIN-001, ADMIN-002, CUSTOMER-006A, OWNER-002]
---

# UI-CUSTOMER-010 — Pengajuan Pemilik Kantin

> **STATUS UI: DRAFT**. Ini spesifikasi perilaku/tampilan, BUKAN kode Flutter atau kontrak endpoint. Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, `../shared/06_STATES_LOADING_ERROR.md` dan file layar ini. Semua aturan bisnis LOCKED tetap berlaku terlepas dari status desain UI.

## Tujuan dan akses
Pengajuan role Owner melalui formulir sederhana; pengajuan bukan pembuatan kantin.

**Titik masuk:** Profil Customer → Ajukan Jadi Pemilik Kantin; juga tautan status pengajuan.

## Struktur layar — urutan visual atas → bawah
- AppBar Kembali + **Pengajuan Pemilik Kantin**.
- Judul dan penjelasan satu paragraf.
- Identitas pemohon nama/email read-only dari Auth.
- Tiga field wajib: **Nama rencana kantin**, **Rencana lokasi usaha**, **Alasan singkat pengajuan**.
- Pesan bahwa pengajuan diperiksa Admin dan tidak membuat kantin/role otomatis.
- CTA **Kirim Pengajuan**.
- Tampilan status terpisah sesuai `Menunggu Review / Disetujui / Ditolak` dengan alasan pada penolakan.

## Interaksi
| Elemen / tindakan | Perilaku yang diwajibkan / arah navigasi |
| --- | --- |
| Kirim | Validasi ketiga field, cegah duplicate pending, simpan lewat backend. |
| Status Menunggu | Tidak ada pengajuan kedua; masih dapat akses Customer. |
| Status Ditolak | Tampilkan alasan penolakan, opsi Ajukan Kembali sesuai aturan. |
| Status Disetujui | Tombol Masuk Area Owner; Owner membuat kantin sendiri sesudah disetujui. |
| Ajukan Kembali | Buat pengajuan baru, jangan edit keputusan/riwayat lama. |

## State layar
| Kondisi | Perilaku UI |
| --- | --- |
| form belum lengkap | Inline errors + CTA disabled/loading. |
| pending | Tampilkan Menunggu Review, tidak membuat status lain. |
| rejected + active orders | Tampilkan alasan penolakan; jika memerlukan guard pengajuan ulang, konfirmasi aturan bisnis+backend dahulu; indikator bukan checkbox bisa diubah Customer. |
| offline/uncertain | Jangan membuat duplikasi pengajuan pada retry; cek hasil backend. |
| approved | Area Owner tersedia hanya jika backend memberikan role. |

## Guard dan sumber data
- Admin memeriksa indikator pesanan aktif dan bila menghalangi persetujuan harus menolak dengan alasan, bukan menunda otomatis.
- Tidak perlu foto KTP, usaha atau dokumen lain saat pengajuan.

## Kriteria penerimaan (UI)
- [ ] Hanya 3 field wajib plus identitas read-only.
- [ ] Tiga status resmi dan alasan penolakan ada.
- [ ] Persetujuan tidak membuat kantin otomatis.

## Batas / jangan ditambahkan
- Tidak ada status Perlu Revisi, Sedang Diverifikasi, Dokumen Wajib.

## Catatan implementasi dan status keputusan
- LAYOUT DRAFT.

**Rujukan bisnis:** ADMIN-001, ADMIN-002, CUSTOMER-006A, OWNER-002.
