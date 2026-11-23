# UI-AUTH-001 — Halaman LOGIN

**STATUS: FINAL · LOCKED atas permintaan eksplisit pengguna.**
**Sumber visual:** rancangan Login minimalis yang telah direvisi dan disetujui (lupa password dipindahkan ke **kanan bawah field Password**, bukan bawah tombol Masuk).
**Wajib membaca:** `00_README_MULAI_DI_SINI.md`, `01_DESIGN_SYSTEM_RESPONSIVE.md`, `08_STATE_NAVIGASI_PENGUJIAN.md`.

## 1. Tujuan dan cakupan

Login via **email/password** atau **Google**; tautan daftar dan pemulihan password. Tidak ada pilihan role, kode OTP, pemilihan kampus atau ilustrasi/promosi. Keberhasilan sesi/role adalah keputusan Auth/backend, bukan sekadar transisi visual.

## 2. Hierarki yang tidak boleh diubah (atas → bawah)

| Urutan | Elemen | Teks/ketentuan yang harus sama |
|---|---|---|
| 1 | Logo | **Logo asli Kantin Cerdas** rata tengah; satu logo, tidak dominan |
| 2 | Heading | **`Selamat datang kembali`** rata tengah |
| 3 | Subtitle | **`Masuk ke akunmu`** rata tengah |
| 4 | Field 1 | Label **`Email`** rata kiri; hint **`nama@email.com`** |
| 5 | Field 2 | Label **`Password`** rata kiri; hint **`Masukkan password`**; eye toggle kanan |
| 6 | Link | **`Lupa password?`** rata **KANAN**, tepat di bawah Password dan **SEBELUM** Masuk |
| 7 | Primary CTA | **`Masuk`**, filled primary, full-width |
| 8 | Divider | Garis tipis — **`atau`** — garis tipis |
| 9 | Google CTA | **`Lanjutkan dengan Google`**, outlined full-width dan logo Google resmi |
| 10 | Footer | **`Belum punya akun? Daftar`** rata tengah; hanya `Daftar` berupa link aktif |

**Wireframe urutan (bukan perintah membuat UI ASCII):**

```text
             [LOGO ASLI]
     Selamat datang kembali
           Masuk ke akunmu

Email
[nama@email.com                        ]
Password
[Masukkan password               [MATA]]
                        Lupa password?

[                  Masuk               ]
----------------- atau -----------------
[     (Google) Lanjutkan dengan Google  ]

         Belum punya akun? Daftar
```

## 3. Geometri dan visual

- Halaman memakai background `colorScheme.surface`; tidak memakai card besar.
- Konten satu kolom dengan max-width sekitar 420 logical px, tengah pada tablet/desktop.
- Logo terpusat dan proporsional; **ukuran logo harus mengikuti rasio aset asli**. Spasi header tidak berlebihan pada HP pendek.
- Judul: `headlineLarge` dan deskripsi: `bodyMedium` dari tema. Label dan isi kontrol mengikuti `KcTheme`.
- Input mengikuti `InputDecorationTheme`, bukan border manual. Tidak ada ikon email atau gembok sebagai dekorasi.
- Tombol `Masuk` memakai `FilledButtonTheme`/primary; `Google` memakai `OutlinedButtonTheme`; minimum target sentuh 48dp.
- `Lupa password?` tetap **satu baris di sisi kanan** jika ruang memungkinkan, dengan target sentuh ≥48dp; jika teks besar, boleh wrap secara aksesibel tanpa memindahkan link ke bawah tombol Masuk.
- Footer di bawah Google dengan jarak yang nyaman; **bukan fixed-bottom** yang menumpuk keyboard.
- Identitas visual seluruhnya berdasarkan `KcTheme.light/dark`, tidak hardcode warna contoh sketsa.

## 4. Perilaku komponen

| Aksi/kondisi | Tindakan UI | Batasan |
|---|---|---|
| Email fokus | Keyboard email; autofill diizinkan | Jangan hapus isian saat gagal |
| Password fokus | Input tersamar, password manager/autofill | Jangan simpan password ke preferensi biasa |
| Eye toggle | Lihat/sembunyikan password | Tidak mengganti/menghapus isi password |
| Tekan Masuk | Validasi dasar UI, loading di tombol dan cegah double-tap | Server/Auth memutuskan sah/tidak |
| Tekan Google | Proses autentikasi Google dari integrasi sebenarnya | Google cancel bukan login berhasil |
| Tekan Lupa password? | Buka UI `06_LUPA_PASSWORD_UI_AUTH_004A.md` | Tautan tepat di posisi LOCKED |
| Tekan Daftar | Buka UI `03_REGISTRASI_LANGKAH_1_UI_AUTH_002A.md` | Tidak tambah layar pemilih metode |
| Login gagal | Feedback di form, email tetap terisi | Jangan bocorkan apakah email ada |
| Sesi sah | Arahkan berdasarkan role/status yang diverifikasi | Jangan meminta user memilih role saat login |

## 5. State layar

- Default: input kosong, tombol utama tersedia sesuai validasi yang digunakan.
- Field invalid: error ringkas di bawah field yang keliru (lihat file 08).
- Credentials invalid: pesan umum di area form, bukan dialog atau halaman baru.
- Loading: CTA `Sedang masuk...`, satu proses aktif, tidak double-submit.
- Network: pesan koneksi, retry aman, input tetap.
- Akun nonaktif/sesi expired: tampilkan pesan aman sesuai kondisi yang benar-benar diterima dari backend.
- Google dibatalkan: kembali ke form tanpa error alarm besar.

## 6. DILARANG mengubah tanpa persetujuan eksplisit

- Pindah posisi `Lupa password?` ke sebelah label Password atau ke bawah tombol Masuk.
- Ubah heading, tambah slogan tambahan, tambah banner ilustrasi, card form besar, ikon input dekoratif, opsi pilihan role, OTP manual, login Apple, atau nomor HP.
- Buat versi dark yang memiliki urutan berbeda.
- Otomatis menautkan identitas atau memutuskan izin checkout dari state Flutter.

## 7. Acceptance criteria layar

- [ ] Elemen 1–10 mengikuti urutan di §2.
- [ ] Heading/subtitle tengah; field kiri; forgot password **kanan bawah field**.
- [ ] Tombol Masuk dan Google full-width dengan standar tema, Google official branding.
- [ ] Password visibility, autofill, keyboard submit, loading/error, cancel Google berfungsi sesuai UI.
- [ ] Light/Dark identik secara struktur, berbeda berdasarkan ColorScheme.
- [ ] Layar sempit, keyboard, landscape, text scale tidak overflow.
- [ ] Tidak muncul elemen di luar spesifikasi ini.
