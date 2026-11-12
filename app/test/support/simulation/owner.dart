part of 'simulation.dart';

class SimulationOwnerRepository implements OwnerRepository {
  SimulationOwnerRepository(this.store);
  final SimulationStore store;
  @override
  bool get isMutationConfigured => true;
  OwnerStall ownedStall(String id) {
    final value = store.table('stalls')[id];
    if (value == null) {
      throw const OwnerNoStallFailure();
    }
    final stall = unpackOwnerStall(asJson(value));
    if (stall.ownerId != store.require(UserRole.owner).id) {
      throw const OwnerForbiddenFailure();
    }
    return stall;
  }

  @override
  Future<OwnerStall?> getMyStall() async {
    final actor = await store.begin(UserRole.owner);
    store.readGuard();
    final matches = store
        .table('stalls')
        .values
        .map((e) => unpackOwnerStall(asJson(e)))
        .where((s) => s.ownerId == actor.$1);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<OwnerMenuPage> listMenus({
    required String stallId,
    required String search,
    bool? available,
    String? cursor,
    int limit = 30,
  }) async {
    await store.begin(UserRole.owner);
    store.readGuard();
    ownedStall(stallId);
    final items = store.empty
        ? <OwnerMenu>[]
        : store
              .table('menus')
              .values
              .map((e) => unpackOwnerMenu(asJson(e)))
              .where(
                (m) =>
                    m.stallId == stallId &&
                    m.name.toLowerCase().contains(search.toLowerCase()) &&
                    (available == null || m.isAvailable == available),
              )
              .toList();
    items.sort((a, b) => a.id.compareTo(b.id));
    final page = store.page(
      items,
      'menus:$stallId:$search:$available',
      cursor,
      limit,
    );
    return OwnerMenuPage(items: page.$1, nextCursor: page.$2);
  }

  Json mutationResult(
    PendingOwnerMutation request,
    Json? record,
    String id,
    int version, {
    OrderStatus? status,
    OrderPaymentStatus? payment,
  }) => {
    'record': record,
    'receipt': packOwnerMutationLookup(
      OwnerMutationLookup(
        request: request,
        outcome: OwnerMutationOutcome.applied,
        resultId: id,
        resultVersion: version,
        orderStatus: status,
        paymentStatus: payment,
      ),
    ),
  };
  @override
  Future<OwnerMenu> saveMenu(
    OwnerMenuInput input, {
    required String mutationId,
  }) async {
    final actor = await store.begin(UserRole.owner);
    final pending = PendingOwnerMutation(
      ownerId: actor.$1,
      mutationId: mutationId,
      stallId: input.stallId,
      kind: OwnerMutationKind.saveMenu,
      targetId: input.id,
      expectedVersion: input.expectedVersion,
    );
    final payload = {
      'request': packPendingOwnerMutation(pending),
      'name': input.name,
      'description': input.description,
      'category': input.category.name,
      'priceIdr': input.priceIdr,
      'isAvailable': input.isAvailable,
      'imageUrl': input.imageUrl,
    };
    final result = await store.mutate(
      actor: actor,
      role: UserRole.owner,
      operation: 'owner',
      id: mutationId,
      payload: payload,
      conflict: const OwnerConflictFailure(),
      apply: () {
        ownedStall(input.stallId);
        final value = store.table('menus')[input.id];
        final before = value == null ? null : unpackOwnerMenu(asJson(value));
        if (input.id != null &&
            (before == null ||
                before.stallId != input.stallId ||
                before.version != input.expectedVersion)) {
          throw const OwnerConflictFailure();
        }
        final menu = OwnerMenu(
          id: input.id ?? store.nextId('menu'),
          stallId: input.stallId,
          name: input.name,
          description: input.description,
          category: input.category,
          priceIdr: input.priceIdr,
          isAvailable: input.isAvailable,
          version: (input.expectedVersion ?? 0) + 1,
          imageUrl: input.imageUrl,
        );
        store.table('menus')[menu.id] = packOwnerMenu(menu);
        return mutationResult(
          pending,
          packOwnerMenu(menu),
          menu.id,
          menu.version,
        );
      },
    );
    return unpackOwnerMenu(asJson(result['record']));
  }

  @override
  Future<void> deleteMenu({
    required String id,
    required int expectedVersion,
    required String mutationId,
  }) async {
    final actor = await store.begin(UserRole.owner);
    // Resolve the target from the original request for replays after deletion.
    final oldReceipt = store.receipt('owner', mutationId);
    final oldReceiptData = oldReceipt?['receipt'];
    final oldRequest = oldReceiptData == null
        ? null
        : unpackOwnerMutationLookup(asJson(oldReceiptData)).request;
    final value = store.table('menus')[id];
    final before = value == null ? null : unpackOwnerMenu(asJson(value));
    final stallId = before?.stallId ?? oldRequest?.stallId;
    if (stallId == null) {
      throw const OwnerRejectedFailure();
    }
    final pending = PendingOwnerMutation(
      ownerId: actor.$1,
      mutationId: mutationId,
      stallId: stallId,
      kind: OwnerMutationKind.deleteMenu,
      targetId: id,
      expectedVersion: expectedVersion,
    );
    await store.mutate(
      actor: actor,
      role: UserRole.owner,
      operation: 'owner',
      id: mutationId,
      payload: {'request': packPendingOwnerMutation(pending)},
      conflict: const OwnerConflictFailure(),
      apply: () {
        ownedStall(stallId);
        final current = store.table('menus')[id];
        if (current == null ||
            unpackOwnerMenu(asJson(current)).version != expectedVersion) {
          throw const OwnerConflictFailure();
        }
        store.table('menus').remove(id);
        return mutationResult(pending, null, id, expectedVersion + 1);
      },
    );
  }

  @override
  Future<OwnerStall> saveStall(
    OwnerStallInput input, {
    required String mutationId,
  }) async {
    final actor = await store.begin(UserRole.owner);
    final pending = PendingOwnerMutation(
      ownerId: actor.$1,
      mutationId: mutationId,
      stallId: input.id,
      kind: OwnerMutationKind.saveStall,
      targetId: input.id,
      expectedVersion: input.expectedVersion,
    );
    final result = await store.mutate(
      actor: actor,
      role: UserRole.owner,
      operation: 'owner',
      id: mutationId,
      payload: {
        'request': packPendingOwnerMutation(pending),
        'name': input.name,
        'block': input.block,
        'description': input.description,
        'isOpen': input.isOpen,
        'prepTimeMin': input.prepTimeMin,
        'imageUrl': input.imageUrl,
      },
      conflict: const OwnerConflictFailure(),
      apply: () {
        final before = ownedStall(input.id);
        if (before.version != input.expectedVersion) {
          throw const OwnerConflictFailure();
        }
        final stall = OwnerStall(
          id: input.id,
          ownerId: actor.$1,
          name: input.name,
          block: input.block,
          description: input.description,
          isOpen: input.isOpen,
          prepTimeMin: input.prepTimeMin,
          version: before.version + 1,
          imageUrl: input.imageUrl,
        );
        store.table('stalls')[stall.id] = packOwnerStall(stall);
        return mutationResult(
          pending,
          packOwnerStall(stall),
          stall.id,
          stall.version,
        );
      },
    );
    return unpackOwnerStall(asJson(result['record']));
  }

  @override
  Future<OrderRecordPage> listOrders({
    required String stallId,
    OrderStatus? status,
    String? cursor,
    int limit = 30,
  }) async {
    await store.begin(UserRole.owner);
    store.readGuard();
    ownedStall(stallId);
    final items = store.empty
        ? <OrderRecord>[]
        : store
              .table('orders')
              .values
              .map((e) => unpackOrderRecord(asJson(e)))
              .where(
                (o) =>
                    o.stallId == stallId &&
                    (status == null || o.status == status),
              )
              .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final page = store.page(
      items,
      'owner-orders:$stallId:$status',
      cursor,
      limit,
    );
    return OrderRecordPage(items: page.$1, nextCursor: page.$2);
  }

  @override
  Future<OrderRecord?> getMyOrder({
    required String stallId,
    required String orderId,
  }) async {
    await store.begin(UserRole.owner);
    store.readGuard();
    ownedStall(stallId);
    final value = store.table('orders')[orderId];
    if (value == null || store.empty) {
      return null;
    }
    final order = unpackOrderRecord(asJson(value));
    return order.stallId == stallId ? order : null;
  }

  @override
  Future<OrderRecord> transitionOrder(
    OwnerOrderTransition input, {
    required String mutationId,
  }) async {
    final actor = await store.begin(UserRole.owner);
    final value = store.table('orders')[input.orderId];
    if (value == null) {
      throw const OwnerRejectedFailure();
    }
    final order = unpackOrderRecord(asJson(value));
    final pending = PendingOwnerMutation(
      ownerId: actor.$1,
      mutationId: mutationId,
      stallId: order.stallId,
      kind: OwnerMutationKind.transitionOrder,
      targetId: input.orderId,
      expectedVersion: input.expectedVersion,
      orderStatus: input.status,
    );
    final result = await store.mutate(
      actor: actor,
      role: UserRole.owner,
      operation: 'owner',
      id: mutationId,
      payload: {
        'request': packPendingOwnerMutation(pending),
        'reason': input.reason,
        'cashReceived': input.cashReceived,
        'foodHandedOver': input.foodHandedOver,
      },
      conflict: const OwnerConflictFailure(),
      apply: () {
        ownedStall(order.stallId);
        final before = unpackOrderRecord(
          asJson(store.table('orders')[input.orderId]),
        );
        if (!input.canApplyTo(before)) {
          throw const OwnerConflictFailure();
        }
        final after = unpackOrderRecord({
          ...packOrderRecord(before),
          'status': input.status.name,
          'paymentStatus': input.status == OrderStatus.completed
              ? 'paid'
              : input.status == OrderStatus.rejected
              ? 'notCharged'
              : 'unpaid',
          'rejectionReason': input.status == OrderStatus.rejected
              ? input.reason
              : null,
          'version': before.version + 1,
          'updatedAt': simulationUpdateTime(before.updatedAt).toIso8601String(),
        });
        store.table('orders')[after.id] = packOrderRecord(after);
        return mutationResult(
          pending,
          packOrderRecord(after),
          after.id,
          after.version,
          status: after.status,
          payment: after.paymentStatus,
        );
      },
    );
    return unpackOrderRecord(asJson(result['record']));
  }

  @override
  Future<OwnerMutationLookup> lookupMutation({
    required String mutationId,
  }) async {
    final result = await store.lookup('owner', mutationId, UserRole.owner);
    final receipt = result?['receipt'];
    if (receipt != null) {
      return unpackOwnerMutationLookup(asJson(receipt));
    }
    final request = await SimulationOwnerMutationJournal(
      SimulationKeyValueStorage(store),
    ).read(store.require().id);
    if (request == null || request.mutationId != mutationId) {
      throw const FormatException('Penanda tidak ditemukan.');
    }
    return OwnerMutationLookup(
      request: request,
      outcome: result?['sealed'] == true
          ? OwnerMutationOutcome.notApplied
          : OwnerMutationOutcome.pending,
    );
  }
}
