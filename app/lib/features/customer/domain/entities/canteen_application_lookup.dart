import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application.dart';

enum CanteenApplicationSubmissionStatus { pending, submitted, notSubmitted }

class CanteenApplicationLookup {
  CanteenApplicationLookup({
    required this.customerId,
    required this.submissionId,
    required this.status,
    this.receipt,
  }) {
    if (customerId.trim().isEmpty ||
        submissionId.trim().isEmpty ||
        (status == CanteenApplicationSubmissionStatus.submitted) !=
            (receipt != null)) {
      throw ArgumentError('Hasil pemeriksaan pengajuan tidak valid.');
    }
  }
  final String customerId;
  final String submissionId;
  final CanteenApplicationSubmissionStatus status;
  final CanteenApplication? receipt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CanteenApplicationLookup &&
          other.customerId == customerId &&
          other.submissionId == submissionId &&
          other.status == status &&
          other.receipt == receipt);

  @override
  int get hashCode => Object.hash(customerId, submissionId, status, receipt);
}
