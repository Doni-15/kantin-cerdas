# Pengujian aplikasi (`app/test`)

Pengujian di sini dipilih berdasarkan **manfaatnya bagi aplikasi, bukan jumlahnya**.
Tidak ada target persentase cakupan. Sebuah test dipertahankan karena melindungi
sesuatu yang mahal jika rusak: uang, pesanan yang hilang atau ganda, akses lintas
akun, atau data yang bocor.

## Empat pertanyaan sebelum menulis atau mempertahankan test

1. **Apa yang rusak jika perilaku ini salah?** Jika jawabannya hanya "tampilannya
   sedikit berbeda", test ini hampir pasti tidak sepadan.
2. **Bisakah test ini gagal?** Rusak-kan kode produksinya sengaja (balik satu
   kondisi, hapus satu pemeriksaan). Test yang tetap hijau tidak melindungi apa pun.
3. **Apakah kegagalannya menunjuk penyebabnya?** Satu test, satu perilaku, judul yang
   menyebut perilaku itu.
4. **Apakah yang diuji kode produksi, bukan double-nya?** Test yang hanya
   memverifikasi stub atau simulator tidak membuktikan aplikasinya benar.

Test yang hanya mengulang isi implementasi (*change-detector*) dibuang, bukan
dipertahankan demi angka.

## Tata letak

Folder `app/`, `core/`, dan `features/` **mencerminkan `lib/`**: test untuk
`lib/X/y.dart` berada di `test/X/y_test.dart`. Empat folder lain menampung test
yang memang tidak punya satu rumah di `lib/`.

| Folder | Isi | Kecepatan |
| --- | --- | --- |
| `architecture/` | Penjaga struktur: batas lapisan Clean Architecture, isolasi simulasi dari `lib/`, tata letak folder test ini | detik |
| `app/`, `core/` | Router, jaringan, penyimpanan, media, utilitas, widget bersama | cepat |
| `features/<fitur>/{domain,data}/` | Entitas, aturan, mapper, repository, penyimpanan | cepat |
| `features/<fitur>/presentation/` | Controller, provider, dan halaman (widget test) di atas `SimulationStore` | sedang |
| `contracts/` | Kontrak klien ↔ backend yang menjangkau banyak fitur: parsing DTO, lookup rekonsiliasi, pemetaan error HTTP | cepat |
| `domain/` | Invarian domain lintas fitur (kesetaraan nilai, hierarki failure, parsing enum) | cepat |
| `simulation/` | Kesetiaan simulator terhadap backend dan alur lintas peran | sedang |
| `support/` | Infrastruktur, **bukan test**: simulator, harness, stub, fixture. `main_simulation.dart` di sini dipakai CI untuk APK simulasi | n/a |

`architecture/test_layout_test.dart` menegakkan aturan ini: lokasi folder, cermin
terhadap `lib/`, tidak ada test yang mengimpor test lain, dan batas 700 baris per
berkas.

## Menjalankan

Dari direktori `app/`:

```bash
flutter test test/architecture                      # gerbang struktur (jalankan pertama)
flutter test test/core test/domain test/contracts   # logika cepat tanpa UI
flutter test test/features/*/domain test/features/*/data
flutter test test/features/*/presentation test/app  # controller, provider, widget
flutter test test/simulation                        # simulator dan alur lintas peran
flutter test                                        # semuanya (dipakai CI)
```

## Peta risiko dan pelindungnya

