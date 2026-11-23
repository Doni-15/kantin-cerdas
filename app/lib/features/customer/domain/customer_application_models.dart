enum OwnerApplicationStatus {
  menungguReview('menunggu_review', 'Menunggu Review'),
  disetujui('disetujui', 'Disetujui'),
  ditolak('ditolak', 'Ditolak');

  const OwnerApplicationStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static OwnerApplicationStatus fromApi(String raw) => switch (raw) {
    'menunggu_review' => menungguReview,
    'disetujui' => disetujui,
    'ditolak' => ditolak,
    _ => throw FormatException('Unknown application status: $raw'),
  };
}

class OwnerApplication {
  const OwnerApplication({
    required this.id,
    required this.plannedStallName,
    required this.plannedLocation,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.rejectionReason,
    this.decidedAt,
  });

  final String id;
  final String plannedStallName;
  final String plannedLocation;
  final String reason;
  final OwnerApplicationStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? decidedAt;

  factory OwnerApplication.fromJson(Map<String, dynamic> json) =>
      OwnerApplication(
        id: json['id'] as String,
        plannedStallName: json['planned_stall_name'] as String,
        plannedLocation: json['planned_location'] as String,
        reason: json['reason'] as String,
        status: OwnerApplicationStatus.fromApi(json['status'] as String),
        rejectionReason: json['rejection_reason'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        decidedAt: json['decided_at'] == null
            ? null
            : DateTime.parse(json['decided_at'] as String),
      );
}

class CustomerActiveOrderIndicator {
  const CustomerActiveOrderIndicator({
    required this.hasActiveOrders,
    required this.activeOrderCount,
  });

  final bool hasActiveOrders;
  final int activeOrderCount;

  factory CustomerActiveOrderIndicator.fromJson(Map<String, dynamic> json) =>
      CustomerActiveOrderIndicator(
        hasActiveOrders: json['has_active_orders'] == true,
        activeOrderCount: json['active_order_count'] as int? ?? 0,
      );
}

class CustomerOwnerApplicationState {
  const CustomerOwnerApplicationState({
    required this.activeOrderIndicator,
    this.latestApplication,
  });

  final OwnerApplication? latestApplication;
  final CustomerActiveOrderIndicator activeOrderIndicator;

  factory CustomerOwnerApplicationState.fromJson(Map<String, dynamic> json) =>
      CustomerOwnerApplicationState(
        latestApplication: json['latest_application'] is Map<String, dynamic>
            ? OwnerApplication.fromJson(
                json['latest_application'] as Map<String, dynamic>,
              )
            : null,
        activeOrderIndicator: CustomerActiveOrderIndicator.fromJson(
          json['active_order_indicator'] as Map<String, dynamic>? ?? const {},
        ),
      );
}
