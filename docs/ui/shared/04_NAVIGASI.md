# Navigasi konseptual — bukan nama route final

```mermaid
flowchart TB
  A[Authentication] --> B[Area Customer]
  A --> C[Area Owner bila sah]
  A --> D[Area Admin bila sah]
  B --> E[Beranda atau Cari]
  E --> F[Detail Kantin]
  F --> G[Detail Menu]
  G --> H[Keranjang]
  H --> I[Checkout]
  I --> J[Detail Pesanan]
  B --> K[Pesanan Aktif dan Riwayat]
  K --> J
  B --> L[Profil]
  L --> M[Edit Profil dan Pengaturan]
  L --> N[Pengajuan Owner]
  L --> C
  B --> O[Food Assistant]
  O --> G
  C --> P[Dashboard Owner]
  P --> Q[Pesanan Owner]
  Q --> R[Detail dan Tindakan]
  P --> S[Menu dan Kategori]
  P --> T[Profil Kantin]
  C --> B
  D --> U[Dashboard Admin]
  U --> V[Review Pengajuan]
  U --> W[Pengelolaan Akun]
  U --> X[Kantin Read Only]
```

## Shell navigasi

| Area | Root destinations | Subhalaman |
|---|---|---|
| Customer | **Beranda · Cari · (FAB robot) · Pesanan · Profil** | Detail Kantin, Detail Menu, Keranjang, Checkout, Detail Pesanan, Form Pengajuan, Edit Profil, Pengaturan, AI chat |
| Owner | **Beranda · Pesanan · Menu · Kantin** | Edit Menu, Kelola Kategori, Detail Order, Cari/Scan, Akun Owner |
| Admin | **Beranda · Pengajuan · Pengguna · Kantin** | Review detail, Detail Pengguna, Detail Kantin, Akun/Pengaturan |
| Auth | Tidak ada bottom navigation | Login, Register 1, Register 2, Verifikasi, Lupa, Reset |

- Back kembali ke konteks asal, bukan memaksa reset tab root.
- Beralih Owner ↔ Customer menggunakan akun/sesi sama; **bukan mengubah role database**.
- Setelah checkout sukses server terverifikasi, arahkan ke Detail Pesanan; jika jaringan tidak pasti, tampilkan pemulihan upaya checkout.
- FAB Robot Customer hadir di shell root, tidak di layar detail.
- Route IDs, path deep-link, dan library navigasi konkret tidak diputuskan oleh berkas UI.
