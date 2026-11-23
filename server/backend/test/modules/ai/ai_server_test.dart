import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:test/test.dart';

import '../../config_test.dart' show validEnvironment;

void main() {
  final bindAddress = InternetAddress.loopbackIPv4.address;
  final entrypoint = File('bin/server.dart').absolute.path;
  final packages = File('.dart_tool/package_config.json').absolute.path;
  final portLine = RegExp(r'^Port\s*:\s*(\d+)$');

  Future<({Process process, Uri origin, Future<void> Function() stop})>
  startServer(String targetEntrypoint) async {
    final scratch = await Directory('.dart_tool').createTemp('ai-srv-test-');
    final serverReady = Completer<int>();

    final process = await Process.start(
      Platform.resolvedExecutable,
      ['--packages=$packages', targetEntrypoint],
      workingDirectory: scratch.absolute.path,
      environment: validEnvironment(
        overrides: {'SERVER_HOST': bindAddress, 'SERVER_PORT': '0'},
      ),
      includeParentEnvironment: false,
    );

    final stdoutSubscription = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final value = portLine.firstMatch(line)?.group(1);
          if (value != null && !serverReady.isCompleted) {
            serverReady.complete(int.parse(value));
          }
        });

    final stderrSubscription = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((_) {});

    final port = await serverReady.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        process.kill();
        throw TimeoutException('Server failed to start: $targetEntrypoint');
      },
    );
    return (
      process: process,
      origin: Uri(scheme: 'http', host: bindAddress, port: port),
      stop: () async {
        process.kill();
        await process.exitCode;
        await stdoutSubscription.cancel();
        await stderrSubscription.cancel();
        await scratch.delete(recursive: true);
      },
    );
  }

  test(
    'canonical bin/server.dart activates AI and Notifications alongside Health, Auth, Catalog, Owner, Customer, and Admin',
    () async {
      final srv = await startServer(entrypoint);
      addTearDown(srv.stop);

      final health = await get(srv.origin.resolve('/v1/health'));
      expect(health.statusCode, 200);

      final aiStatus = await get(srv.origin.resolve('/v1/ai/status'));
      expect(aiStatus.statusCode, 401);

      final notifStatus = await get(
        srv.origin.resolve('/v1/notifications/status'),
      );
      expect(notifStatus.statusCode, 401);

      final adminDash = await get(srv.origin.resolve('/v1/admin/dashboard'));
      expect(adminDash.statusCode, 401);

      final customerCart = await get(srv.origin.resolve('/v1/customer/cart'));
      expect(customerCart.statusCode, 401);
    },
  );
}
