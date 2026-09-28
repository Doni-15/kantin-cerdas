# Aturan Riverpod — KantinCerdas

Dokumen ini melengkapi `app/aturan.md`. Jika ada konflik, `app/aturan.md` menjadi acuan untuk pembagian layer, dan dokumen ini untuk penggunaan Riverpod.

Paket: `flutter_riverpod` (versi pada `pubspec.yaml`). `main.dart` membungkus aplikasi dengan `ProviderScope`.

## 1. Aturan inti

1. Riverpod digunakan untuk **Dependency Injection** dan **State Management**.
2. Provider hanya menyediakan dependency atau state. Provider tidak menjalankan business logic.
3. Provider tidak melakukan HTTP request secara langsung, kecuali provider tersebut memang khusus merupakan abstraksi untuk resource async yang sesuai.
4. Komunikasi API menjadi tanggung jawab **DataSource**.
5. Business logic menjadi tanggung jawab **UseCase**.
6. State fitur menjadi tanggung jawab **Controller/Notifier**.
7. UI tidak membuat dependency secara manual (`AuthDummyDataSource()`, `Dio()`, dan sejenisnya tidak boleh muncul di widget).
8. Dependency antar layer disediakan melalui Riverpod.
9. Jangan membuat satu file provider global yang berisi seluruh provider aplikasi.
10. Provider ditempatkan dekat dengan dependency/fitur yang menjadi tanggung jawabnya.

## 2. Penempatan

```text
features/<fitur>/presentation/providers/     provider dependency dan state bersama
features/<fitur>/presentation/controllers/   Notifier / AsyncNotifier untuk aksi UI
```

Contoh yang sudah ada di `features/auth/`:

| File | Isi | Jenis provider |
| --- | --- | --- |
| `providers/auth_providers.dart` | `authDataSourceProvider`, `authRepositoryProvider`, `loginUseCaseProvider`, `registerUseCaseProvider` | `Provider` (dependency) |
| `providers/auth_state_provider.dart` | `authStateProvider` (`User?`) | `NotifierProvider` (state sinkron) |
| `controllers/login_controller.dart` | `loginControllerProvider` | `AsyncNotifierProvider` (aksi async) |
| `controllers/register_controller.dart` | `registerControllerProvider` | `AsyncNotifierProvider` |

Fitur domain baru mengikuti pola yang sama. Provider fitur A tidak dikumpulkan ke file fitur B.

## 3. Rantai dependency

```text
DataSource → Repository → UseCase → Controller → UI
```

Setiap mata rantai disediakan sebagai provider yang saling `ref.watch`. Mengganti implementasi (dummy → API) hanya mengubah isi provider DataSource:

```dart
final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  return AuthDummyDataSource(); // nanti: AuthApiDataSource(ref.watch(apiClientProvider))
});
```

**Pengecualian composition root:** file provider boleh mengimpor layer Data karena tugasnya merangkai dependency. Halaman, widget, dan controller tidak boleh mengimpor Data.

## 4. Penggunaan `ref`

| Situasi | Gunakan |
| --- | --- |
| Membaca state untuk dirender di `build` | `ref.watch(...)` |
| Memicu aksi dari event (tombol ditekan) | `ref.read(xxxProvider.notifier).aksi()` |
| Efek samping (snackbar, navigasi) terhadap perubahan state | `ref.listen(...)` di widget |
| Membaca provider lain di dalam `build()` Notifier | `ref.watch(...)` |
| Memakai dependency di dalam method aksi Notifier | `ref.read(...)` |

Jangan memakai `ref.read` di dalam `build` widget untuk data yang harus ikut berubah.

## 5. Siapa yang boleh mengubah state

- State hanya diubah oleh Notifier/Controller pemiliknya, bukan langsung oleh widget.
- Widget hanya memanggil method publik notifier.
- Navigasi dan snackbar tetap dilakukan di layer presentation (widget/`ref.listen`), bukan di UseCase atau Repository.

> **Utang saat ini:** `LoginForm` memanggil `authStateProvider.notifier.setUser(...)` setelah login sukses. Sebaiknya `LoginController` yang memperbarui `authStateProvider`, sehingga widget hanya mendengarkan hasil dan bernavigasi.

## 6. Penamaan

- Provider: `<nama>Provider` (`loginUseCaseProvider`).
- Notifier state: `<Nama>Notifier` (`AuthStateNotifier`).
- Controller aksi async: `<Nama>Controller` (`LoginController`).
- Satu file boleh memuat provider dan class notifier miliknya bila ukurannya kecil.

## 7. Pengujian

Ganti dependency lewat override pada `ProviderScope`, jangan memodifikasi kode produksi:

```dart
ProviderScope(
  overrides: [
    authDataSourceProvider.overrideWithValue(FakeAuthDataSource()),
  ],
  child: const KantinCerdasApp(),
)
```

Test controller dan UseCase tidak boleh bergantung pada widget.

## 8. Checklist review PR

- [ ] Tidak ada `Provider(...)`/`Dio()`/DataSource yang dibuat langsung di widget.
- [ ] Tidak ada business logic di dalam provider atau di dalam `build`.
- [ ] Provider berada di folder fitur pemiliknya, bukan file global.
- [ ] Widget hanya memanggil method notifier, tidak menulis `state` langsung.
- [ ] Efek samping memakai `ref.listen`, bukan di dalam `build`.
- [ ] `flutter analyze` bersih.
