---
id: UI-OWNER-007
module: owner
design_status: DRAFT
revision: 2026-11-19
target: Android-first
document_type: screen-ui-spec
business_rule_refs: [ORDER-015, BARCODE-TECH-001]
---

# UI-OWNER-007 — Cari dan Pindai Pesanan

> **STATUS UI: DRAFT**. Ini spesifikasi perilaku/tampilan, BUKAN kode Flutter atau kontrak endpoint. Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, `../shared/06_STATES_LOADING_ERROR.md` dan file layar ini. Semua aturan bisnis LOCKED tetap berlaku terlepas dari status desain UI.

## Tujuan dan akses
Owner menemukan order di kantinnya melalui nomor order manual atau scanner Code 128 tanpa perubahan status.

**Titik masuk:** Daftar Pesanan Owner: field cari atau ikon scan kecil di kanan input.

## Struktur layar — urutan visual atas → bawah
- AppBar **Cari Pesanan** atau **Pindai Pesanan**; Kembali.
- Field nomor pesanan dengan contoh nonotoritatif; tombol Cari; ikon Scan untuk buka scanner kamera.
- Scanner memakai viewfinder sederhana dan instruksi arahkan kamera ke Code128.
- Hasil sah menampilkan ringkasan pendek + tombol Lihat Detail Pesanan.
- Tautan selalu tersedia **Masukkan Nomor Manual** jika scanner tidak berjalan.

## Interaksi
| Elemen / tindakan | Perilaku yang diwajibkan / arah navigasi |
| --- | --- |
| Cari nomor | Backend lookup order hanya milik kantin Owner sah; bukan wildcard data global. |
| Scan berhasil | Decode Code128 sebagai nomor/ID, validasi server, buka hasil pencarian. |
| Lihat Detail | Buka UI-OWNER-006; tidak mengubah order. |
| Camera denied/unavailable | Berikan input nomor manual. |
| Scan ulang | Reset result, tetap di scanner tanpa aksi status. |

## State layar
| Kondisi | Perilaku UI |
| --- | --- |
| tidak ditemukan | Pesan netral, tidak membocorkan kepemilikan order lain. |
| barcode invalid | Tampilkan pesan ringkas dan scan ulang. |
| camera permission denied | Fallback input manual. |
| offline | Input tetap ada dan bisa retry. |
| order status terminal | Masih boleh dibaca jika dimiliki Owner; aksi perubahan tidak muncul. |

## Guard dan sumber data
- Scanner harus membaca Code 128; nomor dengan leading zero tidak boleh diubah ke integer.
- Hasil tidak boleh mengungkap detail milik kantin lain.

## Kriteria penerimaan (UI)
- [ ] Scan tidak auto complete.
- [ ] Kamera gagal punya jalur manual.
- [ ] Invalid/foreign order tidak membocorkan data sensitif.

## Batas / jangan ditambahkan
- Tidak ada tab Scanner pada bottom navigation Owner.

## Catatan implementasi dan status keputusan
- LAYOUT DRAFT. Perangkat scanner nyata perlu uji P1.

**Rujukan bisnis:** ORDER-015, BARCODE-TECH-001.
