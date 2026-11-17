import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';

class SupabaseConfig {
  const SupabaseConfig._({
    required this.projectRef,
    required this.url,
    required this.publishableKey,
    required this.secretKey,
    required this.requestTimeout,
    required this.maxRetries,
  });

  final String projectRef;
  final Uri url;
  final String publishableKey;
  final String secretKey;
  final Duration requestTimeout;
  final int maxRetries;

  factory SupabaseConfig.fromEnv(EnvConfig env) {
    final projectRef = _requiredString(env, 'SUPABASE_PROJECT_REF');

    if (!RegExp(r'^[a-z0-9]{20}$').hasMatch(projectRef)) {
      throw const FormatException(
        'SUPABASE_PROJECT_REF harus berupa 20 karakter '
        'huruf kecil dan angka.',
      );
    }

    final url = _readUrl(_requiredString(env, 'SUPABASE_URL'));
    final publishableKey = _requiredString(env, 'SUPABASE_PUBLISHABLE_KEY');

    if (!publishableKey.startsWith('sb_publishable_')) {
      throw const FormatException(
        'SUPABASE_PUBLISHABLE_KEY harus menggunakan '
        'format sb_publishable_.',
      );
    }

    final secretKey = _requiredString(env, 'SUPABASE_SECRET_KEY');

    if (!secretKey.startsWith('sb_secret_')) {
      throw const FormatException(
        'SUPABASE_SECRET_KEY harus menggunakan '
        'format sb_secret_.',
      );
    }

    return SupabaseConfig._(
      projectRef: projectRef,
      url: url,
      publishableKey: publishableKey,
      secretKey: secretKey,
      requestTimeout: Duration(
        seconds: _readInt(
          env,
          'SUPABASE_REQUEST_TIMEOUT_SECONDS',
          defaultValue: 15,
          min: 1,
          max: 300,
        ),
      ),
      maxRetries: _readInt(
        env,
        'SUPABASE_MAX_RETRIES',
        defaultValue: 2,
        min: 0,
        max: 10,
      ),
    );
  }

  static String _requiredString(EnvConfig env, String key) {
    final value = env[key]?.trim();

    if (value == null || value.isEmpty) {
      throw FormatException('$key wajib diisi pada konfigurasi Supabase.');
    }

    return value;
  }

  static Uri _readUrl(String value) {
    final uri = Uri.tryParse(value);

    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException(
        'SUPABASE_URL harus berupa HTTPS URL yang valid.',
      );
    }

    return uri;
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
