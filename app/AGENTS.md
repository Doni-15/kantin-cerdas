# Kantin Cerdas — Aturan Khusus Flutter (`app/`)

**Berlaku untuk semua file di `app/`.** Baca juga `../AGENTS.md` (root repo). Bila ada pertentangan, larangan keamanan dan perubahan perilaku dari root tetap berlaku. Aturan ini memperinci tanggung jawab Flutter, bukan mandat membuat folder baru.

## 1. Fokus dan tujuan

- Flutter Android-first, tetap responsif dan kompatibel dengan platform lain yang didukung proyek.
- Pada tugas **AUTH-only**, scope utama `lib/features/auth/**`, `lib/app/**` yang memang berkaitan dengan Auth, serta test Auth terkait. `main.dart` hanya boleh disentuh jika integrasi nyata memerlukannya. Jangan merombak `catalog/`, `owner/`, `theme/`, `widgets/` global, atau backend; adaptasi referensi minimal harus dicatat.
- **Tujuan bukan mengecilkan file**, melainkan membuat routing, UI, state, use-case, repository, dan platform integration mudah ditemukan tanpa saling mengambil tanggung jawab.
- Jangan mengubah visual yang telah dikunci: warna, spacing, teks, layout, animasi, transition, validasi, loading/error, responsivitas, dan aksesibilitas.

## 2. Ownership dan dependensi

| Tempat | Memiliki tanggung jawab | Bukan tanggung jawabnya |
| --- | --- | --- |
| `lib/app/` | Bootstrap, composition root, route registry, app-level navigation, app gate, lifecycle integration lintas fitur | Melakukan HTTP langsung, parsing Supabase, implementasi login/reset, membangun form rumit |
| `lib/features/auth/presentation/pages/` | Halaman utuh dan interaksi UI level halaman | Mendefinisikan kebijakan redirect global atau memproses token secara langsung |
| `.../presentation/forms/`, `dialogs/`, `widgets/` | Form, dialog, komponen UI yang punya alasan perubahan jelas; state UI lokal (`TextEditingController`, focus, animasi) | Own global session, network/session persistence |
| `.../application/` | Auth state, koordinasi operasi/use-case, login/logout/recovery, kebijakan pemulihan dan aksi profil | Menggambar UI, mengakses widget context untuk network workflow |
| `.../data/` | Repository implementation, API, DTO, token/session storage, OAuth adapters, avatar platform picker, error translation | Membuat keputusan navigasi atau mengimpor presentation |
| `lib/core/`, `lib/widgets/` | Hal yang sungguh reusable lintas fitur | Membuang semua helper Auth ke folder global |

- Arah umum: `app → presentation/application`, `presentation → application` (UI boleh memakai provider), `application → data/contracts`, `data → platform/network`. Jangan menciptakan import balik dari data ke UI atau siklus provider.
- UI bisa memanggil repository langsung **hanya jika arsitektur aktual secara sadar mengizinkannya dan tanggung jawabnya jelas**; pada refactor Auth, utamakan application-facing use-case untuk proses yang mengubah sesi/akun. Jangan membuat satu `AuthController` baru untuk setiap tombol.
- Satu owner sesi global; **jangan** mengulang refresh, lock web, account-switch logic, atau listener di dua tempat.

## 3. Routing dan navigasi — masalah utama pada AUTH

- Audit dahulu `lib/app/auth_view.dart`, `lib/main.dart`, `features/auth/presentation/widgets/home_with_account.dart` atau hasil pemindahannya, `auth_email_link_view.dart`, splash, serta pemanggil navigasi.
- Target desain **bila memang diperlukan**: `app/router/` mendaftarkan route dan keputusan perpindahan tingkat aplikasi; app gate menentukan tampilan awal berdasar state Auth; halaman Auth hanya merender dan mengirim aksi. `app/router/` bukan tempat mengimplementasikan login atau session refresh.
- **Bukan wajib memasang `go_router` atau membuat deklarasi named routes**. Boleh memakai `Navigator` bawaan atau desain existing bila menjaga perilaku lebih aman. Jangan memaksakan library baru.
- Sebelum mengganti `Stack`/`Offstage`/`PopScope` dengan `Navigator`, catat dan uji preservasi state halaman, tombol Back Android, restoration yang ada, nested overlays, loading, dan transisi. Ini **bukan sekadar pemindahan kode**.
- Route guard di client adalah UX gating, **bukan** pengganti otorisasi backend. Perubahan role/status harus tetap mengikuti data sesi tepercaya.
- Pertahankan deep link masuk saat foreground/background, replay/consumption, Google PKCE/state, dan session recovery.

