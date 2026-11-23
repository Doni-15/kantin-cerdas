---
id: UI-CUSTOMER-007
module: customer
design_status: DRAFT
revision: 2026-11-19
target: Android-first
document_type: screen-ui-spec
business_rule_refs: [CUSTOMER-006, ORDER-017, ORDER-013B]
---

# UI-CUSTOMER-007 — Pesanan Aktif dan Riwayat

> **STATUS UI: DRAFT**. Ini spesifikasi perilaku/tampilan, BUKAN kode Flutter atau kontrak endpoint. Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, `../shared/06_STATES_LOADING_ERROR.md` dan file layar ini. Semua aturan bisnis LOCKED tetap berlaku terlepas dari status desain UI.

## Tujuan dan akses
Dua tab sederhana untuk menemukan order berjalan dan semua order terminal.

**Titik masuk:** Root nav Pesanan Customer.

## Struktur layar — urutan visual atas → bawah
- Header **Pesanan** dan teks pendukung singkat.
- Tab **Aktif / Riwayat** dengan underline tipis.
- Daftar order ringkas: nama kantin, nomor, status, ringkasan jenis menu dan total; ketuk baris ke detail.
- Root bottom nav Customer dengan FAB robot tetap tersusun simetris.

## Interaksi
| Elemen / tindakan | Perilaku yang diwajibkan / arah navigasi |
| --- | --- |
| Tab Aktif | Hanya Menunggu Konfirmasi, Diproses, Siap Diambil. |
| Tab Riwayat | Selesai, Dibatalkan, Ditolak, Gagal Dipenuhi, Tidak Diambil, **Gagal Diambil**. |
| Kartu pesanan | Buka UI-CUSTOMER-006 dengan nomor/ID aktual. |
| Empty Aktif | Ajakan Jelajahi Kantin. |
| Refresh | Dari backend saat user membuka atau kembali online; realtime hanya sinyal. |

## State layar
| Kondisi | Perilaku UI |
| --- | --- |
| kosong | Empty state berbeda per tab. |
| loading | Tidak tampil angka 0 palsu. |
| status berubah | Pindahkan ke tab tepat berdasarkan backend, tidak duplikasi. |
| offline | Tampilkan data terakhir dengan pesan stale/refresh bila sesuai keamanan. |
| Gagal Diambil | Tampil di Riwayat dengan label status asli. |

## Guard dan sumber data
- Sort didasarkan pada waktu backend; urutan waktu di sketsa tidak dianggap data.
- Filter status tidak mengubah hak akses pengguna.

## Kriteria penerimaan (UI)
- [ ] Tiga status aktif dan enam status terminal terwakili.
- [ ] Tidak ada barcode dalam kartu daftar.
- [ ] Semua baris membuka detail, termasuk pesanan gagal.
- [ ] Bottom nav hanya sekali di shell.

## Batas / jangan ditambahkan
- Tidak ada tombol Pesan Lagi, dashboard belanja, rating.

## Catatan implementasi dan status keputusan
- LAYOUT DRAFT.

**Rujukan bisnis:** CUSTOMER-006, ORDER-017, ORDER-013B.
