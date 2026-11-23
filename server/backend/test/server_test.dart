import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:test/test.dart';

import 'config_test.dart' show validEnvironment;

void main() {
  final bindAddress = InternetAddress.loopbackIPv4.address;
  final entrypoint = File('bin/server.dart').absolute.path;
  final packages = File('.dart_tool/package_config.json').absolute.path;
  final portLine = RegExp(r'^Port\s*:\s*(\d+)$');
  late Process process;
  late StreamSubscription<String> stdoutSubscription;
  late StreamSubscription<String> stderrSubscription;
  late Uri origin;

  setUp(() async {
    final scratch = await Directory('.dart_tool').createTemp('shelf-test-');
    addTearDown(() => scratch.delete(recursive: true));
    final serverReady = Completer<int>();

    process = await Process.start(
      Platform.resolvedExecutable,
      ['--packages=$packages', entrypoint],
      workingDirectory: scratch.absolute.path,
      environment: validEnvironment(
        overrides: {'SERVER_HOST': bindAddress, 'SERVER_PORT': '0'},
      ),
      includeParentEnvironment: false,
    );

    // Terus baca stdout agar proses server dapat menulis log.
    stdoutSubscription = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          print('[SERVER] $line');

          final value = portLine.firstMatch(line)?.group(1);
          if (value != null && !serverReady.isCompleted) {
            serverReady.complete(int.parse(value));
          }
        });

    // Terus baca stderr agar buffer tidak penuh.
    stderrSubscription = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          print('[SERVER ERROR] $line');
        });

    final port = await serverReady.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        process.kill();
        throw TimeoutException('Server tidak berhasil dijalankan.');
      },
    );
    origin = Uri(scheme: 'http', host: bindAddress, port: port);
  });

  tearDown(() async {
    process.kill();

    await process.exitCode;

    await stdoutSubscription.cancel();
    await stderrSubscription.cancel();
  });

  test('Health endpoint returns application status', () async {
    final response = await get(origin.resolve('/v1/health'));

    expect(response.statusCode, 200);

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    expect(body['success'], isTrue);

    final data = body['data'] as Map<String, dynamic>;

    expect(data['status'], 'ok');
    expect(data['application'], isNotEmpty);
    expect(data['version'], isNotEmpty);
    expect(data['environment'], isNotEmpty);
  });

  test('Chunked request within body limit reaches router', () async {
    final client = HttpClient();

    try {
      final request = await client.postUrl(origin.resolve('/v1/not-found'));

      request.add(List<int>.filled(1024, 65));

      final response = await request.close();

      expect(response.statusCode, 404);
      await response.drain<void>();
    } finally {
      client.close(force: true);
    }
  });

  test(
    'Oversized chunked request is rejected and server stays responsive',
    () async {
      final result = await Process.run('bash', [
        '-c',
        r'''
head -c 10485761 /dev/zero | curl \
  --http1.1 \
  --silent \
  --show-error \
  --max-time 15 \
  -H 'Transfer-Encoding: chunked' \
  -H 'Expect:' \
  --data-binary @- \
  "$1" \
  -o /dev/null \
  -w '%{http_code}'
''',
        'shelf-test',
        origin.resolve('/v1/not-found').toString(),
      ]);

      expect(result.exitCode, 0, reason: 'curl failed: ${result.stderr}');

      expect(result.stdout.toString().trim(), '413');

      final healthResponse = await get(origin.resolve('/v1/health'));

      expect(healthResponse.statusCode, 200);
    },
  );

  test('Unknown endpoint returns 404', () async {
    final response = await get(origin.resolve('/v1/not-found'));

    expect(response.statusCode, 404);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final error = body['error'] as Map<String, dynamic>;

    expect(body['success'], isFalse);
    expect(error['code'], 'ROUTE_NOT_FOUND');
    expect(error['message'], 'Route not found');
  });

  test(
    'Strict Railway SECURITY_ALLOWED_HOSTS allows healthcheck.railway.app and blocks unknown Host',
    () async {
      final scratch = await Directory('.dart_tool').createTemp('shelf-host-');
      addTearDown(() => scratch.delete(recursive: true));
      final ready = Completer<int>();

      final strictProcess = await Process.start(
        Platform.resolvedExecutable,
        ['--packages=$packages', entrypoint],
        workingDirectory: scratch.absolute.path,
        environment: validEnvironment(
          overrides: {
            'APP_ENV': 'staging',
            'APP_DEBUG': 'false',
            'SERVER_HOST': bindAddress,
            'SERVER_PORT': '0',
            'SECURITY_ALLOWED_HOSTS':
                'kantin-cerdas.up.railway.app,healthcheck.railway.app',
            'CORS_ENABLED': 'false',
          },
        ),
        includeParentEnvironment: false,
      );

      final outSub = strictProcess.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            final value = portLine.firstMatch(line)?.group(1);
            if (value != null && !ready.isCompleted) {
              ready.complete(int.parse(value));
            }
          });
      final errSub = strictProcess.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((_) {});

      try {
        final strictPort = await ready.future.timeout(
          const Duration(seconds: 15),
        );
        final strictOrigin = Uri(
          scheme: 'http',
          host: bindAddress,
          port: strictPort,
        );

        Future<({int statusCode, Map<String, dynamic> body})> probe(
          String hostHeader,
        ) async {
          final client = HttpClient();
          try {
            final req = await client.getUrl(strictOrigin.resolve('/v1/health'));
            req.headers.set(HttpHeaders.hostHeader, hostHeader);
            final res = await req.close();
            final raw = await utf8.decodeStream(res);
            return (
              statusCode: res.statusCode,
              body: jsonDecode(raw) as Map<String, dynamic>,
            );
          } finally {
            client.close(force: true);
          }
        }

        final healthcheckProbe = await probe('healthcheck.railway.app');
        expect(healthcheckProbe.statusCode, 200);
        expect(healthcheckProbe.body['success'], isTrue);
        expect(
          (healthcheckProbe.body['data'] as Map<String, dynamic>)['status'],
          'ok',
        );

        final publicProbe = await probe('kantin-cerdas.up.railway.app');
        expect(publicProbe.statusCode, 200);
        expect(publicProbe.body['success'], isTrue);

        final blockedProbe = await probe('evil.example.com');
        expect(blockedProbe.statusCode, 403);
        expect(blockedProbe.body['success'], isFalse);
        expect(
          (blockedProbe.body['error'] as Map<String, dynamic>)['code'],
          'HOST_NOT_ALLOWED',
        );
      } finally {
        strictProcess.kill();
        await strictProcess.exitCode;
        await outSub.cancel();
        await errSub.cancel();
      }
    },
  );
}
