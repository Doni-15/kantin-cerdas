# Arsitektur `lib/` — KantinCerdas

Dokumen ini menjadi aturan bersama untuk penempatan file di dalam `lib/`.

Tujuannya sederhana: **kode mudah dicari, tidak duplikat, tidak menumpuk di `main.dart`, dan tetap rapi saat fitur bertambah.**

> Dokumen ini berisi **aturan** dan **status struktur saat ini**. Bagian 3 menunjukkan struktur yang sudah ada, dan bagian 20 mencatat bagian yang belum sesuai aturan (utang teknis).

---

## 1. Prinsip utama

KantinCerdas memakai pendekatan **feature-first + shared core**.

Artinya:

- kode yang dipakai banyak fitur masuk ke `core/`;
- kode yang khusus satu fitur tinggal di dalam fitur tersebut;
- semua role berada dalam **satu aplikasi**;
- role menentukan navigasi dan hak akses, bukan membuat aplikasi terpisah;
- nama folder role mengikuti enum `UserRole`: `admin`, `customer`, `owner`;
- hindari folder global seperti `models/`, `providers/`, atau `repositories/` jika isinya sebenarnya hanya milik satu fitur.

---

## 2. Satu aplikasi, satu `main.dart`

KantinCerdas adalah satu aplikasi dengan tiga role:

| Role (`UserRole`) | Peran |
| --- | --- |
| `customer` | Mahasiswa / pembeli |
| `owner` | Pengelola kantin |
| `admin` | Administrator |

Entry point tetap:

```text
lib/main.dart
```

`main.dart` hanya menyalakan aplikasi dan melakukan bootstrap minimum (termasuk `ProviderScope` untuk Riverpod).

Jangan meletakkan di `main.dart`:

- UI halaman;
- logika bisnis;
- pemanggilan repository;
- pengaturan role;
- perhitungan cart;
- navigasi detail.

Alur aplikasi:

```text
main.dart
   │
   ▼
KantinCerdasApp
   │
   ▼
Router (app_router)
   │
   ▼
AppEntryPage ── membaca auth state
   │
   ├── belum login ──────► LoginPage / RegisterPage
   │
   └── sudah login
          │
          ▼
        UserRole
      /    │    \
 customer owner  admin
    │      │       │
    ▼      ▼       ▼
CustomerShell OwnerShell AdminShell
```

---

## 3. Struktur direktori

### Struktur saat ini

```text
lib/
├── main.dart
├── kantin_cerdas_app.dart
│
├── theme/
│   ├── kc_colors.dart
│   ├── kc_radius.dart
│   ├── kc_sizes.dart
│   ├── kc_spacing.dart
│   ├── kc_typography.dart
│   ├── kc_theme.dart
│   └── kc_theme_exports.dart
│
├── core/
│   ├── router/
│   │   ├── app_router.dart
│   │   ├── app_entry_page.dart
│   │   └── routes.dart
│   └── widgets/
│       ├── kc_brand.dart
│       ├── kc_button.dart
│       ├── kc_logo.dart
│       ├── kc_nav_item.dart
│       ├── kc_snackbar.dart
│       └── kc_text_field.dart
│
└── features/
    ├── auth/
    │   ├── data/          (datasources, mappers, models, repositories)
    │   ├── domain/        (entities, enums, repositories, usecases)
    │   └── presentation/  (controllers, pages, providers, widgets)
    ├── admin/
    │   └── presentation/  (pages, widgets)
    ├── customer/
    │   └── presentation/  (pages, widgets)
    ├── owner/
    │   └── presentation/  (pages, widgets)
    └── shell/
        ├── admin_shell.dart
        ├── customer_shell.dart
        └── owner_shell.dart
```

### Struktur target

Struktur tidak harus dibuat seluruhnya sejak awal. Buat folder ketika memang dibutuhkan.

```text
lib/
├── main.dart
│
├── app/
│   ├── kantin_cerdas_app.dart
│   └── router/
│
├── theme/
│
├── core/
│   ├── widgets/
│   ├── services/
│   └── utils/
│
└── features/
    ├── auth/
    ├── admin/
    ├── customer/
    ├── owner/
    ├── shell/
    └── (fitur domain baru: catalog, cart, orders, chat, ...)
```

Perbedaan antara struktur saat ini dan target dicatat di bagian 20.

---

