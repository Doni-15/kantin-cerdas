sealed class OwnerOrderDetailFailure implements Exception {
  const OwnerOrderDetailFailure();

  @override
  bool operator ==(Object other) => runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => '$runtimeType()';
}

final class OwnerOrderDetailInvalidReferenceFailure
    extends OwnerOrderDetailFailure {
  const OwnerOrderDetailInvalidReferenceFailure();
}

final class OwnerOrderDetailInvalidDataFailure extends OwnerOrderDetailFailure {
  const OwnerOrderDetailInvalidDataFailure();
}

final class OwnerOrderDetailTimeoutFailure extends OwnerOrderDetailFailure {
  const OwnerOrderDetailTimeoutFailure();
}
