import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';

class ServerConfig {
  const ServerConfig._({
    required this.host,
    required this.port,
    required this.apiPrefix,
    required this.requestTimeout,
    required this.shutdownTimeout,
    required this.maxRequestBodyBytes,
    required this.maxConcurrentBodyRequests,
  });

  final String host;
  final int port;
  final String apiPrefix;

  final Duration requestTimeout;
  final Duration shutdownTimeout;

  final int maxRequestBodyBytes;
  final int maxConcurrentBodyRequests;

  factory ServerConfig.fromEnv(EnvConfig env) {
    final host = _readString(env, 'SERVER_HOST', defaultValue: '0.0.0.0');

    if (host.contains(RegExp(r'\s'))) {
      throw const FormatException(
        'SERVER_HOST tidak boleh mengandung whitespace.',
      );
    }

    return ServerConfig._(
      host: host,
      port: _readInt(
        env,
        'SERVER_PORT',
        defaultValue: 8080,
        min: 1,
        max: 65535,
      ),
      apiPrefix: _normalizeApiPrefix(
        _readString(env, 'API_PREFIX', defaultValue: '/v1'),
      ),
      requestTimeout: Duration(
        seconds: _readInt(
          env,
          'SERVER_REQUEST_TIMEOUT_SECONDS',
          defaultValue: 30,
          min: 1,
          max: 3600,
        ),
      ),
      shutdownTimeout: Duration(
        seconds: _readInt(
          env,
          'SERVER_SHUTDOWN_TIMEOUT_SECONDS',
          defaultValue: 30,
          min: 1,
          max: 3600,
        ),
      ),
      maxRequestBodyBytes: _readInt(
        env,
        'SERVER_MAX_REQUEST_BODY_BYTES',
        defaultValue: 10485760,
        min: 1,
        max: 10485760,
      ),
      maxConcurrentBodyRequests: _readInt(
        env,
        'SERVER_MAX_CONCURRENT_BODY_REQUESTS',
        defaultValue: 10,
        min: 1,
        max: 100,
      ),
    );
  }

  static String _readString(
    EnvConfig env,
    String key, {
    required String defaultValue,
  }) {
    final value = env[key]?.trim();

    if (value == null || value.isEmpty) {
      return defaultValue;
    }

    return value;
  }

  static int _readInt(
    EnvConfig env,
    String key, {
    required int defaultValue,
    required int min,
    required int max,
  }) {
    final rawValue = env[key];

    if (rawValue == null || rawValue.trim().isEmpty) {
      return defaultValue;
    }

    final value = int.tryParse(rawValue.trim());

    if (value == null || value < min || value > max) {
      throw FormatException('$key harus berupa angka antara $min dan $max.');
    }

    return value;
  }

  static String _normalizeApiPrefix(String value) {
    var prefix = value.trim();

    if (prefix.isEmpty) {
      prefix = '/v1';
    }

    if (!prefix.startsWith('/')) {
      prefix = '/$prefix';
    }

    while (prefix.length > 1 && prefix.endsWith('/')) {
      prefix = prefix.substring(0, prefix.length - 1);
    }

    if (prefix.contains('//') || prefix.contains(RegExp(r'[\s?#]'))) {
      throw const FormatException(
        'API_PREFIX tidak valid. Gunakan path seperti /v1.',
      );
    }

    return prefix;
  }
}
