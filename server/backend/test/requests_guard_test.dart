import 'dart:async';

import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/security_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/server_config.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/requests_guard.dart';
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
    final middleware = requestsGuard(
      securityConfig: createSecurityConfig(allowedHosts: allowedHosts),
      serverConfig: createServerConfig(
        maxRequestBodyBytes: maxRequestBodyBytes,
      ),
    );

    return Pipeline().addMiddleware(middleware).addHandler((request) async {
      final body = await request.readAsString();
      return Response.ok(body);
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

  group('Requests Guard Middleware', () {
    test('accepts an allowed host', () async {
      final handler = createHandler();

      final response = await handler(createRequest(body: 'hello'));

      expect(response.statusCode, 200);
      expect(await response.readAsString(), 'hello');
    });

    test('rejects host with port zero', () async {
      final handler = createHandler();

      final response = await handler(createRequest(host: 'api.example.com:0'));

      expect(response.statusCode, 400);
    });

    test('rejects host with port above 65535', () async {
      final handler = createHandler();

      final response = await handler(
        createRequest(host: 'api.example.com:65536'),
      );

      expect(response.statusCode, 400);
    });

    test('rejects host with invalid port format', () async {
      final handler = createHandler();

      final response = await handler(
        createRequest(host: 'api.example.com:abc'),
      );

      expect(response.statusCode, 400);
    });

    test('rejects host containing path', () async {
      final handler = createHandler();

      final response = await handler(
        createRequest(host: 'api.example.com/path'),
      );

      expect(response.statusCode, 400);
    });

    test('rejects host containing user info', () async {
      final handler = createHandler();

      final response = await handler(
        createRequest(host: 'user@api.example.com'),
      );

      expect(response.statusCode, 400);
    });

    test('accepts valid IPv6 host with port', () async {
      final handler = createHandler(allowedHosts: '[::1]:8080');

      final response = await handler(createRequest(host: '[::1]:8080'));

      expect(response.statusCode, 200);
    });

    test('rejects a disallowed host', () async {
      final handler = createHandler();

      final response = await handler(
        createRequest(host: 'evil.example.com', body: 'hello'),
      );

      expect(response.statusCode, 403);
    });

    test('allows configured hostname with a different port', () async {
      final handler = createHandler();

      final response = await handler(
        createRequest(host: 'api.example.com:8080', body: 'hello'),
      );

      expect(response.statusCode, 200);
    });

    test('rejects host with an unconfigured explicit port', () async {
      final handler = createHandler(allowedHosts: 'api.example.com:8080');

      final response = await handler(
        createRequest(host: 'api.example.com:9090', body: 'hello'),
      );

      expect(response.statusCode, 403);
    });

    test('rejects request exceeding Content-Length limit', () async {
      final handler = createHandler(maxRequestBodyBytes: 5);

      final response = await handler(
        createRequest(body: '123456', headers: {'content-length': '6'}),
      );

      expect(response.statusCode, 413);
    });

    test('rejects oversized streamed body', () async {
      final handler = createHandler(maxRequestBodyBytes: 5);

      final body = Stream<List<int>>.fromIterable([
        [1, 2, 3],
        [4, 5, 6],
      ]);

      final response = await handler(createRequest(body: body));

      expect(response.statusCode, 413);
    });

    test('accepts body exactly at configured limit', () async {
      final handler = createHandler(maxRequestBodyBytes: 5);

      final response = await handler(createRequest(body: '12345'));

      expect(response.statusCode, 200);
      expect(await response.readAsString(), '12345');
    });

    test('rejects invalid Content-Length', () async {
      final handler = createHandler();

      final body = Stream<List<int>>.value([1, 2, 3, 4, 5]);

      final response = await handler(
        createRequest(body: body, headers: {'content-length': 'invalid'}),
      );

      expect(response.statusCode, 400);
    });
  });
}
