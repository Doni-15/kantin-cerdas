import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/session/auth_state_provider.dart';
import 'package:kantin_cerdas/core/session/user_role.dart';
import 'package:kantin_cerdas/core/storage/mutation_journal_controller_base.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/pending_order_submission.dart';
import 'package:kantin_cerdas/features/customer/domain/providers/customer_domain_providers.dart';

export 'package:kantin_cerdas/features/customer/domain/providers/customer_domain_providers.dart'
    show orderSubmissionJournalProvider;

final customerCheckoutJournalProvider =
    AsyncNotifierProvider.family<
      CustomerCheckoutJournal,
      PendingOrderSubmission?,
      String
    >(CustomerCheckoutJournal.new, retry: (_, _) => null);

class CustomerCheckoutJournal
    extends MutationJournalControllerBase<PendingOrderSubmission> {
  CustomerCheckoutJournal(this.customerId);
  final String customerId;

  @override
  String get actorId => customerId;

  @override
  String pendingActorId(PendingOrderSubmission pending) => pending.customerId;

  @override
  String pendingMutationId(PendingOrderSubmission pending) =>
      pending.submissionId;

  @override
  Future<PendingOrderSubmission?> readJournal(String actorId) =>
      ref.read(orderSubmissionJournalProvider).read(actorId);

  @override
  Future<void> saveJournal(PendingOrderSubmission pending) =>
      ref.read(orderSubmissionJournalProvider).save(pending);

  @override
  Future<bool> clearJournal(String actorId, String mutationId) => ref
      .read(orderSubmissionJournalProvider)
      .clear(customerId: actorId, submissionId: mutationId);
}

final customerCheckoutLockedProvider = Provider<bool>((ref) {
  final auth = ref.watch(authStateProvider);
  final user = auth.isLoading ? null : auth.asData?.value;
  if (user == null || !user.isActive || !user.role.canUseCustomerFeatures) {
    return true;
  }
  final journal = ref.watch(customerCheckoutJournalProvider(user.id));
  return journal.isLoading ||
      journal.hasError ||
      journal.asData == null ||
      journal.asData!.value != null;
});
