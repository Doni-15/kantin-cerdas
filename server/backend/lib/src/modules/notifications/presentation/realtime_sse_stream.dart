import 'dart:async';
import 'dart:convert';

import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/application/notifications_service.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_errors.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_models.dart';
import 'package:shelf/shelf.dart';

/// Authenticated Server-Sent Events (SSE) real-time stream with continuous
/// session re-validation and topic-rotation detection (R2, RT-TECH-003, RT-TECH-005).
Future<Response> openRealtimeSseStream({
  required AuthGateway auth,
  required NotificationsService service,
  required String bearer,
  required AuthAccount actor,
  required int afterSeq,
  required int? maxDurationSeconds,
}) async {
  final grant = await service.getChannelGrant(actor.id);
  final catchUp = await service.pollSignals(
    userId: actor.id,
    afterSeq: afterSeq,
    limit: 50,
  );

  final controller = StreamController<List<int>>();
  var closed = false;
  var lastEmittedSeq = catchUp.lastSeq > afterSeq ? catchUp.lastSeq : afterSeq;
  var trackedCustomerEpoch = catchUp.customerEpoch;
  var trackedStallEpoch = catchUp.stallEpoch;
  var rechecking = false;

  void Function()? unsubscribe;
  Timer? heartbeatTimer;
  Timer? sessionRecheckTimer;
  Timer? maxDurationTimer;

  void emitSse(String event, Map<String, Object?> payload, {int? id}) {
    if (closed || controller.isClosed) return;
    final buffer = StringBuffer();
    if (id != null) buffer.writeln('id: $id');
    buffer
      ..writeln('event: $event')
      ..writeln('data: ${jsonEncode(payload)}')
      ..writeln();
    controller.add(utf8.encode(buffer.toString()));
  }

  void emitComment(String comment) {
    if (closed || controller.isClosed) return;
    controller.add(utf8.encode(': $comment\n\n'));
  }

  void shutdown() {
    if (closed) return;
    closed = true;
    unsubscribe?.call();
    unsubscribe = null;
    heartbeatTimer?.cancel();
    heartbeatTimer = null;
    sessionRecheckTimer?.cancel();
    sessionRecheckTimer = null;
    maxDurationTimer?.cancel();
    maxDurationTimer = null;
    if (!controller.isClosed) {
      unawaited(controller.close());
    }
  }

  Future<void> recheckSessionAndCatchUp() async {
    if (closed || rechecking) return;
    rechecking = true;
    try {
      final refreshedActor = await auth.account(bearer);
      if (closed) return;
      if (refreshedActor.id != actor.id ||
          (refreshedActor.role != AccountRole.customer &&
              refreshedActor.role != AccountRole.owner)) {
        emitSse('session_revoked', const {'reason': 'ROLE_OR_SESSION_CHANGED'});
        shutdown();
        return;
      }
      final page = await service.pollSignals(
        userId: actor.id,
        afterSeq: lastEmittedSeq,
        limit: 50,
      );
      if (closed) return;
      if (page.customerEpoch != trackedCustomerEpoch ||
          page.stallEpoch != trackedStallEpoch) {
        trackedCustomerEpoch = page.customerEpoch;
        trackedStallEpoch = page.stallEpoch;
        emitSse('topic_rotated', {
          'customer_epoch': trackedCustomerEpoch,
          'stall_epoch': trackedStallEpoch,
        });
      }
      for (final signal in page.items) {
        if (signal.seq > lastEmittedSeq) {
          lastEmittedSeq = signal.seq;
          emitSse('order_signal', signal.toJson(), id: signal.seq);
        }
      }
    } on AuthFailure {
      emitSse('session_revoked', const {'reason': 'SESSION_REVOKED'});
      shutdown();
    } on NotificationFailure catch (failure) {
      if (failure.code == NotificationFailureCode.accountInactive ||
          failure.code == NotificationFailureCode.roleNotAllowed) {
        emitSse('session_revoked', const {'reason': 'ACCOUNT_REVOKED'});
        shutdown();
      }
    } catch (_) {
      // Transient store outage: keep stream alive until next check.
    } finally {
      rechecking = false;
    }
  }

  controller.onListen = () {
    emitSse('connected', {
      'role': grant.role,
      'customer_epoch': grant.customerEpoch,
      'stall_epoch': grant.stallEpoch,
      'last_seq': lastEmittedSeq,
    });

    for (final signal in catchUp.items) {
      if (signal.seq > afterSeq) {
        if (signal.seq > lastEmittedSeq) lastEmittedSeq = signal.seq;
        emitSse('order_signal', signal.toJson(), id: signal.seq);
      }
    }

    unsubscribe = service.broker.subscribe(
      userId: actor.id,
      isOwner: actor.role == AccountRole.owner,
      onSignal: (RealtimeOrderSignal signal) {
        if (closed || signal.seq <= lastEmittedSeq) return;
        lastEmittedSeq = signal.seq;
        emitSse('order_signal', signal.toJson(), id: signal.seq);
      },
    );

    heartbeatTimer = Timer.periodic(
      service.config.realtimeStreamHeartbeat,
      (_) => emitComment('ping'),
    );
    sessionRecheckTimer = Timer.periodic(
      service.config.realtimeSessionRecheck,
      (_) => unawaited(recheckSessionAndCatchUp()),
    );
    if (maxDurationSeconds != null) {
      maxDurationTimer = Timer(Duration(seconds: maxDurationSeconds), shutdown);
    }
  };

  controller.onCancel = shutdown;

  return Response.ok(
    controller.stream,
    headers: const {
      'content-type': 'text/event-stream; charset=utf-8',
      'cache-control': 'no-store',
      'connection': 'keep-alive',
      'x-accel-buffering': 'no',
    },
    context: const {'shelf.io.buffer_output': false},
  );
}
