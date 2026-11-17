import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Router buildRouter(AppConfig config) {
  final router = Router(
    notFoundHandler: (Request request) {
      return ApiResponse.error(
        statusCode: 404,
        code: 'ROUTE_NOT_FOUND',
        message: 'Route not found',
      );
    },
  );

  router.get('${config.server.apiPrefix}/health', (Request request) {
    return ApiResponse.success(
      data: {
        'status': 'ok',
        'application': config.appName,
        'version': config.version,
        'environment': config.environment.name,
      },
    );
  });

  return router;
}
