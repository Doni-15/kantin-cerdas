import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';
import 'package:kantin_cerdas/features/auth/domain/validators/auth_validator.dart';

/// Pesan umum untuk snackbar atau status kegagalan halaman.
String authErrorMessage(Object error) {
  return switch (error) {
    AuthInvalidCredentialsFailure() => 'Username/email atau password salah.',
    AuthAccountDisabledFailure() =>
      'Akun dinonaktifkan. Hubungi administrator.',
    AuthUsernameTakenFailure() => 'Username sudah digunakan.',
    AuthEmailTakenFailure() => 'Email sudah terdaftar.',
    AuthInvalidCurrentPasswordFailure() => 'Password saat ini salah.',
    AuthSessionExpiredFailure() => 'Sesi berakhir. Silakan masuk kembali.',
    AuthValidationFailure() => 'Periksa kembali data yang diisi.',
    AuthNetworkFailure() =>
      'Tidak dapat terhubung. Periksa koneksi lalu coba lagi.',
    AuthServerFailure() => 'Layanan sedang bermasalah. Coba lagi nanti.',
    AuthStorageFailure() =>
      'Terjadi kendala pada sesi di perangkat ini. Coba lagi.',
    AuthRateLimitedFailure() =>
      'Terlalu banyak percobaan. Tunggu beberapa saat lalu coba lagi.',
    AuthPasswordResetUnconfirmedFailure() =>
      'Status pengiriman email reset belum terkonfirmasi. Periksa kotak masuk sebelum mencoba lagi.',
    AuthOperationInProgressFailure() =>
      'Proses akun masih berjalan. Tunggu sebentar.',
    AuthOperationSupersededFailure() =>
      'Status sesi sudah berubah. Silakan ulangi dari halaman aktif.',
    AuthNotConfiguredFailure() =>
      'Layanan akun belum terhubung. Fitur ini belum tersedia.',
    AuthUnexpectedFailure() => 'Terjadi kesalahan. Silakan coba lagi.',
    _ => 'Terjadi kesalahan. Silakan coba lagi.',
  };
}

String? authFieldErrorMessage({required String field, required String? code}) {
  if (code == null) return null;

  final label = switch (field) {
    'identifier' => 'Username atau email',
    'name' => 'Nama',
    'username' => 'Username',
    'email' => 'Email',
    'password' => 'Password',
    'current_password' => 'Password saat ini',
    'new_password' => 'Password baru',
    'confirm_password' => 'Konfirmasi password',
    _ => 'Data',
  };

  final issue = _validationIssueFromCode(code);

  return switch (issue) {
    AuthValidationIssue.required => '$label wajib diisi.',
    AuthValidationIssue.tooLong => '$label melebihi batas panjang maksimum.',
    AuthValidationIssue.invalidEmail => 'Format email tidak valid.',
    AuthValidationIssue.invalidUsername =>
      'Username hanya boleh berisi huruf, angka, titik, dan underscore.',
    AuthValidationIssue.passwordTooShort =>
      '$label minimal ${AuthValidator.minPasswordLength} karakter.',
    AuthValidationIssue.passwordTooLong =>
      '$label maksimal ${AuthValidator.maxPasswordLength} karakter.',
    AuthValidationIssue.passwordUnchanged =>
      'Password baru harus berbeda dari password saat ini.',
    AuthValidationIssue.passwordMismatch => 'Konfirmasi password tidak sesuai.',
    AuthValidationIssue.invalidUsernameLength =>
      'Username harus ${AuthValidator.minUsernameLength}'
          '-${AuthValidator.maxUsernameLength} karakter.',
    null => code.trim().contains(' ') ? code.trim() : '$label tidak valid.',
  };
}

AuthValidationIssue? _validationIssueFromCode(String code) {
  for (final issue in AuthValidationIssue.values) {
    if (issue.name == code) {
      return issue;
    }
  }

  return null;
}
