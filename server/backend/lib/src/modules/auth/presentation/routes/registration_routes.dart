import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/http/auth_request_body.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/http/auth_request_fields.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/routes/auth_route_context.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/security/auth_web_origin.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

void registerRegistrationRoutes(
  Router router, {
  required AuthRouteContext context,
}) {
  router.post('/register', (Request request) async {
    final body = await readAuthJsonBody(request);
    await context.auth.register(
      readAuthEmail(body),
      readAuthPassword(body, newPassword: true),
      name: body.containsKey('display_name') ? readAuthDisplayName(body) : null,
      androidRedirect: !isAuthBrowserRequest(request),
    );
    return ApiResponse.success(statusCode: 202, data: {'next': 'verify_email'});
  });

  context.registerSessionPair(
    router,
    '/verify-email',
    (body) =>
        context.auth.verifyRegistration(readAuthEmail(body), readAuthOtp(body)),
  );

  context.registerSessionPair(
    router,
    '/verify-email/link',
    (body) => context.auth.verifyRegistrationLink(readAuthLinkToken(body)),
  );

  router.post('/verify-email/resend', (Request request) async {
    final body = await readAuthJsonBody(request);
    await context.auth.resendRegistration(
      readAuthEmail(body),
      androidRedirect: !isAuthBrowserRequest(request),
    );
    return ApiResponse.success(statusCode: 202, data: {'next': 'verify_email'});
  });
}
