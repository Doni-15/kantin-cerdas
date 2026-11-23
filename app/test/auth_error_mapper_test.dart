import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/data/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/auth/data/auth_repository.dart';

const _supportedEnvelopeCases =
    <({int status, String backendCode, String expectedCode, String message})>[
      (
        status: 401,
        backendCode: 'INVALID_SESSION',
        expectedCode: 'INVALID_SESSION',
        message: 'Sesi berakhir. Silakan masuk kembali.',
      ),
      (
        status: 401,
        backendCode: 'INVALID_CREDENTIALS',
        expectedCode: 'INVALID_CREDENTIALS',
        message: 'Email atau kata sandi tidak cocok.',
      ),
      (
        status: 403,
        backendCode: 'EMAIL_NOT_VERIFIED',
        expectedCode: 'EMAIL_NOT_VERIFIED',
        message: 'Verifikasi email untuk melanjutkan.',
      ),
      (
        status: 403,
        backendCode: 'ACCOUNT_INACTIVE',
        expectedCode: 'ACCOUNT_INACTIVE',
        message: 'Akun ini dinonaktifkan.',
      ),
      (
        status: 403,
        backendCode: 'PROVIDER_MANAGED',
        expectedCode: 'PROVIDER_MANAGED',
        message: 'Kelola email dan password melalui Google.',
      ),
      (
        status: 409,
        backendCode: 'PROFILE_INCOMPLETE',
        expectedCode: 'PROFILE_INCOMPLETE',
        message: 'Tambahkan foto profil untuk melanjutkan.',
      ),
      (
        status: 400,
        backendCode: 'INVALID_CODE',
        expectedCode: 'INVALID_CODE',
        message: 'Kode salah atau sudah kedaluwarsa.',
      ),
      (
        status: 422,
        backendCode: 'WEAK_PASSWORD',
        expectedCode: 'WEAK_PASSWORD',
        message: 'Pilih kata sandi yang lebih kuat.',
      ),
      (
        status: 422,
        backendCode: 'SAME_PASSWORD',
        expectedCode: 'SAME_PASSWORD',
        message: 'Gunakan password yang berbeda dari password saat ini.',
      ),
      (
        status: 409,
        backendCode: 'EMAIL_UNAVAILABLE',
        expectedCode: 'EMAIL_UNAVAILABLE',
        message: 'Alamat email ini tidak dapat digunakan.',
      ),
      (
        status: 422,
        backendCode: 'SIGNUP_EMAIL_INVALID',
        expectedCode: 'SIGNUP_EMAIL_INVALID',
        message:
            'Alamat email ini tidak dapat digunakan untuk mendaftar. Periksa '
            'penulisannya atau gunakan alamat email lain.',
      ),
      (
        status: 422,
        backendCode: 'SIGNUP_EMAIL_DELIVERY_RESTRICTED',
        expectedCode: 'SIGNUP_EMAIL_DELIVERY_RESTRICTED',
        message:
            'Tautan verifikasi tidak dapat dikirim ke alamat email ini. '
            'Gunakan alamat email lain.',
      ),
      (
        status: 422,
        backendCode: 'SIGNUP_EMAIL_REJECTED',
        expectedCode: 'SIGNUP_EMAIL_REJECTED',
        message:
            'Pendaftaran tidak dapat dilanjutkan dengan alamat email ini. '
            'Periksa penulisannya atau gunakan alamat email lain.',
      ),
      (
        status: 422,
        backendCode: 'INVALID_PROFILE_PHOTO',
        expectedCode: 'INVALID_PROFILE_PHOTO',
        message: 'Pilih foto yang valid, maksimal 4096 × 4096 piksel.',
      ),
      (
        status: 413,
        backendCode: 'REQUEST_BODY_TOO_LARGE',
        expectedCode: 'PHOTO_TOO_LARGE',
        message: 'Ukuran foto maksimal 2 MB.',
      ),
      (
        status: 415,
        backendCode: 'UNSUPPORTED_MEDIA_TYPE',
        expectedCode: 'UNSUPPORTED_MEDIA_TYPE',
        message: 'Gunakan foto JPEG, PNG, atau WebP.',
      ),
      (
        status: 400,
        backendCode: 'INVALID_INPUT',
        expectedCode: 'INVALID_INPUT',
        message: 'Periksa kembali data yang kamu masukkan.',
      ),
      (
        status: 404,
        backendCode: 'STALL_NOT_FOUND',
        expectedCode: 'STALL_NOT_FOUND',
        message: 'Stan ini sudah tidak tersedia.',
      ),
      (
        status: 400,
        backendCode: 'INVALID_CATALOG_QUERY',
        expectedCode: 'INVALID_CATALOG_QUERY',
        message: 'Periksa kembali kata kunci pencarian.',
      ),
    ];

