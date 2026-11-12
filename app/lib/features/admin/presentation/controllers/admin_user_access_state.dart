import 'package:kantin_cerdas/features/admin/domain/failures/admin_failure.dart';

class AdminUserAccessState {
  const AdminUserAccessState({
    this.busy = false,
    this.unresolvedVersion,
    this.error,
    this.savedIsActive,
    this.reconciled = false,
  });
  final bool busy;
  final int? unresolvedVersion;
  final AdminFailure? error;
  final bool? savedIsActive;
  final bool reconciled;
  bool get blocked => busy || unresolvedVersion != null;
}
