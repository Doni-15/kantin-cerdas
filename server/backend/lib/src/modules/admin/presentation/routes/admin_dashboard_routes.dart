import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/presentation/routes/admin_route_context.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

void registerAdminDashboardRoutes(
  Router router, {
  required AdminRouteContext context,
}) {
  // Administrative Dashboard Summary (ADMIN-005, zero transaction totals).
  router.get('/dashboard', (Request request) async {
    final admin = await context.requireAdmin(request);
    return ApiResponse.success(
      data: await context.service.getDashboard(admin.id),
      headers: noStoreHeaders,
    );
  });
}
