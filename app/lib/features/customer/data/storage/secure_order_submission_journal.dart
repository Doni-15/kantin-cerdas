import 'package:kantin_cerdas/core/storage/secure_mutation_journal_base.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/pending_order_submission.dart';
import 'package:kantin_cerdas/features/customer/domain/repositories/order_submission_journal.dart';

class SecureOrderSubmissionJournal
    extends SecureMutationJournalBase<PendingOrderSubmission>
    implements OrderSubmissionJournal {
  SecureOrderSubmissionJournal(super.storage);

  @override
  String get keyPrefix => 'kantin_cerdas.order.pending.v1';

  @override
  String get invalidMarkerMessage => 'Penanda pengiriman lokal tidak valid.';

  @override
  String get alreadyPendingMessage =>
      'Masih ada pengiriman yang belum diselesaikan.';

  @override
  bool get allowSameMutationOverwrite => true;

  @override
  String actorIdOf(PendingOrderSubmission pending) => pending.customerId;

  @override
  String mutationIdOf(PendingOrderSubmission pending) => pending.submissionId;

  @override
  PendingOrderSubmission decodeEntry(
    String actorId,
    Map<String, Object?> data,
  ) {
    if (data['customerId'] != actorId ||
        data['submissionId'] is! String ||
        (data['submissionId'] as String).trim().isEmpty) {
      throw const FormatException('Penanda pengiriman lokal tidak valid.');
    }
    return PendingOrderSubmission(
      customerId: actorId,
      submissionId: data['submissionId'] as String,
    );
  }

  @override
  Map<String, Object?> encodeEntry(PendingOrderSubmission pending) => {
    'customerId': pending.customerId,
    'submissionId': pending.submissionId,
  };

  @override
  Future<PendingOrderSubmission?> read(String customerId) =>
      readEntry(customerId);

  @override
  Future<void> save(PendingOrderSubmission submission) => saveEntry(submission);

  @override
  Future<bool> clear({
    required String customerId,
    required String submissionId,
  }) => clearEntry(actorId: customerId, mutationId: submissionId);
}
