import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/server_config.dart';
import 'package:test/test.dart';

void main() {
  group('ServerConfig', () {
    test('uses expected development defaults', () {
      final config = ServerConfig.fromEnv(EnvConfig.fromMap({}));
      expect(config.host, '0.0.0.0');
      expect(config.port, 8080);
      expect(config.apiPrefix, '/v1');
      expect(config.requestTimeout, const Duration(seconds: 30));
      expect(config.shutdownTimeout, const Duration(seconds: 30));
      expect(config.maxRequestBodyBytes, 10485760);
      expect(config.maxConcurrentBodyRequests, 10);
    });

    test('accepts maximum request body limit of 10 MiB', () {
      final config = ServerConfig.fromEnv(
        EnvConfig.fromMap({'SERVER_MAX_REQUEST_BODY_BYTES': '10485760'}),
      );

      expect(config.maxRequestBodyBytes, 10485760);
    });

    test('rejects request body limit above 10 MiB', () {
      expect(
        () => ServerConfig.fromEnv(
          EnvConfig.fromMap({'SERVER_MAX_REQUEST_BODY_BYTES': '10485761'}),
        ),
        throwsFormatException,
      );
    });

    test('rejects concurrent body request limit above 100', () {
      expect(
        () => ServerConfig.fromEnv(
          EnvConfig.fromMap({'SERVER_MAX_CONCURRENT_BODY_REQUESTS': '101'}),
        ),
        throwsFormatException,
      );
    });

    test('reads all server environment values', () {
      final config = ServerConfig.fromEnv(
        EnvConfig.fromMap({
          'SERVER_HOST': '127.0.0.1',
          'SERVER_PORT': '9090',
          'API_PREFIX': '/api/v2',
          'SERVER_REQUEST_TIMEOUT_SECONDS': '45',
          'SERVER_SHUTDOWN_TIMEOUT_SECONDS': '20',
          'SERVER_MAX_REQUEST_BODY_BYTES': '5242880',
          'SERVER_MAX_CONCURRENT_BODY_REQUESTS': '20',
        }),
      );

      expect(config.host, '127.0.0.1');
      expect(config.port, 9090);
      expect(config.apiPrefix, '/api/v2');
      expect(config.requestTimeout, const Duration(seconds: 45));
      expect(config.shutdownTimeout, const Duration(seconds: 20));
      expect(config.maxRequestBodyBytes, 5242880);
      expect(config.maxConcurrentBodyRequests, 20);
    });

    test('normalizes API prefix', () {
      final config = ServerConfig.fromEnv(
        EnvConfig.fromMap({'API_PREFIX': 'api/v2/'}),
      );

      expect(config.apiPrefix, '/api/v2');
    });

    test('rejects invalid port', () {
      expect(
        () => ServerConfig.fromEnv(EnvConfig.fromMap({'SERVER_PORT': '70000'})),
        throwsFormatException,
      );
    });

    test('rejects non-numeric timeout', () {
      expect(
        () => ServerConfig.fromEnv(
          EnvConfig.fromMap({'SERVER_REQUEST_TIMEOUT_SECONDS': 'thirty'}),
        ),
        throwsFormatException,
      );
    });

    test('rejects zero request body limit', () {
      expect(
        () => ServerConfig.fromEnv(
          EnvConfig.fromMap({'SERVER_MAX_REQUEST_BODY_BYTES': '0'}),
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid API prefix', () {
      expect(
        () =>
            ServerConfig.fromEnv(EnvConfig.fromMap({'API_PREFIX': '/api//v1'})),
        throwsFormatException,
      );
    });

    test('rejects host containing whitespace', () {
      expect(
        () => ServerConfig.fromEnv(
          EnvConfig.fromMap({'SERVER_HOST': '0.0.0.0 invalid'}),
        ),
        throwsFormatException,
      );
    });
  });
}
