# Status keputusan dan prioritas sumber

## Otoritas saat kontradiksi

1. Enam spesifikasi bisnis **terbaru** (`01_Order...` hingga `06_AI...`, edisi 19 November 2026) dan keputusan/amendemen yang tercatat pada `09_Keputusan_dan_Perubahan.md`.
2. UI yang **secara eksplisit LOCKED**: UI-AUTH-001, UI-CUSTOMER-001, UI-CUSTOMER-002. Struktur visual jangan diubah diam-diam.
3. Kode sumber tema yang dapat diperiksa: `theme.zip` (7 file). Nilai token dan komponen asli menang atas angka/warna sketsa.
4. UI DRAFT dalam paket ini: representasi diskusi sebagai rancangan kerja, bukan persetujuan final.
5. Keputusan teknis yang telah disetujui, hanya dalam ruang lingkupnya (misalnya Code128). Desain uji dan pilihan yang belum terbukti tidak boleh disebut telah lulus uji.

## Audit otentisitas sumber

- Sumber bisnis terbaru dari Library Project `Pemrograman Mobile`: `01_Order_Business_Specification_v1.0(1).md`, `02_Owner_Business_Specification_v1.0(1).md`, `03_Customer_Business_Specification_v1.0(1).md`, `04_Authentication_Business_Specification_v1.0(1).md`, `05_Admin_Business_Specification_v1.0(1).md`, `06_AI_Food_Assistant_Business_Specification_v1.0(1).md`, `07_Arsitektur_MVP_Android.md`, `08_Pengujian_dan_Kriteria_Penerimaan.md`, `09_Keputusan_dan_Perubahan.md`, `11_Metadata_Proyek.json`.
- Source `theme.zip` diperiksa secara langsung; mengandung `kc_theme.dart`, `kc_colors.dart`, `kc_typography.dart`, `kc_spacing.dart`, `kc_radius.dart`, `kc_sizes.dart`, `kc_theme_exports.dart`.
- Authentication UI asli (9 file) dari `Kantin_Cerdas_UI_Authentication_Per_Layar.zip` dipertahankan pada folder `auth/` tanpa mengganti isi layar yang sudah disetujui. Lihat gateway untuk ketentuan jika ada pembaruan bisnis.
- Business spec Order/Owner/Customer mencatat bahwa sebagian naskah user belum ditranskripsi verbatim; ringkasan file ini **bukan pengganti naskah verbatim**.

## Status per modul

| Modul | UI LOCKED | UI DRAFT |
|---|---|---|
| Authentication | Login (`UI-AUTH-001`) | Registrasi, verifikasi, reset password, states |
| Customer | `UI-CUSTOMER-001`, `UI-CUSTOMER-002` | `UI-CUSTOMER-003` s.d. `UI-CUSTOMER-011` |
| Owner | — | `UI-OWNER-001` s.d. `UI-OWNER-008` |
| Admin | — | `UI-ADMIN-001` s.d. `UI-ADMIN-005` |
| AI | — | `UI-AI-001` |

## Hal yang tidak boleh diganti hanya untuk kenyamanan UI

- Gagal Diambil merupakan status akhir yang sah menurut amendemen ORDER-013B 19 November 2026.
- OWNER-001 mengharuskan nama, kampus/universitas dan lokasi fisik detail pada profil kantin.
- OWNER-002 mengharuskan minimal **1 menu Tersedia** sebelum penerbitan pertama.
- OWNER-004A mengizinkan penghapusan kategori hanya ketika **tidak ada menu aktif maupun arsip** yang mengacu kepadanya.
- OWNER-005 mengizinkan **pemulihan menu dari arsip**.
- ADMIN-003 mewajibkan **alasan penonaktifan akun** dan mengizinkan **aktivasi ulang**.
- ADMIN-005 mengharuskan ringkasan pengguna, pengajuan, kantin, akun nonaktif (boleh sangat minimalis, tidak perlu kartu besar).
- ORDER-010 mengizinkan catatan per item **dan** catatan umum pesanan.
