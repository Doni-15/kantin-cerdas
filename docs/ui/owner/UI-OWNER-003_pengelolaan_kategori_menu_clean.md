---
id: UI-OWNER-003
module: owner
design_status: DRAFT
revision: 2026-11-19
target: Android-first
document_type: screen-ui-spec
business_rule_refs: [OWNER-004, OWNER-004A, OWNER-005]
---

# UI-OWNER-003 — Pengelolaan Kategori Menu Clean

> **STATUS UI: DRAFT**. Ini spesifikasi perilaku/tampilan, BUKAN kode Flutter atau kontrak endpoint. Baca `../00_MULAI_DI_SINI.md`, `../shared/03_DESIGN_SYSTEM.md`, `../shared/06_STATES_LOADING_ERROR.md` dan file layar ini. Semua aturan bisnis LOCKED tetap berlaku terlepas dari status desain UI.

## Tujuan dan akses
Mengatur daftar kategori kantin dengan gaya minimalis yang secara visual dipuji user (namun belum diminta LOCK).

**Titik masuk:** Menu Owner → Kategori Menu.

## Struktur layar — urutan visual atas → bawah
- AppBar Kembali + judul tunggal **Kategori Menu**.
- Jumlah kategori kecil (teks sekunder), bukan statistik besar.
- Satu container daftar: tiap baris **nama kategori**, **jumlah menu**, ikon pensil kecil; divider tipis.
- CTA utama **Tambah Kategori** di bawah daftar; **bukan form tambah permanen di halaman**.
- Bottom sheet pendek untuk Tambah/Ubah nama kategori; tombol Simpan/Batal.
- Di sheet edit kategori, tindakan **Hapus kategori** hanya jika kategori benar-benar kosong termasuk menu diarsipkan.

## Interaksi
| Elemen / tindakan | Perilaku yang diwajibkan / arah navigasi |
| --- | --- |
| Tambah Kategori | Buka bottom sheet satu field Nama kategori wajib; validasi nama dan duplikasi dalam kantin yang sama. |
| Ubah | Buka bottom sheet dengan nama saat ini, simpan tanpa mengganti identitas kategori. |
| Hapus | Hanya ketika tidak ada referensi menu aktif maupun arsip. Konfirmasi dan validasi server; jika masih ada menu, jelaskan agar Owner memindahkannya terlebih dahulu. |
| Kembali | Buka Menu Owner. |

## State layar
| Kondisi | Perilaku UI |
| --- | --- |
| belum ada kategori | Empty state singkat + Tambah Kategori. |
| duplikasi nama | Error inline dan disabled Simpan. |
| kategori berisi menu aktif/arsip | Tidak boleh hapus; jangan otomatis memindahkan atau menghapus menu. |
| error save | Sheet tetap terbuka dengan input tidak hilang. |

## Guard dan sumber data
- Kategori awal: Makanan, Minuman, Camilan. `Semua` di Customer adalah filter UI, bukan kategori data.
- Setiap menu selalu memiliki tepat 1 kategori; cek kategori dalam kantin Owner yang sama.
- Jumlah yang menentukan boleh hapus termasuk seluruh menu arsip.

## Kriteria penerimaan (UI)
- [ ] Tidak ada form tambah permanen/ikon dekoratif berulang.
- [ ] Hapus kosong bisa dilakukan dari sheet dengan konfirmasi.
- [ ] Kategori arsip tetap dihitung saat menentukan boleh hapus.
- [ ] Edit nama tidak memindahkan menu atau mengganti ID.

## Batas / jangan ditambahkan
- Tidak ada drag-sort, warna kategori, ikon per kategori, subkategori bertingkat.

## Catatan implementasi dan status keputusan
- LAYOUT DRAFT; desain ini menggantikan mockup Kategori yang ramai. Aturan hapus kosong SUDAH LOCKED secara bisnis, bukan usulan baru.

**Rujukan bisnis:** OWNER-004, OWNER-004A, OWNER-005.
