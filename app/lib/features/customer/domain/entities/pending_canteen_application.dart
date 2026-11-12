import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application.dart';

/// Snapshot disimpan aman sebelum dispatch, bukan draft form yang belum dikirim.
class PendingCanteenApplication {
  PendingCanteenApplication({
    required this.customerId,
    required this.submissionId,
    required this.draft,
    this.previousId,
    this.previousVersion,
  }) {
    if (customerId.trim().isEmpty ||
        submissionId.trim().isEmpty ||
        (previousId == null) != (previousVersion == null) ||
        (previousId != null && previousId!.trim().isEmpty) ||
        (previousVersion != null && previousVersion! < 1)) {
      throw ArgumentError('Penanda pengajuan tidak valid.');
    }
  }
  final String customerId;
  final String submissionId;
  final CanteenApplicationDraft draft;
  final String? previousId;
  final int? previousVersion;

  bool matchesPrevious(CanteenApplication? previous) => previous == null
      ? previousId == null && previousVersion == null
      : previous.id == previousId &&
            previous.version == previousVersion &&
            previous.applicantId == customerId &&
            previous.status == CanteenApplicationStatus.rejected;

  /// Receipt awal yang immutable, bukan status terkini setelah ditinjau admin.
  /// Pengajuan ulang membuat record baru; riwayat yang ditolak dipertahankan.
  bool acceptsResult(CanteenApplication result) =>
      result.applicantId == customerId &&
      result.id != previousId &&
      result.status == CanteenApplicationStatus.submitted &&
      result.reason == null &&
      result.name == draft.name &&
      result.description == draft.description &&
      result.location == draft.location &&
      result.phone == draft.phone;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingCanteenApplication &&
          other.customerId == customerId &&
          other.submissionId == submissionId &&
          other.draft == draft &&
          other.previousId == previousId &&
          other.previousVersion == previousVersion);

  @override
  int get hashCode =>
      Object.hash(customerId, submissionId, draft, previousId, previousVersion);
}
