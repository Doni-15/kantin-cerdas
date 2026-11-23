import 'package:kantin_cerdas_backend/src/core/auth/auth_guard.dart';
import 'package:kantin_cerdas_backend/src/core/config/storage_config.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/errors/owner_errors.dart';
import 'package:kantin_cerdas_backend/src/core/errors/owner_failure_mapper.dart';
import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/avatar_store.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/application/owner_service.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/presentation/routes/owner_category_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/presentation/routes/owner_dashboard_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/presentation/routes/owner_media_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/presentation/routes/owner_menu_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/presentation/routes/owner_order_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/presentation/routes/owner_route_context.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/presentation/routes/owner_stall_routes.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Handler buildOwnerHandler(
  AuthGateway auth, {
  required AvatarStore avatars,
  required OwnerService service,
  required StorageConfig storage,
}) {
  final router = Router(notFoundHandler: notFoundNoStoreResponse);
  final context = OwnerRouteContext(
    auth: auth,
    avatars: avatars,
    service: service,
    storage: storage,
  );

  registerOwnerStallRoutes(router, context: context);
  registerOwnerCategoryRoutes(router, context: context);
  registerOwnerMenuRoutes(router, context: context);
  registerOwnerMediaRoutes(router, context: context);
  registerOwnerDashboardRoutes(router, context: context);
  registerOwnerOrderRoutes(router, context: context);

  return (Request request) async {
    final ApiException error;
    try {
      return await router.call(request);
    } on AuthFailure catch (failure) {
      error = authFailureException(failure);
    } on OwnerFailure catch (failure) {
      error = ownerFailureException(failure);
    } on ApiException catch (exception) {
      error = exception;
    } on FormatException {
      error = ownerFailureException(
        const OwnerFailure(OwnerFailureCode.invalidInput),
      );
    }
    return ApiResponse.error(
      statusCode: error.statusCode,
      code: error.code,
      message: error.message,
      headers: noStoreHeaders,
    );
  };
}
