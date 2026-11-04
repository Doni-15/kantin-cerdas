> ARSIP HISTORIS — bukan acuan implementasi/status terkini. Lihat [pusat dokumentasi](../README.md). Tautan referensi dalam kebutuhan awal dapat mengikuti struktur lama.

> Riwayat tahap 22. Hasil lama bukan bukti patch terbaru lulus; lihat [validasi tahap 23](../04_STATUS_DAN_PENGUJIAN.md).

# Paket terpadu kesiapan app dan simulasi

## Status yang boleh dinyatakan

Paket ini menyediakan implementasi dan pemeriksaan pekerjaan 1–8. Source disusun
berdasarkan tahap 21 yang lulus analyzer pada mesin pengguna. SDK Flutter tidak
tersedia pada lingkungan penyusun: analyzer, tes Flutter, build APK, dan UI pada
perangkat belum dinyatakan lulus sebelum perintah installer berhasil dijalankan.
Pemeriksaan visual manual tetap memerlukan pengguna. Backend nyata tidak dibuat.

## Perubahan inti

- Owner mewarisi kemampuan pelanggan untuk belanja, pesanan pribadi, preferensi,
  serta pemulihan checkout/pembatalan/pengajuan yang dibuat sebelum promosi.
  Admin tidak mewarisi kemampuan itu. Role akun tetap satu; hak akses pribadi
  selalu dibatasi ID akun. Owner tidak dapat mengajukan stan kedua.
- Profil owner mempunyai Belanja dan pesanan pribadi; profil pelanggan milik
  owner mempunyai Kelola stan saya. Redirect/deep link dan dialog mengikuti
  kemampuan yang sama, dengan penjagaan sesi/generasi tetap aktif.
- Mutasi owner menginvalidasi katalog dan pesanan pribadi yang terkait.
  Perubahan sesi menghitung ulang provider. Tidak ada klaim pembaruan real time
  lintas perangkat; daftar/detail menyediakan Muat ulang untuk perubahan eksternal.
- Asisten dibatasi 30 detik; batas 500 karakter mengikuti grapheme UI.
- Skeleton, empty/error/retry, lock pending dan dialog bisnis yang sudah ada
  dipertahankan. Form menu/stan/pengajuan/preferensi memakai konfirmasi keluar.
  Kredensial login/registrasi tidak disimpan sebagai draft disk saat meninggalkan
  alur. Foto profil dan autentikasi eksternal masih di luar kontrak inti.

## Komposisi simulasi

Entry normal: `lib/main.dart`; adapter produksi tetap tidak dikonfigurasi.
Entry simulasi: `test/support/main_simulation.dart`; 15 override Riverpod mengganti sumber
repository dan jurnal, menggunakan UI/controller/router produksi yang sama.
Label MODE SIMULASI selalu terlihat, dengan panel Kontrol.

Satu snapshot JSON lokal memuat akun, stan, menu, pengajuan, preferensi, pesanan,
receipt dan jurnal. Namespace `kantin_cerdas.simulation.v1.` memisahkan semuanya
dari preferensi, token dan secure journal app normal. Data/role/receipt bertahan
setelah logout dan restart pada instalasi yang sama. Ini bukan layanan backend,
bukan penyimpanan multi-perangkat, dan bukan jaminan durability server.

Hanya masukkan data fiktif: password simulasi disimpan sebagai data uji lokal.
Jangan memakai kredensial asli. Reset membutuhkan konfirmasi di panel Kontrol;
reset mengembalikan seed dan mengganti ProviderScope agar state lama dibuang.

## Akun awal

| Username | Role | Keterangan |
| --- | --- | --- |
| pelanggan | customer | Alya, pesanan aktif dan riwayat; dapat mengajukan stan |
| pelanggan2 | customer | Bima, pengajuan menunggu admin dan pesanan pribadi |
| pemilik | owner | Dapur Nusantara, stan buka |
| pemilik2 | owner | Warung Mie Kampus, stan buka |
| pemilik3 | owner | Kedai Segar, stan tutup |
| admin | admin | Meninjau pengajuan dan mengatur akses |

Password semua akun awal: `Simulasi123!`. Email memakai domain `example.test`.
Seed: 3 stan, 15 menu (termasuk habis), 8 pesanan pada beberapa status.
Registrasi membuat akun customer fiktif; login dilakukan melalui form biasa.
Permintaan reset hanya mensimulasikan penerimaan, tidak mengirim email/link.
Asisten memilih dari katalog/preferensi uji, dilabeli simulasi dan bukan AI nyata.
Preferensi bahan tidak menjamin makanan aman untuk alergi.

## Kontrak adapter dan batas simulasi

