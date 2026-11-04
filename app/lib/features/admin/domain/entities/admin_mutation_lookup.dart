import 'package:kantin_cerdas/core/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/pending_admin_mutation.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';

enum AdminMutationOutcome { pending, applied, notApplied }

/// Receipt transaksi immutable, bukan hasil menebak perubahan versi data.
class AdminMutationLookup {
  AdminMutationLookup({
    required this.request,
    required this.outcome,
    this.resultVersion,
    this.decision,
    this.isActive,
    this.resultRole,
    this.approvedStallId,
  }) {
    if (outcome != AdminMutationOutcome.applied) {
      if (resultVersion != null ||
          decision != null ||
          isActive != null ||
          resultRole != null ||
          approvedStallId != null) {
        throw ArgumentError(
          'Receipt nonterminal/tidak diterapkan memuat hasil.',
        );
      }
      return;
    }
    if (resultVersion == null || resultVersion! <= request.expectedVersion) {
      throw ArgumentError('Versi hasil mutasi tidak sesuai.');
    }
    if (request.kind == AdminMutationKind.reviewApplication) {
      if (decision != request.decision ||
          isActive != null ||
          (decision == CanteenApplicationStatus.approved
              ? (resultRole != UserRole.owner ||
                    approvedStallId == null ||
                    approvedStallId!.trim().isEmpty)
              : (resultRole != null || approvedStallId != null))) {
        throw ArgumentError('Receipt keputusan tidak sesuai intent.');
      }
    } else if (isActive != request.isActive ||
        resultRole != request.targetRole ||
        decision != null ||
        approvedStallId != null) {
      throw ArgumentError('Receipt akses tidak sesuai intent.');
    }
  }
  final PendingAdminMutation request;
  final AdminMutationOutcome outcome;
  final int? resultVersion;
  final CanteenApplicationStatus? decision;
  final bool? isActive;

  /// Role target untuk perubahan akses; role pemohon saat approval commit.
  final UserRole? resultRole;
  final String? approvedStallId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdminMutationLookup &&
          other.request == request &&
          other.outcome == outcome &&
          other.resultVersion == resultVersion &&
          other.decision == decision &&
          other.isActive == isActive &&
          other.resultRole == resultRole &&
          other.approvedStallId == approvedStallId);

  @override
  int get hashCode => Object.hash(
    request,
    outcome,
    resultVersion,
    decision,
    isActive,
    resultRole,
    approvedStallId,
  );
}
