import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';

abstract interface class CheckoutAttemptStore {
  Future<CustomerCheckoutAttempt?> read(String accountId);
  Future<void> write(String accountId, CustomerCheckoutAttempt attempt);
  Future<void> clear(String accountId);
}

class MemoryCheckoutAttemptStore implements CheckoutAttemptStore {
  final Map<String, CustomerCheckoutAttempt> _attempts = {};

  @override
  Future<CustomerCheckoutAttempt?> read(String accountId) async =>
      _attempts[accountId];

  @override
  Future<void> write(String accountId, CustomerCheckoutAttempt attempt) async =>
      _attempts[accountId] = attempt;

  @override
  Future<void> clear(String accountId) async => _attempts.remove(accountId);
}

class SecureCheckoutAttemptStore implements CheckoutAttemptStore {
  const SecureCheckoutAttemptStore(this._storage, this._apiBase);

  final FlutterSecureStorage _storage;
  final String _apiBase;

  String _key(String accountId) =>
      'kc.checkout_attempt.v1.$_apiBase.$accountId';

  @override
  Future<CustomerCheckoutAttempt?> read(String accountId) async {
    try {
      final raw = await _storage.read(key: _key(accountId));
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return CustomerCheckoutAttempt.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String accountId, CustomerCheckoutAttempt attempt) async {
    try {
      await _storage.write(
        key: _key(accountId),
        value: jsonEncode(attempt.toJson()),
      );
    } catch (_) {
      // Best effort local persistence; server also stores pending attempts.
    }
  }

  @override
  Future<void> clear(String accountId) async {
    try {
      await _storage.delete(key: _key(accountId));
    } catch (_) {
      // Ignore cleanup errors during logout.
    }
  }
}
