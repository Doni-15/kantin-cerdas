import 'package:kantin_cerdas/features/customer/data/models/food_preferences_model.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences_snapshot.dart';

abstract interface class FoodPreferencesDataSource {
  bool get isSaveConfigured;
  Future<FoodPreferencesSnapshotModel?> getMyPreferences();
  Future<FoodPreferencesSnapshotModel> saveMyPreferences(
    FoodPreferencesUpdate update, {
    required String mutationId,
  });
  Future<FoodPreferencesLookup> lookupSave({required String mutationId});
}
