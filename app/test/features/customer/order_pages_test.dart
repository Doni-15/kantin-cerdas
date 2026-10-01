import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_history_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_orders_page.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_orders_page.dart';
import 'package:kantin_cerdas/theme/kc_theme.dart';

void main() {
  testWidgets('halaman pesanan customer menampilkan status aktif', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: KcTheme.dark,
        home: const Scaffold(body: CustomerOrdersPage()),
      ),
    );

    expect(find.text('KC-027'), findsOneWidget);
    expect(find.text('Menunggu konfirmasi'), findsNWidgets(2));
    expect(find.text('Rp30.000'), findsOneWidget);
  });

  testWidgets('halaman riwayat menampilkan pesanan selesai', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: KcTheme.dark,
        home: const Scaffold(body: CustomerHistoryPage()),
      ),
    );

    expect(find.text('Pesanan KC-019'), findsOneWidget);
    expect(find.text('Tunai diterima'), findsOneWidget);
    expect(find.text('Rp18.000'), findsOneWidget);
  });

  testWidgets('owner dapat menyaring pesanan berdasarkan antrean', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: KcTheme.dark,
        home: const Scaffold(body: OwnerOrdersPage()),
      ),
    );

    expect(find.text('KC-027'), findsOneWidget);
    expect(find.text('KC-025'), findsNothing);

    await tester.tap(find.text('Diproses · 2'));
    await tester.pumpAndSettle();

    expect(find.text('KC-025'), findsOneWidget);
    expect(find.text('KC-026'), findsOneWidget);
    expect(find.text('KC-027'), findsNothing);
  });
}
