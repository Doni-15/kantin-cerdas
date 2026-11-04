import '../../../../support/simulation_harness.dart';

void main() {
  test(
    'single flight sends once and success clears the submitted cart',
    () async {
      final h = await createHarness();
      addTearDown(h.dispose);
      final confirmation = await h.cart();
      final count = h.store.table('orders').length;
      final controller = h.container.read(
        customerOrderControllerProvider.notifier,
      );
      final first = controller.submit(confirmation: confirmation);
      expect(await controller.submit(confirmation: confirmation), isNull);
      expect(await first, isNotNull);
      expect(h.store.table('orders').length, count + 1);
      expect(h.container.read(cartProvider).isEmpty, isTrue);
    },
  );
  test(
    'unknown result stays locked and lookup recovers without duplicate',
    () async {
      final h = await createHarness();
      addTearDown(h.dispose);
      final confirmation = await h.cart();
      final count = h.store.table('orders').length;
      final controller = h.container.read(
        customerOrderControllerProvider.notifier,
      );
      h.store.scenario = SimulationScenario.unknown;
      expect(await controller.submit(confirmation: confirmation), isNull);
      expect(h.container.read(customerCheckoutLockedProvider), isTrue);
      expect(await controller.submit(confirmation: confirmation), isNull);
      h.store.scenario = SimulationScenario.normal;
      expect(await controller.recover(), isNotNull);
      expect(h.store.table('orders').length, count + 1);
    },
  );
  test(
    'definitive rejection preserves input and clears pending marker',
    () async {
      final h = await createHarness();
      addTearDown(h.dispose);
      final confirmation = await h.cart();
      h.store.scenario = SimulationScenario.conflict;
      expect(
        await h.container
            .read(customerOrderControllerProvider.notifier)
            .submit(confirmation: confirmation),
        isNull,
      );
      expect(h.container.read(cartProvider).totalQuantity, 1);
      expect(
        (await h.container.read(
          customerCheckoutJournalProvider('customer-1').future,
        )),
        isNull,
      );
    },
  );
  test(
    'value-equal confirmation succeeds after catalog refresh while altered price confirmation is rejected',
    () async {
      final h = await createHarness();
      addTearDown(h.dispose);
      final actual = await h.cart();
      final altered = CustomerOrderPriceConfirmation(
        draft: actual.draft,
        unitPricesIdr: {
          for (final entry in actual.unitPricesIdr.entries)
            entry.key: entry.value + 1000,
        },
      );
      expect(
        await h.container
            .read(customerOrderControllerProvider.notifier)
            .submit(confirmation: altered),
        isNull,
      );
      expect(h.container.read(cartProvider).isNotEmpty, isTrue);

      final sameValueCopy = CustomerOrderPriceConfirmation(
        draft: actual.draft,
        unitPricesIdr: Map<String, int>.from(actual.unitPricesIdr),
      );
      expect(sameValueCopy, equals(actual));
      expect(sameValueCopy.hashCode, equals(actual.hashCode));
      expect(
        await h.container
            .read(customerOrderControllerProvider.notifier)
            .submit(confirmation: sameValueCopy),
        isNotNull,
      );
      expect(h.container.read(cartProvider).isEmpty, isTrue);
    },
  );
}
