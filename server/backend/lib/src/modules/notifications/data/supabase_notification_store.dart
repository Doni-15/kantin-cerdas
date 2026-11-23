import 'package:http/http.dart' as http;
import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_client_factory.dart';
import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_rpc_helper.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_errors.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_models.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_store.dart';
import 'package:supabase/supabase.dart';

class SupabaseNotificationStore implements NotificationStore {
  const SupabaseNotificationStore(this._factory, {this._httpClient});

  final SupabaseClientFactory _factory;
  final http.Client? _httpClient;

  @override
  Future<PushDeviceRegistration> registerPushDevice({
    required String userId,
    required String deviceId,
    required String fcmToken,
    String platform = 'android',
  }) async {
    final map = await _rpcObject('kc_rt_register_push_device', {
      'p_user_id': userId,
      'p_device_id': deviceId,
      'p_fcm_token': fcmToken,
      'p_platform': platform,
    });
    return PushDeviceRegistration.fromJson(map);
  }

  @override
  Future<bool> revokePushDevice({
    required String userId,
    required String deviceId,
    bool rotateTopics = true,
  }) async {
    final map = await _rpcObject('kc_rt_revoke_push_device', {
      'p_user_id': userId,
      'p_device_id': deviceId,
      'p_rotate_topics': rotateTopics,
    });
    return (map['revoked'] as bool?) ?? false;
  }

  @override
  Future<RealtimeChannelGrant> getChannelGrant(String userId) async {
    final map = await _rpcObject('kc_rt_get_channel_grant', {
      'p_user_id': userId,
    });
    return RealtimeChannelGrant.fromJson(map);
  }

  @override
  Future<RealtimeSignalsPage> pollSignals({
    required String userId,
    required int afterSeq,
    int limit = 50,
  }) async {
    final map = await _rpcObject('kc_rt_poll_signals', {
      'p_user_id': userId,
      'p_after_seq': afterSeq,
      'p_limit': limit,
    });
    return RealtimeSignalsPage.fromJson(map);
  }

  @override
  Future<List<UnbroadcastedRealtimeSignal>> claimUnbroadcastedSignals({
    int limit = 50,
    DateTime? now,
  }) async {
    final map = await _rpcObject('kc_rt_claim_unbroadcasted_signals', {
      'p_limit': limit,
      'p_now': (now ?? DateTime.now().toUtc()).toUtc().toIso8601String(),
    });
    final raw = map['items'];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map)
          UnbroadcastedRealtimeSignal.fromJson(Map<String, Object?>.from(item)),
    ];
  }

  @override
  Future<List<PendingPushDelivery>> claimPendingPushDeliveries({
    int batchSize = 25,
    int maxAttempts = 5,
    int lockSeconds = 60,
    DateTime? now,
  }) async {
    final map = await _rpcObject('kc_push_claim_pending_deliveries', {
      'p_batch_size': batchSize,
      'p_max_attempts': maxAttempts,
      'p_lock_seconds': lockSeconds,
      'p_now': (now ?? DateTime.now().toUtc()).toUtc().toIso8601String(),
    });
    final raw = map['items'];
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map)
          PendingPushDelivery.fromJson(Map<String, Object?>.from(item)),
    ];
  }

  @override
  Future<void> completePushDelivery({
    required String deliveryId,
    required FcmDeliveryOutcome outcome,
    String? errorCode,
    String? providerMessageId,
    int retryDelaySeconds = 30,
    bool deactivateDevice = false,
    DateTime? now,
  }) async {
    final outcomeWire = switch (outcome) {
      FcmDeliveryOutcome.sent => 'sent',
      FcmDeliveryOutcome.retryable => 'retry',
      FcmDeliveryOutcome.failedPermanent => 'failed_permanent',
      FcmDeliveryOutcome.skipped => 'skipped',
    };
    await _rpcObject('kc_push_complete_delivery', {
      'p_delivery_id': deliveryId,
      'p_outcome': outcomeWire,
      'p_error_code': errorCode,
      'p_provider_message_id': providerMessageId,
      'p_retry_delay_seconds': retryDelaySeconds,
      'p_deactivate_device': deactivateDevice,
      'p_now': (now ?? DateTime.now().toUtc()).toUtc().toIso8601String(),
    });
  }

  Future<Map<String, Object?>> _rpcObject(
    String fn,
    Map<String, Object?> params,
  ) => runSupabaseRpc(
    factory: _factory,
    httpClient: _httpClient,
    fn: fn,
    params: params,
    decode: (result) => decodeRpcObject(
      result,
      () => const NotificationFailure(NotificationFailureCode.unavailable),
    ),
    onPostgrestError: _mapPostgrestException,
    onUnavailable: () =>
        const NotificationFailure(NotificationFailureCode.unavailable),
  );
}

NotificationFailure _mapPostgrestException(PostgrestException error) {
  const mapping = {
    'KC_RT_INVALID_INPUT': NotificationFailureCode.invalidInput,
    'KC_PUSH_ROLE_NOT_ALLOWED': NotificationFailureCode.roleNotAllowed,
    'KC_RT_ACCOUNT_INACTIVE': NotificationFailureCode.accountInactive,
    'KC_RT_DELIVERY_NOT_FOUND': NotificationFailureCode.deliveryNotFound,
  };
  final code = matchPostgrestErrorToken(error, mapping);
  return code == null
      ? const NotificationFailure(NotificationFailureCode.unavailable)
      : NotificationFailure(code);
}
