import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// Application-level route composer mounting all module handlers under [AppConfig.server.apiPrefix].
Router buildRouter(
  AppConfig config, {
  required Handler authHandler,
  required Handler catalogHandler,
  Handler? ownerHandler,
  Handler? customerHandler,
  Handler? adminHandler,
  Handler? aiHandler,
  Handler? notificationsHandler,
}) {
  final apiPrefix = config.server.apiPrefix;
  final router = Router(
    notFoundHandler: (Request request) {
      return ApiResponse.error(
        statusCode: 404,
        code: 'ROUTE_NOT_FOUND',
        message: 'Route not found',
      );
    },
  );

  router.get('$apiPrefix/health', (Request request) {
    return ApiResponse.success(
      data: {
        'status': 'ok',
        'application': config.appName,
        'version': config.version,
        'environment': config.environment.name,
      },
    );
  });

  router.mount('$apiPrefix/auth/', authHandler);
  router.mount('$apiPrefix/catalog/', catalogHandler);

  if (ownerHandler != null) {
    router.mount('$apiPrefix/owner/', ownerHandler);
  }
  if (customerHandler != null) {
    router.mount('$apiPrefix/customer/', customerHandler);
  }
  if (adminHandler != null) {
    router.mount('$apiPrefix/admin/', adminHandler);
  }
  if (aiHandler != null) {
    router.mount('$apiPrefix/ai/', aiHandler);
  }
  if (notificationsHandler != null) {
    router.mount('$apiPrefix/notifications/', notificationsHandler);
  }

  return router;
}
