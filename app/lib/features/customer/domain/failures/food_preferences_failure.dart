/// Pada write, notConfigured/forbidden/rejected/conflict/preSend hanya definitif
/// jika tidak terjadi commit atau late commit. Storage gagal tidak membuktikan
/// hasil jaringan; penanda harus dibaca ulang, bukan dihapus paksa.
sealed class FoodPreferencesFailure implements Exception {
  const FoodPreferencesFailure();

  @override
  bool operator ==(Object other) => runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => '$runtimeType()';
}

final class FoodPreferencesNotConfiguredFailure extends FoodPreferencesFailure {
  const FoodPreferencesNotConfiguredFailure();
}

final class FoodPreferencesForbiddenFailure extends FoodPreferencesFailure {
  const FoodPreferencesForbiddenFailure();
}

final class FoodPreferencesInvalidDataFailure extends FoodPreferencesFailure {
  const FoodPreferencesInvalidDataFailure();
}

final class FoodPreferencesReadTimeoutFailure extends FoodPreferencesFailure {
  const FoodPreferencesReadTimeoutFailure();
}

final class FoodPreferencesRejectedFailure extends FoodPreferencesFailure {
  const FoodPreferencesRejectedFailure();
}

final class FoodPreferencesConflictFailure extends FoodPreferencesFailure {
  const FoodPreferencesConflictFailure();
}

final class FoodPreferencesUnknownFailure extends FoodPreferencesFailure {
  const FoodPreferencesUnknownFailure();
}

final class FoodPreferencesStorageFailure extends FoodPreferencesFailure {
  const FoodPreferencesStorageFailure();
}

final class FoodPreferencesPreSendFailure extends FoodPreferencesFailure {
  const FoodPreferencesPreSendFailure();
}
