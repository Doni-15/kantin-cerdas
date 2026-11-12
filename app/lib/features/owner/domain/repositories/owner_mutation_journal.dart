import 'package:kantin_cerdas/features/owner/domain/entities/pending_owner_mutation.dart';

abstract interface class OwnerMutationJournal {
  Future<PendingOwnerMutation?> read(String ownerId);
  Future<void> save(PendingOwnerMutation pending);
  Future<bool> clear({required String ownerId, required String mutationId});
}
