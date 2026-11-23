import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/security_config.dart';
import 'package:test/test.dart';

void main() {
  group('SecurityConfig', () {
    test('uses expected defaults', () {
      final config = SecurityConfig.fromEnv(EnvConfig.fromMap({}));

      expect(config.allowedHosts, {'*'});
      expect(config.allowAnyHost, isTrue);
      expect(config.enableSecurityHeaders, isTrue);
    });

    test('reads custom security settings', () {
      final config = SecurityConfig.fromEnv(
        EnvConfig.fromMap({
          'SECURITY_ALLOWED_HOSTS': 'localhost,127.0.0.1,api.kantincerdas.id',
          'SECURITY_ENABLE_SECURITY_HEADERS': 'false',
        }),
      );

      expect(config.allowedHosts, {
        'localhost',
        '127.0.0.1',
        'api.kantincerdas.id',
      });
      expect(config.allowAnyHost, isFalse);
      expect(config.enableSecurityHeaders, isFalse);
    });

    test('normalizes host entries', () {
      final config = SecurityConfig.fromEnv(
        EnvConfig.fromMap({
          'SECURITY_ALLOWED_HOSTS': 'LOCALHOST,API.EXAMPLE.COM',
        }),
      );

      expect(config.allowedHosts, {'localhost', 'api.example.com'});
    });

    test('supports host with port', () {
      final config = SecurityConfig.fromEnv(
        EnvConfig.fromMap({'SECURITY_ALLOWED_HOSTS': 'localhost:8080'}),
      );

      expect(config.allowedHosts, {'localhost:8080'});
    });

    test('supports Railway public domain paired with healthcheck host', () {
      final config = SecurityConfig.fromEnv(
        EnvConfig.fromMap({
          'SECURITY_ALLOWED_HOSTS':
              'kantin-cerdas.up.railway.app,healthcheck.railway.app',
        }),
      );

      expect(config.allowAnyHost, isFalse);
      expect(config.allowedHosts, {
        'kantin-cerdas.up.railway.app',
        'healthcheck.railway.app',
      });
    });

    test('rejects empty allowed hosts', () {
      expect(
        () => SecurityConfig.fromEnv(
          EnvConfig.fromMap({'SECURITY_ALLOWED_HOSTS': ''}),
        ),
        throwsFormatException,
      );
    });

    test('rejects wildcard combined with other hosts', () {
      expect(
        () => SecurityConfig.fromEnv(
          EnvConfig.fromMap({'SECURITY_ALLOWED_HOSTS': '*,localhost'}),
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid host entries', () {
      expect(
        () => SecurityConfig.fromEnv(
          EnvConfig.fromMap({
            'SECURITY_ALLOWED_HOSTS': 'localhost,invalid host',
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid host port', () {
      expect(
        () => SecurityConfig.fromEnv(
          EnvConfig.fromMap({'SECURITY_ALLOWED_HOSTS': 'localhost:70000'}),
        ),
        throwsFormatException,
      );
    });
  });
}
