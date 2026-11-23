# Kontrak komponen UI bersama

| Komponen konseptual | Perilaku & aturan |
|---|---|
| `RootCustomerNav` | BottomAppBar notched + centerDocked FAB robot; beranda/cari/pesanan/profil; FAB **tanpa label visual**, label semantik tetap ada. |
| `RootOwnerNav` | Empat item, penanda tab aktif konsisten; FAB `+` ditambahkan via Scaffold hanya pada Menu. |
| `RootAdminNav` | Empat item rata, tidak ada FAB. |
| `CompactCanteenRow` | Foto kecil/placeholder, nama, lokasi, Buka/Tutup, tanpa rating; tidak mengubah guard pesanan. |
| `CompactMenuRow` | Foto kecil, nama, harga, status; Owner=baris daftar, Customer=kartu ringkas. |
| `CompactOrderRow` | Identitas pesanan, status, ringkasan; detail/action ada di subhalaman. |
| `StatusText` | Status bisnis resmi saja; warna bukan satu-satunya pembeda, teks selalu ada. |
| `ReasonSheet` | Alasan wajib untuk Owner menolak/gagal, Admin menolak/nonaktif; tombol konfirmasi blocked jika kosong. |
| `ConfirmSheet` | Tindakan konsekuensial butuh penjelasan + Batal/Konfirmasi. |
| `KcFormField` | Label eksplisit, helper seperlunya, error inline, keyboard/scroll aware; tidak menghapus input saat gagal. |
| `KcEmptyState` | 1 ikon relevan, 1 judul pendek, 1 instruksi/aksi jika ada. |
| `KcLoadingState` | Spinner/skeleton secukupnya; jangan menampilkan angka palsu ketika belum loaded. |
| `CheckoutActionBar` | Total harga & 1 CTA, safe-area; disabled jika ada blocker yang terbukti; backend tetap memeriksa. |

## Penting

Nama di atas **deskriptif**, bukan kewajiban membuat class persis dengan nama tersebut. Reuse widget nyata sesuai struktur aplikasi; jangan membangun sistem komponen kedua jika tema/widget sudah tersedia.
