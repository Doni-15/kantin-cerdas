import 'package:characters/characters.dart';
import 'package:kantin_cerdas/core/utils/collection_equality.dart';

enum OrderStatus {
  waiting,
  processing,
  ready,
  completed,
  rejected,
  cancelled;

  static OrderStatus? tryFromRaw(String? raw) {
    return switch (raw?.trim().toLowerCase()) {
      'waiting' => OrderStatus.waiting,
      'processing' => OrderStatus.processing,
      'ready' => OrderStatus.ready,
      'completed' => OrderStatus.completed,
      'rejected' => OrderStatus.rejected,
      'cancelled' || 'canceled' => OrderStatus.cancelled,
      _ => null,
    };
  }
}

enum OrderPaymentStatus {
  unpaid,
  paid,
  notCharged;

  static OrderPaymentStatus? tryFromRaw(String? raw) {
    return switch (raw?.trim().toLowerCase()) {
      'unpaid' => OrderPaymentStatus.unpaid,
      'paid' => OrderPaymentStatus.paid,
      'not_charged' || 'notcharged' => OrderPaymentStatus.notCharged,
      _ => null,
    };
  }
}

extension OrderStatusGroup on OrderStatus {
  bool get isTerminal =>
      this == OrderStatus.completed ||
      this == OrderStatus.rejected ||
      this == OrderStatus.cancelled;
}

class OrderLine {
  OrderLine({
    required this.menuId,
    required this.name,
    required this.quantity,
    required this.unitPriceIdr,
    required this.note,
  }) {
    if (menuId.trim().isEmpty ||
        name.trim().isEmpty ||
        quantity < 1 ||
        quantity > 99 ||
        unitPriceIdr < 1 ||
        unitPriceIdr > 10000000 ||
        note.characters.length > 300) {
      throw ArgumentError('Rincian pesanan tidak valid.');
    }
  }
  final String menuId;
  final String name;
  final int quantity;
  final int unitPriceIdr;
  final String note;
  int get subtotal => quantity * unitPriceIdr;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderLine &&
          other.menuId == menuId &&
          other.name == name &&
          other.quantity == quantity &&
          other.unitPriceIdr == unitPriceIdr &&
          other.note == note);

  @override
  int get hashCode => Object.hash(menuId, name, quantity, unitPriceIdr, note);
}

/// Snapshot pesanan yang sudah dikonfirmasi layanan, bukan isi cart lokal.
class OrderRecord {
  OrderRecord({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.stallId,
    required this.stallName,
    required List<OrderLine> items,
    required this.status,
    required this.paymentStatus,
    required this.totalPriceIdr,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.rejectionReason,
  }) : items = List.unmodifiable(items) {
    if ([
          id,
          orderNumber,
          customerId,
          stallId,
          stallName,
        ].any((v) => v.trim().isEmpty) ||
        items.isEmpty ||
        totalPriceIdr < 0 ||
        note.characters.length > 300 ||
        version < 1) {
      throw ArgumentError('Pesanan tidak valid.');
    }
  }
  final String id;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final String stallId;
  final String stallName;
  final List<OrderLine> items;
  final OrderStatus status;
  final OrderPaymentStatus paymentStatus;
  final int totalPriceIdr;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final String? rejectionReason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderRecord &&
          other.id == id &&
          other.orderNumber == orderNumber &&
          other.customerId == customerId &&
          other.customerName == customerName &&
          other.stallId == stallId &&
          other.stallName == stallName &&
          other.status == status &&
          other.paymentStatus == paymentStatus &&
          other.totalPriceIdr == totalPriceIdr &&
          other.note == note &&
          other.createdAt.isAtSameMomentAs(createdAt) &&
          other.updatedAt.isAtSameMomentAs(updatedAt) &&
          other.version == version &&
          other.rejectionReason == rejectionReason &&
          listEquals(other.items, items));

  @override
  int get hashCode => Object.hash(
    id,
    orderNumber,
    customerId,
    customerName,
    stallId,
    stallName,
    status,
    paymentStatus,
    totalPriceIdr,
    note,
    createdAt.millisecondsSinceEpoch,
    updatedAt.millisecondsSinceEpoch,
    version,
    rejectionReason,
    Object.hashAll(items),
  );
}

class OrderRecordPage {
  OrderRecordPage({required List<OrderRecord> items, this.nextCursor})
    : items = List.unmodifiable(items) {
    if (nextCursor != null && nextCursor!.trim().isEmpty) {
      throw ArgumentError('Cursor pesanan tidak valid.');
    }
    if (this.items.map((item) => item.id).toSet().length != this.items.length) {
      throw ArgumentError('Daftar pesanan memuat ID duplikat.');
    }
  }
  final List<OrderRecord> items;
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderRecordPage &&
          other.nextCursor == nextCursor &&
          listEquals(other.items, items));

  @override
  int get hashCode => Object.hash(nextCursor, Object.hashAll(items));
}
