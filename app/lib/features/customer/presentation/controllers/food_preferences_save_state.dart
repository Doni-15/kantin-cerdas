import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/pending_food_preferences.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/food_preferences_failure.dart';

class FoodPreferencesSaveState {
  const FoodPreferencesSaveState({
    this.busy = false,
    this.pending,
    this.error,
    this.saved = false,
    this.reconciled = false,
    this.needsRefresh = false,
    this.journalLoading = false,
    this.journalError,
    this.configured = true,
    this.revision = 0,
  });
  final bool busy;
  final PendingFoodPreferences? pending;
  final FoodPreferencesFailure? error;
  final bool saved;
  final bool reconciled;
  final bool needsRefresh;
  final bool journalLoading;
  final Object? journalError;
  final bool configured;
  final int revision;
  FoodPreferences? get pendingPreferences => pending?.update.preferences;
  bool get blocked =>
      busy ||
      pending != null ||
      needsRefresh ||
      journalLoading ||
      journalError != null ||
      !configured;
  bool get hasNotice =>
      busy ||
      pending != null ||
      error != null ||
      saved ||
      reconciled ||
      needsRefresh ||
      journalLoading ||
      journalError != null ||
      !configured;
}
