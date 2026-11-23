import 'dart:io';

import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/app_environment.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:test/test.dart';

Map<String, String> validEnvironment({
  Map<String, String> overrides = const {},
}) {
  return {
    // A. Application
    'APP_NAME': 'Kantin Cerdas API',
    'APP_ENV': 'development',
    'APP_DEBUG': 'true',
    'APP_TIMEZONE': 'Asia/Jakarta',
    'APP_LOCALE': 'id_ID',
    'APP_VERSION': '1.0.0',

    // B. HTTP Server
    'SERVER_HOST': '0.0.0.0',
    'SERVER_PORT': '8080',
    'API_PREFIX': '/v1',

    // C. Supabase
    'SUPABASE_PROJECT_REF': 'exampleprojectref001',
    'SUPABASE_URL': 'https://exampleprojectref001.supabase.co',
    'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_test',
    'SUPABASE_SECRET_KEY': 'sb_secret_test',

    // D. Authentication
    'AUTH_JWKS_URL':
        'https://exampleprojectref001.supabase.co/auth/v1/.well-known/jwks.json',
    'AUTH_JWT_ISSUER': 'https://exampleprojectref001.supabase.co/auth/v1',
    'AUTH_JWT_AUDIENCE': 'authenticated',
    'AUTH_JWT_ALLOWED_ALGORITHMS': 'ES256',

    // E. Security
    'SECURITY_ALLOWED_HOSTS': '*',
    'SECURITY_ENABLE_SECURITY_HEADERS': 'true',

    // F. CORS
    'CORS_ENABLED': 'true',
    'CORS_ALLOWED_ORIGINS': '*',
    'CORS_ALLOWED_METHODS': 'GET,POST,PUT,PATCH,DELETE,OPTIONS',
    'CORS_ALLOWED_HEADERS':
        'Origin,Content-Type,Accept,Authorization,Idempotency-Key',
    'CORS_ALLOW_CREDENTIALS': 'false',

    // G. Rate Limiting
    'RATE_LIMIT_ENABLED': 'true',

    // H. Storage
    'STORAGE_BUCKET_NAME': 'kantin-media',
    'STORAGE_PUBLIC_BASE_URL':
        'https://exampleprojectref001.supabase.co/storage/v1/object/public/kantin-media',

    // I. Logging
    'LOG_LEVEL': 'info',
    'LOG_FORMAT': 'text',
    'LOG_REQUEST_ENABLED': 'true',
    'LOG_INCLUDE_STACK_TRACE': 'false',

    ...overrides,
  };
}

