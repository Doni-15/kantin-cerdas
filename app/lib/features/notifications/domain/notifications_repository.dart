import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
import 'package:kantin_cerdas/features/notifications/domain/notification_models.dart';

class RealtimeStreamHandle {
  const RealtimeStreamHandle({required this.frames, required this.close});

  final Stream<RealtimeStreamFrame> frames;
  final Future<void> Function() close;
}

abstract interface class NotificationsRepository {
  Future<RealtimeChannelGrant> fetchChannelGrant(AuthSession session);

  Future<RealtimeSignalsPage> pollSignals(
    AuthSession session, {
    required int afterSeq,
    int limit = 50,
  });

  Future<RealtimeStreamHandle> openRealtimeStream(
    AuthSession session, {
    required int afterSeq,
  });

  Future<void> registerPushDevice(
    AuthSession session, {
    required String deviceId,
    required String fcmToken,
  });

  Future<void> revokePushDevice(
    AuthSession session, {
    required String deviceId,
    bool rotateTopics = true,
  });
}
