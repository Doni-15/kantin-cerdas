import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/application/services/require_account_session.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
import 'package:kantin_cerdas/features/customer/application/customer_providers.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';

sealed class CheckoutOutcome {
  const CheckoutOutcome();
}

final class CheckoutConfirmed extends CheckoutOutcome {
  const CheckoutConfirmed(this.order, {this.replayed = false});
  final CustomerOrderDetail order;
  final bool replayed;
}

final class CheckoutUncertain extends CheckoutOutcome {
  const CheckoutUncertain({required this.attempt, required this.message});
  final CustomerCheckoutAttempt attempt;
  final String message;
}

final customerCheckoutControllerProvider = Provider<CustomerCheckoutController>(
  CustomerCheckoutController.new,
);

class CustomerCheckoutController {
  CustomerCheckoutController(this._ref);

  final Ref _ref;
  var _inFlight = false;

  Future<CustomerCheckoutAttempt?> readPendingAttempt(String accountId) =>
      _ref.read(checkoutAttemptStoreProvider).read(accountId);

  Future<CheckoutOutcome> submitCheckout({
    required String accountId,
    required CustomerCart cart,
  }) async {
    if (_inFlight) {
      throw const AuthException(
        'CHECKOUT_IN_FLIGHT',
        'Pengiriman pesanan sedang diproses.',
      );
    }
    _inFlight = true;
    try {
      final session = _session(accountId);
      final repo = _ref.read(customerRepositoryProvider);
      final attemptStore = _ref.read(checkoutAttemptStoreProvider);

      // Reuse matching local pending attempt if the same draft version was interrupted.
      var attempt = await attemptStore.read(accountId);
      if (attempt != null && attempt.cartVersion == cart.draftVersion) {
        try {
          final recovered = await _tryRecoverAttempt(
            accountId: accountId,
            attemptId: attempt.attemptId,
            session: session,
          );
          if (recovered != null) {
            return recovered;
          }
        } on AuthException catch (error) {
          if (_isUncertainNetworkError(error)) {
            return CheckoutUncertain(
              attempt: attempt,
              message:
                  'Belum dapat memastikan status pengiriman sebelumnya. Periksa lagi sebelum mengirim ulang.',
            );
          }
          rethrow;
        }
      } else {
        attempt = null;
      }

      if (attempt == null) {
        attempt = await repo.createCheckoutAttempt(
          session,
          expectedVersion: cart.draftVersion,
        );
        await attemptStore.write(accountId, attempt);
      }

      try {
        final result = await repo.checkout(
          session,
          attemptId: attempt.attemptId,
          expectedVersion: cart.draftVersion,
        );
        await _afterConfirmed(accountId);
        return CheckoutConfirmed(result.order, replayed: result.replayed);
      } on AuthException catch (error) {
        if (_isUncertainNetworkError(error)) {
          return CheckoutUncertain(
            attempt: attempt,
            message:
                'Koneksi terputus sebelum jawaban akhir diterima. Periksa status pengiriman agar tidak terjadi pesanan ganda.',
          );
        }
        // Definitive rejection (closed, inactive, price changed, archived, etc.)
        if (_isCartStateError(error)) {
          await attemptStore.clear(accountId);
          _ref.invalidate(customerCartProvider(accountId));
        }
        rethrow;
      }
    } finally {
      _inFlight = false;
    }
  }

  Future<CheckoutOutcome> verifyOrRetryAttempt({
    required String accountId,
    required CustomerCheckoutAttempt attempt,
  }) async {
    if (_inFlight) {
      throw const AuthException(
        'CHECKOUT_IN_FLIGHT',
        'Pemeriksaan pesanan sedang diproses.',
      );
    }
    _inFlight = true;
    try {
      final session = _session(accountId);
      final existing = await _tryRecoverAttempt(
        accountId: accountId,
        attemptId: attempt.attemptId,
        session: session,
      );
      if (existing != null) return existing;

      try {
        final result = await _ref
            .read(customerRepositoryProvider)
            .checkout(
              session,
              attemptId: attempt.attemptId,
              expectedVersion: attempt.cartVersion,
            );
        await _afterConfirmed(accountId);
        return CheckoutConfirmed(result.order, replayed: result.replayed);
      } on AuthException catch (error) {
        if (_isUncertainNetworkError(error)) {
          return CheckoutUncertain(
            attempt: attempt,
            message:
                'Belum dapat memastikan status pesanan karena gangguan koneksi. Coba periksa lagi.',
          );
        }
        if (_isCartStateError(error)) {
          await _ref.read(checkoutAttemptStoreProvider).clear(accountId);
          _ref.invalidate(customerCartProvider(accountId));
        }
        rethrow;
      }
    } finally {
      _inFlight = false;
    }
  }

  Future<CheckoutConfirmed?> _tryRecoverAttempt({
    required String accountId,
    required String attemptId,
    required AuthSession session,
  }) async {
    try {
      final lookup = await _ref
          .read(customerRepositoryProvider)
          .fetchOrderByAttempt(session, attemptId: attemptId);
      if (lookup?.order != null) {
        await _afterConfirmed(accountId);
        return CheckoutConfirmed(lookup!.order!, replayed: true);
      }
      return null;
    } on AuthException catch (error) {
      if (_isUncertainNetworkError(error)) {
        rethrow;
      }
      return null;
    }
  }

  Future<void> _afterConfirmed(String accountId) async {
    await _ref.read(checkoutAttemptStoreProvider).clear(accountId);
    _ref.invalidate(customerCartProvider(accountId));
    _ref.invalidate(
      customerOrdersProvider((accountId: accountId, activeOnly: true)),
    );
    _ref.invalidate(
      customerOrdersProvider((accountId: accountId, activeOnly: false)),
    );
    _ref.invalidate(customerOwnerApplicationProvider(accountId));
  }

  bool _isUncertainNetworkError(AuthException error) => const {
    'AUTH_CONNECTION_FAILED',
    'AUTH_TIMEOUT',
    'AUTH_UNAVAILABLE',
    'INVALID_RESPONSE',
    'NETWORK_ERROR',
    'TIMEOUT',
    'SERVICE_UNAVAILABLE',
  }.contains(error.code);

  bool _isCartStateError(AuthException error) => const {
    'STALL_CLOSED',
    'OWNER_INACTIVE',
    'MENU_ARCHIVED',
    'MENU_UNAVAILABLE',
    'PRICE_CHANGED',
    'CART_VERSION_CONFLICT',
    'CART_EMPTY',
    'IDEMPOTENCY_CONFLICT',
  }.contains(error.code);

  AuthSession _session(String accountId) => requireAccountSession(
    _ref.read(authControllerProvider).asData?.value,
    accountId,
  );
}