void main() {
  test('maps every supported (statusCode, error.code) pair to the exact '
      'AuthException and ignores raw backend messages', () {
    for (final testCase in _supportedEnvelopeCases) {
      final direct = mapAuthErrorCode(testCase.status, testCase.backendCode);
      final fromEnvelope = mapAuthEnvelopeError(testCase.status, {
        'success': false,
        'error': {
          'code': testCase.backendCode,
          'message': 'upstream secret detail for ${testCase.backendCode}',
          'details': {'sql': 'SELECT * FROM auth.users', 'token': 'secret-jwt'},
        },
      });
      expect(direct, isA<AuthException>());
      expect(direct.code, testCase.expectedCode);
      expect(direct.message, testCase.message);
      expect(fromEnvelope.code, testCase.expectedCode);
      expect(fromEnvelope.message, testCase.message);
      expect(fromEnvelope.message, isNot(contains('upstream secret')));
      expect(fromEnvelope.message, isNot(contains('auth.users')));
      expect(fromEnvelope.message, isNot(contains('secret-jwt')));
    }
  });

  test('unrecognized or mismatched status/code pairs fall back to '
      'INVALID_RESPONSE without leaking upstream messages', () {
    final unknownCases = <(int, Map<String, dynamic>)>[
      (
        400,
        {
          'success': false,
          'error': {'code': 'UNKNOWN_ERROR', 'message': 'raw backend detail'},
        },
      ),
      (
        400,
        {
          'success': false,
          'error': {'code': 'INVALID_CREDENTIALS', 'message': 'wrong status'},
        },
      ),
      (
        401,
        {
          'success': false,
          'error': {'code': 'INVALID_CODE', 'message': 'wrong status'},
        },
      ),
      (
        422,
        {
          'success': false,
          'error': {'code': 'EMAIL_UNAVAILABLE', 'message': 'wrong status'},
        },
      ),
      (400, {'success': false, 'error': 'plain string error'}),
      (400, {'success': false, 'error': 12345}),
      (
        400,
        {
          'success': false,
          'error': {'message': 'missing code field'},
        },
      ),
      (200, {'success': false}),
    ];

    for (final (status, envelope) in unknownCases) {
      final mapped = mapAuthEnvelopeError(status, envelope);
      expect(mapped, same(authBadResponseException));
      expect(mapped.code, 'INVALID_RESPONSE');
      expect(
        mapped.message,
        'Respons layanan tidak dapat diproses. Coba lagi.',
      );
    }
  });

  test('status mapper preserves precedence for 503 google/exchange, timeouts, '
      'server outages, and rate limits', () {
    final googleDisabledBody = utf8.encode(
      jsonEncode({
        'success': false,
        'error': {
          'code': 'GOOGLE_DISABLED',
          'message': 'internal provider flag off',
        },
      }),
    );

    final googleDisabled = mapAuthStatusError(
      503,
      endpoint: 'google/exchange',
      bodyBytes: googleDisabledBody,
    );
    expect(googleDisabled, same(authGoogleDisabledException));
    expect(googleDisabled?.code, 'GOOGLE_DISABLED');
    expect(googleDisabled?.message, 'Login Google belum tersedia.');

    final webGoogleDisabled = mapAuthStatusError(
      503,
      endpoint: 'web/google/exchange',
      bodyBytes: googleDisabledBody,
    );
    expect(webGoogleDisabled, same(authGoogleDisabledException));

    final configGoogleDisabled = mapAuthStatusError(
      503,
      endpoint: 'google/config',
      bodyBytes: googleDisabledBody,
    );
    expect(configGoogleDisabled, same(authGoogleDisabledException));

    expect(authGoogleClientDisabledException.code, 'GOOGLE_CLIENT_DISABLED');
    expect(authGoogleConfigException.code, 'GOOGLE_CONFIG');
    expect(authGoogleConfigMismatchException.code, 'GOOGLE_CONFIG_MISMATCH');
    expect({
      authGoogleDisabledException.message,
      authGoogleClientDisabledException.message,
      authGoogleConfigException.message,
      authGoogleConfigMismatchException.message,
    }, hasLength(4));

    // A 503 on google/exchange with another error code falls through to >= 500.
    final googleOutage = mapAuthStatusError(
      503,
      endpoint: 'google/exchange',
      bodyBytes: utf8.encode(
        jsonEncode({
          'success': false,
          'error': {'code': 'UPSTREAM_DOWN', 'message': 'db timeout'},
        }),
      ),
    );
    expect(googleOutage, same(authUnavailableException));
    expect(googleOutage?.code, 'AUTH_UNAVAILABLE');
    expect(
      googleOutage?.message,
      'Layanan sedang tidak tersedia. Coba lagi beberapa saat.',
    );

    // A 503 on google/exchange with malformed body throws FormatException so
    // _request maps it to INVALID_RESPONSE, matching pre-refactor behavior.
    expect(
      () => mapAuthStatusError(
        503,
        endpoint: 'google/exchange',
        bodyBytes: utf8.encode('not-json'),
      ),
      throwsFormatException,
    );
    expect(
      () => mapAuthStatusError(
        503,
        endpoint: 'google/exchange',
        bodyBytes: utf8.encode('[]'),
      ),
      throwsFormatException,
    );

    // A 503 on any other endpoint maps to AUTH_UNAVAILABLE without decoding
    // the body (even when the body is empty or carries GOOGLE_DISABLED).
    for (final endpoint in ['login', 'me', 'register', 'refresh']) {
      expect(
        mapAuthStatusError(503, endpoint: endpoint, bodyBytes: const []),
        same(authUnavailableException),
      );
      expect(
        mapAuthStatusError(
          503,
          endpoint: endpoint,
          bodyBytes: googleDisabledBody,
        ),
        same(authUnavailableException),
      );
    }

    // 408 and 504 take precedence over >= 500 and map to AUTH_TIMEOUT.
    for (final status in [408, 504]) {
      final timeout = mapAuthStatusError(status, endpoint: 'login');
      expect(timeout, same(authTimedOutException));
      expect(timeout?.code, 'AUTH_TIMEOUT');
      expect(timeout?.message, 'Layanan terlalu lama merespons. Coba lagi.');
    }

    // Other 5xx statuses map to AUTH_UNAVAILABLE.
    for (final status in [500, 501, 502, 503, 505, 599]) {
      final unavailable = mapAuthStatusError(status, endpoint: 'login');
      expect(unavailable, same(authUnavailableException));
    }

    // 429 maps to RATE_LIMITED.
    final rateLimited = mapAuthStatusError(429, endpoint: 'login');
    expect(rateLimited, same(authRateLimitedException));
    expect(rateLimited?.code, 'RATE_LIMITED');
    expect(
      rateLimited?.message,
      'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.',
    );

    // Non-short-circuit statuses return null so envelope/photo handling runs.
    for (final status in [
      200,
      202,
      204,
      400,
      401,
      403,
      404,
      409,
      413,
      415,
      422,
    ]) {
      expect(mapAuthStatusError(status, endpoint: 'login'), isNull);
    }
  });

  test(
    'AuthRepository produces identical AuthException output via mapper',
    () async {
      for (final testCase in _supportedEnvelopeCases) {
        final client = MockClient(
          (_) async => http.Response(
            jsonEncode({
              'success': false,
              'error': {
                'code': testCase.backendCode,
                'message': 'raw backend secret',
              },
            }),
            testCase.status,
          ),
        );
        addTearDown(client.close);
        final repository = AuthRepository(
          client: client,
          store: MemorySessionStore(),
          baseUrl: 'https://api.example.test',
        );
        await expectLater(
          repository.register(
            'doni@example.test',
            'password-panjang-15',
            'Doni',
          ),
          throwsA(
            isA<AuthException>()
                .having((e) => e.code, 'code', testCase.expectedCode)
                .having((e) => e.message, 'message', testCase.message),
          ),
        );
      }
    },
  );
}
