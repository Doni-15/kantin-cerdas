import 'dart:async';

import 'package:kantin_cerdas_backend/src/core/middleware/request_timeout_middleware.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  group('RequestTimeoutMiddleware', () {
    Handler createHandler({
      required Duration timeout,
      required Handler innerHandler,
    }) {
      return Pipeline()
          .addMiddleware(requestTimeoutMiddleware(timeout))
          .addHandler(innerHandler);
    }

    Request createRequest() {
      return Request('GET', Uri.parse('http://localhost/v1/test'));
    }

    test('allows request completed before timeout', () async {
      final handler = createHandler(
        timeout: const Duration(seconds: 1),
        innerHandler: (request) async {
          await Future<void>.delayed(const Duration(milliseconds: 10));

          return Response.ok('Success');
        },
      );

      final response = await handler(createRequest());

      expect(response.statusCode, 200);
      expect(await response.readAsString(), 'Success');
    });

    test('returns 408 when request exceeds timeout', () async {
      final handler = createHandler(
        timeout: const Duration(milliseconds: 20),
        innerHandler: (request) async {
          await Future<void>.delayed(const Duration(milliseconds: 200));

          return Response.ok('Too late');
        },
      );

      final response = await handler(createRequest());

      expect(response.statusCode, 408);
      final body = await response.readAsString();
      expect(body, contains('"success":false'));
      expect(body, contains('"code":"REQUEST_TIMEOUT"'));
      expect(
        body,
        contains('"message":"Waktu pemrosesan request telah habis."'),
      );
    });

    test('does not cancel the underlying asynchronous operation', () async {
      final operation = Completer<Response>();

      final handler = createHandler(
        timeout: const Duration(milliseconds: 20),
        innerHandler: (request) => operation.future,
      );

      final response = await handler(createRequest());

      expect(response.statusCode, 408);
      expect(operation.isCompleted, false);

      operation.complete(Response.ok('Operation completed'));

      final originalResponse = await operation.future;

      expect(originalResponse.statusCode, 200);
    });

    test('propagates handler errors before timeout', () async {
      final handler = createHandler(
        timeout: const Duration(seconds: 1),
        innerHandler: (request) {
          throw StateError('Test handler error');
        },
      );

      await expectLater(handler(createRequest()), throwsA(isA<StateError>()));
    });

    test('rejects zero timeout configuration', () {
      expect(
        () => requestTimeoutMiddleware(Duration.zero),
        throwsArgumentError,
      );
    });

    test('rejects negative timeout configuration', () {
      expect(
        () => requestTimeoutMiddleware(const Duration(seconds: -1)),
        throwsArgumentError,
      );
    });
  });
}
