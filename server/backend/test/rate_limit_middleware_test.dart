import 'dart:io';

import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/proxy_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/rate_limit_config.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/rate_limit_middleware.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  group('RateLimitMiddleware', () {
    late RateLimitConfig config;
    late ProxyConfig proxyConfig;
    late DateTime currentTime;
    late RateLimitMiddleware rateLimiter;
    late Handler handler;

    Request createRequest({
      String path = '/v1/products',
      String ip = '192.168.1.10',
      Map<String, String> headers = const {},
    }) {
      return Request(
        'GET',
        Uri.parse('http://localhost$path'),
        headers: headers,
        context: {
          'shelf.io.connection_info': FakeHttpConnectionInfo(
            InternetAddress(ip),
          ),
        },
      );
    }

    RateLimitMiddleware createTrustedLimiter() {
      return RateLimitMiddleware(
        config: config,
        apiPrefix: '/v1',
        proxyConfig: ProxyConfig.fromEnv(
          EnvConfig.fromMap({'TRUSTED_PROXY_IPS': '10.0.0.10,10.0.0.20'}),
        ),
        clock: () => currentTime,
      );
    }

    setUp(() {
      config = RateLimitConfig.fromEnv(
        EnvConfig.fromMap({
          'RATE_LIMIT_ENABLED': 'true',
          'RATE_LIMIT_WINDOW_SECONDS': '60',
          'RATE_LIMIT_MAX_REQUESTS': '2',
          'AUTH_RATE_LIMIT_WINDOW_SECONDS': '60',
          'AUTH_RATE_LIMIT_MAX_REQUESTS': '1',
        }),
      );

      proxyConfig = ProxyConfig.fromEnv(EnvConfig.fromMap({}));

      currentTime = DateTime.utc(2026, 11, 17, 10);

      rateLimiter = RateLimitMiddleware(
        config: config,
        apiPrefix: '/v1',
        proxyConfig: proxyConfig,
        clock: () => currentTime,
      );

      handler = rateLimiter.middleware((request) => Response.ok('OK'));
    });

    test('allows requests within the configured limit', () async {
      final response1 = await handler(createRequest());
      final response2 = await handler(createRequest());

      expect(response1.statusCode, 200);
      expect(response2.statusCode, 200);
      expect(response1.headers['x-ratelimit-limit'], '2');
      expect(response1.headers['x-ratelimit-remaining'], '1');
      expect(response2.headers['x-ratelimit-remaining'], '0');
    });

    test('rejects requests exceeding the general limit', () async {
      await handler(createRequest());
      await handler(createRequest());

      final response = await handler(createRequest());

      expect(response.statusCode, 429);
      expect(response.headers['retry-after'], '60');
      expect(response.headers['x-ratelimit-limit'], '2');
      expect(response.headers['x-ratelimit-remaining'], '0');
    });

    test('uses the configured API prefix for authentication routes', () async {
      final customLimiter = RateLimitMiddleware(
        config: config,
        proxyConfig: proxyConfig,
        apiPrefix: '/api/v2',
        clock: () => currentTime,
      );

      final customHandler = customLimiter.middleware(
        (request) => Response.ok('OK'),
      );

      final authResponse1 = await customHandler(
        createRequest(path: '/api/v2/auth/login'),
      );
      final authResponse2 = await customHandler(
        createRequest(path: '/api/v2/auth/login'),
      );

      final nonAuthResponse1 = await customHandler(
        createRequest(path: '/api/v2/authentication'),
      );
      final nonAuthResponse2 = await customHandler(
        createRequest(path: '/api/v2/authentication'),
      );
      final nonAuthResponse3 = await customHandler(
        createRequest(path: '/api/v2/authentication'),
      );

      expect(authResponse1.statusCode, 200);
      expect(authResponse2.statusCode, 429);

      expect(nonAuthResponse1.statusCode, 200);
      expect(nonAuthResponse2.statusCode, 200);
      expect(nonAuthResponse3.statusCode, 429);
    });

    test('uses a separate limit for authentication requests', () async {
      final response1 = await handler(createRequest(path: '/v1/auth/login'));

      final response2 = await handler(createRequest(path: '/v1/auth/login'));

      expect(response1.statusCode, 200);
      expect(response2.statusCode, 429);
      expect(response1.headers['x-ratelimit-limit'], '1');
      expect(response2.headers['x-ratelimit-remaining'], '0');
    });

    test('does not share counters between different client IPs', () async {
      await handler(createRequest(ip: '192.168.1.10'));
      await handler(createRequest(ip: '192.168.1.10'));

      final response = await handler(createRequest(ip: '192.168.1.11'));

      expect(response.statusCode, 200);
      expect(response.headers['x-ratelimit-remaining'], '1');
    });

    test('rejects new clients when entry capacity is full', () async {
      final limitedConfig = RateLimitConfig.fromEnv(
        EnvConfig.fromMap({
          'RATE_LIMIT_MAX_ENTRIES': '1',
          'RATE_LIMIT_MAX_REQUESTS': '5',
        }),
      );

      final limitedLimiter = RateLimitMiddleware(
        config: limitedConfig,
        apiPrefix: '/v1',
        proxyConfig: proxyConfig,
        clock: () => currentTime,
      );

      final limitedHandler = limitedLimiter.middleware(
        (request) => Response.ok('OK'),
      );

      final firstResponse = await limitedHandler(
        createRequest(ip: '192.168.1.20'),
      );

      final rejectedResponse = await limitedHandler(
        createRequest(ip: '192.168.1.21'),
      );

      final existingClientResponse = await limitedHandler(
        createRequest(ip: '192.168.1.20'),
      );

      expect(firstResponse.statusCode, 200);
      expect(rejectedResponse.statusCode, 503);
      expect(rejectedResponse.headers['retry-after'], '1');
      expect(existingClientResponse.statusCode, 200);
    });

    test('cleans expired entries when capacity is exhausted', () async {
      final limitedConfig = RateLimitConfig.fromEnv(
        EnvConfig.fromMap({
          'RATE_LIMIT_MAX_ENTRIES': '1',
          'RATE_LIMIT_WINDOW_SECONDS': '10',
          'RATE_LIMIT_MAX_REQUESTS': '5',
        }),
      );

      final limitedLimiter = RateLimitMiddleware(
        config: limitedConfig,
        apiPrefix: '/v1',
        proxyConfig: proxyConfig,
        clock: () => currentTime,
      );

      final limitedHandler = limitedLimiter.middleware(
        (request) => Response.ok('OK'),
      );

      final firstResponse = await limitedHandler(
        createRequest(ip: '192.168.1.20'),
      );

      currentTime = currentTime.add(const Duration(seconds: 11));

      final secondResponse = await limitedHandler(
        createRequest(ip: '192.168.1.21'),
      );

      expect(firstResponse.statusCode, 200);
      expect(secondResponse.statusCode, 200);
    });

    test('resets the counter after the window expires', () async {
      await handler(createRequest());
      await handler(createRequest());

      currentTime = currentTime.add(const Duration(seconds: 60));

      final response = await handler(createRequest());

      expect(response.statusCode, 200);
      expect(response.headers['x-ratelimit-remaining'], '1');
    });

    test('returns correct retry-after for remaining window time', () async {
      await handler(createRequest());
      await handler(createRequest());

      currentTime = currentTime.add(const Duration(seconds: 25));

      final response = await handler(createRequest());

      expect(response.statusCode, 429);
      expect(response.headers['retry-after'], '35');
    });

    test('allows all requests when rate limiting is disabled', () async {
      final disabledConfig = RateLimitConfig.fromEnv(
        EnvConfig.fromMap({
          'RATE_LIMIT_ENABLED': 'false',
          'RATE_LIMIT_MAX_REQUESTS': '1',
        }),
      );

      final disabledLimiter = RateLimitMiddleware(
        config: disabledConfig,
        apiPrefix: '/v1',
        proxyConfig: proxyConfig,
        clock: () => currentTime,
      );

      final disabledHandler = disabledLimiter.middleware(
        (request) => Response.ok('OK'),
      );

      final response1 = await disabledHandler(createRequest());
      final response2 = await disabledHandler(createRequest());
      final response3 = await disabledHandler(createRequest());

      expect(response1.statusCode, 200);
      expect(response2.statusCode, 200);
      expect(response3.statusCode, 200);
      expect(response1.headers['x-ratelimit-limit'], isNull);
    });

    test('returns 500 when connection information is unavailable', () async {
      final request = Request('GET', Uri.parse('http://localhost/v1/products'));

      final response = await handler(request);

      expect(response.statusCode, 500);
    });

    test('ignores forged X-Forwarded-For from an untrusted client', () async {
      final response1 = await handler(
        createRequest(headers: {'x-forwarded-for': '203.0.113.1'}),
      );

      final response2 = await handler(
        createRequest(headers: {'x-forwarded-for': '203.0.113.2'}),
      );

      final response3 = await handler(
        createRequest(headers: {'x-forwarded-for': '203.0.113.3'}),
      );

      expect(response1.statusCode, 200);
      expect(response2.statusCode, 200);
      expect(response3.statusCode, 429);
    });

    test('uses client IP forwarded by a trusted proxy', () async {
      final trustedHandler = createTrustedLimiter().middleware(
        (request) => Response.ok('OK'),
      );

      final response1 = await trustedHandler(
        createRequest(
          ip: '10.0.0.10',
          headers: {'x-forwarded-for': '203.0.113.5'},
        ),
      );

      final response2 = await trustedHandler(
        createRequest(
          ip: '10.0.0.10',
          headers: {'x-forwarded-for': '203.0.113.5'},
        ),
      );

      final response3 = await trustedHandler(
        createRequest(
          ip: '10.0.0.10',
          headers: {'x-forwarded-for': '203.0.113.5'},
        ),
      );

      expect(response1.statusCode, 200);
      expect(response2.statusCode, 200);
      expect(response3.statusCode, 429);
    });

    test('separates clients behind the same trusted proxy', () async {
      final trustedHandler = createTrustedLimiter().middleware(
        (request) => Response.ok('OK'),
      );

      await trustedHandler(
        createRequest(
          ip: '10.0.0.10',
          headers: {'x-forwarded-for': '203.0.113.5'},
        ),
      );

      await trustedHandler(
        createRequest(
          ip: '10.0.0.10',
          headers: {'x-forwarded-for': '203.0.113.5'},
        ),
      );

      final response = await trustedHandler(
        createRequest(
          ip: '10.0.0.10',
          headers: {'x-forwarded-for': '203.0.113.6'},
        ),
      );

      expect(response.statusCode, 200);
      expect(response.headers['x-ratelimit-remaining'], '1');
    });

    test('walks a trusted proxy chain from right to left', () async {
      final trustedHandler = createTrustedLimiter().middleware(
        (request) => Response.ok('OK'),
      );

      final response1 = await trustedHandler(
        createRequest(
          ip: '10.0.0.10',
          headers: {'x-forwarded-for': '198.51.100.99, 203.0.113.5, 10.0.0.20'},
        ),
      );

      final response2 = await trustedHandler(
        createRequest(
          ip: '10.0.0.10',
          headers: {'x-forwarded-for': '192.0.2.99, 203.0.113.5, 10.0.0.20'},
        ),
      );

      final response3 = await trustedHandler(
        createRequest(
          ip: '10.0.0.10',
          headers: {'x-forwarded-for': '192.0.2.99, 203.0.113.5, 10.0.0.20'},
        ),
      );

      expect(response1.statusCode, 200);
      expect(response2.statusCode, 200);
      expect(response3.statusCode, 429);
    });

    test('falls back to proxy IP when X-Forwarded-For is too long', () async {
      final trustedHandler = createTrustedLimiter().middleware(
        (request) => Response.ok('OK'),
      );

      final oversizedHeader = 'a' * 1025;

      final response1 = await trustedHandler(
        createRequest(
          ip: '10.0.0.10',
          headers: {'x-forwarded-for': oversizedHeader},
        ),
      );

      final response2 = await trustedHandler(
        createRequest(
          ip: '10.0.0.10',
          headers: {'x-forwarded-for': oversizedHeader},
        ),
      );

      final response3 = await trustedHandler(
        createRequest(
          ip: '10.0.0.10',
          headers: {'x-forwarded-for': oversizedHeader},
        ),
      );

      expect(response1.statusCode, 200);
      expect(response2.statusCode, 200);
      expect(response3.statusCode, 429);
    });

    test(
      'falls back to proxy IP when X-Forwarded-For has too many entries',
      () async {
        final trustedHandler = createTrustedLimiter().middleware(
          (request) => Response.ok('OK'),
        );

        final excessiveEntries = List.filled(11, '203.0.113.5').join(', ');

        final response1 = await trustedHandler(
          createRequest(
            ip: '10.0.0.10',
            headers: {'x-forwarded-for': excessiveEntries},
          ),
        );

        final response2 = await trustedHandler(
          createRequest(
            ip: '10.0.0.10',
            headers: {'x-forwarded-for': excessiveEntries},
          ),
        );

        final response3 = await trustedHandler(
          createRequest(
            ip: '10.0.0.10',
            headers: {'x-forwarded-for': excessiveEntries},
          ),
        );

        expect(response1.statusCode, 200);
        expect(response2.statusCode, 200);
        expect(response3.statusCode, 429);
      },
    );

    test('falls back to proxy IP when X-Forwarded-For is invalid', () async {
      final trustedHandler = createTrustedLimiter().middleware(
        (request) => Response.ok('OK'),
      );

      final response1 = await trustedHandler(
        createRequest(
          ip: '10.0.0.10',
          headers: {'x-forwarded-for': 'invalid-ip'},
        ),
      );

      final response2 = await trustedHandler(createRequest(ip: '10.0.0.10'));

      final response3 = await trustedHandler(createRequest(ip: '10.0.0.10'));

      expect(response1.statusCode, 200);
      expect(response2.statusCode, 200);
      expect(response3.statusCode, 429);
    });
  });
}

class FakeHttpConnectionInfo implements HttpConnectionInfo {
  FakeHttpConnectionInfo(this.remoteAddress);

  @override
  final InternetAddress remoteAddress;

  @override
  int get localPort => 8080;

  @override
  int get remotePort => 12345;
}
