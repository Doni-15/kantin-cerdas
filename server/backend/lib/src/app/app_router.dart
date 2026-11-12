import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:kantin_cerdas_backend/src/core/middleware/requests_guard.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/auth_router.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/auth_service.dart';
import 'package:kantin_cerdas_backend/src/modules/media/media_router.dart';
import 'package:kantin_cerdas_backend/src/modules/media/media_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:supabase/supabase.dart';

import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/supabase/supabase_service.dart';

Handler buildAppHandler({
  required AppConfig config,
  required SupabaseService supabaseService,
}) {
  final router = Router();
  final prefix = config.server.apiPrefix;

  // 1. Endpoint pemeriksaan kesehatan server (Healthcheck)
  router.get('$prefix/health', (Request request) {
    return Response.ok(
      jsonEncode({
        'status': 'ok',
        'service': config.app.name,
        'version': config.app.version,
        'environment': config.app.env.name,
        // Identitas proyek Supabase tidak perlu terlihat publik di production.
        if (config.app.env.isDevelopment)
          'project_ref': config.supabase.projectRef,
      }),
      headers: const {
        'content-type': 'application/json; charset=utf-8',
        'cache-control': 'no-store',
      },
    );
  });

  // Modul auth
  final authService = AuthService(supabaseService, config);
  router.mount(
    '$prefix/auth/',
    buildAuthRouter(authService, config.storage).call,
  );

  // Modul image
  final mediaService = MediaService(
    supabase: supabaseService,
    config: config,
  );

  router.mount(
    '$prefix/media/', buildMediaRouter(authService: authService, mediaService: mediaService).call
  );

  // 2. Fallback 404 standar kontrak (wajib menyertakan field "code")
  router.all('/<ignored|.*>', (Request request) {
    return ApiException.notFound(
      'Endpoint ${request.method} /${request.url.path} tidak ditemukan.',
      'ENDPOINT_NOT_FOUND',
    ).toResponse();
  });

  // 3. Rangkaian Middleware: Request Logger -> CORS & Security Headers -> Error Boundary
  var pipeline = const Pipeline();
  if (config.logging.requestEnabled) {
    pipeline = pipeline.addMiddleware(logRequests());
  }

  return pipeline
    .addMiddleware(_corsAndSecurityMiddleware(config))
    .addMiddleware(_errorBoundaryMiddleware(config))
    .addMiddleware(allowedHostsMiddleware(config))
    .addMiddleware(rateLimitMiddleware(config))
    .addMiddleware(bodyLimitMiddleware(config))
    .addMiddleware(requestTimeoutMiddleware(config))
    .addHandler(router.call);
}

Middleware _corsAndSecurityMiddleware(AppConfig config) {
  final cors = config.cors;
  final allowAny = cors.allowedOrigins.contains('*');
  final explicitOrigins = cors.allowedOrigins
      .where((o) => o != '*')
      .map((o) => o.toLowerCase())
      .toSet();

  final securityHeaders = <String, String>{};
  if (config.security.enableSecurityHeaders) {
    securityHeaders['x-content-type-options'] = 'nosniff';
    securityHeaders['x-frame-options'] = 'DENY';
    securityHeaders['referrer-policy'] = 'no-referrer';
  }

  // `Access-Control-Allow-Origin` hanya boleh berisi SATU origin (atau `*`).
  // Daftar dipisah koma tidak valid dan ditolak browser, jadi origin request
  // dicocokkan dengan daftar lalu di-echo, disertai `Vary: Origin`.
  Map<String, String> corsHeaders(Request request) {
    if (!cors.enabled) return const {};

    final headers = <String, String>{
      'access-control-allow-methods': cors.allowedMethods.join(', '),
      'access-control-allow-headers': cors.allowedHeaders.join(', '),
      'access-control-max-age': '${cors.maxAgeSeconds}',
    };

    final origin = request.headers['origin'];
    if (allowAny) {
      // `*` tidak boleh dikombinasikan dengan credentials.
      if (!cors.allowCredentials) {
        headers['access-control-allow-origin'] = '*';
      }
    } else {
      headers['vary'] = 'Origin';
      if (origin != null && explicitOrigins.contains(origin.toLowerCase())) {
        headers['access-control-allow-origin'] = origin;
        if (cors.allowCredentials) {
          headers['access-control-allow-credentials'] = 'true';
        }
      }
    }
    return headers;
  }

  return (Handler innerHandler) {
    return (Request request) async {
      final headers = {...corsHeaders(request), ...securityHeaders};

      if (cors.enabled && request.method == 'OPTIONS') {
        return Response.ok('', headers: headers);
      }

      final response = await innerHandler(request);
      return response.change(headers: {...headers, ...response.headers});
    };
  };
}

Middleware _errorBoundaryMiddleware(AppConfig config) {
  void logError(Request request, Object e, StackTrace st, {String? extra}) {
    final where = '${request.method} /${request.url.path}';
    stderr.writeln('[ERROR] ${extra ?? 'Unhandled exception'} on $where: $e');
    if (config.logging.includeStackTrace) stderr.writeln(st);
  }

  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } 
      on ApiException catch (e) {
        return e.toResponse();
      } 
      on PostgrestException catch (e, st) {
        final mapped = ApiException.fromPostgrest(e);
        // Error DB yang tidak terpetakan (500) wajib terlihat di log server.
        if (mapped.statusCode >= 500) {
          logError(
            request,
            'code=${e.code} message=${e.message} details=${e.details} hint=${e.hint}',
            st,
            extra: 'PostgrestException',
          );
        }
        return mapped.toResponse();
      } 
      on AuthException catch (e) {
        return ApiException.fromSupabaseAuth(e).toResponse();
      } 
      on TimeoutException catch (_) {
        return const ApiException(
          statusCode: 504,
          code: 'UPSTREAM_TIMEOUT',
          message: 'Layanan sedang lambat merespons. Silakan coba lagi.',
        ).toResponse();
      } 
      catch (e, st) {
        // FormatException TIDAK lagi dipetakan menjadi "JSON tidak valid" di
        // sini: JSON rusak ditangani di router (INVALID_JSON), sehingga bug
        // server tidak tersamar sebagai kesalahan client.
        logError(request, e, st);
        return const ApiException(
          statusCode: 500,
          code: 'INTERNAL_SERVER_ERROR',
          message: 'Terjadi kesalahan internal pada server.',
        ).toResponse();
      }
    };
  };
}
