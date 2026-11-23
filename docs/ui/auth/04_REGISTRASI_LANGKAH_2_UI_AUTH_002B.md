# UI-AUTH-002B — Pendaftaran Langkah 2 (Foto Profil)

**STATUS: Desain diterima pengguna; BELUM FINAL · LOCKED secara eksplisit.**
**Bisnis yang diikuti:** AUTH-002 (foto wajib; foto Google default; penggantian foto Google perlu konfirmasi).

## 1. Tujuan

Memastikan pengguna melengkapi **foto profil yang valid**. Avatar placeholder **tidak** dihitung sebagai foto pengguna. Tidak ada tombol skip.

## 2. Susunan vertikal yang disetujui

1. Panah kembali kiri atas; **`Langkah 2 dari 2`** kanan atas.
2. Progres dua segmen, **keduanya aktif** memakai warna primary dari tema.
3. Heading rata tengah **`Lengkapi profil`**.
4. Subtitle tengah **`Satu langkah lagi, tambahkan foto profilmu.`**
5. Preview **avatar bulat** berukuran menonjol tetapi tidak mendominasi layar; menggunakan foto terpilih, foto Google, atau placeholder netral.
6. Tombol outlined/secondary **`Pilih foto profil`** dengan ikon kamera fungsional.
7. Keterangan **`Foto profil wajib untuk menyelesaikan pendaftaran.`**
8. Primary full-width **`Selesaikan Pendaftaran`**.
9. Keterangan **`Foto dapat diubah kembali melalui profil.`**

**Tidak ada:** tombol Lewati, input tambahan, kartu besar, foto makanan, progress tambahan.

## 3. Perilaku yang wajib

| Kondisi | Perilaku UI |
|---|---|
| Daftar email/password, belum ada foto | Placeholder netral; aksi selesai **tidak boleh** berhasil seolah foto ada |
| Google menyediakan foto profil | Foto Google menjadi **default dan terlihat** di avatar; dapat menyelesaikan alur tanpa memilih ulang |
| Google tidak menyediakan foto | Minta foto dari perangkat; placeholder tidak lolos |
| Pengguna memilih foto | Tampilkan preview; bisa memilih ulang sebelum menyelesaikan |
| Pengguna mengganti foto Google | **Tampilkan konfirmasi** sebelum mengganti; jika batal, tetap memakai foto Google |
| Pemilihan atau unggah gagal | Tampilkan error dekat kontrol foto; sediakan retry, jangan hilangkan semua data langkah sebelumnya |
| Tekan Kembali | Kembali ke Langkah 1 sesuai keadaan alur; pertahankan draft non-sensitif yang aman |
| Tekan Selesaikan | Proses dengan loading aman; setelah berhasil, arahkan ke verifikasi email atau alur Google **berdasarkan kondisi sebenarnya** |

**Peringatan:** Foto default Google hanya boleh dianggap ada jika URL/foto benar-benar tersedia dan dapat digunakan secara sah. Jangan menganggap avatar placeholder, inisial, atau foto gagal dimuat sebagai foto wajib yang sudah dipenuhi.

## 4. Konfirmasi mengganti foto Google

- Pesan ringkas yang jelas, misalnya **`Ganti foto profil dari Google?`**
- Aksi lanjutkan penggantian dan aksi batal.
- Gunakan bentuk dialog/bottom sheet yang sudah didefinisikan tema; **jangan membuat alur multi-langkah baru**.
- Rincian copy dialog selain maksud konfirmasinya adalah **default UX penjelas, bukan kutipan naskah persetujuan eksplisit**.

## 5. Responsivitas dan tema

- Avatar selalu menjaga aspect ratio, tidak terpotong, dan tidak meluap di HP kecil.
- Tombol pilih foto dan selesaikan terjangkau saat layar pendek, keyboard atau text scaling.
- Light/Dark punya layout dan status yang sama; warna placeholder/container dari semantik tema.

## 6. Acceptance criteria

- [ ] Progres langkah 2 benar; foto wajib; tidak ada skip.
- [ ] Foto Google otomatis sebagai default jika tersedia; perubahan memunculkan konfirmasi.
- [ ] Hasil foto dilihat dahulu melalui preview; kegagalan upload punya feedback.
- [ ] Komponen dan ukuran aman pada Light/Dark dan layar kecil/besar.
