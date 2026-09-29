# Feature Customer

Aplikasi masih berjalan dengan data dummy, tetapi strukturnya disiapkan agar Backend
nyata cukup menggantikan satu bagian: **datasource**.

## Alur pengajuan buka kantin

```
CustomerCanteenApplicationPage        (tipis: memilih layar berdasarkan state)
  ├─ CanteenApplicationFormScreen     (form: state tampilan saja)
  │     └─ canteenApplicationSubmitProvider   (loading/error saat mengirim)
  │           └─ SubmitCanteenApplicationUseCase   (trim + validasi)
  ├─ CanteenApplicationStatusScreen   (menampilkan status)
  ├─ CanteenApplicationLoadingScreen / CanteenApplicationErrorScreen
  └─ state: canteenApplicationProvider (pengajuan MILIK USER YANG LOGIN)
        └─ CanteenApplicationRepository
              └─ CanteenApplicationDataSource  ← satu-satunya yang diganti API
```

## Struktur

```
domain/
  entities, enums                    CanteenApplication, CanteenApplicationStatus
  failures/                          CanteenApplicationFailure (sealed)
  validators/                        satu sumber aturan validasi
  repositories/                      kontrak
  usecases/                          SubmitCanteenApplicationUseCase
data/
  models/                            fromJson, status string <-> enum
  datasources/                       kontrak + dummy (bicara JSON, per user)
  repositories/                      ApiException -> CanteenApplicationFailure
presentation/
  providers/                         customer_providers (wiring), canteen_application_provider
  controllers/                       canteen_application_submit_controller
  utils/                             pesan error, teks/ikon status
  pages/, widgets/
```

## Aturan yang sengaja dijaga

- Page tidak memuat validasi, proses kirim, atau data dummy.
- State pengajuan mengikuti user login (`authStateProvider`): logout atau ganti akun
  me-reset state, jadi pengajuan satu user tidak terlihat user lain.
- Navigasi ke halaman pengajuan lewat route (`Routes.canteenApplication`), bukan
  `Navigator.push`.
- Teks status hanya ada di `canteen_application_status_presentation.dart`.

## Dummy

Pengajuan disimpan per user di memori (hilang saat aplikasi ditutup).
Skenario error: isi **nama kantin** dengan `offline`, `timeout`, atau `error500`.

## Saat Backend siap

1. Buat `CanteenApplicationApiDataSource` (4 method sesuai kontrak), lempar `ApiException`.
2. Ganti isi `canteenApplicationDataSourceProvider` di `customer_providers.dart`
   (parameter `currentUserId` hilang; Backend membaca user dari token).
3. Sesuaikan `CanteenApplicationModel` dengan JSON Backend dan pemetaan kode error
   di `CanteenApplicationRepositoryImpl._mapApiException`.
4. Pindahkan `updateStatus` (aksi review) ke feature admin.

## Belum dikerjakan

- `CustomerTab` masih berada di `customer_bottom_navigation.dart`; state tab ada di shell.
- Redirect GoRouter berdasarkan `authStateProvider` (lihat README auth bagian 10.7).

## Persistence (tahap dummy)

`CanteenApplicationDummyDataSource` menyimpan pengajuan per user ke `LocalStorage`
(key `customer.canteen_application.dummy_state`), sehingga pengajuan dan statusnya
tetap ada setelah aplikasi dibuka ulang. Saat Backend siap, persistence ini hilang
bersama dummy-nya.
