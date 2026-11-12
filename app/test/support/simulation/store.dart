part of 'simulation.dart';

enum SimulationScenario { normal, slow, empty, readError, conflict, unknown }

/// Local fictional database. One persisted snapshot contains data and receipts.
/// No network, production token or production journal is accessed.
class SimulationStore {
  SimulationStore._(this._storage, this._data);
  final LocalStorage? _storage;
  Json _data;
  Future<void> _queue = Future<void>.value();
  int _sessionEpoch = 0;
  SimulationScenario scenario = SimulationScenario.normal;
  Duration latency = const Duration(milliseconds: 450);
  static const storageKey = 'database.v1';

  static Future<SimulationStore> open(LocalStorage storage) async {
    final raw = storage.getString(storageKey);
    final data = raw == null ? simulationSeed() : asJson(jsonDecode(raw));
    if (data['schema'] != 1) {
      throw const FormatException('Versi simulasi tidak dikenal.');
    }
    final store = SimulationStore._(storage, data);
    if (raw == null) {
      await storage.setString(storageKey, jsonEncode(data));
    }
    return store;
  }

  factory SimulationStore.memory({String? snapshot}) => SimulationStore._(
    null,
    snapshot == null ? simulationSeed() : asJson(jsonDecode(snapshot)),
  )..latency = Duration.zero;
  String exportSimulationData() => jsonEncode(_data);

  Map<String, dynamic> table(String name) =>
      _data[name] as Map<String, dynamic>;
  User? get sessionUser {
    final id = _data['session'];
    final value = table('users')[id];
    return value == null ? null : unpackUser(asJson(value));
  }

  User require([UserRole? role]) {
    final user = sessionUser;
    if (user == null ||
        !user.isActive ||
        (role != null && !user.role.allows(role))) {
      throw const AuthSessionExpiredFailure();
    }
    return user;
  }

  Future<(String, int)> begin([UserRole? role]) async {
    final id = require(role).id;
    final epoch = _sessionEpoch;
    final delay = scenario == SimulationScenario.slow
        ? const Duration(seconds: 3)
        : latency;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    await _queue;
    check((id, epoch), role);
    return (id, epoch);
  }

  void check((String, int) actor, [UserRole? role]) {
    if (_sessionEpoch != actor.$2 || require(role).id != actor.$1) {
      throw const AuthOperationSupersededFailure();
    }
  }

  void readGuard() {
    if (scenario == SimulationScenario.readError) {
      throw const FormatException('Gangguan baca simulasi.');
    }
  }

  bool get empty => scenario == SimulationScenario.empty;

  Future<T> atomic<T>(T Function() action) {
    final result = _queue.then((_) async {
      final before = jsonEncode(_data);
      try {
        final value = action();
        _data['revision'] = (_data['revision'] as int) + 1;
        await _storage?.setString(storageKey, jsonEncode(_data));
        return value;
      } catch (_) {
        _data = asJson(jsonDecode(before));
        rethrow;
      }
    });
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  String nextId(String prefix) {
    final n = (_data['sequence'] as int) + 1;
    _data['sequence'] = n;
    return '$prefix-$n';
  }

  Future<void> signIn(String id) => atomic(() {
    _data['session'] = id;
    _sessionEpoch++;
  });
  Future<void> signOut() => atomic(() {
    _data['session'] = null;
    _sessionEpoch++;
  });
  Future<void> reset() => atomic(() {
    _data = simulationSeed();
    _sessionEpoch++;
    scenario = SimulationScenario.normal;
  });

  /// Every mutation reserves a sealed ID, including definitive rejections.
  /// Replays return the original immutable result, never the latest record.
  Future<Json> mutate({
    required (String, int) actor,
    required String operation,
    required String id,
    required Json payload,
    required Object conflict,
    required Json Function() apply,
    UserRole role = UserRole.customer,
  }) async {
    final key = '${actor.$1}:$operation:$id';
    final fingerprint = jsonEncode(payload);
    Object? rejection;
    final result = await atomic<Json>(() {
      check(actor, role);
      final saved = table('receipts')[key];
      if (saved != null) {
        final receipt = asJson(saved);
        if (receipt['payload'] != fingerprint) {
          throw conflict;
        }
        if (receipt['sealed'] == true) {
          rejection = conflict;
          return {};
        }
        return asJson(receipt['result']);
      }
      if (id.trim().isEmpty) {
        throw ArgumentError('ID request kosong.');
      }
      final before = jsonEncode(_data);
      try {
        if (scenario == SimulationScenario.conflict) {
          throw conflict;
        }
        final result = apply();
        table('receipts')[key] = {
          'payload': fingerprint,
          'result': result,
          'sealed': false,
        };
        return result;
      } catch (error) {
        _data = asJson(jsonDecode(before));
        table('receipts')[key] = {'payload': fingerprint, 'sealed': true};
        rejection = error;
        return {};
      }
    });
    if (rejection != null) {
      throw rejection!;
    }
    if (scenario == SimulationScenario.unknown) {
      throw TimeoutException('Respons simulasi hilang setelah commit.');
    }
    return result;
  }

  Json? receipt(String operation, String id) {
    final entry = table('receipts')['${require().id}:$operation:$id'];
    if (entry == null) {
      return null;
    }
    final value = asJson(entry);
    if (value['sealed'] == true) {
      return {'sealed': true};
    }
    return asJson(value['result']);
  }

  Future<Json?> lookup(String operation, String id, UserRole role) async {
    final actor = await begin(role);
    readGuard();
    return atomic(() {
      check(actor, role);
      // A missing ID is explicitly sealed here; a delayed writer will reject it.
      final key = '${actor.$1}:$operation:$id';
      table(
        'receipts',
      ).putIfAbsent(key, () => {'sealed': true, 'payload': null});
      return receipt(operation, id);
    });
  }

  (List<T>, String?) page<T>(
    List<T> values,
    String binding,
    String? cursor,
    int limit,
  ) {
    if (limit < 1 || limit > 100) {
      throw ArgumentError('Limit tidak valid.');
    }
    var offset = 0;
    if (cursor != null) {
      final c = asJson(jsonDecode(utf8.decode(base64Url.decode(cursor))));
      if (c['binding'] != binding || c['revision'] != _data['revision']) {
        throw const FormatException(
          'Daftar berubah. Muat ulang dari halaman pertama.',
        );
      }
      offset = c['offset'] as int;
      if (offset < 0 || offset > values.length) {
        throw const FormatException('Cursor tidak valid.');
      }
    }
    final items = values.skip(offset).take(limit).toList();
    final next = offset + items.length;
    return (
      items,
      next >= values.length
          ? null
          : base64Url.encode(
              utf8.encode(
                jsonEncode({
                  'binding': binding,
                  'revision': _data['revision'],
                  'offset': next,
                }),
              ),
            ),
    );
  }
}

class SimulationKeyValueStorage {
  SimulationKeyValueStorage(this.store);
  final SimulationStore store;
  Future<String?> read({required String key}) async {
    await store._queue;
    return store.table('journals')[key] as String?;
  }

  Future<void> write({required String key, required String value}) =>
      store.atomic(() {
        store.table('journals')[key] = value;
      });
  Future<void> delete({required String key}) => store.atomic(() {
    store.table('journals').remove(key);
  });
}

DateTime simulationUpdateTime(DateTime previous) {
  final now = DateTime.now().toUtc();
  return now.isAfter(previous)
      ? now
      : previous.add(const Duration(milliseconds: 1));
}
