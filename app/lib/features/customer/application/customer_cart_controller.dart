import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/application/services/require_account_session.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
import 'package:kantin_cerdas/features/customer/application/customer_providers.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';

final customerCartControllerProvider = Provider<CustomerCartController>(
  CustomerCartController.new,
);

class CustomerCartController {
  CustomerCartController(this._ref);

  final Ref _ref;
  var _busy = false;

  Future<CustomerCart> refresh(String accountId) async {
    _ref.invalidate(customerCartProvider(accountId));
    return _ref.read(customerCartProvider(accountId).future);
  }

  Future<CustomerCart> addItem({
    required String accountId,
    required String menuId,
    int quantity = 1,
    String itemNote = '',
    bool replaceStall = false,
  }) => _guard(() async {
    final cart = await _ref
        .read(customerRepositoryProvider)
        .addCartItem(
          _session(accountId),
          menuId: menuId,
          quantity: quantity,
          itemNote: itemNote,
          replaceStall: replaceStall,
        );
    _ref.invalidate(customerCartProvider(accountId));
    return cart;
  });

  Future<CustomerCart> updateItem({
    required String accountId,
    required String itemId,
    required int quantity,
    String? itemNote,
  }) => _guard(() async {
    final cart = await _ref
        .read(customerRepositoryProvider)
        .updateCartItem(
          _session(accountId),
          itemId: itemId,
          quantity: quantity,
          itemNote: itemNote,
        );
    _ref.invalidate(customerCartProvider(accountId));
    return cart;
  });

  Future<CustomerCart> deleteItem({
    required String accountId,
    required String itemId,
  }) => _guard(() async {
    final cart = await _ref
        .read(customerRepositoryProvider)
        .deleteCartItem(_session(accountId), itemId: itemId);
    _ref.invalidate(customerCartProvider(accountId));
    return cart;
  });

  Future<CustomerCart> setGeneralNote({
    required String accountId,
    required String generalNote,
  }) => _guard(() async {
    final cart = await _ref
        .read(customerRepositoryProvider)
        .setCartGeneralNote(_session(accountId), generalNote: generalNote);
    _ref.invalidate(customerCartProvider(accountId));
    return cart;
  });

  Future<CustomerCart> acknowledgePrices({
    required String accountId,
    int? expectedVersion,
  }) => _guard(() async {
    final cart = await _ref
        .read(customerRepositoryProvider)
        .acknowledgeCartPrices(
          _session(accountId),
          expectedVersion: expectedVersion,
        );
    _ref.invalidate(customerCartProvider(accountId));
    return cart;
  });

  Future<CustomerCart> clear({required String accountId}) => _guard(() async {
    final cart = await _ref
        .read(customerRepositoryProvider)
        .clearCart(_session(accountId));
    _ref.invalidate(customerCartProvider(accountId));
    return cart;
  });

  AuthSession _session(String accountId) => requireAccountSession(
    _ref.read(authControllerProvider).asData?.value,
    accountId,
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    if (_busy) {
      throw const AuthException(
        'CART_BUSY',
        'Tunggu sampai perubahan keranjang sebelumnya selesai.',
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
