part of 'simulation.dart';

class SimulationAdminMutationJournal implements AdminMutationJournal {
  SimulationAdminMutationJournal(this._storage);
  final SimulationKeyValueStorage _storage;
  Future<void> _queue = Future<void>.value();
  String _key(String id) =>
      'kantin_cerdas.admin.mutation.v1.${base64Url.encode(utf8.encode(id))}';
  @override
  Future<PendingAdminMutation?> read(String adminId) =>
      _serial(() => _read(adminId));
  Future<PendingAdminMutation?> _read(String adminId) async {
    final raw = await _storage.read(key: _key(adminId));
    if (raw == null) {
      return null;
    }
    final Object? data = jsonDecode(raw);
    if (data is! Map<String, dynamic> ||
        data['version'] != 1 ||
        data['adminId'] != adminId ||
        data['mutationId'] is! String ||
        data['kind'] is! String ||
        data['targetId'] is! String ||
        data['expectedVersion'] is! int ||
        data['reason'] is! String ||
        (data['decision'] != null && data['decision'] is! String) ||
        (data['applicantId'] != null && data['applicantId'] is! String) ||
        (data['isActive'] != null && data['isActive'] is! bool) ||
        (data['targetRole'] != null && data['targetRole'] is! String)) {
      throw const FormatException('Penanda admin tidak valid.');
    }
    return PendingAdminMutation(
      adminId: adminId,
      mutationId: data['mutationId'] as String,
      kind: AdminMutationKind.values.byName(data['kind'] as String),
      targetId: data['targetId'] as String,
      expectedVersion: data['expectedVersion'] as int,
      reason: data['reason'] as String,
      applicantId: data['applicantId'] as String?,
      isActive: data['isActive'] as bool?,
      decision: data['decision'] == null
          ? null
          : CanteenApplicationStatus.values.byName(data['decision'] as String),
      targetRole: data['targetRole'] == null
          ? null
          : UserRole.values.byName(data['targetRole'] as String),
    );
  }

  @override
  Future<void> save(PendingAdminMutation pending) => _serial(() async {
    if (await _read(pending.adminId) != null) {
      throw StateError('Masih ada perubahan admin tertunda.');
    }
    await _storage.write(
      key: _key(pending.adminId),
      value: jsonEncode({
        'version': 1,
        'adminId': pending.adminId,
        'mutationId': pending.mutationId,
        'kind': pending.kind.name,
        'targetId': pending.targetId,
        'expectedVersion': pending.expectedVersion,
        'reason': pending.reason,
        'applicantId': pending.applicantId,
        'isActive': pending.isActive,
        'decision': pending.decision?.name,
        'targetRole': pending.targetRole?.name,
      }),
    );
  });
  @override
  Future<bool> clear({required String adminId, required String mutationId}) =>
      _serial(() async {
        final current = await _read(adminId);
        if (current == null) {
          return true;
        }
        if (current.mutationId != mutationId) {
          return false;
        }
        await _storage.delete(key: _key(adminId));
        return true;
      });
  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _queue.then<T>((_) => action());
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}

class SimulationCanteenApplicationJournal implements CanteenApplicationJournal {
  SimulationCanteenApplicationJournal(this._storage);
  final SimulationKeyValueStorage _storage;
  Future<void> _queue = Future<void>.value();

  String _key(String id) =>
      'kantin_cerdas.application.pending.v1.${base64Url.encode(utf8.encode(id))}';
  @override
  Future<PendingCanteenApplication?> read(String customerId) =>
      _serial(() => _read(customerId));

