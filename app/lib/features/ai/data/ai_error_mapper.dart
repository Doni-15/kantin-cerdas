import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';

AuthException mapAiEnvelopeError(
  int statusCode,
  Map<String, dynamic> envelope,
) {
  final error = envelope['error'];
  final code = error is Map<String, dynamic> ? error['code'] : null;
  final mapped = switch ((statusCode, code)) {
    (403, 'CUSTOMER_ROLE_REQUIRED') => const AuthException(
      'CUSTOMER_ROLE_REQUIRED',
      'Fitur Food Assistant hanya tersedia untuk akun Customer.',
    ),
    (400, 'INVALID_INPUT') => const AuthException(
      'INVALID_INPUT',
      'Periksa kembali pesan atau batas anggaran yang Anda masukkan.',
    ),
    (503, 'AI_SERVICE_UNAVAILABLE') => const AuthException(
      'AI_SERVICE_UNAVAILABLE',
      'Layanan rekomendasi sedang sibuk. Coba beberapa saat lagi.',
    ),
    _ => null,
  };
  return mapped ?? mapAuthEnvelopeError(statusCode, envelope);
}
