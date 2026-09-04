# Panduan Kontribusi KantinCerdas

Dokumen ini mengatur cara tim mengembangkan KantinCerdas secara konsisten.

## Alur kerja Git

Commit fondasi pertama boleh dikirim langsung ke `main` karena repository masih kosong. Setelah itu, seluruh perubahan wajib menggunakan branch dan Pull Request.

1. Sinkronkan branch `main`.
2. Buat branch untuk satu pekerjaan terfokus.
3. Kerjakan dan uji perubahan.
4. Commit menggunakan Conventional Commits.
5. Push branch ke GitHub.
6. Buat Pull Request menuju `main`.
7. Periksa diff Pull Request dan merge hanya setelah CI lulus. Jangan mencatat
   review manusia kecuali review tersebut benar-benar tersedia di GitHub.

## Nama branch

```text
feat/catalog-search
feat/order-status
fix/cart-total
docs/update-roadmap
chore/update-ci
test/order-state
```

Gunakan huruf kecil dan tanda hubung. Hindari nama seperti `fitur-baru`, `coba`, atau `doni-branch` karena tidak menjelaskan pekerjaannya.

## Conventional Commits

```text
feat: add menu search interface
fix: correct cart total calculation
docs: clarify preorder scope
chore: configure Flutter CI
test: add order status widget test
```

Jenis commit yang digunakan:

- `feat`: fitur baru.
- `fix`: perbaikan bug.
- `docs`: perubahan dokumentasi.
- `style`: format tanpa mengubah perilaku.
- `refactor`: restrukturisasi tanpa fitur atau perbaikan bug.
- `test`: penambahan atau perubahan test.
- `chore`: konfigurasi dan pekerjaan pemeliharaan.
- `ci`: perubahan workflow CI.

## Pemeriksaan wajib

Jalankan dari folder `apps/mobile` sebelum membuat Pull Request:

```bash
flutter pub get
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

## Aturan perubahan UI

- Mengikuti design system Kantin Kampus Praktis.
- Mengutamakan grouped list dan divider; kartu, border, serta shadow hanya dipakai ketika membantu struktur.
- Menampilkan floating assistant hanya pada Beranda dan Detail Stan sesuai state yang dikunci.
- Menyertakan screenshot 390 dp dan satu lebar pembanding pada Pull Request jika tampilan berubah.
- Diperiksa pada lebar 360, 390, dan 412 dp, text scale besar, keyboard, dan reduced motion jika relevan.
- Memiliki keadaan loading, kosong, berhasil, gagal/retry, offline, dan disabled jika relevan.
- Tidak mengaktifkan fitur yang hanya terlihat pada mockup tetapi belum tercantum di Mini-SRS.
- Tidak menaruh logika bisnis besar langsung di widget.

## Keamanan repository

- Jangan commit `.env`, token, password, API key, atau signing key.
- Jangan memasukkan credential ke screenshot atau log.
- Gunakan `.env.example` untuk mendokumentasikan nama variabel.
- Laporkan credential yang terlanjur terunggah agar segera dicabut.

## Versi dan tag

- Fitur baru menaikkan versi minor. Perbaikan selama tahap alpha/beta dapat
  menaikkan nomor prerelease; setelah stabil, perbaikan menaikkan patch.
- Tag hanya dibuat dari commit di `main` setelah Flutter CI untuk commit tersebut
  berhasil.
- Tag rilis bersifat immutable: jangan memindahkan, mengganti, atau force-push
  tag yang sudah diterbitkan.
- Nilai versi di `pubspec.yaml` belum otomatis menjadi rilis.
- Release notes disiapkan di `docs/releases`, lalu GitHub Release alpha/beta/rc
  diterbitkan sebagai prerelease.
- Flutter CI tidak membuat tag atau Release. Tidak ada workflow hard-coded per
  versi yang aktif.

Kebijakan dan riwayat lengkap tersedia di
[`docs/releases/README.md`](docs/releases/README.md).
