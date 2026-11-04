sealed class CustomerOrderDetailFailure implements Exception {
  const CustomerOrderDetailFailure();

  @override
  bool operator ==(Object other) => runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => '$runtimeType()';
}

final class CustomerOrderDetailInvalidReferenceFailure
    extends CustomerOrderDetailFailure {
  const CustomerOrderDetailInvalidReferenceFailure();
}

final class CustomerOrderDetailInvalidDataFailure
    extends CustomerOrderDetailFailure {
  const CustomerOrderDetailInvalidDataFailure();
}

final class CustomerOrderDetailTimeoutFailure
    extends CustomerOrderDetailFailure {
  const CustomerOrderDetailTimeoutFailure();
}
