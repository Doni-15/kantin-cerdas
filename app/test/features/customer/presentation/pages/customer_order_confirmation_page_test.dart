import '../../../../support/simulation_harness.dart';

void main() {
  testWidgets('empty confirmation has no submit action', (tester) async {
    final h = await createHarness();
    addTearDown(h.dispose);
    await h.restoreCheckoutJournal();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: h.container,
        child: const KantinCerdasApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    h.container.read(routerProvider).go(Routes.customerOrderConfirmation);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Belum ada pilihan untuk dikonfirmasi'), findsOneWidget);
    expect(find.textContaining('Buat pesanan ·'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets(
    'confirmation displays chosen items without sending automatically',
    (tester) async {
      final h = await createHarness();
      addTearDown(h.dispose);
      await h.cart();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: h.container,
          child: const KantinCerdasApp(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      h.container.read(routerProvider).go(Routes.customerOrderConfirmation);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Konfirmasi pesanan'), findsOneWidget);
      expect(h.store.table('orders').length, 8);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
