# Arsitektur aktual

`app/lib/main.dart` → bootstrap → `kantin_cerdas_app.dart`/MaterialApp.router. `main_simulation.dart` membuka bootstrap simulasi dengan repository override. Graph entry normal tidak boleh menjangkau implementasi simulasi.

| Area | Path | Tanggung jawab |
| --- | --- | --- |
| App | `app/lib/app` | Bootstrap (`bootstrap.dart`), komposisi DI produksi (`production_overrides.dart`), router, redirect dan tujuan login |
| Fitur utama | `app/lib/features/auth,customer,owner,admin` | Domain (`entities`, `failures`, `repositories`, `providers`, `usecases`/`validation`), Data (`datasources`, `models`, `mappers`, `repositories`, `storage`, `providers`), dan Presentation per fitur |
| Pesanan bersama | `app/lib/features/orders` | Domain (`OrderRecord`, `MenuCategory`, `order_record_rules`), Data bersama (`OrderRecordModel`, `CanteenApplicationModel`, `order_record_mapper`), dan Presentation (`order_labels`, `order_record_card`) |
| Pengaturan | `app/lib/features/settings` | Halaman pengaturan tampilan/preferensi lokal (`settings_page`), bantuan (`help_page`), dan ketentuan (`terms_page`) |
| Shell | `app/lib/features/shell` | Navigasi lintas role (`CustomerShell`, `OwnerShell`, `AdminShell`) dan akses recovery |
| Core | `app/lib/core` | Network (`Dio` + `AuthInterceptor`, `AppEnvironment`, `mapDioException`), media Zero-Trust (`ImageSecurityValidator`, `DioMediaUploadRepository`, `DeviceImagePickerAdapter`), config (`AppFeatureFlags`), domain bersama (`CanteenApplication`), session (`auth_state_provider`, `role_read_session`, `shared_data_revision_provider`, kontrak auth/token), storage (`SecureMutationJournalBase`), settings, utilitas (`json_map_utils`, `pagination_validator`, `mutation_id_generator`) dan widget bersama |
| Tema | `app/lib/theme` | Token warna, tipografi, radius, ukuran dan komponen Material |
| Simulasi | `app/test/support/simulation` | Seed, store lokal, receipt dan override terisolasi di luar `app/lib/` |

Alur data: widget → controller/notifier → repository/use case → datasource/storage → state → widget. Batas Clean Architecture ditegakkan secara otomatis oleh `app/test/audit/architecture_boundary_test.dart`:
- `lib/core/` tidak boleh mengimpor `lib/features/`.
- `lib/features/*/presentation/` hanya bergantung pada `domain/` (termasuk `domain/providers/`) dan `core/`; dilarang mengimpor `features/*/data/`.
- `lib/features/*/domain/` bebas dari dependensi `data/`, `presentation/`, dan `package:flutter/`.
- Penyuntikan implementasi `data/` ke provider kontrak `domain/` dan `core/session/` dilakukan terpusat di `buildProductionOverrides()` (`app/lib/app/production_overrides.dart`).
- **Kebijakan Layer `UseCase` (Pragmatis Berbasis YAGNI)**: Kelas `*UseCase` dipertahankan pada fitur yang membutuhkan orkestrasi multi-langkah atau validasi pra-kirim domain tersendiri (seperti `features/auth/domain/usecases/`). Untuk fitur yang aturan bisnis dan invariannya sudah dienkapsulasi penuh di dalam Value Object / Entity domain (`OrderDraft`, `CustomerOrderPriceConfirmation`, `Pending*Mutation`, `OwnerOrderTransition`) serta jurnal idempotensi di controller/repository, pemanggilan langsung ke kontrak `Repository` domain ditetapkan sebagai pola resmi tanpa membuat kelas *pass-through UseCase* kosong.

Provider memilih dependency, FutureProvider membaca data, Notifier/AsyncNotifier menangani aksi. Form memegang state lokal sementara. Snapshot identitas notifier dan generasi sesi melindungi respons lintas await, termasuk logout lalu login ke ID yang sama.

