enum CustomerOrderStatus {
  menungguKonfirmasi('menunggu_konfirmasi', 'Menunggu Konfirmasi', false),
  diproses('diproses', 'Diproses', false),
  siapDiambil('siap_diambil', 'Siap Diambil', false),
  selesai('selesai', 'Selesai', true),
  dibatalkan('dibatalkan', 'Dibatalkan', true),
  ditolak('ditolak', 'Ditolak', true),
  gagalDipenuhi('gagal_dipenuhi', 'Gagal Dipenuhi', true),
  tidakDiambil('tidak_diambil', 'Tidak Diambil', true),
  gagalDiambil('gagal_diambil', 'Gagal Diambil', true);

  const CustomerOrderStatus(this.apiValue, this.label, this.isTerminal);

  final String apiValue;
  final String label;
  final bool isTerminal;

  bool get isActive => !isTerminal;
  bool get showBarcode => this == siapDiambil;
  bool get canCancel => this == menungguKonfirmasi;

  static CustomerOrderStatus fromApi(String raw) => values.firstWhere(
    (s) => s.apiValue == raw,
    orElse: () => throw FormatException('Unknown status: $raw'),
  );
}

enum CustomerOrderPaymentStatus {
  belumLunas('belum_lunas', 'Belum Lunas'),
  lunas('lunas', 'Lunas');

  const CustomerOrderPaymentStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static CustomerOrderPaymentStatus fromApi(String raw) => switch (raw) {
    'lunas' => lunas,
    'belum_lunas' => belumLunas,
    _ => throw FormatException('Unknown payment status: $raw'),
  };
}

class CustomerOrderSummary {
  const CustomerOrderSummary({
    required this.id,
    required this.orderNumber,
    required this.stallId,
    required this.stallName,
    required this.stallBlock,
    required this.stallCampus,
    required this.status,
    required this.paymentStatus,
    required this.generalNote,
    required this.totalAmount,
    required this.itemSummary,
    required this.itemCount,
    required this.createdAt,
    required this.updatedAt,
    this.prepEstimateMinutes,
    this.statusReason,
    this.acceptedAt,
    this.readyAt,
    this.terminalAt,
  });

  final String id;
  final String orderNumber;
  final String stallId;
  final String stallName;
  final String stallBlock;
  final String stallCampus;
  final CustomerOrderStatus status;
  final CustomerOrderPaymentStatus paymentStatus;
  final String generalNote;
  final int totalAmount;
  final int? prepEstimateMinutes;
  final String? statusReason;
  final String itemSummary;
  final int itemCount;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? readyAt;
  final DateTime? terminalAt;
  final DateTime updatedAt;

