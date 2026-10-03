import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_orders_page.dart';
import 'package:kantin_cerdas/theme/kc_colors.dart';

void main() {
  testWidgets('owner dapat mengubah status pesanan dan antreannya', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: const [KcStatusColors.light]),
        home: const Scaffold(body: OwnerOrdersPage()),
      ),
    );

    expect(find.text('KC-027'), findsOneWidget);
    expect(find.text('Baru (3)'), findsOneWidget);

    await tester.ensureVisible(find.text('Ubah status').first);
    await tester.tap(find.text('Ubah status').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Diproses').last);
    await tester.pumpAndSettle();

    expect(find.text('KC-027'), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, 1000));
    await tester.pumpAndSettle();
    expect(find.text('Baru (2)'), findsOneWidget);

    await tester.tap(find.text('Diproses · 3'));
    await tester.pumpAndSettle();

    expect(find.text('KC-027'), findsOneWidget);
    expect(find.text('Diproses (3)'), findsOneWidget);
  });
}
