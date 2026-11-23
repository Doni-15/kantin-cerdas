# UI-AUTH-003 — Verifikasi Email

**STATUS: Desain diterima pengguna; BELUM FINAL · LOCKED secara eksplisit.**
**Bisnis yang diikuti:** AUTH-001 (verifikasi email/password sebelum boleh memesan); bukan verifikasi email lokal ulang untuk Google Sign-In.

## 1. Kapan layar ditampilkan

Setelah alur pendaftaran **email/password** memerlukan konfirmasi alamat email. Backend/Auth tetap menjadi sumber status verifikasi; UI tidak dapat menandai akun verified sendiri.

## 2. Hierarki layar yang disetujui (atas → bawah)

1. Tombol kembali; konteks kecil **`Verifikasi email`**.
2. Simbol status email kecil (mis. `mail-check`) dalam lingkaran/container lembut tema; bukan ilustrasi besar.
3. Heading tengah **`Cek email kamu`**.
4. Deskripsi tengah **`Kami telah mengirim tautan verifikasi ke alamat email berikut.`**
5. Alamat email sesungguhnya ditampilkan dalam container/outline ringkas, bukan alamat contoh saat runtime.
6. Instruksi tengah **`Buka email dan tekan tautan verifikasi untuk mengaktifkan akunmu.`**
7. Tombol utama **`Saya sudah verifikasi`** full-width.
8. Teks **`Belum menerima email?`** dan tautan **`Kirim ulang email`**.
9. Tindakan bawah **`Kembali ke Masuk`**.

## 3. Kontrak perilaku UI

| Aksi/kondisi | Perilaku yang boleh dilakukan |
|---|---|
| Tekan Saya sudah verifikasi | **Meminta pengecekan** status asli ke Auth/backend; jangan set verified lokal |
| Email belum benar-benar verified | Tetap layar ini dengan petunjuk; jangan membuka checkout |
| Verifikasi sah | Arahkan berdasarkan sesi, profil, dan izin aktual |
| Kirim ulang email | Request melalui Auth yang sah; tampilkan loading serta hasil, patuhi limit dari provider |
| Tautan email membuka aplikasi | Proses callback/deep link sesuai integrasi resmi; status harus diverifikasi |
| Tautan kedaluwarsa/tidak valid | Pesan ringkas + kirim ulang atau kembali Login |
| Offline | Pesan koneksi, retry, jangan klaim verifikasi berhasil |

Tidak ada input OTP 6 digit; verifikasi dilakukan dengan **tautan email**, bukan kode yang diketik manual.

## 4. Dark Mode & responsive

- Kolom tunggal, heading/tulisan tengah, target 48dp, max-width ±420dp.
- Alamat email panjang **wrap atau ellipsize secara aman dengan aksesibilitas**, jangan merusak layout atau menghilangkan akses melihat alamat lengkap.
- Tombol resend tetap memiliki touch target 48dp dan tidak tampak seperti teks tidak interaktif.
- Warna ikon/container/error/resend harus memakai ColorScheme light/dark nyata.

## 5. Acceptance criteria

- [ ] Tampilan sesuai urutan 1–9; tidak ada layar input OTP.
- [ ] Tindakan `Saya sudah verifikasi` tidak mengubah status secara lokal.
- [ ] Resend dibatasi oleh Auth; invalid link memiliki jalan keluar.
- [ ] Email panjang, Light/Dark, keyboard, layar kecil dan font besar tidak overflow.
