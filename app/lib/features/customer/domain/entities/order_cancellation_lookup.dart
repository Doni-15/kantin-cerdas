import 'package:kantin_cerdas/features/customer/domain/entities/pending_order_cancellation.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';

enum OrderCancellationOutcome { pending, applied, notApplied }

/// Receipt immutable pada commit pembatalan; bukan status pesanan terbaru.
class OrderCancellationLookup {
  OrderCancellationLookup({
    required this.request,
    required this.outcome,
    this.resultVersion,
    this.status,
    this.paymentStatus,
  }) {
    if (outcome == OrderCancellationOutcome.applied) {
      if (resultVersion == null ||
          resultVersion! <= request.expectedVersion ||
          status != OrderStatus.cancelled ||
          paymentStatus != OrderPaymentStatus.notCharged) {
        throw ArgumentError('Receipt pembatalan tidak sesuai intent.');
      }
    } else if (resultVersion != null ||
        status != null ||
        paymentStatus != null) {
      throw ArgumentError(
        'Receipt tanpa commit tidak boleh membawa hasil sukses.',
      );
    }
  }
  final PendingOrderCancellation request;
  final OrderCancellationOutcome outcome;
  final int? resultVersion;
  final OrderStatus? status;
  final OrderPaymentStatus? paymentStatus;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderCancellationLookup &&
          other.request == request &&
          other.outcome == outcome &&
          other.resultVersion == resultVersion &&
          other.status == status &&
          other.paymentStatus == paymentStatus);

  @override
  int get hashCode =>
      Object.hash(request, outcome, resultVersion, status, paymentStatus);
}
