# KantinCerdas

**Pilih lebih cepat, makan lebih tenang.**

KantinCerdas adalah aplikasi kantin kampus untuk membantu mahasiswa memilih menu, memesan sebelum datang, memantau proses pesanan, lalu mengambil makanan dan membayar tunai di stan. Pengelola memakai aplikasi untuk menangani antrean, memperbarui status pesanan, mengatur ketersediaan menu, serta membuka atau menutup penerimaan pesanan.

Tahap pengembangan saat ini adalah **Flutter UI dengan data dummy**. Backend akan dikerjakan setelah scope integrasinya ditentukan.

> **Status implementasi (diperbarui 28 September 2026, berdasarkan audit folder `app/`):**
> satu aplikasi Flutter dengan satu entry point `app/lib/main.dart`. Yang sudah ada: login dan registrasi berbasis data dummy, pemilihan shell berdasarkan role (`customer`, `owner`, `admin`), design token (`theme/`), dan widget dasar (`core/widgets/`). Semua halaman di dalam shell role masih **placeholder**. Katalog stan/menu, keranjang, pesanan, dan asisten belum diimplementasikan. Backend belum ada.

## Dokumentasi

| Dokumen | Isi |
| --- | --- |
| [SRS_KantinCerdasv1.0.0.md](docs/SRS_KantinCerdasv1.0.0.md) | Scope, aturan bisnis, kebutuhan setiap referensi, model data, pengujian, dan konflik desain. Bagian 5 (arsitektur) tertinggal dari kode, lihat [Keputusan terbuka](#keputusan-terbuka) |
| [Roadmap_KantinCerdasv1.0.0.md](docs/Roadmap_KantinCerdasv1.0.0.md) | 644 task kecil dengan ID, versi, kriteria selesai, PIC, Issue, dan PR |
| [Roadmap_KantinCerdasv2.0.0.md](docs/Roadmap_KantinCerdasv2.0.0.md) | **Usulan** integrasi Firebase. Disusun dari kondisi repo 24 September 2026, sebelum struktur `app/` sekarang |
| [app/README.md](app/README.md) | Aturan penempatan file di `lib/` dan daftar utang teknis |
| [app/aturan.md](app/aturan.md) | Architecture rules wajib (layer, dependency, penamaan) |
| [app/lib/features/auth/README.md](app/lib/features/auth/README.md) | Catatan arsitektur fitur auth (fitur referensi) dan rencana migrasi ke backend |
| [app/lib/theme/README.md](app/lib/theme/README.md) | Design token |
| [docs/Riverpod.md](docs/Riverpod.md) | Aturan penggunaan Riverpod |
| [design/KantinCerdas_UIUX_Current.pdf](design/KantinCerdas_UIUX_Current.pdf) | Referensi UI/UX terkini |

## Status fitur

| Area | Status |
| --- | --- |
| Login (username + password, dummy) | Berjalan |
| Registrasi (publik, otomatis role `customer`) | Berjalan |
| Pemilihan shell per role setelah login | Berjalan |
| Halaman customer: Beranda, Pesanan, Riwayat, AI Chat, Profil | Placeholder |
| Halaman owner: Dashboard, Pesanan, Kantin, Profil | Placeholder |
| Halaman admin: Dashboard, Pengguna, Profil | Placeholder |
| Katalog stan dan menu, pencarian, filter | Belum ada |
| Keranjang dan pembuatan pesanan | Belum ada |
| Asisten dummy | Belum ada |
| Kondisi loading/kosong/gagal/offline | Belum ada |
| Backend, AI, push notification, pembayaran online | Di luar tahap ini |

## Fitur dalam scope

Daftar ini adalah kemampuan **yang ditargetkan** menurut SRS; status implementasi ada pada tabel di atas.

| Mahasiswa | Pengelola |
| --- | --- |
| Menelusuri dan mencari menu/stan | Melihat ringkasan dan antrean stan |
| Menyaring harga, estimasi, dan ketersediaan | Menerima atau menolak pesanan |
| Memilih menu melalui asisten dummy | Menandai pesanan siap diambil |
| Mengatur jumlah dan catatan keranjang | Mengonfirmasi penyerahan dan penerimaan tunai |
| Membuat dan memantau pesanan | Mengubah ketersediaan menu |
| Melihat riwayat dan menyimpan preferensi sesi | Mengatur status manual dan estimasi stan |

Role `admin` dan alur login/registrasi ada di kode tetapi **belum tercantum di SRS**; lihat [Keputusan terbuka](#keputusan-terbuka).

## Aturan utama

- Satu keranjang hanya berisi menu dari **satu stan**. Ganti stan memerlukan konfirmasi.
- Pesanan diambil sendiri. Pembayaran **tunai di konter**, tanpa pembayaran online atau ongkir.
- Status normal: **Menunggu konfirmasi → Diproses → Siap diambil → Selesai**. Pesanan baru juga dapat ditolak dengan alasan.
- Pesanan dianggap selesai setelah makanan diserahkan dan tunai diterima.
- "Pesan lebih awal" tidak mencakup penjadwalan tanggal atau slot pickup.
- Asisten, pengiriman order, izin notifikasi, dan gangguan koneksi disimulasikan; tidak menggunakan AI/API/push nyata.

## Teknologi dan arsitektur

Flutter dan Dart untuk Android portrait. Pendekatan **feature-first + shared core**, semua role dalam **satu aplikasi**; role menentukan navigasi dan hak akses.

| Kebutuhan | Pilihan | Catatan |
| --- | --- | --- |
| State management dan dependency injection | `flutter_riverpod` ^3.4.3 | Aturan di [docs/Riverpod.md](docs/Riverpod.md) |
| Navigasi | `go_router` ^18.0.1 | Route tersentral di `core/router/` |
| HTTP | `dio` ^5.11.1 | Terpasang, **belum dipakai** di kode |
| Font | Plus Jakarta Sans (400/500/600) | Lokal di `assets/fonts/` |
| Lint | `flutter_lints` ^6.0.0 | |

Fitur domain memakai tiga layer dengan arah dependency `presentation → domain ← data`:

```text
UI → Controller (Notifier) → UseCase → Repository → DataSource → Dummy / API
```

`features/auth/` adalah fitur referensi untuk fitur domain berikutnya (`catalog`, `cart`, `orders`, `chat`). Aturan lengkap ada di `app/aturan.md`.

### Alur aplikasi

```text
main.dart (ProviderScope)
   └─ KantinCerdasApp → GoRouter (awal: /login)
        ├─ /login, /register
        └─ /app → AppEntryPage → shell menurut UserRole
              ├─ customer → CustomerShell
              ├─ owner    → OwnerShell
              └─ admin    → AdminShell
```

### Struktur `app/`

```text
app/
├── pubspec.yaml
├── assets/fonts/            Plus Jakarta Sans
├── assets/images/logos/
├── test/widget_test.dart
└── lib/
    ├── main.dart
    ├── kantin_cerdas_app.dart
    ├── theme/               KcColors, KcTypography, KcSpacing, KcRadius, KcSizes, KcTheme
    ├── core/
    │   ├── router/          app_router, app_entry_page, routes
    │   └── widgets/         kc_brand, kc_button, kc_logo, kc_nav_item, kc_snackbar, kc_text_field
    └── features/
        ├── auth/            data / domain / presentation (login, register)
        ├── customer/        presentation (5 halaman + bottom navigation)
        ├── owner/           presentation (4 halaman + bottom navigation)
        ├── admin/           presentation (3 halaman + bottom navigation)
        └── shell/           customer_shell, owner_shell, admin_shell
```

Target perapihan (mis. memindahkan router dan root widget ke `lib/app/`) tercatat sebagai utang teknis di `app/README.md`. Target itu belum menjadi struktur aktif.

## Flutter SDK

- Flutter: **3.44.9**, channel **stable**
- Dart bawaan Flutter: **3.12.2** (`environment.sdk: ^3.12.2` pada `pubspec.yaml`)
- Target platform: **Android**

Versi yang disepakati dicatat dalam `.flutter-version`. Pengembang dan CI harus memakai versi tersebut.

```bash
flutter --version
```

## Menjalankan proyek

Prasyarat: Git, Flutter SDK sesuai `.flutter-version`, toolchain Android, dan emulator/perangkat Android. Semua perintah dijalankan dari direktori `app/` (yang berisi `pubspec.yaml`).

```bash
cd app
flutter doctor
flutter pub get
flutter devices
flutter run -t lib/main.dart
```

Hanya ada satu entry point (`lib/main.dart`). Aplikasi dimulai dari layar login.

### Akun demo

Data dummy di `AuthDummyDataSource`. Password sama untuk semua akun.

| Username | Password | Role |
| --- | --- | --- |
| `customer` | `123456` | Mahasiswa (`customer`) |
| `owner` | `123456` | Pengelola (`owner`) |
| `admin` | `123456` | Administrator (`admin`) |

Akun baru dari halaman registrasi otomatis menjadi `customer`. Login dan registrasi memiliki jeda simulasi 1 detik.

### Pemeriksaan pengembangan

```bash
dart format --output=none --set-exit-if-changed lib test
flutter --suppress-analytics analyze --no-pub
flutter test
```

Saat ini `flutter test` menjalankan satu widget test (`test/widget_test.dart`: aplikasi dapat ditampilkan). `integration_test/` belum tersedia dan CI belum aktif.

Build APK debug untuk demo lokal:

```bash
flutter build apk --debug -t lib/main.dart
```

Build debug tidak sama dengan distribusi produksi.

## Data dummy

Satu-satunya data dummy aktif adalah daftar pengguna di `lib/features/auth/data/datasources/auth_dummy_datasource.dart`. Data disimpan **in-memory**: akun yang didaftarkan hilang saat aplikasi dimulai ulang, dan dua emulator/aplikasi terpisah **tidak berbagi data**. Fixture stan, menu, keranjang, dan pesanan yang disebut SRS belum dibuat. Jangan memasukkan data pribadi nyata.

## Aturan desain

Referensi UI/UX terkini ada pada `design/KantinCerdas_UIUX_Current.pdf`. Jangan mengganti layout, warna, label, navigasi, atau aset berdasarkan selera masing-masing; token visual hanya diubah lewat `lib/theme/`. Nilai dinamis seperti quantity, total, dan status tetap berubah mengikuti data.

Baseline 88 gambar KC-DS-20260906 yang menjadi acuan SRS dan Roadmap v1 tidak lagi ada di working tree (`design/baseline/` tidak tersedia), sehingga tautan gambar di kedua dokumen tersebut rusak. SRS mencatat ketidaksesuaian sumber (Q03 identik dengan loading, crop Q06, kontrol edit pada detail order pengelola); task yang bergantung pada keputusan itu berstatus BLOCKED. Diskusikan lewat Issue keputusan.

## Berkontribusi bersama tim

1. Ambil satu task kecil dari [Roadmap_KantinCerdasv1.0.0.md](docs/Roadmap_KantinCerdasv1.0.0.md), isi PIC, dan buat Issue pada milestone yang sesuai.
2. Buat branch pendek, misalnya `feat/kc-m01-02-home-search`.
3. Kerjakan task sesuai `app/aturan.md` dan [docs/Riverpod.md](docs/Riverpod.md), dengan komponen bersama dan batas scope yang jelas.
4. Jalankan pemeriksaan pengembangan dan sertakan screenshot untuk perubahan tampilan.
5. Buka PR ke `main`, minta review satu teman, lalu tautkan PR pada roadmap.
6. Centang task hanya setelah merge dan kriteria selesai terpenuhi.

### Conventional Commits

```text
feat: add menu search interface
fix: correct cart total calculation
docs: clarify preorder scope
chore: configure Flutter CI
test: add order status widget test
```

| Jenis | Arti |
| --- | --- |
| `feat` | Fitur baru |
| `fix` | Perbaikan bug |
| `docs` | Perubahan dokumentasi |
| `style` | Format tanpa perubahan perilaku |
| `refactor` | Restrukturisasi tanpa fitur/perbaikan bug |
| `test` | Penambahan/perubahan test |
| `chore` | Konfigurasi dan pemeliharaan |
| `ci` | Perubahan workflow CI |

Scope opsional boleh dipakai, contohnya `feat(cart): add item note editor`. Cantumkan task ID pada body commit atau PR. Template Issue/PR lengkap tersedia di roadmap.

## Target versi

| Versi | Fokus |
| --- | --- |
| KantinCerdasv0.1.0 | Scaffold, data, design system |
| KantinCerdasv0.2.0 | Beranda, pencarian, detail stan/menu |
| KantinCerdasv0.3.0 | Asisten dan rekomendasi dummy |
| KantinCerdasv0.4.0 | Keranjang dan integrasi tombol tambah |
| KantinCerdasv0.5.0 | Submit dan pemantauan order mahasiswa |
| KantinCerdasv0.6.0 | Dashboard dan alur order pengelola |
| KantinCerdasv0.7.0 | Menu, pengaturan, profil, pendukung |
| KantinCerdasv0.8.0 | Kondisi sistem dan recovery |
| KantinCerdasv0.9.0 | Responsif, aksesibilitas, review visual/integrasi |
| KantinCerdasv1.0.0 | UI demo lengkap yang telah diverifikasi |

Tag memakai nama `KantinCerdasv1.0.0`; `pubspec.yaml` memakai versi numerik (saat ini `1.0.0+1`). Versi 1.0.0 hanya berlaku untuk scope UI demo; backend dan kesiapan transaksi nyata merupakan tahap terpisah.

## Keputusan terbuka

Kode dan dokumen saat ini belum searah pada hal berikut. Selesaikan lewat Issue keputusan, lalu perbarui SRS/roadmap.

1. **Auth dan role `admin`.** Kode memiliki login, registrasi, dan role `admin`; SRS hanya mendefinisikan Mahasiswa dan Pengelola tanpa sesi login. Tentukan apakah auth dan admin masuk scope v1.0.0.
2. **State management dan navigasi.** SRS bagian 5 menyebut ChangeNotifier dengan constructor injection dan `Navigator`; kode memakai Riverpod dan `go_router`. Catat Riverpod dan go_router sebagai keputusan resmi.
3. **Arah backend.** Roadmap v2 mengusulkan Firebase (Auth, Firestore, Functions); dokumentasi auth dan dependency `dio` mengarah ke REST API. Belum ada keputusan.
4. **Referensi desain.** Tentukan hubungan antara baseline KC-DS-20260906 dan `KantinCerdas_UIUX_Current.pdf`, lalu perbaiki tautan gambar di SRS/roadmap.
5. **Lisensi.** Lisensi source code belum ditetapkan, begitu pula hak distribusi foto dan font. Tetapkan sebelum publikasi atau distribusi lebih luas.

## Batas dan tindak lanjut

Backend, autentikasi nyata, sinkronisasi antardevice, AI sungguhan, push notification, dan pembayaran online belum tersedia. Token pada dummy login (`dummy-access-token-…`) hanya penanda, bukan mekanisme keamanan. Catat kebutuhan integrasi melalui backlog terpisah agar pekerjaan UI tidak bergantung pada endpoint yang belum ada.

Untuk melaporkan bug, buat Issue berisi task/screen ID, langkah reproduksi, hasil yang diharapkan, hasil aktual, role/akun demo, ukuran layar, dan screenshot. Untuk keputusan desain atau arsitektur, sertakan D-ID dari SRS bila ada.
