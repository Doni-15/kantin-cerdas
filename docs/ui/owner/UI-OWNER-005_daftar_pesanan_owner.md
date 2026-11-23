---
id: UI-OWNER-005
module: owner
design_status: DRAFT
revision: 2026-11-19
target: Android-first
document_type: screen-ui-spec
business_rule_refs: [OWNER-006, ORDER-017, ORDER-013B, ORDER-015]
---

# UI-OWNER-005 — Daftar Pesanan Owner

> **STATUS UI: DRAFT**. Ini spesifikasi perilaku/tampilan, BUKAN kode Flutter atau kontrak endpoint. Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, `../shared/06_STATES_LOADING_ERROR.md` dan file layar ini. Semua aturan bisnis LOCKED tetap berlaku terlepas dari status desain UI.

## Tujuan dan akses
Daftar operasional dengan status terbaca tetapi tanpa tombol aksi berdesakan pada setiap pesanan.

**Titik masuk:** Root nav Pesanan Owner atau kartu pesanan Dashboard.

## Struktur layar — urutan visual atas → bawah
- Header **Pesanan**.
- Dua tab **Aktif / Riwayat**.
- Filter ringkas status hanya pada tab Aktif bila diperlukan, tidak membuat 3-4 chip dekoratif.
- Satu container daftar baris + divider: nama Customer, nomor pesanan, waktu backend, ringkasan item/total, status teks + titik kecil, chevron.
- Akses Cari nomor atau ikon scan di area pencarian; tidak membuat tab Scanner tersendiri.
- Root nav Owner datar empat tujuan.

## Interaksi
| Elemen / tindakan | Perilaku yang diwajibkan / arah navigasi |
| --- | --- |
| Baris Pesanan | Buka UI-OWNER-006. |
| Tab Aktif | Menunggu Konfirmasi, Diproses, Siap Diambil. |
| Tab Riwayat | Seluruh 6 terminal, termasuk Gagal Diambil. |
| Filter status | Jika digunakan, tidak mengubah dataset sumber. |
| Cari/Scan | Buka UI-OWNER-007 atau lookup inline; scanner Code128 hanya mencari. |
| Refresh | Sinkronisasi backend, konflik transisi diselesaikan di server. |

## State layar
| Kondisi | Perilaku UI |
| --- | --- |
| empty | Teks khusus tidak ada pesanan; bukan error. |
| Tutup kantin | Order aktif lama tetap bisa diurus. |
| Gagal Diambil | Masuk Riwayat; tidak hilang dari daftar terminal. |
| stale/offline | Tampilkan warning, jangan hasil kosong palsu. |
| izin dicabut | Operasional tidak dapat dilakukan, server guard. |

## Guard dan sumber data
- Prioritaskan Menunggu Konfirmasi; urutan waktu dari server.
- Owner hanya melihat order kantinnya sendiri; Admin tidak punya akses detail operasional.

## Kriteria penerimaan (UI)
- [ ] Semua aktif dan terminal tercakup.
- [ ] Scanner tidak menyelesaikan order.
- [ ] Kartu/baris tidak memiliki action multiple, hanya navigasi ke Detail.
- [ ] Layout tetap clean dan mobile-first.

## Batas / jangan ditambahkan
- Tidak ada grafik pendapatan/pembayaran digital.

## Catatan implementasi dan status keputusan
- LAYOUT DRAFT.

**Rujukan bisnis:** OWNER-006, ORDER-017, ORDER-013B, ORDER-015.
