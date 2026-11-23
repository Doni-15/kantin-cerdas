# UI Authentication — State, Navigasi, Penanganan Error, dan QA

**STATUS:** pola state/error telah diterima dalam brainstorming, **BELUM FINAL · LOCKED formal**. Layar Login tetap FINAL · LOCKED dan hierarkinya tidak boleh diubah.
**Tujuan:** melengkapi file-file layar tanpa menambahkan layar atau aturan bisnis baru.

## 1. Matriks state untuk semua layar

| State | Pola UI | Aturan |
|---|---|---|
| Default | Seluruh field, label, dan CTA sesuai file layar | Jangan tampilkan error sebelum kondisi terkait |
| Field wajib kosong | Pesan singkat di bawah field | Jangan menghapus isian field lain |
| Format email tidak valid | `Masukkan alamat email yang valid.` dekat Email | Jangan menyimpulkan email terdaftar/tidak |
| Loading aksi | Indikator kecil dalam CTA + label relevan, CTA itu mencegah submit berulang | Jangan replace halaman dengan fullscreen spinner untuk request sederhana |
| Login gagal | `Email atau password tidak sesuai. Periksa kembali dan coba lagi.` | Tidak mengungkap field mana yang salah |
| Internet putus | `Koneksi bermasalah. Periksa internetmu, lalu coba lagi.` | Input tetap ada; retry aman |
| Akun nonaktif | `Akun ini sedang dinonaktifkan dan tidak dapat digunakan untuk masuk.` | Berdasarkan status otoritatif backend, bukan tebakan UI |
| Sesi berakhir | `Sesi kamu telah berakhir. Silakan masuk kembali.` | Kembali Login; halaman privat terlindungi |
| Google dibatalkan pengguna | Kembali ke layar sebelum OAuth | Jangan memunculkan alert merah seolah error keamanan |
| Email belum verified | Tampilkan petunjuk Verifikasi Email | Tidak otomatis memberi izin checkout |
| Foto wajib belum terpenuhi | Error dekat pemilih foto | Placeholder tidak dihitung foto |
| Tautan reset invalid | Pesan jelas + `Minta tautan baru` | Jangan izinkan submit reset |
| Respons Auth tidak dikenal | Pesan aman yang bisa ditindaklanjuti | Jangan tampilkan stack trace/token atau error teknis mentah |

**Posisi error umum Login:** sesudah bagian Password dan tautan `Lupa password?`, **sebelum tombol Masuk**. Error hanya muncul ketika ada, tidak mengubah posisi link Lupa Password menjadi di bawah Masuk. Field-specific error tepat di bawah fieldnya.

## 2. Peta navigasi UI — konseptual, bukan nama route implementasi

| Asal | Tindakan | Tujuan yang diharapkan | Prasyarat sebenarnya |
|---|---|---|---|
| Login | `Daftar` | Daftar Langkah 1 | Tidak diperlukan login |
| Login | `Lupa password?` | Lupa Password | Tidak diperlukan login |
| Login | `Masuk` sah | Beranda sesuai role sah | Sesi, role, status akun valid dari server |
| Login | Google dibatalkan | Login | Tidak membuat sesi palsu |
| Daftar 1 | `Lanjutkan` email/password | Daftar Langkah 2 | Validasi UI; urutan simpan backend tidak diasumsikan |
| Daftar 1 | `Lanjutkan dengan Google` | Daftar Langkah 2 bila belum lengkap | Google identity sah, status profil belum lengkap |
| Daftar 2 | `Selesaikan Pendaftaran` email/password | Verifikasi Email | Foto valid dan alur pendaftaran sah |
| Daftar 2 | `Selesaikan Pendaftaran` Google | Lanjutan sesuai sesi/status | Foto valid dan akun sah |
| Verifikasi | `Saya sudah verifikasi` | Lanjutan bila verified | Status diperiksa lewat Auth/backend |
| Verifikasi | `Kirim ulang email` | Tetap layar + feedback | Batas provider berlaku |
| Lupa Password | `Kirim tautan reset` | Status instruksi terkirim | Respons aman, tanpa enumerasi akun |
| Tautan reset valid | Callback resmi | Buat Password Baru | Token/recovery sah |
| Buat Password Baru | `Simpan password baru` sukses | Konfirmasi sukses → Login | Reset sah dan tidak digunakan ulang |
| Tautan reset invalid | `Minta tautan baru` | Lupa Password | Tidak menerima token invalid |
| Logout atau sesi gagal dipulihkan | Keluar sesi | Login | Autentikasi benar-benar berakhir |

**Jangan mengarang** literal route (`/auth/...`), endpoint, nama tabel, token lifetime, atau nilai validasi password di sini. Implementasikan berdasarkan kontrak teknis resmi ketika tersedia.

