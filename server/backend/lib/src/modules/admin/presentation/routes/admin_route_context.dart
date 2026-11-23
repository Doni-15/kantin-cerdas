import 'package:kantin_cerdas_backend/src/core/auth/auth_guard.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/application/admin_service.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/domain/admin_errors.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/avatar_store.dart';
import 'package:shelf/shelf.dart';

class AdminRouteContext {
  const AdminRouteContext({
    required this.auth,
    required this.avatars,
    required this.service,
  });

  final AuthGateway auth;
  final AvatarStore avatars;
  final AdminService service;

  Future<AuthAccount> requireAdmin(Request request) async {
    final actor = await auth.account(requireBearer(request));
    if (actor.displayName == null || !await avatars.exists(actor.id)) {
      throw AuthFailure.profileIncomplete;
    }
    if (actor.role != AccountRole.admin) {
      throw const AdminFailure(AdminFailureCode.adminRoleRequired);
    }
    return actor;
  }
}
