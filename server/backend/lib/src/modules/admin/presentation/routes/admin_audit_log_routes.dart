import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/presentation/admin_request_parser.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/presentation/routes/admin_route_context.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

void registerAdminAuditLogRoutes(
  Router router, {
  required AdminRouteContext context,
}) {
  // Immutable Admin Audit Logs.
  router.get('/action-logs', (Request request) async {
    final admin = await context.requireAdmin(request);
    final query = request.url.queryParameters;
    return ApiResponse.success(
      data: await context.service.listActionLogs(
        admin.id,
        targetUserId: optionalAdminUuidQuery(query['target_user_id']),
        limit: readAdminLimit(query['limit']),
        offset: readAdminOffset(query['offset']),
      ),
      headers: noStoreHeaders,
    );
  });
}
