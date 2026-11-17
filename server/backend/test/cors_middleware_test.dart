import 'package:kantin_cerdas_backend/src/core/config/cors_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/cors_middleware.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

CorsConfig createCorsConfig({Map<String, String> overrides = const {}}) {
  return CorsConfig.fromEnv(
    EnvConfig.fromMap({
      'CORS_ENABLED': 'true',
      'CORS_ALLOWED_ORIGINS': 'https://app.example.com',
      'CORS_ALLOWED_METHODS': 'GET,POST,PUT,DELETE,OPTIONS',
      'CORS_ALLOWED_HEADERS': 'Content-Type,Authorization,Idempotency-Key',
      'CORS_ALLOW_CREDENTIALS': 'true',
      'CORS_MAX_AGE_SECONDS': '600',
      ...overrides,
    }),
  );
}

void main() {
  group('CORS Middleware', () {
    test('adds CORS headers to allowed origin', () async {
      final config = createCorsConfig();

      final handler = Pipeline()
          .addMiddleware(corsMiddleware(config))
          .addHandler((request) => Response.ok('OK'));

      final response = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/'),
          headers: {'origin': 'https://app.example.com'},
        ),
      );

      expect(response.statusCode, 200);
      expect(
        response.headers['access-control-allow-origin'],
        'https://app.example.com',
      );
      expect(response.headers['access-control-allow-credentials'], 'true');
    });

    test('handles valid preflight request', () async {
      final config = createCorsConfig();

      final handler = Pipeline()
          .addMiddleware(corsMiddleware(config))
          .addHandler((request) => Response.ok('OK'));

      final response = await handler(
        Request(
          'OPTIONS',
          Uri.parse('http://localhost/'),
          headers: {
            'origin': 'https://app.example.com',
            'access-control-request-method': 'POST',
            'access-control-request-headers': 'content-type, authorization',
          },
        ),
      );

      expect(response.statusCode, 204);
      expect(
        response.headers['access-control-allow-origin'],
        'https://app.example.com',
      );
      expect(
        response.headers['access-control-allow-methods'],
        contains('POST'),
      );
      expect(
        response.headers['access-control-allow-headers'],
        contains('authorization'),
      );
      expect(response.headers['access-control-max-age'], '600');
    });

    test('rejects preflight from disallowed origin', () async {
      final config = createCorsConfig();

      final handler = Pipeline()
          .addMiddleware(corsMiddleware(config))
          .addHandler((request) => Response.ok('OK'));

      final response = await handler(
        Request(
          'OPTIONS',
          Uri.parse('http://localhost/'),
          headers: {
            'origin': 'https://evil.example.com',
            'access-control-request-method': 'POST',
          },
        ),
      );

      expect(response.statusCode, 403);
      expect(
        response.headers.containsKey('access-control-allow-origin'),
        isFalse,
      );
    });

    test('rejects preflight with disallowed method', () async {
      final config = createCorsConfig();

      final handler = Pipeline()
          .addMiddleware(corsMiddleware(config))
          .addHandler((request) => Response.ok('OK'));

      final response = await handler(
        Request(
          'OPTIONS',
          Uri.parse('http://localhost/'),
          headers: {
            'origin': 'https://app.example.com',
            'access-control-request-method': 'PATCH',
          },
        ),
      );

      expect(response.statusCode, 403);
    });

    test('rejects preflight with disallowed request header', () async {
      final config = createCorsConfig();

      final handler = Pipeline()
          .addMiddleware(corsMiddleware(config))
          .addHandler((request) => Response.ok('OK'));

      final response = await handler(
        Request(
          'OPTIONS',
          Uri.parse('http://localhost/'),
          headers: {
            'origin': 'https://app.example.com',
            'access-control-request-method': 'POST',
            'access-control-request-headers': 'x-unknown-header',
          },
        ),
      );

      expect(response.statusCode, 403);
    });

    test('supports wildcard origin', () async {
      final config = createCorsConfig(
        overrides: {
          'CORS_ALLOWED_ORIGINS': '*',
          'CORS_ALLOW_CREDENTIALS': 'false',
        },
      );

      final handler = Pipeline()
          .addMiddleware(corsMiddleware(config))
          .addHandler((request) => Response.ok('OK'));

      final response = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/'),
          headers: {'origin': 'https://any.example.com'},
        ),
      );

      expect(response.headers['access-control-allow-origin'], '*');
      expect(
        response.headers.containsKey('access-control-allow-credentials'),
        isFalse,
      );
    });

    test('does not add CORS headers when disabled', () async {
      final config = createCorsConfig(overrides: {'CORS_ENABLED': 'false'});

      final handler = Pipeline()
          .addMiddleware(corsMiddleware(config))
          .addHandler((request) => Response.ok('OK'));

      final response = await handler(
        Request(
          'GET',
          Uri.parse('http://localhost/'),
          headers: {'origin': 'https://app.example.com'},
        ),
      );

      expect(response.statusCode, 200);
      expect(
        response.headers.containsKey('access-control-allow-origin'),
        isFalse,
      );
    });
  });
}
