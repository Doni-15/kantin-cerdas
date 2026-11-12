/// notConfigured/forbidden/conflict/rejected/preSend hanya definitif jika layanan
/// menjamin tidak ada commit/late commit. Timeout/response invalid tetap unknown.
/// Storage gagal tidak menentukan hasil jaringan dan tidak menghapus penanda.
sealed class CustomerOrderCancellationFailure implements Exception {
  const CustomerOrderCancellationFailure();

  @override
  bool operator ==(Object other) => runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => '$runtimeType()';
}

final class CustomerOrderCancellationNotConfiguredFailure
    extends CustomerOrderCancellationFailure {
  const CustomerOrderCancellationNotConfiguredFailure();
}

final class CustomerOrderCancellationForbiddenFailure
    extends CustomerOrderCancellationFailure {
  const CustomerOrderCancellationForbiddenFailure();
}

final class CustomerOrderCancellationConflictFailure
    extends CustomerOrderCancellationFailure {
  const CustomerOrderCancellationConflictFailure();
}

final class CustomerOrderCancellationRejectedFailure
    extends CustomerOrderCancellationFailure {
  const CustomerOrderCancellationRejectedFailure();
}

final class CustomerOrderCancellationUnknownFailure
    extends CustomerOrderCancellationFailure {
  const CustomerOrderCancellationUnknownFailure();
}

final class CustomerOrderCancellationStorageFailure
    extends CustomerOrderCancellationFailure {
  const CustomerOrderCancellationStorageFailure();
}

final class CustomerOrderCancellationPreSendFailure
    extends CustomerOrderCancellationFailure {
  const CustomerOrderCancellationPreSendFailure();
}
