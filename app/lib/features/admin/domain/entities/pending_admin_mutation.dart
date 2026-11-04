import 'package:characters/characters.dart';
import 'package:kantin_cerdas/core/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';

enum AdminMutationKind { reviewApplication, changeAccess }

class PendingAdminMutation {
  PendingAdminMutation({
    required this.adminId,
    required this.mutationId,
    required this.kind,
    required this.targetId,
    required this.expectedVersion,
    this.decision,
    this.applicantId,
    this.isActive,
    this.targetRole,
    String reason = '',
  }) : reason = reason.trim() {
    if ([adminId, mutationId, targetId].any((s) => s.trim().isEmpty) ||
        expectedVersion < 1 ||
        this.reason.characters.length > 300) {
      throw ArgumentError('Identitas mutasi admin tidak valid.');
    }
    if (kind == AdminMutationKind.reviewApplication) {
      if ((decision != CanteenApplicationStatus.approved &&
              decision != CanteenApplicationStatus.rejected) ||
          applicantId == null ||
          applicantId!.trim().isEmpty ||
          isActive != null ||
          targetRole != null ||
          (decision == CanteenApplicationStatus.rejected
              ? this.reason.isEmpty
              : this.reason.isNotEmpty)) {
        throw ArgumentError('Intent keputusan tidak valid.');
      }
    } else if (isActive == null ||
        targetRole == null ||
        targetRole == UserRole.admin ||
        adminId == targetId ||
        decision != null ||
        applicantId != null ||
        this.reason.isEmpty) {
      throw ArgumentError('Intent perubahan akses tidak valid.');
    }
  }
  final String adminId;
  final String mutationId;
  final AdminMutationKind kind;
  final String targetId;
  final int expectedVersion;
  final CanteenApplicationStatus? decision;
  final String? applicantId;
  final bool? isActive;
  final UserRole? targetRole;
  final String reason;
  bool matches(PendingAdminMutation other) =>
      adminId == other.adminId &&
      mutationId == other.mutationId &&
      kind == other.kind &&
      targetId == other.targetId &&
      expectedVersion == other.expectedVersion &&
      decision == other.decision &&
      applicantId == other.applicantId &&
      isActive == other.isActive &&
      targetRole == other.targetRole &&
      reason == other.reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingAdminMutation && matches(other));

  @override
  int get hashCode => Object.hash(
    adminId,
    mutationId,
    kind,
    targetId,
    expectedVersion,
    decision,
    applicantId,
    isActive,
    targetRole,
    reason,
  );
}
