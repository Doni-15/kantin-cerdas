# Kantin Cerdas — UI Authentication | MULAI DI SINI

> **Dokumen masuk utama untuk AI/Codex.** BACA berkas ini lebih dahulu, kemudian berkas UI yang relevan. Ini adalah paket **khusus UI/UX Authentication**, BUKAN spesifikasi backend, bukan aturan bisnis baru, dan bukan perintah untuk langsung menulis kode.

## A. Identitas paket

- Modul: **Authentication** saja.
- Fokus: **tata letak, teks UI, komponen, navigasi konseptual, responsivitas, light/dark mode, interaksi pengguna, state, serta acceptance criteria UI**.
- Referensi tema asli: `theme.zip` pengguna (`kc_theme.dart`, `kc_colors.dart`, `kc_typography.dart`, `kc_radius.dart`, `kc_spacing.dart`, `kc_sizes.dart`, `kc_theme_exports.dart`).
- Referensi aturan bisnis terpisah: `04_Authentication_Business_Specification_v1.0.md` — **AUTH-001 hingga AUTH-005A**. Jangan mengganti, mengedit, atau menyalin ulang bunyi aturan bisnis tersebut berdasarkan interpretasi dokumen UI.
- **Status desain:** `UI-AUTH-001 Login` = **FINAL · LOCKED**. Registrasi, Verifikasi Email, Lupa/Reset Password, dan pola error = **desain diterima dalam brainstorming, belum LOCKED formal**.
- Target utama: **Android**, kemudian **iOS**. Tetap responsif pada tablet, web, dan layar besar.

## B. Daftar file dan urutan baca wajib

| Urutan | File | Tanggung jawab eksklusif |
|---|---|---|
| 00 | `00_README_MULAI_DI_SINI.md` | Batas dan sumber kebenaran |
| 01 | `01_DESIGN_SYSTEM_RESPONSIVE.md` | Theme asli, light/dark, responsive dan a11y global |
| 02 | `02_LOGIN_UI_AUTH_001.md` | **LOGIN FINAL · LOCKED** |
| 03 | `03_REGISTRASI_LANGKAH_1_UI_AUTH_002A.md` | Langkah 1, email/password dan Google |
| 04 | `04_REGISTRASI_LANGKAH_2_UI_AUTH_002B.md` | Foto profil wajib |
| 05 | `05_VERIFIKASI_EMAIL_UI_AUTH_003.md` | Konfirmasi email melalui tautan |
| 06 | `06_LUPA_PASSWORD_UI_AUTH_004A.md` | Mengirim permintaan reset |
| 07 | `07_RESET_PASSWORD_UI_AUTH_004C.md` | Mengatur password baru dengan tautan valid |
| 08 | `08_STATE_NAVIGASI_PENGUJIAN.md` | State, error, alur antarlayar, dan QA |

**Aturan membaca:** baca 00 + 01 + file layar yang dikerjakan + 08, lalu rujuk aturan bisnis Auth saat menyambungkan backend. Untuk implementasi seluruh Authentication UI, baca semua file 00–08. **Jangan menerapkan isi satu file layar pada layar lain kecuali aturan global dari 01/08 memang mengharuskan.**

## C. Prioritas jika instruksi bertentangan

1. **Aturan bisnis Auth FINAL · LOCKED** dari dokumen bisnis yang terpisah.
2. **Desain Login UI-AUTH-001 FINAL · LOCKED** dari `02_LOGIN_UI_AUTH_001.md`.
3. Desain UI lain yang telah diterima dalam diskusi dan dijabarkan dalam file masing-masing; jangan klaim telah LOCKED jika belum.
4. **Kode tema/aset nyata yang sudah tersedia** di proyek. Nilai dan nama token dari `theme.zip` menang atas sketsa visual.
5. Ketentuan engineering UI global dalam `01_DESIGN_SYSTEM_RESPONSIVE.md` dan `08_STATE_NAVIGASI_PENGUJIAN.md`.

Jika ada konflik yang tidak bisa diputuskan tanpa mengubah keputusan lebih tinggi, **hentikan bagian terkait dan laporkan blocker**; jangan diam-diam membuat solusi sendiri.

## D. Ketentuan anti-asumsi untuk AI

**WAJIB:**
- Gunakan **logo asli** aplikasi (jika belum tersedia di proyek, laporkan dependensi; jangan membuat logo pengganti).
- Reuse `KcTheme.light` dan `KcTheme.dark`, plus token tema yang tersedia; jangan membuat palet, font, dan sistem spacing baru.
- Hormati urutan dan posisi pada masing-masing file layar. Kata/label yang disebut eksplisit **jangan diganti dengan copy buatan AI**.
- Pisahkan state UI dari hasil autentikasi yang benar-benar diputuskan oleh server.
- Tunjukkan kondisi loading, empty/invalid/error, keyboard terbuka, internet terputus, dan font diperbesar sebagaimana matriks pengujian.

**DILARANG MENAMBAH** tanpa persetujuan: nomor HP, pilihan role pada pendaftaran, NIM, fakultas, pilihan kampus, OTP 6 digit, banner promosi, foto makanan ilustratif, onboarding, login Apple, metode autentikasi ketiga, login otomatis palsu, atau dialog error tambahan yang tidak diperlukan.

**JANGAN DIANGGAP TERSELESAIKAN OLEH UI:** AUTH-005A/Supabase automatic identity linking, urutan persistensi akun/foto, deep link produksi, masa berlaku token, password policy konkret, implementasi route, endpoint/backend schema. Ini **dependensi integrasi**; dokumen UI tidak memberikan solusi backend yang terbukti.

## E. Batas cakupan yang jelas

**Termasuk**: Login, Daftar 2 langkah, Verifikasi Email, Lupa Password, Buat Password Baru, feedback loading/error, transisi konseptual.

**Tidak termasuk**: pengeditan nama/foto di halaman Profil, perubahan email login/password dari Pengaturan Akun, UI Owner/Admin, halaman Customer, API contract, skema database, aturan RLS, kode Supabase Auth, pemeriksaan automatic linking. Hal-hal tersebut punya dokumen/modul tersendiri.

## F. Batasan status dan tindakan

- **Satu-satunya layar UI yang telah diminta user untuk LOCK:** Login (`UI-AUTH-001`). Jangan menyatakan layar lain FINAL hanya karena sudah didiskusikan dan disukai.
- Paket ini adalah **referensi UI yang lebih terstruktur**, bukan bukti seluruh sistem dapat langsung dirilis.
- **Tidak ada kode, migrasi, aset, atau repository yang diubah** oleh pembuatan paket Markdown ini.
- AI pelaksana wajib memeriksa aset logo/font di proyek; `theme.zip` sendiri tidak menyertakan kedua aset tersebut atau `pubspec.yaml`.

## G. Checklist kepatuhan singkat

- [ ] Seluruh file relevan sudah dibaca; setiap layar memakai desainnya sendiri.
- [ ] Tidak ada warna literal dari mockup di widget runtime.
- [ ] UI Login persis menurut § komponen dan urutan di file 02.
- [ ] Kedua mode tema dan rentang layar diuji.
- [ ] Validasi UI tidak menggantikan otorisasi Auth/backend.
- [ ] Tidak ada layar, metode login, atau aturan bisnis ciptaan AI.
- [ ] Masalah backend yang belum pasti dilaporkan, bukan ditutupi.