void main() {
  group('AppEnvironment', () {
    test('parses development environment', () {
      expect(AppEnvironment.parse('development'), AppEnvironment.development);
    });

    test('parses production alias', () {
      expect(AppEnvironment.parse('prod'), AppEnvironment.production);
    });

    test('rejects unknown environment', () {
      expect(() => AppEnvironment.parse('unknown'), throwsFormatException);
    });
  });

  group('EnvConfig', () {
    test('system environment overrides env file', () async {
      final directory = await Directory.systemTemp.createTemp();

      try {
        final envFile = File('${directory.path}/.env');
        await envFile.writeAsString('SERVER_PORT=8080\n');

        final config = await EnvConfig.load(
          envFilePath: envFile.path,
          systemEnvironment: {'SERVER_PORT': '9090'},
        );

        expect(config['SERVER_PORT'], '9090');
      } finally {
        await directory.delete(recursive: true);
      }
    });

    test('reads quoted values', () async {
      final directory = await Directory.systemTemp.createTemp();

      try {
        final envFile = File('${directory.path}/.env');
        await envFile.writeAsString('APP_NAME="Kantin Cerdas"\n');

        final config = await EnvConfig.load(
          envFilePath: envFile.path,
          systemEnvironment: {},
        );

        expect(config['APP_NAME'], 'Kantin Cerdas');
      } finally {
        await directory.delete(recursive: true);
      }
    });
  });

  group('AppConfig', () {
    test('production cannot enable the Google QA gate', () {
      for (final environment in ['development', 'staging', 'production']) {
        final config = AppConfig.fromEnv(
          EnvConfig.fromMap(
            validEnvironment(
              overrides: {
                'APP_ENV': environment,
                'AUTH_GOOGLE_ENABLED': 'true',
              },
            ),
          ),
        );
        expect(config.auth.googleEnabled, environment != 'production');
        expect(config.auth.googleProductionVerified, isFalse);
      }
    });

    test(
      'production enables Google Sign-In only when AUTH_GOOGLE_PRODUCTION_VERIFIED is true',
      () {
        final verifiedProd = AppConfig.fromEnv(
          EnvConfig.fromMap(
            validEnvironment(
              overrides: {
                'APP_ENV': 'production',
                'AUTH_GOOGLE_ENABLED': 'true',
                'AUTH_GOOGLE_PRODUCTION_VERIFIED': 'true',
              },
            ),
          ),
        );
        expect(verifiedProd.isProduction, isTrue);
        expect(verifiedProd.auth.googleProductionVerified, isTrue);
        expect(verifiedProd.auth.googleEnabled, isTrue);

        final disabledDespiteVerified = AppConfig.fromEnv(
          EnvConfig.fromMap(
            validEnvironment(
              overrides: {
                'APP_ENV': 'production',
                'AUTH_GOOGLE_ENABLED': 'false',
                'AUTH_GOOGLE_PRODUCTION_VERIFIED': 'true',
              },
            ),
          ),
        );
        expect(disabledDespiteVerified.auth.googleProductionVerified, isTrue);
        expect(disabledDespiteVerified.auth.googleEnabled, isFalse);
      },
    );

    test('loads all configuration groups', () {
      final config = AppConfig.fromEnv(EnvConfig.fromMap(validEnvironment()));

      expect(config.appName, 'Kantin Cerdas API');
      expect(config.environment, AppEnvironment.development);
      expect(config.debug, isTrue);
      expect(config.timezone, 'Asia/Jakarta');
      expect(config.locale, 'id_ID');
      expect(config.version, '1.0.0');

      expect(config.server.host, '0.0.0.0');
      expect(config.server.port, 8080);
      expect(config.server.apiPrefix, '/v1');

      expect(config.supabase.projectRef, 'exampleprojectref001');
      expect(config.auth.audience, 'authenticated');

      expect(config.cors.enabled, isTrue);
      expect(config.rateLimit.enabled, isTrue);
      expect(config.storage.bucketName, 'kantin-media');
      expect(config.logging.level, 'info');
      expect(config.proxy.trustedProxyIps, isEmpty);
    });

    test('identifies application environment', () {
      final config = AppConfig.fromEnv(EnvConfig.fromMap(validEnvironment()));

      expect(config.isDevelopment, isTrue);
      expect(config.isStaging, isFalse);
      expect(config.isProduction, isFalse);
    });

    test('normalizes API prefix through ServerConfig', () {
      final config = AppConfig.fromEnv(
        EnvConfig.fromMap(
          validEnvironment(
            overrides: {'API_PREFIX': 'v2/', 'SERVER_PORT': '9090'},
          ),
        ),
      );

      expect(config.server.apiPrefix, '/v2');
      expect(config.server.port, 9090);
    });

    test('rejects invalid server port', () {
      expect(
        () => AppConfig.fromEnv(
          EnvConfig.fromMap(
            validEnvironment(overrides: {'SERVER_PORT': '70000'}),
          ),
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid application locale', () {
      expect(
        () => AppConfig.fromEnv(
          EnvConfig.fromMap(
            validEnvironment(overrides: {'APP_LOCALE': 'invalid'}),
          ),
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid application version', () {
      expect(
        () => AppConfig.fromEnv(
          EnvConfig.fromMap(
            validEnvironment(overrides: {'APP_VERSION': 'version-one'}),
          ),
        ),
        throwsFormatException,
      );
    });

    test('derives service addresses from a single Supabase URL', () {
      final config = AppConfig.fromEnv(
        EnvConfig.fromMap(
          validEnvironment(
              overrides: {
                'SUPABASE_URL': 'https://abcdefghijklmnopqrst.supabase.co',
                'STORAGE_BUCKET_NAME': 'project-media',
              },
            )
            ..remove('SUPABASE_PROJECT_REF')
            ..remove('AUTH_JWT_ISSUER')
            ..remove('AUTH_JWKS_URL')
            ..remove('STORAGE_PUBLIC_BASE_URL'),
        ),
      );
      const url = 'https://abcdefghijklmnopqrst.supabase.co';
      expect(config.supabase.projectRef, 'abcdefghijklmnopqrst');
      expect(config.auth.issuer.toString(), '$url/auth/v1');
      expect(
        config.auth.jwksUrl.toString(),
        '$url/auth/v1/.well-known/jwks.json',
      );
      expect(
        config.storage.publicBaseUrl.toString(),
        '$url/storage/v1/object/public/project-media',
      );
    });

    test('rejects Supabase URL from another project', () {
      expect(
        () => AppConfig.fromEnv(
          EnvConfig.fromMap(
            validEnvironment(
              overrides: {
                'SUPABASE_URL': 'https://abcdefghijklmnopqrst.supabase.co',
              },
            ),
          ),
        ),
        throwsFormatException,
      );
    });

    test('loopback Supabase with local JWTs only works in development', () {
      const loopback = 'http://127.0.0.1:54321';
      final values =
          validEnvironment(
              overrides: {
                'SUPABASE_URL': loopback,
                'SUPABASE_PROJECT_REF': 'local',
                'SUPABASE_PUBLISHABLE_KEY': 'test.anon.signature',
                'SUPABASE_SECRET_KEY': 'test.service.signature',
              },
            )
            ..remove('AUTH_JWT_ISSUER')
            ..remove('AUTH_JWKS_URL')
            ..remove('AUTH_JWT_ALLOWED_ALGORITHMS')
            ..remove('STORAGE_PUBLIC_BASE_URL');
      final config = AppConfig.fromEnv(EnvConfig.fromMap(values));
      expect(config.auth.issuer.toString(), '$loopback/auth/v1');
      expect(config.auth.allowedAlgorithms, ['HS256']);
      for (final environment in ['staging', 'production']) {
        expect(
          () => AppConfig.fromEnv(
            EnvConfig.fromMap({...values, 'APP_ENV': environment}),
          ),
          throwsFormatException,
        );
      }
      expect(
        () => AppConfig.fromEnv(
          EnvConfig.fromMap({
            ...values,
            'SUPABASE_URL': 'http://192.0.2.1:54321',
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects Auth URL from another project', () {
      expect(
        () => AppConfig.fromEnv(
          EnvConfig.fromMap(
            validEnvironment(
              overrides: {
                'AUTH_JWT_ISSUER':
                    'https://another-project.supabase.co/auth/v1',
              },
            ),
          ),
        ),
        throwsFormatException,
      );
    });

    test('rejects Storage URL from another project', () {
      expect(
        () => AppConfig.fromEnv(
          EnvConfig.fromMap(
            validEnvironment(
              overrides: {
                'STORAGE_PUBLIC_BASE_URL':
                    'https://another-project.supabase.co/storage/v1/object/public/kantin-media',
              },
            ),
          ),
        ),
        throwsFormatException,
      );
    });
  });
}
