import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final libDir = Directory('lib').existsSync()
      ? Directory('lib')
      : Directory('app/lib');

  List<String> extractUris(String content) {
    final uris = <String>[];
    final directivePattern = RegExp(
      r'''^\s*(?:import|export)\s+([\s\S]*?);''',
      multiLine: true,
    );
    final quotePattern = RegExp(r'''['"]([^'"]+)['"]''');
    for (final match in directivePattern.allMatches(content)) {
      final block = match.group(1) ?? '';
      for (final uriMatch in quotePattern.allMatches(block)) {
        final uri = uriMatch.group(1);
        if (uri != null) {
          uris.add(uri);
        }
      }
    }
    return uris;
  }

  String relativePosix(File file, Directory base) {
    final basePath = base.absolute.path.replaceAll('\\', '/');
    final filePath = file.absolute.path.replaceAll('\\', '/');
    final prefix = basePath.endsWith('/') ? basePath : '$basePath/';
    return filePath.startsWith(prefix)
        ? filePath.substring(prefix.length)
        : filePath;
  }

  group('Flutter Clean Architecture Boundaries', () {
    test('removes dead CatalogView scaffold', () {
      expect(
        File(
          '${libDir.path}/features/catalog/presentation/catalog_view.dart',
        ).existsSync(),
        isFalse,
      );
    });

    test('enforces core, domain, presentation, data, and app layer rules', () {
      expect(libDir.existsSync(), isTrue);
      final dartFiles =
          libDir
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => file.path.endsWith('.dart'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));

      expect(dartFiles, isNotEmpty);
      final violations = <String>[];

      for (final file in dartFiles) {
        final rel = relativePosix(file, libDir);
        final uris = extractUris(file.readAsStringSync());

        for (final uri in uris) {
          if (rel.startsWith('core/') || rel.startsWith('theme/')) {
            if (uri.contains('/features/') ||
                uri.startsWith('package:kantin_cerdas/app/')) {
              violations.add('core/theme violation: $rel -> $uri');
            }
            continue;
          }

          if (rel.startsWith('app/') ||
              rel == 'main.dart' ||
              rel == 'kantin_cerdas_app.dart') {
            if (uri.contains('/data/')) {
              violations.add('app->data violation: $rel -> $uri');
            }
            continue;
          }

          if (!rel.startsWith('features/')) continue;
          final segments = rel.split('/');
          if (segments.length < 3) continue;
          final layerName = segments[2];

          if (layerName == 'domain') {
            if (uri.contains('/data/') ||
                uri.contains('/presentation/') ||
                uri.contains('/application/') ||
                uri.startsWith('package:flutter/')) {
              violations.add('domain violation: $rel -> $uri');
            }
          } else if (layerName == 'presentation') {
            if (uri.contains('/data/')) {
              violations.add('presentation->data violation: $rel -> $uri');
            }
          } else if (layerName == 'data') {
            if (uri.contains('/presentation/') ||
                uri.contains('/application/')) {
              violations.add('data violation: $rel -> $uri');
            }
          } else if (layerName == 'application') {
            if (uri.contains('/presentation/')) {
              violations.add(
                'application->presentation violation: $rel -> $uri',
              );
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Flutter architecture boundary violations:\n${violations.join('\n')}',
      );
    });
  });
}
