import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/session/role_read_session.dart';
import 'package:kantin_cerdas/features/admin/domain/failures/admin_failure.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';

/// Snapshot sesi untuk satu evaluasi provider baca admin.
class AdminReadSession {
  AdminReadSession(Ref ref)
    : _delegate = RoleReadSession.capture(
        ref,
        rolePredicate: (role) => role == UserRole.admin,
        forbiddenError: () => const AdminAccessFailure(),
      );

  final RoleReadSession _delegate;

  String get adminId => _delegate.actorId;

  void check(Ref ref) => _delegate.check(ref);
}