  Future<PendingCanteenApplication?> _read(String customerId) async {
    final raw = await _storage.read(key: _key(customerId));
    if (raw == null) {
      return null;
    }
    final Object? data = jsonDecode(raw);
    if (data is! Map<String, dynamic> ||
        data['version'] != 1 ||
        data['customerId'] != customerId ||
        data['submissionId'] is! String ||
        data['name'] is! String ||
        data['description'] is! String ||
        data['location'] is! String ||
        data['phone'] is! String ||
        (data['previousId'] != null && data['previousId'] is! String) ||
        (data['previousVersion'] != null && data['previousVersion'] is! int)) {
      throw const FormatException('Penanda pengajuan lokal tidak valid.');
    }
    return PendingCanteenApplication(
      customerId: customerId,
      submissionId: data['submissionId'] as String,
      previousId: data['previousId'] as String?,
      previousVersion: data['previousVersion'] as int?,
      draft: CanteenApplicationDraft(
        name: data['name'] as String,
        description: data['description'] as String,
        location: data['location'] as String,
        phone: data['phone'] as String,
      ),
    );
  }

  @override
  Future<void> save(PendingCanteenApplication submission) => _serial(() async {
    if (await _read(submission.customerId) != null) {
      throw StateError('Masih ada pengajuan yang belum diselesaikan.');
    }
    await _storage.write(
      key: _key(submission.customerId),
      value: jsonEncode({
        'version': 1,
        'customerId': submission.customerId,
        'submissionId': submission.submissionId,
        'previousId': submission.previousId,
        'previousVersion': submission.previousVersion,
        'name': submission.draft.name,
        'description': submission.draft.description,
        'location': submission.draft.location,
        'phone': submission.draft.phone,
      }),
    );
  });

  @override
  Future<bool> clear({
    required String customerId,
    required String submissionId,
  }) => _serial(() async {
    final current = await _read(customerId);
    if (current == null) {
      return true;
    }
    if (current.submissionId != submissionId) {
      return false;
    }
    await _storage.delete(key: _key(customerId));
    return true;
  });

  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _queue.then<T>((_) => action());
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}

class SimulationFoodPreferencesJournal implements FoodPreferencesJournal {
  SimulationFoodPreferencesJournal(this._storage);
  final SimulationKeyValueStorage _storage;
  Future<void> _queue = Future<void>.value();
  String _key(String id) =>
      'kantin_cerdas.preferences.pending.v1.${base64Url.encode(utf8.encode(id))}';
  @override
  Future<PendingFoodPreferences?> read(String customerId) =>
      _serial(() => _read(customerId));
  Future<PendingFoodPreferences?> _read(String customerId) async {
    final raw = await _storage.read(key: _key(customerId));
    if (raw == null) {
      return null;
    }
    final Object? data = jsonDecode(raw);
    if (data is! Map<String, dynamic> ||
        data['schema'] != 1 ||
        data['customerId'] != customerId ||
        data['mutationId'] is! String ||
        !data.containsKey('expectedVersion') ||
        (data['expectedVersion'] != null && data['expectedVersion'] is! int) ||
        !data.containsKey('maxBudgetIdr') ||
        (data['maxBudgetIdr'] != null && data['maxBudgetIdr'] is! int) ||
        data['vegetarian'] is! bool ||
        data['avoidIngredients'] is! List ||
        (data['avoidIngredients'] as List).any((value) => value is! String)) {
      throw const FormatException('Penanda preferensi tidak valid.');
    }
    return PendingFoodPreferences(
      customerId: customerId,
      mutationId: data['mutationId'] as String,
      update: FoodPreferencesUpdate(
        expectedVersion: data['expectedVersion'] as int?,
        preferences: FoodPreferences(
          maxBudgetIdr: data['maxBudgetIdr'] as int?,
          vegetarian: data['vegetarian'] as bool,
          avoidIngredients: (data['avoidIngredients'] as List).cast<String>(),
        ),
      ),
    );
  }

