import 'dart:async';
import 'dart:io';

import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/cors_middleware.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/security_headers.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/request_header_guard.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/request_body_guard.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/rate_limit_middleware.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/request_timeout_middleware.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/request_logging_middleware.dart';
import 'package:kantin_cerdas_backend/src/core/middleware/error_handler_middleware.dart';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

Handler _buildHandler(AppConfig config) {
  final router = Router(
    notFoundHandler: (Request request) {
      return ApiResponse.error(
        statusCode: 404,
        code: 'ROUTE_NOT_FOUND',
        message: 'Route not found',
      );
    },
  );

  router.get('${config.server.apiPrefix}/health', (Request request) {
    return ApiResponse.success(
      data: {
        'status': 'ok',
        'application': config.appName,
        'version': config.version,
        'environment': config.environment.name,
      },
    );
  });

  var pipeline = Pipeline();

  // Security Headers membungkus middleware berikutnya.
  pipeline = pipeline.addMiddleware(securityHeaders(config.security));

  // Logging request menggunakan konfigurasi aplikasi.
  pipeline = pipeline.addMiddleware(
    RequestLoggingMiddleware(config: config.logging).middleware,
  );

  // Mengubah exception menjadi respons API JSON yang konsisten.
  pipeline = pipeline.addMiddleware(
    ErrorHandlerMiddleware(config: config.logging).middleware,
  );

  // Membatasi waktu pemrosesan request.
  pipeline = pipeline.addMiddleware(
    requestTimeoutMiddleware(config.server.requestTimeout),
  );

  // Header Guard memvalidasi Host dan Content-Length tanpa membaca body.
  pipeline = pipeline.addMiddleware(
    requestHeaderGuard(
      securityConfig: config.security,
      serverConfig: config.server,
    ),
  );

  // CORS menangani origin dan preflight request.
  pipeline = pipeline.addMiddleware(corsMiddleware(config.cors));

  // Rate Limiting membatasi request berdasarkan IP client.
  final rateLimitMiddleware = RateLimitMiddleware(
    config: config.rateLimit,
    proxyConfig: config.proxy,
    apiPrefix: config.server.apiPrefix,
  );

  pipeline = pipeline.addMiddleware(rateLimitMiddleware.middleware);

  // Body Guard membatasi ukuran body aktual dan concurrency request berbadan.
  pipeline = pipeline.addMiddleware(
    requestBodyGuard(serverConfig: config.server),
  );

  return pipeline.addHandler(router.call);
}

Future<InternetAddress> _resolveAddress(String host) async {
  final parsedAddress = InternetAddress.tryParse(host);

  if (parsedAddress != null) {
    return parsedAddress;
  }

  final addresses = await InternetAddress.lookup(host);

  if (addresses.isEmpty) {
    throw SocketException('Tidak dapat menemukan alamat host: $host');
  }

  return addresses.first;
}

/// Menunggu SIGINT (Ctrl+C) atau SIGTERM.
Future<ProcessSignal> _waitForShutdownSignal() async {
  final completer = Completer<ProcessSignal>();

  final subscriptions = <StreamSubscription<ProcessSignal>>[];

  void handleSignal(ProcessSignal signal) {
    if (!completer.isCompleted) {
      completer.complete(signal);
    }
  }

  subscriptions.add(ProcessSignal.sigint.watch().listen(handleSignal));

  subscriptions.add(ProcessSignal.sigterm.watch().listen(handleSignal));

  final signal = await completer.future;

  for (final subscription in subscriptions) {
    await subscription.cancel();
  }

  return signal;
}

/// Menutup server dengan graceful shutdown dan batas waktu.
Future<void> _shutdownServer(HttpServer server, Duration timeout) async {
  print('Stopping HTTP server...');

  try {
    // Berhenti menerima koneksi baru.
    // Koneksi aktif diberi kesempatan untuk selesai.
    await server.close(force: false).timeout(timeout);

    print('All active connections have been closed.');
  } on TimeoutException {
    print(
      'Graceful shutdown timeout reached. '
      'Forcing remaining connections to close.',
    );

    // Batas waktu habis: tutup koneksi yang masih aktif.
    await server.close(force: true);
  }

  print('HTTP server stopped successfully.');
}

Future<void> main(List<String> args) async {
  final env = await EnvConfig.load();
  final config = AppConfig.fromEnv(env);

  final address = await _resolveAddress(config.server.host);
  final handler = _buildHandler(config);

  final server = await serve(handler, address, config.server.port);

  print('${config.appName} started successfully.');
  print('Environment : ${config.environment.name}');
  print('Version     : ${config.version}');
  print('Address     : ${server.address.address}');
  print('Port        : ${server.port}');
  print('API Prefix  : ${config.server.apiPrefix}');
  print(
    'Health      : http://${config.server.host}:${server.port}'
    '${config.server.apiPrefix}/health',
  );

  // Server tetap berjalan sampai menerima sinyal penghentian.
  final signal = await _waitForShutdownSignal();

  print('\nReceived shutdown signal: $signal');

  await _shutdownServer(server, config.server.shutdownTimeout);
}
