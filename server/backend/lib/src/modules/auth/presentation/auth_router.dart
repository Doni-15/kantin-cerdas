import 'package:kantin_cerdas_backend/src/core/auth/auth_guard.dart';
import 'package:kantin_cerdas_backend/src/core/config/storage_config.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/avatar_store.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/routes/account_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/routes/auth_route_context.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/routes/google_auth_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/routes/login_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/routes/password_reset_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/routes/profile_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/routes/registration_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/routes/session_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/security/auth_web_origin.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

export 'package:kantin_cerdas_backend/src/core/auth/auth_guard.dart';

Handler buildAuthHandler(
  AuthGateway auth, {
  required AvatarStore avatars,
  required StorageConfig storage,
  required String? webOrigin,
  required bool googleEnabled,
  Uri? supabaseUrl,
}) {
  final router = Router();
  final context = AuthRouteContext(auth: auth, avatars: avatars);

  registerRegistrationRoutes(router, context: context);
  registerLoginRoutes(router, context: context);
  registerGoogleAuthRoutes(
    router,
    context: context,
    googleEnabled: googleEnabled,
    supabaseUrl: supabaseUrl,
  );
  registerSessionRoutes(router, context: context);
  registerProfileRoutes(router, context: context, storage: storage);
  registerPasswordResetRoutes(router, context: context);
  registerAccountRoutes(router, context: context);

  return (request) async {
    final ApiException error;
    try {
      if (request.url.path.startsWith('web/')) {
        requireAuthWebOrigin(request, webOrigin);
      }
      final response = await router.call(request);
      if (identical(response, Router.routeNotFound)) return response;
      return response.change(headers: noStoreHeaders);
    } on AuthFailure catch (failure) {
      error = authFailureException(failure);
    } on ApiException catch (exception) {
      error = exception;
    }

    return ApiResponse.error(
      statusCode: error.statusCode,
      code: error.code,
      message: error.message,
      headers: noStoreHeaders,
    );
  };
}
