import 'package:kantin_cerdas_backend/src/core/auth/auth_guard.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/application/admin_service.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/domain/admin_errors.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/presentation/admin_failure_mapper.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/presentation/routes/admin_application_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/presentation/routes/admin_audit_log_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/presentation/routes/admin_dashboard_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/presentation/routes/admin_route_context.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/presentation/routes/admin_stall_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/presentation/routes/admin_user_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/avatar_store.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Handler buildAdminHandler(
  AuthGateway auth, {
  required AvatarStore avatars,
  required AdminService service,
}) {
  final router = Router(notFoundHandler: notFoundNoStoreResponse);
  final context = AdminRouteContext(
    auth: auth,
    avatars: avatars,
    service: service,
  );

  registerAdminDashboardRoutes(router, context: context);
  registerAdminApplicationRoutes(router, context: context);
  registerAdminUserRoutes(router, context: context);
  registerAdminStallRoutes(router, context: context);
  registerAdminAuditLogRoutes(router, context: context);

  return (Request request) async {
    try {
      return await router.call(request);
    } on AdminFailure catch (failure) {
      final error = adminFailureException(failure);
      return ApiResponse.error(
        statusCode: error.statusCode,
        code: error.code,
        message: error.message,
        headers: noStoreHeaders,
      );
    } on ApiException catch (error) {
      return ApiResponse.error(
        statusCode: error.statusCode,
        code: error.code,
        message: error.message,
        headers: noStoreHeaders,
      );
    } on AuthFailure catch (failure) {
      final error = authFailureException(failure);
      return ApiResponse.error(
        statusCode: error.statusCode,
        code: error.code,
        message: error.message,
        headers: noStoreHeaders,
      );
    }
  };
}
