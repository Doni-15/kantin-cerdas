import 'package:characters/characters.dart';
import 'package:kantin_cerdas/core/domain/entities/canteen_application.dart';

class AdminApplicationReview {
  AdminApplicationReview({
    required this.applicationId,
    required this.expectedVersion,
    required this.status,
    String? reason,
  }) : reason = status == CanteenApplicationStatus.rejected
           ? reason?.trim()
           : null {
    if (applicationId.trim().isEmpty ||
        expectedVersion < 1 ||
        (status != CanteenApplicationStatus.approved &&
            status != CanteenApplicationStatus.rejected) ||
        (status == CanteenApplicationStatus.rejected &&
            !validReason(this.reason))) {
      throw ArgumentError('Keputusan pengajuan tidak valid.');
    }
  }
  static const maxReasonLength = 300;
  static bool validReason(String? value) =>
      value != null &&
      value.trim().isNotEmpty &&
      value.trim().characters.length <= maxReasonLength;
  final String applicationId;
  final int expectedVersion;
  final CanteenApplicationStatus status;
  final String? reason;

  bool acceptsResult({
    required CanteenApplication before,
    required CanteenApplication after,
  }) =>
      canApplyTo(before) &&
      after.id == before.id &&
      after.applicantId == before.applicantId &&
      after.version > expectedVersion &&
      after.status == status &&
      after.reason == reason &&
      after.name == before.name &&
      after.description == before.description &&
      after.location == before.location &&
      after.phone == before.phone &&
      after.createdAt.isAtSameMomentAs(before.createdAt);

  bool canApplyTo(CanteenApplication application) =>
      application.id == applicationId &&
      application.version == expectedVersion &&
      application.status.canBeReviewed;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdminApplicationReview &&
          other.applicationId == applicationId &&
          other.expectedVersion == expectedVersion &&
          other.status == status &&
          other.reason == reason);

  @override
  int get hashCode =>
      Object.hash(applicationId, expectedVersion, status, reason);
}