| Operasi | Kontrak yang dijalankan |
| --- | --- |
| Pembacaan | Sesi aktif/role/ownership, limit/filter/cursor, data kosong vs error |
| Checkout | Satu stan, buka/tersedia, harga persis, tunai, waiting+unpaid |
| Status owner | CAS versi, transisi domain, serah-terima/tunai untuk completed+paid |
| Pembatalan | Milik akun, waiting+unpaid, CAS yang bersaing dengan penerimaan |
| Pengajuan | Snapshot lengkap, previous ID/version, satu aktif, ID baru saat resubmit |
| Approval | Pengajuan, satu stan dan promosi role dalam satu commit snapshot |
| Akses admin | Tidak mengubah role, menolak diri/admin, CAS dan alasan |
| Preferensi | Create-if-absent/CAS, normalisasi dan batas domain |
| Pengiriman ulang | Akun+jenis+ID+payload, hasil pertama immutable; payload berbeda ditolak |
| Pemulihan | Receipt terpisah dari data terbaru; lookup ID hilang menyegel ID secara eksplisit sehingga penulis terlambat tidak bisa commit |
| Jurnal | Write sebelum dispatch, per akun, menolak overwrite, clear mencocokkan ID |

Mutasi lokal diserialkan dan data beserta receipt disimpan dalam snapshot yang
sama. Error penyimpanan tidak dilaporkan sebagai sukses. Mode respons hilang
menyimpan perubahan terlebih dahulu, kemudian melempar timeout; lookup memulihkan
hasil yang sama. Aturan ini harus diimplementasikan kembali secara otoritatif oleh
backend nanti, dengan transaksi/otorisasi/retensi/idempotensi yang nyata.
Cursor terikat filter dan revisi snapshot; jika data berubah, Muat ulang dari
halaman pertama. Perubahan antarperangkat belum disimulasikan sebagai jaringan.

## Kontrol skenario

Normal: delay baca/tulis 450 ms. Lambat: 3 detik untuk operasi data bersesi.
Daftar kosong: katalog/list/detail pesanan kosong, tanpa menghapus data asli.
Gagal baca: pembacaan gagal; kembali ke Normal lalu Muat ulang.
Konflik tulis: request disegel tanpa commit; tinjau ulang form sebelum mencoba lagi.
Respons tulis hilang: commit terjadi, respons gagal; kembali Normal lalu pilih
Periksa hasil pada panel recovery. Jangan mengirim ulang untuk membuat sukses.
Latensi buatan hanya berada dalam adapter simulasi.

## Urutan satu skrip

1. Validasi source tahap 21 dan perubahan tes yang dikenal; backup sebelum tulis.
2. Terapkan source, dokumentasi, migrasi kontrak tes serta tes lintas role.
3. Format source/test yang berubah; `flutter pub get` memakai constraint/lock yang ada.
4. Analyzer ketat `lib test`; jalankan seluruh tes dengan timeout per tes 45 detik.
5. Jika pemeriksaan lulus, build APK debug entry normal dan entry simulasi.
6. Simpan APK dengan nama berbeda; tampilkan laporan status, lalu `flutter run`
   untuk entry simulasi. Flutter dapat meminta pilihan perangkat.

`KC_LAUNCH=0` hanya menonaktifkan peluncuran interaktif, bukan analyzer/tes/build.
`KC_DEVICE_ID` opsional memilih device. `KC_APP_DIR` opsional mengganti folder app.
Installer tidak menginstal SDK, tidak mengubah signing dan tidak menaikkan versi
paket. Toolchain Android/Gradle/dependensi mungkin perlu unduhan normal.
Kedua entry memakai application ID Android proyek yang sama: memasang APK satu
mengganti executable yang lain, namun namespace data simulasi tetap terpisah.

## Checklist manual setelah skrip berhasil

- [ ] Login pelanggan: katalog, pencarian, detail stan/menu, stan tutup dan menu habis.
- [ ] Isi keranjang, jumlah/catatan, konfirmasi harga; kirim sekali dan buka detail.
- [ ] Logout → pemilik: pesanan yang sama muncul; terima → siap → uang/makanan diserahkan → selesai.
- [ ] Logout → pelanggan: status terbaru, total tetap, riwayat paid sesuai.
- [ ] Coba batal saat waiting; coba kembali setelah owner menerima, harus ditolak.
- [ ] Owner ubah menu/harga/stan: kembali pelanggan dan muat ulang; katalog berubah.
- [ ] Pelanggan ajukan stan → admin setujui → login kembali: owner dan pesanan pribadi masih dapat diakses.
- [ ] Respons hilang pada checkout/pengajuan/menu/approval/preferensi/pembatalan: keluar app, buka lagi, pulihkan tanpa duplikasi.
- [ ] Admin nonaktifkan customer: login target ditolak; admin tidak dapat mengubah akses diri/admin lain.
- [ ] Simpan preferensi dan coba asisten simulasi; gagal/konflik mempertahankan input.
- [ ] Coba skeleton, kosong, error dan retry melalui panel Kontrol.
- [ ] Form bisnis: back saat berubah, batal dialog, submit ganda dan pergantian sesi.
- [ ] Layar kecil/landscape, keyboard terbuka, teks besar, tema gelap, label pembaca layar.
- [ ] Reset simulasi mengembalikan data awal dan tidak menyentuh mode normal.

Belum dicentangnya checklist bukan keberhasilan. Catat masalah konkret dan log
agar perbaikannya berdasarkan eksekusi. Integrasi backend nyata adalah pekerjaan
berikutnya setelah hasil app/simulasi disepakati.
