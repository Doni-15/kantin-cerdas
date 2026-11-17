import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';

class CorsConfig {
  const CorsConfig._({
    required this.enabled,
    required this.allowedOrigins,
    required this.allowedMethods,
    required this.allowedHeaders,
    required this.allowCredentials,
    required this.maxAge,
  });

  final bool enabled;
  final List<String> allowedOrigins;
  final List<String> allowedMethods;
  final List<String> allowedHeaders;
  final bool allowCredentials;
  final Duration maxAge;

  bool get allowAnyOrigin => allowedOrigins.contains('*');

  factory CorsConfig.fromEnv(EnvConfig env) {
    final origins = _readList(
      env,
      'CORS_ALLOWED_ORIGINS',
      defaultValue: '*',
      normalize: _normalizeOrigin,
    );

    final methods = _readList(
      env,
      'CORS_ALLOWED_METHODS',
      defaultValue: 'GET,POST,PUT,PATCH,DELETE,OPTIONS',
      normalize: (value) =>
          _normalizeToken(value.toUpperCase(), key: 'CORS_ALLOWED_METHODS'),
    );

    final headers = _readList(
      env,
      'CORS_ALLOWED_HEADERS',
      defaultValue: 'Origin,Content-Type,Accept,Authorization,Idempotency-Key',
      normalize: (value) =>
          _normalizeToken(value.toLowerCase(), key: 'CORS_ALLOWED_HEADERS'),
    );

    final allowCredentials = _readBool(
      env,
      'CORS_ALLOW_CREDENTIALS',
      defaultValue: false,
    );

    if (origins.contains('*') && origins.length > 1) {
      throw const FormatException(
        'CORS_ALLOWED_ORIGINS tidak boleh menggabungkan * '
        'dengan origin lainnya.',
      );
    }

    if (origins.contains('*') && allowCredentials) {
      throw const FormatException(
        'CORS_ALLOW_CREDENTIALS tidak boleh true '
        'ketika CORS_ALLOWED_ORIGINS menggunakan wildcard *.',
      );
    }

    return CorsConfig._(
      enabled: _readBool(env, 'CORS_ENABLED', defaultValue: true),
      allowedOrigins: List.unmodifiable(origins),
      allowedMethods: List.unmodifiable(methods),
      allowedHeaders: List.unmodifiable(headers),
      allowCredentials: allowCredentials,
      maxAge: Duration(
        seconds: _readInt(
          env,
          'CORS_MAX_AGE_SECONDS',
          defaultValue: 600,
          min: 0,
          max: 86400,
        ),
      ),
    );
  }

  static List<String> _readList(
    EnvConfig env,
    String key, {
    required String defaultValue,
    required String Function(String) normalize,
  }) {
    final rawValue = env[key] ?? defaultValue;

    final values = rawValue
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .map(normalize)
        .toList();

    if (values.isEmpty) {
      throw FormatException('$key tidak boleh kosong.');
    }

    if (values.toSet().length != values.length) {
      throw FormatException('$key tidak boleh berisi duplikasi.');
    }

    return values;
  }

  static String _normalizeOrigin(String value) {
    if (value == '*') {
      return value;
    }

    final uri = Uri.tryParse(value);

    if (uri == null ||
        !{'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw FormatException('Origin CORS tidak valid: $value');
    }

    // Origin terdiri dari scheme, host, dan port.
    return uri.origin;
  }

  static String _normalizeToken(String value, {required String key}) {
    if (!RegExp(r"^[!#$%&'*+\-.^_`|~0-9A-Za-z]+$").hasMatch(value)) {
      throw FormatException('Nilai tidak valid pada $key: $value');
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
