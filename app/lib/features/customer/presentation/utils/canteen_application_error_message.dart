import 'package:kantin_cerdas/features/customer/domain/failures/canteen_application_failure.dart';

/// Mengubah error dari Controller/Provider menjadi teks untuk user.
String canteenApplicationErrorMessage(Object error) {
  return switch (error) {
    CanteenApplicationValidationFailure(:final fieldErrors) =>
      fieldErrors.values.firstOrNull ?? 'Data yang dimasukkan tidak valid.',
    CanteenApplicationUnauthorizedFailure() =>
      'Sesi Anda berakhir. Silakan login kembali.',
    CanteenApplicationNetworkFailure() =>
      'Tidak dapat terhubung ke server. Periksa koneksi Anda.',
    CanteenApplicationUnknownFailure() =>
      'Terjadi kesalahan pada server. Coba lagi nanti.',
    _ => 'Terjadi kesalahan. Silakan coba lagi.',
  };
}
