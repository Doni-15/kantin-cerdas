import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/admin/application/admin_providers.dart';
import 'package:kantin_cerdas/features/admin/domain/admin_models.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/application/services/require_account_session.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';

/// Isolated mutation controller for Admin actions (M2 / ADMIN-005).
///
/// Never watches or reads derived UI/query providers that depend on it,
/// preventing Riverpod 3 CircularDependencyError during mutations.
final adminActionControllerProvider = Provider<AdminActionController>(
  AdminActionController.new,
);

class AdminActionController {
  AdminActionController(this._ref);

  final Ref _ref;
  var _busy = false;

  Future<AdminOwnerApplication> reviewApplication({
    required String accountId,
    required String applicationId,
    required bool approve,
    String? rejectionReason,
  }) async {
    if (_busy) {
      throw const AuthException(
        'ADMIN_ACTION_BUSY',
        'Tunggu sampai keputusan sebelumnya selesai diproses.',
      );
    }
    _busy = true;
    try {
      final session = _session(accountId);
      final updated = await _ref
          .read(adminRepositoryProvider)
          .reviewApplication(
            session,
            applicationId: applicationId,
            decision: approve ? 'disetujui' : 'ditolak',
            rejectionReason: approve ? null : rejectionReason?.trim(),
          );
      _invalidateAfterApplicationChange(
        accountId,
        applicationId,
        updated.customerId,
      );
      return updated;
    } finally {
      _busy = false;
    }
  }

  Future<AdminManagedUser> setUserActiveStatus({
    required String accountId,
    required String targetUserId,
    required bool isActive,
    String? reason,
  }) async {
    if (_busy) {
      throw const AuthException(
        'ADMIN_ACTION_BUSY',
        'Tunggu sampai perubahan status sebelumnya selesai.',
      );
    }
    _busy = true;
    try {
      final session = _session(accountId);
      final updated = await _ref
          .read(adminRepositoryProvider)
          .setUserActiveStatus(
            session,
            targetUserId: targetUserId,
            isActive: isActive,
            reason: reason?.trim(),
          );
      _invalidateAfterUserStatusChange(accountId, targetUserId);
      return updated;
    } finally {
      _busy = false;
    }
  }

  void _invalidateAfterApplicationChange(
    String accountId,
    String applicationId,
    String customerId,
  ) {
    _ref.invalidate(adminDashboardProvider(accountId));
    _ref.invalidate(adminApplicationsProvider);
    _ref.invalidate(
      adminApplicationDetailProvider((
        accountId: accountId,
        applicationId: applicationId,
      )),
    );
    _ref.invalidate(adminUsersProvider);
    if (customerId.isNotEmpty) {
      _ref.invalidate(
        adminUserDetailProvider((accountId: accountId, userId: customerId)),
      );
    }
    _ref.invalidate(adminActionLogsProvider);
  }

  void _invalidateAfterUserStatusChange(String accountId, String targetUserId) {
    _ref.invalidate(adminDashboardProvider(accountId));
    _ref.invalidate(adminUsersProvider);
    _ref.invalidate(
      adminUserDetailProvider((accountId: accountId, userId: targetUserId)),
    );
    _ref.invalidate(adminApplicationsProvider);
    _ref.invalidate(adminStallsProvider);
    _ref.invalidate(adminStallDetailProvider);
    _ref.invalidate(adminActionLogsProvider);
  }

  AuthSession _session(String accountId) => requireAccountSession(
    _ref.read(authControllerProvider).asData?.value,
    accountId,
  );
}
