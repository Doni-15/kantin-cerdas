/// Error yang dipahami Controller/UI untuk pengajuan kantin.
/// Teks untuk user ada di Presentation (canteen_application_error_message.dart).
sealed class CanteenApplicationFailure implements Exception {
  const CanteenApplicationFailure();

  @override
  String toString() => runtimeType.toString();
}

/// Input tidak valid. Key = nama field (name, description, address).
final class CanteenApplicationValidationFailure
    extends CanteenApplicationFailure {
  const CanteenApplicationValidationFailure(this.fieldErrors);

  final Map<String, String> fieldErrors;
}

/// Belum login atau sesi tidak berlaku.
final class CanteenApplicationUnauthorizedFailure
    extends CanteenApplicationFailure {
  const CanteenApplicationUnauthorizedFailure();
}

/// Tidak ada koneksi atau timeout.
final class CanteenApplicationNetworkFailure extends CanteenApplicationFailure {
  const CanteenApplicationNetworkFailure();
}

/// Server error atau response tidak sesuai kontrak.
final class CanteenApplicationUnknownFailure extends CanteenApplicationFailure {
  const CanteenApplicationUnknownFailure();
}
