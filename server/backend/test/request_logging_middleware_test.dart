import 'dart:convert';

import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/logging_config.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/request_logging_middleware.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  group('RequestLoggingMiddleware', () {
    late List<String> logs;
    late DateTime currentTime;

    LoggingConfig createConfig({
      String level = 'info',
      String format = 'text',
      bool enabled = true,
      bool includeStackTrace = false,
    }) {
      return LoggingConfig.fromEnv(
        EnvConfig.fromMap({
          'LOG_LEVEL': level,
          'LOG_FORMAT': format,
          'LOG_REQUEST_ENABLED': '$enabled',
          'LOG_INCLUDE_STACK_TRACE': '$includeStackTrace',
        }),
      );
    }

    Handler createHandler({
      required LoggingConfig config,
      required Handler innerHandler,
    }) {
      return RequestLoggingMiddleware(
        config: config,
        writer: logs.add,
        clock: () => currentTime,
      ).middleware(innerHandler);
    }

    Request createRequest({String method = 'GET', String path = '/v1/health'}) {
      return Request(method, Uri.parse('http://localhost$path'));
    }

    setUp(() {
      logs = [];
      currentTime = DateTime.utc(2026, 11, 17, 10);
    });

    test('logs successful request in text format', () async {
      final handler = createHandler(
        config: createConfig(),
        innerHandler: (request) => Response.ok('OK'),
      );

      final response = await handler(createRequest());

      expect(response.statusCode, 200);
      expect(logs, hasLength(1));
      expect(logs.first, contains('INFO'));
      expect(logs.first, contains('GET'));
      expect(logs.first, contains('/v1/health'));
      expect(logs.first, contains('[200]'));
    });

    test('logs warning for client error', () async {
      final handler = createHandler(
        config: createConfig(),
        innerHandler: (request) => Response.notFound('Not found'),
      );

      await handler(createRequest());

      expect(logs, hasLength(1));
      expect(logs.first, contains('WARNING'));
      expect(logs.first, contains('[404]'));
    });

    test('logs error for server error', () async {
      final handler = createHandler(
        config: createConfig(),
        innerHandler: (request) => Response.internalServerError(),
      );

      await handler(createRequest());

      expect(logs, hasLength(1));
      expect(logs.first, contains('ERROR'));
      expect(logs.first, contains('[500]'));
    });

    test('writes valid JSON log', () async {
      final handler = createHandler(
        config: createConfig(format: 'json'),
        innerHandler: (request) => Response.ok('OK'),
      );

      await handler(createRequest());

      final event = jsonDecode(logs.first) as Map<String, dynamic>;

      expect(event['level'], 'info');
      expect(event['method'], 'GET');
      expect(event['path'], '/v1/health');
      expect(event['status'], 200);
      expect(event['duration_ms'], isA<int>());
    });

    test('filters logs according to configured level', () async {
      final handler = createHandler(
        config: createConfig(level: 'warning'),
        innerHandler: (request) => Response.ok('OK'),
      );

      await handler(createRequest());

      expect(logs, isEmpty);
    });

    test('logs warning and error at warning level', () async {
      final handler = createHandler(
        config: createConfig(level: 'warning'),
        innerHandler: (request) => Response.notFound('Not found'),
      );

      await handler(createRequest());

      expect(logs, hasLength(1));
      expect(logs.first, contains('WARNING'));
    });

    test('does not log when request logging is disabled', () async {
      final handler = createHandler(
        config: createConfig(enabled: false),
        innerHandler: (request) => Response.ok('OK'),
      );

      await handler(createRequest());

      expect(logs, isEmpty);
    });

    test('logs exception and rethrows it', () async {
      final handler = createHandler(
        config: createConfig(),
        innerHandler: (request) {
          throw StateError('Test exception');
        },
      );

      await expectLater(handler(createRequest()), throwsA(isA<StateError>()));

      expect(logs, hasLength(1));
      expect(logs.first, contains('ERROR'));
      expect(logs.first, contains('StateError'));
    });

    test('includes stack trace when enabled', () async {
      final handler = createHandler(
        config: createConfig(format: 'json', includeStackTrace: true),
        innerHandler: (request) {
          throw StateError('Test exception');
        },
      );

      await expectLater(handler(createRequest()), throwsA(isA<StateError>()));

      expect(logs, hasLength(1));

      final event = jsonDecode(logs.first) as Map<String, dynamic>;

      expect(event['level'], 'error');
      expect(event['exception_type'], 'StateError');
      expect(event['stack_trace'], isNotEmpty);
    });

    test('does not expose query parameters in logs', () async {
      final handler = createHandler(
        config: createConfig(),
        innerHandler: (request) => Response.ok('OK'),
      );

      await handler(createRequest(path: '/v1/users?token=secret-value'));

      expect(logs, hasLength(1));
      expect(logs.first, isNot(contains('secret-value')));
      expect(logs.first, isNot(contains('token')));
    });
  });
}
