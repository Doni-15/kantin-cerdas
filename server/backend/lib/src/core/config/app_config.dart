import 'package:kantin_cerdas_backend/src/core/config/app_environment.dart';
import 'package:kantin_cerdas_backend/src/core/config/auth_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/cors_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_parsers.dart';
import 'package:kantin_cerdas_backend/src/core/config/logging_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/proxy_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/rate_limit_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/security_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/server_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/storage_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/supabase_config.dart';

class AppConfig {
  const AppConfig._({
    required this.appName,
    required this.environment,
    required this.debug,
    required this.timezone,
    required this.locale,
    required this.version,
    required this.server,
    required this.supabase,
    required this.auth,
    required this.security,
    required this.cors,
    required this.rateLimit,
    required this.storage,
    required this.logging,
    required this.proxy,
  });

  // A. Application
  final String appName;
  final AppEnvironment environment;
  final bool debug;
  final String timezone;
  final String locale;
  final String version;

  // B-I. Application configuration groups
  final ServerConfig server;
  final SupabaseConfig supabase;
  final AuthConfig auth;
  final SecurityConfig security;
  final CorsConfig cors;
  final RateLimitConfig rateLimit;
  final StorageConfig storage;
  final LoggingConfig logging;
  final ProxyConfig proxy;

  bool get isDevelopment => environment == AppEnvironment.development;
  bool get isStaging => environment == AppEnvironment.staging;
  bool get isProduction => environment == AppEnvironment.production;

  factory AppConfig.fromEnv(EnvConfig env) {
    // A. APPLICATION
    final appName = readEnvString(
      env,
      'APP_NAME',
      defaultValue: 'Kantin Cerdas API',
    );

    final environment = AppEnvironment.parse(
      readEnvString(env, 'APP_ENV', defaultValue: 'development'),
    );

    final debug = readEnvBool(
      env,
      'APP_DEBUG',
      defaultValue: environment == AppEnvironment.development,
    );

    final timezone = readEnvString(
      env,
      'APP_TIMEZONE',
      defaultValue: 'Asia/Jakarta',
    );

    final locale = readEnvString(env, 'APP_LOCALE', defaultValue: 'id_ID');
    final version = readEnvString(env, 'APP_VERSION', defaultValue: '1.0.0');

    if (!RegExp(r'^[a-z]{2}_[A-Z]{2}$').hasMatch(locale)) {
      throw FormatException('APP_LOCALE tidak valid: $locale');
    }

    if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version)) {
      throw FormatException('APP_VERSION tidak valid: $version');
    }

    // B-I. Parse each configuration using its own class.
    final server = ServerConfig.fromEnv(env);
    final supabase = SupabaseConfig.fromEnv(
      env,
      allowLocal: environment == AppEnvironment.development,
    );
    final googleProductionVerified = readEnvBool(
      env,
      'AUTH_GOOGLE_PRODUCTION_VERIFIED',
      defaultValue: false,
    );
    final auth = AuthConfig.fromEnv(
      env,
      projectUrl: supabase.url,
      allowLocal: supabase.url.scheme == 'http',
      allowGoogle:
          environment != AppEnvironment.production || googleProductionVerified,
    );
    final security = SecurityConfig.fromEnv(env);
    final cors = CorsConfig.fromEnv(env);
    final rateLimit = RateLimitConfig.fromEnv(env);
    final storage = StorageConfig.fromEnv(env, projectUrl: supabase.url);
    final logging = LoggingConfig.fromEnv(env);
    final proxy = ProxyConfig.fromEnv(env);

    // Cross-configuration validation.
    _validateSupabaseIntegration(
      supabase: supabase,
      auth: auth,
      storage: storage,
    );

    return AppConfig._(
      appName: appName,
      environment: environment,
      debug: debug,
      timezone: timezone,
      locale: locale,
      version: version,
      server: server,
      supabase: supabase,
      auth: auth,
      security: security,
      cors: cors,
      rateLimit: rateLimit,
      storage: storage,
      logging: logging,
      proxy: proxy,
    );
  }

  static void _validateSupabaseIntegration({
    required SupabaseConfig supabase,
    required AuthConfig auth,
    required StorageConfig storage,
  }) {
    if (auth.jwksUrl.origin != supabase.url.origin ||
        auth.issuer.origin != supabase.url.origin) {
      throw FormatException(
        'Konfigurasi AUTH harus mengarah ke project Supabase yang sama.',
      );
    }

    if (storage.publicBaseUrl.origin != supabase.url.origin) {
      throw FormatException(
        'STORAGE_PUBLIC_BASE_URL harus mengarah ke project Supabase yang sama.',
      );
    }
  }
}
