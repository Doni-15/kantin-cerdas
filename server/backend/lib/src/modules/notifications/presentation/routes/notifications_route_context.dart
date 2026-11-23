import 'package:kantin_cerdas_backend/src/core/auth/auth_guard.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/avatar_store.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/application/notifications_service.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/domain/notification_errors.dart';
import 'package:shelf/shelf.dart';

class NotificationsRouteContext {
  const NotificationsRouteContext({
    required this.auth,
    required this.avatars,
    required this.service,
  });

  final AuthGateway auth;
  final AvatarStore avatars;
  final NotificationsService service;

  Future<(String bearer, AuthAccount actor)> requireParticipant(
    Request request,
  ) async {
    final bearer = requireBearer(request);
    final actor = await auth.account(bearer);
    if (actor.displayName == null || !await avatars.exists(actor.id)) {
      throw AuthFailure.profileIncomplete;
    }
    if (actor.role != AccountRole.customer && actor.role != AccountRole.owner) {
      throw const NotificationFailure(NotificationFailureCode.roleNotAllowed);
    }
    return (bearer, actor);
  }
}
