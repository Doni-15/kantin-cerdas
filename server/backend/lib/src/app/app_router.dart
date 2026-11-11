import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:kantin_cerdas_backend/src/core/middleware/requests_guard.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/auth_router.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/auth_service.dart';
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
        'project_ref': config.supabase.projectRef,
      }),
      headers: const {
        'content-type': 'application/json; charset=utf-8',
        'cache-control': 'no-store',
      },
    );
  });

  // Modul auth
  final authService = AuthService(supabaseService);
  router.mount('$prefix/auth/', buildAuthRouter(authService).call);

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
  final headers = <String, String>{};

  if (config.cors.enabled) {
    headers['access-control-allow-origin'] = config.cors.allowedOrigins.join(', ');
    headers['access-control-allow-methods'] = config.cors.allowedMethods.join(', ');
    headers['access-control-allow-headers'] = config.cors.allowedHeaders.join(', ');
    headers['access-control-max-age'] = '${config.cors.maxAgeSeconds}';

    if (config.cors.allowCredentials) {
      headers['access-control-allow-credentials'] = 'true';
    }
  }

  if (config.security.enableSecurityHeaders) {
    headers['x-content-type-options'] = 'nosniff';
    headers['x-frame-options'] = 'DENY';
    headers['referrer-policy'] = 'no-referrer';
  }

  return (Handler innerHandler) {
    return (Request request) async {
      if (config.cors.enabled && request.method == 'OPTIONS') {
        return Response.ok('', headers: headers);
      }

      final response = await innerHandler(request);
      return response.change(headers: {...headers, ...response.headers});
    };
  };
}

Middleware _errorBoundaryMiddleware(AppConfig config) {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } 
      on ApiException catch (e) {
        return e.toResponse();
      } 
      on PostgrestException catch (e) {
        return ApiException.fromPostgrest(e).toResponse();
      } 
      on AuthException catch (e) {
        return ApiException.fromSupabaseAuth(e).toResponse();
      } 
      on FormatException catch (_) {
        return ApiException.badRequest(
          'Format body JSON tidak valid.',
          code: 'INVALID_JSON',
        ).toResponse();
      } 
      on TimeoutException catch (_) {
        return const ApiException(
          statusCode: 504,
          code: 'UPSTREAM_TIMEOUT',
          message: 'Layanan sedang lambat merespons. Silakan coba lagi.',
        ).toResponse();
      } 
      catch (e, st) {
        if (config.logging.includeStackTrace) {
          stderr.writeln(
            '[ERROR] Unhandled exception on ${request.method} /${request.url.path}: $e\n$st',
          );
        } 
        else {
          stderr.writeln(
            '[ERROR] Unhandled exception on ${request.method} /${request.url.path}: $e',
          );
        }

        return const ApiException(
          statusCode: 500,
          code: 'INTERNAL_SERVER_ERROR',
          message: 'Terjadi kesalahan internal pada server.',
        ).toResponse();
      }
    };
  };
}