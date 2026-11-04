import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/storage/mutation_journal_controller_base.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/pending_admin_mutation.dart';
import 'package:kantin_cerdas/features/admin/domain/providers/admin_domain_providers.dart';

export 'package:kantin_cerdas/features/admin/domain/providers/admin_domain_providers.dart'
    show adminMutationJournalRepositoryProvider;

final adminMutationJournalProvider =
    AsyncNotifierProvider.family<
      AdminMutationJournalController,
      PendingAdminMutation?,
      String
    >(AdminMutationJournalController.new, retry: (_, _) => null);

class AdminMutationJournalController
    extends MutationJournalControllerBase<PendingAdminMutation> {
  AdminMutationJournalController(this.adminId);
  final String adminId;

  @override
  String get actorId => adminId;

  @override
  String pendingActorId(PendingAdminMutation pending) => pending.adminId;

  @override
  String pendingMutationId(PendingAdminMutation pending) => pending.mutationId;

  @override
  Future<PendingAdminMutation?> readJournal(String actorId) =>
      ref.read(adminMutationJournalRepositoryProvider).read(actorId);

  @override
  Future<void> saveJournal(PendingAdminMutation pending) =>
      ref.read(adminMutationJournalRepositoryProvider).save(pending);

  @override
  Future<bool> clearJournal(String actorId, String mutationId) => ref
      .read(adminMutationJournalRepositoryProvider)
      .clear(adminId: actorId, mutationId: mutationId);
}
