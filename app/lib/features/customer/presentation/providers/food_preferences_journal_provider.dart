import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/storage/mutation_journal_controller_base.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/pending_food_preferences.dart';
import 'package:kantin_cerdas/features/customer/domain/providers/customer_domain_providers.dart';

export 'package:kantin_cerdas/features/customer/domain/providers/customer_domain_providers.dart'
    show foodPreferencesJournalRepositoryProvider;

final foodPreferencesJournalProvider =
    AsyncNotifierProvider.family<
      FoodPreferencesJournalController,
      PendingFoodPreferences?,
      String
    >(FoodPreferencesJournalController.new, retry: (_, _) => null);

class FoodPreferencesJournalController
    extends MutationJournalControllerBase<PendingFoodPreferences> {
  FoodPreferencesJournalController(this.customerId);
  final String customerId;

  @override
  String get actorId => customerId;

  @override
  String pendingActorId(PendingFoodPreferences pending) => pending.customerId;

  @override
  String pendingMutationId(PendingFoodPreferences pending) =>
      pending.mutationId;

  @override
  Future<PendingFoodPreferences?> readJournal(String actorId) =>
      ref.read(foodPreferencesJournalRepositoryProvider).read(actorId);

  @override
  Future<void> saveJournal(PendingFoodPreferences pending) =>
      ref.read(foodPreferencesJournalRepositoryProvider).save(pending);

  @override
  Future<bool> clearJournal(String actorId, String mutationId) => ref
      .read(foodPreferencesJournalRepositoryProvider)
      .clear(customerId: actorId, mutationId: mutationId);
}
