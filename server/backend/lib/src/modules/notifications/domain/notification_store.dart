import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_models.dart';

abstract interface class NotificationStore {
  Future<PushDeviceRegistration> registerPushDevice({
    required String userId,
    required String deviceId,
    required String fcmToken,
    String platform = 'android',
  });

  Future<bool> revokePushDevice({
    required String userId,
    required String deviceId,
    bool rotateTopics = true,
  });

  Future<RealtimeChannelGrant> getChannelGrant(String userId);

  Future<RealtimeSignalsPage> pollSignals({
    required String userId,
    required int afterSeq,
    int limit = 50,
  });

  Future<List<UnbroadcastedRealtimeSignal>> claimUnbroadcastedSignals({
    int limit = 50,
    DateTime? now,
  });

  Future<List<PendingPushDelivery>> claimPendingPushDeliveries({
    int batchSize = 25,
    int maxAttempts = 5,
    int lockSeconds = 60,
    DateTime? now,
  });

  Future<void> completePushDelivery({
    required String deliveryId,
    required FcmDeliveryOutcome outcome,
    String? errorCode,
    String? providerMessageId,
    int retryDelaySeconds = 30,
    bool deactivateDevice = false,
    DateTime? now,
  });
}
