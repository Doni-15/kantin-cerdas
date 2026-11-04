import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/storage/mutation_journal_controller_base.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/pending_order_cancellation.dart';
import 'package:kantin_cerdas/features/customer/domain/providers/customer_domain_providers.dart';

export 'package:kantin_cerdas/features/customer/domain/providers/customer_domain_providers.dart'
    show orderCancellationJournalRepositoryProvider;

final orderCancellationJournalProvider =
    AsyncNotifierProvider.family<
      OrderCancellationJournalController,
      PendingOrderCancellation?,
      String
    >(OrderCancellationJournalController.new, retry: (_, _) => null);

class OrderCancellationJournalController
    extends MutationJournalControllerBase<PendingOrderCancellation> {
  OrderCancellationJournalController(this.customerId);
  final String customerId;

  @override
  String get actorId => customerId;

  @override
  String pendingActorId(PendingOrderCancellation pending) => pending.customerId;

  @override
  String pendingMutationId(PendingOrderCancellation pending) =>
      pending.mutationId;

  @override
  Future<PendingOrderCancellation?> readJournal(String actorId) =>
      ref.read(orderCancellationJournalRepositoryProvider).read(actorId);

  @override
  Future<void> saveJournal(PendingOrderCancellation pending) =>
      ref.read(orderCancellationJournalRepositoryProvider).save(pending);

  @override
  Future<bool> clearJournal(String actorId, String mutationId) => ref
      .read(orderCancellationJournalRepositoryProvider)
      .clear(customerId: actorId, mutationId: mutationId);
}
