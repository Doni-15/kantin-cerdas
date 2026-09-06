import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kantincerdas/design_system_preview.dart';

void main() {
  for (final width in [360.0, 390.0, 412.0]) {
    testWidgets('pratinjau tema terang dan gelap pada $width dp', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.runAsync(() async {
        final loader = FontLoader('PlusJakartaSans');
        for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
          loader.addFont(
            rootBundle.load('assets/fonts/PlusJakartaSans-$weight.ttf'),
          );
        }
        await loader.load();
        final icons = FontLoader('MaterialIcons');
        icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
        await icons.load();
      });
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(key: boundaryKey, child: const DesignSystemPreview()),
      );
      for (final mode in ['light', 'dark']) {
        if (mode == 'dark') {
          await tester.tap(find.byTooltip('Ganti tema terang atau gelap'));
          await tester.pump();
        }
        // Indikator loading sengaja berjalan; jangan pumpAndSettle.
        for (var frame = 0; frame < 6; frame++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
        expect(tester.takeException(), isNull);
        final boundary =
            boundaryKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          try {
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final directory = Directory('build/design-system-preview');
            await directory.create(recursive: true);
            await File(
              '${directory.path}/${width.toInt()}-$mode.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
          } finally {
            image.dispose();
          }
        });
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
