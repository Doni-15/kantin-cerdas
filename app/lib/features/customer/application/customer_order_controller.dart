import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/application/services/require_account_session.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
import 'package:kantin_cerdas/features/customer/application/customer_providers.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';

final customerOrderControllerProvider = Provider<CustomerOrderController>(
  CustomerOrderController.new,
);

class CustomerOrderController {
  CustomerOrderController(this._ref);

  final Ref _ref;
  var _busy = false;

  void refreshOrders(
    String accountId, {
    bool includeActive = true,
    bool includeHistory = true,
  }) {
    if (includeActive) {
      _ref.invalidate(
        customerOrdersProvider((accountId: accountId, activeOnly: true)),
      );
    }
    if (includeHistory) {
      _ref.invalidate(
        customerOrdersProvider((accountId: accountId, activeOnly: false)),
      );
    }
  }

  void refreshOrderDetail(String accountId, String orderId) {
    _ref.invalidate(
      customerOrderDetailProvider((accountId: accountId, orderId: orderId)),
    );
  }

  Future<CustomerOrderDetail> cancelOrder({
    required String accountId,
    required String orderId,
  }) async {
    if (_busy) {
      throw const AuthException(
        'ORDER_BUSY',
        'Tunggu sampai pembatalan sebelumnya selesai.',
      );
    }
    _busy = true;
    try {
      final session = _session(accountId);
      final updated = await _ref
          .read(customerRepositoryProvider)
          .cancelOrder(session, orderId: orderId);
      refreshOrders(accountId);
      refreshOrderDetail(accountId, orderId);
      _ref.invalidate(customerOwnerApplicationProvider(accountId));
      return updated;
    } finally {
      _busy = false;
    }
  }

  Future<CustomerOwnerApplicationState> submitOwnerApplication({
    required String accountId,
    required String plannedStallName,
    required String plannedLocation,
    required String reason,
  }) async {
    if (_busy) {
      throw const AuthException(
        'APPLICATION_BUSY',
        'Tunggu sampai pengiriman sebelumnya selesai.',
      );
    }
    _busy = true;
    try {
      final session = _session(accountId);
      final state = await _ref
          .read(customerRepositoryProvider)
          .submitOwnerApplication(
            session,
            plannedStallName: plannedStallName,
            plannedLocation: plannedLocation,
            reason: reason,
          );
      _ref.invalidate(customerOwnerApplicationProvider(accountId));
      return state;
    } finally {
      _busy = false;
    }
  }

  Future<void> clearLocalAttempts(String accountId) =>
      _ref.read(checkoutAttemptStoreProvider).clear(accountId);

  AuthSession _session(String accountId) => requireAccountSession(
    _ref.read(authControllerProvider).asData?.value,
    accountId,
  );
}
