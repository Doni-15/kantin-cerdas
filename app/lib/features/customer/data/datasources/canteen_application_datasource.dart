import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/pending_canteen_application.dart';
import 'package:kantin_cerdas/features/orders/data/models/canteen_application_model.dart';

export 'package:kantin_cerdas/features/customer/data/models/canteen_application_lookup_model.dart';

abstract interface class CanteenApplicationDataSource {
  bool get isSubmissionConfigured;
  Future<CanteenApplicationModel?> getMyApplication();
  Future<CanteenApplicationModel> submit(PendingCanteenApplication submission);
  Future<CanteenApplicationLookup> lookupSubmission({
    required String submissionId,
  });
}
