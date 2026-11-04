part of 'simulation.dart';

class SimulationOrderRepository implements CustomerOrderRepository {
  SimulationOrderRepository(this.store);
  final SimulationStore store;
  @override
  bool get isCheckoutConfigured => true;
  @override
  Future<String> createOrder({
    required OrderDraft draft,
    required String submissionId,
    required CustomerOrderPriceConfirmation confirmation,
  }) async {
    final actor = await store.begin(UserRole.customer);
    if (!confirmation.matchesDraft(draft)) {
      throw const CustomerOrderPreSendFailure();
    }
    final payload = {
      'stall': draft.stallId,
      'note': draft.orderNote,
      'items': [
        for (final i in draft.items)
          {
            'id': i.menuId,
            'quantity': i.quantity,
            'note': i.note,
            'price': confirmation.unitPricesIdr[i.menuId],
          },
      ],
    };
    final result = await store.mutate(
      actor: actor,
      operation: 'checkout',
      id: submissionId,
      payload: payload,
      conflict: const CustomerOrderRejectedFailure(),
      apply: () {
        final catalog = simulationCatalog(store);
        if (draft.items.any(
          (i) =>
              !catalog.canOrder(i.menuId) ||
              catalog.menuById(i.menuId)!.stallId != draft.stallId,
        )) {
          throw const CustomerOrderRejectedFailure();
        }
        if (draft.items.any(
          (i) =>
              catalog.menuById(i.menuId)!.price !=
              confirmation.unitPricesIdr[i.menuId],
        )) {
          throw const CustomerOrderPriceChangedFailure();
        }
        final user = store.require(UserRole.customer);
        final id = store.nextId('order');
        final now = DateTime.now().toUtc();
        final order = OrderRecord(
          id: id,
          orderNumber: 'SIM-${id.split('-').last}',
          customerId: user.id,
          customerName: user.name,
          stallId: draft.stallId,
          stallName: catalog.stallById(draft.stallId)!.name,
          items: [
            for (final i in draft.items)
              OrderLine(
                menuId: i.menuId,
                name: catalog.menuById(i.menuId)!.name,
                quantity: i.quantity,
                unitPriceIdr: catalog.menuById(i.menuId)!.price,
                note: i.note,
              ),
          ],
          status: OrderStatus.waiting,
          paymentStatus: OrderPaymentStatus.unpaid,
          totalPriceIdr: confirmation.totalPriceIdr,
          note: draft.orderNote,
          createdAt: now,
          updatedAt: now,
          version: 1,
        );
        store.table('orders')[id] = packOrderRecord(order);
        return {'orderId': id};
      },
    );
    return result['orderId'] as String;
  }

  @override
  Future<OrderSubmissionLookup> lookupSubmission({
    required String submissionId,
  }) async {
    final result = await store.lookup(
      'checkout',
      submissionId,
      UserRole.customer,
    );
    return OrderSubmissionLookup(
      customerId: store.require().id,
      submissionId: submissionId,
      status: result == null
          ? OrderSubmissionStatus.pending
          : result['sealed'] == true
          ? OrderSubmissionStatus.notCreated
          : OrderSubmissionStatus.confirmed,
      orderId: result?['orderId'] as String?,
    );
  }
}

class SimulationTrackingRepository implements CustomerOrderTrackingRepository {
  SimulationTrackingRepository(this.store);
  final SimulationStore store;
  @override
  bool get isCancellationConfigured => true;
  @override
  Future<OrderRecord?> getMyOrder({required String orderId}) async {
    final actor = await store.begin(UserRole.customer);
    store.readGuard();
    final value = store.table('orders')[orderId];
    if (value == null || store.empty) {
      return null;
    }
    final order = unpackOrderRecord(asJson(value));
    return order.customerId == actor.$1 ? order : null;
  }

  @override
  Future<OrderRecordPage> listMyOrders({
    required bool history,
    String? cursor,
    int limit = 30,
  }) async {
    final actor = await store.begin(UserRole.customer);
    store.readGuard();
    final items =
        store.empty
              ? <OrderRecord>[]
              : store
                    .table('orders')
                    .values
                    .map((e) => unpackOrderRecord(asJson(e)))
                    .where(
                      (o) =>
                          o.customerId == actor.$1 &&
                          o.status.isTerminal == history,
                    )
                    .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final page = store.page(
      items,
      'customer:${actor.$1}:$history',
      cursor,
      limit,
    );
    return OrderRecordPage(items: page.$1, nextCursor: page.$2);
  }

  @override
  Future<OrderRecord> cancelMyOrder(
    CustomerOrderCancellation cancellation, {
    required String mutationId,
  }) async {
    final actor = await store.begin(UserRole.customer);
    final result = await store.mutate(
      actor: actor,
      operation: 'cancellation',
      id: mutationId,
      payload: packCustomerOrderCancellation(cancellation),
      conflict: const CustomerOrderCancellationConflictFailure(),
      apply: () {
        final value = store.table('orders')[cancellation.orderId];
        if (value == null) {
          throw const CustomerOrderCancellationRejectedFailure();
        }
        final before = unpackOrderRecord(asJson(value));
        if (before.customerId != actor.$1) {
          throw const CustomerOrderCancellationForbiddenFailure();
        }
        if (!cancellation.canApplyTo(before, customerId: actor.$1)) {
          throw const CustomerOrderCancellationConflictFailure();
        }
        final after = unpackOrderRecord({
          ...packOrderRecord(before),
          'status': 'cancelled',
          'paymentStatus': 'notCharged',
          'version': before.version + 1,
          'updatedAt': simulationUpdateTime(before.updatedAt).toIso8601String(),
        });
        final pending = PendingOrderCancellation(
          customerId: actor.$1,
          mutationId: mutationId,
          stallId: before.stallId,
          orderNumber: before.orderNumber,
          input: cancellation,
        );
        store.table('orders')[after.id] = packOrderRecord(after);
        return {
          'record': packOrderRecord(after),
          'receipt': packOrderCancellationLookup(
            OrderCancellationLookup(
              request: pending,
              outcome: OrderCancellationOutcome.applied,
              resultVersion: after.version,
              status: after.status,
              paymentStatus: after.paymentStatus,
            ),
          ),
        };
      },
    );
    return unpackOrderRecord(asJson(result['record']));
  }

  @override
  Future<OrderCancellationLookup> lookupCancellation({
    required String mutationId,
  }) async {
    final result = await store.lookup(
      'cancellation',
      mutationId,
      UserRole.customer,
    );
    if (result != null && result['receipt'] != null) {
      return unpackOrderCancellationLookup(asJson(result['receipt']));
    }
    final pending = await SimulationOrderCancellationJournal(
      SimulationKeyValueStorage(store),
    ).read(store.require().id);
    if (pending == null || pending.mutationId != mutationId) {
      throw const FormatException('Penanda tidak ditemukan.');
    }
    return OrderCancellationLookup(
      request: pending,
      outcome: result?['sealed'] == true
          ? OrderCancellationOutcome.notApplied
          : OrderCancellationOutcome.pending,
    );
  }
}
