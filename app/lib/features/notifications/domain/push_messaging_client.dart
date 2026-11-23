import 'package:kantin_cerdas/features/notifications/domain/push_notification_payload.dart';

/// Platform messaging boundary separating Firebase SDK calls from domain logic
/// so unit & widget tests run deterministically without live Firebase credentials.
abstract interface class PushMessagingClient {
  Future<bool> ensureInitialized();

  Future<PushPermissionOutcome> requestNotificationPermission();

  Future<String?> getToken();

  Stream<String> get onTokenRefresh;

  Stream<PushNotificationPayload> get onForegroundMessage;

  Stream<PushNotificationPayload> get onMessageOpenedApp;

  Future<PushNotificationPayload?> getInitialMessage();
}
