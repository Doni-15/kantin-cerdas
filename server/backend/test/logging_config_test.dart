import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/logging_config.dart';
import 'package:test/test.dart';

void main() {
  group('LoggingConfig', () {
    test('uses expected defaults', () {
      final config = LoggingConfig.fromEnv(EnvConfig.fromMap({}));

      expect(config.level, 'info');
      expect(config.format, 'text');
      expect(config.isTextFormat, isTrue);
      expect(config.isJsonFormat, isFalse);
      expect(config.requestEnabled, isTrue);
      expect(config.includeStackTrace, isFalse);
    });

    test('reads custom logging settings', () {
      final config = LoggingConfig.fromEnv(
        EnvConfig.fromMap({
          'LOG_LEVEL': 'DEBUG',
          'LOG_FORMAT': 'JSON',
          'LOG_REQUEST_ENABLED': 'false',
          'LOG_INCLUDE_STACK_TRACE': 'true',
        }),
      );

      expect(config.level, 'debug');
      expect(config.format, 'json');
      expect(config.isJsonFormat, isTrue);
      expect(config.isTextFormat, isFalse);
      expect(config.requestEnabled, isFalse);
      expect(config.includeStackTrace, isTrue);
    });

    test('accepts all supported log levels', () {
      for (final level in ['debug', 'info', 'warning', 'error']) {
        final config = LoggingConfig.fromEnv(
          EnvConfig.fromMap({'LOG_LEVEL': level}),
        );

        expect(config.level, level);
      }
    });

    test('rejects unsupported log level', () {
      expect(
        () =>
            LoggingConfig.fromEnv(EnvConfig.fromMap({'LOG_LEVEL': 'verbose'})),
        throwsFormatException,
      );
    });

    test('rejects unsupported log format', () {
      expect(
        () => LoggingConfig.fromEnv(EnvConfig.fromMap({'LOG_FORMAT': 'xml'})),
        throwsFormatException,
      );
    });

    test('rejects invalid request logging boolean', () {
      expect(
        () => LoggingConfig.fromEnv(
          EnvConfig.fromMap({'LOG_REQUEST_ENABLED': 'yes'}),
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid stack trace boolean', () {
      expect(
        () => LoggingConfig.fromEnv(
          EnvConfig.fromMap({'LOG_INCLUDE_STACK_TRACE': '1'}),
        ),
        throwsFormatException,
      );
    });

    test('normalizes log level and format', () {
      final config = LoggingConfig.fromEnv(
        EnvConfig.fromMap({'LOG_LEVEL': ' WARNING ', 'LOG_FORMAT': ' JSON '}),
      );

      expect(config.level, 'warning');
      expect(config.format, 'json');
    });
  });
}
