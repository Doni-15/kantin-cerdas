# AI_FUTURE_ACTIVATION.md — Panduan Aktivasi Gemini 3.5 Flash-Lite di Masa Depan

**Status saat ini:** **DISABLED BY DEFAULT (`AI_PROVIDER_ENABLED=false`) / CATALOG FALLBACK ONLY.**  
Dokumen ini memandu tim teknik saat kelak siap mengaktifkan Gemini API Free Tier secara terkendali dan aman (`AI-006A`, `AI-006B`, `AI-TECH-001`). **Jangan menaruh API key nyata di repository atau file dokumentasi ini.**

---

## 1. File Konfigurasi Utama & Komentar TODO Teratas

- **File konfigurasi utama:** `server/backend/lib/src/modules/ai/data/ai_provider_config.dart`
- **Lokasi komentar TODO:** Tepat di **baris paling atas file** (baris 1–20, sebelum statement `import` pertama), berlabel `TODO(AI-FUTURE-ACTIVATION): GEMINI API BELUM DIAKTIFKAN`, berisi langkah persiapan sekaligus URL contoh berdomain `.invalid` agar tidak pernah menjadi endpoint aktif.
- Adapter `server/backend/lib/src/modules/ai/data/gemini_ai_provider.dart` merujuk langsung ke `ai_provider_config.dart` dan menolak pemanggilan apabila URL masih kosong, bukan HTTPS, atau memakai domain `.invalid`.

---

## 2. Variabel Environment Backend

Seluruh variabel berikut disiapkan pada environment server Shelf (lihat juga templat di `server/backend/.env.example`, tanpa nilai rahasia di Git):

| Variabel | Nilai Default Saat Ini | Penjelasan Saat Aktivasi |
| --- | --- | --- |
| `AI_PROVIDER_ENABLED` | `false` | Kill switch utama; set `true` **hanya** sesudah seluruh langkah aktivasi lulus |
| `AI_FREE_TIER_VERIFIED` | `false` | Konfirmasi bahwa project API Google menggunakan Free Tier tanpa billing berbayar (`Rp0`) |
| `AI_PRIVACY_AUDIENCE_VERIFIED` | `false` | Konfirmasi kepatuhan syarat usia (>=18 tahun sesuai target mahasiswa) & privasi data |
| `GEMINI_API_KEY` | *(kosong)* | Kunci rahasia API Gemini dari secret manager server (bukan Git/Flutter/DB) |
| `GEMINI_API_BASE_URL` | *(kosong)* | Base/endpoint HTTPS resmi dokumentasi Google Gemini API (ganti dari contoh `.invalid`) |
| `GEMINI_MODEL` | `gemini-3.5-flash-lite` | Hanya model Free Tier yang disetujui (`AI-006A`) yang lolos validasi `validateActivation()` |
| `AI_DAILY_USER_LIMIT` | `10` | Maksimum panggilan per Customer per tanggal Asia/Jakarta (`1..10`) |
| `AI_PROJECT_DAILY_CAP` | `0` | Batas aman pemanggilan harian level proyek Free Tier (wajib > 0 saat aktif; nilai `0` memicu fail-closed) |
| `AI_PROJECT_RPM_LIMIT` | `15` | Batas panggilan per menit (RPM) in-memory sebelum otomatis mundur ke fallback |
| `AI_REQUEST_TIMEOUT_SECONDS` | `12` | Timeout HTTP panggilan Gemini (`3..30` detik) |

---

## 3. Langkah Memasang API Key & Mengganti URL Placeholder

