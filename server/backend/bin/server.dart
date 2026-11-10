import 'dart:async';
import 'dart:io';
import 'package:kantin_cerdas_backend/src/app/app_router.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_parser.dart';
import 'package:kantin_cerdas_backend/src/core/supabase/supabase_service.dart';

Future<void> main() async {
  final AppConfig config;
  try {
    config = EnvConfig.load();
  } 
  on EnvConfigException catch (e) {
    stderr.writeln('[FATAL] Konfigurasi tidak valid: $e');
    exit(1);
  } 
  catch (e) {
    stderr.writeln('[FATAL] Gagal memuat konfigurasi: $e');
    exit(1);
  }

  final supabaseService = SupabaseService(config.supabase);
  final handler = buildAppHandler(
    config: config,
    supabaseService: supabaseService,
  );

  final HttpServer server;
  try {
    server = await shelf_io.serve(
      handler,
      config.server.host,
      config.server.port,
    );
  } 
  on SocketException catch (e) {
    stderr.writeln(
      '[FATAL] Gagal membuka ${config.server.host}:${config.server.port}: ${e.message}',
    );
    await supabaseService.dispose();
    exit(1);
  }

  stdout.writeln(
    '[INFO] ${config.app.name} v${config.app.version} (${config.app.env.name}) '
    'aktif di http://${server.address.host}:${server.port}${config.server.apiPrefix} '
    '[Supabase: ${config.supabase.projectRef}]',
  );

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
    finally {
      await supabaseService.dispose();
    }
    exit(0);
  }

  ProcessSignal.sigint.watch().listen(shutdown);
  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen(shutdown);
  }
}