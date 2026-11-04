import '../../../../support/simulation_harness.dart';

void main() {
  test('catalog and owner data refer to the same menu and stall', () async {
    final h = await createHarness();
    addTearDown(h.dispose);
    h.container.listen(customerCatalogProvider, (_, _) {});
    final catalog = await h.container.read(customerCatalogProvider.future);
    expect(catalog.stalls, hasLength(3));
    expect(catalog.menus, hasLength(15));
    expect(catalog.canOrder('menu-2-0'), isFalse);
    expect(catalog.canOrder('menu-0-4'), isFalse);
  });
  test(
    'empty and failed reads are distinct; explicit retry recovers',
    () async {
      final h = await createHarness();
      addTearDown(h.dispose);
      h.container.listen(customerCatalogProvider, (_, _) {});
      h.store.scenario = SimulationScenario.empty;
      expect(
        (await h.container.read(customerCatalogProvider.future)).menus,
        isEmpty,
      );
      h.store.scenario = SimulationScenario.readError;
      h.container.invalidate(customerCatalogProvider);
      await expectLater(
        h.container.read(customerCatalogProvider.future),
        throwsA(isA<FormatException>()),
      );
      h.store.scenario = SimulationScenario.normal;
      h.container.invalidate(customerCatalogProvider);
      expect(
        (await h.container.read(customerCatalogProvider.future)).menus,
        isNotEmpty,
      );
    },
  );
  test('late read from a logged out session is rejected', () async {
    final h = await createHarness();
    addTearDown(h.dispose);
    h.store.latency = const Duration(milliseconds: 30);
    final pending = SimulationCatalogRepository(h.store).getCatalog();
    final checked = expectLater(pending, throwsA(isA<AuthFailure>()));
    await h.store.signOut();
    await checked;
  });
}
