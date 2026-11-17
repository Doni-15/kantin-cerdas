import 'package:kantin_cerdas_backend/src/core/config/cors_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:test/test.dart';

void main() {
  group('CorsConfig', () {
    test('uses expected defaults', () {
      final config = CorsConfig.fromEnv(EnvConfig.fromMap({}));

      expect(config.enabled, isTrue);
      expect(config.allowedOrigins, ['*']);
      expect(config.allowedMethods, [
        'GET',
        'POST',
        'PUT',
        'PATCH',
        'DELETE',
        'OPTIONS',
      ]);
      expect(config.allowedHeaders, [
        'origin',
        'content-type',
        'accept',
        'authorization',
        'idempotency-key',
      ]);
      expect(config.allowCredentials, isFalse);
      expect(config.maxAge, const Duration(seconds: 600));
      expect(config.allowAnyOrigin, isTrue);
    });

    test('reads custom CORS configuration', () {
      final config = CorsConfig.fromEnv(
        EnvConfig.fromMap({
          'CORS_ENABLED': 'true',
          'CORS_ALLOWED_ORIGINS':
              'https://app.example.com,https://admin.example.com',
          'CORS_ALLOWED_METHODS': 'GET,POST,OPTIONS',
          'CORS_ALLOWED_HEADERS': 'Content-Type,Authorization,Idempotency-Key',
          'CORS_ALLOW_CREDENTIALS': 'true',
          'CORS_MAX_AGE_SECONDS': '300',
        }),
      );

      expect(config.allowedOrigins, [
        'https://app.example.com',
        'https://admin.example.com',
      ]);
      expect(config.allowedMethods, ['GET', 'POST', 'OPTIONS']);
      expect(config.allowedHeaders, [
        'content-type',
        'authorization',
        'idempotency-key',
      ]);
      expect(config.allowCredentials, isTrue);
      expect(config.maxAge, const Duration(seconds: 300));
      expect(config.allowAnyOrigin, isFalse);
    });

    test('normalizes origins and methods', () {
      final config = CorsConfig.fromEnv(
        EnvConfig.fromMap({
          'CORS_ALLOWED_ORIGINS': 'HTTPS://APP.EXAMPLE.COM/',
          'CORS_ALLOWED_METHODS': 'get,post',
        }),
      );

      expect(config.allowedOrigins, ['https://app.example.com']);
      expect(config.allowedMethods, ['GET', 'POST']);
    });

    test('rejects invalid origin', () {
      expect(
        () => CorsConfig.fromEnv(
          EnvConfig.fromMap({'CORS_ALLOWED_ORIGINS': 'ftp://example.com'}),
        ),
        throwsFormatException,
      );
    });

    test('rejects origin containing path', () {
      expect(
        () => CorsConfig.fromEnv(
          EnvConfig.fromMap({
            'CORS_ALLOWED_ORIGINS': 'https://example.com/api',
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects wildcard combined with other origins', () {
      expect(
        () => CorsConfig.fromEnv(
          EnvConfig.fromMap({'CORS_ALLOWED_ORIGINS': '*,https://example.com'}),
        ),
        throwsFormatException,
      );
    });

    test('rejects wildcard with credentials', () {
      expect(
        () => CorsConfig.fromEnv(
          EnvConfig.fromMap({
            'CORS_ALLOWED_ORIGINS': '*',
            'CORS_ALLOW_CREDENTIALS': 'true',
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid HTTP method token', () {
      expect(
        () => CorsConfig.fromEnv(
          EnvConfig.fromMap({'CORS_ALLOWED_METHODS': 'GET,INVALID METHOD'}),
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid header token', () {
      expect(
        () => CorsConfig.fromEnv(
          EnvConfig.fromMap({
            'CORS_ALLOWED_HEADERS': 'Content-Type,Bad Header',
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid max age', () {
      expect(
        () => CorsConfig.fromEnv(
          EnvConfig.fromMap({'CORS_MAX_AGE_SECONDS': '-1'}),
        ),
        throwsFormatException,
      );
    });

    test('preserves Idempotency-Key header', () {
      final config = CorsConfig.fromEnv(
        EnvConfig.fromMap({
          'CORS_ALLOWED_HEADERS':
              'Origin,Content-Type,Accept,Authorization,Idempotency-Key',
        }),
      );

      expect(config.allowedHeaders, contains('idempotency-key'));
    });
  });
}
