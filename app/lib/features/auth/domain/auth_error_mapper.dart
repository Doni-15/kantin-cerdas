import 'dart:convert';

import 'package:kantin_cerdas/core/error/app_failure.dart';

class AuthException implements AppFailure {
  const AuthException(this.code, this.message);
  @override
  final String code;
  @override
  final String message;
}

const authNotConfiguredException = AuthException(
  'NOT_CONFIGURED',
  'Alamat layanan Kantin Cerdas belum diatur.',
);
const authInvalidSessionException = AuthException(
  'INVALID_SESSION',
  'Sesi berakhir. Silakan masuk kembali.',
);
const authUnavailableException = AuthException(
  'AUTH_UNAVAILABLE',
  'Layanan sedang tidak tersedia. Coba lagi beberapa saat.',
);
const authTimedOutException = AuthException(
  'AUTH_TIMEOUT',
  'Layanan terlalu lama merespons. Coba lagi.',
);
const authConnectionFailedException = AuthException(
  'AUTH_CONNECTION_FAILED',
  'Tidak dapat terhubung ke layanan. Periksa koneksi lalu coba lagi.',
);
const authBadResponseException = AuthException(
  'INVALID_RESPONSE',
  'Respons layanan tidak dapat diproses. Coba lagi.',
);
const authRateLimitedException = AuthException(
  'RATE_LIMITED',
  'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.',
);
const authGoogleDisabledException = AuthException(
  'GOOGLE_DISABLED',
  'Login Google belum tersedia.',
);
const authGoogleClientDisabledException = AuthException(
  'GOOGLE_CLIENT_DISABLED',
  'Login Google dinonaktifkan pada konfigurasi aplikasi.',
);
const authGoogleConfigException = AuthException(
  'GOOGLE_CONFIG',
  'Alamat proyek Google belum dikonfigurasi dengan benar.',
);
const authGoogleConfigMismatchException = AuthException(
  'GOOGLE_CONFIG_MISMATCH',
  'Konfigurasi proyek Supabase pada aplikasi tidak sesuai dengan server.',
);

