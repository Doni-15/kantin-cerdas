import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/notifications/application/push_notification_coordinator.dart';
import 'package:kantin_cerdas/features/notifications/application/realtime_order_sync_controller.dart';
import 'package:kantin_cerdas/features/notifications/data/firebase_push_messaging_client.dart';
import 'package:kantin_cerdas/features/notifications/data/notifications_api_repository.dart';
import 'package:kantin_cerdas/features/notifications/data/push_device_bridge.dart';
import 'package:kantin_cerdas/features/notifications/domain/notification_models.dart';
import 'package:kantin_cerdas/features/notifications/domain/notifications_repository.dart';
import 'package:kantin_cerdas/features/notifications/domain/push_messaging_client.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsApiRepository(ref.watch(authRepositoryProvider)),
);

final pushMessagingClientProvider = Provider<PushMessagingClient>(
  (ref) => FirebasePushMessagingClient(),
);

final pushTokenSourceProvider = Provider<PushTokenSource>(
  (ref) => FirebasePushTokenSource(
    client: ref.watch(pushMessagingClientProvider),
    storage: kIsWeb ? null : const FlutterSecureStorage(),
  ),
);

/// Bounded exponential reconnect backoff schedule; overridable in tests.
final realtimeReconnectBackoffProvider = Provider<List<Duration>>(
  (ref) => const [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 8),
    Duration(seconds: 15),
  ],
);

final realtimeOrderSyncProvider = NotifierProvider.autoDispose
    .family<RealtimeOrderSyncNotifier, RealtimeSyncState, String>(
      RealtimeOrderSyncNotifier.new,
    );

final pushNotificationCoordinatorProvider =
    NotifierProvider<PushNotificationCoordinator, PushCoordinatorState>(
      PushNotificationCoordinator.new,
    );
