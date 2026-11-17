import 'dart:io';

import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';

class ProxyConfig {
  const ProxyConfig._({required this.trustedProxyIps});

  /// IP address dari reverse proxy yang memang dipercaya.
  final Set<String> trustedProxyIps;

  factory ProxyConfig.fromEnv(EnvConfig env) {
    final rawValue = env['TRUSTED_PROXY_IPS']?.trim() ?? '';

    if (rawValue.isEmpty) {
      return const ProxyConfig._(trustedProxyIps: {});
    }

    final entries = rawValue.split(',').map((value) => value.trim()).toList();

    if (entries.any((entry) => entry.isEmpty)) {
      throw const FormatException(
        'TRUSTED_PROXY_IPS mengandung entri IP kosong.',
      );
    }

    final trustedIps = <String>{};

    for (final entry in entries) {
      final address = InternetAddress.tryParse(entry);

      if (address == null) {
        throw FormatException(
          'Alamat IP tidak valid pada TRUSTED_PROXY_IPS: $entry',
        );
      }

      final normalizedIp = address.address;

      if (!trustedIps.add(normalizedIp)) {
        throw FormatException(
          'TRUSTED_PROXY_IPS tidak boleh berisi duplikasi: $entry',
        );
      }
    }

    return ProxyConfig._(trustedProxyIps: Set.unmodifiable(trustedIps));
  }
}
