import 'dart:async';
import '../support/simulation_harness.dart';

Future<void> signIn(SimulationStore store, String username) =>
    SimulationAuthRepository(
      store,
    ).login(identifier: username, password: 'Simulasi123!').then((_) {});
CustomerOrderPriceConfirmation review() {
  final draft = OrderDraft(
    stallId: 'stall-1',
    items: [OrderDraftItem(menuId: 'menu-0-0', quantity: 2)],
    orderNote: 'Tanpa plastik',
  );
  return CustomerOrderPriceConfirmation(
    draft: draft,
    unitPricesIdr: {'menu-0-0': 15000},
  );
}

void main() {
  testWidgets('slow reads still require three seconds of simulated time', (
    tester,
  ) async {
    final h = await createHarness();
    addTearDown(h.dispose);
    h.store.scenario = SimulationScenario.slow;
    var completed = false;
    final result = SimulationCatalogRepository(h.store).getCatalog();
    final observed = result.then((catalog) {
      completed = true;
      return catalog;
    });
    await tester.pump(const Duration(milliseconds: 2999));
    expect(completed, isFalse);
    await tester.pump(const Duration(milliseconds: 1));
    expect(completed, isTrue);
    expect((await observed).menus, isNotEmpty);
  });

  test(
    'customer checkout -> owner fulfilment -> customer history uses one order',
    () async {
      final s = SimulationStore.memory();
      await signIn(s, 'pelanggan');
      final c = review();
      final checkout = SimulationOrderRepository(s);
      final id = await checkout.createOrder(
        draft: c.draft,
        submissionId: 'checkout-1',
        confirmation: c,
      );
      expect(
        await checkout.createOrder(
          draft: c.draft,
          submissionId: 'checkout-1',
          confirmation: c,
        ),
        id,
      );
      expect(s.table('orders').length, 9);
      await signIn(s, 'pemilik');
      final owner = SimulationOwnerRepository(s);
      var order = (await owner.getMyOrder(stallId: 'stall-1', orderId: id))!;
      for (final status in [
        OrderStatus.processing,
        OrderStatus.ready,
        OrderStatus.completed,
      ]) {
        order = await owner.transitionOrder(
          OwnerOrderTransition(
            orderId: id,
            expectedVersion: order.version,
            status: status,
            cashReceived: status == OrderStatus.completed,
            foodHandedOver: status == OrderStatus.completed,
          ),
          mutationId: 'transition-${status.name}',
        );
      }
      await signIn(s, 'pelanggan');
      final history = await SimulationTrackingRepository(
        s,
      ).listMyOrders(history: true);
      expect(
        history.items.any(
          (o) => o.id == id && o.paymentStatus == OrderPaymentStatus.paid,
        ),
        isTrue,
      );
      expect(order.totalPriceIdr, 30000);
    },
  );
  test(
    'price or closed-stall mismatch rejects checkout with no extra order',
    () async {
      final s = SimulationStore.memory();
      await signIn(s, 'pemilik');
      final owner = SimulationOwnerRepository(s);
      final menu = (await owner.listMenus(
        stallId: 'stall-1',
        search: 'Nasi Ayam',
      )).items.first;
      await owner.saveMenu(
        OwnerMenuInput(
          id: menu.id,
          stallId: menu.stallId,
          name: menu.name,
          description: menu.description,
          category: menu.category,
          priceIdr: 17000,
          isAvailable: true,
          expectedVersion: menu.version,
        ),
        mutationId: 'price',
      );
      await signIn(s, 'pelanggan');
      expect(
        (await SimulationCatalogRepository(
          s,
        ).getCatalog()).menuById(menu.id)!.price,
        17000,
      );
      final c = review();
      await expectLater(
        SimulationOrderRepository(s).createOrder(
          draft: c.draft,
          submissionId: 'old-price',
          confirmation: c,
        ),
        throwsA(isA<CustomerOrderPriceChangedFailure>()),
      );
      expect(s.table('orders').length, 8);
    },
  );
  test(
    'promotion preserves personal history and pending lookup after restart',
    () async {
      var s = SimulationStore.memory();
      await signIn(s, 'pelanggan');
      final journal = SimulationOrderSubmissionJournal(
        SimulationKeyValueStorage(s),
      );
      await journal.save(
        PendingOrderSubmission(
          customerId: 'customer-1',
          submissionId: 'lost-checkout',
        ),
      );
      final c = review();
      s.scenario = SimulationScenario.unknown;
      await expectLater(
        SimulationOrderRepository(s).createOrder(
          draft: c.draft,
          submissionId: 'lost-checkout',
          confirmation: c,
        ),
        throwsA(isA<TimeoutException>()),
      );
      s.scenario = SimulationScenario.normal;
      final app = await SimulationApplicationRepository(s).submit(
        PendingCanteenApplication(
          customerId: 'customer-1',
          submissionId: 'new-stall',
          draft: CanteenApplicationDraft(
            name: 'Kedai Alya',
            description: 'Menu kampus',
            location: 'Blok E',
            phone: '081234567891',
          ),
        ),
      );
      await signIn(s, 'admin');
      await SimulationAdminRepository(s).reviewApplication(
        AdminApplicationReview(
          applicationId: app.id,
          expectedVersion: app.version,
          status: CanteenApplicationStatus.approved,
        ),
        mutationId: 'approve-alya',
      );
      await signIn(s, 'pelanggan');
      s = SimulationStore.memory(snapshot: s.exportSimulationData());
      expect(
        (await SimulationAuthRepository(s).restoreSession())!.role,
        UserRole.owner,
      );
      expect(
        (await SimulationTrackingRepository(
          s,
        ).listMyOrders(history: false)).items,
        isNotEmpty,
      );
      final pending = await SimulationOrderSubmissionJournal(
        SimulationKeyValueStorage(s),
      ).read('customer-1');
      expect(pending!.submissionId, 'lost-checkout');
      final result = await SimulationOrderRepository(
        s,
      ).lookupSubmission(submissionId: pending.submissionId);
      expect(result.status, OrderSubmissionStatus.confirmed);
      expect(s.table('orders').length, 9);
      expect(
        (await SimulationOwnerRepository(s).getMyStall())!.name,
        'Kedai Alya',
      );
    },
  );
  test('cancellation loses CAS after owner acceptance', () async {
    final s = SimulationStore.memory();
    await signIn(s, 'pemilik');
    await SimulationOwnerRepository(s).transitionOrder(
      OwnerOrderTransition(
        orderId: 'order-seed-0',
        status: OrderStatus.processing,
        expectedVersion: 1,
      ),
      mutationId: 'accept',
    );
    await signIn(s, 'pelanggan');
    await expectLater(
      SimulationTrackingRepository(s).cancelMyOrder(
        CustomerOrderCancellation(orderId: 'order-seed-0', expectedVersion: 1),
        mutationId: 'cancel',
      ),
      throwsA(isA<CustomerOrderCancellationFailure>()),
    );
    expect(
      (await SimulationTrackingRepository(
        s,
      ).getMyOrder(orderId: 'order-seed-0'))!.status,
      OrderStatus.processing,
    );
  });
  test(
    'owner cannot access another stall and customer cannot call admin',
    () async {
      final s = SimulationStore.memory();
      await signIn(s, 'pemilik2');
      await expectLater(
        SimulationOwnerRepository(s).listOrders(stallId: 'stall-1'),
        throwsA(isA<OwnerFailure>()),
      );
      await signIn(s, 'pelanggan');
      await expectLater(
        SimulationAdminRepository(s).getSummary(),
        throwsA(isA<AuthFailure>()),
      );
    },
  );
  test(
    'admin deactivation blocks subsequent login; admin cannot disable itself',
    () async {
      final s = SimulationStore.memory();
      await signIn(s, 'admin');
      final repo = SimulationAdminRepository(s);
      final user = (await repo.getUser(userId: 'customer-2'))!;
      await repo.setUserAccess(
        AdminUserAccessChange(
          userId: user.user.id,
          expectedVersion: user.version,
          isActive: false,
          reason: 'Skenario uji',
        ),
        mutationId: 'disable',
      );
      await expectLater(
        signIn(s, 'pelanggan2'),
        throwsA(isA<AuthAccountDisabledFailure>()),
      );
      await expectLater(
        repo.setUserAccess(
          AdminUserAccessChange(
            userId: 'admin-1',
            expectedVersion: 1,
            isActive: false,
            reason: 'Uji',
          ),
          mutationId: 'self',
        ),
        throwsA(anything),
      );
    },
  );
  test(
    'preferences unknown receipt retains original snapshot after a later update',
    () async {
      final s = SimulationStore.memory();
      await signIn(s, 'pelanggan');
      final repo = SimulationPreferencesRepository(s);
      final first = FoodPreferencesUpdate(
        preferences: FoodPreferences(
          maxBudgetIdr: 15000,
          vegetarian: true,
          avoidIngredients: ['kacang'],
        ),
        expectedVersion: null,
      );
      s.scenario = SimulationScenario.unknown;
      await expectLater(
        repo.saveMyPreferences(first, mutationId: 'prefs-1'),
        throwsA(isA<TimeoutException>()),
      );
      s.scenario = SimulationScenario.normal;
      await repo.saveMyPreferences(
        FoodPreferencesUpdate(
          preferences: FoodPreferences(
            maxBudgetIdr: 25000,
            vegetarian: false,
            avoidIngredients: [],
          ),
          expectedVersion: 1,
        ),
        mutationId: 'prefs-2',
      );
      final receipt = await repo.lookupSave(mutationId: 'prefs-1');
      expect(receipt.snapshot!.preferences.maxBudgetIdr, 15000);
      expect((await repo.getMyPreferences())!.preferences.maxBudgetIdr, 25000);
    },
  );
  test(
    'journal rejects overwrite and mismatched clear; reset restores only simulation',
    () async {
      final s = SimulationStore.memory();
      final j = SimulationOrderSubmissionJournal(SimulationKeyValueStorage(s));
      await j.save(
        PendingOrderSubmission(customerId: 'a', submissionId: 'one'),
      );
      await expectLater(
        j.save(PendingOrderSubmission(customerId: 'a', submissionId: 'two')),
        throwsStateError,
      );
      expect(await j.clear(customerId: 'a', submissionId: 'other'), isFalse);
      expect((await j.read('a'))!.submissionId, 'one');
      await s.reset();
      expect(await j.read('a'), isNull);
      expect(s.table('orders').length, 8);
    },
  );
}
