# Arsitektur `lib/` — KantinCerdas

Dokumen ini menjadi aturan bersama untuk penempatan file di dalam `apps/mobile/lib/`.

Tujuannya sederhana: **kode mudah dicari, tidak duplikat, tidak menumpuk di `main.dart`, dan tetap rapi saat fitur bertambah.**

---

## 1. Prinsip utama

KantinCerdas memakai pendekatan **feature-first + shared core**.

Artinya:

- kode yang dipakai banyak fitur masuk ke `core/`;
- kode yang khusus satu fitur tinggal di dalam fitur tersebut;
- Mahasiswa dan Pengelola tetap berada dalam **satu aplikasi**;
- role menentukan navigasi dan hak akses, bukan membuat aplikasi terpisah;
- hindari folder global seperti `models/`, `providers/`, atau `repositories/` jika isinya sebenarnya hanya milik satu fitur.

---

## 2. Satu aplikasi, satu `main.dart`

KantinCerdas adalah satu aplikasi dengan dua role utama:

- **Mahasiswa**
- **Pengelola**

Karena itu, entry point utama tetap:

```text
lib/main.dart
```

`main.dart` hanya bertugas menyalakan aplikasi dan melakukan bootstrap minimum.

Jangan meletakkan:

- UI halaman;
- logika bisnis;
- pemanggilan repository;
- pengaturan role;
- perhitungan cart;
- navigasi detail;

langsung di `main.dart`.

Gambaran alur:

```text
main.dart
   │
   ▼
KantinCerdasApp
   │
   ▼
Session / Authentication
   │
   ├── belum login ──────► Login
   │
   └── sudah login
          │
          ▼
         role
       /      \
 student      manager
    │            │
    ▼            ▼
StudentShell   ManagerShell
```

---

## 3. Struktur direktori target

Struktur tidak harus dibuat seluruhnya sejak awal. Buat folder ketika memang dibutuhkan.

```text
lib/
├── main.dart
│
├── app/
│   ├── app.dart
│   ├── router/
│   └── session/
│
├── core/
│   ├── theme/
│   ├── widgets/
│   ├── services/
│   └── utils/
│
└── features/
    ├── auth/
    ├── catalog/
    ├── cart/
    ├── chat/
    ├── orders/
    ├── profile/
    └── stall_management/
```

---

## 4. Tanggung jawab setiap bagian

### `main.dart`

Hanya untuk:

- inisialisasi Flutter;
- inisialisasi dependency global jika diperlukan;
- menjalankan `KantinCerdasApp`.

Contoh tanggung jawab:

```text
main
 └── run application
```

---

### `app/`

Berisi kerangka aplikasi.

Contoh:

```text
app/
├── app.dart
├── router/
└── session/
```

Tanggung jawab:

- `MaterialApp`;
- router;
- session pengguna;
- pemilihan shell berdasarkan role;
- konfigurasi global aplikasi.

`app/` tidak boleh berisi logika bisnis seperti menghitung total cart atau mengubah status pesanan.

---

### `core/`

Berisi hal yang benar-benar dipakai lintas fitur.

Contoh:

```text
core/
├── theme/
├── widgets/
├── services/
└── utils/
```

#### `core/theme/`

Satu-satunya sumber aturan visual global KantinCerdas.

Contoh:

```text
theme/
├── kc_colors.dart
├── kc_typography.dart
├── kc_spacing.dart
├── kc_radius.dart
├── kc_sizes.dart
└── kc_theme.dart
```

Aturan:

- jangan menulis warna acak langsung di screen;
- jangan mengulang ukuran font yang seharusnya menjadi token;
- jangan membuat `StudentTheme` dan `ManagerTheme` kecuali desain memang berbeda;
- Mahasiswa dan Pengelola menggunakan design system KantinCerdas yang sama.

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

#### `core/widgets/`

Hanya untuk widget yang benar-benar generik dan dipakai lintas fitur.

Contoh yang cocok:

```text
kc_button.dart
kc_text_field.dart
kc_empty_view.dart
kc_loading_view.dart
```

Jangan masukkan widget yang hanya relevan untuk satu domain.

Contoh yang **tidak** cocok di `core/widgets/`:

```text
chat_bubble.dart
order_timeline.dart
cart_summary.dart
menu_card.dart
```

