import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/rate_limit_config.dart';
import 'package:test/test.dart';

void main() {
  group('RateLimitConfig', () {
    test('uses expected defaults', () {
      final config = RateLimitConfig.fromEnv(EnvConfig.fromMap({}));

      expect(config.enabled, isTrue);
      expect(config.maxEntries, 10000);
      expect(config.window, const Duration(seconds: 60));
      expect(config.maxRequests, 120);
      expect(config.authWindow, const Duration(seconds: 60));
      expect(config.authMaxRequests, 15);
    });

    test('reads custom rate limit settings', () {
      final config = RateLimitConfig.fromEnv(
        EnvConfig.fromMap({
          'RATE_LIMIT_ENABLED': 'false',
          'RATE_LIMIT_MAX_ENTRIES': '5000',
          'RATE_LIMIT_WINDOW_SECONDS': '120',
          'RATE_LIMIT_MAX_REQUESTS': '300',
          'AUTH_RATE_LIMIT_WINDOW_SECONDS': '30',
          'AUTH_RATE_LIMIT_MAX_REQUESTS': '10',
        }),
      );

      expect(config.enabled, isFalse);
      expect(config.maxEntries, 5000);
      expect(config.window, const Duration(seconds: 120));
      expect(config.maxRequests, 300);
      expect(config.authWindow, const Duration(seconds: 30));
      expect(config.authMaxRequests, 10);
    });

    test('rejects invalid maximum entries', () {
      expect(
        () => RateLimitConfig.fromEnv(
          EnvConfig.fromMap({'RATE_LIMIT_MAX_ENTRIES': '0'}),
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid general rate limit window', () {
      expect(
        () => RateLimitConfig.fromEnv(
          EnvConfig.fromMap({'RATE_LIMIT_WINDOW_SECONDS': '0'}),
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid general request limit', () {
      expect(
        () => RateLimitConfig.fromEnv(
          EnvConfig.fromMap({'RATE_LIMIT_MAX_REQUESTS': '-1'}),
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid auth rate limit window', () {
      expect(
        () => RateLimitConfig.fromEnv(
          EnvConfig.fromMap({'AUTH_RATE_LIMIT_WINDOW_SECONDS': 'abc'}),
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid auth request limit', () {
      expect(
        () => RateLimitConfig.fromEnv(
          EnvConfig.fromMap({'AUTH_RATE_LIMIT_MAX_REQUESTS': '0'}),
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid enabled boolean', () {
      expect(
        () => RateLimitConfig.fromEnv(
          EnvConfig.fromMap({'RATE_LIMIT_ENABLED': 'yes'}),
        ),
        throwsFormatException,
      );
    });
  });
}
