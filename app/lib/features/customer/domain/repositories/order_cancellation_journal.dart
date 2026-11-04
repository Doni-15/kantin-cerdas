import 'package:kantin_cerdas/features/customer/domain/entities/pending_order_cancellation.dart';

abstract interface class OrderCancellationJournal {
  Future<PendingOrderCancellation?> read(String customerId);
  Future<void> save(PendingOrderCancellation pending);
  Future<bool> clear({required String customerId, required String mutationId});
}
