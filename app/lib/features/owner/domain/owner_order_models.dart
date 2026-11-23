import 'package:kantin_cerdas/features/owner/domain/owner_stall_models.dart';

enum OwnerOrderStatus {
  menungguKonfirmasi('menunggu_konfirmasi', 'Menunggu Konfirmasi', true),
  diproses('diproses', 'Diproses', true),
  siapDiambil('siap_diambil', 'Siap Diambil', true),
  selesai('selesai', 'Selesai', false),
  dibatalkan('dibatalkan', 'Dibatalkan', false),
  ditolak('ditolak', 'Ditolak', false),
  gagalDipenuhi('gagal_dipenuhi', 'Gagal Dipenuhi', false),
  tidakDiambil('tidak_diambil', 'Tidak Diambil', false),
  gagalDiambil('gagal_diambil', 'Gagal Diambil', false);

  const OwnerOrderStatus(this.apiValue, this.label, this.isActive);

  final String apiValue;
  final String label;
  final bool isActive;

  static OwnerOrderStatus parse(String raw) => values.firstWhere(
    (s) => s.apiValue == raw,
    orElse: () => throw FormatException('Unknown order status: $raw'),
  );
}

enum OwnerPaymentStatus {
  belumLunas('belum_lunas', 'Belum Lunas'),
  lunas('lunas', 'Lunas');

  const OwnerPaymentStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static OwnerPaymentStatus parse(String raw) => values.firstWhere(
    (s) => s.apiValue == raw,
    orElse: () => throw FormatException('Unknown payment status: $raw'),
  );
}

class OwnerOrderSummary {
  const OwnerOrderSummary({
    required this.id,
    required this.orderNumber,
    required this.stallId,
    required this.customerName,
    required this.status,
    required this.paymentStatus,
    required this.generalNote,
    required this.totalAmount,
    required this.prepEstimateMinutes,
    required this.statusReason,
    required this.createdAt,
    required this.acceptedAt,
    required this.readyAt,
    required this.terminalAt,
    required this.updatedAt,
    required this.itemSummary,
    required this.itemCount,
  });

  final String id;
  final String orderNumber;
  final String stallId;
  final String customerName;
  final OwnerOrderStatus status;
  final OwnerPaymentStatus paymentStatus;
  final String generalNote;
  final int totalAmount;
  final int? prepEstimateMinutes;
  final String? statusReason;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? readyAt;
  final DateTime? terminalAt;
  final DateTime updatedAt;
  final String itemSummary;
  final int itemCount;

  factory OwnerOrderSummary.fromJson(Map<String, dynamic> json) =>
      OwnerOrderSummary(
        id: json['id'] as String,
        orderNumber: json['order_number'] as String,
        stallId: json['stall_id'] as String,
        customerName: json['customer_name'] as String,
        status: OwnerOrderStatus.parse(json['status'] as String),
        paymentStatus: OwnerPaymentStatus.parse(
          json['payment_status'] as String,
        ),
        generalNote: json['general_note'] as String? ?? '',
        totalAmount: json['total_amount'] as int,
        prepEstimateMinutes: json['prep_estimate_minutes'] as int?,
        statusReason: json['status_reason'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        acceptedAt: _parseOptionalDate(json['accepted_at']),
        readyAt: _parseOptionalDate(json['ready_at']),
        terminalAt: _parseOptionalDate(json['terminal_at']),
        updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
        itemSummary: json['item_summary'] as String? ?? '',
        itemCount: json['item_count'] as int? ?? 0,
      );
}

class OwnerOrderItemSnapshot {
  const OwnerOrderItemSnapshot({
    required this.id,
    required this.menuItemId,
    required this.menuName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    required this.itemNote,
  });

  final String id;
  final String? menuItemId;
  final String menuName;
  final int unitPrice;
  final int quantity;
  final int lineTotal;
  final String itemNote;

  factory OwnerOrderItemSnapshot.fromJson(Map<String, dynamic> json) =>
      OwnerOrderItemSnapshot(
        id: json['id'] as String,
        menuItemId: json['menu_item_id'] as String?,
        menuName: json['menu_name'] as String,
        unitPrice: json['unit_price'] as int,
        quantity: json['quantity'] as int,
        lineTotal: json['line_total'] as int,
        itemNote: json['item_note'] as String? ?? '',
      );
}

class OwnerOrderEvent {
  const OwnerOrderEvent({
    required this.id,
    required this.fromStatus,
    required this.toStatus,
    required this.actorRole,
    required this.reason,
    required this.createdAt,
  });

  final String id;
  final OwnerOrderStatus? fromStatus;
  final OwnerOrderStatus toStatus;
  final String actorRole;
  final String? reason;
  final DateTime createdAt;

  factory OwnerOrderEvent.fromJson(Map<String, dynamic> json) =>
      OwnerOrderEvent(
        id: json['id'] as String,
        fromStatus: json['from_status'] == null
            ? null
            : OwnerOrderStatus.parse(json['from_status'] as String),
        toStatus: OwnerOrderStatus.parse(json['to_status'] as String),
        actorRole: json['actor_role'] as String,
        reason: json['reason'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      );
}

class OwnerOrderDetail {
  const OwnerOrderDetail({
    required this.summary,
    required this.items,
    required this.events,
  });

  final OwnerOrderSummary summary;
  final List<OwnerOrderItemSnapshot> items;
  final List<OwnerOrderEvent> events;

  factory OwnerOrderDetail.fromJson(Map<String, dynamic> json) =>
      OwnerOrderDetail(
        summary: OwnerOrderSummary.fromJson(json),
        items: List<OwnerOrderItemSnapshot>.unmodifiable([
          for (final item in json['items'] as List<dynamic>? ?? const [])
            OwnerOrderItemSnapshot.fromJson(item as Map<String, dynamic>),
        ]),
        events: List<OwnerOrderEvent>.unmodifiable([
          for (final ev in json['events'] as List<dynamic>? ?? const [])
            OwnerOrderEvent.fromJson(ev as Map<String, dynamic>),
        ]),
      );
}

class OwnerActiveCounts {
  const OwnerActiveCounts({
    required this.menungguKonfirmasi,
    required this.diproses,
    required this.siapDiambil,
  });

  final int menungguKonfirmasi;
  final int diproses;
  final int siapDiambil;

  factory OwnerActiveCounts.fromJson(Map<String, dynamic> json) =>
      OwnerActiveCounts(
        menungguKonfirmasi: json['menunggu_konfirmasi'] as int? ?? 0,
        diproses: json['diproses'] as int? ?? 0,
        siapDiambil: json['siap_diambil'] as int? ?? 0,
      );
}

class OwnerDashboard {
  const OwnerDashboard({
    required this.stallBundle,
    required this.activeCounts,
    required this.attentionOrders,
  });

  final OwnerStallBundle stallBundle;
  final OwnerActiveCounts activeCounts;
  final List<OwnerOrderSummary> attentionOrders;

  factory OwnerDashboard.fromJson(Map<String, dynamic> json) => OwnerDashboard(
    stallBundle: OwnerStallBundle.fromJson(json),
    activeCounts: OwnerActiveCounts.fromJson(
      json['active_counts'] as Map<String, dynamic>? ?? const {},
    ),
    attentionOrders: List<OwnerOrderSummary>.unmodifiable([
      for (final item in json['attention_orders'] as List<dynamic>? ?? const [])
        OwnerOrderSummary.fromJson(item as Map<String, dynamic>),
    ]),
  );
}

DateTime? _parseOptionalDate(Object? raw) =>
    raw is String ? DateTime.parse(raw).toLocal() : null;
