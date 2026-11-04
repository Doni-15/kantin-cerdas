import 'package:kantin_cerdas/core/storage/secure_mutation_journal_base.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/pending_owner_mutation.dart';
import 'package:kantin_cerdas/features/owner/domain/repositories/owner_mutation_journal.dart';

class SecureOwnerMutationJournal
    extends SecureMutationJournalBase<PendingOwnerMutation>
    implements OwnerMutationJournal {
  SecureOwnerMutationJournal(super.storage);

  @override
  String get keyPrefix => 'kantin_cerdas.owner.mutation.v1';

  @override
  String get invalidMarkerMessage => 'Penanda perubahan owner tidak valid.';

  @override
  String get alreadyPendingMessage => 'Masih ada perubahan tertunda.';

  @override
  String actorIdOf(PendingOwnerMutation pending) => pending.ownerId;

  @override
  String mutationIdOf(PendingOwnerMutation pending) => pending.mutationId;

  @override
  PendingOwnerMutation decodeEntry(String actorId, Map<String, Object?> data) {
    if (data['ownerId'] != actorId ||
        data['mutationId'] is! String ||
        data['stallId'] is! String ||
        data['kind'] is! String ||
        (data['targetId'] != null && data['targetId'] is! String) ||
        (data['expectedVersion'] != null && data['expectedVersion'] is! int) ||
        (data['orderStatus'] != null && data['orderStatus'] is! String)) {
      throw const FormatException('Penanda perubahan owner tidak valid.');
    }
    return PendingOwnerMutation(
      ownerId: actorId,
      mutationId: data['mutationId'] as String,
      stallId: data['stallId'] as String,
      kind: OwnerMutationKind.values.byName(data['kind'] as String),
      targetId: data['targetId'] as String?,
      expectedVersion: data['expectedVersion'] as int?,
      orderStatus: data['orderStatus'] == null
          ? null
          : OrderStatus.values.byName(data['orderStatus'] as String),
    );
  }

  @override
  Map<String, Object?> encodeEntry(PendingOwnerMutation pending) => {
    'ownerId': pending.ownerId,
    'mutationId': pending.mutationId,
    'stallId': pending.stallId,
    'kind': pending.kind.name,
    'targetId': pending.targetId,
    'expectedVersion': pending.expectedVersion,
    'orderStatus': pending.orderStatus?.name,
  };

  @override
  Future<PendingOwnerMutation?> read(String ownerId) => readEntry(ownerId);

  @override
  Future<void> save(PendingOwnerMutation pending) => saveEntry(pending);

  @override
  Future<bool> clear({required String ownerId, required String mutationId}) =>
      clearEntry(actorId: ownerId, mutationId: mutationId);
}
