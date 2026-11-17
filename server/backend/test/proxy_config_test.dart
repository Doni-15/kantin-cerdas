import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/proxy_config.dart';
import 'package:test/test.dart';

void main() {
  group('ProxyConfig', () {
    test('uses empty trusted proxy list by default', () {
      final config = ProxyConfig.fromEnv(EnvConfig.fromMap({}));

      expect(config.trustedProxyIps, isEmpty);
    });

    test('accepts trusted IPv4 addresses', () {
      final config = ProxyConfig.fromEnv(
        EnvConfig.fromMap({'TRUSTED_PROXY_IPS': '127.0.0.1,10.0.0.10'}),
      );

      expect(config.trustedProxyIps, {'127.0.0.1', '10.0.0.10'});
    });

    test('accepts trusted IPv6 addresses', () {
      final config = ProxyConfig.fromEnv(
        EnvConfig.fromMap({'TRUSTED_PROXY_IPS': '::1'}),
      );

      expect(config.trustedProxyIps, {'::1'});
    });

    test('normalizes IP addresses', () {
      final config = ProxyConfig.fromEnv(
        EnvConfig.fromMap({'TRUSTED_PROXY_IPS': ' 127.0.0.1 , 10.0.0.10 '}),
      );

      expect(config.trustedProxyIps, {'127.0.0.1', '10.0.0.10'});
    });

    test('returns an unmodifiable set', () {
      final config = ProxyConfig.fromEnv(
        EnvConfig.fromMap({'TRUSTED_PROXY_IPS': '127.0.0.1'}),
      );

      expect(
        () => config.trustedProxyIps.add('10.0.0.10'),
        throwsUnsupportedError,
      );
    });

    test('rejects hostnames', () {
      expect(
        () => ProxyConfig.fromEnv(
          EnvConfig.fromMap({'TRUSTED_PROXY_IPS': 'localhost'}),
        ),
        throwsFormatException,
      );
    });

    test('rejects CIDR notation', () {
      expect(
        () => ProxyConfig.fromEnv(
          EnvConfig.fromMap({'TRUSTED_PROXY_IPS': '192.168.1.0/24'}),
        ),
        throwsFormatException,
      );
    });

    test('rejects empty entries', () {
      expect(
        () => ProxyConfig.fromEnv(
          EnvConfig.fromMap({'TRUSTED_PROXY_IPS': '127.0.0.1,,10.0.0.10'}),
        ),
        throwsFormatException,
      );
    });

    test('rejects duplicate addresses', () {
      expect(
        () => ProxyConfig.fromEnv(
          EnvConfig.fromMap({'TRUSTED_PROXY_IPS': '127.0.0.1,127.0.0.1'}),
        ),
        throwsFormatException,
      );
    });
  });
}
