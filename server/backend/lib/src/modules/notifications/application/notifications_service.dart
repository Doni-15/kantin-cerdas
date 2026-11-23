import 'package:kantin_cerdas_backend/src/modules/notifications/application/push_notification_worker.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/application/realtime_signal_broker.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/fcm_transport.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_models.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_store.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notifications_config.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/realtime_broadcaster.dart';

class NotificationsService {
  NotificationsService({
    required NotificationStore store,
    required FcmTransport fcmTransport,
    required RealtimeBroadcaster broadcaster,
    required NotificationsConfig config,
    DateTime Function()? clock,
  }) : _store = store,
       _config = config,
       _fcmTransport = fcmTransport,
       _broadcaster = broadcaster,
       _broker = RealtimeSignalBroker(
         store: store,
         broadcaster: broadcaster,
         config: config,
       ),
       _pushWorker = PushNotificationWorker(
         store: store,
         transport: fcmTransport,
         config: config,
         clock: clock,
       );

  final NotificationStore _store;
  final NotificationsConfig _config;
  final FcmTransport _fcmTransport;
  final RealtimeBroadcaster _broadcaster;
  final RealtimeSignalBroker _broker;
  final PushNotificationWorker _pushWorker;

  NotificationsConfig get config => _config;
  RealtimeSignalBroker get broker => _broker;
  PushNotificationWorker get pushWorker => _pushWorker;

  NotificationsStatusSnapshot getStatus() {
    return NotificationsStatusSnapshot(
      fcmEnabled: _pushWorker.isEnabled,
      fcmConfigured: _config.hasCompleteFcmCredentials,
      supabaseBroadcastEnabled: _broadcaster.isEnabled,
      realtimeStreamAvailable: true,
    );
  }

  Future<PushDeviceRegistration> registerDevice({
    required String userId,
    required String deviceId,
    required String fcmToken,
    String platform = 'android',
  }) {
    return _store.registerPushDevice(
      userId: userId,
      deviceId: deviceId,
      fcmToken: fcmToken,
      platform: platform,
    );
  }

  Future<bool> revokeDevice({
    required String userId,
    required String deviceId,
    bool rotateTopics = true,
  }) {
    return _store.revokePushDevice(
      userId: userId,
      deviceId: deviceId,
      rotateTopics: rotateTopics,
    );
  }

  Future<RealtimeChannelGrant> getChannelGrant(String userId) {
    return _store.getChannelGrant(userId);
  }

  Future<RealtimeSignalsPage> pollSignals({
    required String userId,
    required int afterSeq,
    int limit = 50,
  }) {
    return _store.pollSignals(userId: userId, afterSeq: afterSeq, limit: limit);
  }

  /// Best-effort post-mutation hook: broadcasts new realtime signals and
  /// triggers push delivery without ever failing or delaying the order response.
  Future<void> dispatchPendingBestEffort() async {
    try {
      await _broker.flushPendingSignals();
    } catch (_) {
      // Best-effort.
    }
    if (_pushWorker.isEnabled) {
      try {
        await _pushWorker.processPendingBatch(
          scheduleRetryOnTransient: _config.fcmWorkerEnabled,
        );
      } catch (_) {
        // Best-effort.
      }
    }
  }

  void dispose() {
    _broker.dispose();
    _pushWorker.dispose();
    _broadcaster.close();
    _fcmTransport.close();
  }
}
