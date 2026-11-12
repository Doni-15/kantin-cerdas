enum AppEnvironment {
  development,
  staging,
  production;

  bool get isDevelopment => this == AppEnvironment.development;
  bool get isStaging => this == AppEnvironment.staging;
  bool get isProduction => this == AppEnvironment.production;
}

/// Level pencatatan log server.
enum LogLevel { debug, info, warning, error }

/// Format keluaran log server.
enum LogFormat { text, json }

/// A. Identitas dan lingkungan aplikasi.
final class AppSettings {
  final String name;
  final AppEnvironment env;
  final bool debug;
  final String timezone;
  final String locale;
  final String version;

  const AppSettings({
    required this.name,
    required this.env,
    required this.debug,
    required this.timezone,
    required this.locale,
    required this.version,
  });
}

/// B. Konfigurasi HTTP Server Dart Shelf.
final class ServerConfig {
  final String host;
  final int port;
  final String apiPrefix;
  final int requestTimeoutSeconds;
  final int shutdownTimeoutSeconds;
  final int maxRequestBodyBytes;
  final int maxHeaderSizeBytes;

  const ServerConfig({
    required this.host,
    required this.port,
    required this.apiPrefix,
    required this.requestTimeoutSeconds,
    required this.shutdownTimeoutSeconds,
    required this.maxRequestBodyBytes,
    required this.maxHeaderSizeBytes,
  });
}

/// C. Konfigurasi koneksi Supabase Cloud.
final class SupabaseConfig {
  final String url;
  final String publishableKey;
  final String secretKey;
  final String projectRef;
  final int requestTimeoutSeconds;
  final int maxRetries;

  const SupabaseConfig({
    required this.url,
    required this.publishableKey,
    required this.secretKey,
    required this.projectRef,
    required this.requestTimeoutSeconds,
    required this.maxRetries,
  });
}

/// D. Konfigurasi autentikasi dan verifikasi JWT Supabase (ECC P-256 / JWKS).
final class AuthConfig {
  final String jwksUrl;
  final String jwtIssuer;
  final String jwtAudience;
  final List<String> allowedAlgorithms;
  final int jwksCacheTtlSeconds;
  final int clockSkewSeconds;
  final bool requireEmailVerified;

  const AuthConfig({
    required this.jwksUrl,
    required this.jwtIssuer,
    required this.jwtAudience,
    required this.allowedAlgorithms,
    required this.jwksCacheTtlSeconds,
    required this.clockSkewSeconds,
    required this.requireEmailVerified,
  });
}

/// E. Konfigurasi keamanan jaringan dan header HTTP.
final class SecurityConfig {
  final bool trustProxy;
  final List<String> allowedHosts;
  final bool enableSecurityHeaders;

  const SecurityConfig({
    required this.trustProxy,
    required this.allowedHosts,
    required this.enableSecurityHeaders,
  });
}

/// F. Konfigurasi Cross-Origin Resource Sharing (CORS).
final class CorsConfig {
  final bool enabled;
  final List<String> allowedOrigins;
  final List<String> allowedMethods;
  final List<String> allowedHeaders;
  final bool allowCredentials;
  final int maxAgeSeconds;

  const CorsConfig({
    required this.enabled,
    required this.allowedOrigins,
    required this.allowedMethods,
    required this.allowedHeaders,
    required this.allowCredentials,
    required this.maxAgeSeconds,
  });
}

/// G. Konfigurasi pembatasan laju permintaan (Rate Limiting).
final class RateLimitConfig {
  final bool enabled;
  final int windowSeconds;
  final int maxRequests;
  final int authWindowSeconds;
  final int authMaxRequests;
  final int uploadWindowSeconds;
  final int uploadMaxRequests;
  final bool trustProxy;

  const RateLimitConfig({
    required this.enabled,
    required this.windowSeconds,
    required this.maxRequests,
    required this.authWindowSeconds,
    required this.authMaxRequests,
    required this.uploadWindowSeconds,
    required this.uploadMaxRequests,
    required this.trustProxy,
  });
}

/// H. Konfigurasi Storage Bucket `kantin-media` dan validasi unggahan gambar.
final class StorageConfig {
  final String bucketName;
  final int maxUploadBytes;
  final List<String> allowedImageTypes;
  final int maxFilesPerUser;
  final String publicBaseUrl;

  const StorageConfig({
    required this.bucketName,
    required this.maxUploadBytes,
    required this.allowedImageTypes,
    required this.maxFilesPerUser,
    required this.publicBaseUrl,
  });
}

/// I. Konfigurasi pencatatan log dan observability server.
final class LoggingConfig {
  final LogLevel level;
  final LogFormat format;
  final bool requestEnabled;
  final bool includeStackTrace;

  const LoggingConfig({
    required this.level,
    required this.format,
    required this.requestEnabled,
    required this.includeStackTrace,
  });
}

/// Root konfigurasi aplikasi yang menggabungkan seluruh kelompok konfigurasi
final class AppConfig {
  final AppSettings app;
  final ServerConfig server;
  final SupabaseConfig supabase;
  final AuthConfig auth;
  final SecurityConfig security;
  final CorsConfig cors;
  final RateLimitConfig rateLimit;
  final StorageConfig storage;
  final LoggingConfig logging;

  const AppConfig({
    required this.app,
    required this.server,
    required this.supabase,
    required this.auth,
    required this.security,
    required this.cors,
    required this.rateLimit,
    required this.storage,
    required this.logging,
  });
}