import 'package:kantin_cerdas/core/storage/secure_mutation_journal_base.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences_snapshot.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/pending_food_preferences.dart';
import 'package:kantin_cerdas/features/customer/domain/repositories/food_preferences_journal.dart';

class SecureFoodPreferencesJournal
    extends SecureMutationJournalBase<PendingFoodPreferences>
    implements FoodPreferencesJournal {
  SecureFoodPreferencesJournal(super.storage);

  @override
  String get keyPrefix => 'kantin_cerdas.preferences.pending.v1';

  @override
  String get invalidMarkerMessage => 'Penanda preferensi tidak valid.';

  @override
  String get alreadyPendingMessage =>
      'Masih ada penyimpanan preferensi tertunda.';

  @override
  String actorIdOf(PendingFoodPreferences pending) => pending.customerId;

  @override
  String mutationIdOf(PendingFoodPreferences pending) => pending.mutationId;

  @override
  PendingFoodPreferences decodeEntry(
    String actorId,
    Map<String, Object?> data,
  ) {
    if (data['customerId'] != actorId ||
        data['mutationId'] is! String ||
        !data.containsKey('expectedVersion') ||
        (data['expectedVersion'] != null && data['expectedVersion'] is! int) ||
        !data.containsKey('maxBudgetIdr') ||
        (data['maxBudgetIdr'] != null && data['maxBudgetIdr'] is! int) ||
        data['vegetarian'] is! bool ||
        data['avoidIngredients'] is! List<Object?> ||
        (data['avoidIngredients']! as List<Object?>).any(
          (value) => value is! String,
        )) {
      throw const FormatException('Penanda preferensi tidak valid.');
    }
    return PendingFoodPreferences(
      customerId: actorId,
      mutationId: data['mutationId'] as String,
      update: FoodPreferencesUpdate(
        expectedVersion: data['expectedVersion'] as int?,
        preferences: FoodPreferences(
          maxBudgetIdr: data['maxBudgetIdr'] as int?,
          vegetarian: data['vegetarian'] as bool,
          avoidIngredients: (data['avoidIngredients']! as List<Object?>)
              .cast<String>(),
        ),
      ),
    );
  }

  @override
  Map<String, Object?> encodeEntry(PendingFoodPreferences pending) {
    final value = pending.update.preferences;
    return {
      'customerId': pending.customerId,
      'mutationId': pending.mutationId,
      'expectedVersion': pending.update.expectedVersion,
      'maxBudgetIdr': value.maxBudgetIdr,
      'vegetarian': value.vegetarian,
      'avoidIngredients': value.avoidIngredients,
    };
  }

  @override
  Future<PendingFoodPreferences?> read(String customerId) =>
      readEntry(customerId);

  @override
  Future<void> save(PendingFoodPreferences pending) => saveEntry(pending);

  @override
  Future<bool> clear({
    required String customerId,
    required String mutationId,
  }) => clearEntry(actorId: customerId, mutationId: mutationId);
}