## 4. Tanggung jawab setiap bagian

### `main.dart`

Hanya untuk:

- inisialisasi Flutter;
- inisialisasi dependency global jika diperlukan;
- membungkus dengan `ProviderScope` dan menjalankan `KantinCerdasApp`.

---

### `kantin_cerdas_app.dart` dan router

Root widget dan router adalah kerangka aplikasi.

Tanggung jawab:

- `MaterialApp.router`;
- konfigurasi router (`app_router.dart`, `routes.dart`);
- `AppEntryPage`: memilih shell berdasarkan auth state dan role;
- pemasangan theme global.

Tidak boleh berisi logika bisnis seperti menghitung total cart atau mengubah status pesanan.

Router dan root widget **boleh** mengimpor fitur, karena tugasnya merangkai fitur. Karena itu targetnya berada di `app/`, bukan di `core/` (lihat bagian 20).

---

### `theme/`

Satu-satunya sumber aturan visual global KantinCerdas.

```text
theme/
├── kc_colors.dart
├── kc_typography.dart
├── kc_spacing.dart
├── kc_radius.dart
├── kc_sizes.dart
├── kc_theme.dart
└── kc_theme_exports.dart   (barrel file, meng-export semua token)
```

Aturan:

- jangan menulis warna acak langsung di screen;
- jangan mengulang ukuran font yang seharusnya menjadi token;
- jangan membuat theme per role kecuali desain memang berbeda;
- semua role memakai design system KantinCerdas yang sama.

Contoh yang benar:

```dart
color: KcColors.action
```

Hindari:

```dart
color: const Color(0xFFC74418)
```

di banyak screen secara berulang.

---

### `core/widgets/`

Hanya untuk widget generik yang dipakai lintas fitur.

Yang sudah ada:

```text
kc_brand.dart
kc_button.dart
kc_logo.dart
kc_nav_item.dart
kc_snackbar.dart
kc_text_field.dart
```

Jangan masukkan widget yang hanya relevan untuk satu domain.

Contoh yang **tidak** cocok di `core/widgets/`:

```text
chat_bubble.dart
order_timeline.dart
cart_summary.dart
menu_card.dart
```

Widget tersebut tinggal bersama fiturnya.

---

### `core/services/`

Untuk layanan lintas fitur, misalnya `api/`, `storage/`. Belum ada, buat saat dibutuhkan. Jangan menjadikannya tempat semua logika aplikasi.

---

### `core/utils/`

Untuk utility yang benar-benar umum, misalnya:

```text
rupiah_formatter.dart
date_formatter.dart
```

Hindari `helper.dart`, `misc.dart`, `utils2.dart`. Nama file harus menjelaskan tanggung jawabnya.

---

### `features/shell/`

Berisi shell per role: `customer_shell.dart`, `owner_shell.dart`, `admin_shell.dart`.

Shell mengatur navigasi utama role (bottom navigation dan tab). Shell boleh mengimpor halaman dari folder role-nya sendiri, tetapi tidak boleh menjadi tempat business logic.

---

## 5. `features/` adalah pusat pengembangan

Semua kemampuan aplikasi dikelompokkan berdasarkan fitur.

Saat ini ada dua jenis folder di `features/`:

1. **Fitur domain** yang membawa logika dan data, contohnya `auth/`. Nanti: `catalog/`, `cart/`, `orders/`, `chat/`.
2. **Fitur role** yang berisi halaman dan navigasi khusus role: `admin/`, `customer/`, `owner/`.

Aturan pemisahannya:

- halaman dan widget yang hanya dipakai satu role tinggal di folder role;
- model, repository, dan use case tinggal di fitur domain, dan **dipakai bersama** oleh halaman role;
- jangan membuat `CustomerOrderRepository` dan `OwnerOrderRepository` jika keduanya mengakses domain pesanan yang sama.

Contoh saat `orders` sudah punya logika:

```text
features/orders/
├── domain/
├── data/
└── presentation/providers/

features/customer/presentation/pages/customer_orders_page.dart   → memakai provider dari orders
features/owner/presentation/pages/owner_orders_page.dart         → memakai provider dari orders
```

Hindari struktur global seperti `models/`, `providers/`, `repositories/`, `screens/` karena file satu fitur jadi tersebar.

---

## 6. Struktur internal sebuah fitur

