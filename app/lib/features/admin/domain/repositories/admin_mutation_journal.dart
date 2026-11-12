import 'package:kantin_cerdas/features/admin/domain/entities/pending_admin_mutation.dart';

abstract interface class AdminMutationJournal {
  Future<PendingAdminMutation?> read(String adminId);
  Future<void> save(PendingAdminMutation pending);
  Future<bool> clear({required String adminId, required String mutationId});
}
