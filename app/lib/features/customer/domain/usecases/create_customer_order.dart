import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_price_confirmation.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_draft.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_order_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/repositories/customer_order_repository.dart';

/// Mengajukan pembuatan pesanan melalui kontrak repository.
///
/// Tidak mengubah keranjang, menyimpan state UI, atau melakukan navigasi.
class CreateCustomerOrder {
  const CreateCustomerOrder(this._repository);

  final CustomerOrderRepository _repository;

  /// Mengembalikan ID pesanan yang telah dikonfirmasi backend.
  ///
  /// Kegagalan repository diteruskan kepada pemanggil tanpa diubah menjadi
  /// keberhasilan. Tidak ada retry otomatis karena pengulangan request
  /// pembuatan pesanan membutuhkan mekanisme idempotensi dari backend.
  Future<String> execute({
    required OrderDraft draft,
    required String submissionId,
    required CustomerOrderPriceConfirmation confirmation,
  }) {
    if (!_repository.isCheckoutConfigured) {
      return Future.error(const CustomerOrderNotConfiguredFailure());
    }
    if (!confirmation.matchesDraft(draft)) {
      return Future.error(const CustomerOrderPreSendFailure());
    }
    return _repository.createOrder(
      draft: draft,
      submissionId: submissionId,
      confirmation: confirmation,
    );
  }
}