Jika fitur mulai kompleks, gunakan pembagian:

```text
features/<fitur>/
├── data/
├── domain/
└── presentation/
```

**`features/auth/` adalah fitur referensi.** Susunannya:

```text
features/auth/
├── data/
│   ├── datasources/     auth_datasource.dart (kontrak), auth_dummy_datasource.dart
│   ├── mappers/         user_mapper.dart
│   ├── models/          user_model.dart, login_response_model.dart
│   └── repositories/    auth_repository_impl.dart
├── domain/
│   ├── entities/        user.dart
│   ├── enums/           user_role.dart
│   ├── repositories/    auth_repository.dart (kontrak)
│   └── usecases/        login_usecase.dart, register_usecase.dart
└── presentation/
    ├── controllers/     login_controller.dart, register_controller.dart
    ├── providers/       auth_providers.dart, auth_state_provider.dart
    ├── pages/           login_page.dart, register_page.dart
    └── widgets/         login_form.dart, register_form.dart
```

Tidak semua fitur wajib langsung memiliki `data/domain/presentation`. Fitur role (`admin`, `customer`, `owner`) saat ini hanya memiliki `presentation/` karena masih berisi halaman.

---

## 7. Aturan role

Customer, owner, dan admin adalah **role dalam satu aplikasi**, bukan tiga aplikasi.

Yang boleh berbeda:

- shell;
- halaman;
- navigasi;
- action yang tersedia;
- permission.

Yang sebaiknya dibagi bersama jika domainnya sama:

- model dan entity;
- repository;
- data source;
- formatter;
- design system.

Aturan antar-folder role:

- `admin/`, `customer/`, dan `owner/` **tidak boleh saling mengimpor**;
- semuanya boleh mengimpor `core/`, `theme/`, dan `auth/` (untuk `User` dan `UserRole`);
- hanya `shell/` dan router yang boleh mengimpor halaman dari beberapa fitur.

---

## 8. Shell per role

```text
CustomerShell
├── Beranda
├── Pesanan
├── Riwayat
├── AI Chat
└── Profil
```

```text
OwnerShell
├── Dashboard
├── Pesanan
├── Kantin
└── Profil
```

```text
AdminShell
├── Dashboard
├── Users
└── Profil
```

Shell hanya mengatur navigasi utama role. Shell tidak boleh menjadi tempat seluruh business logic.

---

## 9. Role bukan keamanan backend

Menyembunyikan tombol berdasarkan role hanya mengatur UI.

```text
Customer:
- melihat katalog;
- membuat pesanan;
- melihat pesanannya sendiri;
- menggunakan AI Chat.

Owner:
- melihat antrean;
- menerima atau menolak pesanan;
- mengubah status;
- mengatur kantin dan menu.

Admin:
- mengelola user;
- melihat dashboard sistem.
```

Ketika backend sudah tersedia, backend tetap harus memvalidasi permission. Jangan menganggap tombol yang tidak tampil berarti operasi sudah aman.

---

## 10. Provider / state management

Proyek memakai **Riverpod** (`flutter_riverpod`).

Jangan membuat satu folder global `providers/` untuk semua state. State tinggal dekat fitur pemiliknya:

```text
features/auth/presentation/providers/auth_providers.dart        → wiring dependency
features/auth/presentation/providers/auth_state_provider.dart   → state sesi
features/auth/presentation/controllers/login_controller.dart    → aksi dari UI
```

Pembagian tugas:

- **controller**: menerima aksi UI, memanggil use case, mengatur state;
- **providers**: merangkai dependency (datasource → repository → use case);
- file `*_providers.dart` **boleh** mengimpor layer `data/` karena di situlah dependency dirangkai. Halaman, widget, dan controller tidak boleh.

Teknologi state management dapat berubah, tetapi aturan penempatan tetap: **dekatkan state dengan feature pemiliknya**.

---

## 11. Repository

Repository dekat dengan domain pemiliknya, dengan pola kontrak dan implementasi:

```text
features/auth/domain/repositories/auth_repository.dart        → kontrak (abstract)
features/auth/data/repositories/auth_repository_impl.dart     → implementasi
features/auth/data/datasources/auth_datasource.dart           → kontrak sumber data
features/auth/data/datasources/auth_dummy_datasource.dart     → implementasi sementara
```

Hindari satu folder besar `repositories/` untuk seluruh aplikasi.

