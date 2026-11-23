import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/http/auth_request_body.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/http/auth_request_fields.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/routes/auth_route_context.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

void registerPasswordResetRoutes(
  Router router, {
  required AuthRouteContext context,
}) {
  router.post('/password-reset', (Request request) async {
    final body = await readAuthJsonBody(request);
    await context.auth.requestPasswordReset(readAuthEmail(body));
    return ApiResponse.success(statusCode: 202, data: {'next': 'check_email'});
  });

  router.post('/password-reset/check', (Request request) async {
    final body = await readAuthJsonBody(request);
    await context.auth.checkPasswordResetLink(readAuthLinkToken(body));
    return ApiResponse.success(data: null);
  });

  router.post('/password-reset/confirm', (Request request) async {
    final body = await readAuthJsonBody(request);
    final password = readAuthPassword(body, newPassword: true);
    if (body.containsKey('token_hash')) {
      await context.auth.resetPasswordLink(readAuthLinkToken(body), password);
    } else {
      await context.auth.resetPassword(
        readAuthEmail(body),
        readAuthOtp(body),
        password,
      );
    }
    return ApiResponse.success(data: null);
  });
}