  factory CustomerOrderSummary.fromJson(Map<String, dynamic> json) =>
      CustomerOrderSummary(
        id: json['id'] as String,
        orderNumber: json['order_number'] as String,
        stallId: json['stall_id'] as String,
        stallName: json['stall_name'] as String? ?? 'Kantin',
        stallBlock: json['stall_block'] as String? ?? '',
        stallCampus: json['stall_campus'] as String? ?? '',
        status: CustomerOrderStatus.fromApi(json['status'] as String),
        paymentStatus: CustomerOrderPaymentStatus.fromApi(
          json['payment_status'] as String,
        ),
        generalNote: json['general_note'] as String? ?? '',
        totalAmount: json['total_amount'] as int,
        prepEstimateMinutes: json['prep_estimate_minutes'] as int?,
        statusReason: json['status_reason'] as String?,
        itemSummary: json['item_summary'] as String? ?? '',
        itemCount: json['item_count'] as int? ?? 0,
        createdAt: DateTime.parse(json['created_at'] as String),
        acceptedAt: json['accepted_at'] == null
            ? null
            : DateTime.parse(json['accepted_at'] as String),
        readyAt: json['ready_at'] == null
            ? null
            : DateTime.parse(json['ready_at'] as String),
        terminalAt: json['terminal_at'] == null
            ? null
            : DateTime.parse(json['terminal_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

class CustomerOrderItem {
  const CustomerOrderItem({
    required this.id,
    required this.menuName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
    required this.itemNote,
    this.menuItemId,
  });

  final String id;
  final String? menuItemId;
  final String menuName;
  final int unitPrice;
  final int quantity;
  final int lineTotal;
  final String itemNote;

  factory CustomerOrderItem.fromJson(Map<String, dynamic> json) =>
      CustomerOrderItem(
        id: json['id'] as String,
        menuItemId: json['menu_item_id'] as String?,
        menuName: json['menu_name'] as String,
        unitPrice: json['unit_price'] as int,
        quantity: json['quantity'] as int,
        lineTotal: json['line_total'] as int,
        itemNote: json['item_note'] as String? ?? '',
      );
}

class CustomerOrderEvent {
  const CustomerOrderEvent({
    required this.id,
    required this.toStatus,
    required this.actorRole,
    required this.createdAt,
    this.fromStatus,
    this.reason,
  });

  final String id;
  final CustomerOrderStatus? fromStatus;
  final CustomerOrderStatus toStatus;
  final String actorRole;
  final String? reason;
  final DateTime createdAt;

  factory CustomerOrderEvent.fromJson(Map<String, dynamic> json) =>
      CustomerOrderEvent(
        id: json['id'] as String,
        fromStatus: json['from_status'] == null
            ? null
            : CustomerOrderStatus.fromApi(json['from_status'] as String),
        toStatus: CustomerOrderStatus.fromApi(json['to_status'] as String),
        actorRole: json['actor_role'] as String,
        reason: json['reason'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

class CustomerOrderDetail {
  const CustomerOrderDetail({
    required this.summary,
    required this.items,
    required this.events,
  });

  final CustomerOrderSummary summary;
  final List<CustomerOrderItem> items;
  final List<CustomerOrderEvent> events;

  factory CustomerOrderDetail.fromJson(Map<String, dynamic> json) =>
      CustomerOrderDetail(
        summary: CustomerOrderSummary.fromJson(json),
        items: List<CustomerOrderItem>.unmodifiable([
          for (final item in json['items'] as List<dynamic>? ?? const [])
            CustomerOrderItem.fromJson(item as Map<String, dynamic>),
        ]),
        events: List<CustomerOrderEvent>.unmodifiable([
          for (final ev in json['events'] as List<dynamic>? ?? const [])
            CustomerOrderEvent.fromJson(ev as Map<String, dynamic>),
        ]),
      );
}

class CustomerCheckoutAttempt {
  const CustomerCheckoutAttempt({
    required this.attemptId,
    required this.cartVersion,
    required this.payloadHash,
  });

  final String attemptId;
  final int cartVersion;
  final String payloadHash;

  factory CustomerCheckoutAttempt.fromJson(Map<String, dynamic> json) =>
      CustomerCheckoutAttempt(
        attemptId: json['attempt_id'] as String,
        cartVersion: json['cart_version'] as int,
        payloadHash: json['payload_hash'] as String,
      );

  Map<String, Object?> toJson() => {
    'attempt_id': attemptId,
    'cart_version': cartVersion,
    'payload_hash': payloadHash,
  };
}

class CustomerCheckoutResult {
  const CustomerCheckoutResult({required this.replayed, required this.order});

  final bool replayed;
  final CustomerOrderDetail order;

  factory CustomerCheckoutResult.fromJson(Map<String, dynamic> json) =>
      CustomerCheckoutResult(
        replayed: json['replayed'] == true,
        order: CustomerOrderDetail.fromJson(
          json['order'] as Map<String, dynamic>,
        ),
      );
}

class CustomerAttemptLookupResult {
  const CustomerAttemptLookupResult({
    required this.attemptId,
    required this.status,
    this.order,
  });

  final String attemptId;
  final String status;
  final CustomerOrderDetail? order;

  factory CustomerAttemptLookupResult.fromJson(Map<String, dynamic> json) =>
      CustomerAttemptLookupResult(
        attemptId: json['attempt_id'] as String,
        status: json['status'] as String,
        order: json['order'] is Map<String, dynamic>
            ? CustomerOrderDetail.fromJson(
                json['order'] as Map<String, dynamic>,
              )
            : null,
      );
}
