# Matriks QA UI sebelum integrasi dan rilis

## Semua layar

- [ ] Android ukuran kecil, tinggi sempit, keyboard muncul, teks 200%, landscape bila didukung; tidak ada overflow.
- [ ] Light dan Dark; kontras/status tetap terbaca tanpa warna saja.
- [ ] Target sentuh minimal 48dp dan semantic labels untuk icon-only termasuk FAB robot dan FAB `+`.
- [ ] Back navigation, tab, route guard, restore form, dan safe-area perangkat bergesture benar.
- [ ] Loading, empty, error, offline, retry, permission denied, stale data, request in flight, uncertain result tertangani.
- [ ] Tidak menampilkan angka/rekap 0 dari error jaringan.
- [ ] Tidak mengubah status lokal menjadi sukses sebelum backend membenarkan.

## Jalur order kritis

- [ ] Keranjang dua kantin memunculkan konfirmasi, Batal tidak mengubah data.
- [ ] Item Habis atau diarsipkan tetap terlihat dan memblokir seluruh checkout, tanpa auto-delete.
- [ ] Harga berubah menampilkan harga lama/baru dan butuh konfirmasi eksplisit yang cocok dengan versi yang di-checkout.
- [ ] Satu logical checkout dapat di-retry dengan ID yang sama, tanpa membuat pesanan ganda; tes setelah app relaunch.
- [ ] Uji seluruh 8 transisi di `07_STATUS_PESANAN.md`, termasuk Gagal Diambil dan konflik simultan.
- [ ] Nomor + barcode Code128 hanya saat Siap Diambil, scanner lookup tidak mengubah status.
- [ ] Selesai hanya ketika Owner menyatakan tunai diterima dan makanan diserahkan.

## Akses per role

- [ ] User nonaktif tidak dapat bertindak walau layar terakhir masih terbuka.
- [ ] Admin tidak dapat membaca rincian transaksi; lihat hanya indikator ada/tidak pesanan aktif.
- [ ] Penonaktifan Admin/Owner/Customer mengikuti pengaman transaksi dan Admin aktif terakhir; alasan wajib; reaktivasi dicatat.
- [ ] Uji kembali bug Riverpod 3: `AdminMutationController` tidak boleh membaca derived provider yang watch dirinya sendiri (`CircularDependencyError`) sebelum request backend.

## Verifikasi aktual

- [ ] Barcode Code128 di-screen dan lintas HP/scanner nyata belum otomatis dianggap lulus; uji sesuai skenario P1 pada `08_Pengujian_dan_Kriteria_Penerimaan.md`.
- [ ] Perangkat offline, push gagal, sesi lama Realtime masih tersambung setelah logout, dan akses role dicabut diuji.
- [ ] Auth identity linking, Gemini Free Tier/eligibility, dan kewajiban Google Play dicek secara terpisah.