## 3. Matriks identitas dan izin (batas UI)

- Pendaftaran publik default **Customer**, bukan menu pilih role.
- Owner dan Admin diarahkan menurut role **yang diverifikasi backend**; aplikasi tidak memberikan role berdasarkan tombol atau layar yang dipilih user.
- Email/password baru tidak otomatis dapat memesan sampai email telah terverifikasi sesuai AUTH-001.
- Foto profil wajib pada dua jalur registrasi; foto Google hanya default jika benar tersedia.
- Google-only pulih melalui Google; tidak buat password lokal otomatis.
- Konflik login provider/email (AUTH-005A) **BELUM terbukti selesai** dengan desain UI. UI boleh menampilkan error aman dari backend, tetapi tidak menjamin Supabase tidak otomatis link.

## 4. Pengujian layar konkret

| ID tes | Kondisi | Hasil harus tampak |
|---|---|---|
| L01 | Login 320dp light | Tidak overflow; seluruh aksi bisa diakses dengan scroll |
| L02 | Login dark + keyboard | Form jelas, tombol dan link tetap dapat dijangkau |
| L03 | Login saat error | Lupa password tetap kanan, error sebelum Masuk |
| L04 | Login Google cancel | Kembali ke form, tanpa state sukses palsu |
| L05 | Login dua kali cepat | Satu aksi loading, tidak ada submit ganda dari UI |
| R01 | Langkah 1 layar kecil | Semua 3 input + Google + Masuk dapat diakses |
| R02 | Langkah 2 tanpa foto | Tidak bisa menyelesaikan proses tanpa foto valid |
| R03 | Langkah 2 foto Google tersedia | Foto muncul default, dapat diselesaikan tanpa pilih ulang |
| R04 | Ganti foto Google | Konfirmasi muncul, batal mempertahankan foto semula |
| E01 | Verifikasi belum sukses | Tap Saya sudah verifikasi tidak mengaktifkan akun |
| E02 | Resend rate limited | Feedback benar, tidak mengirim terus menerus |
| P01 | Forgot email diketahui/tidak | Pesan publik tetap tidak mengekspos keberadaan akun |
| P02 | Reset token expired | Tidak bisa simpan; ada Minta tautan baru |
| P03 | Reset sukses | Konfirmasi dan tautan kembali Masuk |
| G01 | Setiap layar dark | Kontras memadai, tidak ada warna light hardcoded |
| G02 | Setiap layar text scaling besar | Tidak ada clipping/overflow teks |
| G03 | Setiap layar dengan keyboard/landscape | Area input/CTA dapat digulir/dijangkau |
| G04 | Tablet/web besar | Lebar kerja nyaman ±420dp, tidak split hero |
| G05 | Aksesibilitas | Label screen reader, fokus, tap target ≥48dp |

## 5. Checklist anti-halu sebelum pekerjaan UI dinyatakan selesai

- [ ] Komponen dibangun berdasarkan kode tema aktual, bukan warna hardcoded sketsa.
- [ ] Penggunaan logo asli dan logo Google resmi telah diverifikasi.
- [ ] Login menuruti **exact order** dari file 02; tautan Forgot Password kanan bawah Password.
- [ ] Daftar 2 langkah sama seperti file 03/04; foto wajib dan konfirmasi foto Google tersedia.
- [ ] Verifikasi hanya email-link; tidak ada form OTP tambahan.
- [ ] Forgot/reset sesuai file 06/07, tidak mengungkap keberadaan email.
- [ ] Tidak ada halaman error baru untuk tiap kondisi.
- [ ] Pengujian Light/Dark, Android kecil, iOS, tablet, keyboard, landscape, font besar dilaksanakan.
- [ ] Tidak ada nama route, endpoint, skema database, aturan password, status Auth, maupun solusi automatic linking yang diciptakan AI sendiri.
- [ ] Hanya Login memiliki status UI FINAL · LOCKED; lainnya adalah desain diterima dalam diskusi.

## 6. Apa yang tidak dinyatakan selesai oleh paket ini

- Suksesnya OAuth pada perangkat sungguhan.
- Kemampuan memulihkan draft pendaftaran lintas deep link/process death.
- Kesesuaian internal Supabase Auth dengan larangan linking AUTH-005A.
- Validasi session/role/status akun pada backend.
- Backend implementation, database migration, konfigurasi deep link, reset token handling.

**Semua itu harus mendapat kontrak dan pengujian integrasi tersendiri. Paket ini hanya mendefinisikan UI/UX yang sudah dibahas, bukan menjanjikan kemampuan backend yang belum dibuktikan.**
