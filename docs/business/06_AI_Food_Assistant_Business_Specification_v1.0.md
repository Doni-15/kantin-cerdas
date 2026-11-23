# AI Food Assistant Business Specification v1.0

**Produk:** Kantin Cerdas · **Status keputusan bisnis:** FINAL · LOCKED · **Versi baseline:** 1.0

**Cakupan:** Mengatur asisten kuliner serbaguna, rekomendasi katalog nyata, tampilan chat dan kartu menu, budget dan keamanan makanan, batas tindakan AI, arsitektur hybrid, Gemini Free Tier, kuota, dan fallback.

> **Status verifikasi teks:** 8/8 persetujuan asli tersedia verbatim dan telah diverifikasi SHA-256. Status FINAL dari semua aturan tidak berubah.

## Catatan implementasi Android · 19 November 2026

**Kuota dan operasional.** Naskah persetujuan AI-TECH-001 tercantum pada dokumen 09. Reservasi per Customer mengikuti tanggal Asia/Jakarta. Batas proyek Google tetap berlaku, termasuk ketika kuota individu masih tersisa. Permintaan yang sudah terkirim dengan hasil tidak pasti tetap dihitung. Fallback katalog, keranjang, dan checkout dapat berjalan ketika Gemini tidak tersedia.

**Aktivasi.** Verifikasi audiens kampus terhadap ketentuan usia Gemini dan pastikan informasi pribadi, rahasia, atau sensitif tidak dikirim ke layanan gratis, termasuk melalui pesan bebas. Selama kesesuaian belum terbukti, gunakan pencarian katalog. Uji teknis G1 dan G2 tersedia pada dokumen 08. [Persyaratan Gemini](https://ai.google.dev/gemini-api/terms) · [Kuota proyek](https://ai.google.dev/gemini-api/docs/rate-limits)

## Ikhtisar modul (penjelasan, bukan naskah persetujuan)

Mengatur asisten kuliner serbaguna, rekomendasi katalog nyata, tampilan chat dan kartu menu, budget dan keamanan makanan, batas tindakan AI, arsitektur hybrid, Gemini Free Tier, kuota, dan fallback.

- **Alur dan prinsip:** AI berbicara secara natural dan membantu eksplorasi kuliner; database/backend tetap otoritatif atas katalog, harga, status, dan keterpesanan. AI hanya mengarahkan ke Lihat Detail dan tidak memodifikasi transaksi.
- **Batas cakupan:** Gemini 3.5 Flash-Lite API Free Tier, target tambahan biaya API Rp0, maksimal 10 panggilan per Customer per hari, tanpa upgrade otomatis ke API berbayar.

## Daftar keputusan yang dikunci

| ID | Topik | Status | Naskah verbatim |
|---|---|---|---|
| [AI-001](#ai-001) | Cakupan asisten kuliner serbaguna | **FINAL · LOCKED** | Terverifikasi |
| [AI-002](#ai-002) | Data nyata dan keterpesanan rekomendasi | **FINAL · LOCKED** | Terverifikasi |
| [AI-003](#ai-003) | Chat khusus dan kartu rekomendasi | **FINAL · LOCKED** | Terverifikasi |
| [AI-004](#ai-004) | Budget ketat, preferensi fleksibel, keamanan pangan | **FINAL · LOCKED** | Terverifikasi |
| [AI-005](#ai-005) | Integrasi rekomendasi dan checkout manual | **FINAL · LOCKED** | Terverifikasi |
| [AI-006](#ai-006) | Arsitektur hybrid dan fallback pencarian | **FINAL · LOCKED** | Terverifikasi |
| [AI-006A](#ai-006a) | Gemini Flash-Lite Free Tier dan biaya API Rp0 | **FINAL · LOCKED** | Terverifikasi |
| [AI-006B](#ai-006b) | Batas 10 panggilan AI harian dan fallback | **FINAL · LOCKED** | Terverifikasi |

---

## Rincian per aturan

<a id="ai-001"></a>

### AI-001 — Cakupan asisten kuliner serbaguna

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> Untuk Kantin Cerdas, AI-001 saya memilih C: Food Assistant menjadi asisten kuliner serbaguna yang mendukung rekomendasi katalog Kantin Cerdas dan percakapan kuliner lebih luas.

**SHA-256 naskah persetujuan UTF-8 (tanpa penanda kutipan atau newline):** `0502cf8c228980f155c67dba489d4461962616c3a52a537581ed3820a94ed961`

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Food Assistant mendukung rekomendasi dari katalog Kantin Cerdas **dan** diskusi kuliner yang lebih luas.

**Rincian perilaku yang tercakup:**

- Percakapan umum dapat berupa ide makanan, resep, atau pengetahuan memasak.
- Rekomendasi untuk membeli harus selalu dibedakan dari ide kuliner umum.
- Pemakaian API dan ketersediaan saat fallback diatur pada AI-006 sampai AI-006B.

**Batasan yang harus dijaga:** Tidak mempersempit fitur hanya menjadi mesin filter katalog.

**Keterkaitan aturan:** AI-002, AI-006B.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Tanyakan menu yang bisa dibeli dan resep masakan umum; kedua jenis permintaan ditangani sesuai cakupannya.

---

<a id="ai-002"></a>

### AI-002 — Data nyata dan keterpesanan rekomendasi

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> Untuk Kantin Cerdas, AI-002 saya memilih A: rekomendasi katalog harus berdasarkan data nyata dan memprioritaskan menu yang dapat dipesan dari kantin diterbitkan, Buka, Owner aktif, dan menu Tersedia yang tidak diarsipkan; menu Habis atau kantin Tutup boleh dijelaskan sebagai informasi dengan label jelas jika diminta; AI tidak boleh mengarang data katalog; percakapan kuliner umum tetap didukung.

**SHA-256 naskah persetujuan UTF-8 (tanpa penanda kutipan atau newline):** `ce51418ff69996ef093bd614e78be0d343b0a5f3fabd3d5e88e631a3af790c0f`

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Rekomendasi katalog bersumber dari data nyata dan mengutamakan menu yang dapat dipesan dari kantin diterbitkan, Buka, Owner aktif, serta menu Tersedia yang tidak diarsipkan.

**Rincian perilaku yang tercakup:**

- Menu Habis dan kantin Tutup hanya dijelaskan sebagai informasi berlabel jelas ketika diminta.
- AI tidak mengarang menu, harga, atau ketersediaan.
- Percakapan kuliner umum tetap didukung.

**Batasan yang harus dijaga:** Hasil AI yang tidak cocok dengan katalog backend tidak boleh dijadikan kartu rekomendasi valid.

**Keterkaitan aturan:** ORDER-007, OWNER-005, ADMIN-003B, AI-004.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Minta menu dari kantin Tutup; hanya tampilkan sebagai informasi berstatus jelas ketika permintaan mencakupnya.

---

<a id="ai-003"></a>

### AI-003 — Chat khusus dan kartu rekomendasi

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> Untuk Kantin Cerdas, AI-003 saya memilih A: Food Assistant memiliki halaman chat khusus yang mendukung percakapan kuliner, contoh pertanyaan cepat, dan rekomendasi katalog dalam kartu menu berisi informasi nyata serta tindakan Lihat Detail; pemesanan tetap melalui alur biasa.

**SHA-256 naskah persetujuan UTF-8 (tanpa penanda kutipan atau newline):** `d66935dd6b5071831e1a27711436989b896d182b97b1682a9c3a39fbb2ea344e`

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Food Assistant memiliki halaman chat sendiri, contoh pertanyaan cepat, serta jawaban kuliner natural.

**Rincian perilaku yang tercakup:**

- Rekomendasi katalog berbentuk kartu menu dengan data nyata dan tindakan **Lihat Detail**.
- Tindakan tersebut membuka halaman makanan/kantin yang relevan.
- Pemesanan tetap melalui alur Customer yang sudah disetujui.

**Batasan yang harus dijaga:** Kartu menu bukan cara AI memesan otomatis.

**Keterkaitan aturan:** AI-002, AI-005, CUSTOMER-002.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Buka kartu Lihat Detail; navigasi menuju menu nyata dan tidak mengubah keranjang.

---

<a id="ai-004"></a>

### AI-004 — Budget ketat, preferensi fleksibel, keamanan pangan

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> Untuk Kantin Cerdas, AI-004 saya memilih A: budget maksimal pengguna harus dipatuhi; preferensi makanan digunakan secara fleksibel berdasarkan informasi katalog; AI wajib menyatakan ketidakpastian jika data tidak lengkap dan tidak boleh menjamin keamanan alergi, kandungan bahan, nutrisi, atau sertifikasi tanpa informasi terverifikasi.

**SHA-256 naskah persetujuan UTF-8 (tanpa penanda kutipan atau newline):** `75b4fe8be48a8d5e1cb31e6c7b99c4daf8338bcee3693bb88675de62d95d3576`

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Budget maksimum Customer wajib dihormati; preferensi makanan dicocokkan secara fleksibel sesuai informasi katalog.

**Rincian perilaku yang tercakup:**

- Jika informasi menu tidak memadai, AI menyatakan ketidakpastian.
- AI tidak menjamin keamanan alergi, kandungan bahan, nutrisi, atau sertifikasi tanpa informasi terverifikasi.
- Jawaban pengetahuan umum harus dibedakan dari fakta komposisi menu milik Owner.

**Batasan yang harus dijaga:** Tidak boleh mengklaim menu aman untuk alergi hanya dari nama makanan; tidak boleh diam-diam menaikkan budget.

**Keterkaitan aturan:** AI-002, ORDER-005, OWNER-005.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Minta makanan <= batas harga dan klaim alergi; hanya rekomendasi dalam budget, tanpa kepastian alergi yang tidak didukung.

---

<a id="ai-005"></a>

### AI-005 — Integrasi rekomendasi dan checkout manual

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> Untuk Kantin Cerdas, AI-005 saya memilih A: Food Assistant hanya memberikan rekomendasi katalog dan tindakan Lihat Detail; Customer mengelola keranjang, jumlah, catatan, dan checkout melalui alur pemesanan biasa; AI tidak boleh mengubah keranjang atau membuat pesanan otomatis.

**SHA-256 naskah persetujuan UTF-8 (tanpa penanda kutipan atau newline):** `7a8953014ff1e080a916d57ae72fd97959bb4c71c4a934b5f587be2208d0809d`

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Food Assistant hanya merekomendasikan katalog dan menyediakan **Lihat Detail**; Customer mengelola keranjang, kuantitas, catatan, dan checkout sendiri.

**Rincian perilaku yang tercakup:**

- AI tidak mengubah isi keranjang.
- AI tidak membuat pesanan otomatis.
- Aturan Order untuk satu kantin, harga, dan stok tetap berlaku pada tindakan Customer.

**Batasan yang harus dijaga:** Tidak ada AI add-to-cart, AI checkout, atau AI auto-send dalam MVP.

**Keterkaitan aturan:** ORDER-005, ORDER-009, CUSTOMER-004, AI-003.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Minta AI memasukkan item/checkout; sistem tidak membuat mutasi transaksi dan menawarkan navigasi detail.

---

<a id="ai-006"></a>

### AI-006 — Arsitektur hybrid dan fallback pencarian

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> Untuk Kantin Cerdas, AI-006 saya memilih C: Food Assistant menggunakan pendekatan hybrid antara API AI eksternal untuk percakapan dan pemahaman bahasa alami, backend untuk validasi serta rekomendasi katalog, dan fallback pencarian sederhana ketika API gagal; fitur pemesanan tetap independen dari AI.

**SHA-256 naskah persetujuan UTF-8 (tanpa penanda kutipan atau newline):** `9da4fd47e7ab2b2c8842a4f447f1881347beaf95e0b5c2927751e0f69111bd66`

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Food Assistant memakai pendekatan **hybrid**: API AI eksternal membantu percakapan dan bahasa alami; backend memvalidasi rekomendasi katalog; pencarian sederhana menjadi fallback.

**Rincian perilaku yang tercakup:**

- AI tidak menjadi sumber kebenaran data harga, menu, dan status.
- Jika API gagal, fungsi pencarian katalog sederhana tetap tersedia.
- Alur pemesanan tidak bergantung pada ketersediaan AI.

**Batasan yang harus dijaga:** Tidak boleh menjadikan API AI sebagai syarat berhasilnya checkout.

**Keterkaitan aturan:** AI-006A, AI-006B, ORDER-008.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Simulasi putus API: fallback katalog bekerja, order tetap bisa dibuat melalui alur normal.

---

<a id="ai-006a"></a>

### AI-006A — Gemini Flash-Lite Free Tier dan biaya API Rp0

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> Untuk Kantin Cerdas, AI-006A saya memilih Gemini 3.5 Flash-Lite melalui Gemini API Free Tier dengan target biaya tambahan API Rp0; tidak menggunakan layanan API berbayar atau peningkatan otomatis ke tier berbayar; penggunaan dibatasi sesuai kuota gratis yang tersedia; jika kuota habis atau layanan gagal, Food Assistant menggunakan fallback pencarian katalog sederhana; keamanan data pengguna tetap dijaga dan seluruh aturan AI sebelumnya tetap berlaku.

**SHA-256 naskah persetujuan UTF-8 (tanpa penanda kutipan atau newline):** `a2149ad5c1f4ad3bb4326d328702fb2125f3d54b4ab36bc5c78a9359b894f78d`

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Penyedia yang disetujui adalah **Gemini 3.5 Flash-Lite melalui Gemini API Free Tier**, dengan target biaya tambahan API **Rp0**.

**Rincian perilaku yang tercakup:**

- Tidak menggunakan layanan API berbayar atau upgrade otomatis ke tier berbayar.
- Pemakaian tunduk pada kuota gratis aktual yang tersedia.
- Data pengguna tetap dilindungi; layanan gagal/habis kuota memakai fallback.

**Batasan yang harus dijaga:** Langganan Google AI Pro pribadi tidak diasumsikan memberi kuota API tambahan untuk aplikasi.

**Keterkaitan aturan:** AI-006, AI-006B.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Periksa konfigurasi proyek Free Tier dan tanpa billing berbayar; jika limit tercapai sistem tidak mengeluarkan biaya API.

---

<a id="ai-006b"></a>

### AI-006B — Batas 10 panggilan AI harian dan fallback

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> Untuk Kantin Cerdas, AI-006B saya memilih B: setiap Customer mendapat maksimal 10 pemanggilan Gemini API per hari; pencarian katalog yang ditangani backend tidak mengurangi kuota AI; batas Free Tier proyek tetap menjadi batas utama; jika kuota individu atau proyek habis, Gemini gagal, timeout, atau menghasilkan respons yang tidak valid, sistem menghentikan penggunaan AI dan menyediakan fallback pencarian katalog sederhana; percakapan kuliner umum sementara tidak tersedia; keranjang, checkout, dan pemesanan tetap berjalan independen.

**SHA-256 naskah persetujuan UTF-8 (tanpa penanda kutipan atau newline):** `5b8de4da56de8d4f7f8ae7536c9214480fb48563b897f07f1f24e50914e2b785`

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Setiap Customer mendapatkan maksimal **10 pemanggilan Gemini API per hari**, tetap dibatasi lagi oleh Free Tier proyek.

**Rincian perilaku yang tercakup:**

- Pencarian katalog yang ditangani sepenuhnya oleh backend tidak mengurangi jatah AI.
- Kuota habis, error, timeout, atau hasil tidak valid menyebabkan penggunaan AI dihentikan dan fallback pencarian katalog sederhana ditampilkan.
- Percakapan kuliner umum sementara tidak tersedia saat fallback; keranjang, checkout, pesanan tetap independen.

**Batasan yang harus dijaga:** Tidak ada peningkatan biaya atau panggilan Gemini yang melampaui batas yang sah.

**Keterkaitan aturan:** AI-006A, AI-006, CUSTOMER-004.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Uji batas per Customer dan proyek, timeout, respons AI tak valid, serta backend-only search yang tidak memakai kuota.

---

## Pemeriksaan konsistensi modul

- **Cakupan luas:** percakapan kuliner umum tersedia saat layanan AI berjalan, tanpa menyamar sebagai fakta katalog.
- **Grounding katalog:** backend selalu memutuskan item, harga, kelayakan checkout, dan status nyata.
- **Non-transaksional:** AI tidak mengubah keranjang dan tidak membuat pesanan.
- **API gratis:** Gemini Free Tier, Rp0 biaya tambahan API, tanpa peningkatan otomatis berbayar.
- **Kuota/fallback:** maksimal 10 pemanggilan Gemini per Customer per hari; pencarian backend tetap berjalan tanpa memakai kuota AI.

---

## Perlindungan integritas keputusan

1. **FINAL · LOCKED** adalah status keputusan bisnis, **bukan** klaim bahwa seluruh kutipan aslinya telah tersedia dalam dokumen ini.
2. Bagian berlabel **NASKAH PERSETUJUAN ASLI — VERBATIM** hanya memuat kalimat yang dapat diverifikasi langsung melalui sumber persetujuan yang tersedia. Kalimat ditulis satu baris tanpa koreksi ejaan atau tanda baca.
3. Bagian **Ringkasan operasional**, **Penjabaran**, **Batasan**, dan **Skenario pemeriksaan** adalah penjelasan dari keputusan, **bukan teks verbatim dan bukan amendemen**. Jika penjabaran kurang tepat, sumber persetujuan asli yang berlaku.
4. Aturan FINAL tidak boleh diganti, digabung, dinomori ulang, atau diubah berdasarkan preferensi teknis. Hal baru hanya boleh diajukan sebagai DRAFT/amendemen terpisah melalui persetujuan pengguna.
5. Status spesifikasi ini tidak menyatakan kode, API, database, atau deployment telah dibangun dan diuji.

## Status akhir modul

- **Jumlah aturan:** 8 FINAL · LOCKED.
- **Persetujuan asli yang sudah diverifikasi:** 8.
- **Persetujuan asli yang masih harus diverifikasi:** 0.
- **Pelaksanaan kode/repository:** Tidak dilakukan pada pembuatan dokumen ini.
- **Catatan sumber.** Edisi awal menggunakan arsip audit 18 November 2026. Edisi ini juga merujuk pada percakapan asli. [Percakapan keputusan Kantin Cerdas](https://chatgpt.com/share/6afdc1cc-ac30-83ec-b635-1a8bf4898864)
