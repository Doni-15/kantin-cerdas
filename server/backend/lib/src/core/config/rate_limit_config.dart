import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';

class RateLimitConfig {
  const RateLimitConfig._({
    required this.enabled,
    required this.maxEntries,
    required this.window,
    required this.maxRequests,
    required this.authWindow,
    required this.authMaxRequests,
  });

  final bool enabled;
  final int maxEntries;
  final Duration window;
  final int maxRequests;

  final Duration authWindow;
  final int authMaxRequests;

  factory RateLimitConfig.fromEnv(EnvConfig env) {
    return RateLimitConfig._(
      enabled: _readBool(env, 'RATE_LIMIT_ENABLED', defaultValue: true),
      maxEntries: _readInt(
        env,
        'RATE_LIMIT_MAX_ENTRIES',
        defaultValue: 10000,
        min: 1,
        max: 100000,
      ),
      window: Duration(
        seconds: _readInt(
          env,
          'RATE_LIMIT_WINDOW_SECONDS',
          defaultValue: 60,
          min: 1,
          max: 86400,
        ),
      ),
      maxRequests: _readInt(
        env,
        'RATE_LIMIT_MAX_REQUESTS',
        defaultValue: 120,
        min: 1,
        max: 1000000,
      ),
      authWindow: Duration(
        seconds: _readInt(
          env,
          'AUTH_RATE_LIMIT_WINDOW_SECONDS',
          defaultValue: 60,
          min: 1,
          max: 86400,
        ),
      ),
      authMaxRequests: _readInt(
        env,
        'AUTH_RATE_LIMIT_MAX_REQUESTS',
        defaultValue: 15,
        min: 1,
        max: 1000000,
      ),
    );
  }

  static bool _readBool(
    EnvConfig env,
    String key, {
    required bool defaultValue,
  }) {
    final rawValue = env[key];

    if (rawValue == null || rawValue.trim().isEmpty) {
      return defaultValue;
    }

    switch (rawValue.trim().toLowerCase()) {
      case 'true':
        return true;
      case 'false':
        return false;
      default:
        throw FormatException('$key harus bernilai true atau false.');
    }
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
}