---

## 12. Widget reusable

Sebelum membuat widget baru, tanyakan:

> Apakah widget ini digunakan oleh banyak fitur atau hanya satu fitur?

Lintas fitur:

```text
core/widgets/
```

Milik satu fitur:

```text
features/<fitur>/presentation/widgets/
```

Contoh:

```text
core/widgets/kc_button.dart
features/auth/presentation/widgets/login_form.dart
features/customer/presentation/widgets/customer_bottom_navigation.dart
```

`kc_nav_item.dart` ada di `core/widgets/` karena dipakai oleh bottom navigation ketiga role.

---

## 13. Aturan theme

Semua screen wajib memakai token dari `theme/`:

```text
KcColors
KcTypography
KcSpacing
KcRadius
KcSizes
KcTheme
```

Jangan membuat nilai global baru hanya karena satu screen membutuhkannya. Jika ukuran atau warna hanya berlaku pada satu komponen, simpan di komponen tersebut terlebih dahulu. Global token dibuat hanya jika benar-benar menjadi aturan design system.

---

## 14. Jangan membuat folder kosong berlebihan

Buat folder ketika mulai dikerjakan, bukan dari hari pertama.

Contoh: `features/orders/` baru dibuat ketika pesanan mulai punya model dan repository, bukan saat halaman placeholder dibuat.

---

## 15. Penamaan

Gunakan `snake_case` untuk file.

Benar:

```text
order_repository.dart
customer_orders_page.dart
kc_colors.dart
```

Hindari:

```text
OrderRepository.dart
customerOrdersPage.dart
kc_button.dart.dart      (double ekstensi)
helper2.dart
```

### Aturan nama halaman dan class

Nama file dan nama class harus **unik di seluruh proyek**. Untuk halaman di folder role, beri **prefix role**:

| Folder | File | Class |
| --- | --- | --- |
| `features/admin/` | `admin_dashboard_page.dart` | `AdminDashboardPage` |
| `features/customer/` | `customer_orders_page.dart` | `CustomerOrdersPage` |
| `features/owner/` | `owner_profile_page.dart` | `OwnerProfilePage` |

Alasannya: `DashboardPage`, `ProfilePage`, dan `OrdersPage` sebelumnya ada di beberapa folder sehingga import salah target dan Dart menampilkan error *ambiguous import*.

Halaman yang memang unik (`LoginPage`, `RegisterPage`) tidak perlu prefix.

Ketika membuat halaman baru untuk sebuah role, salin dari template yang benar dan **ganti nama class serta teks placeholder**. Dua halaman admin pernah tertinggal bernama `OwnerProfilePage` dan `OwnerOrdersPage` karena copy-paste.

---

## 16. Aturan import

- Pakai import `package:kantin_cerdas/...` untuk semua file di dalam proyek.
- Hindari import relatif (`import 'kc_logo.dart';`) supaya gaya seragam dan mudah dicari.
- Impor file spesifik, bukan folder induk fitur lain.
- Pakai `theme/kc_theme_exports.dart` jika satu file membutuhkan banyak token theme.

---

## 17. Sebelum menambahkan file baru

Tanyakan empat hal:

1. File ini milik fitur apa?
2. Apakah dipakai lintas fitur?
3. Apakah ini domain, data, atau presentation?
4. Apakah sebenarnya sudah ada komponen yang melakukan hal yang sama?

Jika jawabannya hanya untuk satu fitur, jangan masukkan ke `core/`.

---

## 18. Contoh penempatan

| Kebutuhan | Lokasi |
| --- | --- |
| Warna global | `theme/kc_colors.dart` |
| Theme aplikasi | `theme/kc_theme.dart` |
| Tombol umum | `core/widgets/kc_button.dart` |
| Konstanta route | `core/router/routes.dart` (target: `app/router/`) |
| Entity user dan role | `features/auth/domain/entities/`, `features/auth/domain/enums/` |
| Repository auth | `features/auth/domain/repositories/`, `features/auth/data/repositories/` |
| Login controller | `features/auth/presentation/controllers/login_controller.dart` |
| Auth state | `features/auth/presentation/providers/auth_state_provider.dart` |
| Model order | `features/orders/domain/entities/order.dart` |
| Repository order | `features/orders/data/repositories/order_repository_impl.dart` |
| Daftar pesanan customer | `features/customer/presentation/pages/customer_orders_page.dart` |
| Antrean pesanan owner | `features/owner/presentation/pages/owner_orders_page.dart` |
| Halaman kelola user | `features/admin/presentation/pages/admin_users_page.dart` |
| Bottom navigation role | `features/<role>/presentation/widgets/<role>_bottom_navigation.dart` |
| Shell role | `features/shell/<role>_shell.dart` |
| Bubble AI Chat | `features/customer/presentation/widgets/` atau `features/chat/presentation/widgets/` |
| Format rupiah | `core/utils/rupiah_formatter.dart` |

