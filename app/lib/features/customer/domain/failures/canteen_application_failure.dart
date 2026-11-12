sealed class CanteenApplicationFailure implements Exception {
  const CanteenApplicationFailure();

  /// Adapter hanya boleh memakai kategori definitif bila tidak ada commit dan
  /// request terlambat dengan ID yang sama tidak dapat melakukan commit.
  bool get definitelyNotSubmitted => switch (this) {
    CanteenApplicationNotConfiguredFailure() ||
    CanteenApplicationForbiddenFailure() ||
    CanteenApplicationRejectedFailure() ||
    CanteenApplicationConflictFailure() ||
    CanteenApplicationPreSendFailure() => true,
    CanteenApplicationUnconfirmedFailure() ||
    CanteenApplicationStorageFailure() => false,
  };

  @override
  bool operator ==(Object other) => runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => '$runtimeType()';
}

final class CanteenApplicationNotConfiguredFailure
    extends CanteenApplicationFailure {
  const CanteenApplicationNotConfiguredFailure();
}

final class CanteenApplicationForbiddenFailure
    extends CanteenApplicationFailure {
  const CanteenApplicationForbiddenFailure();
}

final class CanteenApplicationRejectedFailure
    extends CanteenApplicationFailure {
  const CanteenApplicationRejectedFailure();
}

final class CanteenApplicationConflictFailure
    extends CanteenApplicationFailure {
  const CanteenApplicationConflictFailure();
}

final class CanteenApplicationPreSendFailure extends CanteenApplicationFailure {
  const CanteenApplicationPreSendFailure();
}

final class CanteenApplicationUnconfirmedFailure
    extends CanteenApplicationFailure {
  const CanteenApplicationUnconfirmedFailure();
}

final class CanteenApplicationStorageFailure extends CanteenApplicationFailure {
  const CanteenApplicationStorageFailure();
}
