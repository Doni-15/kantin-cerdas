import 'dart:async';

import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/security_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/server_config.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/request_header_guard.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  SecurityConfig createSecurityConfig({
    String allowedHosts = 'api.example.com',
  }) {
    return SecurityConfig.fromEnv(
      EnvConfig.fromMap({'SECURITY_ALLOWED_HOSTS': allowedHosts}),
    );
  }

  ServerConfig createServerConfig({int maxRequestBodyBytes = 5}) {
    return ServerConfig.fromEnv(
      EnvConfig.fromMap({
        'SERVER_MAX_REQUEST_BODY_BYTES': '$maxRequestBodyBytes',
      }),
    );
  }

  Handler createHandler({
    String allowedHosts = 'api.example.com',
    int maxRequestBodyBytes = 5,
  }) {
    final middleware = requestHeaderGuard(
      securityConfig: createSecurityConfig(allowedHosts: allowedHosts),
      serverConfig: createServerConfig(
        maxRequestBodyBytes: maxRequestBodyBytes,
      ),
    );

    return Pipeline().addMiddleware(middleware).addHandler((request) async {
      return Response.ok('accepted');
    });
  }

  Request createRequest({
    String method = 'POST',
    String host = 'api.example.com',
    Object? body,
    Map<String, String> headers = const {},
  }) {
    return Request(
      method,
      Uri.parse('http://request.test/'),
      headers: {'host': host, ...headers},
      body: body,
    );
  }

  group('Request Header Guard Middleware', () {
    test('accepts an allowed host', () async {
      final response = await createHandler()(createRequest(body: 'hello'));

      expect(response.statusCode, 200);
    });

    test('rejects missing Host header', () async {
      final request = Request('GET', Uri.parse('http://request.test/'));

      final response = await createHandler()(request);

      expect(response.statusCode, 400);
    });

    test('rejects empty Host header', () async {
      final response = await createHandler()(createRequest(host: '  '));

      expect(response.statusCode, 400);
    });

    test('rejects host with port zero', () async {
      final response = await createHandler()(
        createRequest(host: 'api.example.com:0'),
      );

      expect(response.statusCode, 400);
    });

    test('rejects host with port above 65535', () async {
      final response = await createHandler()(
        createRequest(host: 'api.example.com:65536'),
      );

      expect(response.statusCode, 400);
    });

    test('rejects host with invalid port format', () async {
      final response = await createHandler()(
        createRequest(host: 'api.example.com:abc'),
      );

      expect(response.statusCode, 400);
    });

    test('rejects host containing path', () async {
      final response = await createHandler()(
        createRequest(host: 'api.example.com/path'),
      );

      expect(response.statusCode, 400);
    });

    test('rejects host containing user info', () async {
      final response = await createHandler()(
        createRequest(host: 'user@api.example.com'),
      );

      expect(response.statusCode, 400);
    });

    test('accepts valid IPv6 host with port', () async {
      final response = await createHandler(allowedHosts: '[::1]:8080')(
        createRequest(host: '[::1]:8080'),
      );

      expect(response.statusCode, 200);
    });

    test('rejects a disallowed host', () async {
      final response = await createHandler()(
        createRequest(host: 'evil.example.com'),
      );

      expect(response.statusCode, 403);
    });

    test(
      'allows Railway healthcheck host only when explicitly configured',
      () async {
        final strictHandler = createHandler(
          allowedHosts: 'kantin-cerdas.up.railway.app,healthcheck.railway.app',
        );

        final healthcheckResponse = await strictHandler(
          Request(
            'GET',
            Uri.parse('http://request.test/v1/health'),
            headers: const {'host': 'healthcheck.railway.app'},
          ),
        );
        final publicResponse = await strictHandler(
          Request(
            'GET',
            Uri.parse('http://request.test/v1/health'),
            headers: const {'host': 'kantin-cerdas.up.railway.app'},
          ),
        );
        final untrustedResponse = await strictHandler(
          Request(
            'GET',
            Uri.parse('http://request.test/v1/health'),
            headers: const {'host': 'evil.example.com'},
          ),
        );

        expect(healthcheckResponse.statusCode, 200);
        expect(publicResponse.statusCode, 200);
        expect(untrustedResponse.statusCode, 403);

        // Does not weaken Host enforcement globally when healthcheck host is omitted.
        final withoutHealthcheckHost = createHandler(
          allowedHosts: 'kantin-cerdas.up.railway.app',
        );
        final omittedResponse = await withoutHealthcheckHost(
          Request(
            'GET',
            Uri.parse('http://request.test/v1/health'),
            headers: const {'host': 'healthcheck.railway.app'},
          ),
        );
        expect(omittedResponse.statusCode, 403);
      },
    );

    test('allows configured hostname with a different port', () async {
      final response = await createHandler()(
        createRequest(host: 'api.example.com:8080'),
      );

      expect(response.statusCode, 200);
    });

    test('rejects host with an unconfigured explicit port', () async {
      final response = await createHandler(
        allowedHosts: 'api.example.com:8080',
      )(createRequest(host: 'api.example.com:9090'));

      expect(response.statusCode, 403);
    });

    test('rejects Content-Length exceeding configured limit', () async {
      final response = await createHandler()(
        createRequest(headers: {'content-length': '6'}),
      );

      expect(response.statusCode, 413);
    });

    test('rejects invalid Content-Length', () async {
      final response = await createHandler()(
        createRequest(headers: {'content-length': 'invalid'}),
      );

      expect(response.statusCode, 400);
    });

    test('rejects negative Content-Length', () async {
      final response = await createHandler()(
        createRequest(headers: {'content-length': '-1'}),
      );

      expect(response.statusCode, 400);
    });

    test('accepts Content-Length exactly at configured limit', () async {
      final response = await createHandler()(
        createRequest(headers: {'content-length': '5'}),
      );

      expect(response.statusCode, 200);
    });

    test('does not consume the request body stream', () async {
      var streamListened = false;

      final body = Stream<List<int>>.multi((controller) {
        streamListened = true;
        controller.add([1, 2, 3]);
        controller.close();
      });

      final response = await createHandler()(createRequest(body: body));

      expect(response.statusCode, 200);
      expect(streamListened, isFalse);
    });
  });
}
