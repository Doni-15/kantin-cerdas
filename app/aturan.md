# ARCHITECTURE RULES

Dokumen ini adalah aturan wajib untuk seluruh pengembangan aplikasi KantinCerdas.

Untuk peta struktur dan status terkini, lihat `README.md`.

---

# 1. PRINSIP UTAMA

Aplikasi menggunakan prinsip:

> ONE RESPONSIBILITY = ONE JOB

Setiap file, class, dan module harus memiliki tanggung jawab
yang jelas dan terbatas.

Jangan menggabungkan beberapa tanggung jawab yang berbeda
dalam satu file/class hanya demi mengurangi jumlah file.

---

# 2. STRUKTUR ROOT

Struktur dasar aplikasi:

lib/
├── main.dart
├── kantin_cerdas_app.dart   (target: app/kantin_cerdas_app.dart)
├── theme/
├── core/
└── features/

Role aplikasi mengikuti enum UserRole:

- customer (Mahasiswa)
- owner    (Pengelola kantin)
- admin    (Administrator)

Semua role berada dalam SATU aplikasi.

---

# 3. MAIN.DART

File:

lib/main.dart

TANGGUNG JAWAB:
- Menjadi entry point aplikasi.
- Melakukan initialization minimum yang diperlukan Flutter.
- Membungkus aplikasi dengan ProviderScope (Riverpod).
- Menjalankan KantinCerdasApp.

CONTOH:

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: KantinCerdasApp()));
}

DILARANG:
- Menaruh UI.
- Menaruh business logic.
- Memanggil API fitur.
- Mengambil data user.
- Menentukan logic login.
- Menentukan logic pemesanan.
- Mengatur state fitur.
- Menaruh konfigurasi fitur.

PRINSIP:

main.dart hanya bertugas MENGHIDUPKAN aplikasi.

Jika main.dart mulai memiliki banyak logic,
pindahkan logic tersebut ke layer yang sesuai.

---

# 4. ROOT WIDGET DAN ROUTER

File:

lib/kantin_cerdas_app.dart
lib/core/router/   (target: lib/app/router/)

TANGGUNG JAWAB:
- Menjadi root widget aplikasi.
- Mengatur MaterialApp.router.
- Mengatur theme global (dari lib/theme/).
- Mengatur router global.
- Memilih shell berdasarkan auth state dan role (AppEntryPage).
- Mengatur localization global jika diperlukan.

CONTOH:

class KantinCerdasApp extends StatelessWidget {
  const KantinCerdasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'KantinCerdas',
      theme: ...,        // dari lib/theme/kc_theme.dart
      routerConfig: ..., // dari app_router.dart
    );
  }
}

DILARANG:
- Menaruh business logic fitur.
- Memanggil API fitur.
- Mengambil data pesanan.
- Mengambil data profile.
- Menaruh logic authentication.
- Menaruh logic halaman tertentu.
- Menjadi tempat penyimpanan state fitur.

PRINSIP:

App mengatur LINGKUNGAN aplikasi,
bukan menjalankan FITUR aplikasi.

CATATAN:

Router dan root widget BOLEH mengimpor fitur karena tugasnya
merangkai fitur. Karena itu router tidak boleh tinggal di core/.
Saat ini router masih di core/router/ dan dicatat sebagai
utang teknis di README.md bagian 20.

---

# 5. CORE DAN THEME

Folder:

lib/core/
lib/theme/

TANGGUNG JAWAB:

Core berisi komponen yang bersifat GENERAL
dan dapat digunakan oleh banyak feature.

Theme berisi token visual (KcColors, KcTypography, KcSpacing,
KcRadius, KcSizes, KcTheme).

Contoh:

core/
├── widgets/
├── services/
├── utils/
└── error/

theme/
├── kc_colors.dart
├── kc_typography.dart
├── kc_spacing.dart
├── kc_radius.dart
├── kc_sizes.dart
├── kc_theme.dart
└── kc_theme_exports.dart

CORE DAN THEME TIDAK BOLEH:
- Bergantung kepada feature tertentu.
- Mengandung business logic khusus feature.
- Mengandung kode pesanan khusus.
- Mengandung kode profile khusus.
- Mengandung kode checkout khusus.