Widget tersebut harus tinggal bersama fiturnya.

---

#### `core/services/`

Untuk layanan lintas fitur, misalnya:

```text
services/
├── api/
├── auth/
└── storage/
```

Jangan menjadikan folder ini tempat semua logika aplikasi.

---

#### `core/utils/`

Untuk utility yang benar-benar umum.

Contoh:

```text
rupiah_formatter.dart
date_formatter.dart
```

Hindari file seperti:

```text
helper.dart
misc.dart
utils2.dart
```

Nama file harus menjelaskan tanggung jawabnya.

---

## 5. `features/` adalah pusat pengembangan

Semua kemampuan bisnis aplikasi dikelompokkan berdasarkan fitur.

Contoh:

```text
features/
├── catalog/
├── cart/
├── chat/
├── orders/
└── profile/
```

Ini lebih disukai daripada struktur global seperti:

```text
models/
providers/
repositories/
screens/
```

karena file satu fitur tidak tersebar ke banyak tempat.

---

## 6. Struktur internal sebuah fitur

Jika sebuah fitur mulai kompleks, gunakan pembagian:

```text
features/orders/
├── data/
├── domain/
└── presentation/
```

### `domain/`

Berisi konsep bisnis inti.

Contoh:

```text
order.dart
order_status.dart
```

### `data/`

Berisi akses dan implementasi data.

Contoh:

```text
order_repository.dart
fake_order_repository.dart
```

### `presentation/`

Berisi UI dan state presentation.

Contoh:

```text
presentation/
├── student/
├── manager/
└── widgets/
```

Tidak semua fitur wajib langsung memiliki `data/domain/presentation`.

Jika fiturnya masih kecil, struktur sederhana boleh digunakan terlebih dahulu.

---

## 7. Aturan dua role

Mahasiswa dan Pengelola adalah **role dalam satu aplikasi**, bukan dua aplikasi berbeda.

Yang boleh berbeda:

- shell;
- halaman;
- navigasi;
- action yang tersedia;
- permission.

Yang sebaiknya tetap dibagi bersama jika domainnya sama:

- model;
- repository;
- data source;
- formatter;
- design system.

Contoh:

```text
                    OrderRepository
                          │
                ┌─────────┴─────────┐
                ▼                   ▼
       StudentOrdersPage    ManagerOrdersPage
```

Jangan langsung membuat:

```text
StudentOrderRepository
ManagerOrderRepository
```

jika keduanya sebenarnya mengakses domain pesanan yang sama.

---

## 8. Shell per role

Role boleh memiliki shell UI yang berbeda.

Contoh:

```text
StudentShell
├── Beranda
├── Pesanan
├── Chat
└── Profil
```

```text
ManagerShell
├── Dashboard
├── Pesanan
├── Menu
└── Profil
```

Shell hanya mengatur navigasi utama role.

Shell tidak boleh menjadi tempat seluruh business logic.

---

## 9. Role bukan keamanan backend

Menyembunyikan tombol berdasarkan role hanya mengatur UI.

Contoh:

```text
Mahasiswa:
- melihat katalog;
- membuat pesanan;
- melihat pesanannya sendiri;
- menggunakan Chat.

Pengelola:
- melihat antrean;
- menerima pesanan;
- menolak pesanan;
- mengubah status;
- mengatur menu.
```

Ketika backend sudah tersedia, backend tetap harus memvalidasi permission.

Jangan menganggap tombol yang tidak tampil berarti operasi sudah aman.

---

## 10. Provider / state management

Jangan membuat satu folder global:

```text
providers/
```

untuk semua state aplikasi.

State sebaiknya tinggal dekat fitur yang menggunakannya.

Contoh:

```text
features/cart/presentation/cart_provider.dart
```

lebih baik daripada:

```text
providers/cart_provider.dart
```

Prinsip yang sama berlaku jika nanti memakai:

- Provider;
- Riverpod;
- Bloc/Cubit;
- ChangeNotifier;
- ValueNotifier.

Teknologi state management dapat berubah, tetapi aturan penempatan tetap sama: **dekatkan state dengan feature pemiliknya**.

---

## 11. Repository

Repository juga sebaiknya dekat dengan domain pemiliknya.

Contoh:

```text
features/orders/data/order_repository.dart
features/catalog/data/catalog_repository.dart
```

Hindari satu folder besar:

