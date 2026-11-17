import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';

class AuthConfig {
  const AuthConfig._({
    required this.jwksUrl,
    required this.issuer,
    required this.audience,
    required this.allowedAlgorithms,
    required this.jwksCacheTtl,
    required this.clockSkew,
    required this.requireEmailVerified,
  });

  final Uri jwksUrl;
  final Uri issuer;
  final String audience;
  final List<String> allowedAlgorithms;
  final Duration jwksCacheTtl;
  final Duration clockSkew;
  final bool requireEmailVerified;

  factory AuthConfig.fromEnv(EnvConfig env) {
    final jwksUrl = _readHttpsUrl(env, 'AUTH_JWKS_URL');
    final issuer = _readHttpsUrl(env, 'AUTH_JWT_ISSUER');
    final audience = _readRequiredString(env, 'AUTH_JWT_AUDIENCE');

    final algorithms = _readAlgorithms(
      env['AUTH_JWT_ALLOWED_ALGORITHMS'] ?? 'ES256',
    );

    return AuthConfig._(
      jwksUrl: jwksUrl,
      issuer: issuer,
      audience: audience,
      allowedAlgorithms: List.unmodifiable(algorithms),
      jwksCacheTtl: Duration(
        seconds: _readInt(
          env,
          'AUTH_JWKS_CACHE_TTL_SECONDS',
          defaultValue: 3600,
          min: 1,
          max: 86400,
        ),
      ),
      clockSkew: Duration(
        seconds: _readInt(
          env,
          'AUTH_CLOCK_SKEW_SECONDS',
          defaultValue: 30,
          min: 0,
          max: 300,
        ),
      ),
      requireEmailVerified: _readBool(
        env,
        'AUTH_REQUIRE_EMAIL_VERIFIED',
        defaultValue: false,
      ),
    );
  }

  static String _readRequiredString(EnvConfig env, String key) {
    final value = env[key]?.trim();

    if (value == null || value.isEmpty) {
      throw FormatException('$key wajib diisi.');
    }

    return value;
  }

  static Uri _readHttpsUrl(EnvConfig env, String key) {
    final value = _readRequiredString(env, key);
    final uri = Uri.tryParse(value);

    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw FormatException('$key harus berupa HTTPS URL yang valid.');
    }

    return uri;
  }

  static List<String> _readAlgorithms(String value) {
    const supportedAlgorithms = {'ES256', 'RS256'};

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
}
