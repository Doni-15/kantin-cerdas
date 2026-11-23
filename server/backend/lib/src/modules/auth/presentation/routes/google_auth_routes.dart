import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/http/auth_request_body.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/http/auth_request_fields.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/presentation/routes/auth_route_context.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

void registerGoogleAuthRoutes(
  Router router, {
  required AuthRouteContext context,
  required bool googleEnabled,
  required Uri? supabaseUrl,
}) {
  router.get('/google/config', (Request request) async {
    if (!googleEnabled || supabaseUrl == null) {
      throw AuthFailure.googleDisabled;
    }
    return ApiResponse.success(
      data: {'google_enabled': true, 'supabase_url': supabaseUrl.toString()},
    );
  });

  router.post('/google', (Request request) async {
    if (!googleEnabled) throw AuthFailure.googleDisabled;
    final body = await readAuthJsonBody(request);
    return context.sessionResponse(
      await context.auth.loginWithGoogle(
        idToken: readAuthToken(body, 'id_token'),
        googleAccessToken: readAuthToken(body, 'google_access_token'),
        nonce: body.containsKey('nonce')
            ? readAuthToken(body, 'nonce', maxLength: 256)
            : null,
      ),
    );
  });

  context.registerSessionPair(router, '/google/exchange', (body) async {
    if (!googleEnabled) throw AuthFailure.googleDisabled;
    if (body.containsKey('supabase_url') && supabaseUrl != null) {
      final clientUrl = readAuthText(
        body,
        'supabase_url',
        maxLength: 256,
      ).trim();
      if (!matchesServerSupabaseOrigin(clientUrl, supabaseUrl)) {
        throw invalidAuthInput(
          'Proyek Supabase pada aplikasi tidak sesuai dengan konfigurasi server.',
        );
      }
    }
    final code = readAuthToken(body, 'code', maxLength: 512);
    final verifier = readAuthText(body, 'code_verifier', maxLength: 128);
    if (!RegExp(r'^[A-Za-z0-9._~-]{43,128}$').hasMatch(verifier)) {
      throw invalidAuthInput('Format verifikasi Google tidak valid.');
    }
    return context.auth.exchangeGoogleCode(code, verifier);
  });
}
