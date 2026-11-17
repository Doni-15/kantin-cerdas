import 'package:kantin_cerdas_backend/src/app/router.dart';
import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/cors_middleware.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/error_handler_middleware.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/rate_limit_middleware.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/request_body_guard.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/request_header_guard.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/request_logging_middleware.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/request_timeout_middleware.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/security_headers.dart';
import 'package:shelf/shelf.dart';

Handler buildAppHandler(AppConfig config) {
  final pipeline = Pipeline()
      // Security Headers membungkus seluruh middleware berikutnya.
      .addMiddleware(securityHeaders(config.security))
      // Logging request.
      .addMiddleware(
        RequestLoggingMiddleware(config: config.logging).middleware,
      )
      // Penanganan exception menjadi respons API JSON.
      .addMiddleware(ErrorHandlerMiddleware(config: config.logging).middleware)
      // Membatasi waktu pemrosesan request.
      .addMiddleware(requestTimeoutMiddleware(config.server.requestTimeout))
      // Validasi header request.
      .addMiddleware(
        requestHeaderGuard(
          securityConfig: config.security,
          serverConfig: config.server,
        ),
      )
      // CORS.
      .addMiddleware(corsMiddleware(config.cors))
      // Rate limiting berdasarkan IP client.
      .addMiddleware(
        RateLimitMiddleware(
          config: config.rateLimit,
          proxyConfig: config.proxy,
          apiPrefix: config.server.apiPrefix,
        ).middleware,
      )
      // Validasi ukuran request body dan concurrency.
      .addMiddleware(requestBodyGuard(serverConfig: config.server));

  return pipeline.addHandler(buildRouter(config).call);
}