CONTOH SALAH:

core/
└── order_helper.dart

Jika hanya digunakan oleh fitur pesanan,
kode tersebut seharusnya berada di feature orders.

PRINSIP:

Core boleh digunakan oleh feature.

Feature TIDAK boleh menjadi dependency Core.

---

# 6. FEATURE

Semua functionality aplikasi harus dikelompokkan
berdasarkan feature.

Ada dua jenis folder di features/:

1. Fitur domain (membawa logika dan data).
   Contoh: auth/. Nanti: catalog/, cart/, orders/, chat/.

2. Fitur role (halaman dan navigasi khusus role).
   Contoh: admin/, customer/, owner/.

Contoh:

features/
├── auth/
├── admin/
├── customer/
├── owner/
└── shell/

Setiap feature bertanggung jawab terhadap domain/functionality-nya sendiri.

auth/
→ hanya mengurus autentikasi.

customer/
→ hanya mengurus halaman dan navigasi milik customer.

shell/
→ hanya mengurus kerangka navigasi per role.

ATURAN ANTAR FEATURE:

- admin/, customer/, dan owner/ TIDAK BOLEH saling mengimpor.
- Semua feature BOLEH mengimpor auth/ (User dan UserRole).
- Hanya shell/ dan router yang boleh mengimpor halaman dari
  beberapa feature.
- Logika bisnis yang dipakai lebih dari satu role (misalnya pesanan)
  masuk ke satu fitur domain, bukan diduplikasi di tiap folder role.

---

# 7. JANGAN MEMBUAT GOD CLASS

DILARANG membuat satu class yang mengurus:

- API
- parsing
- business logic
- state
- navigation
- UI

secara bersamaan.

Contoh yang SALAH:

class OrderManager {
  // API
  // JSON parsing
  // validation
  // state
  // navigation
  // UI
}

Pecah berdasarkan tanggung jawab.

---

# 8. ATURAN DEPENDENCY

Arah dependency harus jelas.

Presentation  →  Domain  ←  Data

Artinya:

Presentation
→ boleh menggunakan Domain.

Data
→ mengimplementasikan kontrak Domain (repository, datasource).

Domain
→ tidak boleh bergantung kepada Presentation maupun Data.

Domain
→ tidak boleh mengetahui detail API,
  Flutter UI, Dio, database, atau widget.

PENGECUALIAN (composition root):

File providers (contoh: auth_providers.dart) BOLEH mengimpor Data
karena tugasnya merangkai dependency
(datasource → repository → use case).

Halaman, widget, dan controller TIDAK BOLEH mengimpor Data.

---

# 9. UI

UI hanya bertanggung jawab terhadap presentation.

UI BOLEH:
- Menampilkan data.
- Menerima input user.
- Memanggil controller/provider.
- Menampilkan loading.
- Menampilkan error.
- Menampilkan success state.

UI TIDAK BOLEH:
- Memanggil API secara langsung.
- Menulis SQL.
- Parsing response API.
- Menjalankan business logic kompleks.
- Mengakses database secara langsung.

CONTOH SALAH:

onPressed: () async {
  final response = await dio.post('/orders');
}

CONTOH BENAR:

onPressed: () {
  ref
      .read(loginControllerProvider.notifier)
      .login(...);
}

---

# 10. DATA SOURCE

DataSource bertugas berkomunikasi dengan sumber data.

Contoh sumber data:
- REST API
- GraphQL
- Firebase
- SQLite
- SharedPreferences
- Local storage
- Data dummy (auth_dummy_datasource.dart)

Kontrak datasource dibuat abstract (auth_datasource.dart),
implementasinya bisa diganti tanpa mengubah layer di atasnya.

DataSource:
- Mengambil data.
- Mengirim data.
- Menghapus data.
- Mengupdate data.

DataSource TIDAK bertanggung jawab terhadap:
- UI.
- Navigation.
- Business rules.
- Widget state.

PRINSIP:

DataSource = "Bagaimana cara mendapatkan data?"

---

