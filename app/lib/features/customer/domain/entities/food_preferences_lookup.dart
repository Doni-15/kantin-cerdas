import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences_snapshot.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/pending_food_preferences.dart';

enum FoodPreferencesOutcome { pending, applied, notApplied }

/// Receipt immutable hasil request, bukan pembacaan preferensi terbaru.
class FoodPreferencesLookup {
  FoodPreferencesLookup({
    required this.request,
    required this.outcome,
    this.snapshot,
  }) {
    if (outcome == FoodPreferencesOutcome.applied) {
      if (snapshot == null || !request.accepts(snapshot!)) {
        throw ArgumentError('Receipt preferensi tidak sesuai request.');
      }
    } else if (snapshot != null) {
      throw ArgumentError(
        'Request belum diterapkan tidak boleh membawa hasil sukses.',
      );
    }
  }
  final PendingFoodPreferences request;
  final FoodPreferencesOutcome outcome;
  final FoodPreferencesSnapshot? snapshot;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodPreferencesLookup &&
          other.request == request &&
          other.outcome == outcome &&
          other.snapshot == snapshot);

  @override
  int get hashCode => Object.hash(request, outcome, snapshot);
}
