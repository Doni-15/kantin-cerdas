import 'package:kantin_cerdas/features/auth/domain/models/auth_account.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';

enum PushPermissionOutcome { granted, denied, notDetermined, unavailable }

enum PushTargetRole {
  customer('customer'),
  owner('owner');

  const PushTargetRole(this.wireValue);

  final String wireValue;

  static PushTargetRole? tryParse(String? raw) {
    if (raw == null) return null;
    for (final value in values) {
      if (value.wireValue == raw) return value;
    }
    return null;
  }
}

/// Strictly models the 7 FINAL/LOCKED push events in ORDER-017A.
/// `selesai`, `gagal_diambil`, and Admin notifications are intentionally rejected.
enum PushOrderEventType {
  orderCreated('order_created', PushTargetRole.owner),
  orderCancelled('order_cancelled', PushTargetRole.owner),
  orderAccepted('order_accepted', PushTargetRole.customer),
  orderRejected('order_rejected', PushTargetRole.customer),
  orderReady('order_ready', PushTargetRole.customer),
  orderFailedFulfill('order_failed_fulfill', PushTargetRole.customer),
  orderNotPickedUp('order_not_picked_up', PushTargetRole.customer);

  const PushOrderEventType(this.wireValue, this.expectedRole);

  final String wireValue;
  final PushTargetRole expectedRole;

  static PushOrderEventType? tryParse(String? raw) {
    if (raw == null) return null;
    for (final value in values) {
      if (value.wireValue == raw) return value;
    }
    return null;
  }
}

/// Minimal non-sensitive push notification payload received from FCM.
class PushNotificationPayload {
  const PushNotificationPayload({
    required this.eventId,
    required this.eventType,
    required this.orderId,
    required this.orderNumber,
    required this.targetRole,
    required this.title,
    required this.body,
  });

  final String eventId;
  final PushOrderEventType eventType;
  final String orderId;
  final String orderNumber;
  final PushTargetRole targetRole;
  final String title;
  final String body;

  /// Parses & validates an FCM `data` payload against the 7 ORDER-017A events.
  /// Returns `null` for malformed, disallowed (`selesai`, `gagal_diambil`, `admin`),
  /// or role-mismatched payloads.
  static PushNotificationPayload? tryParseRemoteData(
    Map<String, dynamic> data, {
    String? title,
    String? body,
  }) {
    final eventType = PushOrderEventType.tryParse(
      data['event_type']?.toString().trim(),
    );
    final targetRole = PushTargetRole.tryParse(
      data['recipient_role']?.toString().trim(),
    );
    final orderId = data['order_id']?.toString().trim() ?? '';
    if (eventType == null ||
        targetRole == null ||
        eventType.expectedRole != targetRole ||
        orderId.isEmpty) {
      return null;
    }

    final rawEventId = data['event_id']?.toString().trim() ?? '';
    final orderNumber = data['order_number']?.toString().trim() ?? '';
    final effectiveEventId = rawEventId.isNotEmpty
        ? rawEventId
        : '${eventType.wireValue}:$orderId';

    final resolvedTitle = (title?.trim().isNotEmpty ?? false)
        ? title!.trim()
        : _defaultTitle(eventType);
    final resolvedBody = (body?.trim().isNotEmpty ?? false)
        ? body!.trim()
        : _defaultBody(eventType, orderNumber);

    return PushNotificationPayload(
      eventId: effectiveEventId,
      eventType: eventType,
      orderId: orderId,
      orderNumber: orderNumber,
      targetRole: targetRole,
      title: resolvedTitle,
      body: resolvedBody,
    );
  }

  static String _defaultTitle(PushOrderEventType type) => switch (type) {
    PushOrderEventType.orderCreated => 'Pesanan baru masuk',
    PushOrderEventType.orderCancelled => 'Pesanan dibatalkan',
    PushOrderEventType.orderAccepted => 'Pesanan diterima',
    PushOrderEventType.orderRejected => 'Pesanan ditolak',
    PushOrderEventType.orderReady => 'Pesanan siap diambil',
    PushOrderEventType.orderFailedFulfill => 'Pesanan gagal dipenuhi',
    PushOrderEventType.orderNotPickedUp => 'Pesanan tidak diambil',
  };

  static String _defaultBody(PushOrderEventType type, String orderNumber) {
    final label = orderNumber.isEmpty ? 'Pesanan' : 'Pesanan #$orderNumber';
    return switch (type) {
      PushOrderEventType.orderCreated => '$label menunggu konfirmasi kantin.',
      PushOrderEventType.orderCancelled => '$label dibatalkan oleh pelanggan.',
      PushOrderEventType.orderAccepted => '$label sedang diproses kantin.',
      PushOrderEventType.orderRejected => '$label ditolak oleh kantin.',
      PushOrderEventType.orderReady => '$label siap diambil di kantin.',
      PushOrderEventType.orderFailedFulfill => '$label gagal dipenuhi kantin.',
      PushOrderEventType.orderNotPickedUp => '$label ditandai tidak diambil.',
    };
  }
}

class AuthorizedPushDestination {
  const AuthorizedPushDestination({
    required this.accountId,
    required this.orderId,
    required this.targetRole,
  });

  final String accountId;
  final String orderId;
  final PushTargetRole targetRole;
}

/// Enforces authentication & role authorization before opening any order screen
/// from a push notification (ORDER-017, ORDER-017A, ADMIN-005, R2).
///
/// Ownership of the concrete `orderId` is still verified authoritatively by Shelf
/// when the destination page loads the order detail endpoint.
AuthorizedPushDestination? resolveAuthorizedPushDestination({
  required AuthSession? session,
  required PushNotificationPayload payload,
}) {
  if (session == null || !session.account.profileComplete) {
    return null;
  }
  final role = session.account.role;
  if (role == AuthRole.admin) {
    return null;
  }
  if (payload.targetRole == PushTargetRole.owner && role != AuthRole.owner) {
    return null;
  }
  return AuthorizedPushDestination(
    accountId: session.account.id,
    orderId: payload.orderId,
    targetRole: payload.targetRole,
  );
}