---

## 19. Ringkasan aturan tim

Gunakan aturan singkat berikut saat review PR:

> **Global masuk `core` dan `theme`, bisnis masuk `features`, aplikasi dirangkai di `app`, dan `main.dart` tetap kecil.**

> **Role memisahkan shell dan permission, bukan menduplikasi domain.**

> **Nama file dan class halaman harus unik. Halaman role diberi prefix role.**

> **Satu feature menyimpan model, data, state, screen, dan widget spesifiknya sedekat mungkin.**

> **Jangan membuat abstraksi atau folder sebelum benar-benar dibutuhkan.**

> **Design system KantinCerdas adalah satu sumber visual untuk semua role.**

Prioritas implementasi:

```text
Theme
  ↓
Shared component
  ↓
App shell
  ↓
Role & navigation
  ↓
Feature screens
  ↓
State/data
  ↓
Backend integration
```

Tahap saat ini: theme, shared component, shell, dan auth (dengan datasource dummy) sudah ada. Halaman role masih placeholder, dan state/data fitur domain belum dimulai.

---

## 20. Status saat ini dan utang teknis

| # | Kondisi sekarang | Target | Alasan |
| --- | --- | --- | --- |
| 1 | `core/router/` mengimpor `features/auth`, `features/shell`, `features/customer` | Pindah ke `app/router/` | `core/` tidak boleh bergantung pada fitur |
| 2 | `kantin_cerdas_app.dart` di root `lib/` | `app/kantin_cerdas_app.dart` | Dikumpulkan bersama router di `app/` |
| 3 | `kc_brand.dart` dan `kc_theme.dart` memakai import relatif | Import `package:` | Gaya import seragam |
| 4 | `kc_theme_exports.dart` belum diimpor file mana pun | Pakai di file yang butuh banyak token, atau hapus | Hindari file mati |
| 5 | Halaman role duplikat konsepnya (`*_orders_page`, `*_profile_page`, `*_dashboard_page`) | Logika bersama masuk fitur domain, halaman tetap per role | Menghindari duplikasi saat data mulai masuk |
| 6 | Teks UI hardcode dengan bahasa campur (Indonesia dan Inggris) | Pindah ke l10n, satu bahasa | Konsistensi, belum mendesak |
| 7 | Halaman admin dan owner masih placeholder | Isi sesuai fitur | Tahap "Feature screens" |

---

## 21. Pengecekan sebelum PR

Jalankan dari root proyek. Semua bagian harus kosong kecuali `flutter analyze` yang harus `No issues found!`.

```bash
flutter analyze

echo "== file kembar ==";  find lib -name "*.dart" -printf "%f\n" | sort | uniq -d
echo "== class kembar =="; grep -rhoE "^(abstract |final |sealed )?class [A-Za-z0-9_]+" lib | awk '{print $NF}' | sort | uniq -d
echo "== double ekstensi =="; find lib -name "*.dart.dart"

echo "== import ke file hilang =="
grep -rhoE "package:kantin_cerdas/[^']+" lib test 2>/dev/null | sort -u \
  | sed 's#package:kantin_cerdas/#lib/#' \
  | while read -r f; do [ -f "$f" ] || echo "HILANG: $f"; done

echo "== role saling import =="
grep -rnE "features/(owner|customer)/" lib/features/admin
grep -rnE "features/(admin|customer)/" lib/features/owner
grep -rnE "features/(admin|owner)/"    lib/features/customer

echo "== core bergantung pada features (utang teknis #1) =="
grep -rn "features/" lib/core
```

---

Dokumen ini dapat diperbarui jika tim menyepakati perubahan arsitektur. Perubahan struktur besar sebaiknya dibahas sebelum merge agar seluruh anggota menggunakan pola yang sama.
