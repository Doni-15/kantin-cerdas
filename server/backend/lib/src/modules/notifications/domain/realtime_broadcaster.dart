import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_models.dart';

abstract interface class RealtimeBroadcaster {
  bool get isEnabled;

  /// Best-effort publish of minimal non-sensitive signals to Supabase Realtime Broadcast.
  Future<void> publish(List<UnbroadcastedRealtimeSignal> signals);

  void close();
}

class NoopRealtimeBroadcaster implements RealtimeBroadcaster {
  const NoopRealtimeBroadcaster();

  @override
  bool get isEnabled => false;

  @override
  Future<void> publish(List<UnbroadcastedRealtimeSignal> signals) async {}

  @override
  void close() {}
}
