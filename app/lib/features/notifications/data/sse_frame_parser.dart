import 'dart:async';
import 'dart:convert';

import 'package:kantin_cerdas/features/notifications/domain/notification_models.dart';

/// Incremental Server-Sent Events (SSE) parser converting UTF-8 byte chunks
/// into typed [RealtimeStreamFrame] instances.
Stream<RealtimeStreamFrame> parseRealtimeSseStream(
  Stream<List<int>> byteStream,
) {
  return Stream<RealtimeStreamFrame>.multi((multi) {
    var currentEvent = 'message';
    final dataLines = <String>[];

    void dispatchIfReady() {
      if (dataLines.isEmpty) {
        currentEvent = 'message';
        return;
      }
      final rawData = dataLines.join('\n');
      final eventName = currentEvent;
      dataLines.clear();
      currentEvent = 'message';

      final frame = _decodeFrame(eventName, rawData);
      if (frame != null && !multi.isClosed) {
        multi.add(frame);
      }
    }

    final sub = byteStream
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen(
          (line) {
            if (line.isEmpty) {
              dispatchIfReady();
              return;
            }
            if (line.startsWith(':')) {
              // Heartbeat comment (`: ping`).
              return;
            }
            if (line.startsWith('event:')) {
              currentEvent = line.substring(6).trim();
              return;
            }
            if (line.startsWith('data:')) {
              var payload = line.substring(5);
              if (payload.startsWith(' ')) payload = payload.substring(1);
              dataLines.add(payload);
              return;
            }
          },
          onError: (Object error, StackTrace stack) {
            if (!multi.isClosed) multi.addError(error, stack);
          },
          onDone: () {
            dispatchIfReady();
            if (!multi.isClosed) multi.close();
          },
          cancelOnError: false,
        );

    multi.onCancel = sub.cancel;
  });
}

RealtimeStreamFrame? _decodeFrame(String eventName, String rawData) {
  try {
    final decoded = jsonDecode(rawData);
    if (decoded is! Map) return null;
    final map = Map<String, dynamic>.from(decoded);
    return switch (eventName) {
      'connected' => RealtimeConnectedFrame(
        lastSeq: (map['last_seq'] as num?)?.toInt() ?? 0,
        customerEpoch: (map['customer_epoch'] as num?)?.toInt() ?? 1,
        stallEpoch: (map['stall_epoch'] as num?)?.toInt(),
      ),
      'order_signal' => RealtimeOrderSignalFrame(
        RealtimeOrderSignal.fromJson(map),
      ),
      'topic_rotated' => RealtimeTopicRotatedFrame(
        customerEpoch: (map['customer_epoch'] as num?)?.toInt() ?? 1,
        stallEpoch: (map['stall_epoch'] as num?)?.toInt(),
      ),
      'session_revoked' => RealtimeSessionRevokedFrame(
        (map['reason'] as String?) ?? 'SESSION_REVOKED',
      ),
      _ => null,
    };
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  }
}
