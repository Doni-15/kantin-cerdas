import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/avatar_store.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/http/auth_request_body.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/http/auth_response_mapper.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/security/auth_web_session.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class AuthRouteContext {
  const AuthRouteContext({
    required this.auth,
    required this.avatars,
    this.cookies = const AuthWebSessionCookie(),
  });

  final AuthGateway auth;
  final AvatarStore avatars;
  final AuthWebSessionCookie cookies;

  Future<Map<String, Object?>> accountJson(AuthAccount account) async =>
      authAccountJson(account, hasPhoto: await avatars.exists(account.id));

  Future<Response> sessionResponse(
    AuthSession session, {
    AuthWebSessionCookie? cookie,
  }) async => authSessionResponse(
    session,
    await accountJson(session.account),
    cookie: cookie,
  );

  void registerSessionPair(
    Router router,
    String path,
    Future<AuthSession> Function(Map<String, Object?> body) start,
  ) {
    router.post(
      path,
      (Request request) async =>
          sessionResponse(await start(await readAuthJsonBody(request))),
    );
    router.post(
      '/web$path',
      (Request request) async => sessionResponse(
        await start(await readAuthJsonBody(request)),
        cookie: cookies,
      ),
    );
  }
}
