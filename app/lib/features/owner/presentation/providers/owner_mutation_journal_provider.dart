import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/storage/mutation_journal_controller_base.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/pending_owner_mutation.dart';
import 'package:kantin_cerdas/features/owner/domain/providers/owner_domain_providers.dart';

export 'package:kantin_cerdas/features/owner/domain/providers/owner_domain_providers.dart'
    show ownerMutationJournalRepositoryProvider;

final ownerMutationJournalProvider =
    AsyncNotifierProvider.family<
      OwnerMutationJournalController,
      PendingOwnerMutation?,
      String
    >(OwnerMutationJournalController.new, retry: (_, _) => null);

class OwnerMutationJournalController
    extends MutationJournalControllerBase<PendingOwnerMutation> {
  OwnerMutationJournalController(this.ownerId);
  final String ownerId;

  @override
  String get actorId => ownerId;

  @override
  String pendingActorId(PendingOwnerMutation pending) => pending.ownerId;

  @override
  String pendingMutationId(PendingOwnerMutation pending) => pending.mutationId;

  @override
  Future<PendingOwnerMutation?> readJournal(String actorId) =>
      ref.read(ownerMutationJournalRepositoryProvider).read(actorId);

  @override
  Future<void> saveJournal(PendingOwnerMutation pending) =>
      ref.read(ownerMutationJournalRepositoryProvider).save(pending);

  @override
  Future<bool> clearJournal(String actorId, String mutationId) => ref
      .read(ownerMutationJournalRepositoryProvider)
      .clear(ownerId: actorId, mutationId: mutationId);
}
