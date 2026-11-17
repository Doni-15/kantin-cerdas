import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart';
import 'package:test/test.dart';

void main() {
  const port = '8080';
  const host = 'http://127.0.0.1:$port';

  late Process process;
  late StreamSubscription<String> stdoutSubscription;
  late StreamSubscription<String> stderrSubscription;

  late Completer<void> serverReady;

  setUp(() async {
    serverReady = Completer<void>();

    process = await Process.start(
      'dart',
      ['run', 'bin/server.dart'],
      environment: {'SERVER_HOST': '127.0.0.1', 'SERVER_PORT': port},
    );

    // Terus baca stdout agar proses server dapat menulis log.
    stdoutSubscription = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          print('[SERVER] $line');

          if (line.contains('started successfully') &&
              !serverReady.isCompleted) {
            serverReady.complete();
          }
        });

    // Terus baca stderr agar buffer tidak penuh.
    stderrSubscription = process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          print('[SERVER ERROR] $line');
        });

    await serverReady.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        process.kill();
        throw TimeoutException('Server tidak berhasil dijalankan.');
      },
    );
  });

  tearDown(() async {
    process.kill();

    await process.exitCode;

    await stdoutSubscription.cancel();
    await stderrSubscription.cancel();
  });

  test('Health endpoint returns application status', () async {
    final response = await get(Uri.parse('$host/v1/health'));

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
      final request = await client.postUrl(Uri.parse('$host/v1/not-found'));

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
  http://127.0.0.1:8080/v1/not-found \
  -o /dev/null \
  -w '%{http_code}'
''',
      ]);

      expect(result.exitCode, 0, reason: 'curl failed: ${result.stderr}');

      expect(result.stdout.toString().trim(), '413');

      final healthResponse = await get(Uri.parse('$host/v1/health'));

      expect(healthResponse.statusCode, 200);
    },
  );

  test('Unknown endpoint returns 404', () async {
    final response = await get(Uri.parse('$host/v1/not-found'));

    expect(response.statusCode, 404);

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final error = body['error'] as Map<String, dynamic>;

    expect(body['success'], isFalse);
    expect(error['code'], 'ROUTE_NOT_FOUND');
    expect(error['message'], 'Route not found');
  });
}
