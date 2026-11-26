import 'package:kantin_cerdas_backend/src/core/auth/auth_guard.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/avatar_store.dart';
import 'package:kantin_cerdas_backend/src/modules/catalog/domain/catalog_store.dart';
import 'package:kantin_cerdas_backend/src/modules/catalog/presentation/routes/catalog_menu_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/catalog/presentation/routes/catalog_route_context.dart';
import 'package:kantin_cerdas_backend/src/modules/catalog/presentation/routes/catalog_stall_routes.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Handler buildCatalogHandler(
    AuthGateway auth,
    AvatarStore avatars,
    CatalogStore store,
    ) {
  final router = Router(
    notFoundHandler: notFoundNoStoreResponse,
  );

  final context = CatalogRouteContext(
    auth: auth,
    avatars: avatars,
    store: store,
  );

  // Register catalog endpoints.
  registerCatalogStallRoutes(
    router,
    context: context,
  );

  registerCatalogMenuRoutes(
    router,
    context: context,
  );

  return (Request request) async {
    try {
      return await router.call(request);
    } on CatalogFailure catch (failure) {
      final error = catalogFailureException(failure);

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
    } on ApiException catch (error) {
      return ApiResponse.error(
        statusCode: error.statusCode,
        code: error.code,
        message: error.message,
        headers: noStoreHeaders,
      );
    }
  };
}

/// Maps catalog domain failures to public API exceptions.
ApiException catalogFailureException(CatalogFailure failure) {
  final (statusCode, code, defaultMessage) = switch (failure.code) {
    CatalogFailureCode.invalidQuery => (
    400,
    'INVALID_CATALOG_QUERY',
    'Parameter permintaan katalog tidak valid.',
    ),
    CatalogFailureCode.stallNotFound => (
    404,
    'STALL_NOT_FOUND',
    'Kantin tidak ditemukan.',
    ),
    CatalogFailureCode.unavailable => (
    503,
    'CATALOG_UNAVAILABLE',
    'Layanan katalog sedang tidak tersedia. Coba lagi.',
    ),
  };

  return ApiException(
    statusCode: statusCode,
    code: code,
    message: failure.message ?? defaultMessage,
  );
}
