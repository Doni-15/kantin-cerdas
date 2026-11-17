import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/security_config.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/security_headers.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  group('Security Headers Middleware', () {
    test('adds security headers when enabled', () async {
      final config = SecurityConfig.fromEnv(
        EnvConfig.fromMap({'SECURITY_ENABLE_SECURITY_HEADERS': 'true'}),
      );

      final handler = Pipeline()
          .addMiddleware(securityHeaders(config))
          .addHandler((request) => Response.ok('OK'));

      final response = await handler(
        Request('GET', Uri.parse('http://localhost/')),
      );

      expect(response.statusCode, 200);
      expect(response.headers['x-content-type-options'], 'nosniff');
      expect(response.headers['x-frame-options'], 'SAMEORIGIN');
      expect(
        response.headers['referrer-policy'],
        'strict-origin-when-cross-origin',
      );
      expect(
        response.headers['permissions-policy'],
        'camera=(), microphone=(), geolocation=()',
      );
      expect(
        response.headers['content-security-policy'],
        "frame-ancestors 'self'",
      );
    });

    test('does not add security headers when disabled', () async {
      final config = SecurityConfig.fromEnv(
        EnvConfig.fromMap({'SECURITY_ENABLE_SECURITY_HEADERS': 'false'}),
      );

      final handler = Pipeline()
          .addMiddleware(securityHeaders(config))
          .addHandler((request) => Response.ok('OK'));

      final response = await handler(
        Request('GET', Uri.parse('http://localhost/')),
      );

      expect(response.statusCode, 200);
      expect(response.headers.containsKey('x-frame-options'), isFalse);
      expect(response.headers.containsKey('content-security-policy'), isFalse);
    });
  });
}
