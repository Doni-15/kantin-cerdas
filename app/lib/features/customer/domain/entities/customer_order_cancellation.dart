import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';

/// Intent pembatalan saja. Identitas pemilik, status, dan pembayaran
/// ditentukan serta diperiksa oleh layanan, bukan dikirim sebagai hak akses.
class CustomerOrderCancellation {
  CustomerOrderCancellation({
    required this.orderId,
    required this.expectedVersion,
  }) {
    if (orderId.trim().isEmpty || expectedVersion < 1) {
      throw ArgumentError('Permintaan pembatalan tidak valid.');
    }
  }
  final String orderId;
  final int expectedVersion;

  static bool canCancel(OrderRecord order, {required String customerId}) =>
      customerId.trim().isNotEmpty &&
      order.customerId == customerId &&
      order.status == OrderStatus.waiting &&
      order.paymentStatus == OrderPaymentStatus.unpaid;

  bool canApplyTo(OrderRecord order, {required String customerId}) =>
      order.id == orderId &&
      order.version == expectedVersion &&
      canCancel(order, customerId: customerId);

  /// Pembatalan mengubah status, pembayaran, updatedAt dan versi saja.
  bool acceptsResult({
    required OrderRecord before,
    required OrderRecord after,
    required String customerId,
  }) {
    if (!canApplyTo(before, customerId: customerId) ||
        after.id != orderId ||
        after.customerId != customerId ||
        after.stallId != before.stallId ||
        after.orderNumber != before.orderNumber ||
        after.customerName != before.customerName ||
        after.stallName != before.stallName ||
        after.version <= expectedVersion ||
        after.status != OrderStatus.cancelled ||
        after.paymentStatus != OrderPaymentStatus.notCharged ||
        after.totalPriceIdr != before.totalPriceIdr ||
        after.note != before.note ||
        after.rejectionReason != before.rejectionReason ||
        !after.createdAt.isAtSameMomentAs(before.createdAt) ||
        after.updatedAt.isBefore(before.updatedAt) ||
        after.items.length != before.items.length) {
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
      (other is CustomerOrderCancellation &&
          other.orderId == orderId &&
          other.expectedVersion == expectedVersion);

  @override
  int get hashCode => Object.hash(orderId, expectedVersion);
}