| Risiko | Mengapa mahal | Pelindung utama |
| --- | --- | --- |
| Pesanan ganda atau hilang saat jaringan gagal | Pelanggan dua kali memesan, atau yakin sudah memesan padahal tidak | `features/customer/presentation/controllers/customer_order_controller_test.dart`, `features/customer/data/repositories/customer_order_repository_impl*_test.dart`, `contracts/mutation_lookup_dto_test.dart`, `core/storage/secure_mutation_journal_base_test.dart` |
| Uang dan status pesanan tidak konsisten | Salah catat pembayaran atau total | `features/orders/domain/validation/order_record_rules_test.dart`, `features/customer/domain/validation/customer_input_limits_test.dart`, `features/customer/domain/entities/order_draft_test.dart`, `core/utils/rupiah_formatter_test.dart`, `features/customer/presentation/providers/cart_*_test.dart` |
| Sesi dan akun: token, akun nonaktif, logout saat login berjalan | Akses akun yang salah | `features/auth/data/repositories/*_test.dart`, `core/network/auth_interceptor_test.dart`, `app/router/auth_redirect_test.dart`, `simulation/simulation_auth_supersede_test.dart` |
| Unggahan gambar berbahaya | Skrip atau polyglot masuk penyimpanan | `core/media/image_security_validator_test.dart`, `core/media/image_upload_flows_test.dart` |
| Kontrak klien ↔ backend bergeser | Aplikasi menerima data yang salah tanpa sadar | `contracts/*_test.dart` |
| Batas arsitektur bocor, test tersebar | Biaya perubahan naik diam-diam | `architecture/*_test.dart` |
| Alur lintas peran (pelanggan → pemilik → admin) | Pesanan tidak sampai ke pemilik | `simulation/connected_flows_test.dart` |

## Catatan jujur tentang nilai test yang ada

Bagian ini sengaja memuat kelemahan, supaya keputusan memangkas atau menambah test
didasarkan pada fakta.

- **`simulation/` menguji simulator, bukan kode produksi.** `SimulationOrderRepository`
  dan kawan-kawannya adalah double yang meniru backend. Test di folder ini penting
  karena hampir semua test presentasi bergantung pada simulator (simulator yang
  keliru membuat test lain hijau palsu), tetapi hasilnya tidak membuktikan
  `*RepositoryImpl` atau backend benar.
- **`domain/value_equality_test.dart` adalah test dengan kepadatan nilai terendah.**
  Satu test sekitar 300 baris untuk `==`/`hashCode` belasan entitas. Yang benar-benar
  berharga hanya kesetaraan `Pending*Mutation` dan `CustomerOrderPriceConfirmation`
  karena dipakai untuk membandingkan jurnal. Sisanya kandidat untuk dipangkas.
- **`core/config/app_feature_flags_test.dart` adalah *change-detector*.** Ia hanya
  bermanfaat sebagai daftar periksa rilis (flag tanpa endpoint harus `false`).
  Hapus bila flag sering berubah.
- **Berkas lama yang menggabungkan banyak subjek sudah dipecah** menurut subjek
  tanpa mengubah isi test. Dua test yang menggabungkan beberapa perilaku dipecah
  menjadi lima test berjudul baru, dan judul `group` pada berkas hasil pecahan
  ditulis ulang. Judul test lainnya tidak berubah, termasuk nomor temuan audit
  (`CRIT-01`, `HIGH-03`, dst.) untuk keterlacakan.

## Celah yang masih terbuka

Berdasarkan penelusuran kode (belum ada test yang menargetkannya langsung), urut
dari yang paling bernilai:

1. **`AuthStateNotifier`** (`lib/core/session/auth_state_provider.dart`). Penjaga sesi
   lintas-`await` yang dijelaskan di `docs/ARSITEKTUR.md` hanya teruji lewat simulator
   dan `AuthRepositoryImpl`, bukan notifier produksinya.
2. **Test kontrak bersama.** Jalankan skenario idempotensi yang sama terhadap simulator
   *dan* `*RepositoryImpl`, agar simulator tidak bisa menyimpang tanpa ketahuan.
3. **Halaman pemilik, admin, auth, dan pengaturan.** Pencarian nama kelas di test
   hampir tidak menemukan referensi langsung ke halaman-halaman ini. Mulai dari alur
   yang mengubah data (persetujuan admin, transisi pesanan pemilik).
4. **`json_map_utils.dart`.** Ketegasan parsing sudah teruji tidak langsung lewat
   `contracts/`; test unit langsung murah ditulis.

## Menambah test baru

- Letakkan di folder cermin `lib/`; satu subjek per berkas, bernama `<subjek>_test.dart`.
- Judul menyebut perilaku, bukan nomor temuan. Nomor temuan boleh ditaruh di akhir.
- Fixture dan stub bersama di `support/`. Stub yang hanya dipakai satu berkas tetap
  privat di berkas itu.
- Pakai `Completer` atau jam palsu, bukan `Future.delayed`, untuk mengatur urutan.
- Tanyakan: *jika test ini merah, apa yang rusak?* Jika tidak bisa dijawab, jangan
  ditulis.
