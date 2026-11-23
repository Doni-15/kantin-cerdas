import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kantin_cerdas/core/error/app_failure.dart';
import 'package:kantin_cerdas/core/error_presenter.dart';
import 'package:kantin_cerdas/features/auth/data/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/auth/data/auth_repository.dart'
    as auth_repo;
import 'package:kantin_cerdas/features/auth/presentation/auth_form_widgets.dart';

class _UntrustedExceptionWithMessage implements Exception {
  const _UntrustedExceptionWithMessage(this.message);
  final String code = 'UNTRUSTED';
  final String message;

  @override
  String toString() => 'UntrustedException($code): $message';
}

class _CustomAppFailure implements AppFailure {
  const _CustomAppFailure(this.code, this.message);
  @override
  final String code;
  @override
  final String message;
}

String _legacyAuthMessageOracle(Object? error) => error is AuthException
    ? error.message
    : 'Terjadi kesalahan saat memulihkan sesi. Coba lagi.';

String _legacyCatalogErrorOracle(Object? error) => switch (error) {
  AuthException(:final message) => message,
  _ => 'Katalog belum dapat dimuat.',
};

void main() {
  test('presents known application AuthException messages for login, '
      'registration, session recovery, Google OAuth, and account actions', () {
    const knownAuthErrors = <(AuthException, String)>[
      (
        AuthException(
          'INVALID_CREDENTIALS',
          'Email atau kata sandi tidak cocok.',
        ),
        'Email atau kata sandi tidak cocok.',
      ),
      (
        AuthException(
          'EMAIL_NOT_VERIFIED',
          'Verifikasi email untuk melanjutkan.',
        ),
        'Verifikasi email untuk melanjutkan.',
      ),
      (
        AuthException(
          'SIGNUP_EMAIL_INVALID',
          'Alamat email ini tidak dapat digunakan untuk mendaftar. Periksa '
              'penulisannya atau gunakan alamat email lain.',
        ),
        'Alamat email ini tidak dapat digunakan untuk mendaftar. Periksa '
            'penulisannya atau gunakan alamat email lain.',
      ),
      (
        AuthException(
          'SIGNUP_EMAIL_DELIVERY_RESTRICTED',
          'Tautan verifikasi tidak dapat dikirim ke alamat email ini. '
              'Gunakan alamat email lain.',
        ),
        'Tautan verifikasi tidak dapat dikirim ke alamat email ini. '
            'Gunakan alamat email lain.',
      ),
      (
        AuthException(
          'SIGNUP_EMAIL_REJECTED',
          'Pendaftaran tidak dapat dilanjutkan dengan alamat email ini. '
              'Periksa penulisannya atau gunakan alamat email lain.',
        ),
        'Pendaftaran tidak dapat dilanjutkan dengan alamat email ini. '
            'Periksa penulisannya atau gunakan alamat email lain.',
      ),
      (
        AuthException(
          'INVALID_SESSION',
          'Sesi berakhir. Silakan masuk kembali.',
        ),
        'Sesi berakhir. Silakan masuk kembali.',
      ),
      (
        AuthException(
          'SESSION_STORAGE_READ',
          'Sesi tersimpan tidak dapat dibaca. Coba lagi atau masuk ulang.',
        ),
        'Sesi tersimpan tidak dapat dibaca. Coba lagi atau masuk ulang.',
      ),
      (
        AuthException(
          'GOOGLE_CODE_EXPIRED',
          'Verifikasi Google sudah kedaluwarsa. Mulai lagi untuk masuk.',
        ),
        'Verifikasi Google sudah kedaluwarsa. Mulai lagi untuk masuk.',
      ),
      (
        AuthException('PHOTO_TOO_LARGE', 'Ukuran foto maksimal 2 MB.'),
        'Ukuran foto maksimal 2 MB.',
      ),
      (
        AuthException(
          'AUTH_UNAVAILABLE',
          'Layanan sedang tidak tersedia. Coba lagi beberapa saat.',
        ),
        'Layanan sedang tidak tersedia. Coba lagi beberapa saat.',
      ),
      (
        AuthException(
          'AUTH_TIMEOUT',
          'Layanan terlalu lama merespons. Coba lagi.',
        ),
        'Layanan terlalu lama merespons. Coba lagi.',
      ),
      (
        AuthException(
          'AUTH_CONNECTION_FAILED',
          'Tidak dapat terhubung ke layanan. Periksa koneksi lalu coba lagi.',
        ),
        'Tidak dapat terhubung ke layanan. Periksa koneksi lalu coba lagi.',
      ),
    ];

    for (final (exception, expectedMessage) in knownAuthErrors) {
      expect(presentAuthError(exception), expectedMessage);
      expect(authMessage(exception), expectedMessage);
      expect(presentAuthError(exception), _legacyAuthMessageOracle(exception));
    }
  });

  test('presents known catalog AuthException messages for initial load, '
      'detail, search query, and pagination', () {
    const knownCatalogErrors = <(AuthException, String)>[
      (
        AuthException('STALL_NOT_FOUND', 'Stan ini sudah tidak tersedia.'),
        'Stan ini sudah tidak tersedia.',
      ),
      (
        AuthException(
          'INVALID_CATALOG_QUERY',
          'Periksa kembali kata kunci pencarian.',
        ),
        'Periksa kembali kata kunci pencarian.',
      ),
      (
        AuthException(
          'INVALID_CATALOG_RESPONSE',
          'Katalog mengirim data yang tidak valid. Coba lagi.',
        ),
        'Katalog mengirim data yang tidak valid. Coba lagi.',
      ),
      (
        AuthException(
          'AUTH_UNAVAILABLE',
          'Layanan sedang tidak tersedia. Coba lagi beberapa saat.',
        ),
        'Layanan sedang tidak tersedia. Coba lagi beberapa saat.',
      ),
    ];

    for (final (exception, expectedMessage) in knownCatalogErrors) {
      expect(presentCatalogError(exception), expectedMessage);
      expect(
        presentCatalogError(exception),
        _legacyCatalogErrorOracle(exception),
      );
    }
  });

  test('returns context-specific fallbacks for unknown errors and never leaks '
      'technical details, stack traces, or untrusted exception messages', () {
    final untrustedErrors = <Object?>[
      null,
      Exception('SELECT * FROM auth.users WHERE email = secret@example.test'),
      http.ClientException(
        'SocketException: Connection refused https://internal-db.local:5432',
      ),
      const FormatException('Unexpected token at offset 42: bearer eyJhbGci'),
      TimeoutException('Future not completed after 0:00:25.000000'),
      StateError('Bad state: internal stack detail'),
      const _UntrustedExceptionWithMessage(
        'upstream detail with token_hash=abcdef1234567890',
      ),
      'raw string error with refresh_token=secret',
      {'error': 'raw map error'},
    ];

    for (final error in untrustedErrors) {
      final authPresented = presentAuthError(error);
      final wrapperPresented = authMessage(error);
      final catalogPresented = presentCatalogError(error);
      final customPresented = presentAppError(
        error,
        fallback: 'Konteks khusus gagal.',
      );

      expect(
        authPresented,
        'Terjadi kesalahan saat memulihkan sesi. Coba lagi.',
      );
      expect(
        wrapperPresented,
        'Terjadi kesalahan saat memulihkan sesi. Coba lagi.',
      );
      expect(catalogPresented, 'Katalog belum dapat dimuat.');
      expect(customPresented, 'Konteks khusus gagal.');

      // Independent oracle equivalence check:
      expect(authPresented, _legacyAuthMessageOracle(error));
      expect(wrapperPresented, _legacyAuthMessageOracle(error));
      expect(catalogPresented, _legacyCatalogErrorOracle(error));

      // Sensitive information leak prevention check:
      for (final output in [
        authPresented,
        wrapperPresented,
        catalogPresented,
        customPresented,
      ]) {
        expect(output, isNot(contains('auth.users')));
        expect(output, isNot(contains('SocketException')));
        expect(output, isNot(contains('eyJhbGci')));
        expect(output, isNot(contains('upstream detail')));
        expect(output, isNot(contains('token_hash')));
        expect(output, isNot(contains('refresh_token')));
      }
    }
  });

  test('AuthException implements AppFailure and Exception while preserving '
      'runtime type, const identity, re-export, and catch semantics', () {
    const error = AuthException('INVALID_SESSION', 'Sesi berakhir.');
    expect(error, isA<AuthException>());
    expect(error, isA<auth_repo.AuthException>());
    expect(error, isA<AppFailure>());
    expect(error, isA<Exception>());
    expect(
      authInvalidSessionException,
      same(
        const AuthException(
          'INVALID_SESSION',
          'Sesi berakhir. Silakan masuk kembali.',
        ),
      ),
    );

    AuthException? caughtAuth;
    try {
      throw error;
    } on AuthException catch (caught) {
      caughtAuth = caught;
    }
    expect(caughtAuth, same(error));
    expect(presentAppError(error, fallback: 'fallback'), 'Sesi berakhir.');

    const otherFailure = _CustomAppFailure('CUSTOM_ERROR', 'Pesan aman fitur.');
    expect(
      presentAppError(otherFailure, fallback: 'fallback'),
      'Pesan aman fitur.',
    );
  });

  test('core error files do not import features modules', () {
    final presenterSource = File(
      'lib/core/error_presenter.dart',
    ).readAsStringSync();
    final failureSource = File(
      'lib/core/error/app_failure.dart',
    ).readAsStringSync();

    expect(presenterSource, isNot(contains('features/')));
    expect(failureSource, isNot(contains('features/')));
  });
}
