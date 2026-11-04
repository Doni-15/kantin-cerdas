import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences.dart';

/// Snapshot server. Null pada repository berarti belum ada preferensi tersimpan.
class FoodPreferencesSnapshot {
  FoodPreferencesSnapshot({
    required this.customerId,
    required this.version,
    required this.preferences,
  }) {
    if (customerId.trim().isEmpty || version < 1) {
      throw ArgumentError('Snapshot preferensi tidak valid.');
    }
  }
  final String customerId;
  final int version;
  final FoodPreferences preferences;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodPreferencesSnapshot &&
          other.customerId == customerId &&
          other.version == version &&
          other.preferences == preferences);

  @override
  int get hashCode => Object.hash(customerId, version, preferences);
}

class FoodPreferencesUpdate {
  FoodPreferencesUpdate({
    required this.preferences,
    required this.expectedVersion,
  }) {
    if (expectedVersion != null && expectedVersion! < 1) {
      throw ArgumentError('Versi tidak valid.');
    }
  }
  final FoodPreferences preferences;

  /// Null berarti create hanya jika belum ada record, diperiksa atomik oleh server.
  final int? expectedVersion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FoodPreferencesUpdate &&
          other.preferences == preferences &&
          other.expectedVersion == expectedVersion);

  @override
  int get hashCode => Object.hash(preferences, expectedVersion);
}