# 11. REPOSITORY

Repository bertindak sebagai abstraction layer
antara application/domain dengan sumber data.

Pola:

domain/repositories/auth_repository.dart      → kontrak (abstract)
data/repositories/auth_repository_impl.dart   → implementasi

Repository bertanggung jawab:
- Menentukan sumber data yang digunakan.
- Menggabungkan remote/local data jika diperlukan.
- Mengubah data menjadi bentuk yang digunakan domain.
- Menyediakan data kepada UseCase.

Repository TIDAK bertanggung jawab terhadap:
- UI.
- Widget.
- Navigation.

Jangan membuat repository terpisah per role
(CustomerOrderRepository, OwnerOrderRepository)
jika domain datanya sama.

PRINSIP:

Repository = "Dari mana aplikasi mendapatkan data?"

Sedangkan:

DataSource = "Bagaimana cara mengambil data tersebut?"

---

# 12. USE CASE

UseCase bertanggung jawab terhadap satu aksi bisnis.

Penamaan file: <aksi>_usecase.dart
Contoh yang sudah ada: login_usecase.dart, register_usecase.dart

Contoh yang direncanakan:

PlaceOrder
GetOrderHistory
CancelOrder
GetProfile
UpdateProfile

Satu UseCase sebaiknya memiliki satu tujuan yang jelas.

Contoh:

PlaceOrder
→ hanya membuat pesanan.

GetOrderHistory
→ hanya mengambil riwayat pesanan.

Jangan membuat:

OrderManager
yang mengurus seluruh operasi pesanan sekaligus
jika operasi tersebut sudah cukup kompleks untuk dipisahkan.

---

# 13. CONTROLLER / STATE MANAGEMENT

State management yang dipakai: Riverpod.

Controller bertugas:
- Menerima aksi dari UI.
- Memanggil UseCase.
- Mengatur state.
- Menyampaikan hasil kepada UI.

Controller TIDAK BOLEH:
- Memanggil API secara langsung.
- Menulis SQL.
- Mengandung UI.
- Mengandung detail HTTP.

Lokasi:

features/<fitur>/presentation/controllers/   → controller
features/<fitur>/presentation/providers/     → provider dan wiring dependency

Alur:

UI
↓
Controller
↓
UseCase
↓
Repository
↓
DataSource

---

# 14. MODEL

Model digunakan untuk merepresentasikan data dari sumber tertentu.

Lokasi: features/<fitur>/data/models/

Contoh:

UserModel
LoginResponseModel

Model boleh mengetahui:
- JSON.
- API response.
- Database structure.

Domain Entity tidak boleh bergantung
kepada API-specific Model.

---

# 15. ENTITY

Entity adalah representasi data/domain
yang digunakan oleh business logic.

Lokasi: features/<fitur>/domain/entities/
Enum domain (contoh: UserRole): features/<fitur>/domain/enums/

Entity tidak boleh mengetahui:
- Dio.
- HTTP.
- JSON.
- Flutter Widget.
- Database implementation.

---

# 16. MAPPER

Jika diperlukan, gunakan Mapper untuk memisahkan
transformasi data.

Lokasi: features/<fitur>/data/mappers/

Contoh:

JSON
↓
UserModel
↓
UserMapper
↓
User Entity

Mapper bertugas:

"mengubah bentuk data A menjadi bentuk data B."

Mapper tidak boleh menjalankan business logic.

---

# 17. NAVIGATION

Navigation hanya boleh dilakukan oleh layer
yang memang bertanggung jawab terhadap navigation
(router, shell, dan widget presentation).

Business logic tidak boleh melakukan:

context.go(...)
Navigator.push(...)

jika navigation tersebut bukan tanggung jawabnya.

UseCase dan Repository tidak boleh mengetahui UI route.

Konstanta route dikumpulkan di routes.dart,
jangan menulis string path langsung di banyak tempat.

---

# 18. ERROR HANDLING

Error harus ditangani pada layer yang sesuai.

DataSource:
→ menangani error komunikasi/data source.

Repository:
→ menerjemahkan error data menjadi error
   yang dipahami domain jika diperlukan.

