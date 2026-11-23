import 'dart:io';

import 'package:test/test.dart';

void main() {
  final srcDir = Directory('lib/src').existsSync()
      ? Directory('lib/src')
      : Directory('server/backend/lib/src');
  final binDir = Directory('bin').existsSync()
      ? Directory('bin')
      : Directory('server/backend/bin');

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

  group('Backend Clean Architecture & Modular Monolith Boundaries', () {
    test(
      'enforces single canonical entrypoint and single composition root',
      () {
        expect(
          File('${binDir.path}/server.dart').existsSync(),
          isTrue,
          reason: 'Canonical bin/server.dart must exist',
        );
        for (final legacy in [
          '${binDir.path}/server_with_owner.dart',
          '${binDir.path}/server_all.dart',
          '${srcDir.path}/app/owner_bootstrap.dart',
          '${srcDir.path}/app/customer_bootstrap.dart',
          '${srcDir.path}/app/admin_bootstrap.dart',
          '${srcDir.path}/app/ai_bootstrap.dart',
        ]) {
          expect(
            File(legacy).existsSync(),
            isFalse,
            reason: 'Obsolete entrypoint/bootstrap must stay removed: $legacy',
          );
        }
      },
    );

    test('enforces layer and cross-module dependency rules across lib/src', () {
      expect(srcDir.existsSync(), isTrue);
      final dartFiles =
          srcDir
              .listSync(recursive: true)
              .whereType<File>()
              .where((file) => file.path.endsWith('.dart'))
              .toList()
            ..sort((a, b) => a.path.compareTo(b.path));

      expect(dartFiles, isNotEmpty);
      final violations = <String>[];

      for (final file in dartFiles) {
        final rel = relativePosix(file, srcDir);
        final uris = extractUris(file.readAsStringSync());

        for (final uri in uris) {
          if (rel.startsWith('core/')) {
            if (uri.contains('/modules/') || uri.contains('/app/')) {
              violations.add('$rel must not depend on $uri');
            }
            continue;
          }

          if (!rel.startsWith('modules/')) continue;
          final segments = rel.split('/');
          if (segments.length < 3) continue;
          final moduleName = segments[1];
          final layerName = segments[2];

          if (layerName == 'domain') {
            if (uri.contains('/data/') ||
                uri.contains('/presentation/') ||
                uri.contains('/application/') ||
                uri.startsWith('package:shelf/')) {
              violations.add('domain violation: $rel -> $uri');
            }
          } else if (layerName == 'application') {
            if (uri.contains('/data/') || uri.contains('/presentation/')) {
              violations.add('application violation: $rel -> $uri');
            }
          } else if (layerName == 'data') {
            if (uri.contains('/presentation/') ||
                uri.contains('/application/')) {
              violations.add('data violation: $rel -> $uri');
            }
          } else if (layerName == 'presentation') {
            final crossMatch = RegExp(
              r'/modules/([^/]+)/(presentation|data|application)/',
            ).firstMatch(uri);
            if (crossMatch != null && crossMatch.group(1) != moduleName) {
              violations.add(
                'cross-module presentation violation: $rel -> $uri',
              );
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Architecture boundary violations:\n${violations.join('\n')}',
      );
    });
  });
}
