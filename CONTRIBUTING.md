# Panduan Kontribusi

Panduan singkat untuk menjaga kualitas kode, kontrak API, dan migrasi database saat berkontribusi ke repositori KantinCerdas.

## 1. Cabang dan Pesan Commit

- Cabang yang dipantau oleh CI (`.github/workflows/ci.yml`): `main`, `staging`, dan `develop`. Buat cabang kerja dari `develop` dengan nama deskriptif singkat:
  - `feat/<topik>` untuk fitur baru (contoh: `feat/customer-search-filter`)
  - `fix/<topik>` untuk perbaikan bug (contoh: `fix/owner-order-conflict`)
  - `db/<topik>` untuk penambahan migrasi SQL (contoh: `db/stall-schedule-index`)
  - `docs/<topik>` atau `chore/<topik>` untuk dokumentasi dan pemeliharaan
- Tulis pesan commit menggunakan format Conventional Commits singkat: `<tipe>(<lingkup>): <ringkasan kalimat aktif>`.

## 2. Pemeriksaan Wajib Sebelum Pull Request

Jalankan seluruh perintah berikut dari direktori `app/` dan pastikan selesai dengan kode keluar `0`:

```bash
cd app
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test
flutter analyze --no-pub --fatal-infos --fatal-warnings lib test
flutter test --no-pub --reporter expanded test/audit/architecture_boundary_test.dart
flutter test --no-pub --reporter expanded
```

Jika Anda mengubah tautan antar-dokumen Markdown, pastikan seluruh target tautan relatif pada berkas di luar `docs/arsip/` benar-benar ada agar langkah `Verify documentation links` di `.github/workflows/ci.yml` tetap lulus.

## 3. Batas Kode dan Kontrak

- Pertahankan arah ketergantungan Clean Architecture (`presentation` $\rightarrow$ `domain` $\leftarrow$ `data`) dan pastikan `app/lib/` tidak pernah mengimpor kode dari `app/test/support/simulation/`.
- Apabila perubahan menyentuh bentuk JSON, batas validasi input, atau kode error, perbarui model/mapper di `app/lib/`, implementasi simulasi di `app/test/support/simulation/`, serta dokumen kontrak di `docs/backend/` pada Pull Request yang sama.
- Jangan pernah melakukan commit terhadap berkas `app/android/local.properties`, `app/android/key.properties`, `app/dart_defines.json`, `.env`, keystore `.jks`, atau kunci rahasia Supabase.

## 4. Aturan Migrasi Database (`server/supabase/migrations/`)

- Jangan mengedit berkas migrasi yang sudah pernah dijalankan di proyek Supabase Cloud bersama; tambahkan perubahan skema sebagai berkas migrasi baru dengan nomor urut berikutnya.
- Bungkus setiap berkas migrasi dengan transaksi (`BEGIN; ... COMMIT;`), tetapkan `SET search_path = ''` dengan kualifikasi skema penuh pada setiap fungsi, panggil `PERFORM public.fn_require_service_role();` di awal fungsi RPC, dan cabut hak `EXECUTE` dari `PUBLIC, anon, authenticated`.
