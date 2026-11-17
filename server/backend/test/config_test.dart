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
    'SUPABASE_PROJECT_REF': 'diprwrdomyqrhllqlche',
    'SUPABASE_URL': 'https://diprwrdomyqrhllqlche.supabase.co',
    'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_test',
    'SUPABASE_SECRET_KEY': 'sb_secret_test',

    // D. Authentication
    'AUTH_JWKS_URL':
        'https://diprwrdomyqrhllqlche.supabase.co/auth/v1/.well-known/jwks.json',
    'AUTH_JWT_ISSUER': 'https://diprwrdomyqrhllqlche.supabase.co/auth/v1',
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
        'https://diprwrdomyqrhllqlche.supabase.co/storage/v1/object/public/kantin-media',

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

      expect(config.supabase.projectRef, 'diprwrdomyqrhllqlche');
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

    test('rejects Supabase URL from another project', () {
      expect(
        () => AppConfig.fromEnv(
          EnvConfig.fromMap(
            validEnvironment(
              overrides: {
                'SUPABASE_URL': 'https://another-project.supabase.co',
              },
            ),
          ),
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
