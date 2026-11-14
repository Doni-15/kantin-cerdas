import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:supabase/supabase.dart';

import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/requests_guard.dart';
import 'package:kantin_cerdas_backend/src/core/supabase/supabase_service.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/admin_router.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/admin_service.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/auth_router.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/auth_service.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/orders/customer_orders_router.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/orders/customer_orders_service.dart';
import 'package:kantin_cerdas_backend/src/modules/media/media_router.dart';
import 'package:kantin_cerdas_backend/src/modules/media/media_service.dart';
import 'package:kantin_cerdas_backend/src/modules/operations/operations_router.dart';
import 'package:kantin_cerdas_backend/src/modules/operations/operations_service.dart';

/// Kunci context Shelf untuk menyimpan ID korelasi request (`x-request-id`).
const String requestIdContextKey = 'kantin_cerdas.request_id';

/// Pola karakter aman untuk `x-request-id` dari klien (mencegah log/header injection).
final RegExp _safeRequestIdPattern = RegExp(r'^[A-Za-z0-9._:-]{8,128}$');

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
        if (config.app.env.isDevelopment)
          'project_ref': config.supabase.projectRef,
      }),
      headers: const {
        'content-type': 'application/json; charset=utf-8',
        'cache-control': 'no-store',
      },
    );
  });

  // 2. Inisialisasi service dengan Dependency Injection bersih
  final mediaService = MediaService(supabase: supabaseService, config: config);
  final authService = AuthService(supabaseService, mediaService: mediaService);
  final adminService = AdminService(supabase: supabaseService);
  final customerOrdersService = CustomerOrdersService(supabaseService);
  final operationsService = OperationsService(supabase: supabaseService);

  router.mount(
    '$prefix/auth/',
    buildAuthRouter(authService, config.storage).call,
  );

  router.mount(
    '$prefix/media/',
    buildMediaRouter(authService: authService, mediaService: mediaService).call,
  );

  router.mount(
    '$prefix/customer/orders/',
    buildCustomerOrdersRouter(
      authService: authService,
      customerOrdersService: customerOrdersService,
    ),
  );

  router.mount(
    '$prefix/admin/',
    buildAdminRouter(authService: authService, adminService: adminService).call,
  );

  router.mount(
    '$prefix/operations/',
    buildOperationsRouter(
      authService: authService,
      operationsService: operationsService,
    ),
  );

  // 3. Fallback 404 standar kontrak (wajib menyertakan field "code")
  router.all('/<ignored|.*>', (Request request) {
    return ApiException.notFound(
      'Endpoint ${request.method} /${request.url.path} tidak ditemukan.',
      'ENDPOINT_NOT_FOUND',
    ).toResponse();
  });

  // 4. Rangkaian Middleware (terluar -> terdalam):
  //    Request ID -> Request Logger -> CORS & Security Headers -> Error Boundary
  //    -> Allowed Hosts -> Rate Limit -> Body Limit -> Timeout -> Router
  var pipeline = const Pipeline().addMiddleware(_requestIdMiddleware());
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

/// Memberi setiap request ID korelasi (`x-request-id`). ID dari klien dipakai
/// hanya bila formatnya aman (mencegah log injection); selain itu dibuat acak.
/// ID dikembalikan di header respons dan field `request_id` pada respons error.
Middleware _requestIdMiddleware() {
  final random = Random.secure();

  String generate() => List<String>.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  return (Handler innerHandler) {
    return (Request request) async {
      final inbound = request.headers['x-request-id']?.trim();
      final id = (inbound != null && _safeRequestIdPattern.hasMatch(inbound))
          ? inbound
          : generate();

      final response = await innerHandler(
        request.change(context: {requestIdContextKey: id}),
      );
      return response.change(headers: {'x-request-id': id});
    };
  };
}

String? _requestIdOf(Request request) {
  final value = request.context[requestIdContextKey];
  return value is String ? value : null;
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

  Map<String, String> corsHeaders(Request request) {
    if (!cors.enabled) return const {};

    final headers = <String, String>{
      'access-control-allow-methods': cors.allowedMethods.join(', '),
      'access-control-allow-headers': cors.allowedHeaders.join(', '),
      'access-control-max-age': '${cors.maxAgeSeconds}',
    };

    final origin = request.headers['origin'];
    if (allowAny) {
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
    final rid = _requestIdOf(request);
    stderr.writeln(
      '[ERROR]${rid == null ? '' : ' [$rid]'} '
      '${extra ?? 'Unhandled exception'} on $where: $e',
    );
    if (config.logging.includeStackTrace) stderr.writeln(st);
  }

  return (Handler innerHandler) {
    return (Request request) async {
      final rid = _requestIdOf(request);
      try {
        return await innerHandler(request);
      } on ApiException catch (e) {
        return e.toResponse(requestId: rid);
      } on PostgrestException catch (e, st) {
        final mapped = ApiException.fromPostgrest(e);
        if (mapped.statusCode >= 500) {
          logError(
            request,
            'code=${e.code} message=${e.message} details=${e.details} hint=${e.hint}',
            st,
            extra: 'PostgrestException',
          );
        }
        return mapped.toResponse(requestId: rid);
      } on AuthException catch (e, st) {
        final mapped = ApiException.fromSupabaseAuth(e);
        if (mapped.statusCode >= 500) {
          logError(
            request,
            'status=${e.statusCode} code=${e.code} message=${e.message}',
            st,
            extra: 'AuthException',
          );
        }
        return mapped.toResponse(requestId: rid);
      } on TimeoutException catch (_) {
        return const ApiException(
          statusCode: 504,
          code: 'UPSTREAM_TIMEOUT',
          message: 'Layanan sedang lambat merespons. Silakan coba lagi.',
        ).toResponse(requestId: rid);
      } on SocketException catch (e, st) {
        logError(request, e, st, extra: 'Upstream unreachable');
        return const ApiException(
          statusCode: 503,
          code: 'UPSTREAM_UNAVAILABLE',
          message:
              'Layanan pendukung sedang tidak tersedia. Silakan coba lagi.',
        ).toResponse(requestId: rid);
      } on http.ClientException catch (e, st) {
        logError(request, e, st, extra: 'Upstream unreachable');
        return const ApiException(
          statusCode: 503,
          code: 'UPSTREAM_UNAVAILABLE',
          message:
              'Layanan pendukung sedang tidak tersedia. Silakan coba lagi.',
        ).toResponse(requestId: rid);
      } catch (e, st) {
        logError(request, e, st);
        return const ApiException(
          statusCode: 500,
          code: 'INTERNAL_SERVER_ERROR',
          message: 'Terjadi kesalahan internal pada server.',
        ).toResponse(requestId: rid);
      }
    };
  };
}
