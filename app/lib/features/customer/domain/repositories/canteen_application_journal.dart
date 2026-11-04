import 'package:kantin_cerdas/features/customer/domain/entities/pending_canteen_application.dart';

abstract interface class CanteenApplicationJournal {
  Future<PendingCanteenApplication?> read(String customerId);

  /// Tolak overwrite jika sudah ada penanda, termasuk dengan ID yang sama.
  Future<void> save(PendingCanteenApplication submission);
  Future<bool> clear({
    required String customerId,
    required String submissionId,
  });
}
