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
7. Merge hanya setelah review dan CI lulus.

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
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug
```

## Aturan perubahan UI

- Mengikuti design system Kantin Hangat.
- Menyertakan screenshot pada Pull Request.
- Diperiksa pada lebar 360, 390, dan 412 dp.
- Memiliki keadaan loading, kosong, berhasil, dan gagal jika relevan.
- Tidak menaruh logika bisnis besar langsung di widget.

## Keamanan repository

- Jangan commit `.env`, token, password, API key, atau signing key.
- Jangan memasukkan credential ke screenshot atau log.
- Gunakan `.env.example` untuk mendokumentasikan nama variabel.
- Laporkan credential yang terlanjur terunggah agar segera dicabut.

## Versi dan tag

- Fitur baru menaikkan versi minor.
- Perbaikan bug menaikkan versi patch.
- Tag hanya dibuat dari commit di `main`.
- Nilai versi di `pubspec.yaml` belum otomatis menjadi rilis.
- Rilis sah setelah release gate dan CI lulus, lalu tag serta GitHub Release dibuat.
