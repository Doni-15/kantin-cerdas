import 'package:kantin_cerdas_backend/src/core/auth/auth_guard.dart';
import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/http/auth_request_body.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/http/auth_request_fields.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/routes/auth_route_context.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

void registerAccountRoutes(Router router, {required AuthRouteContext context}) {
  router.post('/account/email', (Request request) async {
    final token = requireBearer(request);
    final body = await readAuthJsonBody(request);
    await context.auth.changeCredentials(
      token,
      readAuthPassword(body),
      email: readAuthEmail(body),
    );
    return ApiResponse.success(statusCode: 202, data: {'next': 'check_email'});
  });

  router.post('/account/email/confirm', (Request request) async {
    final body = await readAuthJsonBody(request);
    await context.auth.confirmEmailChange(readAuthLinkToken(body));
    return ApiResponse.success(data: null);
  });

  router.post('/account/password', (Request request) async {
    final token = requireBearer(request);
    final body = await readAuthJsonBody(request);
    await context.auth.changeCredentials(
      token,
      readAuthPassword(body),
      password: readAuthPassword(
        body,
        newPassword: true,
        field: 'new_password',
      ),
    );
    return ApiResponse.success(data: null);
  });
}
