---
id: UI-OWNER-006
module: owner
design_status: DRAFT
revision: 2026-11-19
target: Android-first
document_type: screen-ui-spec
business_rule_refs: [ORDER-001, ORDER-003, ORDER-004, ORDER-011, ORDER-012, ORDER-013, ORDER-013A, ORDER-013B, ORDER-014, ORDER-015]
---

# UI-OWNER-006 — Detail Pesanan dan Tindakan Owner

> **STATUS UI: DRAFT**. Ini spesifikasi perilaku/tampilan, BUKAN kode Flutter atau kontrak endpoint. Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, `../shared/06_STATES_LOADING_ERROR.md` dan file layar ini. Semua aturan bisnis LOCKED tetap berlaku terlepas dari status desain UI.

## Tujuan dan akses
Owner membaca snapshot order dan memilih tindakan tunggal yang sah pada state saat ini, dengan konfirmasi dan reason bila diperlukan.

**Titik masuk:** Baris Pesanan Owner atau hasil pencarian/scan.

## Struktur layar — urutan visual atas → bawah
- AppBar Kembali + **Detail Pesanan**.
- Nomor, status, nama Customer yang berhak ditampilkan, timestamp asli server.
- Rincian snapshot item, catatan item/umum, harga & total yang dibekukan.
- Pembayaran: tunai; status Belum Lunas/Lunas.
- Jika Siap Diambil, petunjuk cocokkan barcode/nomor; scanner hanya identifikasi.
- Satu CTA utama per status di bottom safe area dan satu aksi alternatif yang relevan; dialog/sheet konfirmasi saat ditekan.
- Jika status akhir, hanya lihat detail+alasan, tidak ada tombol perubahan status.

## Interaksi
| Elemen / tindakan | Perilaku yang diwajibkan / arah navigasi |
| --- | --- |
| Menunggu → Terima | Konfirmasi; backend ubah ke Diproses. |
| Menunggu → Tolak | Alasan WAJIB, status Ditolak. |
| Diproses → Siap Diambil | Konfirmasi manual; barcode Customer mulai tersedia. |
| Diproses → Gagal Dipenuhi | Alasan WAJIB; terminal, Belum Lunas. |
| Siap Diambil → Selesai | Konfirmasi DUA fakta: uang tunai diterima dan makanan diserahkan; ubah status dan Lunas atomik. |
| Siap Diambil → Tidak Diambil | Konfirmasi manual; hanya ketika Customer tidak mengambil; terminal dan Belum Lunas. |
| Siap Diambil → Gagal Diambil | **Aksi tambahan wajib dari amendemen**: kantin gagal menyerahkan, alasan WAJIB; terminal, Belum Lunas, barcode Customer disembunyikan. |
| Barcode/nomor | Cari dan cocokkan order, tidak auto complete. |

## State layar
| Kondisi | Perilaku UI |
| --- | --- |
| status berubah di perangkat lain | Server reject stale transition, refresh status asli. |
| owner nonaktif | Guard backend membatasi aksi, tidak percaya tombol UI. |
| reason kosong | Konfirmasi disabled. |
| in-flight | Tombol nonaktif, tidak double submit. |
| uncertain | Periksa hasil sebelum retry, tidak membuat transisi ganda. |
| terminal | Snapshot read-only, tampilkan alasan yang ada. |

## Guard dan sumber data
- Gagal Dipenuhi HANYA dari Diproses; Gagal Diambil HANYA dari Siap Diambil.
- Tidak Diambil bukan pengganti Gagal Diambil; tidak ada batas tunggu otomatis.
- Pembayaran Lunas bukan hasil pemindaian barcode.

## Kriteria penerimaan (UI)
- [ ] Ada aksi Gagal Diambil dengan alasan, Belum Lunas dan riwayat.
- [ ] Tolak/Gagal Dipenuhi/Gagal Diambil reason wajib.
- [ ] Tidak boleh Selesai tanpa dua konfirmasi fisik.
- [ ] Terminal read-only; tidak muncul aksi di daftar utama.

## Batas / jangan ditambahkan
- Tidak ada penerimaan otomatis, “Selesai” saat scan, edit pesanan yang sudah dibuat.

## Catatan implementasi dan status keputusan
- LAYOUT DRAFT; Gagal Diambil melengkapi mockup lama yang belum memasukkannya.

**Rujukan bisnis:** ORDER-001, ORDER-003, ORDER-004, ORDER-011, ORDER-012, ORDER-013, ORDER-013A, ORDER-013B, ORDER-014, ORDER-015.
