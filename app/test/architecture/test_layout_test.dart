import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Penjaga tata letak folder `test/` (lihat `test/README.md`).
//
// Tujuannya satu: orang yang mengubah satu berkas di `lib/` bisa menemukan
// test-nya tanpa mencari. Aturan di bawah murah dijalankan dan hanya menolak
// pelanggaran struktur, bukan menuntut jumlah test tertentu.
const mirroredRoots = {'app', 'core', 'features'};
const crossCuttingRoots = {'architecture', 'contracts', 'domain', 'simulation'};
const maxTestFileLines = 700;

String normalize(String path) => path.replaceAll(r'\', '/');

List<String> dartFilesUnderTest() {
  final files =
      Directory('test')
          .listSync(recursive: true)
          .whereType<File>()
          .map((file) => normalize(file.path))
          .where((path) => path.endsWith('.dart'))
          .toList()
        ..sort();
  return files;
}

bool isSupport(String path) => path.startsWith('test/support/');

List<String> testFiles() => dartFilesUnderTest()
    .where((path) => !isSupport(path))
    .toList(growable: false);

void expectNoViolations(List<String> violations, String advice) {
  expect(violations, isEmpty, reason: '$advice\n${violations.join('\n')}');
}

void main() {
  group('Tata letak folder test', () {
    test('setiap berkas test berada di folder tingkat atas yang dikenal', () {
      final allowed = {...mirroredRoots, ...crossCuttingRoots};
      final violations = <String>[];

      for (final path in testFiles()) {
        final segments = path.split('/');
        if (segments.length < 3 || !allowed.contains(segments[1])) {
          violations.add(path);
        }
      }

      expectNoViolations(
        violations,
        'Letakkan test di salah satu: ${allowed.toList()..sort()}, '
        'atau di support/ bila berkas itu bukan test.',
      );
    });

    test(
      'folder test app/, core/, dan features/ mencerminkan folder di lib/',
      () {
        final violations = <String>[];

        for (final path in testFiles()) {
          final segments = path.split('/');
          if (segments.length < 3 || !mirroredRoots.contains(segments[1])) {
            continue;
          }
          final directory = segments.sublist(1, segments.length - 1).join('/');
          if (!Directory('lib/$directory').existsSync()) {
            violations.add('$path (lib/$directory tidak ada)');
          }
        }

        expectNoViolations(
          violations,
          'Test untuk lib/X harus berada di test/X. Pindahkan test ke folder '
          'yang sama dengan berkas yang diuji.',
        );
      },
    );

    test(
      'hanya berkas bernama *_test.dart di luar support/, dan tidak ada test di support/',
      () {
        final violations = <String>[
          for (final path in dartFilesUnderTest())
            if (isSupport(path) && path.endsWith('_test.dart'))
              '$path (test tidak boleh berada di support/)'
            else if (!isSupport(path) && !path.endsWith('_test.dart'))
              '$path (berkas pendukung harus berada di support/)',
        ];

        expectNoViolations(violations, 'Perbaiki lokasi atau nama berkas.');
      },
    );

    test('test tidak mengimpor test lain; berbagi kode lewat support/', () {
      final importPattern = RegExp(r'''^\s*import\s+['"]([^'"]+)['"]''');
      final violations = <String>[];

      for (final path in testFiles()) {
        for (final line in File(path).readAsLinesSync()) {
          final uri = importPattern.firstMatch(line)?.group(1);
          if (uri == null ||
              uri.startsWith('package:') ||
              uri.startsWith('dart:')) {
            continue;
          }
          if (uri.endsWith('_test.dart')) {
            violations.add('$path -> $uri');
          }
        }
      }

      expectNoViolations(
        violations,
        'Pindahkan kode bersama ke test/support/ agar urutan eksekusi dan '
        'kepemilikan test tidak saling bergantung.',
      );
    });

    test(
      'tidak ada berkas test yang membengkak melebihi $maxTestFileLines baris',
      () {
        final violations = <String>[
          for (final path in testFiles())
            if (File(path).readAsLinesSync().length > maxTestFileLines)
              '$path (${File(path).readAsLinesSync().length} baris)',
        ];

        expectNoViolations(
          violations,
          'Pecah berkas menurut subjek yang diuji, bukan menurut nomor temuan.',
        );
      },
    );
  });
}