## 4. Aturan pemisahan code yang benar

1. Mulai dari **peta kepemilikan**: list halaman, state owner, listener, routing, I/O, dan dependensi. Baca isi aktual, bukan tebak nama file.
2. Kelompokkan **per tanggung jawab** yang mempunyai alasan perubahan sendiri. Jangan memecah `build()` menjadi banyak file tanpa manfaat navigasi arsitektur.
3. Sintaks penghubung minimal (import, export, delegasi, constructor, route registration) boleh diubah saat memindahkan ownership. Kondisi, event order, `await`, retry, error, session token, state transitions, teks, dan layout tetap identik secara perilaku.
4. Jangan menganggap memindahkan satu widget + export shim sebagai **refactor navigasi selesai**. Bila hanya langkah kompatibilitas, jelaskan apa yang belum diekstrak dan mengapa.
5. Gunakan `part`/`part of` hanya bila scope private bersama punya alasan kuat. `part` untuk memecah ukuran file tanpa memisahkan tanggung jawab bukan solusi utama.
6. Hindari wrapper passthrough, 1 class per kontrol trivial, file `utils.dart` raksasa, atau penumpukan import lintas fitur.
7. Jangan menghapus compatibility export sebelum semua import referensinya diketahui dan tes selesai.

## 5. Guardrail Auth yang harus tetap sama

- Registrasi dua langkah, verifikasi email dan tautan, Google Sign-In, login, logout, reset password, perubahan email/password, foto wajib, perbarui profil.
- Supabase identity linking yang sah, bukan linking custom; one in-flight refresh, session ownership tunggal, web session lock, account switching, deep link acceptance, retry, dan error mapping.
- Riverpod 3: jangan membuat circular dependency antara notifier dan derived provider; periksa lifecycle disposal, `ref.watch` vs `ref.read`, dan race saat rebuild.
- Status akun/role tidak diputuskan dari input Flutter; keputusan final tetap backend.

## 6. Baseline, test, dan laporan

Sebelum edit, jalankan dari `app/` jika tersedia:

```bash
git status --short
flutter analyze --no-pub --fatal-infos --fatal-warnings lib test
flutter test --no-pub
```

- Catat tes gagal sebelumnya dengan **nama test dan error persis**. Contoh kegagalan `KantinCerdasApp` di `test/widget_test.dart`: cari definisi sebenarnya dan tentukan apakah test memang usang; jangan mengklaim penyebabnya dari refactor tanpa pembuktian.
- Bila baseline FAIL, lakukan targeted tests yang relevan dan bandingkan jumlah/jenis kegagalan; tetap laporkan keseluruhan baseline FAIL.
- Test khusus: navigasi login↔akun, tombol Back, splash, restore sesi, deep link, gagal token, Google OAuth mocking, foto, logout. Tidak semua bisa diuji otomatis—catat QA Android manual yang masih harus dilakukan.
- Setelah edit jalankan analisis dan test kembali, `git diff --check`, audit import, serta `git diff --stat`. Jangan mengubah test expectation demi PASS.
- Laporan akhir wajib mencakup: ownership **sebelum→sesudah**, daftar file nyata, kontrak yang dipertahankan, hasil test (PASS/FAIL/BLOCKED/NOT RUN), kekurangan verifikasi, dan tahap selanjutnya. Jangan menulis `done` hanya karena tidak ada error import.
