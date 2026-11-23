import 'dart:async';
import 'dart:io';

import 'package:kantin_cerdas_backend/src/app/bootstrap.dart';
import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:shelf/shelf_io.dart';

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
Future<void> _shutdownServer(
  HttpServer server,
  Duration timeout, {
  Future<void> Function()? onDispose,
}) async {
  print('Stopping HTTP server...');

  try {
    await server.close(force: false).timeout(timeout);
    print('All active connections have been closed.');
  } on TimeoutException {
    print(
      'Graceful shutdown timeout reached. '
      'Forcing remaining connections to close.',
    );

    await server.close(force: true);
  } finally {
    if (onDispose != null) {
      await onDispose();
    }
  }

  print('HTTP server stopped successfully.');
}

Future<void> main(List<String> args) async {
  final env = await EnvConfig.load();
  final config = AppConfig.fromEnv(env);
  final address = await _resolveAddress(config.server.host);
  final runtime = buildAppRuntime(config, env: env);
  final server = await serve(runtime.handler, address, config.server.port);
  final apiPrefix = config.server.apiPrefix;

  print('${config.appName} started successfully.');
  print('Environment : ${config.environment.name}');
  print('Version     : ${config.version}');
  print('Bind address: ${server.address.address}');
  print('Port        : ${server.port}');
  print('API Prefix  : $apiPrefix');
  print('Health path : $apiPrefix/health');
  print('Auth path   : $apiPrefix/auth');
  print('Catalog path: $apiPrefix/catalog');
  print('Owner path  : $apiPrefix/owner');
  print('Customer    : $apiPrefix/customer');
  print('Admin path  : $apiPrefix/admin');
  print('AI path     : $apiPrefix/ai');
  print('Notif path  : $apiPrefix/notifications');

  final signal = await _waitForShutdownSignal();

  print('\nReceived shutdown signal: $signal');

  await _shutdownServer(
    server,
    config.server.shutdownTimeout,
    onDispose: runtime.dispose,
  );
}
