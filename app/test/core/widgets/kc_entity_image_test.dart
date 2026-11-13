import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/widgets/kc_entity_image.dart';

import '../../support/simulation/simulation.dart';

void main() {
  group('KcEntityImage', () {
    testWidgets(
      'KcEntityImage menerapkan cacheWidth/cacheHeight berbasis DPR dan membedakan key memori untuk byte berukuran sama namun isi berbeda',
      (tester) async {
        final bytesA = Uint8List.fromList(
          SimulationImagePickerPort.validSamplePngBytes,
        );
        final bytesB = Uint8List.fromList(
          SimulationImagePickerPort.validSamplePngBytes,
        );
        // Ubah byte tengah tanpa mengubah panjang array
        bytesB[bytesB.length ~/ 2] = (bytesB[bytesB.length ~/ 2] + 1) & 0xFF;

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(devicePixelRatio: 2.0),
              child: Scaffold(
                body: KcEntityImage.thumbnail(
                  imageUrl: null,
                  previewBytes: bytesA,
                  width: 80,
                  height: 60,
                  fallbackIcon: Icons.fastfood_rounded,
                ),
              ),
            ),
          ),
        );

        final firstImage = tester.widget<Image>(find.byType(Image));
        final firstKey = firstImage.key;
        expect(firstImage.image, isA<ResizeImage>());
        final resized = firstImage.image as ResizeImage;
        expect(resized.width, 160);
        expect(resized.height, 120);

        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(devicePixelRatio: 2.0),
              child: Scaffold(
                body: KcEntityImage.thumbnail(
                  imageUrl: null,
                  previewBytes: bytesB,
                  width: 80,
                  height: 60,
                  fallbackIcon: Icons.fastfood_rounded,
                ),
              ),
            ),
          ),
        );

        final secondImage = tester.widget<Image>(find.byType(Image));
        expect(secondImage.key, isNot(equals(firstKey)));
      },
    );
  });
}