  @override
  Future<void> save(PendingFoodPreferences pending) => _serial(() async {
    if (await _read(pending.customerId) != null) {
      throw StateError('Masih ada penyimpanan preferensi tertunda.');
    }
    final value = pending.update.preferences;
    await _storage.write(
      key: _key(pending.customerId),
      value: jsonEncode({
        'schema': 1,
        'customerId': pending.customerId,
        'mutationId': pending.mutationId,
        'expectedVersion': pending.update.expectedVersion,
        'maxBudgetIdr': value.maxBudgetIdr,
        'vegetarian': value.vegetarian,
        'avoidIngredients': value.avoidIngredients,
      }),
    );
  });
  @override
  Future<bool> clear({
    required String customerId,
    required String mutationId,
  }) => _serial(() async {
    final pending = await _read(customerId);
    if (pending == null) {
      return true;
    }
    if (pending.mutationId != mutationId) {
      return false;
    }
    await _storage.delete(key: _key(customerId));
    return true;
  });
  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _queue.then<T>((_) => action());
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}

class SimulationOrderCancellationJournal implements OrderCancellationJournal {
  SimulationOrderCancellationJournal(this._storage);
  final SimulationKeyValueStorage _storage;
  Future<void> _queue = Future<void>.value();
  String _key(String id) =>
      'kantin_cerdas.order.cancellation.v1.${base64Url.encode(utf8.encode(id))}';
  @override
  Future<PendingOrderCancellation?> read(String customerId) =>
      _serial(() => _read(customerId));
  Future<PendingOrderCancellation?> _read(String customerId) async {
    final raw = await _storage.read(key: _key(customerId));
    if (raw == null) {
      return null;
    }
    final Object? data = jsonDecode(raw);
    if (data is! Map<String, dynamic> ||
        data['schema'] != 1 ||
        data['customerId'] != customerId ||
        data['mutationId'] is! String ||
        data['stallId'] is! String ||
        data['orderNumber'] is! String ||
        data['orderId'] is! String ||
        data['expectedVersion'] is! int) {
      throw const FormatException('Penanda pembatalan tidak valid.');
    }
    return PendingOrderCancellation(
      customerId: customerId,
      mutationId: data['mutationId'] as String,
      stallId: data['stallId'] as String,
      orderNumber: data['orderNumber'] as String,
      input: CustomerOrderCancellation(
        orderId: data['orderId'] as String,
        expectedVersion: data['expectedVersion'] as int,
      ),
    );
  }

  @override
  Future<void> save(PendingOrderCancellation pending) => _serial(() async {
    if (await _read(pending.customerId) != null) {
      throw StateError('Masih ada pembatalan tertunda.');
    }
    await _storage.write(
      key: _key(pending.customerId),
      value: jsonEncode({
        'schema': 1,
        'customerId': pending.customerId,
        'mutationId': pending.mutationId,
        'stallId': pending.stallId,
        'orderNumber': pending.orderNumber,
        'orderId': pending.orderId,
        'expectedVersion': pending.expectedVersion,
      }),
    );
  });
  @override
  Future<bool> clear({
    required String customerId,
    required String mutationId,
  }) => _serial(() async {
    final pending = await _read(customerId);
    if (pending == null) {
      return true;
    }
    if (pending.mutationId != mutationId) {
      return false;
    }
    await _storage.delete(key: _key(customerId));
    return true;
  });
  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _queue.then<T>((_) => action());
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}

class SimulationOrderSubmissionJournal implements OrderSubmissionJournal {
  SimulationOrderSubmissionJournal(this._storage);
  final SimulationKeyValueStorage _storage;
  Future<void> _queue = Future<void>.value();

  String _key(String customerId) =>
      'kantin_cerdas.order.pending.v1.${base64Url.encode(utf8.encode(customerId))}';
  @override
  Future<PendingOrderSubmission?> read(String customerId) =>
      _serial(() => _read(customerId));

  Future<PendingOrderSubmission?> _read(String customerId) async {
    final raw = await _storage.read(key: _key(customerId));
    if (raw == null) {
      return null;
    }
    final Object? data = jsonDecode(raw);
    if (data is! Map<String, dynamic> ||
        data['version'] != 1 ||
        data['customerId'] != customerId ||
        data['submissionId'] is! String ||
        (data['submissionId'] as String).trim().isEmpty) {
      throw const FormatException('Penanda pengiriman lokal tidak valid.');
    }
    return PendingOrderSubmission(
      customerId: customerId,
      submissionId: data['submissionId'] as String,
    );
  }

