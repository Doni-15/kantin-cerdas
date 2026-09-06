# KantinCerdas

**Pilih lebih cepat, makan lebih tenang.**

KantinCerdas adalah aplikasi kantin kampus untuk membantu mahasiswa memilih menu, memesan sebelum datang, memantau proses pesanan, lalu mengambil makanan dan membayar tunai di stan. Pengelola memakai aplikasi untuk menangani antrean, memperbarui status pesanan, mengatur ketersediaan menu, serta membuka atau menutup penerimaan pesanan.

Tahap pengembangan saat ini adalah **Flutter UI dengan data dummy**. Desain mengikuti 88 referensi yang dikunci sebagai **KC-DS-20260906**. Backend akan dikerjakan setelah scope integrasinya ditentukan.

> **Status awal:** paket unduhan dokumentasi berisi tiga file Markdown. Baseline desain berasal dari `Desaign System.zip` yang terpisah. Scaffold Flutter, CI, APK, dan fitur interaktif belum dibuat. Perintah Flutter di bawah adalah panduan target setelah task bootstrap pada roadmap selesai. Semua milestone masih rencana.

## Dokumentasi

| Dokumen | Isi |
| --- | --- |
| [SRS.md](SRS.md) | Scope, aturan bisnis, kebutuhan setiap referensi, model data, arsitektur, pengujian, dan konflik desain |
| [ROADMAP.md](ROADMAP.md) | 644 task kecil dengan ID, versi, kriteria selesai, PIC, Issue, dan PR |
| [Galeri desain](design/baseline/index.html) | Galeri HTML dari paket sumber; buka secara lokal untuk menelusuri 88 referensi |
| [Folder gambar desain](design/baseline/screens/) | F00, M01–M37, P01–P18, U01–U09, S01–S17, Q01–Q06 |

## Fitur dalam scope

| Mahasiswa | Pengelola |
| --- | --- |
| Menelusuri dan mencari menu/stan | Melihat ringkasan dan antrean stan |
| Menyaring harga, estimasi, dan ketersediaan | Menerima atau menolak pesanan |
| Memilih menu melalui asisten dummy | Menandai pesanan siap diambil |
| Mengatur jumlah dan catatan keranjang | Mengonfirmasi penyerahan dan penerimaan tunai |
| Membuat dan memantau pesanan | Mengubah ketersediaan menu |
| Melihat riwayat dan menyimpan preferensi sesi | Mengatur status manual dan estimasi stan |

Kondisi loading, kosong, gagal, offline, teks panjang, dan keyboard aktif juga termasuk scope. Daftar ini adalah kemampuan **yang ditargetkan**; status implementasi diperiksa pada roadmap/Issues.

## Aturan utama

- Satu keranjang hanya berisi menu dari **satu stan**. Ganti stan memerlukan konfirmasi.
- Pesanan diambil sendiri. Pembayaran **tunai di konter**, tanpa pembayaran online atau ongkir.
- Status normal: **Menunggu konfirmasi → Diproses → Siap diambil → Selesai**. Pesanan baru juga dapat ditolak dengan alasan.
- Pesanan dianggap selesai setelah makanan diserahkan dan tunai diterima.
- “Pesan lebih awal” tidak mencakup penjadwalan tanggal atau slot pickup.
- Asisten, pengiriman order, izin notifikasi, dan gangguan koneksi disimulasikan; tidak menggunakan AI/API/push nyata.

## Teknologi dan struktur

Flutter dan Dart digunakan untuk Android portrait. UI memakai komponen bersama, ViewModel, dan interface repository; data berasal dari fixture lokal dan in-memory store. Pilihan awal state menggunakan ChangeNotifier/ValueNotifier dari SDK dengan constructor injection. Versi Flutter konkret dipilih, diverifikasi, dan dipin saat bootstrap; jangan memakai versi berbeda-beda antaranggota.

| Lokasi | Kegunaan |
| --- | --- |
| `lib/app/` | Bootstrap, dependency wiring, route, sesi |
| `lib/core/` | Model, repository, formatter, dan design system |
| `lib/features/` | Katalog, asisten, cart, order, pengelola, profil |
| `assets/` | Foto, font, dan fixture runtime |
| `test/`, `integration_test/` | Pemeriksaan perilaku dan alur kritis |
| `design/baseline/` | Desain sumber terkunci; tidak diedit saat implementasi |

Direktori Flutter di tabel merupakan struktur target. Untuk susunan awal repository, letakkan tiga file Markdown di root, lalu salin isi folder `Desaign System/` dari ZIP desain asli ke `design/baseline/`. Setelah itu `design/baseline/` memuat `index.html`, `app.js`, `styles.css`, `README.md` sumber, `assets/`, dan `screens/`.

## Menjalankan proyek

### Melihat desain sekarang

Ekstrak ZIP dokumentasi dan ZIP desain asli, lalu susun folder seperti petunjuk di atas. Buka `design/baseline/index.html` menggunakan browser lokal. GitHub tidak menjalankan galeri HTML langsung dari tampilan file; unduh/clone terlebih dahulu. Galeri ini adalah referensi desain, bukan aplikasi Flutter. Tautan gambar pada SRS dan roadmap bekerja setelah folder desain ditempatkan di lokasi tersebut.

