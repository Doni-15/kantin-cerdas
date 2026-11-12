import 'package:kantin_cerdas/core/storage/secure_mutation_journal_base.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_cancellation.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/pending_order_cancellation.dart';
import 'package:kantin_cerdas/features/customer/domain/repositories/order_cancellation_journal.dart';

class SecureOrderCancellationJournal
    extends SecureMutationJournalBase<PendingOrderCancellation>
    implements OrderCancellationJournal {
  SecureOrderCancellationJournal(super.storage);

  @override
  String get keyPrefix => 'kantin_cerdas.order.cancellation.v1';

  @override
  String get invalidMarkerMessage => 'Penanda pembatalan tidak valid.';

  @override
  String get alreadyPendingMessage => 'Masih ada pembatalan tertunda.';

  @override
  String actorIdOf(PendingOrderCancellation pending) => pending.customerId;

  @override
  String mutationIdOf(PendingOrderCancellation pending) => pending.mutationId;

  @override
  PendingOrderCancellation decodeEntry(
    String actorId,
    Map<String, Object?> data,
  ) {
    if (data['customerId'] != actorId ||
        data['mutationId'] is! String ||
        data['stallId'] is! String ||
        data['orderNumber'] is! String ||
        data['orderId'] is! String ||
        data['expectedVersion'] is! int) {
      throw const FormatException('Penanda pembatalan tidak valid.');
    }
    return PendingOrderCancellation(
      customerId: actorId,
      mutationId: data['mutationId'] as String,
      stallId: data['stallId'] as String,
      orderNumber: data['orderNumber'] as String,
      input: CustomerOrderCancellation(
        orderId: data['orderId'] as String,
        expectedVersion: data['expectedVersion'] as int,
      ),
    );
  }

  @override
  Map<String, Object?> encodeEntry(PendingOrderCancellation pending) => {
    'customerId': pending.customerId,
    'mutationId': pending.mutationId,
    'stallId': pending.stallId,
    'orderNumber': pending.orderNumber,
    'orderId': pending.orderId,
    'expectedVersion': pending.expectedVersion,
  };

  @override
  Future<PendingOrderCancellation?> read(String customerId) =>
      readEntry(customerId);

  @override
  Future<void> save(PendingOrderCancellation pending) => saveEntry(pending);

  @override
  Future<bool> clear({
    required String customerId,
    required String mutationId,
  }) => clearEntry(actorId: customerId, mutationId: mutationId);
}
