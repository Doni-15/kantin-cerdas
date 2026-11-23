import 'dart:async';

import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_models.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_store.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notifications_config.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/realtime_broadcaster.dart';

class _SignalSubscriber {
  _SignalSubscriber({
    required this.userId,
    required this.isOwner,
    required this.onSignal,
  });

  final String userId;
  final bool isOwner;
  final void Function(RealtimeOrderSignal signal) onSignal;
}

/// Bridges persisted `order_realtime_signals` to:
/// 1. Supabase Realtime HTTP Broadcast API (when configured/enabled)
/// 2. Live authenticated Shelf SSE subscribers (strictly scoped per user/owner)
///
/// Lazy-polls ONLY while at least one SSE subscriber is connected so zero idle
/// timers linger during automated tests or idle periods.
class RealtimeSignalBroker {
  RealtimeSignalBroker({
    required this._store,
    required this._broadcaster,
    required this._config,
  });

  final NotificationStore _store;
  final RealtimeBroadcaster _broadcaster;
  final NotificationsConfig _config;

  final Set<_SignalSubscriber> _subscribers = <_SignalSubscriber>{};
  Timer? _pollTimer;
  var _flushing = false;

  int get subscriberCount => _subscribers.length;

  /// Registers a strictly user-scoped subscriber and returns an unsubscribe handle.
  void Function() subscribe({
    required String userId,
    required bool isOwner,
    required void Function(RealtimeOrderSignal signal) onSignal,
  }) {
    final sub = _SignalSubscriber(
      userId: userId,
      isOwner: isOwner,
      onSignal: onSignal,
    );
    _subscribers.add(sub);
    _ensurePollTimer();

    return () {
      _subscribers.remove(sub);
      if (_subscribers.isEmpty) {
        _pollTimer?.cancel();
        _pollTimer = null;
      }
    };
  }

  /// Claims any unbroadcasted signals from DB, sends them to Supabase Broadcast
  /// (when enabled), and fans out to matching in-process SSE subscribers.
  Future<int> flushPendingSignals({DateTime? now}) async {
    if (_flushing) return 0;
    _flushing = true;
    try {
      final claimed = await _store.claimUnbroadcastedSignals(
        limit: 50,
        now: now,
      );
      if (claimed.isEmpty) return 0;

      if (_broadcaster.isEnabled) {
        await _broadcaster.publish(claimed);
      }

      if (_subscribers.isNotEmpty) {
        for (final signal in claimed) {
          for (final sub in List<_SignalSubscriber>.of(_subscribers)) {
            final matchesCustomer = signal.customerId == sub.userId;
            final matchesOwner = sub.isOwner && signal.ownerId == sub.userId;
            if (!matchesCustomer && !matchesOwner) continue;
            final scope = matchesCustomer && matchesOwner
                ? 'both'
                : matchesOwner
                ? 'owner'
                : 'customer';
            sub.onSignal(signal.toScopedSignal(scope));
          }
        }
      }

      return claimed.length;
    } catch (_) {
      // Best-effort: SSE clients and mobile apps recover via cursor catch-up.
      return 0;
    } finally {
      _flushing = false;
    }
  }

  void _ensurePollTimer() {
    if (_pollTimer != null) return;
    _pollTimer = Timer.periodic(_config.realtimeSignalPollInterval, (_) {
      unawaited(flushPendingSignals());
    });
  }

  void dispose() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _subscribers.clear();
  }
}
