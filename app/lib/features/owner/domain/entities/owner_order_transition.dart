import 'package:characters/characters.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:kantin_cerdas/features/orders/domain/validation/order_record_rules.dart';

class OwnerOrderTransition {
  OwnerOrderTransition({
    required this.orderId,
    required this.status,
    required this.expectedVersion,
    String reason = '',
    this.cashReceived = false,
    this.foodHandedOver = false,
  }) : reason = reason.trim() {
    final completing = status == OrderStatus.completed;
    final rejecting = status == OrderStatus.rejected;
    if (orderId.trim().isEmpty ||
        expectedVersion < 1 ||
        this.reason.characters.length > 300 ||
        status == OrderStatus.waiting ||
        status == OrderStatus.cancelled ||
        (rejecting ? this.reason.isEmpty : this.reason.isNotEmpty) ||
        (completing
            ? (!cashReceived || !foodHandedOver)
            : (cashReceived || foodHandedOver))) {
      throw ArgumentError('Perubahan status pesanan tidak valid.');
    }
  }

  final String orderId;
  final OrderStatus status;
  final int expectedVersion;
  final String reason;
  final bool cashReceived;
  final bool foodHandedOver;

  /// Kontrak pesanan tunai: pembayaran dicatat saat serah terima selesai.
  static bool hasConsistentPayment(OrderRecord order) =>
      OrderRecordRules.hasConsistentPayment(order);

  static bool canMoveTo(OrderRecord order, OrderStatus target) {
    if (!hasConsistentPayment(order)) {
      return false;
    }
    return switch (order.status) {
      OrderStatus.waiting =>
        target == OrderStatus.processing || target == OrderStatus.rejected,
      OrderStatus.processing => target == OrderStatus.ready,
      OrderStatus.ready => target == OrderStatus.completed,
      _ => false,
    };
  }

  bool canApplyTo(OrderRecord order) =>
      order.id == orderId &&
      order.version == expectedVersion &&
      canMoveTo(order, status);

  /// Sukses harus sesuai intent, maju versi, serta mempertahankan snapshot.
  /// Hasil tidak konsisten dianggap belum pasti, bukan sukses lokal.
  bool acceptsResult({
    required OrderRecord before,
    required OrderRecord after,
  }) {
    if (!canApplyTo(before) ||
        after.id != orderId ||
        after.stallId != before.stallId ||
        after.customerId != before.customerId ||
        after.orderNumber != before.orderNumber ||
        after.customerName != before.customerName ||
        after.stallName != before.stallName ||
        !after.createdAt.isAtSameMomentAs(before.createdAt) ||
        after.updatedAt.isBefore(before.updatedAt) ||
        after.version <= expectedVersion ||
        after.status != status ||
        !hasConsistentPayment(after) ||
        after.totalPriceIdr != before.totalPriceIdr ||
        after.note != before.note ||
        after.items.length != before.items.length ||
        (status == OrderStatus.rejected
            ? after.rejectionReason?.trim() != reason
            : after.rejectionReason != null)) {
      return false;
    }
    for (var index = 0; index < before.items.length; index++) {
      final old = before.items[index];
      final updated = after.items[index];
      if (updated.menuId != old.menuId ||
          updated.name != old.name ||
          updated.quantity != old.quantity ||
          updated.unitPriceIdr != old.unitPriceIdr ||
          updated.note != old.note) {
        return false;
      }
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OwnerOrderTransition &&
          other.orderId == orderId &&
          other.status == status &&
          other.expectedVersion == expectedVersion &&
          other.reason == reason &&
          other.cashReceived == cashReceived &&
          other.foodHandedOver == foodHandedOver);

  @override
  int get hashCode => Object.hash(
    orderId,
    status,
    expectedVersion,
    reason,
    cashReceived,
    foodHandedOver,
  );
}
