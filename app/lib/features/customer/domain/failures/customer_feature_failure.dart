sealed class CustomerFeatureFailure implements Exception {
  const CustomerFeatureFailure();

  @override
  bool operator ==(Object other) => runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => '$runtimeType()';
}

final class CustomerFeatureNotConfiguredFailure extends CustomerFeatureFailure {
  const CustomerFeatureNotConfiguredFailure();
}

final class CustomerFeatureForbiddenFailure extends CustomerFeatureFailure {
  const CustomerFeatureForbiddenFailure();
}

final class CustomerFeatureRejectedFailure extends CustomerFeatureFailure {
  const CustomerFeatureRejectedFailure();
}

final class CustomerFeatureUnconfirmedFailure extends CustomerFeatureFailure {
  const CustomerFeatureUnconfirmedFailure();
}

final class CustomerFeatureReadTimeoutFailure extends CustomerFeatureFailure {
  const CustomerFeatureReadTimeoutFailure();
}

final class CustomerFeatureInvalidDataFailure extends CustomerFeatureFailure {
  const CustomerFeatureInvalidDataFailure();
}
