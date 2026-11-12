import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final libDir = Directory('lib');

  List<File> listDartFiles(Directory dir) {
    if (!dir.existsSync()) {
      return const [];
    }
    return dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));
  }

  List<String> extractDirectives(File file) {
    final content = file.readAsStringSync();
    final pattern = RegExp(
      r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
      multiLine: true,
    );
    return pattern
        .allMatches(content)
        .map((m) => m.group(1)!)
        .toList(growable: false);
  }

  group('Clean Architecture Boundary Audit (HIGH-NEW-04, MED-NEW-03, LOW-NEW-03)', () {
    test(
      'lib/core tidak mengimpor atau mengekspor modul dari lib/features',
      () {
        final violations = <String>[];
        final coreFiles = listDartFiles(Directory('lib/core'));

        for (final file in coreFiles) {
          final normalizedPath = file.path.replaceAll(r'\', '/');
          for (final target in extractDirectives(file)) {
            if (target.startsWith('package:kantin_cerdas/features/') ||
                target.contains('/features/') ||
                target.startsWith('../features/')) {
              violations.add('$normalizedPath -> $target');
            }
          }
        }

        expect(violations, isEmpty, reason: violations.join('\n'));
      },
    );

    test(
      'lib/features/*/presentation tidak mengimpor atau mengekspor layer data',
      () {
        final violations = <String>[];
        final allFiles = listDartFiles(libDir);

        for (final file in allFiles) {
          final normalizedPath = file.path.replaceAll(r'\', '/');
          if (!normalizedPath.contains('/features/') ||
              !normalizedPath.contains('/presentation/')) {
            continue;
          }
          for (final target in extractDirectives(file)) {
            final isDataImport =
                RegExp(
                  r'^package:kantin_cerdas/features/[^/]+/data/',
                ).hasMatch(target) ||
                target.contains('/data/');
            if (isDataImport) {
              violations.add('$normalizedPath -> $target');
            }
          }
        }

        expect(violations, isEmpty, reason: violations.join('\n'));
      },
    );

    test(
      'lib/features/*/domain bebas dari dependensi data, presentation, dan Flutter UI',
      () {
        final violations = <String>[];
        final allFiles = listDartFiles(libDir);

        for (final file in allFiles) {
          final normalizedPath = file.path.replaceAll(r'\', '/');
          if (!normalizedPath.contains('/features/') ||
              !normalizedPath.contains('/domain/')) {
            continue;
          }
          for (final target in extractDirectives(file)) {
            final importsDataOrPresentation =
                RegExp(
                  r'^package:kantin_cerdas/features/[^/]+/(?:data|presentation)/',
                ).hasMatch(target) ||
                target.contains('/data/') ||
                target.contains('/presentation/');
            final importsFlutterUi = target.startsWith('package:flutter/');
            if (importsDataOrPresentation || importsFlutterUi) {
              violations.add('$normalizedPath -> $target');
            }
          }
        }

        expect(violations, isEmpty, reason: violations.join('\n'));
      },
    );

    test(
      'seluruh lib/ bebas dari kode simulasi pengujian dan enum *FailureKind hibrida',
      () {
        final directiveViolations = <String>[];
        final failureKindViolations = <String>[];
        final allFiles = listDartFiles(libDir);

        for (final file in allFiles) {
          final normalizedPath = file.path.replaceAll(r'\', '/');
          for (final target in extractDirectives(file)) {
            if (target.contains('simulation') || target.contains('test/')) {
              directiveViolations.add('$normalizedPath -> $target');
            }
          }
          final content = file.readAsStringSync();
          if (content.contains('FailureKind')) {
            failureKindViolations.add(normalizedPath);
          }
        }

        expect(
          directiveViolations,
          isEmpty,
          reason: directiveViolations.join('\n'),
        );
        expect(
          failureKindViolations,
          isEmpty,
          reason: failureKindViolations.join('\n'),
        );
      },
    );

    test(
      'lib/features/*/data/repositories dan kontrak *_datasource.dart abstrak bebas dari dependensi konkret Dio',
      () {
        final violations = <String>[];
        final allFiles = listDartFiles(libDir);

        for (final file in allFiles) {
          final normalizedPath = file.path.replaceAll(r'\', '/');
          final isRepositoryImpl =
              normalizedPath.contains('/features/') &&
              normalizedPath.contains('/data/repositories/');
          final isAbstractDataSource =
              normalizedPath.contains('/features/') &&
              normalizedPath.contains('/data/datasources/') &&
              normalizedPath.endsWith('_datasource.dart') &&
              !normalizedPath.endsWith('_api_datasource.dart');

          if (!isRepositoryImpl && !isAbstractDataSource) {
            continue;
          }

          for (final target in extractDirectives(file)) {
            if (target.startsWith('package:dio/') ||
                target.endsWith('_api_datasource.dart')) {
              violations.add('$normalizedPath -> $target');
            }
          }
        }

        expect(violations, isEmpty, reason: violations.join('\n'));
      },
    );
  });
}
