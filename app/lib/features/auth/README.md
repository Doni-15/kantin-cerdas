# CATATAN ARSITEKTUR — AUTH / LOGIN

## 1. Prinsip Utama

KantinCerdas menggunakan prinsip:

> Satu layer = satu tanggung jawab.

Alur utama:

UI
↓
Controller
↓
UseCase
↓
Repository
↓
DataSource
↓
Dummy / API

Saat ini:

UI
↓
Controller
↓
UseCase
↓
Repository
↓
DummyDataSource

Nanti ketika Backend siap:

UI
↓
Controller
↓
UseCase
↓
Repository
↓
ApiDataSource
↓
ApiClient
↓
Backend

UI dan Business Logic tidak boleh bergantung langsung pada Backend.

---

# 2. Tanggung Jawab Setiap Layer

## UI / Presentation

Tanggung jawab:

- Menampilkan tampilan.
- Menerima input user.
- Menampilkan loading.
- Menampilkan error.
- Menampilkan hasil.
- Memanggil Controller.
- Menjalankan navigasi sesuai kebutuhan UI.

UI tidak boleh:

- Memanggil API langsung.
- Memanggil Dio langsung.
- Mengakses DataSource.
- Mengakses Repository secara langsung.
- Menjalankan business logic.
- Mengetahui endpoint Backend.
- Mengetahui struktur database.

Alur UI:

UI
↓
Controller

---

## Controller

Tanggung jawab:

- Mengelola state UI.
- Menerima action dari UI.
- Memanggil UseCase.
- Mengubah state menjadi loading, success, atau error.
- Menyediakan state yang dibutuhkan UI.

Controller tidak boleh:

- Memanggil HTTP secara langsung.
- Mengetahui endpoint API.
- Mengetahui detail JSON.
- Menjalankan query database.
- Menjadi tempat business logic utama.

Alur:

Controller
↓
UseCase

---

## UseCase

Tanggung jawab:

- Menjalankan satu business action.
- Menjadi tempat business rule.
- Menggunakan Repository untuk mendapatkan atau mengirim data.
- Menghasilkan data dalam bentuk Domain Entity.

Contoh:

LoginUseCase
TransferUseCase
GetProductsUseCase

UseCase tidak boleh:

- Mengetahui Dio.
- Mengetahui HTTP.
- Mengetahui endpoint.
- Mengetahui JSON API.
- Mengetahui database secara langsung.
- Mengurus UI.

Alur:

UseCase
↓
Repository

---

## Repository

Tanggung jawab:

- Menjadi bridge antara Domain dan Data Layer.
- Menggunakan DataSource.
- Mengubah Model menjadi Entity menggunakan Mapper.
- Menyediakan data dalam bentuk yang dipahami Domain.
- Menyembunyikan detail sumber data dari Domain.

Repository tidak boleh:

- Mengurus UI.
- Mengurus navigation.
- Menjadi HTTP Client.
- Mengetahui detail tampilan.
- Menjadi pengganti DataSource.

Alur:

Repository
↓
DataSource

---

## DataSource

Tanggung jawab:

- Berkomunikasi dengan sumber data.
- Mengambil data.
- Mengirim data.
- Menangani format komunikasi dengan sumber data.

Jenis DataSource dapat berupa:

- DummyDataSource
- ApiDataSource
- LocalDataSource
- DatabaseDataSource

Contoh Auth:

AuthDataSource
├── AuthDummyDataSource
└── AuthApiDataSource

DataSource boleh mengetahui:

- Endpoint API.
- Request API.
- Response API.
- JSON.
- Detail database jika menggunakan database.

DataSource tidak boleh:

- Mengurus UI.
- Mengurus navigation.
- Menjadi tempat business logic.
- Mengubah state UI.

---

## Model / DTO

Tanggung jawab:

- Merepresentasikan bentuk data dari sumber data.
- Mengikuti struktur API/database/external source.
- Melakukan parsing dari/ke JSON jika diperlukan.

Contoh:

UserModel
LoginResponseModel

Model tidak harus sama dengan Entity.

Model boleh menggunakan:

String role

karena API mungkin mengirim:

"role": "admin"

---

## Mapper

Tanggung jawab:

