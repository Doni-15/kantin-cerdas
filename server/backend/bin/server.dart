import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf_io.dart' as shelf_io;

import 'package:kantin_cerdas_backend/src/app/app_router.dart';
import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_parser.dart';
import 'package:kantin_cerdas_backend/src/core/supabase/supabase_service.dart';

Future<void> main() async {
  await runZonedGuarded<Future<void>>(
    _run,
    (error, stack) {
      stderr.writeln('[FATAL] Error tidak tertangani: $error\n$stack');
      exit(70);
    },
  );
}

Future<void> _run() async {
  // 1. Muat konfigurasi (fail-fast)
  final AppConfig config;
  try {
    config = EnvConfig.load();
  } 
  on EnvConfigException catch (e) {
    stderr.writeln('[FATAL] Konfigurasi tidak valid: $e');
    exit(1);
  } 
  catch (e) {
    stderr.writeln('[FATAL] Gagal memuat konfigurasi (${e.runtimeType})');
    exit(1);
  }

  // 2. Bangun dependensi dan jalankan server
  final supabaseService = SupabaseService(config.supabase);

  final HttpServer server;
  try {
    final handler = buildAppHandler(
      config: config,
      supabaseService: supabaseService,
    );
    server = await shelf_io.serve(
      handler,
      config.server.host,
      config.server.port,
      poweredByHeader: null,
    );
  } 
  on SocketException catch (e) {
    stderr.writeln(
      '[FATAL] Gagal membuka ${config.server.host}:${config.server.port}: '
      '${e.message}',
    );

    await _safeDispose(supabaseService);
    exit(1);
  } 
  catch (e, st) {
    stderr.writeln('[FATAL] Gagal menyiapkan server: $e\n$st');
    await _safeDispose(supabaseService);
    exit(1);
  }

  server.idleTimeout = const Duration(seconds: 30);

  stdout.writeln(
    '[INFO] ${config.app.name} v${config.app.version} (${config.app.env.name}) '
    'aktif di http://${server.address.host}:${server.port}${config.server.apiPrefix} '
    '[Supabase: ${config.supabase.projectRef}]',
  );

  // 3. Graceful shutdown
  var shuttingDown = false;
  Future<void> shutdown(ProcessSignal signal) async {
    if (shuttingDown) return;

    shuttingDown = true;
    stdout.writeln('[INFO] Menerima sinyal $signal, menutup server dengan aman...');

    try {
      await server.close().timeout(
        Duration(seconds: config.server.shutdownTimeoutSeconds),
      );
    } 
    on TimeoutException {
      await server.close(force: true);
    } 
    catch (e) {
      stderr.writeln('[ERROR] Gagal menutup server: $e');
    } 
    finally {
      await _safeDispose(supabaseService);
    }
    exit(0);
  }

  ProcessSignal.sigint.watch().listen(shutdown);
  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen(shutdown);
  }
}

Future<void> _safeDispose(SupabaseService service) async {
  try {
    await service.dispose();
  } 
  catch (e) {
    stderr.writeln('[ERROR] Gagal dispose SupabaseService: $e');
  }
}