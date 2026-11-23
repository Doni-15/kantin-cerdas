import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_parsers.dart';

class SecurityConfig {
  const SecurityConfig._({
    required this.allowedHosts,
    required this.allowAnyHost,
    required this.enableSecurityHeaders,
  });

  final Set<String> allowedHosts;
  final bool allowAnyHost;
  final bool enableSecurityHeaders;

  factory SecurityConfig.fromEnv(EnvConfig env) {
    final hosts = _readAllowedHosts(env['SECURITY_ALLOWED_HOSTS'] ?? '*');

    return SecurityConfig._(
      allowedHosts: Set.unmodifiable(hosts),
      allowAnyHost: hosts.contains('*'),
      enableSecurityHeaders: readEnvBool(
        env,
        'SECURITY_ENABLE_SECURITY_HEADERS',
        defaultValue: true,
      ),
    );
  }

  static List<String> _readAllowedHosts(String rawValue) {
    final value = rawValue.trim();

    if (value.isEmpty) {
      throw const FormatException('SECURITY_ALLOWED_HOSTS tidak boleh kosong.');
    }

    if (value == '*') {
      return const ['*'];
    }

    final hosts = value
        .split(',')
        .map((host) => host.trim().toLowerCase())
        .toList();

    if (hosts.any((host) => host.isEmpty)) {
      throw const FormatException(
        'SECURITY_ALLOWED_HOSTS mengandung entri host kosong.',
      );
    }

    if (hosts.contains('*')) {
      throw const FormatException(
        'Wildcard * tidak boleh digabung dengan host lainnya.',
      );
    }

    const hostPattern = r'^[a-z0-9][a-z0-9.-]*[a-z0-9]$';
    const singleCharacterHostPattern = r'^[a-z0-9]$';
    const ipv6Pattern = r'^\[[0-9a-f:]+\](?::[0-9]{1,5})?$';
    const hostnameWithPortPattern = r'^[a-z0-9][a-z0-9.-]*[a-z0-9]:[0-9]{1,5}$';

    for (final host in hosts) {
      final isValid =
          RegExp(hostPattern).hasMatch(host) ||
          RegExp(singleCharacterHostPattern).hasMatch(host) ||
          RegExp(ipv6Pattern).hasMatch(host) ||
          RegExp(hostnameWithPortPattern).hasMatch(host);

      if (!isValid) {
        throw FormatException(
          'Host tidak valid pada SECURITY_ALLOWED_HOSTS: $host',
        );
      }

      final portSeparator = host.lastIndexOf(':');

      if (portSeparator > 0 &&
          !host.startsWith('[') &&
          portSeparator < host.length - 1) {
        final port = int.tryParse(host.substring(portSeparator + 1));

        if (port == null || port < 1 || port > 65535) {
          throw FormatException(
            'Port host tidak valid pada SECURITY_ALLOWED_HOSTS: $host',
          );
        }
      }

      if (host.startsWith('[')) {
        final closingBracket = host.indexOf(']');
        final suffix = host.substring(closingBracket + 1);

        if (suffix.startsWith(':')) {
          final port = int.tryParse(suffix.substring(1));

          if (port == null || port < 1 || port > 65535) {
            throw FormatException(
              'Port host tidak valid pada SECURITY_ALLOWED_HOSTS: $host',
            );
          }
        }
      }
    }

    if (hosts.toSet().length != hosts.length) {
      throw const FormatException(
        'SECURITY_ALLOWED_HOSTS tidak boleh berisi duplikasi.',
      );
    }

    return hosts;
  }
}
