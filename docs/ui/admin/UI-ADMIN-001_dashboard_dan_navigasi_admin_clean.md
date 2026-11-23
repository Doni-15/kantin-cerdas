---
id: UI-ADMIN-001
module: admin
design_status: DRAFT
revision: 2026-11-19
target: Android-first
document_type: screen-ui-spec
business_rule_refs: [ADMIN-005, ADMIN-001, ADMIN-004]
---

# UI-ADMIN-001 — Dashboard dan Navigasi Admin Clean

> **STATUS UI: DRAFT**. Ini spesifikasi perilaku/tampilan, BUKAN kode Flutter atau kontrak endpoint. Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, `../shared/06_STATES_LOADING_ERROR.md` dan file layar ini. Semua aturan bisnis LOCKED tetap berlaku terlepas dari status desain UI.

## Tujuan dan akses
Workspace minimalis bagi Admin untuk melihat antrean pengajuan Owner serta ringkasan administratif wajib tanpa statistik transaksi.

**Titik masuk:** Role Admin sah aktif → root Beranda.

## Struktur layar — urutan visual atas → bawah
- Header tunggal **Beranda**; ikon akun kanan atas.
- Ringkasan empat angka/label administratif **Pengguna**, **Pengajuan Owner**, **Kantin**, **Akun Nonaktif** dalam bentuk sangat ringkas (teks inline atau grid tenang, TANPA kartu statistik besar).
- Fokus utama **Pengajuan Menunggu Review**: jumlah pending dan 1–2 baris terbaru dengan nama pemohon + nama rencana kantin.
- Link **Lihat Semua** menuju Pengajuan; empty state bila tidak ada pending.
- Bottom nav empat item sama rata **Beranda / Pengajuan / Pengguna / Kantin**; tidak ada FAB.

## Interaksi
| Elemen / tindakan | Perilaku yang diwajibkan / arah navigasi |
| --- | --- |
| Baris pengajuan | Buka UI-ADMIN-002 detail/Review. |
| Lihat Semua | Buka daftar Pengajuan. |
| Nav Pengguna | Buka UI-ADMIN-003. |
| Nav Kantin | Buka UI-ADMIN-004 read-only. |
| Ikon akun | Buka UI-ADMIN-005. |

## State layar
| Kondisi | Perilaku UI |
| --- | --- |
| tidak ada pending | Jumlah pending 0 hanya setelah fetch sah; pesan antrean kosong. |
| loading/error | Jangan menampilkan ringkasan 0 untuk fetch gagal. |
| admin nonaktif | Tolak akses protected area. |
| admin aktif terakhir | Pengaman aksi pada backend, bukan dashboard klik. |

## Guard dan sumber data
- ADMIN-005 mewajibkan keempat ringkasan administratif; desain boleh mini dan tanpa kartu.
- Tidak ada transaksi/keuangan/isi pesanan di Admin.

## Kriteria penerimaan (UI)
- [ ] Empat ringkasan ADMIN-005 tersedia dan tetap clean.
- [ ] Pengajuan terbaru dapat dibuka tanpa tombol keputusan di daftar.
- [ ] Keempat tab nav simetris.

## Batas / jangan ditambahkan
- Jangan menambah grafik, total pembayaran, income/expense, status pesanan detail, FAB.

## Catatan implementasi dan status keputusan
- LAYOUT DRAFT revisi clean. Koreksi: mockup beranda Admin sebelumnya hanya menampilkan angka Pengajuan, sedangkan bisnis mewajibkan empat ringkasan.

**Rujukan bisnis:** ADMIN-005, ADMIN-001, ADMIN-004.
