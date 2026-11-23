import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/presentation/admin_request_parser.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/presentation/routes/admin_route_context.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

void registerAdminStallRoutes(
  Router router, {
  required AdminRouteContext context,
}) {
  // Read-Only Stall Monitoring (ADMIN-004, zero stall/menu/order mutation endpoints).
  router.get('/stalls', (Request request) async {
    final admin = await context.requireAdmin(request);
    final query = request.url.queryParameters;
    return ApiResponse.success(
      data: await context.service.listStalls(
        admin.id,
        query: readAdminOptionalQueryText(query['q']),
        limit: readAdminLimit(query['limit']),
        offset: readAdminOffset(query['offset']),
      ),
      headers: noStoreHeaders,
    );
  });

  router.get('/stalls/<id>', (Request request, String id) async {
    final admin = await context.requireAdmin(request);
    return ApiResponse.success(
      data: await context.service.getStall(
        admin.id,
        stallId: requireAdminUuid(id),
      ),
      headers: noStoreHeaders,
    );
  });

  router.get('/stalls/<id>/photo', (Request request, String id) async {
    final admin = await context.requireAdmin(request);
    return jpegDownloadResponse(
      await context.service.readStallPhoto(
        admin.id,
        stallId: requireAdminUuid(id),
      ),
    );
  });
}