- Mengubah Model menjadi Entity.
- Mengubah Entity menjadi Model jika diperlukan.
- Menjadi boundary antara Data Layer dan Domain Layer.

Contoh:

UserModel
↓
UserMapper
↓
User

Mapper juga menjadi tempat normalisasi data dari API ke Domain.

Contoh:

"admin"
↓
UserRole.admin

---

## Entity

Tanggung jawab:

- Merepresentasikan konsep yang digunakan oleh Domain.
- Tidak bergantung pada API.
- Tidak bergantung pada database.
- Tidak bergantung pada Dio.
- Tidak bergantung pada JSON.

Contoh:

User

Entity tidak harus memiliki semua field dari database/API.

---

## Enum

Tanggung jawab:

- Merepresentasikan nilai yang memiliki pilihan terbatas dan sudah ditentukan.
- Menghindari magic string dan typo.
- Menjaga konsistensi di Domain dan Presentation.

Contoh:

enum UserRole {
  admin,
  cashier,
  customer,
}

Gunakan:

UserRole.admin

Bukan:

'admin'

Domain tidak boleh menyebarkan magic string untuk konsep yang sudah memiliki enum.

---

## ApiClient

Tanggung jawab:

- Infrastruktur HTTP umum.
- Base URL.
- Timeout.
- Headers.
- GET.
- POST.
- PUT.
- DELETE.
- Interceptor.
- Authorization header.
- HTTP-level error handling.

ApiClient tidak boleh memiliki logic feature.

Jangan membuat:

login()
getProducts()
transfer()
getProfile()

di ApiClient.

Endpoint feature tetap menjadi tanggung jawab DataSource.

---

## Router

Tanggung jawab:

- Navigation.
- Route configuration.
- Redirect berdasarkan authentication state jika diperlukan.

Router tidak boleh:

- Memanggil API login.
- Menjalankan business logic.
- Mengakses database.
- Menjadi Auth Controller.

---

# 3. Kondisi Sekarang — Dummy

Saat ini:

UI
↓
Controller
↓
UseCase
↓
Repository
↓
AuthDataSource
↓
AuthDummyDataSource
↓
Dummy Data

Tujuan DummyDataSource:

> Meniru perilaku Backend sehingga UI dan Business Logic dapat dikembangkan sebelum Backend tersedia.

DummyDataSource harus mengikuti kontrak yang sama dengan DataSource yang nantinya digunakan oleh API.

---

# 4. Saat Backend Sudah Siap

Jangan membuat ulang fitur Login.

Yang dilakukan adalah mengganti implementasi DataSource:

SEKARANG:

AuthDataSource
↓
AuthDummyDataSource

NANTI:

AuthDataSource
↓
AuthApiDataSource
↓
ApiClient
↓
Backend

---

# 5. Bagian yang Akan Diupdate Saat Backend Siap

## 5.1 AuthApiDataSource — TAMBAH

Buat:

auth_api_datasource.dart

Tugas:

- Memanggil endpoint login.
- Mengirim username/password.
- Menerima response Backend.
- Mengubah response JSON menjadi Model.

Contoh:

POST /auth/login

DataSource adalah tempat endpoint login berada.

---

## 5.2 AuthDataSource Provider — UPDATE

Sekarang:

AuthDummyDataSource

Nanti:

AuthApiDataSource

Layer di atasnya tetap menggunakan:

AuthDataSource

Tidak perlu mengubah:

Controller
UseCase
Repository

hanya karena sumber data berubah.

---

## 5.3 UserModel — MUNGKIN UPDATE

Saat Backend tersedia, UserModel harus disesuaikan dengan response API sebenarnya.

Jika API:

{
  "id": 1,
  "username": "admin",
  "role": "admin"
}

maka Model mengikuti struktur tersebut.

Jika Backend ternyata menggunakan:

{
  "user_id": 1,
  "user_name": "admin",
  "user_role": "ADMIN"
}

maka UserModel dan parsing-nya disesuaikan.

UI tidak perlu mengetahui perubahan tersebut.

---

## 5.4 LoginResponseModel — MUNGKIN UPDATE

Sesuaikan dengan response login Backend sebenarnya.

Contoh yang kita asumsikan:

{
  "access_token": "...",
  "refresh_token": "...",
  "user": {}
}

Jika Backend menggunakan struktur berbeda, Model disesuaikan.