Controller:
→ mengubah error menjadi state yang dapat ditampilkan UI.

UI:
→ hanya menampilkan error (contoh: KcSnackbar).

---

# 19. JANGAN DUPLIKASI LOGIC

Jika logic yang sama digunakan beberapa tempat,
jangan copy-paste.

Cari lokasi tanggung jawab yang tepat
dan gunakan kembali logic tersebut.

Namun jangan membuat helper global hanya karena
ingin menghilangkan beberapa baris kode.

Reusable code harus benar-benar reusable.

---

# 20. PENAMAAN DAN IMPORT

ATURAN NAMA:

- File memakai snake_case.
- Nama file dan nama class harus UNIK di seluruh proyek.
- Halaman di folder role WAJIB diberi prefix role.
- Dilarang double ekstensi (kc_button.dart.dart).

CONTOH:

features/admin/presentation/pages/admin_dashboard_page.dart
→ class AdminDashboardPage

features/customer/presentation/pages/customer_orders_page.dart
→ class CustomerOrdersPage

features/owner/presentation/pages/owner_profile_page.dart
→ class OwnerProfilePage

Halaman yang memang unik (LoginPage, RegisterPage) tidak perlu prefix.

CONTOH SALAH:

DashboardPage di admin/ dan DashboardPage di owner/
→ import salah target dan error ambiguous import.

Saat menyalin halaman dari role lain, WAJIB mengganti
nama class dan teks placeholder.

ATURAN IMPORT:

- Gunakan import package:kantin_cerdas/... untuk file di dalam proyek.
- Hindari import relatif.
- Jangan mengimpor antar folder role.

---

# 21. ATURAN MEMBUAT FILE BARU

Sebelum membuat file baru, AI Agent WAJIB bertanya:

1. Apa tanggung jawab file ini?
2. Apakah tanggung jawab tersebut sudah dimiliki file lain?
3. Apakah file ini khusus feature atau bersifat global?
4. Apakah file ini berada pada layer yang benar?
5. Apakah dependency-nya mengikuti arah arsitektur?
6. Apakah nama file dan class-nya unik dan memakai prefix role
   jika berada di folder role?

Jangan membuat file baru hanya untuk memindahkan
kode tanpa alasan arsitektur yang jelas.

---

# 22. ATURAN SEBELUM MENGUBAH KODE

AI Agent WAJIB:
1. Memahami struktur project (baca README.md).
2. Mencari implementation yang sudah ada.
3. Menghindari membuat duplicate service/repository/helper.
4. Mengikuti architecture rules ini.
5. Memastikan perubahan tidak melanggar dependency direction.
6. Menjalankan flutter analyze setelah perubahan.

Jangan langsung membuat file baru sebelum memeriksa
apakah functionality tersebut sudah tersedia.

Gunakan features/auth/ sebagai referensi struktur
untuk fitur domain baru.

---

# 23. ATURAN UTAMA UNTUK AI AGENT

Jika AI Agent tidak yakin sebuah kode harus ditempatkan
di mana, JANGAN menaruhnya secara sembarangan.

Tentukan terlebih dahulu:

"Siapa yang bertanggung jawab terhadap pekerjaan ini?"

Kemudian tempatkan kode pada layer tersebut.

Gunakan prinsip:

DATA SOURCE
→ mengambil/mengirim data.

REPOSITORY
→ menyediakan data.

USE CASE
→ menjalankan business action.

CONTROLLER
→ mengatur state.

PRESENTATION
→ menampilkan.

SHELL
→ mengatur navigasi utama per role.

APP / ROUTER
→ mengatur aplikasi.

MAIN
→ menghidupkan aplikasi.

---

# 24. PRIORITAS ARSITEKTUR

Jika terdapat konflik antara:
- membuat kode lebih cepat,
- membuat file lebih sedikit,
- dan menjaga separation of concerns,

prioritaskan separation of concerns selama
kompleksitas yang ditambahkan masih masuk akal.

Jangan melakukan overengineering tanpa alasan.

Architecture harus membantu maintenance,
bukan membuat project menjadi rumit tanpa manfaat.
