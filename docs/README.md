# Pusat dokumentasi KantinCerdas

Dokumentasi aktif KantinCerdas (diperbarui 4 November 2026). Seluruh arsitektur Clean Architecture 3-lapis, adapter klien REST API (`Dio` + `AuthInterceptor`), manajemen jurnal idempotensi, dan validasi media Zero-Trust di sisi aplikasi Flutter telah selesai dan siap diintegrasikan dengan server backend.

## Pilih sesuai kebutuhan

| Dokumen | Fungsi | Pembaca utama |
| --- | --- | --- |
| [01 — Mulai dan simulasi](01_MULAI_DAN_SIMULASI.md) | Setup, perintah jalan (simulasi & REST API), akun uji, kontrol simulasi dan batasnya | Anggota baru, penguji, demonstrator |
| [02 — Arsitektur dan aturan](02_ARSITEKTUR_DAN_ATURAN.md) | Struktur kode 3-lapis, komposisi DI, alur state/data, sesi, recovery dan aturan mengubah source | Pengembang Flutter |
| [03 — UI/UX](03_UI_UX.md) | Perilaku loading/form/error/navigasi, komponen media dan acuan desain | Pengembang UI, desainer |
| [04 — Status dan pengujian](04_STATUS_DAN_PENGUJIAN.md) | Bukti verifikasi otomatis terkini, kesiapan integrasi backend, dan checklist QA langsung | Semua anggota, reviewer/dosen |
| [Backend — Spesifikasi](backend/SPESIFIKASI_BACKEND.md) | Kontrak endpoint `/v1/*`, skema tabel/entity, kode error, otorisasi, CAS, dan receipt | Pengembang backend |
| [Arsip](arsip/README.md) | Riwayat tahap dan kebutuhan awal; tidak dijadikan status terkini | Pembaca riwayat proyek |

## Urutan baca

- Ingin mencoba/menilai aplikasi: **01 → 04**.
- Ingin mengubah Flutter: **01 → 02 → 03 → 04**.
- Ingin membangun/mengintegrasikan backend: **02 → [spesifikasi backend](backend/SPESIFIKASI_BACKEND.md) → [kamus data](backend/KAMUS_DATA.md) → [peta integrasi file](backend/PETA_INTEGRASI_FILE.md) → 04**.
- Butuh token warna/font/spacing: [Sistem desain](desain/SISTEM_DESAIN.md). PDF [referensi UI/UX](desain/REFERENSI_UI_UX.pdf) adalah referensi visual awal, bukan tangkapan layar build terbaru.

## Aturan menjaga dokumen tetap rapi

1. Satu topik mempunyai satu dokumen utama. Status hasil tes hanya diperbarui di [04](04_STATUS_DAN_PENGUJIAN.md); dokumen lain menautkannya.
2. Ubah dokumen aktif ketika kontrak/fitur berubah. Catatan tahap lama tetap di arsip dengan label historis.
3. Jangan membuat dokumen tahapan baru sebagai pengganti panduan utama. Tambahkan bagian pada dokumen yang tepat.
4. Source adalah acuan implementasi; spesifikasi backend mendokumentasikan kontrak HTTP `/v1/*` yang sudah diimplementasikan oleh adapter Flutter untuk dipenuhi oleh server backend.
5. Jalankan `flutter analyze --no-pub --fatal-infos --fatal-warnings lib test` dan `flutter test --no-pub` dari folder `app/` setelah mengubah kode atau kontrak.

README root adalah pintu masuk; `app/README.md` hanya penunjuk. README teknis bawaan asset/platform tidak termasuk panduan proyek dan tetap dekat asetnya.
