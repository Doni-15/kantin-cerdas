import 'dart:convert';

import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/logging_config.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/error_handler_middleware.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  group('ErrorHandlerMiddleware', () {
    late List<String> logs;

    LoggingConfig createConfig({
      String level = 'info',
      String format = 'text',
      bool requestEnabled = true,
      bool includeStackTrace = false,
    }) {
      return LoggingConfig.fromEnv(
        EnvConfig.fromMap({
          'LOG_LEVEL': level,
          'LOG_FORMAT': format,
          'LOG_REQUEST_ENABLED': '$requestEnabled',
          'LOG_INCLUDE_STACK_TRACE': '$includeStackTrace',
        }),
      );
    }

    Handler createHandler({
      required Handler innerHandler,
      String level = 'info',
      String format = 'text',
      bool requestEnabled = true,
      bool includeStackTrace = false,
    }) {
      return ErrorHandlerMiddleware(
        config: createConfig(
          level: level,
          format: format,
          requestEnabled: requestEnabled,
          includeStackTrace: includeStackTrace,
        ),
        writer: logs.add,
        clock: () => DateTime.utc(2026, 11, 17, 10),
      ).middleware(innerHandler);
    }

    Request createRequest() {
      return Request('GET', Uri.parse('http://localhost/test'));
    }

    setUp(() {
      logs = [];
    });

    test('converts ApiException into a JSON error response', () async {
      final handler = createHandler(
        innerHandler: (request) async {
          throw ApiException(
            statusCode: 422,
            code: 'VALIDATION_ERROR',
            message: 'Data tidak valid.',
          );
        },
      );

      final response = await handler(createRequest());

      expect(response.statusCode, 422);
      expect(
        response.headers['content-type'],
        'application/json; charset=utf-8',
      );

      final body = jsonDecode(await response.readAsString());

      expect(body['success'], false);
      expect(body['error']['code'], 'VALIDATION_ERROR');
      expect(body['error']['message'], 'Data tidak valid.');
      expect(logs, isEmpty);
    });

    test('converts unknown exceptions into a generic 500 response', () async {
      final handler = createHandler(
        innerHandler: (request) async {
          throw StateError('Sensitive internal detail');
        },
      );

      final response = await handler(createRequest());

      expect(response.statusCode, 500);

      final responseBody = await response.readAsString();
      final body = jsonDecode(responseBody);

      expect(body['success'], false);
      expect(body['error']['code'], 'INTERNAL_SERVER_ERROR');
      expect(
        body['error']['message'],
        'Terjadi kesalahan internal pada server.',
      );
      expect(responseBody, isNot(contains('Sensitive internal detail')));
      expect(responseBody, isNot(contains('StateError')));

      expect(logs, hasLength(1));
      expect(logs.first, contains('ERROR'));
      expect(logs.first, contains('GET'));
      expect(logs.first, contains('/test'));
      expect(logs.first, contains('[500]'));
      expect(logs.first, contains('StateError'));
    });

    test('writes unknown exceptions in JSON format', () async {
      final handler = createHandler(
        format: 'json',
        innerHandler: (request) async {
          throw StateError('Sensitive internal detail');
        },
      );

      await handler(createRequest());

      expect(logs, hasLength(1));

      final event = jsonDecode(logs.first) as Map<String, dynamic>;

      expect(event['timestamp'], '2026-11-17T10:00:00.000Z');
      expect(event['level'], 'error');
      expect(event['method'], 'GET');
      expect(event['path'], '/test');
      expect(event['status'], 500);
      expect(event['exception_type'], 'StateError');
      expect(event.containsKey('stack_trace'), isFalse);
      expect(logs.first, isNot(contains('Sensitive internal detail')));
    });

    test('includes stack trace when enabled', () async {
      final handler = createHandler(
        format: 'json',
        includeStackTrace: true,
        innerHandler: (request) async {
          throw StateError('Sensitive internal detail');
        },
      );

      await handler(createRequest());

      final event = jsonDecode(logs.first) as Map<String, dynamic>;

      expect(event['stack_trace'], isA<String>());
      expect(event['stack_trace'], isNotEmpty);
    });

    test('logs exceptions even when request logging is disabled', () async {
      final handler = createHandler(
        requestEnabled: false,
        innerHandler: (request) async {
          throw StateError('Internal failure');
        },
      );

      final response = await handler(createRequest());

      expect(response.statusCode, 500);
      expect(logs, hasLength(1));
      expect(logs.first, contains('StateError'));
    });

    test('does not modify a normal response', () async {
      final handler = createHandler(
        innerHandler: (request) async {
          return Response.ok('Normal response');
        },
      );

      final response = await handler(createRequest());

      expect(response.statusCode, 200);
      expect(await response.readAsString(), 'Normal response');
      expect(logs, isEmpty);
    });
  });
}