  @override
  Future<void> save(PendingOrderSubmission submission) => _serial(() async {
    final current = await _read(submission.customerId);
    if (current != null && current.submissionId != submission.submissionId) {
      throw StateError('Masih ada pengiriman yang belum diselesaikan.');
    }
    await _storage.write(
      key: _key(submission.customerId),
      value: jsonEncode({
        'version': 1,
        'customerId': submission.customerId,
        'submissionId': submission.submissionId,
      }),
    );
  });
  @override
  Future<bool> clear({
    required String customerId,
    required String submissionId,
  }) => _serial(() async {
    final current = await _read(customerId);
    if (current == null) {
      return true;
    }
    if (current.submissionId != submissionId) {
      return false;
    }
    await _storage.delete(key: _key(customerId));
    return true;
  });
  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _queue.then<T>((_) => action());
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}

class SimulationOwnerMutationJournal implements OwnerMutationJournal {
  SimulationOwnerMutationJournal(this._storage);
  final SimulationKeyValueStorage _storage;
  Future<void> _queue = Future<void>.value();
  String _key(String id) =>
      'kantin_cerdas.owner.mutation.v1.${base64Url.encode(utf8.encode(id))}';
  @override
  Future<PendingOwnerMutation?> read(String ownerId) =>
      _serial(() => _read(ownerId));

  Future<PendingOwnerMutation?> _read(String ownerId) async {
    final raw = await _storage.read(key: _key(ownerId));
    if (raw == null) {
      return null;
    }
    final Object? data = jsonDecode(raw);
    if (data is! Map<String, dynamic> ||
        data['version'] != 1 ||
        data['ownerId'] != ownerId ||
        data['mutationId'] is! String ||
        data['stallId'] is! String ||
        data['kind'] is! String ||
        (data['targetId'] != null && data['targetId'] is! String) ||
        (data['expectedVersion'] != null && data['expectedVersion'] is! int) ||
        (data['orderStatus'] != null && data['orderStatus'] is! String)) {
      throw const FormatException('Penanda perubahan owner tidak valid.');
    }
    return PendingOwnerMutation(
      ownerId: ownerId,
      mutationId: data['mutationId'] as String,
      stallId: data['stallId'] as String,
      kind: OwnerMutationKind.values.byName(data['kind'] as String),
      targetId: data['targetId'] as String?,
      expectedVersion: data['expectedVersion'] as int?,
      orderStatus: data['orderStatus'] == null
          ? null
          : OrderStatus.values.byName(data['orderStatus'] as String),
    );
  }

  @override
  Future<void> save(PendingOwnerMutation pending) => _serial(() async {
    if (await _read(pending.ownerId) != null) {
      throw StateError('Masih ada perubahan tertunda.');
    }
    await _storage.write(
      key: _key(pending.ownerId),
      value: jsonEncode({
        'version': 1,
        'ownerId': pending.ownerId,
        'mutationId': pending.mutationId,
        'stallId': pending.stallId,
        'kind': pending.kind.name,
        'targetId': pending.targetId,
        'expectedVersion': pending.expectedVersion,
        'orderStatus': pending.orderStatus?.name,
      }),
    );
  });
  @override
  Future<bool> clear({required String ownerId, required String mutationId}) =>
      _serial(() async {
        final current = await _read(ownerId);
        if (current == null) {
          return true;
        }
        if (current.mutationId != mutationId) {
          return false;
        }
        await _storage.delete(key: _key(ownerId));
        return true;
      });
  Future<T> _serial<T>(Future<T> Function() action) {
    final result = _queue.then<T>((_) => action());
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }
}
