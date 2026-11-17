import 'package:kantin_cerdas_backend/src/core/config/auth_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:test/test.dart';

void main() {
  const validValues = {
    'AUTH_JWKS_URL':
        'https://example.supabase.co/auth/v1/.well-known/jwks.json',
    'AUTH_JWT_ISSUER': 'https://example.supabase.co/auth/v1',
    'AUTH_JWT_AUDIENCE': 'authenticated',
    'AUTH_JWT_ALLOWED_ALGORITHMS': 'ES256',
  };

  group('AuthConfig', () {
    test('reads authentication configuration', () {
      final config = AuthConfig.fromEnv(EnvConfig.fromMap(validValues));

      expect(config.jwksUrl.toString(), validValues['AUTH_JWKS_URL']);
      expect(config.issuer.toString(), validValues['AUTH_JWT_ISSUER']);
      expect(config.audience, 'authenticated');
      expect(config.allowedAlgorithms, ['ES256']);
      expect(config.jwksCacheTtl, const Duration(seconds: 3600));
      expect(config.clockSkew, const Duration(seconds: 30));
      expect(config.requireEmailVerified, isFalse);
    });

    test('reads custom authentication settings', () {
      final config = AuthConfig.fromEnv(
        EnvConfig.fromMap({
          ...validValues,
          'AUTH_JWT_ALLOWED_ALGORITHMS': 'ES256,RS256',
          'AUTH_JWKS_CACHE_TTL_SECONDS': '1800',
          'AUTH_CLOCK_SKEW_SECONDS': '60',
          'AUTH_REQUIRE_EMAIL_VERIFIED': 'true',
        }),
      );

      expect(config.allowedAlgorithms, ['ES256', 'RS256']);
      expect(config.jwksCacheTtl, const Duration(seconds: 1800));
      expect(config.clockSkew, const Duration(seconds: 60));
      expect(config.requireEmailVerified, isTrue);
    });

    test('rejects missing JWKS URL', () {
      expect(
        () => AuthConfig.fromEnv(
          EnvConfig.fromMap({...validValues}..remove('AUTH_JWKS_URL')),
        ),
        throwsFormatException,
      );
    });

    test('rejects non-HTTPS issuer', () {
      expect(
        () => AuthConfig.fromEnv(
          EnvConfig.fromMap({
            ...validValues,
            'AUTH_JWT_ISSUER': 'http://example.com/auth/v1',
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects unsupported JWT algorithm', () {
      expect(
        () => AuthConfig.fromEnv(
          EnvConfig.fromMap({
            ...validValues,
            'AUTH_JWT_ALLOWED_ALGORITHMS': 'none',
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects duplicate JWT algorithms', () {
      expect(
        () => AuthConfig.fromEnv(
          EnvConfig.fromMap({
            ...validValues,
            'AUTH_JWT_ALLOWED_ALGORITHMS': 'ES256,ES256',
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects negative clock skew', () {
      expect(
        () => AuthConfig.fromEnv(
          EnvConfig.fromMap({...validValues, 'AUTH_CLOCK_SKEW_SECONDS': '-1'}),
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid email verification boolean', () {
      expect(
        () => AuthConfig.fromEnv(
          EnvConfig.fromMap({
            ...validValues,
            'AUTH_REQUIRE_EMAIL_VERIFIED': 'yes',
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects empty audience', () {
      expect(
        () => AuthConfig.fromEnv(
          EnvConfig.fromMap({...validValues, 'AUTH_JWT_AUDIENCE': ''}),
        ),
        throwsFormatException,
      );
    });
  });
}
