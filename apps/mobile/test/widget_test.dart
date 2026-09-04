import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kantincerdas/main.dart';

void main() {
  testWidgets('menampilkan status fondasi KantinCerdas', (tester) async {
    await tester.pumpWidget(const KantinCerdasApp());

    expect(find.text('KantinCerdas'), findsOneWidget);
    expect(find.text('Fondasi aplikasi siap'), findsOneWidget);
    expect(find.byIcon(Icons.restaurant_menu), findsOneWidget);
  });
}
