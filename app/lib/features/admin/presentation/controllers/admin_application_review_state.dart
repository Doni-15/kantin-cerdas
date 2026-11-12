import 'package:kantin_cerdas/features/admin/domain/failures/admin_failure.dart';

class AdminApplicationReviewState {
  const AdminApplicationReviewState({
    this.busy = false,
    this.unresolvedVersion,
    this.error,
    this.saved = false,
    this.reconciled = false,
  });
  final bool busy;
  final int? unresolvedVersion;
  final AdminFailure? error;
  final bool saved;
  final bool reconciled;
  bool get blocked => busy || unresolvedVersion != null;
}
