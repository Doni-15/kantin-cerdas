import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/storage/mutation_journal_controller_base.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/pending_canteen_application.dart';
import 'package:kantin_cerdas/features/customer/domain/providers/customer_domain_providers.dart';

export 'package:kantin_cerdas/features/customer/domain/providers/customer_domain_providers.dart'
    show canteenApplicationJournalRepositoryProvider;

final canteenApplicationJournalProvider =
    AsyncNotifierProvider.family<
      CanteenApplicationJournalController,
      PendingCanteenApplication?,
      String
    >(CanteenApplicationJournalController.new, retry: (_, _) => null);

class CanteenApplicationJournalController
    extends MutationJournalControllerBase<PendingCanteenApplication> {
  CanteenApplicationJournalController(this.customerId);
  final String customerId;

  @override
  String get actorId => customerId;

  @override
  String pendingActorId(PendingCanteenApplication pending) =>
      pending.customerId;

  @override
  String pendingMutationId(PendingCanteenApplication pending) =>
      pending.submissionId;

  @override
  Future<PendingCanteenApplication?> readJournal(String actorId) =>
      ref.read(canteenApplicationJournalRepositoryProvider).read(actorId);

  @override
  Future<void> saveJournal(PendingCanteenApplication pending) =>
      ref.read(canteenApplicationJournalRepositoryProvider).save(pending);

  @override
  Future<bool> clearJournal(String actorId, String mutationId) => ref
      .read(canteenApplicationJournalRepositoryProvider)
      .clear(customerId: actorId, submissionId: mutationId);
}
