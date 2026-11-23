import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_parsers.dart';

class AuthConfig {
  const AuthConfig._({
    required this.jwksUrl,
    required this.issuer,
    required this.audience,
    required this.allowedAlgorithms,
    required this.jwksCacheTtl,
    required this.clockSkew,
    required this.requireEmailVerified,
    required this.webOrigin,
    required this.googleEnabled,
    required this.googleProductionVerified,
    required this.recoveryLinkTtlSeconds,
  });

  final Uri jwksUrl;
  final Uri issuer;
  final String audience;
  final List<String> allowedAlgorithms;
  final Duration jwksCacheTtl;
  final Duration clockSkew;
  final bool requireEmailVerified;
  final String? webOrigin;
  final bool googleEnabled;
  final bool googleProductionVerified;
  final int recoveryLinkTtlSeconds;

  factory AuthConfig.fromEnv(
    EnvConfig env, {
    Uri? projectUrl,
    bool allowLocal = false,
    bool allowGoogle = true,
  }) {
    final jwksUrl = _readHttpsUrl(
      env,
      'AUTH_JWKS_URL',
      fallback: projectUrl?.resolve('/auth/v1/.well-known/jwks.json'),
      allowLocal: allowLocal,
    );
    final issuer = _readHttpsUrl(
      env,
      'AUTH_JWT_ISSUER',
      fallback: projectUrl?.resolve('/auth/v1'),
      allowLocal: allowLocal,
    );
    final audience = _readRequiredString(env, 'AUTH_JWT_AUDIENCE');

    final algorithms = _readAlgorithms(
      env['AUTH_JWT_ALLOWED_ALGORITHMS'] ?? (allowLocal ? 'HS256' : 'ES256'),
      allowLocal: allowLocal,
    );

    return AuthConfig._(
      jwksUrl: jwksUrl,
      issuer: issuer,
      audience: audience,
      allowedAlgorithms: List.unmodifiable(algorithms),
      jwksCacheTtl: Duration(
        seconds: readEnvInt(
          env,
          'AUTH_JWKS_CACHE_TTL_SECONDS',
          defaultValue: 3600,
          min: 1,
          max: 86400,
        ),
      ),
      clockSkew: Duration(
        seconds: readEnvInt(
          env,
          'AUTH_CLOCK_SKEW_SECONDS',
          defaultValue: 30,
          min: 0,
          max: 300,
        ),
      ),
      requireEmailVerified: readEnvBool(
        env,
        'AUTH_REQUIRE_EMAIL_VERIFIED',
        defaultValue: false,
      ),
      webOrigin: _readWebOrigin(env),
      googleEnabled:
          readEnvBool(env, 'AUTH_GOOGLE_ENABLED', defaultValue: false) &&
          allowGoogle,
      googleProductionVerified: readEnvBool(
        env,
        'AUTH_GOOGLE_PRODUCTION_VERIFIED',
        defaultValue: false,
      ),
      recoveryLinkTtlSeconds: readEnvInt(
        env,
        'AUTH_RECOVERY_LINK_TTL_SECONDS',
        defaultValue: 3600,
        min: 1,
        max: 86400,
      ),
    );
  }

  static String? _readWebOrigin(EnvConfig env) {
    final value = env['AUTH_WEB_ORIGIN']?.trim();
    if (value == null || value.isEmpty) return null;
    final uri = _readHttpsUrl(env, 'AUTH_WEB_ORIGIN');
    if ((uri.path.isNotEmpty && uri.path != '/') ||
        RegExp(r'[\s,]').hasMatch(value)) {
      throw const FormatException(
        'AUTH_WEB_ORIGIN harus berupa origin HTTPS tanpa path.',
      );
    }
    return uri.origin;
  }

  static String _readRequiredString(EnvConfig env, String key) {
    final value = env[key]?.trim();

    if (value == null || value.isEmpty) {
      throw FormatException('$key wajib diisi.');
    }

    return value;
  }

  static Uri _readHttpsUrl(
    EnvConfig env,
    String key, {
    Uri? fallback,
    bool allowLocal = false,
  }) {
    final value = env[key]?.trim();
    if (value == null || value.isEmpty) {
      if (fallback != null) return fallback;
      throw FormatException('$key wajib diisi.');
    }
    final uri = Uri.tryParse(value);

    if (uri == null ||
        (uri.scheme != 'https' &&
            !(allowLocal && uri.scheme == 'http' && uri.host == '127.0.0.1')) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw FormatException('$key harus berupa HTTPS URL yang valid.');
    }

    return uri;
  }

  static List<String> _readAlgorithms(
    String value, {
    required bool allowLocal,
  }) {
    final supportedAlgorithms = {'ES256', 'RS256', if (allowLocal) 'HS256'};

    final algorithms = value
        .split(',')
        .map((algorithm) => algorithm.trim().toUpperCase())
        .where((algorithm) => algorithm.isNotEmpty)
        .toList();

    if (algorithms.isEmpty) {
      throw const FormatException(
        'AUTH_JWT_ALLOWED_ALGORITHMS tidak boleh kosong.',
      );
    }

    if (algorithms.toSet().length != algorithms.length) {
      throw const FormatException(
        'AUTH_JWT_ALLOWED_ALGORITHMS tidak boleh berisi duplikasi.',
      );
    }

    for (final algorithm in algorithms) {
      if (!supportedAlgorithms.contains(algorithm)) {
        throw FormatException('Algoritma JWT tidak didukung: $algorithm.');
      }
    }

    return algorithms;
  }
}
