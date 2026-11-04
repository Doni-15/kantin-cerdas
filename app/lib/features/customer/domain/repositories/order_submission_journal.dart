import 'package:kantin_cerdas/features/customer/domain/entities/pending_order_submission.dart';

abstract interface class OrderSubmissionJournal {
  Future<PendingOrderSubmission?> read(String customerId);

  /// Harus selesai sebelum request pembuatan boleh dikirim.
  Future<void> save(PendingOrderSubmission submission);

  /// Hanya menghapus penanda yang ID-nya cocok, bukan seluruh penyimpanan.
  Future<bool> clear({
    required String customerId,
    required String submissionId,
  });
}