```text
repositories/
```

yang berisi repository seluruh aplikasi tanpa batas feature yang jelas.

---

## 12. Widget reusable

Sebelum membuat widget baru, tanyakan:

> Apakah widget ini digunakan oleh banyak fitur atau hanya satu fitur?

Jika lintas fitur:

```text
core/widgets/
```

Jika hanya milik satu fitur:

```text
features/<feature>/presentation/widgets/
```

Contoh:

```text
core/widgets/kc_button.dart
features/chat/presentation/widgets/chat_bubble.dart
features/orders/presentation/widgets/order_timeline.dart
```

---

## 13. Aturan theme

Theme adalah fondasi seluruh UI.

Semua screen wajib menggunakan token dari:

```text
core/theme/
```

Minimal meliputi:

```text
KcColors
KcTypography
KcSpacing
KcRadius
KcSizes
KcTheme
```

Jangan membuat nilai global baru hanya karena satu screen membutuhkannya.

Jika ukuran/warna hanya berlaku pada satu komponen, simpan di komponen tersebut terlebih dahulu.

Global token dibuat hanya jika benar-benar menjadi aturan design system.

---

## 14. Jangan membuat folder kosong berlebihan

Struktur target bukan berarti seluruh folder harus dibuat dari hari pertama.

Contoh:

Jika saat ini baru mengerjakan theme, cukup:

```text
lib/
├── main.dart
├── app/
└── core/
    └── theme/
```

Ketika mulai mengerjakan Chat, baru buat:

```text
features/chat/
```

Ketika mulai mengerjakan Cart, baru buat:

```text
features/cart/
```

Tujuannya agar struktur mengikuti kebutuhan nyata, bukan sekadar terlihat kompleks.

---

## 15. Penamaan file

Gunakan `snake_case`.

Benar:

```text
order_repository.dart
student_orders_screen.dart
kc_colors.dart
chat_bubble.dart
```

Hindari:

```text
OrderRepository.dart
studentOrdersScreen.dart
helper2.dart
final_widget.dart
```

Nama file harus menjelaskan fungsinya.

---

## 16. Sebelum menambahkan file baru

Tanyakan empat hal:

1. File ini milik fitur apa?
2. Apakah dipakai lintas fitur?
3. Apakah ini domain/data/presentation?
4. Apakah sebenarnya sudah ada komponen yang melakukan hal yang sama?

Jika jawabannya hanya untuk satu fitur, jangan masukkan ke `core/`.

---

## 17. Contoh penempatan

| Kebutuhan | Lokasi |
| --- | --- |
| Warna global | `core/theme/kc_colors.dart` |
| Theme aplikasi | `core/theme/kc_theme.dart` |
| Tombol umum | `core/widgets/kc_button.dart` |
| Model order | `features/orders/domain/order.dart` |
| Repository order | `features/orders/data/order_repository.dart` |
| Daftar pesanan mahasiswa | `features/orders/presentation/student/` |
| Antrean pengelola | `features/orders/presentation/manager/` |
| Bubble Chat | `features/chat/presentation/widgets/` |
| Cart state | `features/cart/presentation/` |
| Format rupiah | `core/utils/rupiah_formatter.dart` |
| Session pengguna | `app/session/` |
| Routing aplikasi | `app/router/` |

---

## 18. Ringkasan aturan tim

Gunakan aturan singkat berikut saat review PR:

> **Global masuk `core`, bisnis masuk `features`, aplikasi dirangkai di `app`, dan `main.dart` tetap kecil.**

> **Role memisahkan shell dan permission, bukan menduplikasi seluruh aplikasi.**

> **Satu feature menyimpan model, data, state, screen, dan widget spesifiknya sedekat mungkin.**

> **Jangan membuat abstraksi atau folder sebelum benar-benar dibutuhkan.**

> **Design system KantinCerdas adalah satu sumber visual untuk semua role.**

---

## 19. Prioritas implementasi saat ini

Tahap pengembangan sekarang dimulai dari:

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

Jangan melompat langsung membuat seluruh screen sebelum fondasi theme dan komponen bersama stabil.

---

Dokumen ini dapat diperbarui jika tim menyepakati perubahan arsitektur. Perubahan struktur besar sebaiknya dibahas sebelum merge agar seluruh anggota menggunakan pola yang sama.
