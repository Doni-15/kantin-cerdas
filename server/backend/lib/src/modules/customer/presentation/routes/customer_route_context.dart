import 'package:kantin_cerdas_backend/src/core/auth/auth_guard.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/avatar_store.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/application/customer_service.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/domain/customer_errors.dart';
import 'package:shelf/shelf.dart';

class CustomerRouteContext {
  const CustomerRouteContext({
    required this.auth,
    required this.avatars,
    required this.service,
  });

  final AuthGateway auth;
  final AvatarStore avatars;
  final CustomerService service;

  Future<AuthAccount> requireActor(
    Request request, {
    bool strictCustomerRole = false,
  }) async {
    final actor = await auth.account(requireBearer(request));
    if (actor.displayName == null || !await avatars.exists(actor.id)) {
      throw AuthFailure.profileIncomplete;
    }
    if (strictCustomerRole) {
      if (actor.role == AccountRole.owner) {
        throw const CustomerFailure(CustomerFailureCode.alreadyOwner);
      }
      if (actor.role != AccountRole.customer) {
        throw const CustomerFailure(CustomerFailureCode.customerRoleRequired);
      }
    } else if (actor.role != AccountRole.customer &&
        actor.role != AccountRole.owner) {
      throw const CustomerFailure(CustomerFailureCode.customerRoleRequired);
    }
    return actor;
  }
}
