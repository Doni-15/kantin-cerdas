import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_models.dart';

/// Minimal, non-sensitive FCM HTTP v1 payload for one of the 7 ORDER-017A events.
/// Never includes email, phone, address, item prices, totals, or auth tokens.
class FcmMessagePayload {
  const FcmMessagePayload({
    required this.token,
    required this.title,
    required this.body,
    required this.data,
  });

  final String token;
  final String title;
  final String body;
  final Map<String, String> data;

  static FcmMessagePayload? tryBuild(PendingPushDelivery delivery) {
    final eventType = PushEventType.tryParse(delivery.eventType);
    final recipientRole = PushRecipientRole.tryParse(delivery.recipientRole);
    if (eventType == null ||
        recipientRole == null ||
        eventType.expectedRecipientRole != recipientRole) {
      return null;
    }

    final safeOrderNumber = delivery.orderNumber.trim();
    final orderLabel = safeOrderNumber.isEmpty
        ? 'Pesanan'
        : 'Pesanan #$safeOrderNumber';
    final (title, body) = switch (eventType) {
      PushEventType.orderCreated => (
        'Pesanan baru masuk',
        '$orderLabel menunggu konfirmasi kantin.',
      ),
      PushEventType.orderCancelled => (
        'Pesanan dibatalkan',
        '$orderLabel dibatalkan oleh pelanggan.',
      ),
      PushEventType.orderAccepted => (
        'Pesanan diterima',
        '$orderLabel sedang diproses oleh kantin.',
      ),
      PushEventType.orderRejected => (
        'Pesanan ditolak',
        '$orderLabel ditolak oleh kantin. Buka aplikasi untuk melihat detail.',
      ),
      PushEventType.orderReady => (
        'Pesanan siap diambil',
        '$orderLabel siap diambil di kantin. Tunjukkan kode pengambilan.',
      ),
      PushEventType.orderFailedFulfill => (
        'Pesanan gagal dipenuhi',
        '$orderLabel tidak dapat dipenuhi oleh kantin. Buka aplikasi untuk detail.',
      ),
      PushEventType.orderNotPickedUp => (
        'Pesanan ditandai tidak diambil',
        '$orderLabel berakhir dengan status tidak diambil.',
      ),
    };

    return FcmMessagePayload(
      token: delivery.fcmToken,
      title: title,
      body: body,
      data: {
        'event_id': delivery.notificationEventId,
        'event_type': eventType.wireValue,
        'order_id': delivery.orderId,
        'order_number': safeOrderNumber,
        'recipient_role': recipientRole.wireValue,
      },
    );
  }

  /// FCM HTTP v1 `messages:send` JSON envelope.
  Map<String, Object?> toFcmV1RequestBody() => {
    'message': {
      'token': token,
      'notification': {'title': title, 'body': body},
      'data': data,
      'android': {
        'priority': 'HIGH',
        'notification': {
          'channel_id': 'kantin_order_updates',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      },
    },
  };
}

abstract interface class FcmTransport {
  bool get isLiveEnabled;

  Future<FcmSendResult> send(FcmMessagePayload payload);

  void close();
}

/// Safe default when FCM_ENABLED=false: never makes external HTTP calls.
class DisabledFcmTransport implements FcmTransport {
  const DisabledFcmTransport();

  @override
  bool get isLiveEnabled => false;

  @override
  Future<FcmSendResult> send(FcmMessagePayload payload) async =>
      const FcmSendResult.skipped('FCM_DISABLED');

  @override
  void close() {}
}

typedef FakeFcmHandler = FcmSendResult Function(FcmMessagePayload payload);

/// Deterministic fake transport for local tests & local QA without Firebase credentials.
class FakeFcmTransport implements FcmTransport {
  FakeFcmTransport({this._onSend});

  final FakeFcmHandler? _onSend;
  final List<FcmMessagePayload> sentPayloads = <FcmMessagePayload>[];
  var _counter = 0;

  @override
  bool get isLiveEnabled => true;

  @override
  Future<FcmSendResult> send(FcmMessagePayload payload) async {
    sentPayloads.add(payload);
    final custom = _onSend;
    if (custom != null) {
      return custom(payload);
    }
    _counter++;
    return FcmSendResult.sent('projects/local-fake/messages/$_counter');
  }

  @override
  void close() {}
}
