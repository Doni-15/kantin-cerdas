# Auth Flutter — Tahap 01: pindah pembungkus navigasi akun

## Tujuan
Memindahkan class `HomeWithAccount` dari folder widget UI Auth ke folder navigasi app tanpa mengubah implementasinya.

## File yang berubah
- BARU: `lib/app/navigation/home_with_account.dart` — isi sama persis dengan file sebelumnya, byte-for-byte.
- DIUBAH: `lib/features/auth/presentation/widgets/home_with_account.dart` — sekarang hanya export kompatibilitas, sehingga import lama tetap berlaku.

Tidak mengubah `auth_view.dart`, controller, repository, session coordinator, OAuth, form, atau validasi.

## Batasan
Ini **belum** implementasi router pusat. `Stack`, `Offstage`, dan `PopScope` tetap sama. Perubahan rute/guard akan menjadi tahap terpisah setelah perilaku baseline diverifikasi.

## Pemasangan dari root app/ (setelah backup/commit)
```
git status --short
unzip -o /lokasi/auth_refactor_step_01.zip
flutter analyze
flutter test
git diff -- lib/features/auth/presentation/widgets/home_with_account.dart
git status --short
```

## Smoke test manual
1. Login akun customer; pastikan halaman customer terbuka.
2. Buka halaman akun dan kembali; pastikan state halaman sebelumnya tetap ada.
3. Ulangi buka/tutup halaman akun, dan tombol Back Android.
4. Logout lalu login kembali.
5. Jika mode preview owner tersedia, tes buka/tutup akun pada halaman owner.

Catatan: Flutter/Dart SDK dan full project tidak tersedia di lingkungan pengolahan ZIP, sehingga analyzer dan runtime tests harus dijalankan pada mesin proyek.
