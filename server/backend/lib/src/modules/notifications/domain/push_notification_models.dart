/// Strictly models the 7 FINAL/LOCKED push events defined in ORDER-017A.
/// `selesai`, `gagal_diambil`, and Admin actions are intentionally excluded.
enum PushEventType {
  orderCreated('order_created', PushRecipientRole.owner),
  orderCancelled('order_cancelled', PushRecipientRole.owner),
  orderAccepted('order_accepted', PushRecipientRole.customer),
  orderRejected('order_rejected', PushRecipientRole.customer),
  orderReady('order_ready', PushRecipientRole.customer),
  orderFailedFulfill('order_failed_fulfill', PushRecipientRole.customer),
  orderNotPickedUp('order_not_picked_up', PushRecipientRole.customer);

  const PushEventType(this.wireValue, this.expectedRecipientRole);

  final String wireValue;
  final PushRecipientRole expectedRecipientRole;

  static PushEventType? tryParse(String? raw) {
    if (raw == null) return null;
    for (final value in values) {
      if (value.wireValue == raw) return value;
    }
    return null;
  }
}

enum PushRecipientRole {
  customer('customer'),
  owner('owner');

  const PushRecipientRole(this.wireValue);

  final String wireValue;

  static PushRecipientRole? tryParse(String? raw) {
    if (raw == null) return null;
    for (final value in values) {
      if (value.wireValue == raw) return value;
    }
    return null;
  }
}

class PushDeviceRegistration {
  const PushDeviceRegistration({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.platform,
    required this.isActive,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String deviceId;
  final String platform;
  final bool isActive;
  final DateTime updatedAt;

  factory PushDeviceRegistration.fromJson(Map<String, Object?> json) {
    return PushDeviceRegistration(
      id: (json['id'] as String?) ?? '',
      userId: (json['user_id'] as String?) ?? '',
      deviceId: (json['device_id'] as String?) ?? '',
      platform: (json['platform'] as String?) ?? 'android',
      isActive: (json['is_active'] as bool?) ?? false,
      updatedAt:
          DateTime.tryParse((json['updated_at'] as String?) ?? '') ??
          DateTime.now().toUtc(),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'device_id': deviceId,
    'platform': platform,
    'is_active': isActive,
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };
}

class PendingPushDelivery {
  const PendingPushDelivery({
    required this.deliveryId,
    required this.notificationEventId,
    required this.orderId,
    required this.orderNumber,
    required this.stallName,
    required this.recipientId,
    required this.recipientRole,
    required this.eventType,
    required this.deviceId,
    required this.fcmToken,
    required this.attemptCount,
    required this.maxAttempts,
  });

  final String deliveryId;
  final String notificationEventId;
  final String orderId;
  final String orderNumber;
  final String stallName;
  final String recipientId;
  final String recipientRole;
  final String eventType;
  final String deviceId;
  final String fcmToken;
  final int attemptCount;
  final int maxAttempts;

  factory PendingPushDelivery.fromJson(Map<String, Object?> json) {
    return PendingPushDelivery(
      deliveryId: (json['delivery_id'] as String?) ?? '',
      notificationEventId: (json['notification_event_id'] as String?) ?? '',
      orderId: (json['order_id'] as String?) ?? '',
      orderNumber: (json['order_number'] as String?) ?? '',
      stallName: (json['stall_name'] as String?) ?? '',
      recipientId: (json['recipient_id'] as String?) ?? '',
      recipientRole: (json['recipient_role'] as String?) ?? '',
      eventType: (json['event_type'] as String?) ?? '',
      deviceId: (json['device_id'] as String?) ?? '',
      fcmToken: (json['fcm_token'] as String?) ?? '',
      attemptCount: (json['attempt_count'] as num?)?.toInt() ?? 1,
      maxAttempts: (json['max_attempts'] as num?)?.toInt() ?? 5,
    );
  }
}

enum FcmDeliveryOutcome { sent, retryable, failedPermanent, skipped }

class FcmSendResult {
  const FcmSendResult({
    required this.outcome,
    this.providerMessageId,
    this.errorCode,
    this.deactivateDevice = false,
  });

  const FcmSendResult.sent(String messageId)
    : outcome = FcmDeliveryOutcome.sent,
      providerMessageId = messageId,
      errorCode = null,
      deactivateDevice = false;

  const FcmSendResult.retryable(String code)
    : outcome = FcmDeliveryOutcome.retryable,
      providerMessageId = null,
      errorCode = code,
      deactivateDevice = false;

  const FcmSendResult.failedPermanent(
    String code, {
    this.deactivateDevice = false,
  }) : outcome = FcmDeliveryOutcome.failedPermanent,
       providerMessageId = null,
       errorCode = code;

  const FcmSendResult.skipped(String code)
    : outcome = FcmDeliveryOutcome.skipped,
      providerMessageId = null,
      errorCode = code,
      deactivateDevice = false;

  final FcmDeliveryOutcome outcome;
  final String? providerMessageId;
  final String? errorCode;
  final bool deactivateDevice;
}

class PushBatchReport {
  const PushBatchReport({
    this.claimed = 0,
    this.sent = 0,
    this.retryScheduled = 0,
    this.failedPermanent = 0,
    this.skipped = 0,
  });

  final int claimed;
  final int sent;
  final int retryScheduled;
  final int failedPermanent;
  final int skipped;
}

class NotificationsStatusSnapshot {
  const NotificationsStatusSnapshot({
    required this.fcmEnabled,
    required this.fcmConfigured,
    required this.supabaseBroadcastEnabled,
    required this.realtimeStreamAvailable,
  });

  final bool fcmEnabled;
  final bool fcmConfigured;
  final bool supabaseBroadcastEnabled;
  final bool realtimeStreamAvailable;

  Map<String, Object?> toJson() => {
    'fcm_enabled': fcmEnabled,
    'fcm_configured': fcmConfigured,
    'supabase_broadcast_enabled': supabaseBroadcastEnabled,
    'realtime_stream_available': realtimeStreamAvailable,
  };
}
