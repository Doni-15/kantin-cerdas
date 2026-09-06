# Software Requirements Specification — KantinCerdas

| Identitas | Nilai |
| --- | --- |
| Versi dokumen | 1.0 — 6 September 2026 |
| Status dokumen | Spesifikasi implementasi demo; keputusan terbuka dicatat pada bagian 13 |
| Target akhir roadmap | **KantinCerdasv1.0.0 — Flutter UI Demo** |
| Baseline desain | **KC-DS-20260906 — LOCKED** |
| Sumber utama | `Desaign System.zip`, 88 PNG, HTML/CSS/JavaScript, dan aset lokal |
| Teknologi yang diminta | Flutter untuk UI; data dummy; backend menyusul |
| Dokumen pendamping | [ROADMAP.md](ROADMAP.md), [README.md](README.md) |

> Dokumen ini menyatakan kebutuhan yang harus dibangun, bukan klaim bahwa aplikasi, pengujian, CI, atau rilisnya sudah tersedia. ZIP sumber adalah paket desain web statis; tidak berisi proyek Flutter atau backend. Seluruh pekerjaan pada roadmap diawali dengan status TODO, kecuali tugas yang ditandai BLOCKED karena keputusan desain.

## Daftar isi

1. [Tujuan dan ruang lingkup](#1-tujuan-dan-ruang-lingkup)
2. [Sumber dan aturan penguncian desain](#2-sumber-dan-aturan-penguncian-desain)
3. [Aktor, istilah, dan hak aksi](#3-aktor-istilah-dan-hak-aksi)
4. [Aturan bisnis](#4-aturan-bisnis)
5. [Arsitektur Flutter dan batas backend](#5-arsitektur-flutter-dan-batas-backend)
6. [Model dan kontrak data dummy](#6-model-dan-kontrak-data-dummy)
7. [Status, navigasi, dan operasi asynchronous](#7-status-navigasi-dan-operasi-asynchronous)
8. [Fondasi visual](#8-fondasi-visual)
9. [Kebutuhan nonfungsional](#9-kebutuhan-nonfungsional)
10. [Skenario dan penerimaan end-to-end](#10-skenario-dan-penerimaan-end-to-end)
11. [Versi dan ketertelusuran](#11-versi-dan-ketertelusuran)
12. [Spesifikasi setiap referensi](#12-spesifikasi-setiap-referensi)
13. [Keputusan dan konflik sumber](#13-keputusan-dan-konflik-sumber)
14. [Manifest baseline](#14-manifest-baseline)
15. [Rujukan teknis](#15-rujukan-teknis)

## 1. Tujuan dan ruang lingkup

KantinCerdas membantu mahasiswa memilih menu kantin, memesan lebih awal, memantau pesanan, lalu mengambil makanan dan membayar tunai di stan. Pengelola melihat antrean, menerima atau menolak pesanan, menandai pesanan siap, mengonfirmasi penyerahan dan pembayaran, serta mengatur ketersediaan menu dan penerimaan pesanan.

Tujuan tahap ini adalah **aplikasi Flutter interaktif dengan repository dummy** yang mengikuti desain terkunci. Halaman harus benar-benar bereaksi terhadap tap, input, perubahan data, dan kegagalan simulasi. Menempelkan PNG sebagai seluruh halaman tidak memenuhi kebutuhan ini.

### 1.1 Cakupan wajib

- Fondasi visual dan komponen F00.
- Seluruh 37 referensi mahasiswa M01–M37.
- Seluruh 18 referensi pengelola P01–P18.
- Seluruh sembilan referensi pendukung U01–U09.
- Seluruh 17 kondisi sistem S01–S17.
- Seluruh enam variasi ukuran/konten Q01–Q06, dengan konflik acuan dicatat secara terbuka.
- Navigasi, filter, catatan, cart, total, transisi order, preferensi, dan status stan berbasis state.
- Fixture deterministik untuk data normal, kosong, loading, gagal, offline, dan hasil submit tidak diketahui.
- Repository interface agar sumber data dapat diganti setelah backend disepakati.
- Dokumentasi tim, Conventional Commits, PR kecil, dan milestone versi.

### 1.2 Di luar scope KantinCerdasv1.0.0

Backend/API nyata; basis data server; autentikasi/login/register/OTP; otorisasi server; AI/LLM sungguhan; push notification/FCM; pembayaran elektronik; QRIS; dompet; kurir; ongkir; pesanan multi-stan dalam satu cart; voucher; rating; ulasan; favorit; penjadwalan pickup; pembatalan order oleh mahasiswa; pengubahan item order oleh pengelola; laporan keuangan; CRUD tambah/hapus menu; unggah foto; pengeditan identitas akun/stan; deployment layanan produksi.

Pengubahan item oleh pengelola disebut di luar scope sementara karena sumber menampilkan kontrolnya tetapi tidak mendefinisikan alur dan akibatnya. Konflik **D-04 wajib diselesaikan sebelum rilis demo lengkap**. Ini bukan izin untuk menghapus kontrol atau menciptakan alur baru sendiri.

“Pesan lebih awal” berarti mahasiswa memesan sebelum datang, bukan memilih tanggal atau slot jam pengambilan. Jadwal stan pada P17 bersifat informasi; isOpen manual menentukan penerimaan pesanan.

### 1.3 Platform dan tahap hasil

- Baseline utama: Android, portrait, 390 × 844 logical pixels/dp.
- Ukuran uji tambahan: 360 × 800 dan 412 × 915 dp.
- Flutter/Dart versi **dipilih dan dipin saat bootstrap**, bukan ditebak dari paket desain. iOS, web, desktop, landscape, dan dark mode tidak menjadi syarat rilis tahap ini.
- Android emulator/perangkat cukup untuk demo. Tidak perlu akun cloud, API key, layanan AI, atau server.
- Angka `1.0.0` berarti lengkap terhadap scope **UI demo** ini, bukan siap melayani transaksi dunia nyata.

## 2. Sumber dan aturan penguncian desain

### 2.1 Hierarki acuan

| Urutan | Acuan | Fungsi |
| --- | --- | --- |
| 1 | Instruksi pengguna pada tugas ini | Flutter, dummy, desain locked, dokumentasi, roadmap atomik, commit |
| 2 | `design/baseline/screens/<ID>_*.png` | Komposisi, warna, ikon, label, hierarki visual per referensi |
| 3 | `design/baseline/app.js` | Dataset contoh, varian layar, label, pemetaan ID ke fungsi |
| 4 | `design/baseline/styles.css` dan F00 | Token, ukuran, font, pola komponen; konflik tidak diselesaikan diam-diam |
| 5 | SRS ini | Aturan perilaku yang dapat diuji dan keputusan teknis tambahan |

Tidak ada dokumen audit lama, PDF lain, ataupun `DESIGN_SYSTEM.md` lain di dalam ZIP ini. Dokumen tersebut tidak dijadikan sumber tersembunyi. Label yang tertera di PNG dan implementasi sumber sama-sama dibaca; bila bertentangan, catat nomor keputusan pada bagian 13.

### 2.2 Apa yang dikunci

Nama produk, warna, font, ikon, foto sumber, label UI, posisi dan hierarki elemen, kelompok navigasi, pola list, dialog, sheet, badge, cart bar, CTA, serta alur utama yang telah tergambar. Tidak boleh mengganti desain menjadi tema Material bawaan, mengubah layout supaya lebih “modern”, atau menambah layar bisnis yang tidak diminta.

Data runtime boleh berubah sebagai akibat aksi: jumlah porsi, total, nama item yang dipilih, status, waktu, jumlah hasil, dan order ID. Setiap screenshot menggunakan fixture spesifik agar visual dapat dibandingkan secara deterministik. Tidak semua screenshot merepresentasikan satu database pada waktu yang sama.

### 2.3 Cara menjaga baseline

1. Simpan seluruh sumber asli di `design/baseline/` tanpa mengubah byte. Daftar SHA-256 tersedia pada bagian 14.
2. Implementasi Flutter berada di luar direktori baseline; tidak mengedit CSS/PNG supaya pengujian tampak lulus.
3. PR yang menyentuh tampilan menyebut ID layar, task ID, dan menyertakan screenshot Flutter pada ukuran terkait.
4. Reviewer membandingkan referensi dan implementasi dengan fixture dan skala yang sama.
5. Golden Flutter dibuat dari implementasi yang telah ditinjau, bukan langsung menuntut kecocokan byte dengan raster browser.
6. Jika baseline bertentangan dengan dirinya sendiri, tandai tugas visual BLOCKED. Pekerjaan komponen/data yang tidak terdampak tetap berjalan.
7. Perubahan visual hanya melalui persetujuan eksplisit pemilik desain. Catat keputusan, alasan, layar terdampak, tanggal, dan baseline baru. Arsip lama tetap utuh; tidak menimpa baseline ini.

### 2.4 Penanda sumber kebutuhan

- **B — Baseline:** terlihat pada PNG atau kode desain.
- **U — User:** diminta langsung pengguna.
- **A — Asumsi implementasi:** keputusan teknis yang diusulkan dokumen ini untuk membuat demo dapat diuji; dapat direvisi secara tercatat tanpa mendesain ulang.
- **D — Decision pending:** konflik/ketidaklengkapan sumber yang membutuhkan keputusan pemilik produk/desain.

## 3. Aktor, istilah, dan hak aksi

| Aktor | Hak aksi demo | Batas |
| --- | --- | --- |
| Mahasiswa | Telusur katalog, asisten dummy, kelola cart, submit, pantau order sendiri, preferensi | Tidak mengubah status order atau katalog |
| Pengelola | Antrean stan sendiri, accept/reject/ready/complete, availability menu, status dan estimasi stan | Tidak mengelola stan lain; tidak ada editor transaksi pasca-submit |
| Pengembang/QA | Memilih peran, fixture, error, waktu, dan koneksi melalui entry point/harness pengujian | Harness tidak dimasukkan ke navigasi produk yang locked |
| Repository dummy | Menyediakan state lokal dan mensimulasikan operasi | Tidak melakukan komunikasi antardevice atau menjamin transaksi nyata |

| Istilah | Arti |
| --- | --- |
| Stan | Penjual makanan di kantin; satu stan per cart |
| Jenis menu | Banyaknya menu ID yang berbeda, bukan jumlah porsinya |
| Porsi | Jumlah seluruh quantity item cart/order |
| Cart/keranjang | Draft belanja yang masih dapat diubah mahasiswa |
| Order/pesanan | Snapshot yang telah berhasil dibuat |
| Submission ID | Identitas satu niat pengiriman untuk mencegah order duplikat |
| Snapshot | Salinan harga, nama, catatan, dan quantity pada saat submit |
| Fixture | Data dan kondisi awal yang sengaja disusun untuk demo/uji |
| Golden test | Uji regresi screenshot Flutter dengan lingkungan tetap |
| Milestone | Kumpulan task yang ditargetkan selesai pada satu versi |

Pemilihan peran tidak membutuhkan layar login baru. Target teknis awal adalah `main_student.dart` dan `main_manager.dart`. Harness integration test boleh mengganti session role dalam proses yang sama supaya kedua tampilan membaca `DemoStore` yang sama; harness bukan fitur pengguna. Dua aplikasi/proses terpisah memiliki state dummy terpisah.

## 4. Aturan bisnis

| ID | Asal | Aturan dan kriteria yang harus dipenuhi |
| --- | --- | --- |
| BR-01 | B | Semua line cart memiliki satu stallId. Penambahan dari stan berbeda memunculkan M21. Batal mempertahankan semuanya; setuju mengganti secara atomik dengan item baru. |
| BR-02 | B | Pengambilan dilakukan sendiri di stan. Pembayaran hanya tunai di konter. Total tidak mengandung pajak/biaya/ongkir tambahan yang tidak ada di sumber. |
| BR-03 | B/A | Nilai uang memakai integer rupiah, tidak memakai double. lineTotal = unitPrice × quantity. total = jumlah line valid. Format tampilan Rp18.000 tanpa desimal. |
| BR-04 | A | Draft detail menu minimal satu. Dalam cart/row katalog, minus dari satu menghapus line dan menyediakan undo; plus menambah satu. Tidak ada quantity nol/negatif yang tersimpan. Batas quantity bisnis belum ditetapkan; UI tidak mengarang batas stok numerik. |
| BR-05 | B/A | Catatan item dan catatan pesanan berbeda. Cart memakai satu line per menu ID; tambah menu sama menaikkan quantity. Penambahan tanpa catatan mempertahankan catatan lama; catatan eksplisit dari detail menggantikannya. Field catatan tidak wajib; perubahan kosong yang disengaja dilakukan melalui editor catatan. |
| BR-06 | A | Undo penghapusan terakhir berlaku 5 detik dalam sesi, memulihkan quantity, catatan, posisi. Hapus baru menggantikan snapshot undo lama. Ganti stan, clear cart, logout, atau sukses submit membatalkan undo. |
| BR-07 | B/A | Validasi saat menuju konfirmasi dan sebelum create order: cart tidak kosong, satu stan, stan buka, semua item available, quantity valid. Jika availability berubah, tampil M23; item habis tidak dihitung dalam total menu tersedia tetapi tetap tampak sampai pengguna menghapusnya. Stan tutup menggunakan informasi S06 dan blok submit; detail penempatan pesan tambahan mengikuti D-09. |
| BR-08 | B | Create order sukses mulai pada Menunggu konfirmasi. Sukses tidak berarti diterima pengelola atau sudah dibayar. |
| BR-09 | B/A | Satu submission aktif untuk satu snapshot cart. Tap berulang tidak menimbulkan create kedua. Hasil unknown wajib lookup dahulu; cart dibersihkan hanya setelah keberhasilan terkonfirmasi. |
| BR-10 | B | Jalur normal: Menunggu konfirmasi → Diproses → Siap diambil → Selesai. Penolakan hanya dari Menunggu konfirmasi. Status terminal tidak kembali ke status aktif. |
| BR-11 | B | Selesai hanya setelah konfirmasi makanan diserahkan dan tunai diterima. Ditolak tidak ditagihkan; alasan tampil kepada mahasiswa. |
| BR-12 | B/A | Baru diurutkan createdAt terlama dahulu; Diproses acceptedAt terlama dahulu; Siap readyAt terlama dahulu. Jika waktunya sama, gunakan sequence urut stabil. Riwayat diurutkan waktu terminal terbaru dahulu. |
| BR-13 | B | Menutup stan mencegah order baru, tidak membatalkan atau menyembunyikan antrean yang telah masuk. Jadwal informasi tidak mengubah isOpen otomatis. |
| BR-14 | B/A | Pergantian availability menu hanya mengubah katalog dan validasi cart, tidak mengubah snapshot order lama. Gagal update mempertahankan nilai tersimpan lama; retry memakai intent yang sama. |
| BR-15 | B/A | Offline dengan cache: katalog/order terakhir dapat dibaca dan cart lokal boleh diedit; create order, asisten, serta mutasi pengelola diblokir. Tidak ada antrean submit offline otomatis. Saat online pulih lakukan refresh/validasi ulang. |
| BR-16 | B/A | Filter pencarian: harga per porsi <= batas, batas atas estimasi <= batas waktu, nama menu/stan cocok secara case-insensitive. Hanya menu tersedia mengecualikan Habis jika aktif. Draft sheet berbeda dari applied filter. |
| BR-17 | B/A | Asisten memakai filter lokal dan aturan fixture, bukan LLM. Rekomendasi hanya dari stan buka dan item available. Harga/waktu menjadi batas keras; selera menjadi preferensi urutan, bukan klaim bebas alergen atau jaminan nutrisi. |
| BR-18 | B/A | Preferensi dan pengaturan form baru masuk repository setelah Simpan. Gagal simpan mempertahankan draft, tetapi data tersimpan tidak berubah. |
| BR-19 | B/A | Izin notifikasi adalah state simulasi; menolak/tunda tidak menghalangi akses Pesanan. Push dan perubahan izin OS sebenarnya belum diimplementasikan pada scope ini. |
| BR-20 | A | Angka dashboard, hitungan tab, harga, dan total harus berasal dari data. Fixture visual antarstatus dipisah agar KC-027 tidak sekaligus waiting dan completed dalam satu store. |
| BR-21 | A | Semua waktu memakai clock yang dapat diinjeksi. Demo memakai 6 September 2026 pada zona Asia/Jakarta; format tampilan HH.mm. Waktu menerima order berbeda dari waktu refresh terakhir. |
| BR-22 | U/B | Tidak menambah pembayaran, login, CRUD menu, atau screen baru untuk mengisi celah baseline tanpa keputusan desain. |

### 4.1 Validasi input minimum

Query dan catatan diperlakukan sebagai teks, tidak sebagai HTML/perintah. Trim dipakai untuk pencarian; baris baru catatan tetap terbaca. Input kosong pada catatan sah. Tidak ada batas panjang baru yang ditampilkan karena sumber tidak menetapkannya; uji nama/catatan panjang dan scroll. Radio harga/waktu wajib memiliki nilai enum termasuk `unlimited`. Selera awal menggunakan satu pilihan (A-06), sehingga Pedas dan Tidak pedas tidak terpilih bersamaan. Alasan reject wajib salah satu enum yang ada; `Lainnya` adalah pilihan literal, bukan otomatis field teks baru.

## 5. Arsitektur Flutter dan batas backend

### 5.1 Keputusan teknis tahap demo

| Area | Pilihan awal | Alasan/batas |
| --- | --- | --- |
| UI | Flutter + Dart, widget native | Diperintahkan pengguna; PNG hanya referensi |
| Target | Android portrait | Sesuai galeri sumber |
| UI state | ViewModel berbasis ChangeNotifier/ValueNotifier, immutable state object | Pilihan awal yang ringan, memakai SDK; jangan campur beberapa pola state tanpa keputusan |
| Dependency injection | Constructor injection pada composition root | Fake repository mudah diganti; tidak membutuhkan service locator global |
| Navigasi | Navigator dan route factory terpusat | Route menerima ID model; state cart/order berada di luar route |
| Data | JSON/assets fixture + typed models + in-memory DemoStore | Deterministik; tidak membutuhkan internet |
| Aset | Foto dan font lokal dari baseline | Tidak bergantung CDN; hak distribusi dicatat sebagai tindak lanjut |
| Pengujian | flutter_test; integration_test untuk alur kritis; golden terpilih | Fokus risiko perilaku dan desain terkunci |
| Tooling | dart format, flutter analyze, flutter test; Android build | Gerbang proyek yang harus disiapkan, belum tersedia dalam ZIP |
| SDK/dependency | Pin satu Flutter SDK, Dart mengikuti SDK, commit pubspec.lock | Versi konkret dicatat setelah bootstrap diverifikasi |
| Backend | Belum dipilih | Tidak menetapkan bahasa, database, cloud, endpoint, atau autentikasi sekarang |

Pemisahan UI/ViewModel dan data/repository diadaptasi dari [panduan arsitektur Flutter](https://docs.flutter.dev/app-architecture/guide). Pilihan ChangeNotifier dan constructor injection di atas adalah keputusan proyek yang diusulkan, bukan satu-satunya pola Flutter yang benar.

### 5.2 Struktur direktori target

| Lokasi | Tanggung jawab |
| --- | --- |
| `lib/main_student.dart` | Bootstrap sesi mahasiswa demo |
| `lib/main_manager.dart` | Bootstrap sesi pengelola demo |
| `lib/app/` | App root, dependency wiring, route registry, session scope |
| `lib/core/design_system/` | Token dan komponen bersama sesuai F00 |
| `lib/core/models/` | Model domain bersama dan enum |
| `lib/core/data/` | Interface repository dan implementasi fake/shared DemoStore |
| `lib/core/utils/` | Format rupiah, clock, filter murni, validasi |
| `lib/features/catalog/` | Beranda, pencarian, stan, menu |
| `lib/features/assistant/` | Input kebutuhan, klarifikasi, hasil dummy |
| `lib/features/cart/` | Draft cart, catatan, undo, penggantian stan |
| `lib/features/orders/` | Submit, lookup, daftar, detail/timeline |
| `lib/features/manager/` | Dashboard, tindakan order, menu, pengaturan |
| `lib/features/profile/` | Profil, preferensi, notifikasi, bantuan, tentang |
| `assets/images/`, `assets/fonts/` | Salinan aset runtime dari sumber yang terverifikasi |
| `assets/fixtures/` | Fixture JSON serta metadata skenario |
| `test/`, `integration_test/` | Unit/widget/golden serta alur integrasi |
| `design/baseline/` | Sumber desain immutable, tidak digunakan sebagai layar full-image |

UI memanggil ViewModel; ViewModel memanggil interface repository. Tidak ada kalkulasi total atau perubahan status tersebar di build widget. Feature yang memakai cart membaca satu CartRepository, bukan membuat salinan cart sendiri. ViewModel boleh mengoordinasikan lebih dari satu repository; repository tidak saling mengimpor secara siklik. Repository fake dapat berbagi DemoStore internal.

### 5.3 Penggantian ke backend nanti

Interface repository adalah batas internal Dart, **bukan kontrak HTTP yang telah disepakati**. Setelah backend tersedia, tambahkan adapter remote dan mapping DTO ke model. Pertahankan hasil operasi, status, dan aturan UI; sepakati idempotency, authorization, validasi harga/stok, persistensi, error mapping, sinkronisasi, serta autentikasi melalui spesifikasi backend terpisah. Tidak cukup mengganti URL karena validasi client tidak menjamin keamanan transaksi server.

## 6. Model dan kontrak data dummy

### 6.1 Model minimum

| Model | Field dan tipe minimum | Invariant |
| --- | --- | --- |
| UserProfile | id:String, name:String, email:String, role:student/manager, stallId:String? | manager memiliki stallId; data contoh saja |
| Stall | id, name, description, location, block:String; imageAsset:String; isOpen:bool; prepMin/prepMax:int; scheduleLabel:String | prepMin <= prepMax; isOpen terpisah dari jadwal |
| MenuItem | id, stallId, name, description, imageAsset:String; priceRupiah:int; category:enum; tasteTags:Set; prepMin/prepMax:int; availability:available/soldOut | price >= 0; stallId harus ada |
| CatalogFilter | query:String; maxPriceRupiah:int?; maxWaitMinutes:int?; availableOnly:bool; category:enum?; stallId:String? | null berarti tanpa batas; scope stan diterapkan sebelum query |
| CartLine | lineId, menuId, stallId:String; nameSnapshot:String; unitPriceRupiah:int; quantity:int; note:String | quantity > 0; satu line per menu ID dalam scope awal |
| Cart | stallId:String?; lines:List; orderNote:String; revision:int | kosong berarti stallId null; satu stan; revision naik setiap mutasi |
| UndoSnapshot | removedLine, originalIndex, cartRevision, expiresAt | hanya dipakai pada cart yang kompatibel |
| OrderLine | menuId, name, unitPriceRupiah, quantity, note | immutable setelah order dibuat |
| Order | id, code, submissionId, studentId, stallId; lines; orderNote; totalRupiah; status; paymentStatus; rejectionReason?; createdAt; acceptedAt?; readyAt?; completedAt?; rejectedAt?; version:int | total dari snapshot; tanggal event mengikuti transisi sah |
| OrderEvent | orderId, fromStatus?, toStatus, at, sequence | append-only pada fake store; tidak menggandakan event pada retry |
| Submission | id; cartRevision; snapshot; state; orderId? | satu ID untuk satu logical submit; unknown tetap dilacak |
| FoodPreferences | taste:enum?; maxPriceRupiah:int?; maxWaitMinutes:int? | tersimpan terpisah dari draft form |
| NotificationSettings | permission:unknown/granted/denied; enabled:bool | permission simulasi berbeda dari pilihan enabled aplikasi |
| DataEnvelope<T> | data:T?; loadedAt; isStale:bool; error:AppError? | data stale dapat dipertahankan ketika refresh gagal |
| DemoScenario | key; seed; clock; latency; connectivity; outcomes | dapat direset; hasil tidak acak tanpa seed |

### 6.2 Repository interface minimum

Nama signature di bawah adalah rancangan internal; implementasi dapat memakai tipe Result/Either sendiri dengan makna yang sama. Tidak perlu menambah package hanya untuk membuat Result.

| Interface | Operasi | Keluaran/perilaku |
| --- | --- | --- |
| CatalogRepository | loadCatalog(), search(filter), getStall(id), getMenu(id) | Model terstruktur; data kosong dibedakan dari error |
| CartRepository | watchCart(), add(menuId, qty, note?), increment(lineId), decrement(lineId), remove(lineId), undo(), updateNote(), updateOrderNote(), clear(), replaceStall() | Satu sumber cart; guard satu stan; notifikasi perubahan |
| CartValidator | validate(cart, catalogSnapshot) | valid / empty / stallClosed / unavailableItems / invalidQuantity |
| RecommendationRepository | recommend(query) | matches / clarificationNeeded / empty / failure |
| OrderRepository | createOrder(submission), lookupSubmission(id), watchOrders(roleScope), getOrder(id), updateStatus(id, expectedVersion, action, reason?) | create idempotent di fake store; optimistic version guard untuk status |
| StallRepository | getSettings(stallId), saveSettings(draft), setOpen(), setMenuAvailability() | Perubahan tersimpan atomik; failure tidak memodifikasi state |
| PreferencesRepository | read(), save(draft), watch() | Persistensi selama sesi; draft bukan nilai tersimpan |
| SessionRepository | current(), clear() | Profil demo dan peran; bukan autentikasi nyata |
| NotificationPermissionGateway | readPermission(), requestPermission(), openSettingsSimulation() | Hasil skenario tanpa mengubah permission OS |
| DemoScenarioController | load(key), reset(), setConnectivity(), setNextOutcome() | Dipakai test/harness; tidak muncul di navigasi produk |

### 6.3 Dataset katalog baseline

| ID fixture | Menu | Stan | Harga | Estimasi | Status awal |
| --- | --- | --- | ---: | --- | --- |
| ayam | Nasi Ayam Sambal Matah | Dapur Bu Rina | Rp18.000 | 5–10 menit | Tersedia |
| telur | Nasi Telur Dadar | Dapur Bu Rina | Rp12.000 | 5–10 menit | Tersedia |
| sayur | Sayur Asem | Dapur Bu Rina | Rp6.000 | 5–10 menit | Habis |
| teh | Es Teh Manis | Dapur Bu Rina | Rp5.000 | 3–5 menit | Tersedia |
| kecap | Nasi Ayam Kecap | Dapur Bu Rina | Rp17.000 | 5–10 menit | Habis |
| mie | Mi Gomak | Kedai Pak Ucok | Rp15.000 | 5–10 menit | Tersedia |
| goreng | Nasi Goreng Spesial | Kedai Pak Ucok | Rp20.000 | 10–15 menit | Tersedia |
| geprek | Ayam Geprek | Warung Sinta | Rp16.000 | 10–15 menit | Tersedia |

Dapur Bu Rina berada di Blok A, Kedai Pak Ucok di Blok B, Warung Sinta di Blok C. Fixture mahasiswa Doni memakai doni@example.com; pengelola Bu Rina memakai rina@example.com. Metadata kategori/tag yang tidak ada di objek JS harus diberi penanda data tambahan A-06; jangan membuat klaim alergi/nutrisi.

### 6.4 Fixture order dan konsistensi angka

| Kode | Pemilik | Keadaan fixture antrean | Jumlah/total | Waktu sumber |
| --- | --- | --- | --- | --- |
| KC-027 | Doni | waiting | 2 porsi / Rp30.000 | dibuat 12.05 |
| KC-028 | Ayu | waiting | 1 porsi / Rp18.000 | dibuat 12.05 |
| KC-029 | Bima | waiting | 2 porsi / Rp24.000 | dibuat 12.06 |
| KC-025 | Raka | processing | 1 porsi / Rp12.000 | mulai 11.58 |
| KC-026 | Sari | processing | 1 porsi / Rp18.000 | mulai 12.01 |
| KC-024 | Dita | ready | 2 porsi / Rp23.000 | siap 12.03 |
| KC-019 | Doni | completed, riwayat mahasiswa | 1 porsi / Rp18.000 | 3 Sep |
| KC-018 | Rani | rejected, riwayat pengelola | Rp12.000 | 5 Sep 13.10 |

Detail komposisi KC-028/029/025/026/024 tidak seluruhnya ditetapkan sumber. Untuk demo interaktif usulkan ayam ×1; telur ×2; telur ×1; ayam ×1; ayam ×1 + teh ×1 secara berurutan. Ini **A-12**, bukan rincian yang diklaim terbaca dari gambar detail. Untuk menghasilkan dashboard 24 secara konsisten, seed 18 order completed tambahan pada hari demo; ID buatan harus berbeda dan ditandai fixture tambahan. Jangan hanya hardcode angka dashboard.

KC-027 pada halaman selesai/ditolak adalah **varian skenario** dari pesanan yang sama. Dalam satu store ia hanya memiliki satu status. Skenario screenshot `screen_M34` boleh memulai KC-027 sebagai completed, sedangkan `journey_order` memulai waiting dan mengubahnya lewat aksi.

### 6.5 Masa hidup data dan reset

**A-02:** seluruh data bersifat in-memory. Navigasi, membuka/menutup sheet, dan perubahan role melalui test harness dalam satu proses mempertahankan DemoStore. Cold restart mengembalikan fixture; tidak ada persistensi lintas perangkat atau jaminan bertahan setelah proses dimatikan. Hot reload pengembang bukan kontrak produk. Logout membersihkan state privat sesi; arah layar setelah logout mengikuti D-08. Untuk demo lintas peran, gunakan harness satu proses atau skenario scripted; jangan menyebut dua emulator terpisah tersinkron.

### 6.6 Hasil operasi dan simulasi

| Hasil internal | Makna | Efek yang diwajibkan |
| --- | --- | --- |
| success(data) | Operasi selesai | Tampilkan hasil; mutasi state satu kali |
| empty | Operasi sukses tanpa data | Empty state, bukan error |
| offline | Skenario tidak terhubung | Cache jika ada; blok aksi yang memerlukan hasil baru |
| knownFailure | Diketahui tidak berhasil | Retry eksplisit, pertahankan draft/data lama |
| unknownOutcome | Create mungkin berhasil | M27 dan lookup submission; jangan langsung create ulang |
| conflict | expectedVersion/status tidak lagi sesuai | Refresh order; jangan overwrite data terbaru |
| validationFailure | Cart/item/stan tidak valid | Tinjau data sebelum submit |

Latensi default usulan **600 ms** melalui injected scheduler; unit test memakai fake clock tanpa menunggu waktu nyata. Skenario loading dapat ditahan oleh harness. Untuk unknown tersedia dua kasus terpisah: tersimpan tetapi respons hilang, dan tidak tersimpan tetapi hasil belum dapat dipastikan. Lookup juga dapat tetap unknown; tidak boleh mengasumsikan `not found` lokal sementara sebagai bukti gagal permanen pada backend mendatang.

## 7. Status, navigasi, dan operasi asynchronous

### 7.1 Transisi order

| Status awal | Aksi | Prasyarat | Status akhir | Pembayaran | Referensi |
| --- | --- | --- | --- | --- | --- |
| Belum ada order | Buat pesanan sukses | Cart valid, submission unik | waiting | unpaidCash | M24–M28 |
| waiting | Terima & siapkan | Pengelola stan sama, expectedVersion cocok | processing | unpaidCash | P08 → P09 |
| waiting | Tolak pesanan | Alasan enum dipilih | rejected | notCharged | P13 → P14, M35 |
| processing | Tandai siap diambil | Operasi berhasil | ready | unpaidCash | P09 → P10, M33 |
| ready | Ya, selesaikan | Penyerahan dan tunai dikonfirmasi | completed | cashReceived | P11 → P12, M34 |
| terminal | Aksi mutasi order | Tidak sah | Tidak berubah | Tidak berubah | Hanya baca |
| status apa pun | Refresh gagal | Ada snapshot lama | Tidak berubah | Tidak berubah | S08/S16/S17 sesuai konteks |

`Menunggu`/`Baru` pada list adalah label ringkas untuk status yang sama dengan `Menunggu konfirmasi`, bukan enum order tambahan. `Membuat pesanan`, `Pesanan belum terkirim`, dan `hasil belum diketahui` adalah status operasi submission, bukan status order.

### 7.2 Route dan Back

| Kelompok | Route target yang diusulkan | Parameter/state |
| --- | --- | --- |
| Shell mahasiswa | `/student/home`, `/student/orders`, `/student/profile` | Tab terpilih dipertahankan |
| Katalog | `/search`, `/stalls/:stallId`, `/menus/:menuId` | Query/filter dan asal navigasi |
| Asisten | Sheet pada halaman asal; `/recommendations` | Draft kebutuhan dan cart bersama |
| Checkout | `/cart`, `/checkout`, `/order-success/:orderId` | Cart revision, submissionId; ID order hanya setelah sukses |
| Detail mahasiswa | `/student/orders/:orderId` | Order harus milik mahasiswa aktif |
| Shell pengelola | `/manager/dashboard`, `/manager/orders`, `/manager/menu`, `/manager/profile` | Scope stallId pengelola |
| Detail pengelola | `/manager/orders/:orderId` | Expected version untuk mutasi |
| Pendukung | `/preferences`, `/notifications`, `/help`, `/about`, `/account`, `/stall-settings` | Kembali ke role/route pemanggil |

Route adalah rancangan teknis; layar tidak harus memiliki class terpisah per PNG. M31–M35 dapat memakai satu detail view dengan state berbeda. S dan Q umumnya varian layar, bukan destinasi navigasi baru.

Back menutup keyboard terlebih dahulu bila aktif; kemudian modal/sheet sesuai perilaku platform; kemudian halaman. Back pada draft form yang belum disimpan membuang draft sesuai A-03. Mengganti tab tidak menghapus cart. Back/close pada dialog destruktif sama dengan aksi batal. Jika operasi asynchronous masih berjalan, controller memeriksa lifecycle; respons usang tidak menimpa state terbaru.

### 7.3 Konsistensi dan race condition

- Satu operasi mutasi aktif per entity. Disable/reject tap berulang sampai hasil diketahui.
- Query pencarian memakai generation/request ID agar hasil query lama tidak menimpa query terbaru.
- State submit disimpan pada coordinator/repository yang hidup lebih lama daripada halaman checkout.
- `lookupSubmission` mengembalikan order yang sudah ada bila request yang sama telah berhasil.
- Jika pengguna mengedit cart setelah hasil **knownFailure**, perubahan snapshot memerlukan submission ID baru. ID lama tidak boleh dipakai untuk payload berbeda. Pada **unknownOutcome**, selesaikan lookup niat lama sebelum membuka submit baru; perubahan cart baru tidak mengubah snapshot operasi yang masih dilacak.
- Success hanya membersihkan cart bila cartRevision masih cocok dengan snapshot submission; cart baru yang dibuat pengguna tidak boleh ikut terhapus.
- Update status memakai expectedVersion; respons konflik tidak boleh menandai pesanan sebagai sukses.
- Stream/controller/listener dibersihkan pada dispose; tidak ada setState setelah widget dibuang.

## 8. Fondasi visual

### 8.1 Token warna

| Token | Nilai |
| --- | --- |
| background / surface / alt | #FAFAF8 / #FFFFFF / #F7F3F0 |
| brand / action / active | #E85D2A / #C74418 / #9B341B |
| text / secondary / outline | #251B17 / #6D5A50 / #DDD6D1 |
| disabled / accent | #A99A92 / #F4B740 |
| available foreground / background | #2E7D32 / #E7F5E8 |
| waiting foreground / background | #906000 / #FFF1C2 |
| processing foreground / background | #A54B00 / #FFE7CC |
| ready foreground / background | #167A56 / #DDF5EA |
| completed foreground / background | #475569 / #EEF2F6 |
| destructive/rejected foreground / background | #B3261E / #FCE8E6 |

### 8.2 Ukuran dan tipografi sumber

F00 menyatakan Plus Jakarta Sans; H1 24/32, H2 20/28, judul 18/24, body 16/24, metadata 14/20. CSS layar memakai varian lebih kecil pada beberapa row: nama menu 14/19, metadata 12/17, badge 11/14, nav 10. **Jangan mengganti semua font menjadi ukuran F00 secara massal**; konflik D-03 dicatat untuk penetapan acuan final.

| Komponen | Ukuran visual sumber |
| --- | --- |
| Padding horizontal halaman | 16 dp |
| App bar | 56 dp, di luar status bar simulasi |
| Input pencarian | 52 dp, radius 12 dp |
| Foto menu normal | 88 × 88 dp, radius 12 dp |
| Hero stan/menu | Tinggi 158 dp, radius 14 dp |
| Tombol utama | Minimum tinggi 50 dp, radius 12 dp |
| Chip | Minimum visual 38 dp, radius 20 dp |
| Quantity control | Tinggi visual 44 dp, slot 36 dp |
| Bottom navigation | 72 dp pada render sumber |
| Sticky cart | 70 dp; baseline di atas navigasi atau standalone pada detail |
| FAB | 56 × 56 dp |
| Bottom sheet | Radius atas 24 dp; isi dapat scroll |
| Dialog | Radius 18 dp |

F00 meminta area sentuh minimal 48 × 48 dp, sedangkan sejumlah elemen CSS lebih kecil. Hit target tak terlihat dapat diperluas hanya bila tidak tumpang tindih; jika layout perlu bergeser, keputusan D-03 berlaku. Status bar dan keyboard HTML adalah ilustrasi lingkungan; Flutter memakai status bar/keyboard perangkat dan SafeArea, tidak menggambar keyboard palsu.

## 9. Kebutuhan nonfungsional

| ID | Kebutuhan terukur | Cara memeriksa |
| --- | --- | --- |
| NFR-01 | Semua 88 referensi memiliki mapping, fixture, dan hasil review; konflik terbuka tidak diberi label lulus | Matriks bagian 12 dan checklist roadmap |
| NFR-02 | Tidak ada overflow/render exception pada 360, 390, 412 dp untuk flow terkait; konten panjang dapat digulir | Widget/layout test Q01–Q06 dan pemeriksaan perangkat |
| NFR-03 | Text scale 1.0 dan 1.5 dapat digunakan tanpa menyembunyikan aksi penting | Widget test + inspeksi Q03/Q04, menunggu acuan konflik |
| NFR-04 | Tombol ikon memiliki nama aksesibel, switch/chip mengumumkan selected/disabled, status tidak hanya warna | Semantics test terpilih dan TalkBack pada alur order |
| NFR-05 | Total, quantity, one-stall guard, dan transisi order konsisten di semua tampilan | Unit test perhitungan dan integration test lintas peran |
| NFR-06 | Tap ganda submit/accept/complete menghasilkan satu mutasi logis | Test request count dan event count |
| NFR-07 | App demo dapat memuat font/foto/data normal tanpa jaringan | Jalankan skenario normal dengan jaringan perangkat dimatikan; offline UI tetap dipicu lewat controller |
| NFR-08 | Error menjaga input dan data terakhir sesuai konteks; retry tidak duplikasi | S01–S17 dan M15/M26/M27/U08 |
| NFR-09 | Tidak ada password, token, key AI, atau data pribadi nyata dalam fixture/repository | Review file sebelum commit |
| NFR-10 | Tidak ada kalkulasi uang dalam double atau total hardcode dalam widget | Unit test + review struktur |
| NFR-11 | SDK dan dependency terkunci, format/analyze/test relevan lulus | CI setelah diimplementasikan; tidak ada klaim lulus pada dokumen awal |
| NFR-12 | Aksi lokal memberi feedback pada frame berikutnya; latensi fake tidak memblokir UI isolate | Profil/periksa scroll dan tap selama delay 600 ms; target bukan angka performa terukur saat ini |
| NFR-13 | Semua task UI merujuk screen ID; PR menunjukkan apa yang berubah dan bukti pemeriksaan | Template Issue/PR pada ROADMAP |
| NFR-14 | Tidak ada state tersebar yang membuat dashboard, cart, order detail saling berbeda | Integration test store bersama dan observer |
| NFR-15 | Baseline tidak berubah selama implementasi | Cocokkan SHA-256 pada bagian 14 |

Panduan semantics, text scaling, dan pemeriksaan aksesibilitas merujuk [dokumentasi aksesibilitas Flutter](https://docs.flutter.dev/ui/accessibility). Dokumen ini tidak menyatakan aplikasi telah lulus audit aksesibilitas.

## 10. Skenario dan penerimaan end-to-end

| ID | Kondisi dan aksi | Hasil wajib | Cakupan |
| --- | --- | --- | --- |
| AT-01 | Dari beranda tambah ayam satu dan telur satu | Cart dua porsi Rp30.000 pada semua view | M01/M03/M07/M09/M17 |
| AT-02 | Edit catatan ayam, simpan, buka checkout | Catatan sama, catatan order terpisah, total tetap | M18/M24 |
| AT-03 | Hapus telur lalu Urungkan dalam lima detik | Rp18.000 kembali Rp30.000; quantity/catatan pulih | M19 |
| AT-04 | Tambah Mi Gomak dari cart Bu Rina; batal lalu setuju | Batal tidak mengubah; setuju satu Mi Gomak Rp15.000 | M21 |
| AT-05 | Ubah telur menjadi Habis sebelum checkout | Total valid Rp18.000, submit diblokir, hapus invalid memulihkan alur | M23/P15 |
| AT-06 | Submit sukses lalu pengelola accept → ready → complete | Satu order berubah di kedua role; tunai baru diterima pada complete | M24–M34/P08–P12 |
| AT-07 | Pengelola menolak waiting dengan Menu tidak tersedia | Mahasiswa melihat alasan; tidak ditagihkan; pindah riwayat | P13/P14/M35 |
| AT-08 | Tap Buat pesanan berulang; response hilang setelah order disimpan | M27; lookup menemukan order sama; jumlah order hanya satu | M25/M27/M28 |
| AT-09 | Create dipastikan belum tersimpan lalu retry | Cart tetap; satu order dibuat saat retry sukses | M26 |
| AT-10 | Lookup terus unknown | Tetap M27; tidak muncul pesanan sukses palsu atau create kedua | M27 |
| AT-11 | Tutup stan dengan enam order aktif | Order baru diblokir; enam order lama masih dapat diproses | P02/P03/S06 |
| AT-12 | Update siap atau availability gagal | State tersimpan lama bertahan; retry menargetkan intent yang sama | S16/P16 |
| AT-13 | Offline dengan dan tanpa cache | Cache ditandai stale; tanpa cache empty; mutasi yang dilarang tidak berjalan | S03/S04/S17 |
| AT-14 | Asisten ambiguity, gagal, dan kosong | Klarifikasi/retry/manual search tersedia; tidak memanggil API AI | M12/M15/M16 |
| AT-15 | Tolak izin notifikasi dummy lalu pantau pesanan | Order tetap dapat dipantau | U01/U02 |
| AT-16 | Gagal simpan pengaturan lalu retry | Draft dipertahankan; repository berubah hanya sesudah sukses | U08 |
| AT-17 | Cart empat jenis/delapan porsi | Total Rp94.000; item terakhir dapat dijangkau | Q05 |
| AT-18 | Layar sempit, teks besar, keyboard aktif | Tidak kehilangan input/aksi; keputusan konflik visual ditutup | Q01–Q06 |
| AT-19 | Cold restart demo | Fixture kembali; keterbatasan persistensi sesuai README | A-02 |
| AT-20 | Perubahan role dalam harness satu proses | Mahasiswa hanya order sendiri; pengelola hanya stan sendiri | Session scope |

Pengujian bisnis wajib untuk kalkulasi, satu stan, undo, status, dan idempotency. Jangan membuat satu test sepele untuk setiap label hanya demi jumlah test. Screenshot review tetap per referensi; golden otomatis diprioritaskan pada komponen bersama dan varian berisiko. Tugas baru dinyatakan selesai setelah implementasi, bukti pemeriksaan yang relevan, dan review terpenuhi.

## 11. Versi dan ketertelusuran

Versi dokumen, baseline desain, dan versi aplikasi adalah tiga hal terpisah. Baseline KC-DS-20260906 tidak berubah ketika milestone aplikasi meningkat. Target versi rilis mengikuti tabel roadmap; semua target awal belum dirilis.

Format task: `KC-<SCREEN>-<NN>` untuk layar, `KC-ENG-<NN>` untuk fondasi teknis, `KC-DATA-<NN>` untuk data, `KC-LOGIC-<NN>` untuk aturan bersama, `KC-QA-<NN>` untuk integrasi, `KC-REL-<NN>` untuk rilis. Requirement per referensi adalah `FR-<SCREEN>`, subkebutuhan `FR-<SCREEN>.<NN>`. Task `KC-M01-02` memenuhi `FR-M01.02`. Ini membuat satu tombol dapat ditugaskan tanpa mengambil seluruh Beranda.

Milestone 0.x bersifat bertahap dan belum menggambarkan aplikasi lengkap. Callback lintas milestone ditandai jelas, misalnya komponen Tambah pada M08 dibangun di 0.2.0 tetapi mutasi cart terhubung melalui M09 pada 0.4.0. Jangan menyebut interaksi lintas milestone lulus sebelum task dependensinya selesai.


## 12. Spesifikasi setiap referensi

Seluruh kebutuhan pada tabel berikut wajib untuk target demo lengkap, kecuali bagian D-ID yang belum mempunyai keputusan final. Setiap nomor subkebutuhan memetakan langsung ke task dengan nomor sama pada roadmap. Asal visual/copy adalah B; perilaku tambahan mengikuti BR/A/D yang disebut. Bukti penerimaan terdiri dari fixture, aksi/hasil yang ditetapkan, screenshot review, serta test terpilih menurut risiko.

### 12.1 Inventaris dan target versi

| ID | Referensi | Target | Requirement | Jumlah task |
| --- | --- | --- | --- | ---: |
| F00 | [Fondasi visual dan komponen](design/baseline/screens/F00_fondasi_visual_dan_komponen.png) | KantinCerdasv0.1.0 | FR-F00 | 44 |
| M01 | [Beranda, kunjungan kembali](design/baseline/screens/M01_beranda_kunjungan_kembali.png) | KantinCerdasv0.2.0 | FR-M01 | 17 |
| M02 | [Pengenalan asisten](design/baseline/screens/M02_pengenalan_asisten.png) | KantinCerdasv0.3.0 | FR-M02 | 4 |
| M03 | [Beranda dengan cart](design/baseline/screens/M03_beranda_dengan_cart.png) | KantinCerdasv0.4.0 | FR-M03 | 6 |
| M04 | [Hasil pencarian](design/baseline/screens/M04_hasil_pencarian.png) | KantinCerdasv0.2.0 | FR-M04 | 9 |
| M05 | [Filter pencarian](design/baseline/screens/M05_filter_pencarian.png) | KantinCerdasv0.2.0 | FR-M05 | 6 |
| M06 | [Detail stan buka](design/baseline/screens/M06_detail_stan_buka.png) | KantinCerdasv0.2.0 | FR-M06 | 11 |
| M07 | [Detail stan dengan cart](design/baseline/screens/M07_detail_stan_dengan_cart.png) | KantinCerdasv0.4.0 | FR-M07 | 6 |
| M08 | [Detail menu](design/baseline/screens/M08_detail_menu.png) | KantinCerdasv0.2.0 | FR-M08 | 8 |
| M09 | [Menu berhasil ditambahkan](design/baseline/screens/M09_menu_berhasil_ditambahkan.png) | KantinCerdasv0.4.0 | FR-M09 | 5 |
| M10 | [Asisten pilih menu](design/baseline/screens/M10_asisten_pilih_menu.png) | KantinCerdasv0.3.0 | FR-M10 | 8 |
| M11 | [Asisten dengan keyboard](design/baseline/screens/M11_asisten_dengan_keyboard.png) | KantinCerdasv0.3.0 | FR-M11 | 4 |
| M12 | [Asisten meminta klarifikasi](design/baseline/screens/M12_asisten_meminta_klarifikasi.png) | KantinCerdasv0.3.0 | FR-M12 | 5 |
| M13 | [Hasil rekomendasi](design/baseline/screens/M13_hasil_rekomendasi.png) | KantinCerdasv0.3.0 | FR-M13 | 7 |
| M14 | [Rekomendasi dengan cart](design/baseline/screens/M14_rekomendasi_dengan_cart.png) | KantinCerdasv0.4.0 | FR-M14 | 5 |
| M15 | [Asisten gagal](design/baseline/screens/M15_asisten_gagal.png) | KantinCerdasv0.3.0 | FR-M15 | 4 |
| M16 | [Rekomendasi kosong](design/baseline/screens/M16_rekomendasi_kosong.png) | KantinCerdasv0.3.0 | FR-M16 | 4 |
| M17 | [Keranjang dua porsi](design/baseline/screens/M17_keranjang_dua_porsi.png) | KantinCerdasv0.4.0 | FR-M17 | 14 |
| M18 | [Edit catatan item](design/baseline/screens/M18_edit_catatan_item.png) | KantinCerdasv0.4.0 | FR-M18 | 6 |
| M19 | [Hapus item dengan undo](design/baseline/screens/M19_hapus_item_dengan_undo.png) | KantinCerdasv0.4.0 | FR-M19 | 5 |
| M20 | [Konfirmasi kosongkan cart](design/baseline/screens/M20_konfirmasi_kosongkan_cart.png) | KantinCerdasv0.4.0 | FR-M20 | 4 |
| M21 | [Ganti stan](design/baseline/screens/M21_ganti_stan.png) | KantinCerdasv0.4.0 | FR-M21 | 5 |
| M22 | [Keranjang kosong](design/baseline/screens/M22_keranjang_kosong.png) | KantinCerdasv0.4.0 | FR-M22 | 4 |
| M23 | [Ketersediaan berubah](design/baseline/screens/M23_ketersediaan_berubah.png) | KantinCerdasv0.4.0 | FR-M23 | 6 |
| M24 | [Konfirmasi pesanan](design/baseline/screens/M24_konfirmasi_pesanan.png) | KantinCerdasv0.5.0 | FR-M24 | 7 |
| M25 | [Membuat pesanan](design/baseline/screens/M25_membuat_pesanan.png) | KantinCerdasv0.5.0 | FR-M25 | 5 |
| M26 | [Pesanan belum terkirim](design/baseline/screens/M26_pesanan_belum_terkirim.png) | KantinCerdasv0.5.0 | FR-M26 | 4 |
| M27 | [Hasil pengiriman belum diketahui](design/baseline/screens/M27_hasil_pengiriman_belum_diketahui.png) | KantinCerdasv0.5.0 | FR-M27 | 6 |
| M28 | [Pesanan berhasil](design/baseline/screens/M28_pesanan_berhasil.png) | KantinCerdasv0.5.0 | FR-M28 | 7 |
| M29 | [Pesanan aktif](design/baseline/screens/M29_pesanan_aktif.png) | KantinCerdasv0.5.0 | FR-M29 | 6 |
| M30 | [Riwayat mahasiswa](design/baseline/screens/M30_riwayat_mahasiswa.png) | KantinCerdasv0.5.0 | FR-M30 | 5 |
| M31 | [Menunggu konfirmasi](design/baseline/screens/M31_menunggu_konfirmasi.png) | KantinCerdasv0.5.0 | FR-M31 | 6 |
| M32 | [Pesanan diproses](design/baseline/screens/M32_pesanan_diproses.png) | KantinCerdasv0.5.0 | FR-M32 | 6 |
| M33 | [Siap diambil](design/baseline/screens/M33_siap_diambil.png) | KantinCerdasv0.5.0 | FR-M33 | 6 |
| M34 | [Pesanan selesai](design/baseline/screens/M34_pesanan_selesai.png) | KantinCerdasv0.5.0 | FR-M34 | 6 |
| M35 | [Pesanan ditolak](design/baseline/screens/M35_pesanan_ditolak.png) | KantinCerdasv0.5.0 | FR-M35 | 6 |
| M36 | [Profil mahasiswa](design/baseline/screens/M36_profil_mahasiswa.png) | KantinCerdasv0.7.0 | FR-M36 | 7 |
| M37 | [Preferensi makanan](design/baseline/screens/M37_preferensi_makanan.png) | KantinCerdasv0.7.0 | FR-M37 | 6 |
| P01 | [Dashboard pengelola](design/baseline/screens/P01_dashboard_pengelola.png) | KantinCerdasv0.6.0 | FR-P01 | 16 |
| P02 | [Dialog menutup stan](design/baseline/screens/P02_dialog_menutup_stan.png) | KantinCerdasv0.6.0 | FR-P02 | 5 |
| P03 | [Dashboard stan tutup](design/baseline/screens/P03_dashboard_stan_tutup.png) | KantinCerdasv0.6.0 | FR-P03 | 5 |
| P04 | [Pesanan baru](design/baseline/screens/P04_pesanan_baru.png) | KantinCerdasv0.6.0 | FR-P04 | 6 |
| P05 | [Pesanan diproses](design/baseline/screens/P05_pesanan_diproses.png) | KantinCerdasv0.6.0 | FR-P05 | 6 |
| P06 | [Pesanan siap](design/baseline/screens/P06_pesanan_siap.png) | KantinCerdasv0.6.0 | FR-P06 | 6 |
| P07 | [Riwayat pengelola](design/baseline/screens/P07_riwayat_pengelola.png) | KantinCerdasv0.6.0 | FR-P07 | 6 |
| P08 | [Detail pesanan baru](design/baseline/screens/P08_detail_pesanan_baru.png) | KantinCerdasv0.6.0 | FR-P08 | 8 |
| P09 | [Detail pesanan diproses](design/baseline/screens/P09_detail_pesanan_diproses.png) | KantinCerdasv0.6.0 | FR-P09 | 5 |
| P10 | [Detail siap diambil](design/baseline/screens/P10_detail_siap_diambil.png) | KantinCerdasv0.6.0 | FR-P10 | 4 |
| P11 | [Konfirmasi penyerahan](design/baseline/screens/P11_konfirmasi_penyerahan.png) | KantinCerdasv0.6.0 | FR-P11 | 5 |
| P12 | [Detail pesanan selesai](design/baseline/screens/P12_detail_pesanan_selesai.png) | KantinCerdasv0.6.0 | FR-P12 | 4 |
| P13 | [Konfirmasi penolakan](design/baseline/screens/P13_konfirmasi_penolakan.png) | KantinCerdasv0.6.0 | FR-P13 | 7 |
| P14 | [Detail pesanan ditolak](design/baseline/screens/P14_detail_pesanan_ditolak.png) | KantinCerdasv0.6.0 | FR-P14 | 4 |
| P15 | [Kelola menu](design/baseline/screens/P15_kelola_menu.png) | KantinCerdasv0.7.0 | FR-P15 | 8 |
| P16 | [Gagal ubah ketersediaan](design/baseline/screens/P16_gagal_ubah_ketersediaan.png) | KantinCerdasv0.7.0 | FR-P16 | 4 |
| P17 | [Pengaturan stan](design/baseline/screens/P17_pengaturan_stan.png) | KantinCerdasv0.7.0 | FR-P17 | 9 |
| P18 | [Profil pengelola](design/baseline/screens/P18_profil_pengelola.png) | KantinCerdasv0.7.0 | FR-P18 | 7 |
| Q01 | [Beranda cart — 360 dp](design/baseline/screens/Q01_beranda_cart_360_dp.png) | KantinCerdasv0.9.0 | FR-Q01 | 4 |
| Q02 | [Detail stan — 412 dp](design/baseline/screens/Q02_detail_stan_412_dp.png) | KantinCerdasv0.9.0 | FR-Q02 | 4 |
| Q03 | [Beranda teks 150%](design/baseline/screens/Q03_beranda_teks_150.png) | KantinCerdasv0.9.0 | FR-Q03 | 4 |
| Q04 | [Rekomendasi teks panjang](design/baseline/screens/Q04_rekomendasi_teks_panjang.png) | KantinCerdasv0.9.0 | FR-Q04 | 5 |
| Q05 | [Keranjang delapan porsi](design/baseline/screens/Q05_keranjang_delapan_porsi.png) | KantinCerdasv0.9.0 | FR-Q05 | 5 |
| Q06 | [Cart dengan keyboard](design/baseline/screens/Q06_cart_dengan_keyboard.png) | KantinCerdasv0.9.0 | FR-Q06 | 5 |
| S01 | [Loading Beranda](design/baseline/screens/S01_loading_beranda.png) | KantinCerdasv0.8.0 | FR-S01 | 5 |
| S02 | [Hasil pencarian kosong](design/baseline/screens/S02_hasil_pencarian_kosong.png) | KantinCerdasv0.8.0 | FR-S02 | 3 |
| S03 | [Offline dengan data](design/baseline/screens/S03_offline_dengan_data.png) | KantinCerdasv0.8.0 | FR-S03 | 6 |
| S04 | [Offline tanpa data](design/baseline/screens/S04_offline_tanpa_data.png) | KantinCerdasv0.8.0 | FR-S04 | 3 |
| S05 | [Gagal memuat Pesanan](design/baseline/screens/S05_gagal_memuat_pesanan.png) | KantinCerdasv0.8.0 | FR-S05 | 3 |
| S06 | [Detail stan tutup](design/baseline/screens/S06_detail_stan_tutup.png) | KantinCerdasv0.8.0 | FR-S06 | 5 |
| S07 | [Detail menu habis](design/baseline/screens/S07_detail_menu_habis.png) | KantinCerdasv0.8.0 | FR-S07 | 3 |
| S08 | [Pembaruan status gagal](design/baseline/screens/S08_pembaruan_status_gagal.png) | KantinCerdasv0.8.0 | FR-S08 | 4 |
| S09 | [Loading daftar pesanan](design/baseline/screens/S09_loading_daftar_pesanan.png) | KantinCerdasv0.8.0 | FR-S09 | 3 |
| S10 | [Gagal memuat katalog](design/baseline/screens/S10_gagal_memuat_katalog.png) | KantinCerdasv0.8.0 | FR-S10 | 3 |
| S11 | [Stan belum memiliki menu](design/baseline/screens/S11_stan_belum_memiliki_menu.png) | KantinCerdasv0.8.0 | FR-S11 | 3 |
| S12 | [Pesanan mahasiswa kosong](design/baseline/screens/S12_pesanan_mahasiswa_kosong.png) | KantinCerdasv0.8.0 | FR-S12 | 3 |
| S13 | [Antrean pengelola kosong](design/baseline/screens/S13_antrean_pengelola_kosong.png) | KantinCerdasv0.8.0 | FR-S13 | 3 |
| S14 | [Filter menu kosong](design/baseline/screens/S14_filter_menu_kosong.png) | KantinCerdasv0.8.0 | FR-S14 | 3 |
| S15 | [Foto makanan gagal](design/baseline/screens/S15_foto_makanan_gagal.png) | KantinCerdasv0.8.0 | FR-S15 | 3 |
| S16 | [Gagal ubah status](design/baseline/screens/S16_gagal_ubah_status.png) | KantinCerdasv0.8.0 | FR-S16 | 4 |
| S17 | [Pengelola offline](design/baseline/screens/S17_pengelola_offline.png) | KantinCerdasv0.8.0 | FR-S17 | 5 |
| U01 | [Penjelasan notifikasi](design/baseline/screens/U01_penjelasan_notifikasi.png) | KantinCerdasv0.7.0 | FR-U01 | 5 |
| U02 | [Izin notifikasi ditolak](design/baseline/screens/U02_izin_notifikasi_ditolak.png) | KantinCerdasv0.7.0 | FR-U02 | 4 |
| U03 | [Notifikasi aktif](design/baseline/screens/U03_notifikasi_aktif.png) | KantinCerdasv0.7.0 | FR-U03 | 4 |
| U04 | [Bantuan](design/baseline/screens/U04_bantuan.png) | KantinCerdasv0.7.0 | FR-U04 | 7 |
| U05 | [Tentang KantinCerdas](design/baseline/screens/U05_tentang_kantincerdas.png) | KantinCerdasv0.7.0 | FR-U05 | 5 |
| U06 | [Data akun pengelola](design/baseline/screens/U06_data_akun_pengelola.png) | KantinCerdasv0.7.0 | FR-U06 | 5 |
| U07 | [Konfirmasi keluar](design/baseline/screens/U07_konfirmasi_keluar.png) | KantinCerdasv0.7.0 | FR-U07 | 4 |
| U08 | [Simpan pengaturan gagal](design/baseline/screens/U08_simpan_pengaturan_gagal.png) | KantinCerdasv0.7.0 | FR-U08 | 4 |
| U09 | [Preferensi tersimpan](design/baseline/screens/U09_preferensi_tersimpan.png) | KantinCerdasv0.7.0 | FR-U09 | 3 |

### 12.2 Kebutuhan rinci per referensi

#### FR-F00 — Fondasi visual dan komponen

**Acuan:** [F00](design/baseline/screens/F00_fondasi_visual_dan_komponen.png) · **Target:** KantinCerdasv0.1.0 · **Fixture:** `screen_F00`

**Kondisi awal/pemicu:** Referensi bersama seluruh layar; bukan halaman pengguna.

**Prasyarat teknis:** Scaffold ENG; nilai sumber CSS dan F00; D-03 pada metrik konflik.

**Hasil/alur keluar:** Komponen Flutter dapat dipakai ulang tanpa mengganti identitas visual.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-F00.01 | Mendaftarkan token background | Warna latar #FAFAF8 tersedia dalam tema. |
| FR-F00.02 | Mendaftarkan token surface | Warna permukaan #FFFFFF tersedia dalam tema. |
| FR-F00.03 | Mendaftarkan token surface alternatif | Warna #F7F3F0 tersedia dalam tema. |
| FR-F00.04 | Mendaftarkan token brand | Warna #E85D2A dipakai untuk identitas dan FAB. |
| FR-F00.05 | Mendaftarkan token action | Warna #C74418 dipakai untuk aksi utama. |
| FR-F00.06 | Mendaftarkan token active | Warna #9B341B dipakai untuk penanda aktif. |
| FR-F00.07 | Mendaftarkan token teks | Teks utama #251B17 dan sekunder #6D5A50 dapat dirujuk dengan nama semantik. |
| FR-F00.08 | Mendaftarkan token outline | Garis pembatas menggunakan #DDD6D1. |
| FR-F00.09 | Mendaftarkan token status | Pasangan warna teks/latar setiap status mengikuti tabel token SRS. |
| FR-F00.10 | Mendaftarkan font Plus Jakarta Sans | Lima berkas font lokal dikenali sebagai bobot 400, 500, 600, 700, 800. |
| FR-F00.11 | Mendaftarkan skala tipografi | Gaya F00 dan gaya spesifik layar dipisahkan sesuai catatan konflik D-03. **BLOCKED: D-03.** |
| FR-F00.12 | Mendaftarkan token jarak | Grid 8 dp, padding halaman 16 dp, serta pengecualian CSS tercatat. |
| FR-F00.13 | Mendaftarkan token radius | Radius input/tombol 12 dp dan radius atas sheet 24 dp tersedia. |
| FR-F00.14 | Membuat ikon bersama | Bentuk glyph mengikuti SVG app.js, tanpa mengganti keluarga ikon. |
| FR-F00.15 | Membuat tombol primary | Tampilan normal mengikuti F00 dan callback menerima aksi pemanggil. |
| FR-F00.16 | Membuat tombol secondary | Outline dan warna mengikuti F00. |
| FR-F00.17 | Membuat tombol ghost | Aksi sekunder tanpa latar mengikuti sumber. |
| FR-F00.18 | Membuat tombol destructive | Warna merah hanya dipakai untuk tindakan destruktif. |
| FR-F00.19 | Membuat state disabled tombol | Tap tidak memanggil callback ketika disabled. |
| FR-F00.20 | Membuat state loading tombol | Tap ganda dicegah dan label proses ditampilkan. |
| FR-F00.21 | Membuat tombol ikon | Nama aksesibel tersedia; area sentuh mengikuti keputusan D-03. **BLOCKED: D-03.** |
| FR-F00.22 | Membuat input catatan | Label tetap ada ketika field berisi teks dan fokus mengikuti sumber. |
| FR-F00.23 | Membuat chip pilihan | State selected menampilkan warna dan tanda centang bila ada di sumber. |
| FR-F00.24 | Membuat radio pilihan | Hanya satu nilai terpilih dalam satu kelompok. |
| FR-F00.25 | Membuat switch | Status aktif dan nonaktif memiliki semantics yang benar. |
| FR-F00.26 | Membuat badge status | Teks status selalu tampil sehingga arti tidak bergantung pada warna. |
| FR-F00.27 | Membuat row menu | Foto, nama, metadata, harga, badge, dan slot aksi mengikuti sumber. |
| FR-F00.28 | Membuat kontrol jumlah | Tombol minus dan plus menerima callback terpisah. |
| FR-F00.29 | Membuat row stan | Nama, lokasi, status, foto, dan arah navigasi mengikuti sumber. |
| FR-F00.30 | Membuat row pesanan | Kode, pemilik/stan, jumlah, nilai, dan status dapat dikonfigurasi. |
| FR-F00.31 | Membuat banner informasi | Ikon, judul, isi, dan slot aksi dapat digunakan ulang. |
| FR-F00.32 | Membuat banner kegagalan | Pesan dan aksi pemulihan mengikuti sumber tanpa menghapus konten lama. |
| FR-F00.33 | Membuat bottom sheet | Handle, header, tombol tutup, overlay, dan insets keyboard tersedia. |
| FR-F00.34 | Membuat dialog konfirmasi | Aksi batal dan konfirmasi dibedakan serta dapat diakses lewat Back. |
| FR-F00.35 | Membuat snackbar undo | Callback pemulihan diberikan pemanggil; durasi mengikuti BR-06. |
| FR-F00.36 | Membuat skeleton row | Placeholder mengikuti proporsi S01/S09. |
| FR-F00.37 | Membuat placeholder foto | Kegagalan foto tidak mengubah ukuran row. |
| FR-F00.38 | Membuat sticky cart | Jumlah porsi, total, nama stan, dan aksi keranjang menerima data state. |
| FR-F00.39 | Membuat FAB asisten | Ukuran visual 56 dp dan glyph mengikuti sumber. |
| FR-F00.40 | Membuat coachmark asisten | Callout dan tombol tutup mengikuti M02. |
| FR-F00.41 | Membuat footer CTA | Total dan tombol tidak tertutup safe area perangkat. |
| FR-F00.42 | Membuat timeline status | Tahap dan waktu berasal dari event pesanan. |
| FR-F00.43 | Membuat navigasi mahasiswa | Tiga destinasi persis Beranda, Pesanan, Profil. |
| FR-F00.44 | Membuat navigasi pengelola | Empat destinasi persis Dashboard, Pesanan, Menu, Profil. |

#### FR-M01 — Beranda, kunjungan kembali

**Acuan:** [M01](design/baseline/screens/M01_beranda_kunjungan_kembali.png) · **Target:** KantinCerdasv0.2.0 · **Fixture:** `screen_M01`

**Kondisi awal/pemicu:** Aplikasi dibuka sebagai mahasiswa; katalog dummy tersedia, cart kosong.

**Prasyarat teknis:** KC-ENG-10; KC-ENG-14; model/fixture DATA; komponen F00.

**Hasil/alur keluar:** Pengguna dapat menelusuri menu, stan, pencarian, dan destinasi utama.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M01.01 | Menampilkan sapaan beranda | Kantin Kampus, Halo Doni, dan judul mengikuti fixture M01. |
| FR-M01.02 | Menambahkan kolom pencarian beranda | Tap membuka M04 dengan fokus pencarian. |
| FR-M01.03 | Menambahkan chip Semua | Memilihnya menghapus pembatas kategori. |
| FR-M01.04 | Menambahkan chip Nasi | Memilihnya menyaring kategori Nasi. |
| FR-M01.05 | Menambahkan chip Mi | Memilihnya menyaring kategori Mi. |
| FR-M01.06 | Menambahkan chip Camilan | Kategori tanpa data menghasilkan daftar kosong tanpa menu rekaan. |
| FR-M01.07 | Menambahkan chip Minuman | Memilihnya hanya menampilkan minuman. |
| FR-M01.08 | Menampilkan bagian Cepat jadi | Fixture awal menampilkan Nasi Ayam Sambal Matah dan Mi Gomak. |
| FR-M01.09 | Menambahkan tombol Lihat semua | Membuka daftar pencarian dengan batas waktu 10 menit; keputusan A-04. |
| FR-M01.10 | Menghubungkan row menu ke detail | Tap isi row membuka M08 untuk menu terpilih. |
| FR-M01.11 | Menghubungkan tombol Tambah | Menambahkan satu porsi; memilih stan lain memakai aturan BR-01. |
| FR-M01.12 | Menampilkan daftar stan buka | Dapur Bu Rina, Kedai Pak Ucok, Warung Sinta beserta bloknya tampil. |
| FR-M01.13 | Menghubungkan row stan ke detail | Tap membuka M06 untuk stan terpilih. |
| FR-M01.14 | Menghubungkan tombol Beranda | Destinasi aktif tetap Beranda tanpa menumpuk route. |
| FR-M01.15 | Menghubungkan tombol Pesanan | Tap membuka M29 tanpa menghapus keranjang. |
| FR-M01.16 | Menghubungkan tombol Profil | Tap membuka M36 tanpa menghapus keranjang. |
| FR-M01.17 | Menghubungkan FAB asisten | Tap membuka M10 dan mempertahankan konteks beranda. |

#### FR-M02 — Pengenalan asisten

**Acuan:** [M02](design/baseline/screens/M02_pengenalan_asisten.png) · **Target:** KantinCerdasv0.3.0 · **Fixture:** `screen_M02`

**Kondisi awal/pemicu:** Mahasiswa pertama kali melihat asisten dalam sesi demo.

**Prasyarat teknis:** M01 dan F00 coachmark/FAB.

**Hasil/alur keluar:** Coachmark dapat ditutup tanpa menghalangi pemesanan.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M02.01 | Menampilkan teks pengenalan asisten | Bingung pilih? dan Aku bantu cari menu. mengikuti referensi. |
| FR-M02.02 | Menambahkan tombol tutup coachmark | Tap menyembunyikan callout tanpa membuka asisten. |
| FR-M02.03 | Menyimpan status coachmark sesi | Navigasi kembali tidak menampilkan callout yang telah ditutup; restart mereset sesuai A-02. |
| FR-M02.04 | Menempatkan coachmark di dekat FAB | Tidak menutupi tombol navigasi atau sticky cart. |

#### FR-M03 — Beranda dengan cart

**Acuan:** [M03](design/baseline/screens/M03_beranda_dengan_cart.png) · **Target:** KantinCerdasv0.4.0 · **Fixture:** `screen_M03`

**Kondisi awal/pemicu:** M01 dengan dua porsi dari Dapur Bu Rina di cart.

**Prasyarat teknis:** M01 dan LOGIC; cart fixture dua porsi.

**Hasil/alur keluar:** Beranda mencerminkan state keranjang yang sama.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M03.01 | Menampilkan jumlah item di row beranda | Nasi Ayam Sambal Matah menunjukkan jumlah satu dari cart. |
| FR-M03.02 | Menghubungkan tombol plus row beranda | Jumlah menu dan total cart meningkat satu kali per tap. |
| FR-M03.03 | Menghubungkan tombol minus row beranda | Jumlah berkurang sesuai BR-04; tidak menjadi negatif. |
| FR-M03.04 | Menampilkan sticky cart beranda | Fixture menampilkan 2 porsi, Rp30.000, Dapur Bu Rina. |
| FR-M03.05 | Menghubungkan tombol Lihat keranjang beranda | Tap membuka M17. |
| FR-M03.06 | Menggeser posisi FAB ketika cart tampil | FAB mengikuti referensi di atas sticky cart. |

#### FR-M04 — Hasil pencarian

**Acuan:** [M04](design/baseline/screens/M04_hasil_pencarian.png) · **Target:** KantinCerdasv0.2.0 · **Fixture:** `screen_M04`

**Kondisi awal/pemicu:** Pencarian dibuka dari beranda; fixture kata ayam.

**Prasyarat teknis:** M01; CatalogRepository dan CatalogFilter DATA.

**Hasil/alur keluar:** Hasil diperbarui dari katalog lokal sesuai query dan filter yang diterapkan.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M04.01 | Menambahkan tombol kembali pencarian | Kembali ke sumber tanpa kehilangan cart. |
| FR-M04.02 | Menambahkan field query pencarian | Pencarian nama menu/stan memakai trim dan pencocokan tanpa membedakan huruf besar. |
| FR-M04.03 | Menambahkan tombol hapus query | Field menjadi kosong dan hasil dihitung ulang. |
| FR-M04.04 | Menampilkan chip filter aktif | Fixture Maks. Rp20.000 mengikuti filter yang sudah diterapkan. |
| FR-M04.05 | Menambahkan tombol Filter | Tap membuka M05 dengan salinan filter aktif. |
| FR-M04.06 | Menampilkan jumlah hasil | Fixture awal menghasilkan tiga menu; nilai dihitung dari hasil. |
| FR-M04.07 | Menampilkan hasil menu tersedia | Ayam sambal matah dan ayam geprek dapat ditambahkan. |
| FR-M04.08 | Menampilkan hasil menu habis | Nasi Ayam Kecap tetap terlihat pada fixture M04 dengan tombol Tidak tersedia. |
| FR-M04.09 | Menghubungkan item pencarian ke detail | Menu yang dibuka sesuai ID item, bukan selalu ayam sambal matah. |

#### FR-M05 — Filter pencarian

**Acuan:** [M05](design/baseline/screens/M05_filter_pencarian.png) · **Target:** KantinCerdasv0.2.0 · **Fixture:** `screen_M05`

**Kondisi awal/pemicu:** Sheet filter dibuka di atas M04.

**Prasyarat teknis:** M04; komponen sheet/chip/radio F00.

**Hasil/alur keluar:** Filter berubah hanya setelah diterapkan.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M05.01 | Menambahkan kelompok batas harga filter | Pilihan Rp15.000, Rp20.000, Tanpa batas bersifat single-select. |
| FR-M05.02 | Menambahkan kelompok waktu tunggu filter | Pilihan 10 menit, 20 menit, Tanpa batas bersifat single-select. |
| FR-M05.03 | Menambahkan pilihan hanya menu tersedia | Nilai boolean tersimpan dalam draft filter; konflik snapshot D-05 dicatat. |
| FR-M05.04 | Menghubungkan tombol Terapkan filter | Draft menjadi filter aktif; sheet tutup; daftar dan jumlah hasil diperbarui. |
| FR-M05.05 | Menghubungkan tombol Reset filter | Draft kembali tanpa batas harga/waktu dan semua status; belum diterapkan sampai CTA ditekan. |
| FR-M05.06 | Menghubungkan tombol tutup filter | Draft dibuang dan hasil sebelumnya tidak berubah. |

#### FR-M06 — Detail stan buka

**Acuan:** [M06](design/baseline/screens/M06_detail_stan_buka.png) · **Target:** KantinCerdasv0.2.0 · **Fixture:** `screen_M06`

**Kondisi awal/pemicu:** Mahasiswa memilih stan yang buka.

**Prasyarat teknis:** M01/M04; fixture stan/menu DATA.

**Hasil/alur keluar:** Katalog dibatasi pada stan yang dipilih.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M06.01 | Menambahkan tombol kembali detail stan | Kembali ke daftar sebelumnya. |
| FR-M06.02 | Menampilkan foto stan | Aset stan-bu-rina.jpg digunakan pada fixture Bu Rina. |
| FR-M06.03 | Menampilkan identitas stan | Nama, lokasi Blok A, deskripsi, estimasi, dan badge Buka sesuai sumber. |
| FR-M06.04 | Menambahkan pencarian dalam stan | Query tidak menghasilkan menu milik stan lain. |
| FR-M06.05 | Menambahkan chip Semua dalam stan | Semua kategori stan ditampilkan. |
| FR-M06.06 | Menambahkan chip Makanan | Hanya item makanan stan ditampilkan. |
| FR-M06.07 | Menambahkan chip Minuman dalam stan | Hanya minuman stan ditampilkan. |
| FR-M06.08 | Menampilkan daftar menu stan | Lima menu Bu Rina tersedia dalam data dan dapat dijangkau dengan scroll. |
| FR-M06.09 | Menghubungkan tombol Tambah pada stan | Satu porsi masuk cart dan row berubah ke kontrol jumlah. |
| FR-M06.10 | Menghubungkan foto atau nama menu ke detail | M08 memakai ID menu terpilih. |
| FR-M06.11 | Menghubungkan FAB dari detail stan | Asisten tetap mengetahui cart dan konteks stan. |

#### FR-M07 — Detail stan dengan cart

**Acuan:** [M07](design/baseline/screens/M07_detail_stan_dengan_cart.png) · **Target:** KantinCerdasv0.4.0 · **Fixture:** `screen_M07`

**Kondisi awal/pemicu:** M06 dengan keranjang Bu Rina yang terisi.

**Prasyarat teknis:** M06 dan LOGIC.

**Hasil/alur keluar:** Jumlah di katalog stan dan cart selalu konsisten.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M07.01 | Menampilkan jumlah ayam pada detail stan | Fixture ayam menunjukkan satu porsi. |
| FR-M07.02 | Menampilkan jumlah telur pada detail stan | Fixture telur menunjukkan satu porsi. |
| FR-M07.03 | Menghubungkan perubahan jumlah dari detail stan | Perubahan diteruskan ke CartRepository yang sama. |
| FR-M07.04 | Menampilkan sticky cart detail stan | Jumlah dua porsi dan total Rp30.000 mengikuti state. |
| FR-M07.05 | Menghubungkan tombol keranjang detail stan | Tap membuka M17. |
| FR-M07.06 | Menempatkan FAB detail stan di atas cart | Tidak bertumpuk dengan CTA cart. |

#### FR-M08 — Detail menu

**Acuan:** [M08](design/baseline/screens/M08_detail_menu.png) · **Target:** KantinCerdasv0.2.0 · **Fixture:** `screen_M08`

**Kondisi awal/pemicu:** Mahasiswa membuka menu tersedia.

**Prasyarat teknis:** M06/M04; model MenuItem dan input F00.

**Hasil/alur keluar:** Detail menyediakan draft jumlah/catatan; commit cart diselesaikan pada v0.4.0.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M08.01 | Menambahkan tombol kembali detail menu | Draft yang belum ditambahkan tidak mengubah cart. |
| FR-M08.02 | Menampilkan foto besar menu | Fixture memakai nasi-ayam-sambal-matah.jpg. |
| FR-M08.03 | Menampilkan informasi menu | Nama, stan, estimasi, ketersediaan, harga, deskripsi mengikuti menu terpilih. |
| FR-M08.04 | Menambahkan input catatan item | Opsional, nilai dipertahankan selama detail aktif. |
| FR-M08.05 | Menambahkan tombol plus jumlah detail | Draft bertambah satu; harga total draft ikut berubah. |
| FR-M08.06 | Menambahkan tombol minus jumlah detail | Draft minimal satu dan tidak menghapus item cart yang sudah ada. |
| FR-M08.07 | Menampilkan total draft detail | Jumlah dikali harga integer rupiah. |
| FR-M08.08 | Menambahkan tombol Tambah ke keranjang | Komponen siap menerima handler CartRepository pada milestone v0.4.0. |

#### FR-M09 — Menu berhasil ditambahkan

**Acuan:** [M09](design/baseline/screens/M09_menu_berhasil_ditambahkan.png) · **Target:** KantinCerdasv0.4.0 · **Fixture:** `screen_M09`

**Kondisi awal/pemicu:** Draft M08 berhasil dimasukkan; fixture sebelumnya sudah memiliki satu telur.

**Prasyarat teknis:** M08 dan LOGIC.

**Hasil/alur keluar:** Feedback tambah ditampilkan dan cart menjadi dua porsi.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M09.01 | Menghubungkan submit draft detail ke cart | Jumlah dan catatan yang dikirim sama dengan draft M08. |
| FR-M09.02 | Menampilkan banner Menu ditambahkan | Pesan menunjukkan satu porsi menu ini di cart untuk fixture. |
| FR-M09.03 | Menambahkan tombol Tambah lagi | Menambahkan jumlah draft yang sama sekali lagi sesuai A-05. |
| FR-M09.04 | Menampilkan sticky cart setelah tambah | Fixture total menjadi Rp30.000 dari ayam dan telur. |
| FR-M09.05 | Menghubungkan tombol Lihat keranjang setelah tambah | Tap membuka isi cart terbaru. |

#### FR-M10 — Asisten pilih menu

**Acuan:** [M10](design/baseline/screens/M10_asisten_pilih_menu.png) · **Target:** KantinCerdasv0.3.0 · **Fixture:** `screen_M10`

**Kondisi awal/pemicu:** FAB asisten dipilih; mode online simulasi aktif.

**Prasyarat teknis:** M01; RecommendationRepository; komponen sheet F00.

**Hasil/alur keluar:** Asisten dummy menghasilkan rekomendasi deterministik.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M10.01 | Menambahkan tombol tutup asisten | Sheet tutup dan konteks halaman asal tetap tersedia. |
| FR-M10.02 | Menambahkan pilihan harga asisten | Rp15.000, Rp20.000, Tanpa batas dapat dipilih. |
| FR-M10.03 | Menambahkan pilihan waktu asisten | 10 menit, 20 menit, Tanpa batas dapat dipilih. |
| FR-M10.04 | Menambahkan pilihan selera asisten | Tidak pedas, Pakai nasi, Berkuah mengikuti sumber dan aturan A-06. |
| FR-M10.05 | Menambahkan input kebutuhan tambahan | Teks bebas disimpan sebagai input dummy; tidak dikirim ke AI eksternal. |
| FR-M10.06 | Menghubungkan tombol Cari rekomendasi | Query lengkap membuka M13; fixture ambigu membuka M12. |
| FR-M10.07 | Menghubungkan tombol Nanti saja | Menutup sheet tanpa membuat pesanan. |
| FR-M10.08 | Mengisi pilihan awal dari preferensi | Nilai terakhir yang tersimpan dalam sesi mengisi draft asisten. |

#### FR-M11 — Asisten dengan keyboard

**Acuan:** [M11](design/baseline/screens/M11_asisten_dengan_keyboard.png) · **Target:** KantinCerdasv0.3.0 · **Fixture:** `screen_M11`

**Kondisi awal/pemicu:** Field kebutuhan tambahan memperoleh fokus.

**Prasyarat teknis:** M10; dukungan input/fokus Flutter.

**Hasil/alur keluar:** Input dan aksi utama tetap dapat dijangkau ketika keyboard terbuka.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M11.01 | Memfokuskan input kebutuhan | Keyboard perangkat asli terbuka pada Flutter. |
| FR-M11.02 | Menyesuaikan inset sheet asisten | Sheet mengikuti tinggi keyboard tanpa menyalin gambar keyboard HTML. |
| FR-M11.03 | Mempertahankan teks saat keyboard ditutup | Input Ingin makan sebelum kelas tidak hilang. |
| FR-M11.04 | Membuat isi sheet asisten dapat digulir | Aksi Cari rekomendasi dan Nanti saja dapat dijangkau; lihat D-02. **BLOCKED: D-02.** |

#### FR-M12 — Asisten meminta klarifikasi

**Acuan:** [M12](design/baseline/screens/M12_asisten_meminta_klarifikasi.png) · **Target:** KantinCerdasv0.3.0 · **Fixture:** `screen_M12`

**Kondisi awal/pemicu:** Skenario ambigu: Yang murah dan cepat.

**Prasyarat teknis:** M10; hasil clarificationNeeded.

**Hasil/alur keluar:** Klarifikasi melengkapi query tanpa menghapus kebutuhan sebelumnya.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M12.01 | Menampilkan ringkasan kebutuhan ambigu | Teks Yang murah dan cepat mengikuti fixture. |
| FR-M12.02 | Menampilkan pertanyaan batas harga | Pertanyaan sesuai referensi. |
| FR-M12.03 | Menambahkan pilihan harga klarifikasi | Satu batas harga dapat dipilih. |
| FR-M12.04 | Menghubungkan tombol Tampilkan rekomendasi | Harga baru digabungkan dengan kebutuhan lama dan membuka M13. |
| FR-M12.05 | Menghubungkan tombol Ubah kebutuhan | Kembali ke M10 dengan draft terisi. |

#### FR-M13 — Hasil rekomendasi

**Acuan:** [M13](design/baseline/screens/M13_hasil_rekomendasi.png) · **Target:** KantinCerdasv0.3.0 · **Fixture:** `screen_M13`

**Kondisi awal/pemicu:** Asisten dummy berhasil menemukan kandidat.

**Prasyarat teknis:** M10; hasil matches.

**Hasil/alur keluar:** Hasil tetap dapat ditelusuri dan dipilih secara manual.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M13.01 | Menambahkan tombol kembali rekomendasi | Kembali ke halaman pemanggil. |
| FR-M13.02 | Menampilkan ringkasan pilihan rekomendasi | Batas harga dan waktu berasal dari query aktif. |
| FR-M13.03 | Menghubungkan ikon edit rekomendasi | Membuka M10 dengan pilihan aktif. |
| FR-M13.04 | Menghubungkan tombol Ubah pilihan | Membuka draft yang sama seperti ikon edit. |
| FR-M13.05 | Menampilkan tiga kandidat fixture | Ayam sambal matah, telur dadar, Mi Gomak tampil dalam urutan fixture. |
| FR-M13.06 | Menghubungkan kandidat ke detail menu | Tap isi row membuka detail kandidat. |
| FR-M13.07 | Menyediakan callback Tambah rekomendasi | Menggunakan handler cart bersama ketika milestone v0.4.0 siap. |

#### FR-M14 — Rekomendasi dengan cart

**Acuan:** [M14](design/baseline/screens/M14_rekomendasi_dengan_cart.png) · **Target:** KantinCerdasv0.4.0 · **Fixture:** `screen_M14`

**Kondisi awal/pemicu:** Rekomendasi dibuka saat cart Bu Rina terisi.

**Prasyarat teknis:** M13 dan LOGIC.

**Hasil/alur keluar:** Pilihan rekomendasi menghormati batas satu stan.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M14.01 | Menampilkan banner stan cart di rekomendasi | Dapur Bu Rina, 2 porsi, Rp30.000 sesuai fixture. |
| FR-M14.02 | Menghubungkan kontrol jumlah rekomendasi | Perubahan ayam/telur memperbarui seluruh cart. |
| FR-M14.03 | Menampilkan sticky cart rekomendasi | Footer standalone mengikuti M14 tanpa bottom navigation. |
| FR-M14.04 | Menghubungkan tombol keranjang rekomendasi | Tap membuka M17. |
| FR-M14.05 | Mencegat tambah kandidat stan berbeda | Mi Gomak memunculkan M21 sebelum cart berubah. |

#### FR-M15 — Asisten gagal

**Acuan:** [M15](design/baseline/screens/M15_asisten_gagal.png) · **Target:** KantinCerdasv0.3.0 · **Fixture:** `screen_M15`

**Kondisi awal/pemicu:** Repository asisten mengembalikan kegagalan yang diketahui.

**Prasyarat teknis:** M10; hasil failure.

**Hasil/alur keluar:** Pengguna bisa retry atau memakai pencarian manual.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M15.01 | Menampilkan banner asisten gagal | Pesan Asisten sedang bermasalah mengikuti sumber. |
| FR-M15.02 | Mempertahankan pilihan saat asisten gagal | Harga, waktu, selera, teks tidak kembali ke default. |
| FR-M15.03 | Menghubungkan tombol Coba lagi asisten | Memanggil ulang query yang sama satu kali per tap. |
| FR-M15.04 | Menghubungkan tombol Cari menu sendiri | Membuka M04 dengan filter harga/waktu yang sesuai. |

#### FR-M16 — Rekomendasi kosong

**Acuan:** [M16](design/baseline/screens/M16_rekomendasi_kosong.png) · **Target:** KantinCerdasv0.3.0 · **Fixture:** `screen_M16`

**Kondisi awal/pemicu:** Asisten berhasil tetapi kandidat berjumlah nol.

**Prasyarat teknis:** M13; hasil empty.

**Hasil/alur keluar:** Tidak ada rekomendasi rekaan; pilihan dapat diubah.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M16.01 | Menampilkan empty state rekomendasi | Pesan Belum ada menu yang cocok mengikuti sumber. |
| FR-M16.02 | Menampilkan saran melonggarkan kriteria | Harga atau waktu dapat disesuaikan. |
| FR-M16.03 | Menghubungkan Ubah pilihan pada hasil kosong | Kembali ke draft asisten tanpa kehilangan input. |
| FR-M16.04 | Menghubungkan Lihat semua menu | Membuka katalog tanpa pembatas rekomendasi. |

#### FR-M17 — Keranjang dua porsi

**Acuan:** [M17](design/baseline/screens/M17_keranjang_dua_porsi.png) · **Target:** KantinCerdasv0.4.0 · **Fixture:** `screen_M17`

**Kondisi awal/pemicu:** Cart berisi satu ayam Rp18.000 dan satu telur Rp12.000.

**Prasyarat teknis:** LOGIC; CartRepository; F00 row/quantity/footer.

**Hasil/alur keluar:** Cart menjadi sumber ringkasan yang konsisten sebelum checkout.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M17.01 | Menambahkan tombol kembali keranjang | Kembali ke asal; cart tetap tersimpan dalam sesi. |
| FR-M17.02 | Menampilkan nama stan keranjang | Hanya satu stan tampil. |
| FR-M17.03 | Menampilkan item ayam keranjang | Foto, harga, jumlah, catatan Sambal dipisah berasal dari cart. |
| FR-M17.04 | Menampilkan item telur keranjang | Foto, harga, jumlah berasal dari cart. |
| FR-M17.05 | Menghubungkan tombol plus item cart | Satu porsi ditambahkan pada item yang benar. |
| FR-M17.06 | Menghubungkan tombol minus item cart | Mengikuti minimum dan penghapusan BR-04. |
| FR-M17.07 | Menghubungkan tombol Ubah catatan item | Membuka M18 untuk line ID yang dipilih. |
| FR-M17.08 | Menghubungkan tombol Hapus item | Menghapus line terpilih dan memunculkan M19. |
| FR-M17.09 | Menghubungkan tombol Kosongkan | Membuka M20 tanpa mengosongkan langsung. |
| FR-M17.10 | Menambahkan input catatan pesanan | Bungkus terpisah tersimpan terpisah dari catatan item. |
| FR-M17.11 | Menghitung subtotal cart | Jumlah harga dikali quantity seluruh item valid; fixture Rp30.000. |
| FR-M17.12 | Menghitung jumlah porsi cart | Jumlah quantity adalah dua, bukan jumlah jenis sebagai aturan umum. |
| FR-M17.13 | Menampilkan keterangan tunai | Tunai saat mengambil di stan tetap tampil. |
| FR-M17.14 | Menghubungkan Lanjut konfirmasi | Cart valid membuka M24 pada v0.5.0; cart tidak valid masuk M23. |

#### FR-M18 — Edit catatan item

**Acuan:** [M18](design/baseline/screens/M18_edit_catatan_item.png) · **Target:** KantinCerdasv0.4.0 · **Fixture:** `screen_M18`

**Kondisi awal/pemicu:** Ubah catatan dipilih pada satu item keranjang.

**Prasyarat teknis:** M17; snapshot draft line.

**Hasil/alur keluar:** Hanya catatan item terpilih yang dapat berubah.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M18.01 | Menampilkan judul sheet catatan | Nama menu berasal dari line cart terpilih. |
| FR-M18.02 | Mengisi field dengan catatan lama | Catatan opsional dapat dikosongkan. |
| FR-M18.03 | Menghubungkan Simpan catatan | Draft menggantikan catatan line yang tepat lalu sheet ditutup. |
| FR-M18.04 | Menghubungkan Batal catatan | Draft dibuang; catatan lama tetap. |
| FR-M18.05 | Menghubungkan tombol tutup catatan | Efek sama seperti Batal. |
| FR-M18.06 | Menyesuaikan sheet catatan terhadap keyboard | Input dan Simpan dapat dijangkau tanpa overflow. |

#### FR-M19 — Hapus item dengan undo

**Acuan:** [M19](design/baseline/screens/M19_hapus_item_dengan_undo.png) · **Target:** KantinCerdasv0.4.0 · **Fixture:** `screen_M19`

**Kondisi awal/pemicu:** Satu telur dihapus dari cart dua porsi.

**Prasyarat teknis:** M17; snapshot undo LOGIC.

**Hasil/alur keluar:** Cart satu ayam bernilai Rp18.000; undo tersedia.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M19.01 | Menyimpan snapshot item terhapus | Snapshot mencakup line ID, quantity, catatan, dan posisi. |
| FR-M19.02 | Memperbarui total setelah penghapusan | Fixture total berubah dari Rp30.000 menjadi Rp18.000. |
| FR-M19.03 | Menampilkan snackbar item terhapus | Nama item yang benar ditampilkan. |
| FR-M19.04 | Menghubungkan tombol Urungkan | Item pulih utuh selama jendela undo masih valid. |
| FR-M19.05 | Mengakhiri undo yang kedaluwarsa | Undo lama tidak memulihkan item setelah cart diganti stan atau checkout. |

#### FR-M20 — Konfirmasi kosongkan cart

**Acuan:** [M20](design/baseline/screens/M20_konfirmasi_kosongkan_cart.png) · **Target:** KantinCerdasv0.4.0 · **Fixture:** `screen_M20`

**Kondisi awal/pemicu:** Kosongkan dipilih pada cart terisi.

**Prasyarat teknis:** M17; F00 dialog.

**Hasil/alur keluar:** Cart berubah hanya setelah konfirmasi.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M20.01 | Menampilkan ringkasan pengosongan | Jumlah porsi dan stan sesuai cart saat dialog dibuka. |
| FR-M20.02 | Menghubungkan Tetap simpan | Dialog tutup tanpa mutasi. |
| FR-M20.03 | Menghubungkan Kosongkan pada dialog | Semua line dan catatan pesanan dibersihkan; tampil M22. |
| FR-M20.04 | Menangani Back pada dialog pengosongan | Efek sama seperti Tetap simpan. |

#### FR-M21 — Ganti stan

**Acuan:** [M21](design/baseline/screens/M21_ganti_stan.png) · **Target:** KantinCerdasv0.4.0 · **Fixture:** `screen_M21`

**Kondisi awal/pemicu:** Pengguna menambah Mi Gomak sementara cart berasal dari Bu Rina.

**Prasyarat teknis:** LOGIC; callback tambah M14/M01/M06.

**Hasil/alur keluar:** Perpindahan stan merupakan transaksi cart yang terkonfirmasi.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M21.01 | Menampilkan ringkasan cart lama pada dialog | Dua porsi Bu Rina Rp30.000 terlihat. |
| FR-M21.02 | Menampilkan kandidat stan baru pada dialog | Mi Gomak Pak Ucok Rp15.000 terlihat. |
| FR-M21.03 | Menghubungkan Tetap di Bu Rina | Cart lama dan catatan tetap utuh. |
| FR-M21.04 | Menghubungkan Ganti ke Pak Ucok | Cart lama diganti satu kandidat baru secara atomik. |
| FR-M21.05 | Membatalkan undo cart lama setelah ganti stan | Urungkan sebelumnya tidak dapat menghasilkan cart multi-stan. |

#### FR-M22 — Keranjang kosong

**Acuan:** [M22](design/baseline/screens/M22_keranjang_kosong.png) · **Target:** KantinCerdasv0.4.0 · **Fixture:** `screen_M22`

**Kondisi awal/pemicu:** Cart tidak memiliki line.

**Prasyarat teknis:** M17 dan state cart kosong.

**Hasil/alur keluar:** Pengguna diarahkan kembali memilih menu.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M22.01 | Menampilkan ikon keranjang kosong | Ikon dan komposisi mengikuti M22. |
| FR-M22.02 | Menampilkan pesan keranjang kosong | Tidak ada footer total nol atau tombol checkout aktif. |
| FR-M22.03 | Menghubungkan tombol Cari menu dari cart | Membuka Beranda. |
| FR-M22.04 | Menyembunyikan sticky cart di halaman lain | Cart kosong tidak meninggalkan bar atau jumlah lama. |

#### FR-M23 — Ketersediaan berubah

**Acuan:** [M23](design/baseline/screens/M23_ketersediaan_berubah.png) · **Target:** KantinCerdasv0.4.0 · **Fixture:** `screen_M23`

**Kondisi awal/pemicu:** Validasi ulang menemukan telur berubah menjadi Habis.

**Prasyarat teknis:** M17; CartValidator LOGIC.

**Hasil/alur keluar:** Checkout diblokir sampai perubahan ditinjau.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M23.01 | Menampilkan banner ketersediaan berubah | Item invalid tetap terlihat agar perubahan dapat dipahami. |
| FR-M23.02 | Menandai line telur sebagai habis | Quantity lama tidak otomatis diubah. |
| FR-M23.03 | Menghitung total menu tersedia | Fixture valid subtotal Rp18.000; cart masih memuat dua porsi sampai penghapusan. |
| FR-M23.04 | Menonaktifkan CTA checkout saat invalid | Tap Tinjau perubahan tidak membuat pesanan. |
| FR-M23.05 | Menghubungkan Hapus menu habis | Semua line invalid dihapus dan total/jumlah dihitung ulang. |
| FR-M23.06 | Menangani semua item menjadi habis | Penghapusan semua invalid mengarah ke M22. |

#### FR-M24 — Konfirmasi pesanan

**Acuan:** [M24](design/baseline/screens/M24_konfirmasi_pesanan.png) · **Target:** KantinCerdasv0.5.0 · **Fixture:** `screen_M24`

**Kondisi awal/pemicu:** Cart valid diteruskan ke konfirmasi.

**Prasyarat teknis:** M17/M23; SUBMIT coordinator.

**Hasil/alur keluar:** Pesanan hanya dibuat melalui CTA eksplisit.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M24.01 | Menambahkan tombol kembali konfirmasi | Cart dan catatan tetap utuh. |
| FR-M24.02 | Menampilkan lokasi pengambilan | Nama stan dan blok berasal dari cart. |
| FR-M24.03 | Menampilkan ringkasan item checkout | Quantity, harga, catatan item, dan total sama dengan cart. |
| FR-M24.04 | Menampilkan metode pembayaran checkout | Tunai di konter; tidak ada QRIS atau pilihan pembayaran baru. |
| FR-M24.05 | Menampilkan estimasi penyajian checkout | Rentang berlaku setelah pesanan diterima pengelola. |
| FR-M24.06 | Memvalidasi ulang cart sebelum submit | Stan buka dan semua menu tersedia; perubahan diarahkan ke aturan BR-07. |
| FR-M24.07 | Menghubungkan tombol Buat pesanan | Satu submission ID dibuat dan state berpindah ke M25. |

#### FR-M25 — Membuat pesanan

**Acuan:** [M25](design/baseline/screens/M25_membuat_pesanan.png) · **Target:** KantinCerdasv0.5.0 · **Fixture:** `screen_M25`

**Kondisi awal/pemicu:** Operasi create order dummy sedang berjalan.

**Prasyarat teknis:** M24; SUBMIT idempotency.

**Hasil/alur keluar:** Permintaan ganda dicegah sampai hasil operasi diketahui.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M25.01 | Menampilkan label Membuat pesanan | Indikator proses berada di CTA sesuai sumber. |
| FR-M25.02 | Mengunci CTA selama submit | Tap berulang tidak menambah operasi baru. |
| FR-M25.03 | Mempertahankan snapshot submission | Isi permintaan tidak berubah walaupun state katalog berubah. |
| FR-M25.04 | Mengarahkan hasil submit | Sukses ke M28, pasti gagal ke M26, tidak diketahui ke M27. |
| FR-M25.05 | Menangani Back saat submit | Halaman boleh ditinggalkan tetapi operation tetap dilacak; tidak ada submit kedua otomatis. |

#### FR-M26 — Pesanan belum terkirim

**Acuan:** [M26](design/baseline/screens/M26_pesanan_belum_terkirim.png) · **Target:** KantinCerdasv0.5.0 · **Fixture:** `screen_M26`

**Kondisi awal/pemicu:** Fake repository memastikan pesanan belum dibuat.

**Prasyarat teknis:** M25; knownFailure.

**Hasil/alur keluar:** Retry aman dilakukan tanpa kehilangan cart.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M26.01 | Menampilkan banner Pesanan belum terkirim | Pesan tidak dipakai untuk hasil yang belum diketahui. |
| FR-M26.02 | Mempertahankan cart setelah gagal kirim | Quantity, catatan, dan total tetap. |
| FR-M26.03 | Menghubungkan Coba kirim lagi | Mengulang logical submission yang sama setelah validasi; tidak menciptakan duplikat. |
| FR-M26.04 | Mencegah retry saat offline simulasi | Operasi tidak dipanggil sampai koneksi simulasi pulih. |

#### FR-M27 — Hasil pengiriman belum diketahui

**Acuan:** [M27](design/baseline/screens/M27_hasil_pengiriman_belum_diketahui.png) · **Target:** KantinCerdasv0.5.0 · **Fixture:** `screen_M27`

**Kondisi awal/pemicu:** Respons hilang setelah create order mungkin telah diterima.

**Prasyarat teknis:** M25; SUBMIT lookup.

**Hasil/alur keluar:** Status submission diperiksa sebelum pengguna mengirim lagi.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M27.01 | Menampilkan banner hasil belum diketahui | Copy Memeriksa pesananmu mengikuti referensi. |
| FR-M27.02 | Mengganti CTA menjadi Periksa status pengiriman | Tidak tersedia CTA yang langsung membuat pesanan kedua. |
| FR-M27.03 | Menghubungkan pemeriksaan submission | Pencarian menggunakan submission ID sebelumnya. |
| FR-M27.04 | Menangani hasil pemeriksaan ditemukan | Buka M28 dengan order ID yang sama dan kosongkan cart sekali. |
| FR-M27.05 | Menangani hasil pemeriksaan dipastikan tidak dibuat | Buka M26; retry memakai logical submission yang sama. |
| FR-M27.06 | Menangani pemeriksaan masih tidak pasti | Tetap M27, cart dan submission ID tidak dihapus. |

#### FR-M28 — Pesanan berhasil

**Acuan:** [M28](design/baseline/screens/M28_pesanan_berhasil.png) · **Target:** KantinCerdasv0.5.0 · **Fixture:** `screen_M28`

**Kondisi awal/pemicu:** Pesanan berhasil tersimpan dalam repository dummy.

**Prasyarat teknis:** M25/M27; order sukses terkonfirmasi.

**Hasil/alur keluar:** Bukti pemesanan tersedia dan pengguna dapat memantau status.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M28.01 | Menampilkan pesan Pesanan dibuat | Badge awal Menunggu konfirmasi tampil. |
| FR-M28.02 | Menampilkan kode pesanan sukses | Fixture KC-027; pesanan berikutnya memakai kode unik. |
| FR-M28.03 | Menampilkan ringkasan sukses | Stan, blok, waktu, jumlah, total, tunai sesuai snapshot order. |
| FR-M28.04 | Mengosongkan cart setelah sukses terkonfirmasi | Hanya cart yang berasal dari submission tersebut dibersihkan sekali. |
| FR-M28.05 | Menghubungkan tombol Pantau pesanan | Membuka M31 untuk ID pesanan yang dibuat. |
| FR-M28.06 | Menghubungkan Kembali ke beranda | Membuka M01 tanpa menghapus pesanan. |
| FR-M28.07 | Memicu pengenalan notifikasi secara kontekstual | U01 dapat muncul sekali sesuai skenario, bukan menghalangi keberhasilan order. |

#### FR-M29 — Pesanan aktif

**Acuan:** [M29](design/baseline/screens/M29_pesanan_aktif.png) · **Target:** KantinCerdasv0.5.0 · **Fixture:** `screen_M29`

**Kondisi awal/pemicu:** Tab Pesanan mahasiswa dibuka.

**Prasyarat teknis:** OrderRepository; M28.

**Hasil/alur keluar:** Daftar aktif hanya memuat pesanan mahasiswa yang masih berjalan.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M29.01 | Menghubungkan tab Aktif | Menampilkan waiting, processing, ready milik mahasiswa aktif. |
| FR-M29.02 | Menghubungkan tab Riwayat | Membuka M30. |
| FR-M29.03 | Menampilkan row pesanan aktif | Kode, stan, jumlah, total, status berasal dari repository. |
| FR-M29.04 | Menghubungkan Lihat detail pesanan aktif | Membuka M31/M32/M33 menurut status aktual. |
| FR-M29.05 | Menampilkan banner menunggu konfirmasi | Waktu dibuat sesuai order aktif. |
| FR-M29.06 | Memperbarui daftar saat event order berubah | Order terminal keluar dari Aktif tanpa duplikasi. |

#### FR-M30 — Riwayat mahasiswa

**Acuan:** [M30](design/baseline/screens/M30_riwayat_mahasiswa.png) · **Target:** KantinCerdasv0.5.0 · **Fixture:** `screen_M30`

**Kondisi awal/pemicu:** Tab Riwayat mahasiswa dipilih.

**Prasyarat teknis:** M29 dan fixture riwayat.

**Hasil/alur keluar:** Pesanan selesai dan ditolak dapat dibaca kembali.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M30.01 | Menampilkan daftar riwayat mahasiswa | Hanya order terminal milik pengguna yang tampil. |
| FR-M30.02 | Menampilkan waktu pada row riwayat | Fixture KC-027 selesai 12.20 dan KC-019 tanggal 3 Sep. |
| FR-M30.03 | Menghubungkan row riwayat ke detail | Selesai membuka M34; ditolak membuka M35. |
| FR-M30.04 | Menghubungkan tab Aktif dari riwayat | Kembali ke M29. |
| FR-M30.05 | Menangani riwayat tanpa data | Gunakan varian kosong studentOrders(history:true, empty:true) dalam sumber; tanpa tombol pemesanan ulang baru. |

#### FR-M31 — Menunggu konfirmasi

**Acuan:** [M31](design/baseline/screens/M31_menunggu_konfirmasi.png) · **Target:** KantinCerdasv0.5.0 · **Fixture:** `screen_M31`

**Kondisi awal/pemicu:** Detail order berstatus Menunggu konfirmasi dipilih.

**Prasyarat teknis:** M29; model Order/Event dan timeline F00.

**Hasil/alur keluar:** Status Menunggu konfirmasi terlihat konsisten dengan order yang sama.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M31.01 | Menampilkan header status Menunggu konfirmasi | Label status, order ID, dan stan berasal dari order. |
| FR-M31.02 | Menampilkan pesan status Menunggu konfirmasi | Belum ada tahap diproses yang ditandai selesai. |
| FR-M31.03 | Menampilkan timeline Menunggu konfirmasi | Hanya event yang sudah terjadi memiliki waktu dan penanda selesai. |
| FR-M31.04 | Menampilkan ringkasan pada status Menunggu konfirmasi | Total dan item menggunakan snapshot, tidak mengikuti harga katalog baru. |
| FR-M31.05 | Menampilkan waktu pembaruan Menunggu konfirmasi | lastSyncedAt dibedakan dari waktu perpindahan status. |
| FR-M31.06 | Menghubungkan kembali dari status Menunggu konfirmasi | Kembali ke tab asal tanpa mengubah order. |

#### FR-M32 — Pesanan diproses

**Acuan:** [M32](design/baseline/screens/M32_pesanan_diproses.png) · **Target:** KantinCerdasv0.5.0 · **Fixture:** `screen_M32`

**Kondisi awal/pemicu:** Detail order berstatus Diproses dipilih.

**Prasyarat teknis:** M31; fixture processing.

**Hasil/alur keluar:** Status Diproses terlihat konsisten dengan order yang sama.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M32.01 | Menampilkan header status Diproses | Label status, order ID, dan stan berasal dari order. |
| FR-M32.02 | Menampilkan pesan status Diproses | Estimasi dihitung sejak acceptedAt; fixture diterima 12.07. |
| FR-M32.03 | Menampilkan timeline Diproses | Hanya event yang sudah terjadi memiliki waktu dan penanda selesai. |
| FR-M32.04 | Menampilkan ringkasan pada status Diproses | Total dan item menggunakan snapshot, tidak mengikuti harga katalog baru. |
| FR-M32.05 | Menampilkan waktu pembaruan Diproses | lastSyncedAt dibedakan dari waktu perpindahan status. |
| FR-M32.06 | Menghubungkan kembali dari status Diproses | Kembali ke tab asal tanpa mengubah order. |

#### FR-M33 — Siap diambil

**Acuan:** [M33](design/baseline/screens/M33_siap_diambil.png) · **Target:** KantinCerdasv0.5.0 · **Fixture:** `screen_M33`

**Kondisi awal/pemicu:** Detail order berstatus Siap diambil dipilih.

**Prasyarat teknis:** M31; fixture ready.

**Hasil/alur keluar:** Status Siap diambil terlihat konsisten dengan order yang sama.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M33.01 | Menampilkan header status Siap diambil | Label status, order ID, dan stan berasal dari order. |
| FR-M33.02 | Menampilkan pesan status Siap diambil | Kode KC-027 ditonjolkan dan instruksi bayar Rp30.000 tampil. |
| FR-M33.03 | Menampilkan timeline Siap diambil | Hanya event yang sudah terjadi memiliki waktu dan penanda selesai. |
| FR-M33.04 | Menampilkan ringkasan pada status Siap diambil | Total dan item menggunakan snapshot, tidak mengikuti harga katalog baru. |
| FR-M33.05 | Menampilkan waktu pembaruan Siap diambil | lastSyncedAt dibedakan dari waktu perpindahan status. |
| FR-M33.06 | Menghubungkan kembali dari status Siap diambil | Kembali ke tab asal tanpa mengubah order. |

#### FR-M34 — Pesanan selesai

**Acuan:** [M34](design/baseline/screens/M34_pesanan_selesai.png) · **Target:** KantinCerdasv0.5.0 · **Fixture:** `screen_M34`

**Kondisi awal/pemicu:** Detail order berstatus Selesai dipilih.

**Prasyarat teknis:** M31; fixture completed.

**Hasil/alur keluar:** Status Selesai terlihat konsisten dengan order yang sama.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M34.01 | Menampilkan header status Selesai | Label status, order ID, dan stan berasal dari order. |
| FR-M34.02 | Menampilkan pesan status Selesai | Timeline lengkap dan pesan sudah diambil serta dibayar tampil. |
| FR-M34.03 | Menampilkan timeline Selesai | Hanya event yang sudah terjadi memiliki waktu dan penanda selesai. |
| FR-M34.04 | Menampilkan ringkasan pada status Selesai | Total dan item menggunakan snapshot, tidak mengikuti harga katalog baru. |
| FR-M34.05 | Menampilkan waktu pembaruan Selesai | lastSyncedAt dibedakan dari waktu perpindahan status. |
| FR-M34.06 | Menghubungkan kembali dari status Selesai | Kembali ke tab asal tanpa mengubah order. |

#### FR-M35 — Pesanan ditolak

**Acuan:** [M35](design/baseline/screens/M35_pesanan_ditolak.png) · **Target:** KantinCerdasv0.5.0 · **Fixture:** `screen_M35`

**Kondisi awal/pemicu:** Detail order berstatus Ditolak dipilih.

**Prasyarat teknis:** M31; fixture rejected; D-06.

**Hasil/alur keluar:** Status Ditolak terlihat konsisten dengan order yang sama.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M35.01 | Menampilkan header status Ditolak | Label status, order ID, dan stan berasal dari order. |
| FR-M35.02 | Menampilkan pesan status Ditolak | Alasan penolakan tampil, tidak ada tagihan; catatan konflik D-06 berlaku. **BLOCKED: D-06.** |
| FR-M35.03 | Menampilkan timeline Ditolak | Hanya event yang sudah terjadi memiliki waktu dan penanda selesai. |
| FR-M35.04 | Menampilkan ringkasan pada status Ditolak | Total dan item menggunakan snapshot, tidak mengikuti harga katalog baru. |
| FR-M35.05 | Menampilkan waktu pembaruan Ditolak | lastSyncedAt dibedakan dari waktu perpindahan status. |
| FR-M35.06 | Menghubungkan kembali dari status Ditolak | Kembali ke tab asal tanpa mengubah order. |

#### FR-M36 — Profil mahasiswa

**Acuan:** [M36](design/baseline/screens/M36_profil_mahasiswa.png) · **Target:** KantinCerdasv0.7.0 · **Fixture:** `screen_M36`

**Kondisi awal/pemicu:** Mahasiswa membuka Profil.

**Prasyarat teknis:** Shell mahasiswa; UserProfile DATA.

**Hasil/alur keluar:** Profil demo menjadi pintu ke preferensi dan bantuan.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M36.01 | Menampilkan identitas mahasiswa | Avatar D, Doni, doni@example.com, dan Mode demo tampil. |
| FR-M36.02 | Menghubungkan row Riwayat pesanan profil | Membuka M30. |
| FR-M36.03 | Menghubungkan row Preferensi makanan | Membuka M37. |
| FR-M36.04 | Menghubungkan row Notifikasi mahasiswa | Membuka U02/U03 sesuai izin simulasi. |
| FR-M36.05 | Menghubungkan row Bantuan mahasiswa | Membuka U04. |
| FR-M36.06 | Menghubungkan row Tentang mahasiswa | Membuka U05. |
| FR-M36.07 | Menghubungkan row Keluar mahasiswa | Membuka U07. |

#### FR-M37 — Preferensi makanan

**Acuan:** [M37](design/baseline/screens/M37_preferensi_makanan.png) · **Target:** KantinCerdasv0.7.0 · **Fixture:** `screen_M37`

**Kondisi awal/pemicu:** Preferensi makanan dibuka dari Profil.

**Prasyarat teknis:** M36; PreferencesRepository.

**Hasil/alur keluar:** Preferensi sesi tersimpan hanya melalui CTA simpan.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-M37.01 | Menampilkan penjelasan preferensi | Copy mengikuti sumber. |
| FR-M37.02 | Menambahkan chip selera preferensi | Pedas, Tidak pedas, Berkuah, Pakai nasi mengikuti A-06. |
| FR-M37.03 | Menambahkan radio harga preferensi | Pilihan 15000, 20000, tanpa batas bersifat tunggal. |
| FR-M37.04 | Menambahkan radio waktu preferensi | Pilihan 10, 20, tanpa batas bersifat tunggal. |
| FR-M37.05 | Menghubungkan Simpan preferensi | Draft masuk PreferencesRepository; sukses memicu U09. |
| FR-M37.06 | Memulihkan preferensi ketika dibuka kembali | Dalam sesi sama nilai tersimpan tampil; Back sebelum simpan membuang draft. |

#### FR-P01 — Dashboard pengelola

**Acuan:** [P01](design/baseline/screens/P01_dashboard_pengelola.png) · **Target:** KantinCerdasv0.6.0 · **Fixture:** `screen_P01`

**Kondisi awal/pemicu:** Aplikasi dijalankan sebagai pengelola Bu Rina.

**Prasyarat teknis:** KC-ENG-11; STATE agregasi; fixture antrean DATA.

**Hasil/alur keluar:** Dashboard menampilkan ringkasan dan pintasan tindakan stan sendiri.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-P01.01 | Menampilkan sapaan pengelola | Nama Bu Rina dan Dapur Bu Rina sesuai profil. |
| FR-P01.02 | Menampilkan status buka dashboard | Nilai berasal dari StallRepository. |
| FR-P01.03 | Menghubungkan switch tutup dashboard | Memunculkan P02 sebelum mengubah status. |
| FR-P01.04 | Menampilkan angka total pesanan hari ini | Fixture 24 berasal dari agregasi dataset hari demo. |
| FR-P01.05 | Menampilkan angka pesanan menunggu | Fixture tiga berasal dari order waiting. |
| FR-P01.06 | Menampilkan angka pesanan diproses | Fixture dua berasal dari order processing. |
| FR-P01.07 | Menampilkan angka pesanan siap | Fixture satu berasal dari order ready. |
| FR-P01.08 | Menampilkan jumlah selesai hari ini | Fixture 18 menghasilkan konsistensi 24 = 3 + 2 + 1 + 18. |
| FR-P01.09 | Menghubungkan Lihat pesanan dashboard | Membuka P04. |
| FR-P01.10 | Menghubungkan Kelola menu dashboard | Membuka P15 dengan filter Habis; aktif pada v0.7.0. |
| FR-P01.11 | Menampilkan antrean terbaru | KC-027, KC-028, KC-029 tersusun sesuai waktu dan urutan tie-break. |
| FR-P01.12 | Menghubungkan detail antrean dashboard | Membuka detail ID order yang dipilih. |
| FR-P01.13 | Menghubungkan tombol Dashboard | Tidak menumpuk route dashboard. |
| FR-P01.14 | Menghubungkan tombol Pesanan pengelola | Membuka P04. |
| FR-P01.15 | Menghubungkan tombol Menu pengelola | Membuka P15 ketika milestone v0.7.0 tersedia. |
| FR-P01.16 | Menghubungkan tombol Profil pengelola | Membuka P18 ketika milestone v0.7.0 tersedia. |

#### FR-P02 — Dialog menutup stan

**Acuan:** [P02](design/baseline/screens/P02_dialog_menutup_stan.png) · **Target:** KantinCerdasv0.6.0 · **Fixture:** `screen_P02`

**Kondisi awal/pemicu:** Switch buka dimatikan dari dashboard.

**Prasyarat teknis:** P01; StallRepository.

**Hasil/alur keluar:** Menutup stan tidak membatalkan antrean aktif.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-P02.01 | Menampilkan dialog tutup stan | Copy menjelaskan pesanan baru diblokir dan pesanan lama tetap ditangani. |
| FR-P02.02 | Menghitung antrean aktif dialog | Waiting + processing + ready menghasilkan enam pada fixture. |
| FR-P02.03 | Menghubungkan Tetap buka | Tidak ada mutasi status stan. |
| FR-P02.04 | Menghubungkan Tutup stan | Set isOpen false setelah sukses repository; tampil P03. |
| FR-P02.05 | Mempertahankan order saat stan ditutup | Enam order aktif tetap berada dalam repository. |

#### FR-P03 — Dashboard stan tutup

**Acuan:** [P03](design/baseline/screens/P03_dashboard_stan_tutup.png) · **Target:** KantinCerdasv0.6.0 · **Fixture:** `screen_P03`

**Kondisi awal/pemicu:** Stan telah ditutup secara manual.

**Prasyarat teknis:** P02; shared state stan.

**Hasil/alur keluar:** Antrean lama tetap dikelola dan stan dapat dibuka kembali.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-P03.01 | Menampilkan label Stan tutup | Keterangan Tidak menerima pesanan baru mengikuti sumber. |
| FR-P03.02 | Menampilkan switch tutup | State switch sesuai isOpen false. |
| FR-P03.03 | Menghubungkan switch buka kembali | Sukses mengubah isOpen true dan kembali ke P01. |
| FR-P03.04 | Mempertahankan pintasan pesanan saat tutup | P04/P05/P06 tetap dapat dibuka. |
| FR-P03.05 | Menyebarkan status tutup ke katalog mahasiswa | S06 muncul pada repository demo bersama; create order baru ditolak. |

#### FR-P04 — Pesanan baru

**Acuan:** [P04](design/baseline/screens/P04_pesanan_baru.png) · **Target:** KantinCerdasv0.6.0 · **Fixture:** `screen_P04`

**Kondisi awal/pemicu:** Tab Baru pengelola dipilih.

**Prasyarat teknis:** P01; STATE scope/sorting.

**Hasil/alur keluar:** Antrean Baru milik stan sendiri tampil.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-P04.01 | Mengaktifkan tab Baru | Indikator tab sesuai destinasi dan badge jumlah dihitung dari repository. |
| FR-P04.02 | Menyaring order pada tab Baru | Hanya status waiting pada stan pengelola yang muncul. |
| FR-P04.03 | Menampilkan data fixture tab Baru | KC-027, KC-028, KC-029 tampil dengan jumlah, nilai, waktu, serta nama yang sesuai. |
| FR-P04.04 | Mengurutkan antrean Baru | Urutan menggunakan aturan BR-12 dan tie-break sequence yang stabil. |
| FR-P04.05 | Menghubungkan Lihat detail tab Baru | Buka detail order yang dipilih dengan status aktual. |
| FR-P04.06 | Memperbarui badge tab Baru | Mutasi order pada repository memperbarui hitungan tanpa reload aplikasi. |

#### FR-P05 — Pesanan diproses

**Acuan:** [P05](design/baseline/screens/P05_pesanan_diproses.png) · **Target:** KantinCerdasv0.6.0 · **Fixture:** `screen_P05`

**Kondisi awal/pemicu:** Tab Diproses pengelola dipilih.

**Prasyarat teknis:** P04; state processing.

**Hasil/alur keluar:** Antrean Diproses milik stan sendiri tampil.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-P05.01 | Mengaktifkan tab Diproses | Indikator tab sesuai destinasi dan badge jumlah dihitung dari repository. |
| FR-P05.02 | Menyaring order pada tab Diproses | Hanya status processing pada stan pengelola yang muncul. |
| FR-P05.03 | Menampilkan data fixture tab Diproses | KC-025, KC-026 tampil dengan jumlah, nilai, waktu, serta nama yang sesuai. |
| FR-P05.04 | Mengurutkan antrean Diproses | Urutan menggunakan aturan BR-12 dan tie-break sequence yang stabil. |
| FR-P05.05 | Menghubungkan Lihat detail tab Diproses | Buka detail order yang dipilih dengan status aktual. |
| FR-P05.06 | Memperbarui badge tab Diproses | Mutasi order pada repository memperbarui hitungan tanpa reload aplikasi. |

#### FR-P06 — Pesanan siap

**Acuan:** [P06](design/baseline/screens/P06_pesanan_siap.png) · **Target:** KantinCerdasv0.6.0 · **Fixture:** `screen_P06`

**Kondisi awal/pemicu:** Tab Siap pengelola dipilih.

**Prasyarat teknis:** P04; state ready.

**Hasil/alur keluar:** Antrean Siap milik stan sendiri tampil.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-P06.01 | Mengaktifkan tab Siap | Indikator tab sesuai destinasi dan badge jumlah dihitung dari repository. |
| FR-P06.02 | Menyaring order pada tab Siap | Hanya status ready pada stan pengelola yang muncul. |
| FR-P06.03 | Menampilkan data fixture tab Siap | KC-024 tampil dengan jumlah, nilai, waktu, serta nama yang sesuai. |
| FR-P06.04 | Mengurutkan antrean Siap | Urutan menggunakan aturan BR-12 dan tie-break sequence yang stabil. |
| FR-P06.05 | Menghubungkan Lihat detail tab Siap | Buka detail order yang dipilih dengan status aktual. |
| FR-P06.06 | Memperbarui badge tab Siap | Mutasi order pada repository memperbarui hitungan tanpa reload aplikasi. |

#### FR-P07 — Riwayat pengelola

**Acuan:** [P07](design/baseline/screens/P07_riwayat_pengelola.png) · **Target:** KantinCerdasv0.6.0 · **Fixture:** `screen_P07`

**Kondisi awal/pemicu:** Pengelola memilih Riwayat.

**Prasyarat teknis:** P04; fixture riwayat.

**Hasil/alur keluar:** Riwayat stan berisi order selesai atau ditolak.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-P07.01 | Menghubungkan tab Riwayat pengelola | Indikator aktif sesuai referensi. |
| FR-P07.02 | Menambahkan chip Semua riwayat | Menampilkan selesai dan ditolak dari stan sendiri. |
| FR-P07.03 | Menambahkan chip Selesai riwayat | Menyaring status completed. |
| FR-P07.04 | Menambahkan chip Ditolak riwayat | Menyaring status rejected. |
| FR-P07.05 | Menampilkan row riwayat pengelola | KC-027 selesai dan KC-018 ditolak mengikuti fixture riwayat terpisah. |
| FR-P07.06 | Menghubungkan detail riwayat pengelola | Selesai membuka P12; ditolak membuka P14. |

#### FR-P08 — Detail pesanan baru

**Acuan:** [P08](design/baseline/screens/P08_detail_pesanan_baru.png) · **Target:** KantinCerdasv0.6.0 · **Fixture:** `screen_P08`

**Kondisi awal/pemicu:** Order baru KC-027 dibuka pengelola stan terkait.

**Prasyarat teknis:** P04; STATE transition guard; D-04 untuk kontrol edit.

**Hasil/alur keluar:** Pengelola dapat menerima atau memulai penolakan.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-P08.01 | Menampilkan identitas order baru | Kode, nama Doni, dibuat 12.05, dan Menunggu konfirmasi sesuai data. |
| FR-P08.02 | Menampilkan snapshot item order baru | Ayam dan telur beserta catatan, harga, quantity sesuai pesanan. |
| FR-P08.03 | Menampilkan catatan pesanan pengelola | Bungkus terpisah berasal dari snapshot. |
| FR-P08.04 | Menampilkan pembayaran belum dibayar | Total Rp30.000 dengan tunai saat mengambil. |
| FR-P08.05 | Mencatat kontrol edit pada detail order | Kontrol Ubah catatan, Hapus, minus, plus masuk keputusan D-04; tidak diberi mutasi diam-diam. **BLOCKED: D-04.** |
| FR-P08.06 | Menghubungkan tombol Tolak order baru | Membuka P13 tanpa mengubah status lebih dahulu. |
| FR-P08.07 | Menghubungkan Terima & siapkan | Hanya waiting dapat berubah ke processing; sukses menampilkan P09. |
| FR-P08.08 | Mencegah penerimaan ganda | Satu operasi aktif per order; retry tidak menggandakan event accepted. |

#### FR-P09 — Detail pesanan diproses

**Acuan:** [P09](design/baseline/screens/P09_detail_pesanan_diproses.png) · **Target:** KantinCerdasv0.6.0 · **Fixture:** `screen_P09`

**Kondisi awal/pemicu:** Order telah diterima pengelola.

**Prasyarat teknis:** P08; STATE transisi processing.

**Hasil/alur keluar:** Order dapat ditandai siap setelah penyiapan.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-P09.01 | Menampilkan status Diproses pengelola | Badge dan acceptedAt sesuai event. |
| FR-P09.02 | Mempertahankan snapshot order diproses | Item, harga, quantity, catatan tidak dihitung ulang dari katalog. |
| FR-P09.03 | Menambahkan tombol Tandai siap diambil | CTA sesuai sumber. |
| FR-P09.04 | Menghubungkan transisi ke siap | Hanya processing dapat berubah ke ready; sukses membuka P10. |
| FR-P09.05 | Menangani gagal transisi siap | Order tetap processing dan menampilkan S16 pada milestone v0.8.0. |

#### FR-P10 — Detail siap diambil

**Acuan:** [P10](design/baseline/screens/P10_detail_siap_diambil.png) · **Target:** KantinCerdasv0.6.0 · **Fixture:** `screen_P10`

**Kondisi awal/pemicu:** Order siap diambil.

**Prasyarat teknis:** P09; STATE transisi ready.

**Hasil/alur keluar:** Pengelola mencocokkan kode sebelum konfirmasi penyerahan.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-P10.01 | Menampilkan banner siap pengelola | KC-027 dan instruksi mencocokkan nomor tampil. |
| FR-P10.02 | Menampilkan waktu siap pengelola | Fixture readyAt 12.15. |
| FR-P10.03 | Menampilkan pembayaran belum dibayar saat siap | Status tunai belum diterima tidak berubah otomatis. |
| FR-P10.04 | Menghubungkan Selesaikan pesanan | Membuka P11; belum membuat status completed. |

#### FR-P11 — Konfirmasi penyerahan

**Acuan:** [P11](design/baseline/screens/P11_konfirmasi_penyerahan.png) · **Target:** KantinCerdasv0.6.0 · **Fixture:** `screen_P11`

**Kondisi awal/pemicu:** CTA penyelesaian ditekan pada order ready.

**Prasyarat teknis:** P10; STATE complete atomik.

**Hasil/alur keluar:** Selesai berarti makanan diserahkan dan tunai diterima.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-P11.01 | Menampilkan nomor order dalam dialog penyerahan | Kode sesuai order yang sedang ditangani. |
| FR-P11.02 | Menampilkan nilai tunai dalam dialog | Rp30.000 dan nama Doni mengikuti snapshot. |
| FR-P11.03 | Menghubungkan Belum selesai | Dialog ditutup; status tetap ready. |
| FR-P11.04 | Menghubungkan Ya, selesaikan | Status completed dan payment cashReceived berubah dalam satu operasi. |
| FR-P11.05 | Mencegah konfirmasi penyerahan berulang | Klik ganda menghasilkan satu completed event. |

#### FR-P12 — Detail pesanan selesai

**Acuan:** [P12](design/baseline/screens/P12_detail_pesanan_selesai.png) · **Target:** KantinCerdasv0.6.0 · **Fixture:** `screen_P12`

**Kondisi awal/pemicu:** Penyelesaian pesanan berhasil.

**Prasyarat teknis:** P11; D-04 untuk treatment kontrol historis.

**Hasil/alur keluar:** Riwayat menunjukkan hasil final penyerahan dan pembayaran.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-P12.01 | Menampilkan status Selesai pengelola | Waktu completedAt fixture 12.20. |
| FR-P12.02 | Menampilkan Tunai diterima | Nilai pembayaran sesuai order selesai. |
| FR-P12.03 | Mempertahankan total historis | Harga katalog baru tidak mengubah total order. |
| FR-P12.04 | Menghubungkan Kembali ke pesanan selesai | Membuka P07 dengan order tersebut tersedia. |

#### FR-P13 — Konfirmasi penolakan

**Acuan:** [P13](design/baseline/screens/P13_konfirmasi_penolakan.png) · **Target:** KantinCerdasv0.6.0 · **Fixture:** `screen_P13`

**Kondisi awal/pemicu:** Tolak dipilih untuk order waiting.

**Prasyarat teknis:** P08; enum rejectionReason.

**Hasil/alur keluar:** Alasan penolakan dicatat dan terlihat oleh mahasiswa.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-P13.01 | Menampilkan ringkasan order pada sheet tolak | Kode, nama, porsi, total mengikuti snapshot. |
| FR-P13.02 | Menambahkan alasan Menu tidak tersedia | Radio memilih satu alasan. |
| FR-P13.03 | Menambahkan alasan Stan tidak dapat memproses | Radio memilih satu alasan. |
| FR-P13.04 | Menambahkan alasan Lainnya | Gunakan enum other tanpa field baru; perluasan teks bebas masuk keputusan A-09. |
| FR-P13.05 | Menghubungkan Tolak pesanan pada sheet | Status waiting menjadi rejected dengan alasan terpilih. |
| FR-P13.06 | Menghubungkan Batal penolakan | Sheet ditutup tanpa perubahan order. |
| FR-P13.07 | Menghubungkan tombol tutup penolakan | Efek sama seperti Batal. |

#### FR-P14 — Detail pesanan ditolak

**Acuan:** [P14](design/baseline/screens/P14_detail_pesanan_ditolak.png) · **Target:** KantinCerdasv0.6.0 · **Fixture:** `screen_P14`

**Kondisi awal/pemicu:** Penolakan order telah tersimpan.

**Prasyarat teknis:** P13; D-04.

**Hasil/alur keluar:** Order ditolak tidak ditagihkan dan tidak diproses.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-P14.01 | Menampilkan status Ditolak pengelola | Waktu penolakan sesuai event. |
| FR-P14.02 | Menampilkan alasan penolakan pengelola | Alasan sama dengan yang dibaca mahasiswa. |
| FR-P14.03 | Menampilkan Tidak ditagihkan | paymentStatus notCharged untuk order rejected. |
| FR-P14.04 | Menghubungkan Kembali ke pesanan ditolak | Membuka P07 dengan order rejected. |

#### FR-P15 — Kelola menu

**Acuan:** [P15](design/baseline/screens/P15_kelola_menu.png) · **Target:** KantinCerdasv0.7.0 · **Fixture:** `screen_P15`

**Kondisi awal/pemicu:** Pengelola membuka Menu.

**Prasyarat teknis:** P01; StallRepository availability; komponen menu F00.

**Hasil/alur keluar:** Ketersediaan lima menu Bu Rina dapat dikelola.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-P15.01 | Menambahkan pencarian menu pengelola | Query hanya mencari menu stan miliknya. |
| FR-P15.02 | Menambahkan filter Semua menu pengelola | Menampilkan lima menu fixture. |
| FR-P15.03 | Menambahkan filter Tersedia pengelola | Hanya status available muncul. |
| FR-P15.04 | Menambahkan filter Habis pengelola | Sayur Asem dan Nasi Ayam Kecap tampil pada fixture. |
| FR-P15.05 | Menampilkan daftar menu pengelola | Nama, foto, harga, status, estimasi mengikuti data. |
| FR-P15.06 | Menghubungkan switch ketersediaan menu | Satu menu berubah tersedia/habis lewat repository. |
| FR-P15.07 | Mencegah update ketersediaan bersamaan pada item sama | Tap cepat tidak menghasilkan respons lama yang menimpa nilai baru. |
| FR-P15.08 | Memperbarui katalog setelah perubahan menu | Mahasiswa membaca status baru dari store demo bersama. |

#### FR-P16 — Gagal ubah ketersediaan

**Acuan:** [P16](design/baseline/screens/P16_gagal_ubah_ketersediaan.png) · **Target:** KantinCerdasv0.7.0 · **Fixture:** `screen_P16`

**Kondisi awal/pemicu:** Perubahan Sayur Asem dari Habis ke Tersedia gagal.

**Prasyarat teknis:** P15; knownFailure availability.

**Hasil/alur keluar:** Nilai lama tetap berlaku dan retry tersedia pada row yang gagal.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-P16.01 | Memulihkan switch setelah update gagal | Sayur Asem tetap Habis. |
| FR-P16.02 | Menampilkan pesan inline perubahan gagal | Status belum berubah tampil pada item yang gagal. |
| FR-P16.03 | Menghubungkan Coba lagi ketersediaan | Mengirim target nilai yang gagal, bukan membalik status tanpa konteks. |
| FR-P16.04 | Menghapus pesan setelah update berhasil | Badge dan switch mengikuti nilai baru. |

#### FR-P17 — Pengaturan stan

**Acuan:** [P17](design/baseline/screens/P17_pengaturan_stan.png) · **Target:** KantinCerdasv0.7.0 · **Fixture:** `screen_P17`

**Kondisi awal/pemicu:** Pengelola membuka Pengaturan stan.

**Prasyarat teknis:** P18; StallRepository; P02 untuk konfirmasi tutup.

**Hasil/alur keluar:** Hanya status manual dan estimasi yang dapat disimpan.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-P17.01 | Menampilkan foto pengaturan stan | Aset Bu Rina mengikuti sumber. |
| FR-P17.02 | Menampilkan identitas stan hanya baca | Nama, deskripsi, dan lokasi tidak memiliki editor baru. |
| FR-P17.03 | Menambahkan switch status manual dalam draft | Belum mengubah repository sampai Simpan perubahan. |
| FR-P17.04 | Menambahkan pilihan estimasi 5–10 menit | Nilai dapat dipilih sebagai draft. |
| FR-P17.05 | Menambahkan pilihan estimasi 10–15 menit | Nilai dapat dipilih sebagai draft. |
| FR-P17.06 | Menambahkan pilihan estimasi 15–20 menit | Nilai dapat dipilih sebagai draft. |
| FR-P17.07 | Menampilkan jadwal informasi | Senin–Jumat 08.00–16.00 hanya informasi, bukan scheduler. |
| FR-P17.08 | Menghubungkan Simpan perubahan | Draft disimpan atomik; menutup stan memakai konfirmasi P02 sesuai A-10. |
| FR-P17.09 | Membuang draft pengaturan saat kembali | Data tersimpan tidak berubah tanpa Simpan. |

#### FR-P18 — Profil pengelola

**Acuan:** [P18](design/baseline/screens/P18_profil_pengelola.png) · **Target:** KantinCerdasv0.7.0 · **Fixture:** `screen_P18`

**Kondisi awal/pemicu:** Pengelola membuka Profil.

**Prasyarat teknis:** Shell pengelola; UserProfile DATA.

**Hasil/alur keluar:** Profil demo memberi akses ke pengaturan dan informasi.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-P18.01 | Menampilkan identitas pengelola | Avatar BR, Bu Rina, Dapur Bu Rina, rina@example.com, Mode demo. |
| FR-P18.02 | Menghubungkan row Data akun | Membuka U06. |
| FR-P18.03 | Menghubungkan row Pengaturan stan | Membuka P17. |
| FR-P18.04 | Menghubungkan row Notifikasi pengelola | Membuka U02/U03 sesuai izin dummy. |
| FR-P18.05 | Menghubungkan row Bantuan pengelola | Membuka U04. |
| FR-P18.06 | Menghubungkan row Tentang pengelola | Membuka U05. |
| FR-P18.07 | Menghubungkan row Keluar pengelola | Memakai dialog U07 yang sama. |

#### FR-Q01 — Beranda cart — 360 dp

**Acuan:** [Q01](design/baseline/screens/Q01_beranda_cart_360_dp.png) · **Target:** KantinCerdasv0.9.0 · **Fixture:** `screen_Q01`

**Kondisi awal/pemicu:** M03 pada viewport 360 × 800 dp.

**Prasyarat teknis:** M03; golden environment QA.

**Hasil/alur keluar:** Konten beranda dan cart tetap dapat dioperasikan di layar sempit.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-Q01.01 | Mengatur viewport uji Q01 | Golden memakai 360 × 800 logical pixels dengan text scale 1.0. |
| FR-Q01.02 | Menyesuaikan row menu pada 360 dp | Kontrol jumlah berpindah mengikuti sumber tanpa overflow horizontal. |
| FR-Q01.03 | Memeriksa sticky cart pada 360 dp | Nilai total dan tombol keranjang tetap terbaca. |
| FR-Q01.04 | Memeriksa FAB pada 360 dp | Tidak menutupi CTA cart atau navigasi. |

#### FR-Q02 — Detail stan — 412 dp

**Acuan:** [Q02](design/baseline/screens/Q02_detail_stan_412_dp.png) · **Target:** KantinCerdasv0.9.0 · **Fixture:** `screen_Q02`

**Kondisi awal/pemicu:** M07 pada viewport 412 × 915 dp.

**Prasyarat teknis:** M07; golden environment QA.

**Hasil/alur keluar:** Detail stan tetap sesuai komposisi referensi lebar.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-Q02.01 | Mengatur viewport uji Q02 | Golden memakai 412 × 915 logical pixels. |
| FR-Q02.02 | Menyesuaikan hero stan pada 412 dp | Crop mengikuti sumber tanpa distorsi. |
| FR-Q02.03 | Memeriksa row stan pada 412 dp | Informasi dan jumlah tetap sejajar. |
| FR-Q02.04 | Memeriksa footer stan pada 412 dp | Cart, FAB, navigasi, safe area tidak bertumpuk. |

#### FR-Q03 — Beranda teks 150%

**Acuan:** [Q03](design/baseline/screens/Q03_beranda_teks_150.png) · **Target:** KantinCerdasv0.9.0 · **Fixture:** `screen_Q03`

**Kondisi awal/pemicu:** Target beranda pada text scale 150%; PNG sumber justru identik S01.

**Prasyarat teknis:** M03/S01; D-01/D-03.

**Hasil/alur keluar:** Pengujian text scale berjalan; kelulusan visual menunggu D-01.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-Q03.01 | Mencatat konflik gambar Q03 | Hash duplikat S01 dicatat tanpa menimpa gambar sumber. |
| FR-Q03.02 | Mengatur uji teks 150 persen beranda | TextScaler sistem disetel 1.5 pada fixture M03. |
| FR-Q03.03 | Memeriksa akses konten beranda pada teks besar | Tidak mengecilkan font untuk memaksa cocok; semua konten dapat digulir. |
| FR-Q03.04 | Menentukan referensi golden Q03 | BLOCKED oleh D-01 sampai pemilik desain menetapkan acuan. **BLOCKED: D-01.** |

#### FR-Q04 — Rekomendasi teks panjang

**Acuan:** [Q04](design/baseline/screens/Q04_rekomendasi_teks_panjang.png) · **Target:** KantinCerdasv0.9.0 · **Fixture:** `screen_Q04`

**Kondisi awal/pemicu:** M14 dengan nama menu panjang di 360 × 800 dp dan teks besar.

**Prasyarat teknis:** M14; D-03 dan golden environment.

**Hasil/alur keluar:** Nama panjang tetap terbaca dan aksi dapat dijangkau.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-Q04.01 | Menambahkan fixture nama menu panjang | Nasi Ayam Sambal Matah dengan Lalapan Segar sesuai sumber. |
| FR-Q04.02 | Mengatur uji viewport Q04 | 360 × 800 dp, text scale 1.5; catat perbedaan CSS manual dalam D-03. **BLOCKED: D-03.** |
| FR-Q04.03 | Membuat nama kandidat membungkus | Tidak terpotong dengan ellipsis yang menyembunyikan informasi utama. |
| FR-Q04.04 | Memeriksa kontrol jumlah kandidat panjang | Tombol tetap dapat dijangkau dengan scroll. |
| FR-Q04.05 | Memeriksa footer rekomendasi teks panjang | Total dan aksi tetap terlihat tanpa overlay konten penting. |

#### FR-Q05 — Keranjang delapan porsi

**Acuan:** [Q05](design/baseline/screens/Q05_keranjang_delapan_porsi.png) · **Target:** KantinCerdasv0.9.0 · **Fixture:** `screen_Q05`

**Kondisi awal/pemicu:** Cart berisi delapan porsi, empat jenis menu.

**Prasyarat teknis:** M17; fixture delapan porsi.

**Hasil/alur keluar:** Total Rp94.000 dan seluruh catatan dapat diperiksa.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-Q05.01 | Menambahkan fixture delapan porsi | Ayam 3, telur 2, teh 2, sayur 1; sayur available khusus skenario. |
| FR-Q05.02 | Menghitung total fixture besar | 54000 + 24000 + 10000 + 6000 = 94000. |
| FR-Q05.03 | Menghitung label porsi dan jenis | 8 porsi dan 4 jenis menu tampil. |
| FR-Q05.04 | Membungkus catatan item panjang | Catatan ayam dan teh tidak menutup kontrol lain. |
| FR-Q05.05 | Membuat cart panjang dapat digulir | Item terakhir dan catatan pesanan dapat dijangkau di atas footer. |

#### FR-Q06 — Cart dengan keyboard

**Acuan:** [Q06](design/baseline/screens/Q06_cart_dengan_keyboard.png) · **Target:** KantinCerdasv0.9.0 · **Fixture:** `screen_Q06`

**Kondisi awal/pemicu:** Input catatan cart aktif pada viewport 360 × 800 dp.

**Prasyarat teknis:** M17; D-02 dan keyboard test.

**Hasil/alur keluar:** Keyboard tidak menghilangkan draft; koreksi crop menunggu D-02.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-Q06.01 | Mengatur uji keyboard Q06 | Viewport logical 360 × 800 dengan insets keyboard nyata/simulasi uji. |
| FR-Q06.02 | Mempertahankan catatan cart selama fokus | Teks panjang sesuai fixture tidak hilang. |
| FR-Q06.03 | Menyembunyikan footer cart saat keyboard aktif | Mengikuti sumber yang tidak merender footer pada Q06. |
| FR-Q06.04 | Memulihkan footer setelah keyboard ditutup | Total dan Lanjut konfirmasi kembali dengan nilai terbaru. |
| FR-Q06.05 | Memeriksa lebar konten Q06 | Tidak menjadikan crop 390 ke 360 sebagai perilaku aplikasi; kelulusan visual bergantung D-02. **BLOCKED: D-02.** |

#### FR-S01 — Loading Beranda

**Acuan:** [S01](design/baseline/screens/S01_loading_beranda.png) · **Target:** KantinCerdasv0.8.0 · **Fixture:** `screen_S01`

**Kondisi awal/pemicu:** Beranda mulai memuat tanpa data.

**Prasyarat teknis:** M01; controller skenario DATA; RECOVERY.

**Hasil/alur keluar:** Katalog sukses membuka M01; gagal membuka S10.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-S01.01 | Menampilkan skeleton header beranda | Proporsi mengikuti S01. |
| FR-S01.02 | Menampilkan skeleton pencarian beranda | Tidak menerima input sebelum katalog siap. |
| FR-S01.03 | Menampilkan skeleton row katalog | Tidak bercampur spinner layar penuh. |
| FR-S01.04 | Mempertahankan navigasi selama loading beranda | Pengguna dapat berpindah tab tanpa crash. |
| FR-S01.05 | Membuang respons loading usang | Respons permintaan lama tidak menimpa state terbaru. |

#### FR-S02 — Hasil pencarian kosong

**Acuan:** [S02](design/baseline/screens/S02_hasil_pencarian_kosong.png) · **Target:** KantinCerdasv0.8.0 · **Fixture:** `screen_S02`

**Kondisi awal/pemicu:** Query sushi tidak menemukan menu.

**Prasyarat teknis:** M04; controller skenario DATA; RECOVERY.

**Hasil/alur keluar:** Pengguna bisa mengubah query atau menghapus filter.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-S02.01 | Menampilkan empty state pencarian | Menu tidak ditemukan dan panduan pemulihan mengikuti sumber. |
| FR-S02.02 | Menghubungkan Ubah kata pencarian | Fokus kembali ke field query yang masih berisi sushi. |
| FR-S02.03 | Menghubungkan Hapus filter hasil kosong | Filter aktif dihapus dan hasil dihitung ulang; query tetap. |

#### FR-S03 — Offline dengan data

**Acuan:** [S03](design/baseline/screens/S03_offline_dengan_data.png) · **Target:** KantinCerdasv0.8.0 · **Fixture:** `screen_S03`

**Kondisi awal/pemicu:** Offline simulasi dengan cache katalog.

**Prasyarat teknis:** M03; controller skenario DATA; RECOVERY.

**Hasil/alur keluar:** Cache dapat dibaca; operasi yang memerlukan hasil baru diblokir.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-S03.01 | Menampilkan banner offline dengan cache | Waktu data terakhir 12.02 tampil pada fixture. |
| FR-S03.02 | Mengganti placeholder pencarian offline | Cari di data tersimpan sesuai sumber. |
| FR-S03.03 | Menampilkan status stan sebagai data terakhir | Tidak menyatakan status cache sebagai keadaan live. |
| FR-S03.04 | Menyembunyikan FAB saat offline | Asisten tidak dipanggil. |
| FR-S03.05 | Memblokir submit pesanan saat offline | Cart lokal tetap dapat dibaca/diedit sesuai BR-15. |
| FR-S03.06 | Menghubungkan Coba lagi katalog offline | Keberhasilan refresh memperbarui cache dan lastSyncedAt. |

#### FR-S04 — Offline tanpa data

**Acuan:** [S04](design/baseline/screens/S04_offline_tanpa_data.png) · **Target:** KantinCerdasv0.8.0 · **Fixture:** `screen_S04`

**Kondisi awal/pemicu:** Offline simulasi tanpa cache.

**Prasyarat teknis:** M01; controller skenario DATA; RECOVERY.

**Hasil/alur keluar:** Tidak ada data buatan tambahan untuk menggantikan kegagalan.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-S04.01 | Menampilkan empty state offline tanpa data | Pesan Belum ada data yang bisa ditampilkan sesuai sumber. |
| FR-S04.02 | Menghubungkan Coba lagi offline tanpa cache | Memuat katalog setelah skenario koneksi pulih. |
| FR-S04.03 | Mempertahankan navigasi tanpa cache | Profil dan Pesanan tetap dapat dibuka sesuai state masing-masing. |

#### FR-S05 — Gagal memuat Pesanan

**Acuan:** [S05](design/baseline/screens/S05_gagal_memuat_pesanan.png) · **Target:** KantinCerdasv0.8.0 · **Fixture:** `screen_S05`

**Kondisi awal/pemicu:** Daftar pesanan pengelola gagal dimuat.

**Prasyarat teknis:** P04; controller skenario DATA; RECOVERY.

**Hasil/alur keluar:** Retry dan kembali ke dashboard tersedia.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-S05.01 | Menampilkan gagal memuat pesanan pengelola | S05 dipetakan ke pengelola sesuai app.js, bukan diasumsikan mahasiswa. |
| FR-S05.02 | Menghubungkan Coba lagi pesanan pengelola | Query mempertahankan tab aktif. |
| FR-S05.03 | Menghubungkan Kembali ke dashboard saat gagal | Membuka P01/P03 sesuai status stan. |

#### FR-S06 — Detail stan tutup

**Acuan:** [S06](design/baseline/screens/S06_detail_stan_tutup.png) · **Target:** KantinCerdasv0.8.0 · **Fixture:** `screen_S06`

**Kondisi awal/pemicu:** Mahasiswa membuka stan tutup.

**Prasyarat teknis:** M06; controller skenario DATA; RECOVERY.

**Hasil/alur keluar:** Menu dapat dilihat tetapi tidak dapat dipesan dari stan ini.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-S06.01 | Menampilkan badge Tutup detail stan | Nilai berasal dari isOpen false. |
| FR-S06.02 | Menampilkan banner stan tidak menerima pesanan | Copy mengikuti sumber. |
| FR-S06.03 | Menghilangkan aksi tambah di katalog stan tutup | Tidak ada mutasi tambah melalui row. |
| FR-S06.04 | Menonaktifkan pemesanan dari detail menu stan tutup | Guard berlaku walaupun route M08 dibuka langsung. |
| FR-S06.05 | Mempertahankan pencarian stan tutup | Katalog masih dapat ditelusuri. |

#### FR-S07 — Detail menu habis

**Acuan:** [S07](design/baseline/screens/S07_detail_menu_habis.png) · **Target:** KantinCerdasv0.8.0 · **Fixture:** `screen_S07`

**Kondisi awal/pemicu:** Detail menu dengan availability habis.

**Prasyarat teknis:** M08; controller skenario DATA; RECOVERY.

**Hasil/alur keluar:** Mahasiswa diarahkan ke menu lain pada stan sama.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-S07.01 | Menampilkan badge Habis detail menu | Fixture ayam dibuat habis khusus skenario ini. |
| FR-S07.02 | Menampilkan banner menu sedang habis | Tidak ada tombol Tambah ke keranjang aktif. |
| FR-S07.03 | Menghubungkan Lihat menu lain dari stan ini | Kembali ke katalog stan menu tersebut. |

#### FR-S08 — Pembaruan status gagal

**Acuan:** [S08](design/baseline/screens/S08_pembaruan_status_gagal.png) · **Target:** KantinCerdasv0.8.0 · **Fixture:** `screen_S08`

**Kondisi awal/pemicu:** Refresh status mahasiswa gagal setelah data pernah dimuat.

**Prasyarat teknis:** M32; controller skenario DATA; RECOVERY.

**Hasil/alur keluar:** Status terakhir tetap terlihat.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-S08.01 | Menampilkan banner pembaruan status gagal | Copy Status belum dapat diperbarui sesuai sumber. |
| FR-S08.02 | Mempertahankan timeline cache mahasiswa | Status tetap Diproses dan data tidak dihapus. |
| FR-S08.03 | Menampilkan waktu sinkronisasi terakhir | Fixture 12.08 tidak diperbarui ketika refresh gagal. |
| FR-S08.04 | Menghubungkan Muat ulang status | Keberhasilan mengganti status dari repository. |

#### FR-S09 — Loading daftar pesanan

**Acuan:** [S09](design/baseline/screens/S09_loading_daftar_pesanan.png) · **Target:** KantinCerdasv0.8.0 · **Fixture:** `screen_S09`

**Kondisi awal/pemicu:** Daftar order mahasiswa mulai dimuat.

**Prasyarat teknis:** M29; controller skenario DATA; RECOVERY.

**Hasil/alur keluar:** Skeleton diganti data atau empty state setelah operasi berakhir.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-S09.01 | Menampilkan skeleton daftar pesanan | Tiga placeholder mengikuti referensi. |
| FR-S09.02 | Mempertahankan tab Aktif dan Riwayat saat loading | Tab tetap terlihat. |
| FR-S09.03 | Menyelesaikan loading order | Sukses berisi data ke M29; kosong ke S12; error sesuai keputusan D-09. |

#### FR-S10 — Gagal memuat katalog

**Acuan:** [S10](design/baseline/screens/S10_gagal_memuat_katalog.png) · **Target:** KantinCerdasv0.8.0 · **Fixture:** `screen_S10`

**Kondisi awal/pemicu:** Katalog gagal dimuat tanpa data sebelumnya.

**Prasyarat teknis:** M01; controller skenario DATA; RECOVERY.

**Hasil/alur keluar:** Pengguna dapat mencoba kembali.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-S10.01 | Menampilkan pesan katalog gagal | Menu belum dapat dimuat sesuai sumber. |
| FR-S10.02 | Menghubungkan Coba lagi katalog gagal | Satu request aktif dan skeleton S01 selama percobaan. |
| FR-S10.03 | Mempertahankan bottom navigation saat katalog gagal | Destinasi mahasiswa tetap dapat digunakan. |

#### FR-S11 — Stan belum memiliki menu

**Acuan:** [S11](design/baseline/screens/S11_stan_belum_memiliki_menu.png) · **Target:** KantinCerdasv0.8.0 · **Fixture:** `screen_S11`

**Kondisi awal/pemicu:** Stan buka tetapi tidak memiliki menu.

**Prasyarat teknis:** M06; controller skenario DATA; RECOVERY.

**Hasil/alur keluar:** Pengguna dapat mencari stan lain.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-S11.01 | Menampilkan pesan stan tanpa menu | Tidak disamakan dengan menu sedang habis. |
| FR-S11.02 | Menghubungkan Lihat stan lain | Membuka daftar stan di Beranda. |
| FR-S11.03 | Menjaga identitas stan pada empty state | Foto, nama, lokasi, dan status tetap terlihat. |

#### FR-S12 — Pesanan mahasiswa kosong

**Acuan:** [S12](design/baseline/screens/S12_pesanan_mahasiswa_kosong.png) · **Target:** KantinCerdasv0.8.0 · **Fixture:** `screen_S12`

**Kondisi awal/pemicu:** Daftar pesanan mahasiswa sukses dengan nol order aktif.

**Prasyarat teknis:** M29; controller skenario DATA; RECOVERY.

**Hasil/alur keluar:** Pengguna diarahkan memilih menu.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-S12.01 | Menampilkan pesan Belum ada pesanan aktif | Tab Aktif tetap terpilih. |
| FR-S12.02 | Menghubungkan Cari menu dari pesanan kosong | Membuka Beranda. |
| FR-S12.03 | Mempertahankan tab Riwayat saat aktif kosong | Riwayat dapat dibaca walaupun Aktif nol. |

#### FR-S13 — Antrean pengelola kosong

**Acuan:** [S13](design/baseline/screens/S13_antrean_pengelola_kosong.png) · **Target:** KantinCerdasv0.8.0 · **Fixture:** `screen_S13`

**Kondisi awal/pemicu:** Antrean baru pengelola sukses dengan nol order.

**Prasyarat teknis:** P04; controller skenario DATA; RECOVERY.

**Hasil/alur keluar:** Tidak ada error atau pesanan rekaan.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-S13.01 | Menampilkan pesan Belum ada pesanan baru | Copy mengikuti S13. |
| FR-S13.02 | Menghitung badge Baru dari data kosong | Menjadi nol pada mode interaktif; konflik snapshot D-10 dicatat. |
| FR-S13.03 | Mempertahankan akses tab lain saat antrean kosong | Diproses, Siap, Riwayat tetap dapat dibuka. |

#### FR-S14 — Filter menu kosong

**Acuan:** [S14](design/baseline/screens/S14_filter_menu_kosong.png) · **Target:** KantinCerdasv0.8.0 · **Fixture:** `screen_S14`

**Kondisi awal/pemicu:** Filter menu pengelola menghasilkan nol item.

**Prasyarat teknis:** P15; controller skenario DATA; RECOVERY.

**Hasil/alur keluar:** Reset filter memulihkan daftar.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-S14.01 | Menampilkan empty state filter pengelola | Pesan sesuai sumber. |
| FR-S14.02 | Menghubungkan Reset filter pengelola | Query dikosongkan dan filter status menjadi Semua sesuai A-11. |
| FR-S14.03 | Mempertahankan state query ketika belum direset | Input tidak hilang hanya karena hasil nol. |

#### FR-S15 — Foto makanan gagal

**Acuan:** [S15](design/baseline/screens/S15_foto_makanan_gagal.png) · **Target:** KantinCerdasv0.8.0 · **Fixture:** `screen_S15`

**Kondisi awal/pemicu:** Satu aset foto menu gagal dibaca.

**Prasyarat teknis:** M04; controller skenario DATA; RECOVERY.

**Hasil/alur keluar:** Kegagalan gambar tidak memblokir item.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-S15.01 | Menampilkan placeholder foto gagal | Slot gambar tetap 88 dp pada baseline normal. |
| FR-S15.02 | Mempertahankan informasi menu saat foto gagal | Nama, harga, badge tetap tampil. |
| FR-S15.03 | Mempertahankan aksi tambah saat foto gagal | Menu available tetap dapat ditambahkan. |

#### FR-S16 — Gagal ubah status

**Acuan:** [S16](design/baseline/screens/S16_gagal_ubah_status.png) · **Target:** KantinCerdasv0.8.0 · **Fixture:** `screen_S16`

**Kondisi awal/pemicu:** Transisi processing ke ready gagal.

**Prasyarat teknis:** P09; controller skenario DATA; RECOVERY.

**Hasil/alur keluar:** Status lama tetap berlaku dan retry eksplisit tersedia.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-S16.01 | Menampilkan banner Status belum berubah | Pesanan tetap Diproses sesuai referensi. |
| FR-S16.02 | Mengganti label CTA retry siap | Coba tandai siap diambil mengikuti sumber. |
| FR-S16.03 | Menghubungkan retry perubahan status | Expected status/version mencegah transisi dari data usang. |
| FR-S16.04 | Mencegah sukses palsu saat status gagal | Mahasiswa dan dashboard tetap melihat status lama. |

#### FR-S17 — Pengelola offline

**Acuan:** [S17](design/baseline/screens/S17_pengelola_offline.png) · **Target:** KantinCerdasv0.8.0 · **Fixture:** `screen_S17`

**Kondisi awal/pemicu:** Pengelola offline dengan cache order.

**Prasyarat teknis:** P04; controller skenario DATA; RECOVERY.

**Hasil/alur keluar:** Antrean hanya baca sampai simulasi online pulih.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-S17.01 | Menampilkan banner offline pengelola | Data terakhir 12.06 sesuai fixture. |
| FR-S17.02 | Mempertahankan daftar antrean cache | Nama, waktu, jumlah masih dapat dibaca. |
| FR-S17.03 | Memblokir mutasi order saat offline | Terima, Tolak, Tandai siap, Selesaikan tidak memanggil repository mutasi. |
| FR-S17.04 | Memblokir mutasi stan saat offline | Update isOpen, availability, dan settings tidak dijalankan. |
| FR-S17.05 | Menghubungkan Coba lagi pengelola offline | Refresh memuat snapshot terbaru sebelum mengaktifkan kembali mutasi. |

#### FR-U01 — Penjelasan notifikasi

**Acuan:** [U01](design/baseline/screens/U01_penjelasan_notifikasi.png) · **Target:** KantinCerdasv0.7.0 · **Fixture:** `screen_U01`

**Kondisi awal/pemicu:** Sesudah order berhasil atau konteks notifikasi dibuka.

**Prasyarat teknis:** M28; gateway izin dummy DATA.

**Hasil/alur keluar:** Permintaan izin dummy tidak menghalangi alur Pesanan.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-U01.01 | Menampilkan sheet penjelasan notifikasi | Alasan menerima kabar status sesuai sumber. |
| FR-U01.02 | Menghubungkan Aktifkan notifikasi | Memanggil NotificationPermissionGateway fake dengan hasil skenario granted/denied. |
| FR-U01.03 | Menghubungkan Nanti saja notifikasi | Sheet ditutup dan order sukses tetap tersedia. |
| FR-U01.04 | Menghubungkan tombol tutup izin | Tidak dianggap sebagai persetujuan izin. |
| FR-U01.05 | Menampilkan alternatif memantau manual | Status tetap dapat dilihat pada Pesanan. |

#### FR-U02 — Izin notifikasi ditolak

**Acuan:** [U02](design/baseline/screens/U02_izin_notifikasi_ditolak.png) · **Target:** KantinCerdasv0.7.0 · **Fixture:** `screen_U02`

**Kondisi awal/pemicu:** Izin notifikasi simulasi denied.

**Prasyarat teknis:** U01; state denied.

**Hasil/alur keluar:** Pengguna mengetahui izin nonaktif dan dapat memantau secara manual.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-U02.01 | Menampilkan status notifikasi ditolak | Tidak mengklaim izin perangkat sungguhan dalam dokumentasi demo. |
| FR-U02.02 | Menghubungkan Buka pengaturan perangkat | Gateway fake menyimulasikan kunjungan pengaturan; tidak meminta izin OS pada scope sekarang. |
| FR-U02.03 | Memuat ulang hasil izin setelah kembali | Skenario granted membuka U03; denied tetap U02. |
| FR-U02.04 | Menampilkan petunjuk Pesanan | Penolakan izin tidak memblokir pemesanan. |

#### FR-U03 — Notifikasi aktif

**Acuan:** [U03](design/baseline/screens/U03_notifikasi_aktif.png) · **Target:** KantinCerdasv0.7.0 · **Fixture:** `screen_U03`

**Kondisi awal/pemicu:** Izin dummy granted.

**Prasyarat teknis:** U01; state granted; PreferencesRepository.

**Hasil/alur keluar:** Pengaturan aplikasi terpisah dari status izin dummy.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-U03.01 | Menampilkan label notifikasi aktif | Status berasal dari gateway, bukan teks hardcode terpisah. |
| FR-U03.02 | Menambahkan switch notifikasi aplikasi | Mengubah enabled di PreferencesRepository dalam sesi. |
| FR-U03.03 | Mencegah pengiriman event notifikasi ketika nonaktif | Event order tetap memperbarui halaman Pesanan. |
| FR-U03.04 | Menghubungkan kembali notifikasi aktif | Kembali ke profil sesuai peran. |

#### FR-U04 — Bantuan

**Acuan:** [U04](design/baseline/screens/U04_bantuan.png) · **Target:** KantinCerdasv0.7.0 · **Fixture:** `screen_U04`

**Kondisi awal/pemicu:** Bantuan dibuka melalui profil.

**Prasyarat teknis:** M36/P18; D-07 untuk interaksi isi bantuan.

**Hasil/alur keluar:** Lima topik bantuan tercantum; detail yang belum didesain dilacak.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-U04.01 | Menampilkan pengantar Bantuan | Copy mengikuti sumber. |
| FR-U04.02 | Menambahkan row Cara memesan | Interaksi detail mengikuti keputusan D-07 sebelum dinyatakan selesai. **BLOCKED: D-07.** |
| FR-U04.03 | Menambahkan row Mengambil dan membayar | Interaksi detail mengikuti keputusan D-07. **BLOCKED: D-07.** |
| FR-U04.04 | Menambahkan row Pesanan ditolak | Interaksi detail mengikuti keputusan D-07. **BLOCKED: D-07.** |
| FR-U04.05 | Menambahkan row Koneksi terputus | Interaksi detail mengikuti keputusan D-07. **BLOCKED: D-07.** |
| FR-U04.06 | Menambahkan row Menggunakan asisten | Interaksi detail mengikuti keputusan D-07. **BLOCKED: D-07.** |
| FR-U04.07 | Menampilkan banner satu stan pada bantuan | Instruksi ambil dan bayar tunai mengikuti sumber. |

#### FR-U05 — Tentang KantinCerdas

**Acuan:** [U05](design/baseline/screens/U05_tentang_kantincerdas.png) · **Target:** KantinCerdasv0.7.0 · **Fixture:** `screen_U05`

**Kondisi awal/pemicu:** Tentang dibuka melalui profil.

**Prasyarat teknis:** M36/P18.

**Hasil/alur keluar:** Aplikasi dinyatakan sebagai versi demo.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-U05.01 | Menampilkan nama produk Tentang | KantinCerdas sesuai sumber. |
| FR-U05.02 | Menampilkan tagline Tentang | Pilih lebih cepat, makan lebih tenang. |
| FR-U05.03 | Menampilkan deskripsi singkat produk | Pilih menu, pesan lebih awal, ambil dan bayar di kantin. |
| FR-U05.04 | Menampilkan label Versi demo | Tidak menggantinya dengan klaim layanan produksi. |
| FR-U05.05 | Menampilkan pernyataan data contoh | Nama, menu, dan pesanan dijelaskan sebagai contoh. |

#### FR-U06 — Data akun pengelola

**Acuan:** [U06](design/baseline/screens/U06_data_akun_pengelola.png) · **Target:** KantinCerdasv0.7.0 · **Fixture:** `screen_U06`

**Kondisi awal/pemicu:** Data akun dibuka pengelola.

**Prasyarat teknis:** P18; UserProfile.

**Hasil/alur keluar:** Identitas demo bersifat hanya baca.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-U06.01 | Menampilkan label Akun demo | Sesuai referensi. |
| FR-U06.02 | Menampilkan nama akun pengelola | Bu Rina dari profil aktif. |
| FR-U06.03 | Menampilkan email akun pengelola | rina@example.com dari profil aktif. |
| FR-U06.04 | Menampilkan peran akun | Pengelola ditampilkan. |
| FR-U06.05 | Menampilkan stan akun | Dapur Bu Rina ditampilkan tanpa editor. |

#### FR-U07 — Konfirmasi keluar

**Acuan:** [U07](design/baseline/screens/U07_konfirmasi_keluar.png) · **Target:** KantinCerdasv0.7.0 · **Fixture:** `screen_U07`

**Kondisi awal/pemicu:** Keluar dipilih pada profil.

**Prasyarat teknis:** M36/P18; SessionRepository; D-08 untuk tujuan akhir.

**Hasil/alur keluar:** Sesi dummy dapat diakhiri tanpa menyiratkan autentikasi backend.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-U07.01 | Menampilkan dialog keluar | Copy dan dua aksi sesuai sumber. |
| FR-U07.02 | Menghubungkan Batal keluar | Profil dan seluruh state sesi tetap. |
| FR-U07.03 | Menghubungkan konfirmasi Keluar | SessionRepository dihapus; data privat sesi dan draft dibersihkan. |
| FR-U07.04 | Menentukan tujuan setelah logout | D-08 harus diputuskan; jangan menambah layar login tanpa baseline. **BLOCKED: D-08.** |

#### FR-U08 — Simpan pengaturan gagal

**Acuan:** [U08](design/baseline/screens/U08_simpan_pengaturan_gagal.png) · **Target:** KantinCerdasv0.7.0 · **Fixture:** `screen_U08`

**Kondisi awal/pemicu:** Simpan pengaturan stan gagal pada fake repository.

**Prasyarat teknis:** P17; knownFailure settings.

**Hasil/alur keluar:** Draft tetap tersedia untuk retry.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-U08.01 | Menampilkan banner perubahan belum tersimpan | Copy sesuai sumber. |
| FR-U08.02 | Mempertahankan draft setelah gagal simpan | Status dan estimasi pilihan pengguna tidak kembali ke nilai lama di form. |
| FR-U08.03 | Mempertahankan nilai repository lama | Katalog mahasiswa tidak melihat draft yang gagal. |
| FR-U08.04 | Menghubungkan Coba simpan lagi | Menyimpan draft yang sama secara atomik. |

#### FR-U09 — Preferensi tersimpan

**Acuan:** [U09](design/baseline/screens/U09_preferensi_tersimpan.png) · **Target:** KantinCerdasv0.7.0 · **Fixture:** `screen_U09`

**Kondisi awal/pemicu:** Simpan preferensi berhasil.

**Prasyarat teknis:** M37; sukses save.

**Hasil/alur keluar:** Feedback hanya muncul sesudah nilai benar-benar masuk repository.

| ID kebutuhan | Komponen/perilaku | Kriteria penerimaan |
| --- | --- | --- |
| FR-U09.01 | Menampilkan snackbar Preferensi disimpan | Teks dan ikon sesuai sumber. |
| FR-U09.02 | Mempertahankan nilai preferensi tersimpan | Buka ulang M37 menampilkan nilai baru. |
| FR-U09.03 | Menerapkan preferensi pada pembukaan asisten berikutnya | M10 menerima default dari nilai terbaru. |


## 13. Keputusan dan konflik sumber

Bagian ini mencegah tim menganggap inkonsistensi gambar sebagai aturan bisnis yang sengaja dibuat. **Tidak ada gambar sumber yang diubah.** Keputusan yang masih pending menghalangi klaim “seluruh desain selesai”, tetapi tidak menghalangi pengerjaan komponen dan logika yang sudah jelas.

### 13.1 Konflik dan celah desain

| ID | Bukti yang ditemukan | Dampak | Penanganan dan status |
| --- | --- | --- | --- |
| D-01 | `Q03_beranda_teks_150.png` mempunyai SHA-256 identik dengan S01. `renderScreen('Q03')` justru memanggil home dengan textScale yang tidak menerapkan seluruh class yang dimaksud. | Tidak ada gambar beranda teks 150% yang dapat dipercaya sebagai golden Q03. | **PENDING.** Pemilik desain menetapkan acuan Q03 yang dimaksud; simpan keputusan/versi tambahan, jangan overwrite PNG. Uji layout 1.5 tetap dapat dikerjakan. |
| D-02 | Q06 dicapture pada 360 dp tetapi `cart({keyboard:true})` tetap menghasilkan screen default 390 dp; PNG kanan terpotong. M11 juga memperlihatkan area aksi berdekatan/tertutup keyboard. | Menyalin crop menghasilkan kontrol yang tidak dapat dijangkau. | **PENDING.** Usulan perilaku: lebar ikut viewport dan isi dapat scroll di atas keyboard. Perubahan posisi yang terlihat perlu persetujuan desain. |
| D-03 | F00 meminta target sentuh 48 dp dan skala tipografi tertentu; CSS memakai chip 38 dp, quantity slot 36 dp, font metadata lebih kecil, serta Q04 memakai pembesaran manual yang bukan TextScaler 1.5 penuh. | Kesetiaan raster, target sentuh, dan text scaling tidak selalu dapat dipenuhi serentak tanpa penyesuaian. | **PENDING.** Pertahankan ukuran visual yang dapat diikuti; perluas hit area hanya jika tidak tumpang tindih. Tetapkan pengecualian per komponen sebelum golden final. |
| D-04 | P08/P09/P10/P12/P14 menggunakan `cartItem()` sehingga memuat Ubah catatan, Hapus, minus, plus bahkan setelah selesai/ditolak. Tidak ada alur persetujuan edit order. | Mengaktifkan kontrol dapat mengubah transaksi setelah dipesan; menghapusnya mengubah desain locked. | **PENDING.** Usulan: detail order hanya baca, tetapi treatment visual kontrol harus ditetapkan pemilik desain. Tidak boleh diam-diam mengaktifkan mutasi, menghapus kontrol, atau menghitung tugas ini selesai. |
| D-05 | M04 menampilkan Nasi Ayam Kecap Habis; M05 menunjukkan Hanya menu tersedia dipilih. | Bisa tampak seperti filter tidak bekerja. | **ADOPSI A-07:** M05 adalah draft belum diterapkan; M04 memakai applied availableOnly false. Setelah Terapkan, item habis harus hilang. Ini penjelasan state, bukan perubahan PNG. |
| D-06 | M35 menjelaskan Ditolak dan tidak ada pembayaran, tetapi footer lokasi masih berbunyi Bayar tunai saat mengambil karena komponen generik. | Instruksi pembayaran bertentangan dengan status final. | **PENDING.** Aturan bisnis tetap notCharged. Pemilik desain menentukan copy footer ditolak; baseline asli tetap diarsipkan. |
| D-07 | U04 memuat lima row bantuan dengan chevron; tidak ada layar isi atau handler detail pada app.js. | Tidak ada acuan lengkap bagi hasil tap row bantuan. | **PENDING.** Siapkan konten jawaban berdasarkan BR, lalu pemilik desain menentukan cara penyajian memakai pola yang ada; jangan membuat lima halaman baru tanpa acuan. |
| D-08 | U07 memiliki konfirmasi keluar, tetapi ZIP tidak menyediakan halaman login/pemilih peran/landing pasca-logout. | Tujuan navigasi logout belum ditentukan. | **PENDING.** clear session dapat dibangun; usulan demo mengembalikan kontrol ke launcher/harness di luar UI produk. Keputusan eksplisit dibutuhkan agar tidak ada tombol keluar tanpa hasil. |
| D-09 | Beberapa error belum memiliki referensi khusus: gagal pertama kali memuat order mahasiswa (S05 adalah pengelola), konflik versi, gagal toggle dashboard, dan stan tutup tepat di checkout. | Semua hasil repository perlu ditangani tetapi tidak boleh menambah UI baru sembarangan. | **PENDING.** Usulan gunakan banner/error component yang sudah ada pada halaman terkait; tetapkan copy dan posisi. Task penanganan hasil tidak boleh mengklaim visual final sebelum keputusan. |
| D-10 | S13 empty antrean masih menampilkan badge Baru 3 akibat template; screenshot history juga memakai state KC-027 yang berbeda dari dashboard. | Hardcode angka membuat aplikasi interaktif tidak konsisten. | **ADOPSI BR-20:** snapshot visual dan journey interaktif berbeda fixture; count runtime dihitung. Fixture kosong mempunyai Baru 0. Struktur/warna/posisi tetap, perubahan angka adalah data dinamis yang diizinkan. |

### 13.2 Asumsi implementasi yang dapat ditinjau

| ID | Keputusan awal yang digunakan |
| --- | --- |
| A-01 | Android portrait adalah target wajib awal; entry point terpisah per peran tanpa login baru. |
| A-02 | Data in-memory, cold restart reset fixture, tidak tersinkron lintas proses; coachmark/preferensi hanya selama sesi. |
| A-03 | Back/close pada form yang belum disimpan membuang draft; tidak menambah dialog unsaved changes tanpa desain. |
| A-04 | Lihat semua pada Cepat jadi membuka pencarian dengan batas waktu 10 menit, query kosong, dan availableOnly true. Pencarian umum tetap dapat mencari nama stan melalui menu yang dimilikinya; daftar khusus hasil stan belum ada desain. |
| A-05 | Tambah pada row menambah satu; Tambah lagi pada detail mengulang quantity draft. Cart satu line per menu ID; aturan catatan mengikuti BR-05. |
| A-06 | Selera bersifat single-select pada tahap awal. Kategori/tag tambahan ditandai metadata fixture; selera hanya soft preference, harga/waktu hard limit. Urutan tiga rekomendasi default mengikuti sumber. |
| A-07 | Draft filter berbeda dari applied filter. Reset filter mahasiswa: tanpa batas harga/waktu, availableOnly false, lalu Terapkan. |
| A-08 | Undo terakhir 5 detik, fake latency 600 ms, injected clock/seed tetap untuk test. Parameter ini bukan angka dari PNG. |
| A-09 | Alasan Lainnya memakai enum other dan label literal; tidak menambah input alasan bebas pada baseline sekarang. |
| A-10 | Switch P17 hanya mengubah draft; simpan yang mengubah buka menjadi tutup memakai konfirmasi P02 dengan angka terbaru. Batal mempertahankan draft tetapi tidak mengubah repository. |
| A-11 | Reset filter pengelola menghapus query dan mengembalikan filter ke Semua. |
| A-12 | Komposisi order tambahan dan 18 order completed untuk dashboard adalah seed tambahan yang didokumentasikan, bukan rincian yang seluruhnya tergambar. |
| A-13 | Estimasi menu tetap metadata per item untuk search; perubahan estimasi stan memengaruhi informasi stan dan estimasi order baru, tidak mengganti histori atau seluruh estimasi menu otomatis. |
| A-14 | Izin perangkat dan pembukaan Settings memakai fake gateway dalam scope dummy. Integrasi permission OS/push menjadi pekerjaan tahap berikutnya bila diminta. |

### 13.3 Cara menutup keputusan

Setiap keputusan pending dibuat Issue `decision` yang merujuk D-ID dan layar terkait. Isi keputusan: pilihan final, alasan, dampak visual/perilaku, nama penentu, tanggal, PR terkait, dan apakah baseline tambahan diperlukan. Keputusan tidak otomatis berarti seluruh screen harus ditunda: pecah task yang jelas dan task yang blocked. Jangan menandai checklist blocked sebagai selesai hanya karena catatan konfliknya sudah ditulis.

Penerimaan KantinCerdasv1.0.0 mensyaratkan seluruh keputusan yang menghalangi fungsi/visual ditutup. Jika belum ditutup, hasil yang boleh diumumkan adalah **demo parsial / release candidate dengan daftar celah**, bukan implementasi penuh 88 referensi.

## 14. Manifest baseline

Manifest berikut mengunci byte sumber saat dokumen disusun. Path relatif terhadap `design/baseline/`. File README pada direktori baseline adalah README sumber asli, berbeda dari README proyek di root. Hash dapat dipakai untuk mendeteksi perubahan tanpa menyatakan aplikasi sudah diimplementasikan.

SHA-256 ZIP asli: `23ec78ee4c49c6cdc6c26eba986a0d810e89d05a94e2574d1fb3a5ab0c92fb9e`.

Jumlah file sumber: **107**; gambar referensi: **88**.

```text
086d211c9c078be5d8c85103472667bdaeaf9725e3a53e99a59e3e7267114840  README.md
72f223d226a20c16893a0573caa3f97bad4f8cf2dd13b52e85bd8a1aa2cf6fff  app.js
5a8175b499c9b38c5e08b9dc75dfa1fcac207ad421a7b4d612e134860b9ee4fd  assets/ayam-geprek.jpg
eb242f9952a217cd2aabb9e865d69e65e06937fd7d4057755d0e8fc849ebc15c  assets/es-teh-manis.jpg
12b7defcb05ee7f68125da264cb3fa23a7d9cf8abe112e7349bed99f565770f5  assets/mi-gomak.jpg
a5bd347c1999919c50c4d20ba7f6b680c370bc264c19e2d07e5e5780f2e582f4  assets/nasi-ayam-kecap.jpg
ecf96fca11d67a460e94b19f2fe7b9a2c155bd44ecc7cadc1105f6495b8311dc  assets/nasi-ayam-sambal-matah.jpg
f1f4c5e9f6a1ffb68ba583339f433a875531fc09ec516d5bfa3026807e3f47cd  assets/nasi-ayam-thumb.jpg
a5bd347c1999919c50c4d20ba7f6b680c370bc264c19e2d07e5e5780f2e582f4  assets/nasi-goreng.jpg
a98016ddf8daf320d0fd4bfb41433a72a321b42d8eed305fb890e0f7428841a5  assets/nasi-telur-dadar.jpg
076831b98043f50f829b6c91db3be4a844641f1c95bccff5c886ed87c661a852  assets/plus-jakarta-400.ttf
b4fc14ec283d54236fd302cdb92546f98ae0ff061ca5ee23453a02bdf4628791  assets/plus-jakarta-500.ttf
50357df108c5d297ec4ece76aeddf49561f3794f67af077cfc2c711b7a75b439  assets/plus-jakarta-600.ttf
32971ad7976930539a11c79ce91ce84092df7f25c5be716b594601842f10a7ae  assets/plus-jakarta-700.ttf
d9e0ddb4a15a0054ad84b4ded3b4b9f354a0b7df426e21a1363d6933728da9d5  assets/plus-jakarta-800.ttf
4158d9db050cbeadcba5da8c58d608ded149d2481365264d88b56a11272ebcdc  assets/sayur-asem.jpg
80b9861a8a81482ad514191ac2539f8cd34e924a9f4343aaa12c6694df9ee667  assets/stan-bu-rina.jpg
a6c9c784c781ffcaa30c8e4a115dadfd20a54e5cf985b462ce4a9789cc527563  index.html
ef38bf0f0f1128ab411e5b473ea25a7982c9e50ff1a63f644a82063c21626ba0  screens/F00_fondasi_visual_dan_komponen.png
a75f08134ea1063965902dfae9ba3c22ec545f5b0410371438fd33c9249a1b14  screens/M01_beranda_kunjungan_kembali.png
65ebf385f377fddd27825321b33ffbad76670ff0afc52805b859f27d5240cd88  screens/M02_pengenalan_asisten.png
0ae43f142da2e533348ce232a3b6b8b2b6a9f2052a863b66c00850a1b329c9d2  screens/M03_beranda_dengan_cart.png
57fbea6d9eb2d2cbcbd4047ce3d6209dc7d2f55357793b6ddd0eadeda36e73a2  screens/M04_hasil_pencarian.png
6731138b0a719cdffbef2870bf40c83d85dd33d3032d129c7156f2a1374bb124  screens/M05_filter_pencarian.png
9b21d1488bee880b5da824c617f2ccd1b0022dd35c60626bcbbc6d746a91dfab  screens/M06_detail_stan_buka.png
6d1647432144c4714aebb12c56ae869aa4ba7a3334349feaf743e896d4945aa9  screens/M07_detail_stan_dengan_cart.png
555d5c6d8e29c4425ff0b942939c2c3d071750d8b9bd9e2e7bb762b2923408e4  screens/M08_detail_menu.png
845541b495f6026a0513cfa51cd03ad3913bad64979342d8783afd1aa68eb302  screens/M09_menu_berhasil_ditambahkan.png
321b4c0c5f5298bc16391a66a46164986809cd0140e28efdf99b1a44ae34f2f5  screens/M10_asisten_pilih_menu.png
70988050d95b070412921c57783a2a8686b698798e4b5d16438a4c06f919c906  screens/M11_asisten_dengan_keyboard.png
d8ee05fe32d9defaeb5d48d02b5f69f1a9f09bcbae3a585d3da1d870f5f8aa59  screens/M12_asisten_meminta_klarifikasi.png
407885e73ee35fb54377515d1d8e4979446a22351607c6025aa96b16d60cc554  screens/M13_hasil_rekomendasi.png
02f3f0d6024a99b020d94f074604669f4a61cae23bd0ddb288684098722dfd82  screens/M14_rekomendasi_dengan_cart.png
0948ed16422b0ef0eb84f7f96d5b85910b73d935ab77873916c4dbf159048028  screens/M15_asisten_gagal.png
79daa3ff9baab171800f2ca1cc1274143380a4f63d1732accb9e306950a9f5e0  screens/M16_rekomendasi_kosong.png
569f175ca2e0deea965eaa96f596dc389f5958d1f0448e8e89cee4166fe13259  screens/M17_keranjang_dua_porsi.png
789355ba791619d206f620961e3fe7d3129c8e7b6e3c1b39395838ed39a87b71  screens/M18_edit_catatan_item.png
9941f69e10c991143160e38abd3f4306ff0343ff68e7e62ceb7cbe60b8c6fe65  screens/M19_hapus_item_dengan_undo.png
f22b6b4e022dcfe5941d13d1683e530ef98e8575552f16b81c0557f364f9ef57  screens/M20_konfirmasi_kosongkan_cart.png
8387dfe68251768c72a9a75c76a2e5f6c6330bc2952efe6026eaafab3a379363  screens/M21_ganti_stan.png
babd547aebe894cd75689c2aecc57ef4a8565e34403a2b78d10d4f393fcf22d7  screens/M22_keranjang_kosong.png
aa38e8abd3b99a5ce02feac9585506fed07970b07febdd2da839173d921078c1  screens/M23_ketersediaan_berubah.png
ec13883179b724aa1ddc118657a05eed8efce5272522d6ddb986e8e2e4ba04ae  screens/M24_konfirmasi_pesanan.png
35ee4ebf201de92a78df25f57fbc4bbffe02e6f345371e601165b72f21c556a4  screens/M25_membuat_pesanan.png
eb5b2b43a9c116307d139303a66cb5d807ab9fb5fca0af29a07cd96a207784f3  screens/M26_pesanan_belum_terkirim.png
23232c1efe2cf678e4458330ae22e93c1e91e48812e610b017d15eff3f8b3a67  screens/M27_hasil_pengiriman_belum_diketahui.png
e8eecdedffe18c3027743138604af699ca7d27f2a48f2eec2d024e894f1741c8  screens/M28_pesanan_berhasil.png
cd751d8e49e228dc5ebc9e3f6059d67569114e393b06d2d955324973f7eecf3f  screens/M29_pesanan_aktif.png
7ef8512d1aab723f040ebffe7f2ac5e53eec608011450aab2505936047862a76  screens/M30_riwayat_mahasiswa.png
3be3863baaabd8f5a0f9b441ebf84475ab27696397e8a090ee07bef6f8f09b8d  screens/M31_menunggu_konfirmasi.png
39eab90b96b36c469bb28da14c6dbb7cb96929781a658acd9346e0ac269427b5  screens/M32_pesanan_diproses.png
35eaaac8090d6712b98fbb62f1ca95bf8a264e27892e7a1c3fe47bb52e061b02  screens/M33_siap_diambil.png
a8735b6c0c914149bb629c8e6140842e1cbee174b7592a599ce7b9b80ec9dd88  screens/M34_pesanan_selesai.png
640cef892b9316cf0a6a159b3c76b0bf3b18bbc1f163655b2a77b7d5fda0e983  screens/M35_pesanan_ditolak.png
0a07d5353cc92ba3c4c3866dc3d5380b0358e54d9c992e7846fdad2c0df97555  screens/M36_profil_mahasiswa.png
4f847809b5dc72ff62806411ad6d79fbc4613fd00408b8eb9a2cf68389e1f359  screens/M37_preferensi_makanan.png
07a154524888a11f8b4f634784ae1765e4bcff97c5b861eda82d9925cf244f0f  screens/P01_dashboard_pengelola.png
e5c9401e8e93741d1f953b56a2d3c289e221d4d84408a90ad9635cdb765c001c  screens/P02_dialog_menutup_stan.png
e0c67b15ad096a5112f7f76050f4e849609a2720905c0b7d09854fa6c5e3c0ae  screens/P03_dashboard_stan_tutup.png
1a338bd92163e510a6efd6658991a76b5bbd14cb8dc01dfa93a88b217948c603  screens/P04_pesanan_baru.png
462543cfdfc6a6c6975a68aef898f7b44ae862b7f8bd83e9a9786ed565a4f847  screens/P05_pesanan_diproses.png
313174b620b81960d50d09ece63cab80cd1d22c01509245acd52a4bbac609d88  screens/P06_pesanan_siap.png
4a56886fcc39729f9b79bffb25f4c71048f51897ee1f7c7a5aa812267826f4c0  screens/P07_riwayat_pengelola.png
2f29b5aa2f47526f70f894418579b6e0b3de8ff359aa0c3bc2915741fd12e70f  screens/P08_detail_pesanan_baru.png
71b8c837b69107d807f411d263dad3aa192c84f8f6e4053f584b47c1630c696a  screens/P09_detail_pesanan_diproses.png
0c3fbbab48df7fdfd63891cf2fc1637a245e51a11cb6dfd0207a94e28beaced6  screens/P10_detail_siap_diambil.png
5e30cd17e4fc5e116b78247d415c6740cd6a2db5b4bcce43d07b2c3637ddd617  screens/P11_konfirmasi_penyerahan.png
cbf240f7bb1fb1e6b04694ebd0a942c52f87d81156d510605b2a91f383d21bd4  screens/P12_detail_pesanan_selesai.png
51e1554e4bf77d4696cfff9470a124652f99fdee8b807438ee38863d193ede72  screens/P13_konfirmasi_penolakan.png
538255a4f23f231a0bdc7c7f454b9def3b13d5fbc046d6d0e6525516db07c968  screens/P14_detail_pesanan_ditolak.png
baa7108204515a89de8a903f271cc884be0b8bf6fb722d9ec8db1f8882173f8c  screens/P15_kelola_menu.png
961b0df37813224039e83646da8efa350c13a0a62f1f4276957430bfb18c052c  screens/P16_gagal_ubah_ketersediaan.png
3de2cf35405b64e5268d3e566813d9c6920d3d4e357a3d026c9125c3cc7a6078  screens/P17_pengaturan_stan.png
3abd80031a8247eab5d7dba6c8fca87a7d30f674e0fc0c7decf50cc2b68b31db  screens/P18_profil_pengelola.png
f8a0d01f3232733c37e6413af7a1c30f0a6433c297cd8b35573b2d6832483cb3  screens/Q01_beranda_cart_360_dp.png
8ba9327ea3f1ff74103862fc9345daf34cb34ada87cc69c7b895d06ef3cfb0d7  screens/Q02_detail_stan_412_dp.png
bef1f15c8ecff12f222a039e25cbd298552ef193591a7801b833e706d5f5e35a  screens/Q03_beranda_teks_150.png
4feab669d7e2d57a4daba9dc5ac3e34dbe8db94b36642c704967b74a249403cb  screens/Q04_rekomendasi_teks_panjang.png
f7b3138e9c70c14e50abc73d931b7cee86b67c31a9e9900f0c3067c5895c6b9f  screens/Q05_keranjang_delapan_porsi.png
a7eed2f9375dcbf9be19f6c4c1e808de78ac7756d7c67103786075af7d45646a  screens/Q06_cart_dengan_keyboard.png
bef1f15c8ecff12f222a039e25cbd298552ef193591a7801b833e706d5f5e35a  screens/S01_loading_beranda.png
570a2a9f679146d3d54497947d71ef64ed5fe57bf63655c40cd114169a6b1a55  screens/S02_hasil_pencarian_kosong.png
0331f1dc796d1f886b9da6e119ce2c2fab66a466e978d705f45d15a2635f3588  screens/S03_offline_dengan_data.png
fee35cba4eb9e0671d21130133cd43318454b9cbb67babaa30c11effd21b31eb  screens/S04_offline_tanpa_data.png
5376f55718402e2085e44e820c6e7a51df32be80b804e5f6f774b50d291906c0  screens/S05_gagal_memuat_pesanan.png
f87cd0c1e27227514b57109cf3aa485071dd98d6f1f0ffef6bd8c6ed922bdc3a  screens/S06_detail_stan_tutup.png
04d9538613501593c04153cf8ce1e1b45df2e1edeeb3ad473f77474230552382  screens/S07_detail_menu_habis.png
fe72ffd3aa66d7d4ab275fd071f4fb8b1149f1dab69196df7a0625e713ae8259  screens/S08_pembaruan_status_gagal.png
11ade3c4c8be47e4a16653ffc42a7af0e2911a96e5e7250542b5ec45625eab15  screens/S09_loading_daftar_pesanan.png
8642c8e304a46152a4a873ae0859972afcbb627405c2392d8b238c1017eb5b49  screens/S10_gagal_memuat_katalog.png
ca52b760975cc90d9219571a24885c5746fe3ca9b56cf3d2328cb560360181f0  screens/S11_stan_belum_memiliki_menu.png
97b22a32912c8235de220bbd77af20fa2b86cb507baf5ecd7124bcf468773be8  screens/S12_pesanan_mahasiswa_kosong.png
887d747dd18ad44713353dfe5f16128fab7230f3f0ad6fb7f300a3e5121cb0c8  screens/S13_antrean_pengelola_kosong.png
734cb5219b0d5cb1ec7377558e6c404209c6322b31480bbb4d77c18fcbaf715f  screens/S14_filter_menu_kosong.png
e76dce1905f7b005ef02360647e38a7f1d925d8d0cac541dd972e2d68e0854ca  screens/S15_foto_makanan_gagal.png
96d33d7556890310af75c30b62d0d7122178df92187314962873e9ee32eef4f2  screens/S16_gagal_ubah_status.png
23cddce43bfa14da40ab2a19e9bde0e438a8cbb28c1b1fa6910756fb21f7dd8e  screens/S17_pengelola_offline.png
55737053d5d085b64ddb5204b94fa25e558e2d331bba409aa45fc0126946e836  screens/U01_penjelasan_notifikasi.png
291503ff7ca42553d06907683b4c65fade49b3755a700653f85ca0dd0599bc71  screens/U02_izin_notifikasi_ditolak.png
13ea2521ce93d50386b5bd7f656c305c1d4369aeaf165d5a16996772ee1136fc  screens/U03_notifikasi_aktif.png
0792a85acd09a10f21f9b83acba67b3d84d13b39840cf6f0d5db13151a1ec524  screens/U04_bantuan.png
ff7587fb5df9306a8cc5cd11e1ed60fa8cfd7bcf458559326f1bbb6efa73a31e  screens/U05_tentang_kantincerdas.png
bbbbfd311c86c55f1f891072ba9e75a72ceb938c70a98a8a6a88e3d084defccf  screens/U06_data_akun_pengelola.png
2d594d6cc93ea69f64c0f523d9bf2547294047fd2350de8e2f902ba718fe876d  screens/U07_konfirmasi_keluar.png
80bbd311a48e3e2be94d8fd1afdb57c319c1b7519cf27d41d02679d240ce36b0  screens/U08_simpan_pengaturan_gagal.png
2dec7bdff00ab7f3bcf102befcafee92ff3b352100b23f333500729e3d1e4da8  screens/U09_preferensi_tersimpan.png
71b791c1667a1e964a17167e889c1d0518178103760e3c0ed3760ca6d659757b  styles.css
```

## 15. Rujukan teknis

- Struktur UI/ViewModel/repository diadaptasi secara terbatas dari [Guide to app architecture — Flutter](https://docs.flutter.dev/app-architecture/guide).
- Pemeriksaan semantics dan text scaling merujuk [Accessibility — Flutter](https://docs.flutter.dev/ui/accessibility).
- Format pesan commit mengikuti [Conventional Commits 1.0.0](https://www.conventionalcommits.org/en/v1.0.0/), dengan delapan jenis yang dipilih pengguna.
- Pemisahan major/minor/patch dan sifat 0.x sebagai pengembangan awal merujuk [Semantic Versioning 2.0.0](https://semver.org/). Prefix tag KantinCerdas adalah konvensi repository ini; nilai versi aplikasi tetap numerik.

Rujukan diakses saat penyusunan 6 September 2026. Sumber produk tetap ZIP pengguna; tautan teknis tidak digunakan untuk mendesain ulang aplikasi.
