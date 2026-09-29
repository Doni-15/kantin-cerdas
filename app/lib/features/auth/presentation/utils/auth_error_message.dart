import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';

/// Mengubah error dari Controller menjadi teks untuk user.
String authErrorMessage(Object error) {
  return switch (error) {
    InvalidCredentialsFailure() => 'Username/email atau password salah.',
    AccountDisabledFailure() => 'Akun Anda dinonaktifkan. Hubungi admin.',
    UsernameTakenFailure() => 'Username sudah digunakan.',
    EmailTakenFailure() => 'Email sudah terdaftar.',
    InvalidCurrentPasswordFailure() => 'Password saat ini salah.',
    SessionExpiredFailure() => 'Sesi berakhir. Silakan masuk kembali.',
    NetworkFailure() =>
      'Tidak dapat terhubung ke server. Periksa koneksi Anda.',
    ValidationFailure(:final fieldErrors) =>
      fieldErrors.values.firstOrNull ?? 'Data yang dimasukkan tidak valid.',
    UnknownFailure() => 'Terjadi kesalahan pada server. Coba lagi nanti.',
    _ => 'Terjadi kesalahan. Silakan coba lagi.',
  };
}
