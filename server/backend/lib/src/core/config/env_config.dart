import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_parser.dart';

final class EnvConfig {
  const EnvConfig._();

  static AppConfig load({String envFilePath = '.env'}) {
    final dotEnv = DotEnv(includePlatformEnvironment: true);
    if (File(envFilePath).existsSync()) {
      dotEnv.load([envFilePath]);
    }

    final map = <String, String?>{
      ...Platform.environment,
    };

    if (File(envFilePath).existsSync()) {
      for (final line in File(envFilePath).readAsLinesSync()) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

        final eqIndex = trimmed.indexOf('=');
        if (eqIndex <= 0) continue;

        final key = trimmed.substring(0, eqIndex).trim();
        map[key] = dotEnv[key];
      }
    }

    return fromMap(map);
  }

  static AppConfig fromMap(Map<String, String?> rawMap) {
    final normalized = <String, String?>{...rawMap};

    void alias(String canonicalKey, String fallbackKey) {
      final current = normalized[canonicalKey]?.trim() ?? '';
      if (current.isEmpty && (normalized[fallbackKey]?.trim().isNotEmpty ?? false)) {
        normalized[canonicalKey] = normalized[fallbackKey];
      }
    }

    alias('SERVER_HOST', 'HOST');
    alias('SERVER_PORT', 'PORT');
    alias('SUPABASE_PUBLISHABLE_KEY', 'SUPABASE_ANON_KEY');
    alias('SUPABASE_SECRET_KEY', 'SUPABASE_SERVICE_ROLE_KEY');
    alias('AUTH_JWKS_URL', 'SUPABASE_JWKS_URL');
    alias('STORAGE_MAX_UPLOAD_BYTES', 'MAX_UPLOAD_SIZE_BYTES');
    alias('STORAGE_ALLOWED_IMAGE_TYPES', 'ALLOWED_IMAGE_MIME_TYPES');
    alias('STORAGE_MAX_FILES_PER_USER', 'MAX_MEDIA_ASSETS_PER_USER');

    final parser = EnvParser(normalized);

    // A. Application Settings
    final env = parser.enumValue(
      'APP_ENV',
      AppEnvironment.values,
      defaultValue: AppEnvironment.development,
    );
    final rawDebug = parser.boolValue('APP_DEBUG', defaultValue: false);
    final effectiveDebug = env.isProduction ? false : rawDebug;

    final appSettings = AppSettings(
      name: parser.optionalString('APP_NAME', defaultValue: 'Kantin Cerdas API'),
      env: env,
      debug: effectiveDebug,
      timezone: parser.optionalString('APP_TIMEZONE', defaultValue: 'Asia/Jakarta'),
      locale: parser.optionalString('APP_LOCALE', defaultValue: 'id_ID'),
      version: parser.optionalString('APP_VERSION', defaultValue: '1.0.0'),
    );

    // B. HTTP Server Configuration
    final rawPrefix = parser.optionalString('API_PREFIX', defaultValue: '/v1');
    final apiPrefix = rawPrefix.startsWith('/') ? rawPrefix : '/$rawPrefix';

    final serverConfig = ServerConfig(
      host: parser.optionalString('SERVER_HOST', defaultValue: '0.0.0.0'),
      port: parser.intValue('SERVER_PORT', defaultValue: 8080, min: 1, max: 65535),
      apiPrefix: apiPrefix,
      requestTimeoutSeconds: parser.intValue(
        'SERVER_REQUEST_TIMEOUT_SECONDS',
        defaultValue: 30,
        min: 5,
        max: 120,
      ),

      shutdownTimeoutSeconds: parser.intValue(
        'SERVER_SHUTDOWN_TIMEOUT_SECONDS',
        defaultValue: 30,
        min: 1,
        max: 120,
      ),

      maxRequestBodyBytes: parser.intValue(
        'SERVER_MAX_REQUEST_BODY_BYTES',
        defaultValue: 10485760,
        min: 1024,
        max: 52428800,
      ),

      maxHeaderSizeBytes: parser.intValue(
        'SERVER_MAX_HEADER_SIZE_BYTES',
        defaultValue: 16384,
        min: 1024,
        max: 65536,
      ),
    );

    // C. Supabase Configuration
    final supabaseUrl = parser.urlString(
      'SUPABASE_URL',
      requireHttps: env.isProduction,
    );

    final supabaseConfig = SupabaseConfig(
      url: supabaseUrl,
      publishableKey: parser.requiredString('SUPABASE_PUBLISHABLE_KEY'),
      secretKey: parser.requiredString('SUPABASE_SECRET_KEY'),
      projectRef: parser.optionalString(
        'SUPABASE_PROJECT_REF',
        defaultValue: Uri.parse(supabaseUrl).host.split('.').first,
      ),

      requestTimeoutSeconds: parser.intValue(
        'SUPABASE_REQUEST_TIMEOUT_SECONDS',
        defaultValue: 15,
        min: 1,
        max: 60,
      ),

      maxRetries: parser.intValue(
        'SUPABASE_MAX_RETRIES',
        defaultValue: 2,
        min: 0,
        max: 5,
      ),
    );

    // D. Authentication & JWT Configuration (Turunan otomatis dari SUPABASE_URL)
    final authConfig = AuthConfig(
      jwksUrl: parser.urlString(
        'AUTH_JWKS_URL',
        defaultValue: '$supabaseUrl/auth/v1/.well-known/jwks.json',
        requireHttps: env.isProduction,
      ),

      jwtIssuer: parser.urlString(
        'AUTH_JWT_ISSUER',
        defaultValue: '$supabaseUrl/auth/v1',
        requireHttps: env.isProduction,
      ),

      jwtAudience: parser.optionalString(
        'AUTH_JWT_AUDIENCE',
        defaultValue: 'authenticated',
      ),

      allowedAlgorithms: parser.csvList(
        'AUTH_JWT_ALLOWED_ALGORITHMS',
        defaultValue: const ['ES256'],
      ),

      jwksCacheTtlSeconds: parser.intValue(
        'AUTH_JWKS_CACHE_TTL_SECONDS',
        defaultValue: 3600,
        min: 60,
        max: 86400,
      ),

      clockSkewSeconds: parser.intValue(
        'AUTH_CLOCK_SKEW_SECONDS',
        defaultValue: 30,
        min: 0,
        max: 300,
      ),

      requireEmailVerified: parser.boolValue(
        'AUTH_REQUIRE_EMAIL_VERIFIED',
        defaultValue: false,
      ),
    );

    // E. Security Configuration
    final securityConfig = SecurityConfig(
      trustProxy: parser.boolValue('SECURITY_TRUST_PROXY', defaultValue: false),
      allowedHosts: parser.csvList(
        'SECURITY_ALLOWED_HOSTS',
        defaultValue: const ['*'],
      ),

      enableSecurityHeaders: parser.boolValue(
        'SECURITY_ENABLE_SECURITY_HEADERS',
        defaultValue: true,
      ),
    );

    // F. CORS Configuration (Menyertakan Idempotency-Key sesuai kontrak mutasi Flutter)
    final corsConfig = CorsConfig(
      enabled: parser.boolValue('CORS_ENABLED', defaultValue: true),
      allowedOrigins: parser.csvList(
        'CORS_ALLOWED_ORIGINS',
        defaultValue: const ['*'],
      ),

      allowedMethods: parser.csvList(
        'CORS_ALLOWED_METHODS',
        defaultValue: const ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
      ),

      allowedHeaders: parser.csvList(
        'CORS_ALLOWED_HEADERS',
        defaultValue: const [
          'Origin',
          'Content-Type',
          'Accept',
          'Authorization',
          'Idempotency-Key',
        ],
      ),

      allowCredentials: parser.boolValue(
        'CORS_ALLOW_CREDENTIALS',
        defaultValue: false,
      ),

      maxAgeSeconds: parser.intValue(
        'CORS_MAX_AGE_SECONDS',
        defaultValue: 600,
        min: 0,
        max: 86400,
      ),
    );

    // G. Rate Limiting Configuration
    final rateLimitConfig = RateLimitConfig(
      enabled: parser.boolValue('RATE_LIMIT_ENABLED', defaultValue: true),
      windowSeconds: parser.intValue(
        'RATE_LIMIT_WINDOW_SECONDS',
        defaultValue: 60,
        min: 1,
        max: 3600,
      ),

      maxRequests: parser.intValue(
        'RATE_LIMIT_MAX_REQUESTS',
        defaultValue: 120,
        min: 1,
        max: 10000,
      ),

      authWindowSeconds: parser.intValue(
        'AUTH_RATE_LIMIT_WINDOW_SECONDS',
        defaultValue: 60,
        min: 1,
        max: 3600,
      ),

      authMaxRequests: parser.intValue(
        'AUTH_RATE_LIMIT_MAX_REQUESTS',
        defaultValue: 60,
        min: 1,
        max: 1000,
      ),
      uploadWindowSeconds: parser.intValue(
        'UPLOAD_RATE_LIMIT_WINDOW_SECONDS',
        defaultValue: 60,
        min: 1,
        max: 3600,
      ),

      uploadMaxRequests: parser.intValue(
        'UPLOAD_RATE_LIMIT_MAX_REQUESTS',
        defaultValue: 20,
        min: 1,
        max: 1000,
      ),
      trustProxy: parser.boolValue('RATE_LIMIT_TRUST_PROXY', defaultValue: false),
    );

    // H. Storage & Media Configuration (Selaras Migrasi 010: bucket kantin-media, maks 2 MB, kuota 200)
    final storageConfig = StorageConfig(
      bucketName: parser.optionalString(
        'STORAGE_BUCKET_NAME',
        defaultValue: 'kantin-media',
      ),

      maxUploadBytes: parser.intValue(
        'STORAGE_MAX_UPLOAD_BYTES',
        defaultValue: 2097152,
        min: 32,
        max: 2097152,
      ),

      allowedImageTypes: parser.csvList(
        'STORAGE_ALLOWED_IMAGE_TYPES',
        defaultValue: const ['image/jpeg', 'image/png', 'image/webp'],
      ),

      maxFilesPerUser: parser.intValue(
        'STORAGE_MAX_FILES_PER_USER',
        defaultValue: 200,
        min: 1,
        max: 200,
      ),

      publicBaseUrl: parser.urlString(
        'STORAGE_PUBLIC_BASE_URL',
        defaultValue: '$supabaseUrl/storage/v1/object/public/kantin-media',
        requireHttps: env.isProduction,
      ),
    );

    // I. Logging & Observability Configuration
    final rawIncludeStack = parser.boolValue(
      'LOG_INCLUDE_STACK_TRACE',
      defaultValue: !env.isProduction,
    );

    final loggingConfig = LoggingConfig(
      level: parser.enumValue(
        'LOG_LEVEL',
        LogLevel.values,
        defaultValue: LogLevel.info,
      ),

      format: parser.enumValue(
        'LOG_FORMAT',
        LogFormat.values,
        defaultValue: env.isProduction ? LogFormat.json : LogFormat.text,
      ),
      
      requestEnabled: parser.boolValue('LOG_REQUEST_ENABLED', defaultValue: true),
      includeStackTrace: env.isProduction ? false : rawIncludeStack,
    );

    return AppConfig(
      app: appSettings,
      server: serverConfig,
      supabase: supabaseConfig,
      auth: authConfig,
      security: securityConfig,
      cors: corsConfig,
      rateLimit: rateLimitConfig,
      storage: storageConfig,
      logging: loggingConfig,
    );
  }
}