1. Buat project Google AI / Gemini API khusus backend Kantin Cerdas dan **pastikan Cloud Billing / pay-as-you-go tidak aktif** agar batas biaya API tetap **Rp0**.
2. Simpan kredensial `GEMINI_API_KEY` di environment runtime backend (misalnya Secret Manager atau file `.env` privat yang di-`.gitignore`). **Jangan pernah** menaruhnya di `app/` (Flutter) atau database PostgreSQL.
3. Verifikasi endpoint HTTPS dan ID model resmi `gemini-3.5-flash-lite` dari dokumentasi resmi Gemini API (`https://generativelanguage.googleapis.com/...` atau versi terbaru saat rilis).
4. Set `GEMINI_API_BASE_URL` pada environment server menggantikan contoh `.invalid`. Apabila endpoint belum diisi atau masih berdomain `.invalid`, `AiProviderConfig.resolveEndpointUri()` otomatis mengembalikan `null` dan menolak aktivasi.

---

## 4. Verifikasi Free Tier, Billing Rp0, Usia, Layanan, & Privasi

1. **Free Tier & Billing (`AI-006A`):** Pastikan dashboard Google AI / Cloud Billing menunjukkan tier gratis, tidak ada kartu/billing aktif untuk upgrade otomatis, dan jangan mengasumsikan langganan Google AI Pro pribadi menambah kuota API aplikasi. Tetapkan `AI_PROJECT_DAILY_CAP` dan `AI_PROJECT_RPM_LIMIT` di bawah kuota Free Tier aktual, lalu barulah set `AI_FREE_TIER_VERIFIED=true`.
2. **Usia, Persyaratan Layanan, & Privasi:** Audit target audiens mahasiswa agar memenuhi batas usia minimum Ketentuan Layanan Gemini API (`AI-TECH-001` / dokumen 09). Pastikan prompt yang dikirim tidak membawa email, nomor HP, NIK, token, atau data pribadi (`AiInputGuard` sudah menyaring input sensitif sebelum memanggil Gemini dan tidak menyertakan identitas akun pada konteks). Setelah audit produk/hukum selesai, set `AI_PRIVACY_AUDIENCE_VERIFIED=true`.

---

## 5. Pengujian Provider Nyata Sebelum Rilis

Sebelum menyalakan untuk pengguna produksi, uji pada environment QA terisolasi:
1. Terapkan seluruh migration termasuk `20261122000001_ai_food_assistant.sql`.
2. Jalankan `server_all.dart` di staging QA terisolasi dengan flag aktif dan `AI_PROJECT_DAILY_CAP` uji kecil.
3. Uji:
   - `GET /v1/ai/status` menampilkan `provider_ready: true` dan `quota.remaining_today: 10`, tanpa membocorkan key/URL.
   - Pertanyaan katalog + budget `<= Rp20.000` menghasilkan kartu terverifikasi DB (`kc_ai_verify_menu_candidates`).
   - Pertanyaan kuliner umum (`"ide resep..."`) terbalas dengan label non-katalog.
   - Uji melebihi 10 panggilan memblokir panggilan ke-11 (`quota_exhausted`), menyisakan fallback katalog, dan mereset pukul 00:00 WIB.
   - Pastikan pemakaian tagihan di Google AI tetap **Rp0**.

---

## 6. Aktivasi Feature Flag & Kill Switch Darurat

- **Aktivasi:** Setelah semua uji staging nyata lulus, set pada environment server:
  ```dotenv
  AI_PROVIDER_ENABLED=true
  AI_FREE_TIER_VERIFIED=true
  AI_PRIVACY_AUDIENCE_VERIFIED=true
  AI_PROJECT_DAILY_CAP=<angka_aman_terverifikasi>
  ```
  Lalu restart proses `server_all.dart`. Tidak diperlukan build ulang aplikasi Flutter.
- **Menonaktifkan Segera (Kill Switch):** Jika terjadi lonjakan error, risiko biaya/billing, kebocoran/isu privasi, atau perubahan kebijakan Google:
  1. Segera ubah `AI_PROVIDER_ENABLED=false` (atau kosongkan `GEMINI_API_KEY` / set `AI_PROJECT_DAILY_CAP=0`).
  2. Restart service backend `server_all.dart`.
  3. Dalam hitungan detik seluruh endpoint `/v1/ai/**` langsung kembali ke **Catalog Fallback Mode** tanpa memutus pencarian katalog, keranjang, atau checkout Customer.
