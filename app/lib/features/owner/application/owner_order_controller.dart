import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/application/services/require_account_session.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
import 'package:kantin_cerdas/features/owner/application/owner_providers.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_order_rules.dart';

final ownerOrderControllerProvider = Provider<OwnerOrderController>(
  OwnerOrderController.new,
);

class OwnerOrderController {
  OwnerOrderController(this._ref);

  final Ref _ref;
  var _busy = false;

  Future<OwnerOrderDetail> lookupByCode({
    required String accountId,
    required String code,
  }) => _guard(
    () => _ref
        .read(ownerRepositoryProvider)
        .lookupOrder(_session(accountId), orderNumber: code),
  );

  Future<OwnerOrderDetail> performAction({
    required String accountId,
    required String orderId,
    required OwnerOrderAction action,
    String? reason,
    bool cashReceived = false,
    bool foodHandedOver = false,
  }) => _guard(() async {
    final session = _session(accountId);
    final repo = _ref.read(ownerRepositoryProvider);
    final updated = switch (action) {
      OwnerOrderAction.accept => await repo.acceptOrder(
        session,
        orderId: orderId,
      ),
      OwnerOrderAction.reject => await repo.rejectOrder(
        session,
        orderId: orderId,
        reason: reason ?? '',
      ),
      OwnerOrderAction.ready => await repo.markOrderReady(
        session,
        orderId: orderId,
      ),
      OwnerOrderAction.failFulfillment => await repo.failOrderFulfillment(
        session,
        orderId: orderId,
        reason: reason ?? '',
      ),
      OwnerOrderAction.complete => await repo.completeOrder(
        session,
        orderId: orderId,
        cashReceived: cashReceived,
        foodHandedOver: foodHandedOver,
      ),
      OwnerOrderAction.notPickedUp => await repo.markOrderNotPickedUp(
        session,
        orderId: orderId,
      ),
      OwnerOrderAction.failPickup => await repo.failOrderPickup(
        session,
        orderId: orderId,
        reason: reason ?? '',
      ),
    };
    _ref.invalidate(
      ownerOrderDetailProvider((accountId: accountId, orderId: orderId)),
    );
    _ref.invalidate(ownerOrdersProvider);
    _ref.invalidate(ownerDashboardProvider(accountId));
    return updated;
  });

  void refreshOrders(
    String accountId, {
    bool includeDashboard = true,
    bool includeOrdersList = true,
  }) {
    if (includeDashboard) {
      _ref.invalidate(ownerDashboardProvider(accountId));
    }
    if (includeOrdersList) {
      _ref.invalidate(ownerOrdersProvider);
    }
  }

  AuthSession _session(String accountId) => requireAccountSession(
    _ref.read(authControllerProvider).asData?.value,
    accountId,
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    if (_busy) {
      throw const AuthException(
        'OWNER_REQUEST_BUSY',
        'Tunggu hingga proses sebelumnya selesai.',
      );
    }
    _busy = true;
    try {
      return await action();
    } finally {
      _busy = false;
    }
  }
}
