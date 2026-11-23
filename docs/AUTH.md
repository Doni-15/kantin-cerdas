# Menyiapkan Authentication di lingkungan uji

Gunakan proyek Supabase pengujian, akun pengujian, dan SMTP yang dapat mengirim ke kotak masuk pengujian. Simpan kunci server di konfigurasi lokal Shelf. Flutter hanya memerlukan URL Shelf serta URL proyek Supabase saat Google diaktifkan untuk pengujian.

## Shelf dan database

Terapkan [migrasi berurutan](../server/supabase/README.md) ke database pengujian sebelum menjalankan Shelf. Pengaturan issuer, audience dan algoritme JWT harus sama dengan konfigurasi token proyek Supabase. Shelf memakai endpoint Auth `/user` untuk validasi tanda tangan, lalu mencocokkan subjek dan memeriksa status sesi dari database. Sesi yang sudah dicabut dan akun dengan larangan aktif ditolak.

Aktifkan konfirmasi email pada Supabase, konfigurasi SMTP, atur masa berlaku email OTP, dan gunakan Secure Email Change untuk konfirmasi di alamat lama dan baru. Perubahan password di aplikasi meminta password saat ini. Token dan alamat email dari template pengujian tidak perlu dicantumkan dalam log.

## Android App Links

Gunakan satu host HTTPS milik proyek uji. Isi `AUTH_EMAIL_LINK_HOST` sebagai variabel lingkungan Gradle dan sebagai `--dart-define=AUTH_EMAIL_LINK_HOST` di Flutter. Gunakan nilai host yang sama tanpa skema atau path. Sajikan `/.well-known/assetlinks.json` dari host tersebut untuk paket `com.kantincerdas.app` dan sidik jari SHA-256 sertifikat build yang dipasang. Verifikasi status domain dengan `adb shell pm get-app-links com.kantincerdas.app`. [Panduan verifikasi Android](https://developer.android.com/training/app-links/verify-applinks)

Shelf menyerahkan pilihan URL email registrasi dan kirim ulang ke Supabase. Template bawaan mengikuti **Site URL** di **Authentication → URL Configuration**. Uji perubahan template atau Site URL secara terpisah setelah pengiriman email sudah terbukti. [Redirect Supabase](https://supabase.com/docs/guides/auth/redirect-urls)

Gunakan URL berikut pada template Supabase. Ganti `auth.example.test` dengan host pengujian yang sebenarnya.

| Template | URL |
| --- | --- |
| Confirm signup | `https://auth.example.test/auth/verify-email?token_hash={{ .TokenHash }}` |
| Reset password | `https://auth.example.test/auth/reset-password?token_hash={{ .TokenHash }}` |
| Change email address | `https://auth.example.test/auth/change-email?token_hash={{ .TokenHash }}` |

Di **Authentication → Email Templates → Confirm signup**, gunakan `<a href="https://auth.example.test/auth/verify-email?token_hash={{ .TokenHash }}">Verifikasi email</a>`. Template ini menyerahkan token hash ke layar konfirmasi Kantin Cerdas. Aplikasi meminta Shelf memverifikasinya lewat Supabase setelah pengguna menekan konfirmasi. Kirim ulang email setelah konfigurasi berubah, karena email yang sudah dikirim masih memuat tautan lama.

Pada Android, buka tautan dan lakukan aksi konfirmasi di layar. Setelah pendaftaran email/password, konfirmasi email mendahului unggahan foto. Nama draft tersimpan di Supabase agar akun dapat melanjutkan pendaftaran setelah masuk kembali. Simpan host fallback tanpa pencatatan query token dan tanpa skrip pihak ketiga. [Template email Supabase](https://supabase.com/docs/guides/auth/auth-email-templates)

Terapkan migrasi pemeriksaan tautan reset sebelum merilis Shelf dan Flutter yang memakainya. Samakan `AUTH_RECOVERY_LINK_TTL_SECONDS` di Shelf dengan masa berlaku Email OTP di Supabase. Shelf memeriksa tautan tanpa mengonsumsinya ketika membuka formulir. Supabase Auth memeriksa ulang dan mengonsumsi tautan ketika password disimpan.

## Memeriksa pengiriman email hosted

Gunakan satu akun uji dan lihat statusnya di **Authentication → Users**. Untuk akun yang menunggu konfirmasi, catat waktu uji dan gunakan **Kirim ulang email** sekali. Cocokkan waktunya dengan `/auth/v1/resend` di Auth Logs atau Logs Explorer. Untuk percobaan pendaftaran sebelumnya, periksa `/auth/v1/signup`. HTTP 202 dari Shelf berarti permintaan diproses dengan respons netral. Periksa SMTP atau Send Email Hook untuk status pengiriman dan konfirmasikan pesan baru di kotak masuk akun uji. [Panduan diagnosis email Supabase](https://supabase.com/kb/troubleshooting/not-receiving-auth-emails-from-the-supabase-project-OFSNzw)

## Google dari browser Android

Tombol **Lanjutkan dengan Google** menggunakan alur OAuth browser dengan PKCE. Flutter membentuk `/auth/v1/authorize?provider=google` setara dengan alur `signInWithOAuth`, lalu membuka browser eksternal. `app_links` menerima `id.kantincerdas.oauth://auth/google` yang terdaftar di manifest. Flutter memeriksa `kc_state` dan mengirim kode beserta verifier melalui `POST /v1/auth/google/exchange`. Shelf menukarkannya dengan GoTrue dan memeriksa principal serta sesi. Web OAuth Client cukup untuk jalur ini. Grant ID token terpisah di `POST /v1/auth/google` dipakai oleh klien yang sudah memperoleh token Google melalui integrasi lain. [Google untuk Supabase](https://supabase.com/docs/guides/auth/social-sign-in/auth-google)

### Konfigurasi Google dan Supabase QA

1. **Google Cloud → Google Auth Platform → Clients → Web application → Authorized redirect URIs.** Salin URL callback dari halaman provider Google pada Dashboard Supabase **QA**. Untuk project URL standar, formatnya `https://<project-ref-QA>.supabase.co/auth/v1/callback`. Daftarkan URL HTTPS ini persis seperti yang ditampilkan Dashboard.
2. **Supabase QA → Authentication → Sign In / Providers → Google.** Aktifkan Google dan masukkan Web Client ID dan Web Client Secret dari langkah 1. Pertahankan pengaturan verifikasi provider. Jika aplikasi OAuth berstatus Testing, tambahkan akun penguji di Google Auth Platform → Audience. [Google untuk Supabase](https://supabase.com/docs/guides/auth/social-sign-in/auth-google)
3. **Supabase QA → Authentication → URL Configuration → Redirect URLs.** Tambahkan pola berikut (terverifikasi tersimpan di Supabase Dashboard). Pada glob wildcard Supabase, `?` mencocokkan 1 karakter non-separator (termasuk literal `?`) dan `*` mencocokkan nilai acak `kc_state`, sementara Flutter memvalidasi ulang exact scheme, host, path, dan `kc_state` pada `matchesGoogleRedirect`. Tambahkan pula `id.kantincerdas.oauth://auth/verify-email` untuk callback verifikasi email. [Redirect URLs](https://supabase.com/docs/guides/auth/redirect-urls)

   ```text
   id.kantincerdas.oauth://auth/google?kc_state=*
   id.kantincerdas.oauth://auth/verify-email
   ```

4. **Shelf QA.** Set `APP_ENV=staging`, `AUTH_GOOGLE_ENABLED=true` dan `SUPABASE_URL` proyek QA. Pakai kunci serta pengaturan JWT proyek QA. Dari direktori `app/`, jalankan dengan URL Shelf yang dapat dijangkau Android dan URL Supabase yang sama dengan Shelf.

   ```sh
   flutter run -d <ID_ANDROID> \
     --dart-define=API_BASE_URL="$KC_QA_SHELF_URL" \
     --dart-define=SUPABASE_URL="$KC_QA_SUPABASE_URL" \
     --dart-define=AUTH_GOOGLE_ENABLED=true
   ```

5. Masuk lewat browser, lalu periksa bahwa aplikasi menerima sesi Shelf dan membuka profil atau langkah foto sesuai akun yang dikonfirmasi. Jika browser kembali ke Site URL, periksa allowlist Supabase dan `kc_state`. Jika Google menampilkan `redirect_uri_mismatch`, cocokkan callback HTTPS Supabase dengan Authorized redirect URIs di Web Client. Jika aplikasi menampilkan Google belum tersedia, periksa flag di APK dan Shelf QA.

[KC-AUTH-AMEND-2026-11-20-01](development/Kantin_Cerdas_AUTH_005A_Amendment_Final/AMENDEMEN_AUTH_005_005A_2026-11-20.md) mengizinkan linking bawaan Supabase sesuai pemeriksaan provider. GoTrue dapat menautkan sebelum Shelf menerima kode. Shelf memeriksa identitas, sesi, status akun dan kepemilikan berdasarkan ID yang sah. Pertahankan Google nonaktif pada provider dan build produksi sampai A1–A4 lulus. Shelf juga menonaktifkan rute tersebut di `APP_ENV=production`. Verified App Links untuk tautan email mengikuti konfigurasi HTTPS terpisah di atas. [Identity linking](https://supabase.com/docs/guides/auth/auth-identity-linking)

## Skenario penerimaan

Jalankan [matriks A1–A4](development/08_Pengujian_dan_Kriteria_Penerimaan.md) pada proyek QA terisolasi setelah menerapkan migrasi canonical. Pertahankan konfirmasi email dan verifikasi provider. Nonaktifkan penautan manual dan opsi seperti skip nonce pada QA jika tersedia. Gunakan akun penguji terdaftar di Google Cloud.

1. **A1** — Buat akun password terverifikasi, lengkapi profil dan foto, serta siapkan relasi data melalui alur QA. Catat ID, profil, role, status dan relasi sebelum membuka login Google di Android. Uji PKCE dari APK. Periksa grant ID token memakai klien uji Google yang diotorisasi untuk proyek QA dan kirim ke `POST /v1/auth/google` dari runner lokal dengan `id_token`, `google_access_token`, serta `nonce` mentah jika digunakan untuk request Google. Gunakan nonce unik per upaya sesuai panduan Google/Supabase. Pastikan kedua respons merujuk ID yang sama, profil dan relasi tetap dimiliki ID tersebut dan login password masih bekerja.
2. **A2** — Buat akun Google-only di Android. Coba signup password, login dengan password percobaan, dan reset untuk email yang sama. Pastikan kueri QA menunjukkan satu akun dan akun itu tetap tanpa password otomatis. Ulangi dengan fixture terpisah yang mula-mula signup password tanpa konfirmasi, lalu login Google dengan email yang sama. Periksa perubahan identitas di Supabase dan pastikan password/tautan lama dan sesi yang belum sah tidak membuka data akun setelah perpindahan identitas.
3. **A3** — Pakai dua perangkat atau emulator dengan state terpisah. Jalankan signup email dan Google hampir bersamaan untuk email baru dan ulangi kedua urutan. Coba menyelesaikan profil dari kedua perangkat dengan sesi sah. Periksa satu ID, satu profil dan satu objek avatar kanonik. Pastikan semua sesi sah menunjuk ID yang sama dan role awal tetap Customer.
4. **A4** — Sajikan Digital Asset Links melalui HTTPS dengan sertifikat penandatangan APK aktual. Pada perangkat QA bersih jalankan `adb shell pm verify-app-links --re-verify com.kantincerdas.app`, tunggu verifikasi, lalu periksa `adb shell pm get-app-links com.kantincerdas.app`. Setelah host berstatus `verified`, buka signup, reset dan perubahan email dari klien email tanpa memilih paket lewat ADB. Uji cold start, tautan invalid, kedaluwarsa dan terpakai, kedua alamat konfirmasi, foto default/pengganti dan logout dua perangkat. [Panduan verifikasi Android](https://developer.android.com/training/app-links/verify-applinks)

Gunakan tampilan admin atau kueri terbatas proyek QA untuk membandingkan `auth.users.id`, entri provider dan sesi. Catat ada atau tidaknya password tanpa membaca/mencetak hash. Rekam ID tersamarkan, perangkat, build, metode, dan hasil. Pengujian lokal dengan host fixture atau skema callback Google membuktikan routing lokal. Status hosted memerlukan hasil verifikasi domain dan OAuth Google asli.

Untuk QA lokal, arahkan Shelf ke gateway Supabase pada `http://127.0.0.1:<port>`, set `APP_ENV=development` dan `SUPABASE_PROJECT_REF=local`, lalu gunakan JWT anon dan service role dari stack lokal. Atur `AUTH_JWT_AUDIENCE=authenticated`. Issuer dan URL layanan diturunkan dari `SUPABASE_URL` jika variabel URL masing-masing kosong. Pada emulator, arahkan build debug ke Shelf dengan `--dart-define=API_BASE_URL=http://10.0.2.2:<port-shelf>`. Matriks pengujian dan kriteria penerimaan tersedia di [08_Pengujian_dan_Kriteria_Penerimaan.md](development/08_Pengujian_dan_Kriteria_Penerimaan.md).
