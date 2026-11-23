---
id: UI-ADMIN-003
module: admin
design_status: DRAFT
revision: 2026-11-19
target: Android-first
document_type: screen-ui-spec
business_rule_refs: [ADMIN-003, ADMIN-003A, ADMIN-003B, ADMIN-005, AUTH-003]
---

# UI-ADMIN-003 — Pengelolaan Pengguna dan Aktivasi Kembali

> **STATUS UI: DRAFT**. Ini spesifikasi perilaku/tampilan, BUKAN kode Flutter atau kontrak endpoint. Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, `../shared/06_STATES_LOADING_ERROR.md` dan file layar ini. Semua aturan bisnis LOCKED tetap berlaku terlepas dari status desain UI.

## Tujuan dan akses
Menampilkan akun dan menjalankan penonaktifan atau aktivasi kembali yang terotorisasi, dengan audit.

**Titik masuk:** Root nav Pengguna.

## Struktur layar — urutan visual atas → bawah
- Header tunggal **Pengguna**, field cari nama/email.
- Daftar ringkas: nama, email, role, Aktif/Nonaktif; baris divider, bukan kartu per pengguna.
- Detail Pengguna: identitas, role sah, status akun, indikator pesanan aktif ada/tidak (read-only).
- Jika aktif: tombol **Nonaktifkan Akun**, membuka sheet alasan wajib + konfirmasi.
- Jika nonaktif: tombol **Aktifkan Kembali**, membuka sheet konfirmasi; jangan sembunyikan hak reaktivasi yang sudah LOCKED pada ADMIN-003.
- Informasi tindakan terakhir/riwayat administrasi sederhana jika API menyediakan data audit; jangan menampilkan token atau password.

## Interaksi
| Elemen / tindakan | Perilaku yang diwajibkan / arah navigasi |
| --- | --- |
| Cari | Filter pengguna menurut data backend. |
| Buka detail | Baca profil dasar+status+indikator pesanan aktif tanpa isi order. |
| Nonaktifkan | Alasan WAJIB; blok jika punya pesanan aktif; backend cek ulang serta catat aktor/waktu/alasan. |
| Aktifkan Kembali | Aksi dari status Nonaktif melalui backend, disertai konfirmasi dan audit. |
| Admin terakhir | Backend melindungi Admin aktif terakhir bila tindakan dapat menghabiskan akses administratif. |
| Konfirmasi | Batal tidak mengubah status. |

## State layar
| Kondisi | Perilaku UI |
| --- | --- |
| akun aktif + pesanan aktif | Tidak dapat dinonaktifkan; indikator hanya baca. |
| akun aktif + tanpa pesanan aktif | Nonaktif boleh setelah server sah; sheet alasan wajib. |
| akun nonaktif | Aktifkan Kembali muncul; bukan tombol Nonaktifkan lagi. |
| dua admin bersamaan | Salah satu mutasi ditolak sesuai keadaan terbaru; refresh status. |
| server error | Jangan optimistically mark aktif/nonaktif. |
| admin tidak aktif | Tindakan dilarang. |

## Guard dan sumber data
- ADMIN-003: aktif/nonaktif, alasan wajib untuk nonaktif, setiap tindakan dicatat.
- ADMIN-003A: larangan nonaktif jika ada order aktif terkait.
- ADMIN-003B: Owner nonaktif tidak menerima order baru, tetapi publication/open flags tidak diubah.

## Kriteria penerimaan (UI)
- [ ] Alasan nonaktif wajib dan divalidasi.
- [ ] Aktifkan Kembali tersedia untuk akun Nonaktif.
- [ ] Admin tidak melihat rincian pesanan.
- [ ] Proteksi Admin aktif terakhir tetap ada di backend.

## Batas / jangan ditambahkan
- Tidak ada hapus akun lewat Admin, reset password orang lain, ubah role sembarang, akses token.

## Catatan implementasi dan status keputusan
- LAYOUT DRAFT; mockup lama keliru menyebut aktivasi ulang belum disepakati, sumber ADMIN-003 sudah LOCKED. Regresi Riverpod `CircularDependencyError` wajib diuji sebelum integrasi Admin mutation.

**Rujukan bisnis:** ADMIN-003, ADMIN-003A, ADMIN-003B, ADMIN-005, AUTH-003.