Owner juga dapat memakai fitur pribadi customer miliknya setelah promosi. Admin tidak mendapat bypass ke route pribadi customer. Otorisasi UI wajib diulang oleh server.

Checkout menginvalidasi daftar/detail pesanan; owner menginvalidasi katalog dan pesanan terkait; admin menginvalidasi ringkasan/pengguna/pengajuan; preferensi dan pengajuan memperbarui pembaca masing-masing. Invalidasi hanya pada container saat ini; perubahan perangkat lain belum realtime.

Katalog merupakan snapshot lengkap, konsisten antara daftar umum dan detail stan. Keranjang satu stan mengecek menu tersedia DAN stan buka. Jangan memasukkan halaman parsial ke CustomerCatalog.

Jurnal lokal per akun menyimpan ID+intent sebelum dispatch untuk checkout, pengajuan, owner, admin, preferensi dan pembatalan. Unknown mengunci aksi terkait; lookup membaca receipt ID sama. Versi berubah/null bukan bukti gagal. Jurnal bertahan setelah restart/logout; tidak boleh dihapus paksa. Jurnal lokal bukan pengganti dedupe/otorisasi server atau koordinasi lintas perangkat.

Lihat [kontrak strict](backend/SPESIFIKASI_BACKEND.md) dan [peta per file](backend/PETA_INTEGRASI_FILE.md).


## Aturan pengembangan

1. Gunakan source terbaru, baca aturan pada dokumen ini dan pubspec/lock; simpan pekerjaan lokal sebelum patch.
2. Catat perilaku sebelum/sesudah dan dampak pada domain, adapter, controller, UI, simulator, tes dan dokumen.
3. Terapkan DRY, separation of concerns dan YAGNI. Jangan tambah lapisan/package tanpa kebutuhan atau akses network dari presentation.
4. Simulasi wajib diisolasi di app/test/support/simulation/ dan dilarang berada di dalam app/lib/. main.dart harus bebas simulasi; error layanan normal tidak boleh fallback ke fixture.
5. Tambah regresi untuk bug perilaku, jalankan format/analyzer/test/build relevan; jangan memakai angka hasil historis.
6. Review sesi lintas await, identitas/ownership, validasi, CAS, receipt, unknown dan invalidasi terkait.
7. Perubahan schema jurnal membutuhkan migrasi, bukan hapus pending. Perubahan kontrak membutuhkan update seluruh implementasi.
8. Seluruh adapter HTTP (`*_api_datasource.dart`), repository produksi (`*_repository_impl.dart`), dan layanan unggah media (`DioMediaUploadRepository`) telah terhubung di `buildProductionOverrides()`. Saat mengintegrasikan dengan server backend nyata, pastikan endpoint mutasi dan lookup `/v1/operations/*` aktif bersamaan.

Jangan commit secret, token, service-account, signing key, build cache atau data pribadi simulasi. Environment/release signing disediakan melalui proses tim.

Presentation tidak mengakses layanan jaringan secara langsung atau mengarang hasil layanan. Logic/state tidak membuat widget. Domain interface tidak mengimpor Flutter UI. Jika `API_BASE_URL` tidak diberikan pada saat runtime/build, adapter secara aman mengembalikan `*NotConfiguredFailure`. Kontrak repository dan endpoint HTTP lengkap ada di [spesifikasi backend](backend/SPESIFIKASI_BACKEND.md); rincian per berkas ada di [peta integrasi](backend/PETA_INTEGRASI_FILE.md).

## Kapan dokumen diperbarui

Perubahan route/sesi/state: perbarui dokumen ini dan checklist 04. Perubahan aturan bisnis/entity/error: perbarui spesifikasi backend, kamus data dan peta file. Perubahan komponen/tema: perbarui 03 dan sistem desain. Catat hasil verifikasi aktual di 04.
