---
id: UI-OWNER-001
module: owner
design_status: DRAFT
revision: 2026-11-19
target: Android-first
document_type: screen-ui-spec
business_rule_refs: [OWNER-002, OWNER-002B, OWNER-006, ORDER-007, ORDER-012]
---

# UI-OWNER-001 — Beranda dan Navigasi Owner

> **STATUS UI: DRAFT**. Ini spesifikasi perilaku/tampilan, BUKAN kode Flutter atau kontrak endpoint. Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, `../shared/06_STATES_LOADING_ERROR.md` dan file layar ini. Semua aturan bisnis LOCKED tetap berlaku terlepas dari status desain UI.

## Tujuan dan akses
Dashboard operasional bersih bagi Owner, fokus pada status kantin dan pesanan yang perlu ditangani.

**Titik masuk:** Area Owner dengan role sah dari backend; root nav Beranda.

## Struktur layar — urutan visual atas → bawah
- Header satu judul **Beranda**, ikon akun kanan atas.
- Owner baru: satu empty state **Siapkan kantinmu**, CTA Mulai Buat Kantin.
- Kantin belum diterbitkan: info draft + CTA Lanjutkan Pengaturan, tanpa statistik palsu.
- Kantin terbit: satu permukaan nama/lokasi, status Diterbitkan, status Buka/Tutup, tombol manual Buka atau Tutup.
- Angka pesanan aktif per status dalam satu deret angka ringkas tanpa tiga kartu dekoratif.
- Bagian **Perlu Ditangani** maksimal beberapa baris prioritas; link Lihat Semua menuju daftar Pesanan.
- Root nav Owner sejajar **Beranda / Pesanan / Menu / Kantin**, **tanpa notch dan chatbot**.

## Interaksi
| Elemen / tindakan | Perilaku yang diwajibkan / arah navigasi |
| --- | --- |
| Buka/Tutup | Konfirmasi lalu mutasi status dari backend; tidak mengubah publikasi atau order aktif. |
| Ringkasan status | Ketuk angka menuju Pesanan terfilter sesuai status. |
| Baris Perlu Ditangani | Buka UI-OWNER-006. |
| Mulai Buat/Lanjutkan Pengaturan | Buka UI-OWNER-002. |
| Akun kanan atas | Buka UI-OWNER-008. |

## State layar
| Kondisi | Perilaku UI |
| --- | --- |
| Owner baru | Tidak ada kantin/angka pesanan palsu. |
| draft belum published | Pengaturan untuk menyiapkan menu tersedia sebelum terbit. |
| published Tutup | Pesanan aktif tetap dapat ditangani. |
| published Buka | Boleh menerima order baru jika Owner aktif dan menu eligible. |
| loading/error | Jangan mengganti angka menjadi nol saat fetch gagal. |
| Owner nonaktif | Akses mutasi ditolak backend, tampilkan state akses. |

## Guard dan sumber data
- Owner hanya satu kantin sah.
- Dashboard hitung aktif dari Menunggu Konfirmasi/Diproses/Siap Diambil; Gagal Diambil status terminal.
- Waktu estimasi dari OWNER-003 ditampilkan pada detail order bila ada, bukan countdown otomatis.

## Kriteria penerimaan (UI)
- [ ] Tidak lebih dari satu kartu identitas utama, daftar rapi, empat tab rata.
- [ ] Tutup tidak menghapus/menyembunyikan pesanan berjalan.
- [ ] Aksi Buka/Tutup gagal tidak membuat UI menganggap berhasil.

## Batas / jangan ditambahkan
- Tidak ada dashboard pendapatan, grafik penjualan, jumlah profit, FAB robot.

## Catatan implementasi dan status keputusan
- LAYOUT DRAFT revisi minimalis.

**Rujukan bisnis:** OWNER-002, OWNER-002B, OWNER-006, ORDER-007, ORDER-012.
