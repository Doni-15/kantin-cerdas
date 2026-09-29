import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kantin_cerdas/kantin_cerdas_app.dart';

void main() {
  testWidgets(
    'KantinCerdas app dapat ditampilkan',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: KantinCerdasApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('KantinCerdas'), findsWidgets);
    },
  );
}