sealed class AdminFailure implements Exception {
  const AdminFailure();

  @override
  bool operator ==(Object other) => runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => '$runtimeType()';
}

final class AdminNotConfiguredFailure extends AdminFailure {
  const AdminNotConfiguredFailure();
}

final class AdminAccessFailure extends AdminFailure {
  const AdminAccessFailure();
}

final class AdminInvalidDataFailure extends AdminFailure {
  const AdminInvalidDataFailure();
}

final class AdminReadTimeoutFailure extends AdminFailure {
  const AdminReadTimeoutFailure();
}

/// Hanya jika layanan menjamin keputusan tidak diterapkan.
final class AdminReviewRejectedFailure extends AdminFailure {
  const AdminReviewRejectedFailure();
}

/// Perbandingan versi gagal atomik; request ini tidak mengubah pengajuan.
final class AdminReviewConflictFailure extends AdminFailure {
  const AdminReviewConflictFailure();
}

/// Request mungkin sudah diterapkan, termasuk respons setelah kirim yang invalid.
final class AdminReviewUnknownFailure extends AdminFailure {
  const AdminReviewUnknownFailure();
}

/// Penolakan definitif; server menjamin request ini tidak mengubah akses.
final class AdminUserAccessRejectedFailure extends AdminFailure {
  const AdminUserAccessRejectedFailure();
}

/// Versi tidak sesuai; request ini tidak melakukan commit.
final class AdminUserAccessConflictFailure extends AdminFailure {
  const AdminUserAccessConflictFailure();
}

/// Tidak dapat dipastikan apakah perubahan sudah diterapkan.
final class AdminUserAccessUnknownFailure extends AdminFailure {
  const AdminUserAccessUnknownFailure();
}

final class AdminMutationStorageFailure extends AdminFailure {
  const AdminMutationStorageFailure();
}

final class AdminMutationPreSendFailure extends AdminFailure {
  const AdminMutationPreSendFailure();
}
