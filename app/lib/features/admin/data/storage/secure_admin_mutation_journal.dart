import 'package:kantin_cerdas/core/storage/secure_mutation_journal_base.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/pending_admin_mutation.dart';
import 'package:kantin_cerdas/features/admin/domain/repositories/admin_mutation_journal.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/core/domain/entities/canteen_application.dart';

class SecureAdminMutationJournal
    extends SecureMutationJournalBase<PendingAdminMutation>
    implements AdminMutationJournal {
  SecureAdminMutationJournal(super.storage);

  @override
  String get keyPrefix => 'kantin_cerdas.admin.mutation.v1';

  @override
  String get invalidMarkerMessage => 'Penanda admin tidak valid.';

  @override
  String get alreadyPendingMessage => 'Masih ada perubahan admin tertunda.';

  @override
  String actorIdOf(PendingAdminMutation pending) => pending.adminId;

  @override
  String mutationIdOf(PendingAdminMutation pending) => pending.mutationId;

  @override
  PendingAdminMutation decodeEntry(String actorId, Map<String, Object?> data) {
    if (data['adminId'] != actorId ||
        data['mutationId'] is! String ||
        data['kind'] is! String ||
        data['targetId'] is! String ||
        data['expectedVersion'] is! int ||
        data['reason'] is! String ||
        (data['decision'] != null && data['decision'] is! String) ||
        (data['applicantId'] != null && data['applicantId'] is! String) ||
        (data['isActive'] != null && data['isActive'] is! bool) ||
        (data['targetRole'] != null && data['targetRole'] is! String)) {
      throw const FormatException('Penanda admin tidak valid.');
    }
    return PendingAdminMutation(
      adminId: actorId,
      mutationId: data['mutationId'] as String,
      kind: AdminMutationKind.values.byName(data['kind'] as String),
      targetId: data['targetId'] as String,
      expectedVersion: data['expectedVersion'] as int,
      reason: data['reason'] as String,
      applicantId: data['applicantId'] as String?,
      isActive: data['isActive'] as bool?,
      decision: data['decision'] == null
          ? null
          : CanteenApplicationStatus.values.byName(data['decision'] as String),
      targetRole: data['targetRole'] == null
          ? null
          : UserRole.values.byName(data['targetRole'] as String),
    );
  }

  @override
  Map<String, Object?> encodeEntry(PendingAdminMutation pending) => {
    'adminId': pending.adminId,
    'mutationId': pending.mutationId,
    'kind': pending.kind.name,
    'targetId': pending.targetId,
    'expectedVersion': pending.expectedVersion,
    'reason': pending.reason,
    'applicantId': pending.applicantId,
    'isActive': pending.isActive,
    'decision': pending.decision?.name,
    'targetRole': pending.targetRole?.name,
  };

  @override
  Future<PendingAdminMutation?> read(String adminId) => readEntry(adminId);

  @override
  Future<void> save(PendingAdminMutation pending) => saveEntry(pending);

  @override
  Future<bool> clear({required String adminId, required String mutationId}) =>
      clearEntry(actorId: adminId, mutationId: mutationId);
}
