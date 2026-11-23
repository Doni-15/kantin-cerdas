import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/domain/admin_errors.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/presentation/admin_request_parser.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/presentation/routes/admin_route_context.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

void registerAdminUserRoutes(
  Router router, {
  required AdminRouteContext context,
}) {
  // User Oversight & Activate/Deactivate (ADMIN-003, ADMIN-003A, ADMIN-005).
  router.get('/users', (Request request) async {
    final admin = await context.requireAdmin(request);
    final query = request.url.queryParameters;
    final rawRole = query['role']?.trim().toLowerCase();
    final role = (rawRole == null || rawRole.isEmpty) ? null : rawRole;
    if (role != null &&
        role != 'customer' &&
        role != 'owner' &&
        role != 'admin') {
      throw const AdminFailure(AdminFailureCode.invalidInput);
    }
    final rawStatus = query['status']?.trim().toLowerCase();
    final status = (rawStatus == null || rawStatus.isEmpty) ? null : rawStatus;
    if (status != null && status != 'active' && status != 'inactive') {
      throw const AdminFailure(AdminFailureCode.invalidInput);
    }
    return ApiResponse.success(
      data: await context.service.listUsers(
        admin.id,
        role: role,
        status: status,
        query: readAdminOptionalQueryText(query['q']),
        limit: readAdminLimit(query['limit']),
        offset: readAdminOffset(query['offset']),
      ),
      headers: noStoreHeaders,
    );
  });

  router.get('/users/<id>', (Request request, String id) async {
    final admin = await context.requireAdmin(request);
    return ApiResponse.success(
      data: await context.service.getUser(
        admin.id,
        userId: requireAdminUuid(id),
      ),
      headers: noStoreHeaders,
    );
  });

  router.post('/users/<id>/status', (Request request, String id) async {
    final admin = await context.requireAdmin(request);
    final targetUserId = requireAdminUuid(id);
    final body = await readAdminJsonBody(request);
    final isActive = readAdminRequiredBool(body, 'is_active');
    final reason = readAdminOptionalReason(body, 'reason');
    return ApiResponse.success(
      data: await context.service.setUserActiveStatus(
        admin.id,
        targetUserId: targetUserId,
        isActive: isActive,
        reason: reason,
      ),
      headers: noStoreHeaders,
    );
  });
}
