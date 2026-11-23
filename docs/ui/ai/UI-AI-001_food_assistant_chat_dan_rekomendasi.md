---
id: UI-AI-001
module: ai
design_status: DRAFT
revision: 2026-11-19
target: Android-first
document_type: screen-ui-spec
business_rule_refs: [AI-001, AI-002, AI-003, AI-004, AI-005, AI-006, AI-006A, AI-006B, AI-TECH-001]
---

# UI-AI-001 — Food Assistant Chat dan Rekomendasi

> **STATUS UI: DRAFT**. Ini spesifikasi perilaku/tampilan, BUKAN kode Flutter atau kontrak endpoint. Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, `../shared/06_STATES_LOADING_ERROR.md` dan file layar ini. Semua aturan bisnis LOCKED tetap berlaku terlepas dari status desain UI.

## Tujuan dan akses
Chat kuliner natural dan rekomendasi menu berdasarkan katalog yang nyata; AI tidak pernah mengeksekusi pesanan.

**Titik masuk:** FAB robot centerDocked dari root Customer; subhalaman chat tanpa bottom nav.

## Struktur layar — urutan visual atas → bawah
- AppBar kembali, ikon `Icons.smart_toy_rounded`, nama **Food Assistant**, subtitle singkat; indikator kuota AI **hanya jika backend menyediakan nilai terverifikasi**, tampil kecil tanpa mendominasi.
- Area percakapan pesan Customer dan balasan AI dengan bubble sederhana, tanpa avatar robot berulang.
- Quick suggestion chips singkat sebagai input contoh, bukan rekomendasi fiktif.
- Balasan rekomendasi katalog memakai daftar menu ringkas dengan nama kantin, nama item, harga, keterpesanan dan **Lihat Detail**.
- Balasan percakapan umum resep/ide makanan berupa teks dengan label/penjelasan bahwa itu bukan item katalog yang dapat dibeli.
- Input pertanyaan bawah, tombol kirim, aman saat keyboard.

## Interaksi
| Elemen / tindakan | Perilaku yang diwajibkan / arah navigasi |
| --- | --- |
| Kirim pertanyaan | Backend memeriksa izin, kuota user dan batas proyek sebelum pemanggilan model; jawaban tidak boleh dianggap sumber katalog. |
| Pertanyaan cepat | Mengisi/mengirim pesan sesuai UX yang diputuskan; kontrol tidak melakukan transaksi. |
| Lihat Detail | Buka UI-CUSTOMER-003 berdasarkan ID menu sah; Customer yang memutuskan Tambah/Keranjang/Checkout. |
| Kuota habis/AI unavailable | Fallback pencarian katalog backend tanpa mengurangi kuota AI. |
| Pertanyaan kuliner umum | Boleh dijawab jika model diaktifkan secara sah; bila tidak, jelaskan bahwa percakapan umum AI tidak tersedia dan tawarkan pencarian katalog. |

## State layar
| Kondisi | Perilaku UI |
| --- | --- |
| loading | Chat in-flight terlihat, double-send dicegah. |
| kuota harian 0 | Jelaskan reset 00:00 Asia/Jakarta; fallback katalog. |
| Free Tier proyek habis | Fallback katalog; jangan upgrade otomatis ke bayar. |
| API timeout/uncertain | Kuota permintaan yang sudah dikirim mungkin tetap terpakai; cek backend, jangan mengarang sisanya. |
| tidak ada menu cocok | Jelaskan tidak ada hasil, tidak membuat menu fiktif. |
| menu Habis/kantin Tutup | Jika dimunculkan untuk informasi, beri status jelas dan tidak dorong checkout. |
| user minor/data sensitif belum aman | Blok panggilan eksternal yang tak memenuhi syarat; fallback katalog sesuai kebijakan. |
| offline | Jangan hilangkan ketikan; tampilkan pesan jaringan. |

## Guard dan sumber data
- AI-001 mencakup **diskusi kuliner umum** dan rekomendasi katalog, tetapi rekomendasi untuk dibeli harus grounded.
- AI-002: eligible = published, Buka, Owner aktif, menu Tersedia dan tidak arsip; budget Customer adalah batas keras.
- 10 panggilan AI/user/hari reset Asia/Jakarta; proyek Free Tier bisa berhenti lebih dulu; fallback tidak konsumsi jatah.
- Teks prompt/model belum boleh memicu add-to-cart atau create-order.
- Ketersediaan/kelayakan model bernama “Gemini 3.5 Flash-Lite” dan syarat audiens/dataset harus diverifikasi sebelum aktivasi Gemini.

## Kriteria penerimaan (UI)
- [ ] Chat jelas terpisah dari katalog; hasil rekomendasi memakai data backend.
- [ ] Kuota/limit berasal backend, bukan counter hardcoded.
- [ ] Fallback tetap bisa berfungsi tanpa model AI.
- [ ] Tidak ada aksi AI menambah keranjang/pesanan.
- [ ] Light/Dark, keyboard, teks panjang, error/timeout tampil wajar.

## Batas / jangan ditambahkan
- Tidak ada voice call, pembayaran via AI, hasil inventaris yang dikarang, klaim alergi/nutrisi/sertifikasi tanpa bukti.

## Catatan implementasi dan status keputusan
- LAYOUT DRAFT. Teks/sisa kuota/menu mockup hanya contoh. Pendaftaran Gemini dan kelayakan Free Tier bukan hal yang dibuktikan UI.

**Rujukan bisnis:** AI-001, AI-002, AI-003, AI-004, AI-005, AI-006, AI-006A, AI-006B, AI-TECH-001.
