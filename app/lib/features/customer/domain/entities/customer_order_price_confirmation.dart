import 'package:kantin_cerdas/core/utils/collection_equality.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_draft.dart';
import 'package:kantin_cerdas/features/customer/domain/validation/customer_input_limits.dart';

enum CustomerOrderPaymentMethod { cashOnPickup }

/// Harga yang dilihat dan disetujui pengguna, bukan harga otoritatif server.
/// Layanan wajib membandingkannya secara atomik sebelum membuat pesanan.
/// Tidak ada biaya tambahan atau penggantian harga otomatis pada kontrak ini.
class CustomerOrderPriceConfirmation {
  CustomerOrderPriceConfirmation({
    required this.draft,
    required Map<String, int> unitPricesIdr,
  }) : unitPricesIdr = Map.unmodifiable(unitPricesIdr) {
    if (unitPricesIdr.length != draft.items.length ||
        draft.items.any(
          (item) =>
              !unitPricesIdr.containsKey(item.menuId) ||
              !CustomerInputLimits.validPrice(unitPricesIdr[item.menuId]!),
        )) {
      throw ArgumentError('Harga setiap menu harus tersedia dan valid.');
    }
  }

  final OrderDraft draft;
  final Map<String, int> unitPricesIdr;
  CustomerOrderPaymentMethod get paymentMethod =>
      CustomerOrderPaymentMethod.cashOnPickup;

  int get totalPriceIdr => draft.items.fold<int>(
    0,
    (total, item) => total + unitPricesIdr[item.menuId]! * item.quantity,
  );

  bool matchesDraft(OrderDraft other) {
    if (draft.stallId != other.stallId ||
        draft.orderNote != other.orderNote ||
        draft.items.length != other.items.length) {
      return false;
    }
    final byId = {for (final item in other.items) item.menuId: item};
    return draft.items.every((item) {
      final current = byId[item.menuId];
      return current != null &&
          current.quantity == item.quantity &&
          current.note == item.note;
    });
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerOrderPriceConfirmation &&
          other.draft == draft &&
          mapEquals(other.unitPricesIdr, unitPricesIdr));

  @override
  int get hashCode => Object.hash(draft, mapHashValue(unitPricesIdr));
}
