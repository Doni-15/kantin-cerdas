---
id: UI-ADMIN-002
module: admin
design_status: DRAFT
revision: 2026-11-19
target: Android-first
document_type: screen-ui-spec
business_rule_refs: [ADMIN-001, ADMIN-002, CUSTOMER-006A, OWNER-002]
---

# UI-ADMIN-002 — Daftar dan Review Pengajuan Owner

> **STATUS UI: DRAFT**. Ini spesifikasi perilaku/tampilan, BUKAN kode Flutter atau kontrak endpoint. Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, `../shared/06_STATES_LOADING_ERROR.md` dan file layar ini. Semua aturan bisnis LOCKED tetap berlaku terlepas dari status desain UI.

## Tujuan dan akses
Admin meninjau permohonan Owner tanpa melihat isi pesanan; keputusan Disetujui/Ditolak sah dengan alasan wajib saat tolak.

**Titik masuk:** Root nav Pengajuan atau daftar Pengajuan Terbaru Dashboard.

## Struktur layar — urutan visual atas → bawah
- Daftar Pengajuan: Header tunggal **Pengajuan**, tab **Menunggu / Riwayat**, baris pemohon + nama rencana kantin, divider halus; tanpa tombol Setujui/Tolak di baris.
- Detail Pengajuan (subhalaman): AppBar Kembali; status; identitas pemohon; nama rencana kantin; lokasi rencana; alasan singkat.
- Satu baris **Indikator Pesanan Aktif: Ada / Tidak Ada**, **read-only dari backend**; tidak menggunakan segmented toggle admin.
- Tindakan pada pending: CTA Setujui Pengajuan, aksi sekunder Tolak Pengajuan.
- Sheet Setujui untuk konfirmasi; sheet Tolak berisi field **Alasan Penolakan*** dan konfirmasi.
- Riwayat keputusan tetap dapat dilihat read-only, alasan penolakan tercatat.

## Interaksi
| Elemen / tindakan | Perilaku yang diwajibkan / arah navigasi |
| --- | --- |
| Tab Menunggu | Filter pending resmi; satu pending per Customer. |
| Tab Riwayat | Disetujui dan Ditolak; riwayat keputusan. |
| Setujui | Memeriksa status, hak admin, indikator pesanan aktif secara atomik di backend. Bila ada pesanan aktif yang menghalangi, tidak disetujui; admin harus menolak dengan alasan. |
| Tolak | Alasan wajib; simpan keputusan dan alasan; boleh reapply sebagai pengajuan baru. |
| Buka detail | Tidak memuat pesanan individual. |
| Status berubah | Refresh bila pengajuan telah diputuskan admin lain. |

## State layar
| Kondisi | Perilaku UI |
| --- | --- |
| pengajuan pending | Tindakan tersedia sesuai guard. |
| pesanan aktif ada | Setujui diblokir; tampilkan alasan bahwa review harus ditolak sesuai aturan; tombol Tolak dapat dipakai. |
| pesanan aktif tidak ada | Setujui masih wajib diverifikasi transaksi backend. |
| riwayat | Tindakan nonaktif, alasan dapat dibaca. |
| loading/offline | Jangan menganggap penolakan/persetujuan selesai sebelum hasil backend. |
| reason kosong | Tombol Konfirmasi Tolak disabled. |

## Guard dan sumber data
- Indikator pesanan aktif hanya boolean/agregat, bukan detail transaksi.
- Persetujuan hanya memberi akses Owner, tidak membuat kantin atau publikasi.
- Keputusan race dengan checkout/deaktivasi dicegah oleh backend.

## Kriteria penerimaan (UI)
- [ ] Admin tidak dapat mengubah indikator pesanan aktif.
- [ ] Penolakan wajib alasan; riwayat memuat alasan.
- [ ] Tidak ada status Menunda/Perlu Revisi baru.

## Batas / jangan ditambahkan
- Tidak ada operasi order atau akses detail pesanan.

## Catatan implementasi dan status keputusan
- LAYOUT DRAFT.

**Rujukan bisnis:** ADMIN-001, ADMIN-002, CUSTOMER-006A, OWNER-002.