---

## 5.5 UserMapper — MUNGKIN UPDATE

Mapper disesuaikan apabila format Backend berbeda.

Contoh:

Backend:

"role": "admin"

Mapper:

UserRole.admin

Domain tetap menggunakan:

UserRole.admin

meskipun format Backend berubah.

---

## 5.6 ApiClient — CONFIGURE / UPDATE

Ketika Backend tersedia, konfigurasi:

- Base URL.
- Timeout.
- Header.
- Interceptor.
- Authorization.
- Error handling.

Contoh:

https://api.kantincerdas.com

ApiClient tetap bersifat umum dan tidak mengetahui business feature.

---

## 5.7 Token / Session Storage — TAMBAH

Jika login menghasilkan:

- Access Token.
- Refresh Token.

Maka diperlukan mekanisme session/token storage.

Alur:

Login
↓
Backend
↓
Token
↓
Secure Storage
↓
ApiClient
↓
Authorization Header

Token tidak disimpan di UI.

Token tidak dikelola langsung oleh Widget.

---

## 5.8 Authentication State — TAMBAH

Aplikasi nantinya perlu mengetahui:

- Apakah user sudah login.
- User yang sedang login.
- Role user.
- Status session.
- Validitas authentication/session.

Authentication state harus terpisah dari UI.

---

## 5.9 Error Handling — UPDATE

Dummy mungkin hanya memiliki:

Username atau password salah.

Backend dapat menghasilkan:

- 400 Bad Request
- 401 Unauthorized
- 403 Forbidden
- 422 Validation Error
- 500 Server Error
- Timeout
- Network Error

Error dari Backend perlu dipetakan menjadi error aplikasi yang dapat dipahami oleh Controller/UI.

---

## 5.10 GoRouter — MUNGKIN UPDATE

Setelah Authentication State tersedia, Router dapat menggunakan auth state untuk redirect.

Contoh:

Belum login
↓
/login

Sudah login
↓
/home

Router hanya mengatur navigation.

---

# 6. Bagian yang Seharusnya TIDAK Berubah

Ketika Dummy diganti Backend, bagian berikut seharusnya tetap stabil:

UI
Controller
UseCase
Repository Contract
Entity
Enum

Target:

UI
↓
Controller
↓
UseCase
↓
Repository

tetap sama.

Perubahan terutama terjadi di:

DataSource
Model
Mapper
ApiClient
Session/Token
Error Handling

---

# 7. Prinsip Migrasi Backend

Backend siap ≠ Login dibuat ulang.

Backend siap = implementasi DataSource diganti dan Data Contract disesuaikan.

Target:

DummyDataSource
↓
diganti
↓
ApiDataSource

Bukan:

UI
↓
API langsung

dan bukan:

Controller
↓
Dio langsung

---

# 8. Rule Utama Project

1. UI tidak memanggil API.
2. Controller tidak memanggil HTTP.
3. UseCase tidak mengetahui HTTP.
4. Repository tidak menjadi HTTP Client.
5. DataSource tidak mengurus UI.
6. ApiClient tidak mengetahui feature.
7. Model mengikuti external data source.
8. Entity mengikuti kebutuhan Domain.
9. Mapper menjadi boundary Model ↔ Entity.
10. Enum digunakan untuk nilai domain yang terbatas.
11. Router hanya mengurus navigation.
12. DummyDataSource harus mengikuti kontrak DataSource.
13. Pergantian Dummy → API tidak boleh memaksa perubahan UI.
14. Business Logic tidak boleh diletakkan di UI.
15. Jangan membuat satu class yang mengurus terlalu banyak tanggung jawab.

---

# 9. Target Akhir

Arsitektur Login harus memungkinkan:

Dummy:

UI
↓
Controller
↓
UseCase
↓
Repository
↓
DummyDataSource

diganti menjadi:

Real Backend:

UI
↓
Controller
↓
UseCase
↓
Repository
↓
ApiDataSource
↓
ApiClient
↓
Backend

dengan perubahan seminimal mungkin pada layer di atas Data Layer.

> Tujuan arsitektur ini bukan membuat banyak file, tetapi membuat setiap bagian memiliki tanggung jawab yang jelas sehingga perubahan pada satu bagian tidak merusak bagian lainnya.