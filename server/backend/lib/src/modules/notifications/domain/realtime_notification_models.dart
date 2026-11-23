class RealtimeChannelGrant {
  const RealtimeChannelGrant({
    required this.userId,
    required this.role,
    required this.customerTopic,
    required this.customerEpoch,
    required this.lastSeq,
    this.stallId,
    this.stallTopic,
    this.stallEpoch,
  });

  final String userId;
  final String role;
  final String customerTopic;
  final int customerEpoch;
  final String? stallId;
  final String? stallTopic;
  final int? stallEpoch;
  final int lastSeq;

  factory RealtimeChannelGrant.fromJson(Map<String, Object?> json) {
    return RealtimeChannelGrant(
      userId: (json['user_id'] as String?) ?? '',
      role: (json['role'] as String?) ?? 'customer',
      customerTopic: (json['customer_topic'] as String?) ?? '',
      customerEpoch: (json['customer_epoch'] as num?)?.toInt() ?? 1,
      stallId: json['stall_id'] as String?,
      stallTopic: json['stall_topic'] as String?,
      stallEpoch: (json['stall_epoch'] as num?)?.toInt(),
      lastSeq: (json['last_seq'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toJson() => {
    'role': role,
    'customer_topic': customerTopic,
    'customer_epoch': customerEpoch,
    'stall_id': stallId,
    'stall_topic': stallTopic,
    'stall_epoch': stallEpoch,
    'last_seq': lastSeq,
  };
}

/// Minimal non-sensitive realtime order signal (RT-TECH-003).
/// Clients use this signal strictly as a wake-up trigger to re-fetch
/// authoritative details via authenticated Shelf REST endpoints.
class RealtimeOrderSignal {
  const RealtimeOrderSignal({
    required this.seq,
    required this.eventId,
    required this.orderId,
    required this.stallId,
    required this.toStatus,
    required this.audienceScope,
    required this.createdAt,
  });

  final int seq;
  final String eventId;
  final String orderId;
  final String stallId;
  final String toStatus;
  final String audienceScope;
  final DateTime createdAt;

  factory RealtimeOrderSignal.fromJson(Map<String, Object?> json) {
    return RealtimeOrderSignal(
      seq: (json['seq'] as num?)?.toInt() ?? 0,
      eventId: (json['event_id'] as String?) ?? '',
      orderId: (json['order_id'] as String?) ?? '',
      stallId: (json['stall_id'] as String?) ?? '',
      toStatus: (json['to_status'] as String?) ?? '',
      audienceScope: (json['audience_scope'] as String?) ?? 'customer',
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ??
          DateTime.now().toUtc(),
    );
  }

  Map<String, Object?> toJson() => {
    'seq': seq,
    'event_id': eventId,
    'order_id': orderId,
    'stall_id': stallId,
    'to_status': toStatus,
    'audience_scope': audienceScope,
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}

class RealtimeSignalsPage {
  const RealtimeSignalsPage({
    required this.items,
    required this.lastSeq,
    required this.customerEpoch,
    this.stallEpoch,
  });

  final List<RealtimeOrderSignal> items;
  final int lastSeq;
  final int customerEpoch;
  final int? stallEpoch;

  factory RealtimeSignalsPage.fromJson(Map<String, Object?> json) {
    final rawItems = json['items'];
    final items = <RealtimeOrderSignal>[
      if (rawItems is List)
        for (final item in rawItems)
          if (item is Map)
            RealtimeOrderSignal.fromJson(Map<String, Object?>.from(item)),
    ];
    return RealtimeSignalsPage(
      items: items,
      lastSeq: (json['last_seq'] as num?)?.toInt() ?? 0,
      customerEpoch: (json['customer_epoch'] as num?)?.toInt() ?? 1,
      stallEpoch: (json['stall_epoch'] as num?)?.toInt(),
    );
  }

  Map<String, Object?> toJson() => {
    'items': [for (final item in items) item.toJson()],
    'last_seq': lastSeq,
    'customer_epoch': customerEpoch,
    'stall_epoch': stallEpoch,
  };
}

class UnbroadcastedRealtimeSignal {
  const UnbroadcastedRealtimeSignal({
    required this.seq,
    required this.eventId,
    required this.orderId,
    required this.stallId,
    required this.customerId,
    required this.ownerId,
    required this.toStatus,
    required this.customerTopic,
    required this.stallTopic,
    required this.createdAt,
  });

  final int seq;
  final String eventId;
  final String orderId;
  final String stallId;
  final String customerId;
  final String ownerId;
  final String toStatus;
  final String customerTopic;
  final String stallTopic;
  final DateTime createdAt;

  factory UnbroadcastedRealtimeSignal.fromJson(Map<String, Object?> json) {
    return UnbroadcastedRealtimeSignal(
      seq: (json['seq'] as num?)?.toInt() ?? 0,
      eventId: (json['event_id'] as String?) ?? '',
      orderId: (json['order_id'] as String?) ?? '',
      stallId: (json['stall_id'] as String?) ?? '',
      customerId: (json['customer_id'] as String?) ?? '',
      ownerId: (json['owner_id'] as String?) ?? '',
      toStatus: (json['to_status'] as String?) ?? '',
      customerTopic: (json['customer_topic'] as String?) ?? '',
      stallTopic: (json['stall_topic'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ??
          DateTime.now().toUtc(),
    );
  }

  /// Minimal non-sensitive broadcast payload safe for private Realtime topics.
  Map<String, Object?> toBroadcastPayload() => {
    'seq': seq,
    'event_id': eventId,
    'order_id': orderId,
    'stall_id': stallId,
    'to_status': toStatus,
    'created_at': createdAt.toUtc().toIso8601String(),
  };

  RealtimeOrderSignal toScopedSignal(String audienceScope) =>
      RealtimeOrderSignal(
        seq: seq,
        eventId: eventId,
        orderId: orderId,
        stallId: stallId,
        toStatus: toStatus,
        audienceScope: audienceScope,
        createdAt: createdAt,
      );
}
