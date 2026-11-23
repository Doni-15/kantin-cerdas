# UI-AUTH-002A — Pendaftaran Langkah 1 (Identitas)

**STATUS: Desain diterima pengguna; BELUM FINAL · LOCKED secara eksplisit.**
**Bisnis yang diikuti:** AUTH-001, AUTH-002, AUTH-005A. Jangan mengubah aturan tersebut lewat UI.

## 1. Tujuan

Mengambil informasi minimum untuk mendaftar dengan email/password, **atau** menggunakan identitas Google. Tidak ada nomor telepon, pemilihan role, NIM, fakultas, atau universitas.

## 2. Susunan vertikal yang disetujui

1. Tombol panah **Kembali** di kiri atas; label **`Langkah 1 dari 2`** di kanan atas.
2. Indikator progres **2 segmen**: segmen pertama aktif (primary), kedua netral.
3. Heading tengah **`Buat akun`**.
4. Subtitle tengah **`Isi informasi dasar untuk memulai.`**
5. Label+input `Nama lengkap` — hint `Nama lengkap kamu`.
6. Label+input `Email` — hint `nama@email.com`.
7. Label+input `Password` — hint `Buat password`, kontrol mata di kanan input.
8. Primary full-width **`Lanjutkan`**.
9. Divider garis halus **`atau`**.
10. Outlined full-width **`Lanjutkan dengan Google`** dengan identitas Google resmi.
11. Footer tengah **`Sudah punya akun? Masuk`**.

Tidak perlu logo besar pada layar ini. Gunakan permukaan latar netral, tanpa card besar atau ilustrasi.

## 3. Ketentuan interaksi

| Kejadian | Respons UI |
|---|---|
| Data email/password lengkap dan valid secara UI | `Lanjutkan` membuka Langkah 2; pembuatan akun final tetap mengikuti alur integrasi yang sah |
| Salah satu field kosong/format email keliru | Error dekat field; pertahankan nilai lain |
| Password tidak sesuai kebijakan backend | Tampilkan pesan dari kebijakan yang nyata, jangan mengarang panjang minimum |
| Tekan Google | Jalankan OAuth yang sebenarnya; apabila perlu melengkapi foto, lanjut Langkah 2 |
| Google dibatalkan | Kembali pada langkah semula tanpa dialog error berlebihan |
| Kembali ke Login | Tampilkan Login yang sudah LOCKED, bukan layar metode login baru |
| Kembali dari Langkah 2 | Pulihkan input non-rahasia dari draft alur aktif bila tersedia; password tidak boleh disimpan persisten secara tidak aman |
| Konflik metode/email | Gunakan respons aman dari backend; UI bukan pembukti pencegahan automatic linking |

**Penting:** Dua langkah berarti **dua tahap pengalaman pengguna**, bukan jaminan dua transaksi backend tertentu. Kapan akun tercipta/foto diunggah adalah urusan desain Auth backend yang sah; jangan diimprovisasi dari dokumen ini.

## 4. Responsivitas dan Dark Mode

- Satu kolom dengan lebar max ±420dp, padding horizontal berdasar tema.
- Dua segmen progres menggunakan warna semantik theme, bukan warna statis mockup.
- Layar kecil + keyboard: dapat scroll sampai tombol Lanjutkan/Google dan link Masuk.
- Dark Mode mempertahankan layout, hanya permukaan/teks/border/CTA berubah mengikuti `KcTheme.dark`.

## 5. Acceptance criteria

- [ ] Urutan 1–11 sesuai; tidak ada field tambahan atau pemilihan role.
- [ ] Password eye toggle, Google alternate CTA, kembali dan progress berfungsi.
- [ ] Loading/validasi/error tidak membuang draft yang dapat dipertahankan secara aman.
- [ ] Light/Dark, HP kecil, tablet, landscape, keyboard, text scaling lulus.
