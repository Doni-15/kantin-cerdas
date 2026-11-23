import 'dart:async';
import 'dart:math';

import 'package:kantin_cerdas_backend/src/modules/notifications/domain/fcm_transport.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_models.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_store.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notifications_config.dart';

/// Drains public.order_notification_events via bounded single-in-flight batches.
/// Best-effort by contract (ORDER-017): push failures never roll back or alter order state.
class PushNotificationWorker {
  PushNotificationWorker({
    required this._store,
    required this._transport,
    required this._config,
    DateTime Function()? clock,
  }) : _clock = clock ?? _utcNow;

  final NotificationStore _store;
  final FcmTransport _transport;
  final NotificationsConfig _config;
  final DateTime Function() _clock;

  var _inFlight = false;
  Timer? _retryTimer;

  bool get isEnabled => _transport.isLiveEnabled;

  /// Bounded exponential backoff: 15s, 30s, 60s, 120s, 240s, capped at 600s.
  static int retryDelaySecondsForAttempt(int attemptCount) {
    final exponent = max(0, min(attemptCount - 1, 6));
    return min(600, 15 * (1 << exponent));
  }

  Future<PushBatchReport> processPendingBatch({
    DateTime? now,
    int batchSize = 25,
    bool scheduleRetryOnTransient = false,
  }) async {
    if (!isEnabled || _inFlight) {
      return const PushBatchReport();
    }
    _inFlight = true;
    final currentTime = (now ?? _clock()).toUtc();
    var claimed = 0;
    var sent = 0;
    var retryScheduled = 0;
    var failedPermanent = 0;
    var skipped = 0;
    int? earliestRetrySeconds;

    try {
      final deliveries = await _store.claimPendingPushDeliveries(
        batchSize: batchSize,
        maxAttempts: _config.fcmMaxRetryAttempts,
        now: currentTime,
      );
      claimed = deliveries.length;

      for (final delivery in deliveries) {
        final payload = FcmMessagePayload.tryBuild(delivery);
        if (payload == null) {
          skipped++;
          await _safeComplete(
            deliveryId: delivery.deliveryId,
            outcome: FcmDeliveryOutcome.skipped,
            errorCode: 'DISALLOWED_EVENT_OR_ROLE',
            now: currentTime,
          );
          continue;
        }

        FcmSendResult result;
        try {
          result = await _transport.send(payload);
        } catch (_) {
          result = const FcmSendResult.retryable('TRANSPORT_EXCEPTION');
        }

        switch (result.outcome) {
          case FcmDeliveryOutcome.sent:
            sent++;
            await _safeComplete(
              deliveryId: delivery.deliveryId,
              outcome: FcmDeliveryOutcome.sent,
              providerMessageId: result.providerMessageId,
              now: currentTime,
            );
          case FcmDeliveryOutcome.retryable:
            final delaySeconds = retryDelaySecondsForAttempt(
              delivery.attemptCount,
            );
            if (delivery.attemptCount >= delivery.maxAttempts) {
              failedPermanent++;
            } else {
              retryScheduled++;
              earliestRetrySeconds = earliestRetrySeconds == null
                  ? delaySeconds
                  : min(earliestRetrySeconds, delaySeconds);
            }
            await _safeComplete(
              deliveryId: delivery.deliveryId,
              outcome: FcmDeliveryOutcome.retryable,
              errorCode: result.errorCode ?? 'TRANSIENT_FAILURE',
              retryDelaySeconds: delaySeconds,
              now: currentTime,
            );
          case FcmDeliveryOutcome.failedPermanent:
            failedPermanent++;
            await _safeComplete(
              deliveryId: delivery.deliveryId,
              outcome: FcmDeliveryOutcome.failedPermanent,
              errorCode: result.errorCode ?? 'PERMANENT_FAILURE',
              deactivateDevice: result.deactivateDevice,
              now: currentTime,
            );
          case FcmDeliveryOutcome.skipped:
            skipped++;
            await _safeComplete(
              deliveryId: delivery.deliveryId,
              outcome: FcmDeliveryOutcome.skipped,
              errorCode: result.errorCode ?? 'SKIPPED',
              now: currentTime,
            );
        }
      }
    } catch (_) {
      // Best-effort worker: swallow store/network errors so API lifecycle stays unaffected.
    } finally {
      _inFlight = false;
    }

    if (scheduleRetryOnTransient &&
        earliestRetrySeconds != null &&
        _retryTimer == null) {
      _retryTimer = Timer(Duration(seconds: earliestRetrySeconds), () {
        _retryTimer = null;
        unawaited(processPendingBatch(scheduleRetryOnTransient: true));
      });
    }

    return PushBatchReport(
      claimed: claimed,
      sent: sent,
      retryScheduled: retryScheduled,
      failedPermanent: failedPermanent,
      skipped: skipped,
    );
  }

  Future<void> _safeComplete({
    required String deliveryId,
    required FcmDeliveryOutcome outcome,
    String? errorCode,
    String? providerMessageId,
    int retryDelaySeconds = 30,
    bool deactivateDevice = false,
    required DateTime now,
  }) async {
    try {
      await _store.completePushDelivery(
        deliveryId: deliveryId,
        outcome: outcome,
        errorCode: errorCode,
        providerMessageId: providerMessageId,
        retryDelaySeconds: retryDelaySeconds,
        deactivateDevice: deactivateDevice,
        now: now,
      );
    } catch (_) {
      // Locked row will safely expire and recover via crash-recovery claim window.
    }
  }

  void dispose() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }
}

DateTime _utcNow() => DateTime.now().toUtc();
