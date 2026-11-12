import 'package:kantin_cerdas_backend/src/core/constants/security_constants.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/auth_validator.dart';
import 'package:test/test.dart';

Matcher _invalidToken() => isA<ApiException>()
    .having((e) => e.statusCode, 'statusCode', 401)
    .having((e) => e.code, 'code', 'INVALID_TOKEN');

void main() {
  group('AuthValidator.validateRefreshToken', () {
    test('menerima refresh_token (snake_case)', () {
      expect(
        AuthValidator.validateRefreshToken({'refresh_token': 'abc123'}),
        'abc123',
      );
    });

    test('menerima refreshToken (camelCase)', () {
      expect(
        AuthValidator.validateRefreshToken({'refreshToken': 'abc123'}),
        'abc123',
      );
    });

    test('memangkas spasi di sekitar token', () {
      expect(
        AuthValidator.validateRefreshToken({'refresh_token': '  abc123 \n'}),
        'abc123',
      );
    });

    test('menolak body tanpa token dengan 401 INVALID_TOKEN', () {
      expect(
        () => AuthValidator.validateRefreshToken(<String, Object?>{}),
        throwsA(_invalidToken()),
      );
    });

    test('menolak token kosong atau hanya spasi', () {
      expect(
        () => AuthValidator.validateRefreshToken({'refresh_token': ''}),
        throwsA(_invalidToken()),
      );
      expect(
        () => AuthValidator.validateRefreshToken({'refresh_token': '   '}),
        throwsA(_invalidToken()),
      );
    });

    test('menolak token yang bukan string', () {
      for (final value in <Object?>[null, 123, true, <String>['a'], {'a': 1}]) {
        expect(
          () => AuthValidator.validateRefreshToken({'refresh_token': value}),
          throwsA(_invalidToken()),
          reason: 'nilai $value seharusnya ditolak',
        );
      }
    });

    test('menerima token tepat pada batas panjang maksimum', () {
      final token = 'a' * SecurityConstants.maxRefreshTokenLength;
      expect(
        AuthValidator.validateRefreshToken({'refresh_token': token}),
        token,
      );
    });

    test('menolak token yang melebihi batas panjang maksimum', () {
      final token = 'a' * (SecurityConstants.maxRefreshTokenLength + 1);
      expect(
        () => AuthValidator.validateRefreshToken({'refresh_token': token}),
        throwsA(_invalidToken()),
      );
    });
  });
}
