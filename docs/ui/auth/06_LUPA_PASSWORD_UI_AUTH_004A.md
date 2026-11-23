# UI-AUTH-004A — Lupa Password / Permintaan Tautan Reset

**STATUS: Desain diterima pengguna; BELUM FINAL · LOCKED secara eksplisit.**
**Bisnis yang diikuti:** AUTH-004. Google-only menggunakan pemulihan Google; Admin tidak reset password manual.

## 1. Fungsi

Pengguna meminta tautan penggantian password **berbasis email**. Layar ini **bukan** halaman untuk memasukkan password baru dan bukan form OTP.

## 2. Hierarki layar (atas → bawah)

1. Tombol kembali, konteks kecil **`Pemulihan akun`**.
2. Heading tengah **`Lupa password?`**.
3. Deskripsi tengah: **`Masukkan alamat email akunmu. Kami akan mengirim tautan untuk mengatur ulang password.`**
4. Label field **`Email`**, hint **`nama@email.com`**.
5. Primary full-width **`Kirim tautan reset`**.
6. Footer **`Ingat password? Masuk`** dengan tautan aktif `Masuk`.

Tidak perlu logo ulang, ilustrasi besar, card pembungkus form, tautan OTP atau nomor telepon.

## 3. Interaksi dan state

| Aksi/kondisi | Perilaku UI |
|---|---|
| Email kosong/format salah | Error dekat input; jangan kirim request yang jelas invalid |
| Tekan Kirim tautan reset | Loading di CTA, cegah submit berulang |
| Permintaan diterima untuk diproses | Tampilkan kalimat **netral**: `Jika alamat email terdaftar dan mendukung pemulihan password, instruksi pemulihan akan dikirim.` |
| Email tidak terdaftar | Jangan mengungkap keberadaan akun melalui pesan berbeda |
| Akun Google-only | Tidak menawarkan pembuatan password lokal; rujuk pemulihan Google bila metode diketahui secara sah |
| Internet gagal | Tampilkan error jaringan, pertahankan input |
| Tekan Masuk/Kembali | Kembali ke Login yang sudah LOCKED |

State email dikirim cukup pemberitahuan dalam pengalaman pemulihan yang sama; **tidak wajib membuat halaman baru** hanya untuk pesan konfirmasi.

## 4. Persyaratan display

- Input 1 kolom, max-width ±420dp, warna dari tema, target 48dp.
- Footer bisa scroll pada HP kecil; tidak fixed di bawah keyboard.
- Kontras dan feedback identik fungsinya di Light/Dark.

## 5. Acceptance criteria

- [ ] Urutan sesuai §2 dan tidak ada field password di layar permintaan.
- [ ] Feedback tidak mengungkap apakah akun email ada.
- [ ] Submit, loading, error offline, back ke Login diuji.
- [ ] Tema gelap dan font besar tidak merusak layout.
