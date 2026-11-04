import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/pending_owner_mutation.dart';

enum OwnerMutationOutcome { pending, applied, notApplied }

/// Receipt immutable dari mutasi, bukan kesimpulan dari data terkini.
class OwnerMutationLookup {
  OwnerMutationLookup({
    required this.request,
    required this.outcome,
    this.resultId,
    this.resultVersion,
    this.orderStatus,
    this.paymentStatus,
  }) {
    final applied = outcome == OwnerMutationOutcome.applied;
    if (applied
        ? (resultId == null ||
              resultId!.trim().isEmpty ||
              resultVersion == null ||
              resultVersion! < 1)
        : (resultId != null ||
              resultVersion != null ||
              orderStatus != null ||
              paymentStatus != null)) {
      throw ArgumentError('Receipt perubahan owner tidak valid.');
    }
    if (applied) {
      if ((request.targetId != null && resultId != request.targetId) ||
          (request.expectedVersion != null &&
              resultVersion! <= request.expectedVersion!)) {
        throw ArgumentError('Identitas atau versi receipt tidak sesuai.');
      }
      if (request.kind == OwnerMutationKind.transitionOrder) {
        final expectedPayment = switch (request.orderStatus!) {
          OrderStatus.completed => OrderPaymentStatus.paid,
          OrderStatus.rejected => OrderPaymentStatus.notCharged,
          _ => OrderPaymentStatus.unpaid,
        };
        if (orderStatus != request.orderStatus ||
            paymentStatus != expectedPayment) {
          throw ArgumentError('Status receipt pesanan tidak sesuai intent.');
        }
      } else if (orderStatus != null || paymentStatus != null) {
        throw ArgumentError('Receipt non-pesanan memuat status pesanan.');
      }
    }
  }
  final PendingOwnerMutation request;
  final OwnerMutationOutcome outcome;
  final String? resultId;

  /// Untuk delete: versi tombstone yang lebih baru dari expectedVersion.
  final int? resultVersion;
  final OrderStatus? orderStatus;
  final OrderPaymentStatus? paymentStatus;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OwnerMutationLookup &&
          other.request == request &&
          other.outcome == outcome &&
          other.resultId == resultId &&
          other.resultVersion == resultVersion &&
          other.orderStatus == orderStatus &&
          other.paymentStatus == paymentStatus);

  @override
  int get hashCode => Object.hash(
    request,
    outcome,
    resultId,
    resultVersion,
    orderStatus,
    paymentStatus,
  );
}
