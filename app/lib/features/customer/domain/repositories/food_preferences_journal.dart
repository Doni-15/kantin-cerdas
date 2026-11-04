import 'package:kantin_cerdas/features/customer/domain/entities/pending_food_preferences.dart';

abstract interface class FoodPreferencesJournal {
  Future<PendingFoodPreferences?> read(String customerId);
  Future<void> save(PendingFoodPreferences pending);
  Future<bool> clear({required String customerId, required String mutationId});
}
