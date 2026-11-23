import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/domain/admin_errors.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/presentation/admin_request_parser.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/presentation/routes/admin_route_context.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

void registerAdminApplicationRoutes(
  Router router, {
  required AdminRouteContext context,
}) {
  // Owner Applications Queue & Manual Review (ADMIN-001, ADMIN-002, CUSTOMER-006A).
  router.get('/applications', (Request request) async {
    final admin = await context.requireAdmin(request);
    final query = request.url.queryParameters;
    final scope = (query['scope'] ?? 'pending').trim().toLowerCase();
    if (scope != 'pending' && scope != 'history' && scope != 'all') {
      throw const AdminFailure(AdminFailureCode.invalidInput);
    }
    return ApiResponse.success(
      data: await context.service.listApplications(
        admin.id,
        scope: scope,
        limit: readAdminLimit(query['limit']),
        offset: readAdminOffset(query['offset']),
      ),
      headers: noStoreHeaders,
    );
  });

  router.get('/applications/<id>', (Request request, String id) async {
    final admin = await context.requireAdmin(request);
    return ApiResponse.success(
      data: await context.service.getApplication(
        admin.id,
        applicationId: requireAdminUuid(id),
      ),
      headers: noStoreHeaders,
    );
  });

  router.post('/applications/<id>/review', (Request request, String id) async {
    final admin = await context.requireAdmin(request);
    final applicationId = requireAdminUuid(id);
    final body = await readAdminJsonBody(request);
    final decision = readAdminRequiredText(body, 'decision', maxLength: 32);
    final reason = readAdminOptionalReason(body, 'rejection_reason');
    return ApiResponse.success(
      data: await context.service.reviewApplication(
        admin.id,
        applicationId: applicationId,
        decision: decision,
        rejectionReason: reason,
      ),
      headers: noStoreHeaders,
    );
  });
}
