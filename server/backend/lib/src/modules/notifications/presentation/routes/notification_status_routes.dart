import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/notifications/presentation/routes/notifications_route_context.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

void registerNotificationStatusRoutes(
  Router router, {
  required NotificationsRouteContext context,
}) {
  // Non-secret runtime readiness snapshot for Realtime & Push.
  router.get('/status', (Request request) async {
    await context.requireParticipant(request);
    return ApiResponse.success(
      data: context.service.getStatus().toJson(),
      headers: noStoreHeaders,
    );
  });
}
