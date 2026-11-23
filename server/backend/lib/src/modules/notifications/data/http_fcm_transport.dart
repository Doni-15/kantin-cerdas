import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:kantin_cerdas_backend/src/modules/notifications/data/google_oauth_jwt_signer.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/fcm_transport.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_models.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notifications_config.dart';

/// Real Firebase Cloud Messaging HTTP v1 transport (RT-TECH-002).
/// Stays completely inactive unless FCM_ENABLED=true and full env config is provided.
class HttpFcmTransport implements FcmTransport {
  factory HttpFcmTransport({
    required NotificationsConfig config,
    http.Client? httpClient,
    GoogleOAuth2TokenProvider? tokenProvider,
  }) {
    final resolvedClient = httpClient ?? http.Client();
    return HttpFcmTransport._(
      config: config,
      httpClient: resolvedClient,
      tokenProvider:
          tokenProvider ??
          (config.isFcmActive
              ? GoogleOAuth2TokenProvider(
                  clientEmail: config.fcmClientEmail,
                  privateKeyPem: config.fcmPrivateKey,
                  tokenUri: config.fcmTokenUri,
                  httpClient: resolvedClient,
                  timeout: config.fcmRequestTimeout,
                )
              : null),
    );
  }

  HttpFcmTransport._({
    required this._config,
    required this._httpClient,
    required this._tokenProvider,
  });

  final NotificationsConfig _config;
  final http.Client _httpClient;
  final GoogleOAuth2TokenProvider? _tokenProvider;

  @override
  bool get isLiveEnabled => _config.isFcmActive;

  @override
  void close() {
    _httpClient.close();
  }

  @override
  Future<FcmSendResult> send(FcmMessagePayload payload) async {
    if (!_config.isFcmActive || _tokenProvider == null) {
      return const FcmSendResult.skipped('FCM_DISABLED');
    }

    final Uri endpoint;
    try {
      final base = _config.fcmApiBaseUrl.replaceFirst(RegExp(r'/+$'), '');
      endpoint = Uri.parse(
        '$base/v1/projects/${Uri.encodeComponent(_config.fcmProjectId)}/messages:send',
      );
    } on FormatException {
      return const FcmSendResult.failedPermanent('FCM_INVALID_ENDPOINT');
    }

    final String bearer;
    try {
      bearer = await _tokenProvider.getAccessToken();
    } on TimeoutException {
      return const FcmSendResult.retryable('OAUTH_TIMEOUT');
    } on IOException {
      return const FcmSendResult.retryable('OAUTH_NETWORK_ERROR');
    } on http.ClientException {
      return const FcmSendResult.retryable('OAUTH_CLIENT_ERROR');
    } on FormatException {
      return const FcmSendResult.failedPermanent('OAUTH_CONFIG_INVALID');
    } on StateError catch (error) {
      final msg = error.message;
      if (msg.contains('500') || msg.contains('502') || msg.contains('503')) {
        return FcmSendResult.retryable(msg);
      }
      return FcmSendResult.failedPermanent(msg);
    }

    try {
      final response = await _httpClient
          .post(
            endpoint,
            headers: {
              'authorization': 'Bearer $bearer',
              'content-type': 'application/json; charset=utf-8',
            },
            body: jsonEncode(payload.toFcmV1RequestBody()),
          )
          .timeout(_config.fcmRequestTimeout);

      return _classifyResponse(response);
    } on TimeoutException {
      return const FcmSendResult.retryable('FCM_TIMEOUT');
    } on IOException {
      return const FcmSendResult.retryable('FCM_NETWORK_ERROR');
    } on http.ClientException {
      return const FcmSendResult.retryable('FCM_CLIENT_ERROR');
    }
  }

  FcmSendResult _classifyResponse(http.Response response) {
    final code = response.statusCode;
    final body = _tryDecodeMap(response.body);
    if (code >= 200 && code < 300) {
      final messageName = (body?['name'] as String?)?.trim() ?? 'fcm_sent';
      return FcmSendResult.sent(messageName);
    }

    final fcmErrorCode = _extractFcmErrorCode(body);
    if (code == 401) {
      _tokenProvider?.invalidateCache();
      return FcmSendResult.retryable(fcmErrorCode ?? 'FCM_UNAUTHENTICATED');
    }
    if (code == 429 || code >= 500) {
      return FcmSendResult.retryable(fcmErrorCode ?? 'FCM_HTTP_$code');
    }
    if (code == 404 || fcmErrorCode == 'UNREGISTERED') {
      return FcmSendResult.failedPermanent(
        fcmErrorCode ?? 'UNREGISTERED',
        deactivateDevice: true,
      );
    }
    if (code == 400 &&
        (fcmErrorCode == 'INVALID_ARGUMENT' ||
            fcmErrorCode == 'SENDER_ID_MISMATCH')) {
      return FcmSendResult.failedPermanent(
        fcmErrorCode!,
        deactivateDevice: true,
      );
    }
    return FcmSendResult.failedPermanent(fcmErrorCode ?? 'FCM_HTTP_$code');
  }

  Map<String, Object?>? _tryDecodeMap(String raw) {
    try {
      final parsed = jsonDecode(raw);
      if (parsed is Map) return Map<String, Object?>.from(parsed);
    } on FormatException {
      return null;
    }
    return null;
  }

  String? _extractFcmErrorCode(Map<String, Object?>? body) {
    final error = body?['error'];
    if (error is! Map) return null;
    final details = error['details'];
    if (details is List) {
      for (final item in details) {
        if (item is Map && item['errorCode'] is String) {
          return item['errorCode'] as String;
        }
      }
    }
    if (error['status'] is String) {
      return error['status'] as String;
    }
    return null;
  }
}
