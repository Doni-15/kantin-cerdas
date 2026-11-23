import 'package:kantin_cerdas_backend/src/modules/auth/presentation/http/auth_request_fields.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/routes/auth_route_context.dart';
import 'package:shelf_router/shelf_router.dart';

void registerLoginRoutes(Router router, {required AuthRouteContext context}) {
  context.registerSessionPair(
    router,
    '/login',
    (body) => context.auth.login(readAuthEmail(body), readAuthPassword(body)),
  );
}