### Setelah scaffold Flutter tersedia

Prasyarat: Git, Flutter SDK yang dipin proyek, toolchain Android, dan emulator/perangkat Android. Pastikan `flutter doctor` tidak menunjukkan blocker pada target Android. Buka terminal pada direktori root repository yang berisi `pubspec.yaml`.

```bash
flutter doctor
flutter pub get
flutter devices
```

Menjalankan demo mahasiswa:

```bash
flutter run -t lib/main_student.dart
```

Menjalankan demo pengelola:

```bash
flutter run -t lib/main_manager.dart
```

Entry point tersebut harus dibuat pada milestone `KantinCerdasv0.1.0`. Setelah siap, perbarui README dengan versi SDK yang diuji serta hasil menjalankan kedua perintah. Tidak diperlukan `.env`, API key, akun cloud, atau server untuk scope dummy.

### Pemeriksaan pengembangan

```bash
dart format --output=none --set-exit-if-changed lib test integration_test
flutter analyze
flutter test
```

Perintah format di atas digunakan setelah ketiga direktori tersedia; pada scaffold awal hanya sertakan direktori yang sudah dibuat. Jalankan integration test sesuai file test yang benar-benar dibuat dan perangkat target yang dipilih. CI perlu disiapkan melalui task roadmap; README ini tidak menyatakan CI sudah aktif.

Contoh build APK demo setelah entry point tersedia:

```bash
flutter build apk --debug -t lib/main_student.dart
flutter build apk --debug -t lib/main_manager.dart
```

Salin/arsipkan APK mahasiswa sebelum membangun APK pengelola karena lokasi output default dapat tertimpa. Build debug untuk demo lokal tidak sama dengan distribusi produksi. Application ID terpisah/flavor untuk memasang dua role bersamaan belum diwajibkan.

## Data dummy

Fixture utama menggunakan Doni, Bu Rina, Dapur Bu Rina, Kedai Pak Ucok, dan Warung Sinta. Contoh cart terdiri dari satu Nasi Ayam Sambal Matah Rp18.000 dan satu Nasi Telur Dadar Rp12.000, sehingga totalnya Rp30.000.

Data bertahan selama proses/sesi demo berjalan dan kembali ke fixture pada cold restart. Dua aplikasi atau emulator terpisah **belum berbagi data**. Pengujian lintas peran menggunakan harness satu proses dengan store yang sama. Semua nama/email/riwayat merupakan contoh; jangan memasukkan data pribadi nyata.

## Aturan desain terkunci

Implementasi mengikuti PNG, komponen, token, foto, dan font dalam baseline. Jangan mengganti layout, warna, label, navigasi, atau aset berdasarkan selera masing-masing. Nilai dinamis seperti quantity, total, dan status tetap berubah mengikuti data.

SRS mencatat ketidaksesuaian sumber, termasuk Q03 yang identik dengan loading, crop Q06, dan kontrol edit pada detail order pengelola. Task yang bergantung pada keputusan tersebut diberi status BLOCKED. Diskusikan lewat Issue keputusan; simpan baseline asli dan jangan mengubah gambar untuk menyamarkan perbedaan.

## Berkontribusi bersama tim

1. Ambil satu task kecil dari [ROADMAP.md](ROADMAP.md), isi PIC, dan buat Issue pada milestone yang sesuai.
2. Buat branch pendek, misalnya `feat/kc-m01-02-home-search`.
3. Kerjakan task dengan komponen bersama dan batas scope yang jelas.
4. Jalankan pemeriksaan yang relevan dan sertakan screenshot untuk perubahan tampilan.
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

Contoh di atas mengikuti konvensi yang dipilih tim. Untuk perubahan file workflow berikutnya gunakan `ci`, misalnya `ci: add Flutter analyze workflow`. Scope opsional boleh dipakai, contohnya `feat(cart): add item note editor`. Cantumkan task ID pada body commit atau PR. Template Issue/PR lengkap tersedia di roadmap.

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

Tag memakai nama `KantinCerdasv1.0.0`; `pubspec.yaml` tetap memakai versi numerik, misalnya `1.0.0+10`. Build number pada contoh harus diganti sesuai urutan build aktual. Versi 1.0.0 hanya berlaku untuk scope UI demo; backend dan kesiapan transaksi nyata merupakan tahap terpisah.

## Batas dan tindak lanjut

Backend, autentikasi nyata, sinkronisasi antardevice, AI sungguhan, push notification, dan pembayaran online belum tersedia. Keputusan stack backend belum dibuat. Catat kebutuhan integrasi melalui backlog terpisah agar pekerjaan UI tidak bergantung pada endpoint yang belum ada.

Lisensi source code belum ditetapkan. Sebelum publikasi/distribusi lebih luas, tim perlu memilih lisensi dan mencatat hak penggunaan foto/font. Keberadaan aset dalam paket tidak otomatis menetapkan izin distribusinya.

Untuk melaporkan bug, buat Issue berisi task/screen ID, langkah reproduksi, hasil yang diharapkan, hasil aktual, peran demo, skenario fixture, ukuran layar, dan screenshot. Untuk keputusan desain, sertakan D-ID dari SRS.
