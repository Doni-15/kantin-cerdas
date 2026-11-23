import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_parsers.dart';

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
      enabled: readEnvBool(env, 'RATE_LIMIT_ENABLED', defaultValue: true),
      maxEntries: readEnvInt(
        env,
        'RATE_LIMIT_MAX_ENTRIES',
        defaultValue: 10000,
        min: 1,
        max: 100000,
      ),
      window: Duration(
        seconds: readEnvInt(
          env,
          'RATE_LIMIT_WINDOW_SECONDS',
          defaultValue: 60,
          min: 1,
          max: 86400,
        ),
      ),
      maxRequests: readEnvInt(
        env,
        'RATE_LIMIT_MAX_REQUESTS',
        defaultValue: 120,
        min: 1,
        max: 1000000,
      ),
      authWindow: Duration(
        seconds: readEnvInt(
          env,
          'AUTH_RATE_LIMIT_WINDOW_SECONDS',
          defaultValue: 60,
          min: 1,
          max: 86400,
        ),
      ),
      authMaxRequests: readEnvInt(
        env,
        'AUTH_RATE_LIMIT_MAX_REQUESTS',
        defaultValue: 15,
        min: 1,
        max: 1000000,
      ),
    );
  }
}
