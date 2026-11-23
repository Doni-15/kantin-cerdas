---
id: UI-CUSTOMER-008
module: customer
design_status: DRAFT
revision: 2026-11-19
target: Android-first
document_type: screen-ui-spec
business_rule_refs: [CUSTOMER-003, CUSTOMER-001, OWNER-005]
---

# UI-CUSTOMER-008 — Pencarian Global

> **STATUS UI: DRAFT**. Ini spesifikasi perilaku/tampilan, BUKAN kode Flutter atau kontrak endpoint. Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, `../shared/06_STATES_LOADING_ERROR.md` dan file layar ini. Semua aturan bisnis LOCKED tetap berlaku terlepas dari status desain UI.

## Tujuan dan akses
Mencari nama kantin dan nama menu di seluruh katalog kantin yang diterbitkan secara bersamaan.

**Titik masuk:** Root nav Cari; juga field pencarian pada Beranda.

## Struktur layar — urutan visual atas → bawah
- Header tunggal **Cari**.
- Satu input **Cari kantin atau makanan...** plus aksi bersihkan teks.
- Jika query ada: bagian **Kantin** dan **Menu** terpisah dalam satu scroll; tidak perlu sub-tab.
- Baris kantin horizontal ringkas: foto, nama, lokasi, Buka/Tutup.
- Baris menu ringkas: foto, nama, asal kantin, harga, Tersedia/Habis, status kantin.
- Root nav Customer konsisten.

## Interaksi
| Elemen / tindakan | Perilaku yang diwajibkan / arah navigasi |
| --- | --- |
| Query | Mencari nama kantin dan menu dengan request terkendali; abaikan respons lama saat query berubah. |
| Baris kantin | Buka UI-CUSTOMER-002. |
| Baris menu | Buka UI-CUSTOMER-003 sesuai kantin asal. |
| Clear | Kosongkan query; empty prompt. |
| FAB robot | Buka UI-AI-001. |

## State layar
| Kondisi | Perilaku UI |
| --- | --- |
| query kosong | Pesan “Mau cari apa?” dan instruksi singkat. |
| tak ada hasil | Pesan “Tidak ada hasil”, bukan error. |
| loading | Indikator ringkas. |
| offline | Error dan Coba Lagi; query tetap di input. |
| menu Habis/kantin Tutup | Tetap dapat muncul sebagai informasi dengan status benar. |

## Guard dan sumber data
- Pencarian tidak melibatkan kantin belum diterbitkan atau menu arsip.
- Harga dan status real dari backend, tidak dari jawaban AI.

## Kriteria penerimaan (UI)
- [ ] Satu input mencari dua tipe entitas.
- [ ] Menekan hasil menuju detail tepat.
- [ ] Tidak ada input kampus di UI.
- [ ] Hasil dari query lama tidak mengalahkan query baru.

## Batas / jangan ditambahkan
- Tidak ada filter budget, sort rumit, riwayat pencarian wajib, diskon/ulasan.

## Catatan implementasi dan status keputusan
- LAYOUT DRAFT.

**Rujukan bisnis:** CUSTOMER-003, CUSTOMER-001, OWNER-005.
