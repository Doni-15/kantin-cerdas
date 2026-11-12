import '../../../../support/simulation_harness.dart';

void main() {
  testWidgets('legacy success URL loads owned order without creating another', (
    tester,
  ) async {
    final h = await createHarness();
    addTearDown(h.dispose);
    h.container.listen(customerOrderDetailProvider('order-seed-0'), (_, _) {});
    await h.container.read(customerOrderDetailProvider('order-seed-0').future);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: h.container,
        child: const KantinCerdasApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    h.container
        .read(routerProvider)
        .go('/customer/orders/order-seed-0/success');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.textContaining('SIM-100'), findsWidgets);
    expect(h.store.table('orders').length, 8);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  test(
    'foreign or missing order never becomes a successful personal order',
    () async {
      final h = await createHarness();
      addTearDown(h.dispose);
      final repo = SimulationTrackingRepository(h.store);
      expect(await repo.getMyOrder(orderId: 'order-seed-7'), isNull);
      expect(await repo.getMyOrder(orderId: 'missing'), isNull);
    },
  );
}
