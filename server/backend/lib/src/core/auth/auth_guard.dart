import 'package:kantin_cerdas_backend/src/core/auth/auth_failure.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:shelf/shelf.dart';

export 'package:kantin_cerdas_backend/src/core/auth/auth_failure.dart';

String requireBearer(Request request) {
  final header = request.headers['authorization'];
  if (header == null || header.length > 8199) throw AuthFailure.invalidSession;
  final match = RegExp(
    r'^Bearer ([A-Za-z0-9_.-]+)$',
    caseSensitive: false,
  ).firstMatch(header);
  if (match == null) throw AuthFailure.invalidSession;
  return match.group(1)!;
}

ApiException authFailureException(AuthFailure failure) {
  final (statusCode, code, message) = switch (failure) {
    AuthFailure.invalidCredentials => (
      401,
      'INVALID_CREDENTIALS',
      'Kredensial masuk tidak valid.',
    ),
    AuthFailure.invalidSession => (
      401,
      'INVALID_SESSION',
      'Sesi tidak valid atau telah berakhir.',
    ),
    AuthFailure.emailNotVerified => (
      403,
      'EMAIL_NOT_VERIFIED',
      'Verifikasi email untuk melanjutkan.',
    ),
    AuthFailure.inactiveAccount => (
      403,
      'ACCOUNT_INACTIVE',
      'Akun ini dinonaktifkan.',
    ),
    AuthFailure.profileIncomplete => (
      409,
      'PROFILE_INCOMPLETE',
      'Lengkapi foto profil untuk melanjutkan.',
    ),
    AuthFailure.providerManaged => (
      403,
      'PROVIDER_MANAGED',
      'Kelola kredensial akun ini melalui Google.',
    ),
    AuthFailure.googleDisabled => (
      503,
      'GOOGLE_DISABLED',
      'Login Google belum tersedia.',
    ),
    AuthFailure.signupEmailInvalid => (
      422,
      'SIGNUP_EMAIL_INVALID',
      'Alamat email ini tidak dapat digunakan untuk mendaftar.',
    ),
    AuthFailure.signupEmailDeliveryRestricted => (
      422,
      'SIGNUP_EMAIL_DELIVERY_RESTRICTED',
      'Tautan verifikasi tidak dapat dikirim ke alamat email ini.',
    ),
    AuthFailure.invalidInput => (
      400,
      'INVALID_INPUT',
      'Periksa kembali data pendaftaran.',
    ),
    AuthFailure.invalidCode => (
      400,
      'INVALID_CODE',
      'Kode salah atau telah kedaluwarsa.',
    ),
    AuthFailure.weakPassword => (
      422,
      'WEAK_PASSWORD',
      'Pilih kata sandi yang lebih kuat.',
    ),
    AuthFailure.samePassword => (
      422,
      'SAME_PASSWORD',
      'Gunakan password yang berbeda dari password saat ini.',
    ),
    AuthFailure.emailUnavailable => (
      409,
      'EMAIL_UNAVAILABLE',
      'Alamat email ini tidak dapat digunakan.',
    ),
    AuthFailure.rateLimited => (
      429,
      'AUTH_RATE_LIMITED',
      'Terlalu banyak percobaan. Coba lagi nanti.',
    ),
    AuthFailure.unavailable => (
      503,
      'AUTH_UNAVAILABLE',
      'Layanan autentikasi sedang tidak tersedia. Coba lagi.',
    ),
  };
  return ApiException(statusCode: statusCode, code: code, message: message);
}
