import 'package:kantin_cerdas_backend/src/core/auth/auth_guard.dart';
import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/http/auth_request_body.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/http/auth_request_fields.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/routes/auth_route_context.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

void registerSessionRoutes(Router router, {required AuthRouteContext context}) {
  final cookies = context.cookies;

  router.post('/refresh', (Request request) async {
    final body = await readAuthJsonBody(request);
    return context.sessionResponse(
      await context.auth.refresh(readAuthToken(body, 'refresh_token')),
    );
  });

  router.post('/web/refresh', (Request request) async {
    await readAuthJsonBody(request);
    final token = cookies.read(request);
    if (token == null) return cookies.empty();
    try {
      return context.sessionResponse(
        await context.auth.refresh(token),
        cookie: cookies,
      );
    } on AuthFailure catch (failure) {
      if (failure != AuthFailure.invalidSession &&
          failure != AuthFailure.inactiveAccount &&
          failure != AuthFailure.emailNotVerified) {
        rethrow;
      }
      return cookies.empty();
    }
  });

  router.post('/web/logout', (Request request) async {
    final body = await readAuthJsonBody(request);

    final intendedAccount = body.containsKey('account_id')
        ? readAuthText(body, 'account_id', maxLength: 128)
        : null;

    final token = cookies.read(request);
    if (token == null) return cookies.empty();

    try {
      final session = await context.auth.refresh(token);
      if (intendedAccount != null && intendedAccount != session.account.id) {
        return ApiResponse.success(
          data: null,
          headers: {'set-cookie': cookies.serialize(session.refreshToken)},
        );
      }
      await context.auth.logout(session.accessToken);
    } on AuthFailure catch (failure) {
      if (failure != AuthFailure.invalidSession &&
          failure != AuthFailure.inactiveAccount &&
          failure != AuthFailure.emailNotVerified) {
        rethrow;
      }
    }
    return cookies.empty();
  });

  router.post('/logout', (Request request) async {
    await context.auth.logout(requireBearer(request));
    return ApiResponse.success(data: null);
  });
}
