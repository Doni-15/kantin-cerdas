# UI-AUTH-004C — Buat Password Baru

**STATUS: Desain diterima pengguna; BELUM FINAL · LOCKED secara eksplisit.**
**Bisnis yang diikuti:** AUTH-004. Tautan reset wajib aman, memiliki masa berlaku, sekali pakai; implementasi keabsahan token merupakan tugas Auth/backend.

## 1. Prasyarat membuka layar

Layar input password baru **hanya** ditampilkan setelah alur callback/recovery Auth menentukan bahwa tautan reset valid. **Jangan** mengaktifkan form reset hanya berdasarkan query string URL yang belum diverifikasi.

## 2. Hierarki layar (atas → bawah)

1. Tombol kembali dan konteks **`Reset password`**.
2. Heading tengah **`Buat password baru`**.
3. Subtitle tengah **`Gunakan password baru untuk mengamankan akunmu.`**
4. Field **`Password baru`** dengan show/hide kanan.
5. Field **`Konfirmasi password`** dengan show/hide kanan.
6. Primary full-width **`Simpan password baru`**.

Tidak ada kolom password lama, reset oleh Admin, OTP manual, atau ilustrasi besar.

## 3. State dan aksi

| Keadaan | Tindakan UI |
|---|---|
| Salah satu field kosong | Error di bawah field terkait |
| Password dan konfirmasi berbeda | Error yang menjelaskan keduanya tidak cocok |
| Kebijakan password tidak terpenuhi | Tampilkan kebijakan **yang benar-benar digunakan oleh Auth/backend**; jangan mengarang minimal panjang |
| Menekan simpan | Loading di CTA; cegah submit ganda; backend memutuskan hasil |
| Berhasil diperbarui | Pesan **`Password berhasil diperbarui`** dan tindakan kembali **Masuk** |
| Tautan invalid/expired/terpakai | Form tidak melakukan reset; pesan jelas + tindakan **`Minta tautan baru`** |
| Offline/API gagal | Error singkat dan kesempatan coba lagi secara aman |

Untuk akun Google-only, pemulihan dilakukan melalui Google; jangan menciptakan password email/password secara otomatis.

## 4. Kontrak visual

- Satu kolom, heading tengah, label input kiri, eye toggle fungsional.
- Border, error, fokus, disabled dan tombol dari `KcTheme`.
- Success/invalid-link cukup state informatif dan tombol aksi, tanpa layar selebrasi/dekorasi yang tidak disetujui.
- Light/Dark sama dari sisi fungsi dan urutan; keyboard/landscape/text scale teruji.

## 5. Acceptance criteria

- [ ] Tautan invalid tidak bisa mengaktifkan penggantian password.
- [ ] Field Password Baru + Konfirmasi punya toggle dan error cocok/tidak cocok.
- [ ] Tidak ada kebijakan password atau field baru ciptaan AI.
- [ ] Sukses mengarahkan kembali untuk login; link invalid memberi pemulihan.
- [ ] Keduanya terlihat dan bisa dioperasikan pada Light/Dark, HP kecil, dan tablet.
