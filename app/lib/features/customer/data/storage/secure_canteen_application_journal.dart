import 'package:kantin_cerdas/core/storage/secure_mutation_journal_base.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/pending_canteen_application.dart';
import 'package:kantin_cerdas/features/customer/domain/repositories/canteen_application_journal.dart';

class SecureCanteenApplicationJournal
    extends SecureMutationJournalBase<PendingCanteenApplication>
    implements CanteenApplicationJournal {
  SecureCanteenApplicationJournal(super.storage);

  @override
  String get keyPrefix => 'kantin_cerdas.application.pending.v1';

  @override
  String get invalidMarkerMessage => 'Penanda pengajuan lokal tidak valid.';

  @override
  String get alreadyPendingMessage =>
      'Masih ada pengajuan yang belum diselesaikan.';

  @override
  String actorIdOf(PendingCanteenApplication pending) => pending.customerId;

  @override
  String mutationIdOf(PendingCanteenApplication pending) =>
      pending.submissionId;

  @override
  PendingCanteenApplication decodeEntry(
    String actorId,
    Map<String, Object?> data,
  ) {
    if (data['customerId'] != actorId ||
        data['submissionId'] is! String ||
        data['name'] is! String ||
        data['description'] is! String ||
        data['location'] is! String ||
        data['phone'] is! String ||
        (data['previousId'] != null && data['previousId'] is! String) ||
        (data['previousVersion'] != null && data['previousVersion'] is! int)) {
      throw const FormatException('Penanda pengajuan lokal tidak valid.');
    }
    return PendingCanteenApplication(
      customerId: actorId,
      submissionId: data['submissionId'] as String,
      previousId: data['previousId'] as String?,
      previousVersion: data['previousVersion'] as int?,
      draft: CanteenApplicationDraft(
        name: data['name'] as String,
        description: data['description'] as String,
        location: data['location'] as String,
        phone: data['phone'] as String,
      ),
    );
  }

  @override
  Map<String, Object?> encodeEntry(PendingCanteenApplication pending) => {
    'customerId': pending.customerId,
    'submissionId': pending.submissionId,
    'previousId': pending.previousId,
    'previousVersion': pending.previousVersion,
    'name': pending.draft.name,
    'description': pending.draft.description,
    'location': pending.draft.location,
    'phone': pending.draft.phone,
  };

  @override
  Future<PendingCanteenApplication?> read(String customerId) =>
      readEntry(customerId);

  @override
  Future<void> save(PendingCanteenApplication submission) =>
      saveEntry(submission);

  @override
  Future<bool> clear({
    required String customerId,
    required String submissionId,
  }) => clearEntry(actorId: customerId, mutationId: submissionId);
}
