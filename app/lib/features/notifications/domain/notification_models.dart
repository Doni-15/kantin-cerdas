enum RealtimeConnectionMode {
  idle,
  connecting,
  live,
  reconnecting,
  restFallback,
  revoked,
}

class RealtimeChannelGrant {
  const RealtimeChannelGrant({
    required this.role,
    required this.customerTopic,
    required this.customerEpoch,
    required this.lastSeq,
    this.stallId,
    this.stallTopic,
    this.stallEpoch,
  });

  final String role;
  final String customerTopic;
  final int customerEpoch;
  final String? stallId;
  final String? stallTopic;
  final int? stallEpoch;
  final int lastSeq;

  factory RealtimeChannelGrant.fromJson(Map<String, dynamic> json) {
    return RealtimeChannelGrant(
      role: (json['role'] as String?) ?? 'customer',
      customerTopic: (json['customer_topic'] as String?) ?? '',
      customerEpoch: (json['customer_epoch'] as num?)?.toInt() ?? 1,
      stallId: json['stall_id'] as String?,
      stallTopic: json['stall_topic'] as String?,
      stallEpoch: (json['stall_epoch'] as num?)?.toInt(),
      lastSeq: (json['last_seq'] as num?)?.toInt() ?? 0,
    );
  }
}

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

  bool get targetsCustomer =>
      audienceScope == 'customer' || audienceScope == 'both';

  bool get targetsOwner => audienceScope == 'owner' || audienceScope == 'both';

  factory RealtimeOrderSignal.fromJson(Map<String, dynamic> json) {
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

  factory RealtimeSignalsPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return RealtimeSignalsPage(
      items: [
        for (final item in rawItems)
          if (item is Map<String, dynamic>) RealtimeOrderSignal.fromJson(item),
      ],
      lastSeq: (json['last_seq'] as num?)?.toInt() ?? 0,
      customerEpoch: (json['customer_epoch'] as num?)?.toInt() ?? 1,
      stallEpoch: (json['stall_epoch'] as num?)?.toInt(),
    );
  }
}

sealed class RealtimeStreamFrame {
  const RealtimeStreamFrame();
}

class RealtimeConnectedFrame extends RealtimeStreamFrame {
  const RealtimeConnectedFrame({
    required this.lastSeq,
    required this.customerEpoch,
    this.stallEpoch,
  });

  final int lastSeq;
  final int customerEpoch;
  final int? stallEpoch;
}

class RealtimeOrderSignalFrame extends RealtimeStreamFrame {
  const RealtimeOrderSignalFrame(this.signal);

  final RealtimeOrderSignal signal;
}

class RealtimeTopicRotatedFrame extends RealtimeStreamFrame {
  const RealtimeTopicRotatedFrame({
    required this.customerEpoch,
    this.stallEpoch,
  });

  final int customerEpoch;
  final int? stallEpoch;
}

class RealtimeSessionRevokedFrame extends RealtimeStreamFrame {
  const RealtimeSessionRevokedFrame(this.reason);

  final String reason;
}

class RealtimeSyncState {
  const RealtimeSyncState({
    this.mode = RealtimeConnectionMode.idle,
    this.lastSeq = 0,
    this.customerEpoch = 1,
    this.stallEpoch,
    this.receivedSignals = 0,
    this.lastOrderId,
    this.lastStatus,
  });

  final RealtimeConnectionMode mode;
  final int lastSeq;
  final int customerEpoch;
  final int? stallEpoch;
  final int receivedSignals;
  final String? lastOrderId;
  final String? lastStatus;

  bool get isLive => mode == RealtimeConnectionMode.live;

  RealtimeSyncState copyWith({
    RealtimeConnectionMode? mode,
    int? lastSeq,
    int? customerEpoch,
    int? stallEpoch,
    int? receivedSignals,
    String? lastOrderId,
    String? lastStatus,
  }) {
    return RealtimeSyncState(
      mode: mode ?? this.mode,
      lastSeq: lastSeq ?? this.lastSeq,
      customerEpoch: customerEpoch ?? this.customerEpoch,
      stallEpoch: stallEpoch ?? this.stallEpoch,
      receivedSignals: receivedSignals ?? this.receivedSignals,
      lastOrderId: lastOrderId ?? this.lastOrderId,
      lastStatus: lastStatus ?? this.lastStatus,
    );
  }
}
