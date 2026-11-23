# Authentication Business Specification v1.0

**Produk:** Kantin Cerdas · **Status keputusan bisnis:** FINAL · LOCKED · **Versi baseline:** 1.0

**Cakupan:** Mengatur verifikasi email, registrasi dua langkah dan foto, login dan sesi, reset password, perubahan identitas login, dan konflik alamat email antar-metode autentikasi.

> **Status verifikasi teks:** 6/6 persetujuan baseline tersedia verbatim dan telah diverifikasi SHA-256. Klausul linking AUTH-005 dan AUTH-005A mengikuti [amendemen resmi 20 November 2026](../development/Kantin_Cerdas_AUTH_005A_Amendment_Final/AMENDEMEN_AUTH_005_005A_2026-11-20.md).

## Catatan implementasi Android · 20 November 2026

**Syarat integrasi Android.** Supabase Auth boleh menautkan email/password dan Google otomatis menurut verifikasi provider. Shelf memakai satu ID Supabase yang sah untuk profil dan kepemilikan. Rilis Google menunggu bukti A1–A4 di QA.

Gunakan SMTP yang dapat menjangkau email mahasiswa dan uji tautan verifikasi, reset, serta perubahan email pada Android. Periksa pemulihan langkah foto dan logout satu perangkat ketika perangkat kedua tetap aktif. [Penautan identitas](https://supabase.com/docs/guides/auth/auth-identity-linking) · [SMTP](https://supabase.com/docs/guides/auth/auth-smtp)

## Ikhtisar modul (penjelasan, bukan naskah persetujuan)

Mengatur verifikasi email, registrasi dua langkah dan foto, login dan sesi, reset password, perubahan identitas login, dan konflik alamat email antar-metode autentikasi.

- **Alur dan prinsip:** Registrasi publik menghasilkan CUSTOMER. Google Sign-In dan email/password didukung sesuai aturan; perubahan role Owner melalui persetujuan Admin, dan akun Admin tidak dapat dibuat dari pendaftaran umum.
- **Batas cakupan:** Penautan otomatis mengikuti Supabase Auth. Penggabungan data berdasarkan email, penautan manual antar-email, akun aplikasi duplikat, dan reset password manual oleh Admin berada di luar cakupan.

## Daftar keputusan yang dikunci

| ID | Topik | Status | Naskah verbatim |
|---|---|---|---|
| [AUTH-001](#auth-001) | Verifikasi email untuk pemesanan | **FINAL · LOCKED** | Terverifikasi |
| [AUTH-002](#auth-002) | Registrasi dua langkah dan foto profil wajib | **FINAL · LOCKED** | Terverifikasi |
| [AUTH-003](#auth-003) | Login, logout, dan pengelolaan sesi | **FINAL · LOCKED** | Terverifikasi |
| [AUTH-004](#auth-004) | Reset password dan pemulihan akun | **FINAL · LOCKED** | Terverifikasi |
| [AUTH-005](#auth-005) | Perubahan profil dan informasi autentikasi | **FINAL · diamendemen untuk linking** | Terverifikasi |
| [AUTH-005A](#auth-005a) | Konflik email antara metode login | **FINAL · diamendemen untuk linking** | Terverifikasi |

---

## Rincian per aturan

<a id="auth-001"></a>

### AUTH-001 — Verifikasi email untuk pemesanan

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> Untuk Kantin Cerdas, AUTH-001 saya memilih A: pendaftaran email/password membutuhkan verifikasi alamat email sebelum menggunakan fitur pemesanan, sedangkan login Google menggunakan verifikasi identitas Google.

**SHA-256 naskah persetujuan UTF-8 (tanpa penanda kutipan atau newline):** `5337017a4d6e686e649b05724b7150c6ecf70d507baee01c24e5134e546f3565`

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Pendaftaran email/password mensyaratkan verifikasi alamat email sebelum pengguna dapat menggunakan fitur pemesanan. Login Google menggunakan verifikasi identitas dari Google.

**Rincian perilaku yang tercakup:**

- Syarat berlaku untuk kemampuan memesan, bukan perubahan status order yang sudah dibuat.
- Pengguna Google tidak otomatis diwajibkan menjalani mekanisme verifikasi email lokal yang sama.
- Sisi backend harus menegakkan syarat akses transaksi.

**Batasan yang harus dijaga:** Jangan menganggap keberhasilan pembuatan akun email/password sama dengan hak langsung untuk memesan.

**Keterkaitan aturan:** AUTH-002, AUTH-005, CUSTOMER-004.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Akun email/password belum terverifikasi tidak dapat checkout; setelah verifikasi sah diperbolehkan jika syarat lain terpenuhi.

---

<a id="auth-002"></a>

### AUTH-002 — Registrasi dua langkah dan foto profil wajib

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> Untuk Kantin Cerdas, AUTH-002 saya memilih A: pendaftaran dua langkah minimalis; langkah pertama nama lengkap, email dan password atau identitas Google; langkah kedua foto profil wajib; foto Google digunakan sebagai default jika tersedia dan perubahan foto memerlukan konfirmasi; tanpa nomor telepon.

**SHA-256 naskah persetujuan UTF-8 (tanpa penanda kutipan atau newline):** `2c6df45bc560266a73e3fc18299c982caac1f7790a6dee78210623ca85557a76`

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Registrasi Customer dilakukan dalam dua langkah minimalis: identitas akun terlebih dahulu, lalu foto profil wajib.

**Rincian perilaku yang tercakup:**

- Metode email/password meminta nama lengkap, email dan password; metode Google menggunakan identitas Google.
- Foto Google dipakai sebagai default jika tersedia; pergantian foto memerlukan konfirmasi.
- Nomor telepon tidak diminta sebagai syarat registrasi.

**Batasan yang harus dijaga:** Tidak menambah kewajiban NIM, fakultas, nomor telepon, atau atribut lain tanpa persetujuan.

**Keterkaitan aturan:** AUTH-001, AUTH-005, CUSTOMER-006.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Uji pendaftaran dua metode, foto Google tersedia/tidak, dan konfirmasi ketika foto diganti.

---

<a id="auth-003"></a>

### AUTH-003 — Login, logout, dan pengelolaan sesi

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> Untuk Kantin Cerdas, AUTH-003 saya memilih A: pengguna tetap login secara aman selama sesi masih valid atau dapat diperbarui; logout mengakhiri sesi perangkat saat ini; jika sesi tidak dapat dipulihkan pengguna harus login ulang; akses dan navigasi mengikuti role serta status akun yang sah.

**SHA-256 naskah persetujuan UTF-8 (tanpa penanda kutipan atau newline):** `c896d7827053c91d3a5a6595d80ed0115be87c3ed6a76f79c791df3387045302`

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Sesi pengguna dipertahankan secara aman selama masih valid atau dapat diperbarui; logout mengakhiri sesi pada perangkat saat ini.

**Rincian perilaku yang tercakup:**

- Sesi tidak dapat dipulihkan mewajibkan login ulang.
- Backend menentukan akses berdasarkan role dan status akun yang sah.
- Aplikasi yang ditutup tidak otomatis dianggap logout.

**Batasan yang harus dijaga:** Jangan mengandalkan hanya nilai role tersimpan di perangkat untuk otorisasi.

**Keterkaitan aturan:** AUTH-004, ADMIN-003, ADMIN-005.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Tutup/buka aplikasi, kedaluwarsa sesi, logout perangkat, dan akun dinonaktifkan harus menghasilkan akses sesuai aturan.

---

<a id="auth-004"></a>

### AUTH-004 — Reset password dan pemulihan akun

**Status: FINAL · LOCKED**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> Untuk Kantin Cerdas, AUTH-004 saya memilih A: lupa password dipulihkan melalui tautan reset email yang aman, sekali pakai, dan memiliki masa berlaku terbatas; akun Google-only dipulihkan melalui Google; Admin tidak melakukan reset password manual.

**SHA-256 naskah persetujuan UTF-8 (tanpa penanda kutipan atau newline):** `c558b0189aa09454c5970c85e3539d26ab6c79f5cf7c110fe9466b928337e437`

**Isi keputusan yang disahkan — ringkasan penjelas, bukan verbatim**

Pengguna email/password mereset password melalui tautan email aman, sekali pakai, dan berbatas waktu.

**Rincian perilaku yang tercakup:**

- Akun yang hanya menggunakan Google melakukan pemulihan melalui Google.
- Admin tidak mereset password secara manual.
- Tautan kedaluwarsa atau terpakai tidak dapat dipakai lagi.

**Batasan yang harus dijaga:** Jangan membuat password lokal otomatis untuk akun Google-only.

**Keterkaitan aturan:** AUTH-001, AUTH-005, ADMIN-005.

**Skenario pemeriksaan saat implementasi (bukan aturan baru):** Uji token reset sekali pakai, kedaluwarsa, dan pembedaan akun Google-only.

---

<a id="auth-005"></a>

### AUTH-005 — Perubahan profil dan informasi autentikasi

**Status baseline: FINAL · LOCKED**

**SUPERSEDED FOR LINKING CLAUSES BY KC-AUTH-AMEND-2026-11-20-01**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> Untuk Kantin Cerdas, AUTH-005 saya memilih A: pengguna dapat mengubah nama/foto, mengganti password dengan verifikasi aman, dan mengganti email login melalui proses verifikasi; akun Google-only tetap dikelola melalui Google; tidak ada penautan metode login otomatis.

**SHA-256 naskah persetujuan UTF-8 (tanpa penanda kutipan atau newline):** `e44b34b80d9a504fb7495f5cada0ed233148dac570164b63a09178460e6cf322`

**Aturan operasional berlaku.** Nama dan foto dapat diubah. Perubahan email/password memerlukan verifikasi. Akun Google-only memakai Google untuk login dan pemulihan. Akun dengan metode email/password yang sah dapat mengelola kredensial sesuai bukti password. Linking yang sah melalui Supabase mempertahankan role, status dan relasi data pada ID yang sama.

Lihat [amendemen](../development/Kantin_Cerdas_AUTH_005A_Amendment_Final/AMENDEMEN_AUTH_005_005A_2026-11-20.md) dan skenario A1–A4.

---

<a id="auth-005a"></a>

### AUTH-005A — Konflik email antara metode login

**Status baseline: FINAL · LOCKED**

**SUPERSEDED FOR LINKING CLAUSES BY KC-AUTH-AMEND-2026-11-20-01**

**NASKAH PERSETUJUAN ASLI — VERBATIM**

> Untuk Kantin Cerdas, AUTH-005A saya memilih A: jika email sudah terdaftar melalui metode login tertentu, pengguna harus menggunakan metode tersebut; jangan membuat akun duplikat atau menautkan metode secara otomatis.

**SHA-256 naskah persetujuan UTF-8 (tanpa penanda kutipan atau newline):** `9c52140d98573e7133adf7eb4995f67df858afd7642781ea92614da20d431e6b`

**Aturan operasional berlaku.** Supabase Auth dapat menautkan Google dan email/password bila pemeriksaan provider mengizinkan. Shelf memeriksa status verifikasi dan sesi lalu mengotorisasi berdasarkan ID pengguna yang sah. Satu ID mempertahankan satu profil dan relasi data. Pesan publik tetap netral. Penyatuan data berdasarkan alamat email dan linking manual antar-email berada di luar cakupan MVP.

Lihat [amendemen](../development/Kantin_Cerdas_AUTH_005A_Amendment_Final/AMENDEMEN_AUTH_005_005A_2026-11-20.md) dan skenario A1–A4.

---

## Pemeriksaan konsistensi modul

- **Pendaftaran ≠ boleh checkout:** email/password harus diverifikasi, dan foto profil wajib dilengkapi.
- **Identitas tunggal:** alamat email yang sama tidak boleh menciptakan akun duplikat antar-metode.
- **Otorisasi server:** akses selalu mengikuti role dan status akun yang sah.
- **Integrasi Admin:** pendaftaran publik tidak menghasilkan role ADMIN dan Admin tidak melakukan reset password manual.

---

## Perlindungan integritas keputusan

1. **FINAL · LOCKED** adalah status keputusan bisnis, **bukan** klaim bahwa seluruh kutipan aslinya telah tersedia dalam dokumen ini.
2. Bagian berlabel **NASKAH PERSETUJUAN ASLI — VERBATIM** hanya memuat kalimat yang dapat diverifikasi langsung melalui sumber persetujuan yang tersedia. Kalimat ditulis satu baris tanpa koreksi ejaan atau tanda baca.
3. Bagian **Ringkasan operasional**, **Penjabaran**, **Batasan**, dan **Skenario pemeriksaan** adalah penjelasan dari keputusan, **bukan teks verbatim dan bukan amendemen**. Jika penjabaran kurang tepat, sumber persetujuan asli yang berlaku.
4. Aturan FINAL tidak boleh diganti, digabung, dinomori ulang, atau diubah berdasarkan preferensi teknis. Hal baru hanya boleh diajukan sebagai DRAFT/amendemen terpisah melalui persetujuan pengguna.
5. Status spesifikasi ini tidak menyatakan kode, API, database, atau deployment telah dibangun dan diuji.

## Status akhir modul

- **Jumlah aturan:** 6 FINAL · LOCKED.
- **Persetujuan asli yang sudah diverifikasi:** 6.
- **Persetujuan asli yang masih harus diverifikasi:** 0.
- **Pelaksanaan kode/repository:** Tidak dilakukan pada pembuatan dokumen ini.
- **Catatan sumber.** Edisi awal menggunakan arsip audit 18 November 2026. Edisi ini juga merujuk pada percakapan asli. [Percakapan keputusan Kantin Cerdas](https://chatgpt.com/share/6afdc1cc-ac30-83ec-b635-1a8bf4898864)
