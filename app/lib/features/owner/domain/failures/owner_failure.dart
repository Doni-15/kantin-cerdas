sealed class OwnerFailure implements Exception {
  const OwnerFailure();

  @override
  bool operator ==(Object other) => runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => '$runtimeType()';
}

final class OwnerNotConfiguredFailure extends OwnerFailure {
  const OwnerNotConfiguredFailure();
}

final class OwnerForbiddenFailure extends OwnerFailure {
  const OwnerForbiddenFailure();
}

final class OwnerNoStallFailure extends OwnerFailure {
  const OwnerNoStallFailure();
}

final class OwnerConflictFailure extends OwnerFailure {
  const OwnerConflictFailure();
}

final class OwnerRejectedFailure extends OwnerFailure {
  const OwnerRejectedFailure();
}

final class OwnerUnconfirmedFailure extends OwnerFailure {
  const OwnerUnconfirmedFailure();
}

final class OwnerStorageFailure extends OwnerFailure {
  const OwnerStorageFailure();
}

final class OwnerInvalidDataFailure extends OwnerFailure {
  const OwnerInvalidDataFailure();
}

final class OwnerReadTimeoutFailure extends OwnerFailure {
  const OwnerReadTimeoutFailure();
}

final class OwnerPreSendFailure extends OwnerFailure {
  const OwnerPreSendFailure();
}
