import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/session/role_read_session.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_feature_failure.dart';

/// Snapshot sesi untuk satu evaluasi provider baca pelanggan.
class CustomerReadSession {
  CustomerReadSession(Ref ref)
    : _delegate = RoleReadSession.capture(
        ref,
        rolePredicate: (role) => role.canUseCustomerFeatures,
        forbiddenError: () => const CustomerFeatureForbiddenFailure(),
      );

  final RoleReadSession _delegate;

  String get customerId => _delegate.actorId;

  void check(Ref ref) => _delegate.check(ref);
}
