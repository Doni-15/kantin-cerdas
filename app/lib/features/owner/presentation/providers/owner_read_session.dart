import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/session/role_read_session.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/owner/domain/failures/owner_failure.dart';

/// Snapshot sesi untuk satu evaluasi provider baca pemilik stan.
class OwnerReadSession {
  OwnerReadSession(Ref ref)
    : _delegate = RoleReadSession.capture(
        ref,
        rolePredicate: (role) => role == UserRole.owner,
        forbiddenError: () => const OwnerForbiddenFailure(),
      );

  final RoleReadSession _delegate;

  String get ownerId => _delegate.actorId;

  void check(Ref ref) => _delegate.check(ref);
}