/// Maps HTTP status codes that take precedence before response payload or
/// binary photo handling.
///
/// Priority order matches `AuthApiTransport.request`:
/// 1. HTTP 503 on `google/exchange` or `google/config` with
///    `error.code == 'GOOGLE_DISABLED'`.
///    Throws [FormatException] when the 503 payload on `google/exchange` or
///    `google/config` is not a valid JSON object.
/// 2. HTTP 408 or 504 -> [authTimedOutException] (`AUTH_TIMEOUT`).
/// 3. HTTP >= 500 -> [authUnavailableException] (`AUTH_UNAVAILABLE`).
/// 4. HTTP 429 -> [authRateLimitedException] (`RATE_LIMITED`).
///
/// Returns `null` when status handling should continue to photo or JSON
/// envelope processing.
AuthException? mapAuthStatusError(
  int statusCode, {
  String endpoint = '',
  List<int> bodyBytes = const [],
}) {
  if (statusCode == 503 &&
      (endpoint.endsWith('google/exchange') ||
          endpoint.endsWith('google/config'))) {
    final decoded = jsonDecode(utf8.decode(bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected JSON object');
    }
    final error = decoded['error'];
    if (error is Map && error['code'] == 'GOOGLE_DISABLED') {
      return authGoogleDisabledException;
    }
  }
  if (statusCode == 408 || statusCode == 504) {
    return authTimedOutException;
  }
  if (statusCode >= 500) {
    return authUnavailableException;
  }
  if (statusCode == 429) {
    return authRateLimitedException;
  }
  return null;
}

/// Extracts `error.code` from a decoded JSON [envelope] and maps it with
/// [statusCode] to the canonical [AuthException].
///
/// Upstream backend messages (`envelope['error']['message']`) are never read
/// or exposed.
AuthException mapAuthEnvelopeError(
  int statusCode,
  Map<String, dynamic> envelope,
) {
  final error = envelope['error'];
  final code = error is Map<String, dynamic> ? error['code'] : null;
  return mapAuthErrorCode(statusCode, code);
}

/// Maps an HTTP [statusCode] and backend error [code] pair to the user-safe
/// [AuthException]. Unrecognized or mismatched pairs return
/// [authBadResponseException] (`INVALID_RESPONSE`).
AuthException mapAuthErrorCode(int statusCode, Object? code) =>
    switch ((statusCode, code)) {
      (401, 'INVALID_SESSION') => authInvalidSessionException,
      (401, 'INVALID_CREDENTIALS') => const AuthException(
        'INVALID_CREDENTIALS',
        'Email atau kata sandi tidak cocok.',
      ),
      (403, 'EMAIL_NOT_VERIFIED') => const AuthException(
        'EMAIL_NOT_VERIFIED',
        'Verifikasi email untuk melanjutkan.',
      ),
      (403, 'ACCOUNT_INACTIVE') => const AuthException(
        'ACCOUNT_INACTIVE',
        'Akun ini dinonaktifkan.',
      ),
      (403, 'PROVIDER_MANAGED') => const AuthException(
        'PROVIDER_MANAGED',
        'Kelola email dan password melalui Google.',
      ),
      (409, 'PROFILE_INCOMPLETE') => const AuthException(
        'PROFILE_INCOMPLETE',
        'Tambahkan foto profil untuk melanjutkan.',
      ),
      (400, 'INVALID_CODE') => const AuthException(
        'INVALID_CODE',
        'Kode salah atau sudah kedaluwarsa.',
      ),
      (422, 'WEAK_PASSWORD') => const AuthException(
        'WEAK_PASSWORD',
        'Pilih kata sandi yang lebih kuat.',
      ),
      (422, 'SAME_PASSWORD') => const AuthException(
        'SAME_PASSWORD',
        'Gunakan password yang berbeda dari password saat ini.',
      ),
      (409, 'EMAIL_UNAVAILABLE') => const AuthException(
        'EMAIL_UNAVAILABLE',
        'Alamat email ini tidak dapat digunakan.',
      ),
      (422, 'SIGNUP_EMAIL_INVALID') => const AuthException(
        'SIGNUP_EMAIL_INVALID',
        'Alamat email ini tidak dapat digunakan untuk mendaftar. Periksa '
            'penulisannya atau gunakan alamat email lain.',
      ),
      (422, 'SIGNUP_EMAIL_DELIVERY_RESTRICTED') => const AuthException(
        'SIGNUP_EMAIL_DELIVERY_RESTRICTED',
        'Tautan verifikasi tidak dapat dikirim ke alamat email ini. '
            'Gunakan alamat email lain.',
      ),
      (422, 'SIGNUP_EMAIL_REJECTED') => const AuthException(
        'SIGNUP_EMAIL_REJECTED',
        'Pendaftaran tidak dapat dilanjutkan dengan alamat email ini. '
            'Periksa penulisannya atau gunakan alamat email lain.',
      ),
      (422, 'INVALID_PROFILE_PHOTO') => const AuthException(
        'INVALID_PROFILE_PHOTO',
        'Pilih foto yang valid, maksimal 4096 × 4096 piksel.',
      ),
      (413, 'REQUEST_BODY_TOO_LARGE') => const AuthException(
        'PHOTO_TOO_LARGE',
        'Ukuran foto maksimal 2 MB.',
      ),
      (415, 'UNSUPPORTED_MEDIA_TYPE') => const AuthException(
        'UNSUPPORTED_MEDIA_TYPE',
        'Gunakan foto JPEG, PNG, atau WebP.',
      ),
      (400, 'INVALID_INPUT') => const AuthException(
        'INVALID_INPUT',
        'Periksa kembali data yang kamu masukkan.',
      ),
      (404, 'STALL_NOT_FOUND') => const AuthException(
        'STALL_NOT_FOUND',
        'Stan ini sudah tidak tersedia.',
      ),
      (400, 'INVALID_CATALOG_QUERY') => const AuthException(
        'INVALID_CATALOG_QUERY',
        'Periksa kembali kata kunci pencarian.',
      ),
      _ => authBadResponseException,
    };
