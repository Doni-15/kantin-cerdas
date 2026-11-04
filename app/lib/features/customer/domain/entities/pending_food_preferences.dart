import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences_snapshot.dart';

/// Snapshot disimpan sebelum kirim; hanya untuk pencocokan receipt, bukan retry.
class PendingFoodPreferences {
  PendingFoodPreferences({
    required this.customerId,
    required this.mutationId,
    required this.update,
  }) {
    if (customerId.trim().isEmpty || mutationId.trim().isEmpty) {
      throw ArgumentError('Identitas penyimpanan preferensi tidak valid.');
    }
  }
  final String customerId;
  final String mutationId;
  final FoodPreferencesUpdate update;
  bool matches(PendingFoodPreferences other) =>
      customerId == other.customerId &&
      mutationId == other.mutationId &&
      update.expectedVersion == other.update.expectedVersion &&
      update.preferences.sameAs(other.update.preferences);
  bool accepts(FoodPreferencesSnapshot snapshot) =>
      snapshot.customerId == customerId &&
      snapshot.version > (update.expectedVersion ?? 0) &&
      snapshot.preferences.sameAs(update.preferences);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingFoodPreferences &&
          other.customerId == customerId &&
          other.mutationId == mutationId &&
          other.update == update);

  @override
  int get hashCode => Object.hash(customerId, mutationId, update);
}
