import 'package:characters/characters.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';

/// Pesanan tunai tanpa biaya tambahan; pembayaran dicatat saat serah terima.
abstract final class OrderRecordRules {
  static bool hasConsistentPayment(OrderRecord order) => switch (order.status) {
    OrderStatus.waiting ||
    OrderStatus.processing ||
    OrderStatus.ready => order.paymentStatus == OrderPaymentStatus.unpaid,
    OrderStatus.completed => order.paymentStatus == OrderPaymentStatus.paid,
    OrderStatus.rejected || OrderStatus.cancelled =>
      order.paymentStatus == OrderPaymentStatus.notCharged,
  };

  static bool hasConsistentSnapshot(OrderRecord order) {
    final reason = order.rejectionReason?.trim() ?? '';
    return hasConsistentPayment(order) &&
        order.totalPriceIdr ==
            order.items.fold<int>(0, (sum, item) => sum + item.subtotal) &&
        !order.updatedAt.isBefore(order.createdAt) &&
        order.items.map((item) => item.menuId).toSet().length ==
            order.items.length &&
        (order.status == OrderStatus.rejected
            ? reason.isNotEmpty && reason.characters.length <= 300
            : reason.isEmpty);
  }
}
