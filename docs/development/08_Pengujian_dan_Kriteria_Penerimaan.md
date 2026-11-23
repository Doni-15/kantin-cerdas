# Kantin Cerdas · Pengujian dan kriteria penerimaan Android

Edisi 19 November 2026. Gunakan dokumen ini untuk menguji aplikasi Flutter dan backend melalui alur pengguna. Daftar di bagian terakhir memetakan setiap aturan bisnis ke skenarionya. Status awal seluruh uji aplikasi adalah **belum dijalankan**.

## Hasil yang sudah tersedia

| Objek | Hasil dan batas bukti |
|---|---|
| Branch rebuild/clean-start saat inspeksi | Titik masuk aplikasi dan tes widget yang diperiksa masih berupa penghitung bawaan Flutter. Belum tersedia hasil alur bisnis ujung ke ujung. [Titik masuk](https://github.com/Doni-15/kantin-cerdas/blob/rebuild/clean-start/app/lib/main.dart) · [Tes widget](https://github.com/Doni-15/kantin-cerdas/blob/rebuild/clean-start/app/test/widget_test.dart) |
| Format Code 128 | Tiga contoh nomor, masing-masing dalam tiga ukuran gambar, menghasilkan 9/9 pembacaan persis termasuk nol awal. Pembacaan dari layar atau kamera perangkat fisik masih menunggu P1. |
| Model status | Enam status akhir menurut spesifikasi terkini adalah Selesai, Dibatalkan, Ditolak, Gagal Dipenuhi, Tidak Diambil, dan Gagal Diambil. Verifikasi implementasi Gagal Diambil melalui O4. |
| Perilaku layanan Auth dan Realtime | Dokumentasi vendor menjelaskan penautan otomatis dan cache izin. A1–A4 dan R2 menguji dampaknya pada konfigurasi proyek. |

## Persiapan dan pencatatan

Gunakan proyek pengujian dengan konfigurasi Auth, SMTP, database, Realtime, worker pengiriman, dan aplikasi Android yang akan diuji. Siapkan dua perangkat Android, akun uji untuk tiap peran, dua Admin aktif untuk uji konkurensi, dua kantin, menu tersedia, menu habis, serta menu arsip. Pakai uang dan akun simulasi. Catat versi build/commit, konfigurasi layanan, model HP, versi Android, urutan tindakan, waktu, hasil aktual, dan ID pengujian. Samarkan email serta token pada bukti. Untuk uji persaingan, catat urutan commit dan periksa data akhir melalui pembacaan backend.

## Skenario integrasi prioritas

A1–A3 mengikuti [KC-AUTH-AMEND-2026-11-20-01](Kantin_Cerdas_AUTH_005A_Amendment_Final/AMENDEMEN_AUTH_005_005A_2026-11-20.md). Kelulusan hosted A1–A4 masih menunggu QA.

| Uji | Persiapan dan tindakan | Kriteria penerimaan |
|---|---|---|
| A1 · Penautan pada akun password | Verifikasi akun email/password dengan profil dan relasi. Masuk Google dengan email sama melalui PKCE dan cek juga grant ID token. | Linking sah mempertahankan satu ID, satu profil, role, status dan relasi. Kedua metode sah bekerja. |
| A2 · Google-only dan identitas belum terverifikasi | Pada akun Google-only, coba signup ulang, login password dan reset. Untuk email lain, buat signup password belum terverifikasi lalu masuk dengan Google pada email yang sama. | Google-only tetap tanpa password otomatis dan pemulihan memakai Google. Catat perubahan identitas di provider. Kredensial belum terverifikasi tidak boleh membuka data milik pengguna lain. |
| A3 · Dua pendaftaran dan inisialisasi profil | Mulai signup email dan Google hampir bersamaan. Ulangi kedua urutan. Lengkapi profil pada dua perangkat dan periksa akun, identitas, sesi serta penyimpanan foto. | Linking sah tetap satu ID dan satu profil. Setiap sesi valid menunjuk ID yang sama. Relasi, role dan otorisasi terjaga. |
| A4 · Pendaftaran dan pemulihan Android | Gunakan SMTP QA dan App Links terverifikasi. Uji cold start, foto Google dan pengganti, pemulihan profil, reset, tautan invalid/expired/used, perubahan email dua alamat dan logout dua perangkat. | Email tiba dan Android membuka App Link terverifikasi. Foto dan status verifikasi wajib. Tautan invalid ditolak, registrasi dapat dilanjutkan, dan sesi perangkat lain tetap aktif setelah logout lokal. |
| K1 · Keranjang satu kantin | Dengan item di kantin A, pilih item B, batalkan penggantian, lalu ulangi dan setujui. Ubah harga, tandai Habis atau arsipkan satu item sebelum checkout. | Pembatalan menjaga draft A. Persetujuan mengganti isi. Harga lama/baru terlihat dan memerlukan persetujuan ulang. Item Habis/arsip memblokir seluruh checkout hingga pengguna bertindak. |
| K2 · Dua perangkat dan respons hilang | Kirim checkout dari dua perangkat untuk versi keranjang yang sama. Putuskan koneksi setelah commit, tutup aplikasi, buka dan cari hasil dengan ID upaya semula. Coba gunakan ID yang sama untuk isi berbeda. | Paling banyak satu pesanan. Setelah commit sukses nomor pesanan dapat dipulihkan. ID lama tidak menerima isi berbeda. Saat offline tidak ada pemesanan baru atau pengiriman otomatis. |
| K3 · Perubahan bersamaan | Jalankan checkout bersamaan dengan harga berubah, kantin tutup, menu diarsipkan, Customer/Owner dinonaktifkan, dan promosi Customer. Uji masing-masing arah commit. | Checkout sebelum perubahan menghasilkan snapshot sah. Perubahan lebih dahulu membuat checkout ditolak atau meminta persetujuan harga. Akun dengan pesanan aktif terlindungi dari penonaktifan atau promosi terkait. |
| O1 · Terima vs batalkan | Owner menerima bersamaan dengan Customer membatalkan pesanan Menunggu Konfirmasi. Ulangi dengan urutan dibalik. | Satu perubahan sah, satu riwayat yang konsisten, satu rangkaian akibat bisnis. Pihak yang kalah mendapat status aktual. |
| O2 · Status aktif dan terminal | Coba setiap jalur pada matriks dokumen 07, termasuk penolakan tanpa alasan dan tindakan terhadap status akhir. Biarkan waktu estimasi berlalu. | Hanya tindakan pelaksana yang sah dari status asal yang sah berhasil. Alasan wajib tervalidasi. Estimasi dan waktu tunggu tidak memicu perubahan otomatis. |
| O3 · Tunai di lokasi | Dari Siap Diambil, pindai nomor dua kali, cari manual, batalkan konfirmasi, lalu Owner konfirmasi setelah serah terima dan menerima uang tunai. | Pembacaan dan pembatalan tidak mengubah status. Akhirnya tersimpan satu Selesai bersamaan dengan Lunas. |
| O4 · Gagal Diambil | Dari Siap Diambil, coba akun selain Owner yang berhak, alasan kosong dan batal konfirmasi. Kemudian Owner mengisi alasan dan mengonfirmasi. Ulangi pengiriman dan uji bersamaan dengan Selesai pada pesanan uji terpisah. Coba juga dari Diproses. | Hanya satu transisi sah dari Siap Diambil yang menang. Jika Gagal Diambil berhasil, pembayaran tetap Belum Lunas. Customer dan Owner melihat alasan di riwayat, barcode hilang, hitungan aktif hanya mencakup pesanan lain. Setelah reconnect hasil tetap sama. Tidak ada push khusus. |
| P1 · Pemindaian di kantin | Tampilkan Code 128 pada HP Customer. Coba kamera/perangkat Owner pada ukuran layar dan pencahayaan lokasi, lalu pakai nomor manual. Coba nomor kantin lain. | Nomor terbaca persis, termasuk nol depan. Owner hanya melihat pesanan miliknya. Input manual bekerja saat pindai gagal. Barcode Customer hanya muncul ketika siap. |
| M1 · Admin dan pengajuan | Kirim dua pengajuan menunggu, tolak tanpa alasan, tinjau Customer dengan pesanan aktif, lalu ajukan kembali setelah terminal. Uji dua Admin saling menonaktifkan secara bersamaan. | Maksimal satu pengajuan menunggu. Alasan penolakan wajib. Indikator aktif terlihat tanpa rincian transaksi. Setelah konflik tetap ada Admin aktif dan tindakan yang berhasil tercatat. |
| M2 · Regresi perubahan akses | Picu tindakan perubahan akses dari UI Admin, pantau state Riverpod dan permintaan backend sampai respons tampil. | Tidak terjadi CircularDependencyError. Controller tidak membaca provider turunan yang mengamati controller itu sendiri. Satu konfirmasi yang sah menghasilkan satu mutasi logis. |
| R1 · Push dan pemulihan | Picu tujuh kejadian pada dokumen 07 serta Selesai dan Gagal Diambil. Simulasikan FCM gagal, izin notifikasi ditolak, aplikasi di latar, dan worker berhenti setelah mengirim sebelum memperbarui antrean. | Penerima sesuai matriks. Selesai dan Gagal Diambil tidak menghasilkan push. Duplikat tidak menyebabkan aksi bisnis ganda. Pesanan tetap tersimpan. Saat kembali online aplikasi membaca status terbaru. |
| R2 · Pencabutan akses | Login akun yang sama di dua HP. Logout satu perangkat, lalu uji perubahan akun/peran dengan koneksi channel masih terbuka. Periksa perangkat lama, perangkat yang masih sah dan detail melalui Shelf. | Sesi dicabut tidak menerima pembaruan privat baru atau mengambil detail terlindungi. Perangkat sah tetap bekerja sesuai hak terbaru. Antrean lama tidak membocorkan rincian ke perangkat yang sudah kehilangan akses. |
| G1 · Kuota dan kegagalan AI | Saat tersisa satu pemanggilan, kirim dua permintaan bersamaan. Lewati 00.00 WIB. Simulasikan batas proyek, timeout sesudah pengiriman, hasil tak valid, dan fallback. | Maksimum 10 pemanggilan per Customer per tanggal Jakarta. Permintaan terkirim yang hasilnya tidak pasti dihitung. Fallback tidak memakan kuota. Batas proyek diutamakan dan checkout tetap berjalan. |
| G2 · Kualitas rekomendasi | Masukkan batas harga, ubah harga/ketersediaan sebelum kartu ditampilkan, minta menu habis dan tanyakan alergen yang tidak tercatat. | Kartu sesuai katalog terkini dan batas anggaran. Kondisi Habis/Tutup hanya sebagai informasi sesuai permintaan. Ketidakpastian dinyatakan. AI hanya membuka detail, tanpa mutasi keranjang atau pesanan. |
| E1 · Uji lengkap | Daftarkan Customer dan calon Owner, Admin menyetujui Owner, Owner menerbitkan dan membuka kantin. Customer memesan, Owner menerima dan menyiapkan, lalu lakukan serah terima tunai. Ulangi dengan Gemini tidak tersedia. | Nomor, snapshot, timeline dan hasil pembayaran sama pada kedua perangkat setelah aplikasi dibuka ulang. Riwayat dapat dibuka. Tidak diperlukan tindakan Admin untuk menyelesaikan transaksi. |

## Bukti dan keputusan pilot

Auth memerlukan bukti A1–A4 pada Supabase pengujian. Pilot pemesanan memerlukan bukti transaksi, akses, perangkat, notifikasi serta hasil lulus O4 dan E1. Pengujian Gemini berlaku sebelum mengaktifkan layanan eksternal. Simpan satu baris per pelaksanaan dan tautkan bukti yang dapat diperiksa kembali.

| ID uji | Build, perangkat, tanggal | Hasil aktual | Lulus / gagal / terhalang | Bukti dan tindak lanjut |
|---|---|---|---|---|
| A1 dan A3 | Shelf QA otomatis, 20 November 2026 | Kedua grant menerima linked principal berbasis ID pada mock. Google OAuth dan race lintas-provider belum diuji. | BLOCKED hosted | Lihat prosedur QA di [panduan Auth](../AUTH.md) |
| A2 | GoTrue v2.186.0 lokal, 20 November 2026 | Fixture Google-only tetap satu ID tanpa password, identity email, sesi baru, atau email recovery. Kasus akun password belum terverifikasi masih menunggu OAuth asli. | PASS terbatas lokal · BLOCKED hosted | Lihat prosedur QA di [panduan Auth](../AUTH.md) |
| A4 | APK debug, emulator API 34 | Cold start, foto wajib, pemulihan profil, reset, perubahan email dua alamat dan logout lulus lokal. | PASS lokal · BLOCKED hosted | Verifikasi domain & App Links di [panduan Auth](../AUTH.md) |

## Keterlacakan 58 aturan bisnis

Setiap baris mengambil skenario dari spesifikasi modul asal. Untuk sebuah aturan, periksa juga hasil dan batasan di dokumen bisnisnya. Matriks ini dapat dipakai kembali setelah revisi implementasi.

### Order

| Aturan | Perilaku | Pemeriksaan per aturan |
|---|---|---|
| ORDER-001 | Pembatalan oleh Customer sebelum konfirmasi | Simulasikan Customer membatalkan bersamaan dengan Owner menerima. hanya satu perubahan status yang boleh menang. |
| ORDER-002 | Pesanan tidak diambil | Setelah ditandai Tidak Diambil, pastikan status pembayaran belum lunas dan record tetap terlihat di riwayat. |
| ORDER-003 | Penolakan pesanan oleh Owner | Tolak permintaan tanpa alasan. terima alasan yang valid hanya ketika status masih Menunggu Konfirmasi. |
| ORDER-004 | Penyelesaian tunai saat serah terima | Coba menyelesaikan pesanan tanpa kondisi serah-terima. uji bahwa status Selesai dan Lunas tidak dapat terpisah. |
| ORDER-005 | Perubahan harga sebelum checkout | Ubah harga setelah item ada di keranjang. checkout harus tertahan hingga perubahan dikonfirmasi. |
| ORDER-006 | Item Habis di dalam keranjang | Ubah satu dari beberapa item menjadi Habis. verifikasi bahwa item tetap terlihat dan checkout tidak dapat diselesaikan. |
| ORDER-007 | Buka/Tutup kantin secara manual | Tutup kantin dengan pesanan aktif. pastikan pesanan lama tetap ada dan checkout baru ditolak. |
| ORDER-008 | Checkout online dan idempotensi | Putus koneksi setelah server sukses tetapi sebelum respons diterima. retry tetap menghasilkan tepat satu pesanan. |
| ORDER-009 | Satu kantin per keranjang dan pesanan | Tambah menu dari kantin kedua pada keranjang berisi kantin pertama. periksa kedua opsi konfirmasi. |
| ORDER-010 | Jumlah item, catatan, dan keranjang tersimpan | Periksa kuantitas default, pengurangan 1→0, dan pemulihan draft saat pengguna membuka aplikasi kembali. |
| ORDER-011 | Snapshot pesanan tidak dapat diedit | Ubah menu, harga, dan catatan setelah checkout. snapshot pesanan terdahulu harus identik. |
| ORDER-012 | Estimasi persiapan dan status Siap Diambil | Lewatkan waktu estimasi tanpa tindakan Owner. pesanan tidak boleh otomatis menjadi Siap Diambil. |
| ORDER-013 | Gagal Dipenuhi setelah penerimaan | Gagal Dipenuhi harus meminta alasan dan menghasilkan status terminal yang tidak Lunas. |
| ORDER-013A | Batas status Gagal Dipenuhi | Coba melakukan transisi Siap Diambil→Gagal Dipenuhi. pastikan ditolak. |
| ORDER-013B | Gagal Diambil setelah Siap Diambil | Periksa izin Owner, alasan wajib, konfirmasi, satu status akhir, pembayaran Belum Lunas, riwayat, barcode dan indikator aktif sesuai O4. |
| ORDER-014 | Syarat penandaan Tidak Diambil | Coba tindakan dari Diproses dan setelah berbagai durasi tunggu. hanya Siap Diambil yang memenuhi kondisi status. |
| ORDER-015 | Bukti pengambilan dengan barcode | Pemindaian atau input manual hanya membuka/mengidentifikasi pesanan tanpa mengubah status ataupun pembayaran. |
| ORDER-016 | Pesanan pending tanpa timeout otomatis | Biarkan pending melewati berbagai waktu. tidak boleh muncul transisi otomatis. |
| ORDER-017 | Sinkronisasi realtime dan push penting | Putuskan jaringan, ubah status dari pihak lain, sambungkan kembali. tampilan memuat status backend yang benar. |
| ORDER-017A | Tujuh kejadian notifikasi push | Uji matriks ketujuh event, pastikan Selesai dan Gagal Diambil tidak memicu push dan Admin tidak menerima push transaksi. |

### Owner

| Aturan | Perilaku | Pemeriksaan per aturan |
|---|---|---|
| OWNER-001 | Profil wajib dan opsional kantin | Validasi publish dengan nama/kampus/lokasi yang lengkap serta deskripsi/foto kosong. |
| OWNER-002 | Satu Owner satu kantin dan publikasi awal | Coba publish tanpa profil wajib/menunya belum tersedia. pastikan tidak lolos, dan publish sah dimulai Tutup. |
| OWNER-002A | Visibilitas kantin terbit saat menu tidak dapat dipesan | Jadikan seluruh menu Habis/arsip. kantin tetap muncul, tetapi tidak ada item yang bisa di-checkout. |
| OWNER-002B | Tidak ada unpublish manual pada MVP | Kantin sudah publish kemudian Tutup. tetap tampil, dan tidak muncul aksi unpublish. |
| OWNER-003 | Jam operasional informatif dan estimasi persiapan | Atur jam operasional lalu lewati jadwal. status Buka/Tutup tidak berubah tanpa tindakan Owner. |
| OWNER-004 | Kategori menu standar dan kustom | Tambah kategori sendiri dan pastikan setiap menu masih menunjuk tepat ke satu kategori yang sah. |
| OWNER-004A | Kategori hanya boleh dihapus jika benar-benar kosong | Coba hapus kategori yang hanya berisi menu arsip. tindakan harus ditolak sampai menu dipindahkan. |
| OWNER-005 | Data menu, status, arsip dan pemulihan | Arsip menu dan ubah harganya. periksa menu tidak hilang dari order yang sudah dibuat. |
| OWNER-005A | Menu diarsipkan saat masih di keranjang | Arsip item keranjang, periksa label dan blok checkout. pulihkan lalu validasi ulang dengan harga terbaru. |
| OWNER-006 | Dashboard Owner operasional | Hitung jumlah aktif per status dan pastikan tidak muncul fitur analitik keuangan. |

### Customer

| Aturan | Perilaku | Pemeriksaan per aturan |
|---|---|---|
| CUSTOMER-001 | Beranda daftar kantin tanpa pemilihan universitas | Buka beranda: kantin diterbitkan muncul, termasuk Tutup. tidak ada pemilihan universitas. |
| CUSTOMER-002 | Halaman detail kantin | Cari menu dalam detail satu kantin. hasil tidak boleh mengambil menu kantin lain. |
| CUSTOMER-003 | Pencarian utama lintas kantin dan makanan | Masukkan kata yang cocok dengan nama kantin dan menu. verifikasi dua kelompok hasil berbeda. |
| CUSTOMER-004 | Keranjang, checkout, dan pembayaran tunai | Lakukan perjalanan lengkap keranjang→checkout→pesanan. pembayaran tetap berlabel tunai. |
| CUSTOMER-005 | Detail pesanan dan barcode pengambilan | Lihat detail di status pending, diproses, siap dan selesai. barcode hanya muncul saat Siap Diambil. |
| CUSTOMER-006 | Pesanan aktif, riwayat, dan profil Customer | Setiap status terminal tetap muncul di Riwayat dan halaman detail dapat dibuka. |
| CUSTOMER-006A | Penolakan pengajuan Owner saat masih ada pesanan aktif | Ajukan Owner ketika ada satu pesanan aktif. Admin wajib menolak dengan alasan, bukan menunda aktivasi. |

### Authentication

| Aturan | Perilaku | Pemeriksaan per aturan |
|---|---|---|
| AUTH-001 | Verifikasi email untuk pemesanan | Akun email/password belum terverifikasi tidak dapat checkout. setelah verifikasi sah diperbolehkan jika syarat lain terpenuhi. |
| AUTH-002 | Registrasi dua langkah dan foto profil wajib | Uji pendaftaran dua metode, foto Google tersedia/tidak, dan konfirmasi ketika foto diganti. |
| AUTH-003 | Login, logout, dan pengelolaan sesi | Tutup/buka aplikasi, kedaluwarsa sesi, logout perangkat, dan akun dinonaktifkan harus menghasilkan akses sesuai aturan. |
| AUTH-004 | Reset password dan pemulihan akun | Uji token reset sekali pakai, kedaluwarsa, dan pembedaan akun Google-only. |
| AUTH-005 | Perubahan profil dan informasi autentikasi | Ganti email/password secara sah. pastikan akun dan hubungan pesanan yang sama tetap dimiliki pengguna. |
| AUTH-005A | Penautan identitas otomatis oleh Supabase | A1–A3 membuktikan satu ID dan profil, preservasi kepemilikan, serta penolakan kredensial belum sah. |

### Admin

| Aturan | Perilaku | Pemeriksaan per aturan |
|---|---|---|
| ADMIN-001 | Form pengajuan Owner yang ringkas | Form hanya memerlukan tiga input rencana usaha, sementara identitas akun terisi dari autentikasi. |
| ADMIN-002 | Review manual pengajuan Owner | Ajukan dua pengajuan pending dan coba menyetujui pemohon yang masih memiliki pesanan aktif. pastikan aturan tetap ditegakkan. |
| ADMIN-003 | Aktif/nonaktif akun dan riwayat tindakan | Coba menonaktifkan tanpa alasan, mengaktifkan kembali, dan mencari jejak keputusan Admin. |
| ADMIN-003A | Larangan penonaktifan saat ada pesanan aktif | Akun dengan pesanan Menunggu Konfirmasi, Diproses, atau Siap Diambil tidak dapat dinonaktifkan. |
| ADMIN-003B | Owner nonaktif dan kelayakan checkout kantin | Nonaktifkan Owner dengan kantin Buka dan tanpa pesanan aktif. kantin tetap ditampilkan tetapi checkout ditolak. |
| ADMIN-004 | Pengawasan data dasar kantin read-only | Verifikasi antarmuka dan backend menolak semua upaya modifikasi kantin oleh Admin. |
| ADMIN-005 | Dashboard Admin dan perlindungan akses | Pastikan user non-Admin ditolak, Admin nonaktif tidak bisa bertindak, dan Admin terakhir tidak bisa dinonaktifkan. |

### AI Food Assistant

| Aturan | Perilaku | Pemeriksaan per aturan |
|---|---|---|
| AI-001 | Cakupan asisten kuliner serbaguna | Tanyakan menu yang bisa dibeli dan resep masakan umum. kedua jenis permintaan ditangani sesuai cakupannya. |
| AI-002 | Data nyata dan keterpesanan rekomendasi | Minta menu dari kantin Tutup. hanya tampilkan sebagai informasi berstatus jelas ketika permintaan mencakupnya. |
| AI-003 | Chat khusus dan kartu rekomendasi | Buka kartu Lihat Detail. navigasi menuju menu nyata dan tidak mengubah keranjang. |
| AI-004 | Budget ketat, preferensi fleksibel, keamanan pangan | Minta makanan <= batas harga dan klaim alergi. hanya rekomendasi dalam budget, tanpa kepastian alergi yang tidak didukung. |
| AI-005 | Integrasi rekomendasi dan checkout manual | Minta AI memasukkan item/checkout. sistem tidak membuat mutasi transaksi dan menawarkan navigasi detail. |
| AI-006 | Arsitektur hybrid dan fallback pencarian | Simulasi putus API: fallback katalog bekerja, order tetap bisa dibuat melalui alur normal. |
| AI-006A | Gemini Flash-Lite Free Tier dan biaya API Rp0 | Periksa konfigurasi proyek Free Tier dan tanpa billing berbayar. jika limit tercapai sistem tidak mengeluarkan biaya API. |
| AI-006B | Batas 10 panggilan AI harian dan fallback | Uji batas per Customer dan proyek, timeout, respons AI tak valid, serta backend-only search yang tidak memakai kuota. |
