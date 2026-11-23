import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_parsers.dart';

/// Environment-only configuration for Realtime & FCM push notifications.
/// Reads environment variable names strictly without embedding any secret values.
class NotificationsConfig {
  const NotificationsConfig({
    required this.fcmEnabled,
    required this.fcmProjectId,
    required this.fcmClientEmail,
    required this.fcmPrivateKey,
    required this.fcmTokenUri,
    required this.fcmApiBaseUrl,
    required this.fcmRequestTimeout,
    required this.fcmMaxRetryAttempts,
    required this.fcmWorkerEnabled,
    required this.fcmWorkerPollInterval,
    required this.supabaseBroadcastEnabled,
    required this.realtimeSignalPollInterval,
    required this.realtimeStreamHeartbeat,
    required this.realtimeSessionRecheck,
  });

  const NotificationsConfig.defaults()
    : fcmEnabled = false,
      fcmProjectId = '',
      fcmClientEmail = '',
      fcmPrivateKey = '',
      fcmTokenUri = 'https://oauth2.googleapis.com/token',
      fcmApiBaseUrl = 'https://fcm.googleapis.com',
      fcmRequestTimeout = const Duration(seconds: 10),
      fcmMaxRetryAttempts = 5,
      fcmWorkerEnabled = false,
      fcmWorkerPollInterval = const Duration(seconds: 3),
      supabaseBroadcastEnabled = false,
      realtimeSignalPollInterval = const Duration(milliseconds: 500),
      realtimeStreamHeartbeat = const Duration(seconds: 15),
      realtimeSessionRecheck = const Duration(seconds: 5);

  final bool fcmEnabled;
  final String fcmProjectId;
  final String fcmClientEmail;
  final String fcmPrivateKey;
  final String fcmTokenUri;
  final String fcmApiBaseUrl;
  final Duration fcmRequestTimeout;
  final int fcmMaxRetryAttempts;
  final bool fcmWorkerEnabled;
  final Duration fcmWorkerPollInterval;
  final bool supabaseBroadcastEnabled;
  final Duration realtimeSignalPollInterval;
  final Duration realtimeStreamHeartbeat;
  final Duration realtimeSessionRecheck;

  bool get hasCompleteFcmCredentials =>
      fcmProjectId.isNotEmpty &&
      fcmClientEmail.isNotEmpty &&
      fcmPrivateKey.isNotEmpty;

  bool get isFcmActive => fcmEnabled && hasCompleteFcmCredentials;

  factory NotificationsConfig.fromEnv(EnvConfig env) {
    final fcmEnabled = _readBool(env, 'FCM_ENABLED', defaultValue: false);
    final fcmProjectId = readEnvString(env, 'FCM_PROJECT_ID');
    final fcmClientEmail = readEnvString(env, 'FCM_CLIENT_EMAIL');
    final fcmPrivateKey = readEnvString(
      env,
      'FCM_PRIVATE_KEY',
    ).replaceAll(r'\n', '\n');
    final fcmTokenUri = readEnvString(
      env,
      'FCM_TOKEN_URI',
      defaultValue: 'https://oauth2.googleapis.com/token',
    );
    final fcmApiBaseUrl = readEnvString(
      env,
      'FCM_API_BASE_URL',
      defaultValue: 'https://fcm.googleapis.com',
    );
    final timeoutSeconds = _readInt(
      env,
      'FCM_REQUEST_TIMEOUT_SECONDS',
      defaultValue: 10,
      min: 2,
      max: 30,
    );
    final maxRetries = _readInt(
      env,
      'FCM_MAX_RETRY_ATTEMPTS',
      defaultValue: 5,
      min: 1,
      max: 10,
    );
    final workerEnabled = _readBool(
      env,
      'FCM_WORKER_ENABLED',
      defaultValue: fcmEnabled,
    );
    final workerIntervalSeconds = _readInt(
      env,
      'FCM_WORKER_POLL_INTERVAL_SECONDS',
      defaultValue: 3,
      min: 1,
      max: 60,
    );
    final supabaseBroadcastEnabled = _readBool(
      env,
      'REALTIME_SUPABASE_BROADCAST_ENABLED',
      defaultValue: false,
    );
    final signalPollMs = _readInt(
      env,
      'REALTIME_SIGNAL_POLL_INTERVAL_MS',
      defaultValue: 500,
      min: 100,
      max: 10000,
    );
    final heartbeatSeconds = _readInt(
      env,
      'REALTIME_STREAM_HEARTBEAT_SECONDS',
      defaultValue: 15,
      min: 5,
      max: 60,
    );
    final sessionRecheckSeconds = _readInt(
      env,
      'REALTIME_SESSION_RECHECK_SECONDS',
      defaultValue: 5,
      min: 1,
      max: 30,
    );

    return NotificationsConfig(
      fcmEnabled: fcmEnabled,
      fcmProjectId: fcmProjectId,
      fcmClientEmail: fcmClientEmail,
      fcmPrivateKey: fcmPrivateKey,
      fcmTokenUri: fcmTokenUri,
      fcmApiBaseUrl: fcmApiBaseUrl,
      fcmRequestTimeout: Duration(seconds: timeoutSeconds),
      fcmMaxRetryAttempts: maxRetries,
      fcmWorkerEnabled: workerEnabled,
      fcmWorkerPollInterval: Duration(seconds: workerIntervalSeconds),
      supabaseBroadcastEnabled: supabaseBroadcastEnabled,
      realtimeSignalPollInterval: Duration(milliseconds: signalPollMs),
      realtimeStreamHeartbeat: Duration(seconds: heartbeatSeconds),
      realtimeSessionRecheck: Duration(seconds: sessionRecheckSeconds),
    );
  }

  static bool _readBool(
    EnvConfig env,
    String key, {
    required bool defaultValue,
  }) {
    final value = env[key]?.trim().toLowerCase();
    if (value == null || value.isEmpty) return defaultValue;
    return value == 'true' || value == '1';
  }

  static int _readInt(
    EnvConfig env,
    String key, {
    required int defaultValue,
    required int min,
    required int max,
  }) {
    final raw = env[key]?.trim();
    if (raw == null || raw.isEmpty) return defaultValue;
    final parsed = int.tryParse(raw);
    if (parsed == null) return defaultValue;
    if (parsed < min) return min;
    if (parsed > max) return max;
    return parsed;
  }
}
