import '../../../../support/simulation_harness.dart';

void main() {
  test(
    'cart uses current availability, one stall and quantity limits',
    () async {
      final h = await createHarness();
      addTearDown(h.dispose);
      await h.cart();
      final catalog = await h.container.read(customerCatalogProvider.future);
      final cart = h.container.read(cartProvider.notifier);
      expect(cart.addItem(catalog.menuById('menu-1-0')!), isFalse);
      expect(cart.addItem(catalog.menuById('menu-0-4')!), isFalse);
      for (var i = 1; i < 99; i++) {
        expect(cart.addItem(catalog.menuById('menu-0-0')!), isTrue);
      }
      expect(cart.addItem(catalog.menuById('menu-0-0')!), isFalse);
      expect(h.container.read(cartProvider).totalQuantity, 99);
    },
  );
  test(
    'pending checkout locks cart and account switch clears choices',
    () async {
      final h = await createHarness();
      addTearDown(h.dispose);
      await h.cart();
      final menu = h.container.read(cartProvider).items.first.menu;
      await h.container
          .read(customerCheckoutJournalProvider('customer-1').notifier)
          .begin(
            PendingOrderSubmission(
              customerId: 'customer-1',
              submissionId: 'pending-test',
            ),
          );
      expect(h.container.read(cartProvider.notifier).addItem(menu), isFalse);
      await h.login('pelanggan2');
      expect(h.container.read(cartProvider).isEmpty, isTrue);
    },
  );
  test('owner can use personal cart while admin cannot', () async {
    final h = await createHarness(username: 'pemilik');
    addTearDown(h.dispose);
    await h.cart();
    expect(h.container.read(cartProvider).totalQuantity, 1);
    await h.login('admin');
    expect(h.container.read(customerCheckoutReviewProvider), isNull);
  });
}
