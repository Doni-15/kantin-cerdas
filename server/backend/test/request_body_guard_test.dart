import 'dart:async';

import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/server_config.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/request_body_guard.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  ServerConfig createServerConfig({
    int maxRequestBodyBytes = 5,
    int maxConcurrentBodyRequests = 10,
  }) {
    return ServerConfig.fromEnv(
      EnvConfig.fromMap({
        'SERVER_MAX_REQUEST_BODY_BYTES': '$maxRequestBodyBytes',
        'SERVER_MAX_CONCURRENT_BODY_REQUESTS': '$maxConcurrentBodyRequests',
      }),
    );
  }

  Request createRequest({
    String method = 'POST',
    Object? body,
    Map<String, String> headers = const {},
  }) {
    return Request(
      method,
      Uri.parse('http://request.test/'),
      headers: headers,
      body: body,
    );
  }

  Handler createHandler({
    int maxRequestBodyBytes = 5,
    int maxConcurrentBodyRequests = 10,
  }) {
    final middleware = requestBodyGuard(
      serverConfig: createServerConfig(
        maxRequestBodyBytes: maxRequestBodyBytes,
        maxConcurrentBodyRequests: maxConcurrentBodyRequests,
      ),
    );

    return Pipeline().addMiddleware(middleware).addHandler((request) async {
      return Response.ok(await request.readAsString());
    });
  }

  group('Request Body Guard Middleware', () {
    test('accepts a body within the configured limit', () async {
      final response = await createHandler()(
        createRequest(body: 'hello', headers: {'content-length': '5'}),
      );

      expect(response.statusCode, 200);
      expect(await response.readAsString(), 'hello');
    });

    test('accepts a body exactly at the configured limit', () async {
      final response = await createHandler()(
        createRequest(body: '12345', headers: {'content-length': '5'}),
      );

      expect(response.statusCode, 200);
      expect(await response.readAsString(), '12345');
    });

    test('rejects a body exceeding the actual size limit', () async {
      final body = Stream<List<int>>.fromIterable([
        [1, 2, 3],
        [4, 5, 6],
      ]);

      final response = await createHandler()(
        createRequest(body: body, headers: {'transfer-encoding': 'chunked'}),
      );

      expect(response.statusCode, 413);
    });

    test('accepts a chunked body without Content-Length', () async {
      final response = await createHandler()(
        createRequest(body: 'hello', headers: {'transfer-encoding': 'chunked'}),
      );

      expect(response.statusCode, 200);
      expect(await response.readAsString(), 'hello');
    });

    test('rejects invalid Content-Length', () async {
      final response = await createHandler()(
        createRequest(
          body: Stream<List<int>>.value([1, 2, 3, 4, 5]),
          headers: {'content-length': 'invalid'},
        ),
      );

      expect(response.statusCode, 400);
    });

    test('rejects negative Content-Length', () async {
      final response = await createHandler()(
        createRequest(
          body: Stream<List<int>>.value([1, 2, 3, 4, 5]),
          headers: {'content-length': '-1'},
        ),
      );

      expect(response.statusCode, 400);
    });

    test('rejects Content-Length exceeding configured limit', () async {
      final response = await createHandler()(
        createRequest(headers: {'content-length': '6'}),
      );

      expect(response.statusCode, 413);
    });

    test('rejects conflicting Content-Length and Transfer-Encoding', () async {
      final response = await createHandler()(
        createRequest(
          body: 'hello',
          headers: {'content-length': '5', 'transfer-encoding': 'chunked'},
        ),
      );

      expect(response.statusCode, 400);
    });

    test(
      'does not require a concurrency slot for requests without a body',
      () async {
        final firstStarted = Completer<void>();
        final releaseFirst = Completer<void>();

        final middleware = requestBodyGuard(
          serverConfig: createServerConfig(maxConcurrentBodyRequests: 1),
        );

        final handler = Pipeline().addMiddleware(middleware).addHandler((
          request,
        ) async {
          if (request.method == 'GET') {
            return Response.ok('no body');
          }

          firstStarted.complete();
          await releaseFirst.future;
          return Response.ok(await request.readAsString());
        });

        final firstRequest = handler(
          createRequest(body: 'first', headers: {'content-length': '5'}),
        );

        await firstStarted.future;

        final noBodyResponse = await handler(createRequest(method: 'GET'));

        expect(noBodyResponse.statusCode, 200);

        releaseFirst.complete();
        final firstResponse = await firstRequest;

        expect(firstResponse.statusCode, 200);
      },
    );

    test('rejects body requests when concurrency limit is reached', () async {
      final firstStarted = Completer<void>();
      final releaseFirst = Completer<void>();

      final middleware = requestBodyGuard(
        serverConfig: createServerConfig(maxConcurrentBodyRequests: 1),
      );

      final handler = Pipeline().addMiddleware(middleware).addHandler((
        request,
      ) async {
        if (request.method == 'GET') {
          return Response.ok('no body');
        }

        if (!firstStarted.isCompleted) {
          firstStarted.complete();
        }

        await releaseFirst.future;
        return Response.ok(await request.readAsString());
      });

      final firstRequest = handler(
        createRequest(body: 'first', headers: {'content-length': '5'}),
      );

      await firstStarted.future;

      final secondResponse = await handler(
        createRequest(body: 'other', headers: {'content-length': '5'}),
      );

      expect(secondResponse.statusCode, 503);
      expect(secondResponse.headers['retry-after'], '1');

      releaseFirst.complete();
      final firstResponse = await firstRequest;

      expect(firstResponse.statusCode, 200);
    });

    test('releases concurrency slot after handler completes', () async {
      final firstStarted = Completer<void>();
      final releaseFirst = Completer<void>();
      var callCount = 0;

      final middleware = requestBodyGuard(
        serverConfig: createServerConfig(maxConcurrentBodyRequests: 1),
      );

      final handler = Pipeline().addMiddleware(middleware).addHandler((
        request,
      ) async {
        callCount++;

        if (callCount == 1) {
          firstStarted.complete();
          await releaseFirst.future;
        }

        return Response.ok(await request.readAsString());
      });

      final firstRequest = handler(
        createRequest(body: 'first', headers: {'content-length': '5'}),
      );

      await firstStarted.future;
      releaseFirst.complete();

      final firstResponse = await firstRequest;
      expect(firstResponse.statusCode, 200);

      final secondResponse = await handler(
        createRequest(body: 'other', headers: {'content-length': '5'}),
      );

      expect(secondResponse.statusCode, 200);
      expect(await secondResponse.readAsString(), 'other');
    });
  });
}
