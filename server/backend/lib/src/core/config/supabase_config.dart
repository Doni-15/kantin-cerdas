import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_parsers.dart';

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

  factory SupabaseConfig.fromEnv(EnvConfig env, {bool allowLocal = false}) {
    final url = _readUrl(
      _requiredString(env, 'SUPABASE_URL'),
      allowLocal: allowLocal,
    );
    final local = url.scheme == 'http';
    final project = RegExp(
      r'^([a-z0-9]{20})\.supabase\.co$',
    ).firstMatch(url.host);
    if (project == null && !local) {
      throw const FormatException(
        'SUPABASE_URL harus memakai hostname proyek Supabase Cloud.',
      );
    }
    final projectRef = local ? 'local' : project!.group(1)!;
    final configuredRef = env['SUPABASE_PROJECT_REF']?.trim();
    if (configuredRef != null &&
        configuredRef.isNotEmpty &&
        configuredRef != projectRef) {
      throw const FormatException(
        'SUPABASE_URL tidak sesuai dengan SUPABASE_PROJECT_REF.',
      );
    }

    final publishableKey = _requiredString(env, 'SUPABASE_PUBLISHABLE_KEY');

    if (local
        ? !_jwt.hasMatch(publishableKey)
        : !publishableKey.startsWith('sb_publishable_')) {
      throw const FormatException(
        'SUPABASE_PUBLISHABLE_KEY harus menggunakan '
        'format sb_publishable_ pada Supabase Cloud atau JWT pada Supabase lokal.',
      );
    }

    final secretKey = _requiredString(env, 'SUPABASE_SECRET_KEY');

    if (local
        ? !_jwt.hasMatch(secretKey)
        : !secretKey.startsWith('sb_secret_')) {
      throw const FormatException(
        'SUPABASE_SECRET_KEY harus menggunakan '
        'format sb_secret_ pada Supabase Cloud atau JWT pada Supabase lokal.',
      );
    }

    return SupabaseConfig._(
      projectRef: projectRef,
      url: url,
      publishableKey: publishableKey,
      secretKey: secretKey,
      requestTimeout: Duration(
        seconds: readEnvInt(
          env,
          'SUPABASE_REQUEST_TIMEOUT_SECONDS',
          defaultValue: 15,
          min: 1,
          max: 300,
        ),
      ),
      maxRetries: readEnvInt(
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

  static final _jwt = RegExp(
    r'^[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+$',
  );

  static Uri _readUrl(String value, {required bool allowLocal}) {
    final uri = Uri.tryParse(value);
    final local =
        allowLocal && uri?.scheme == 'http' && uri?.host == '127.0.0.1';

    if (uri == null ||
        (!local && uri.scheme != 'https') ||
        uri.host.isEmpty ||
        (!local && uri.hasPort) ||
        uri.userInfo.isNotEmpty ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const FormatException(
        'SUPABASE_URL harus berupa HTTPS URL yang valid.',
      );
    }

    return uri;
  }
}
