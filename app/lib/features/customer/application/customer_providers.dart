import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/application/services/require_account_session.dart';
import 'package:kantin_cerdas/features/customer/data/checkout_attempt_store.dart';
import 'package:kantin_cerdas/features/customer/data/customer_api_repository.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_repository.dart';

const _apiBase = String.fromEnvironment('API_BASE_URL');

typedef CustomerStallKey = ({String accountId, String stallId});
typedef CustomerMenuKey = ({String accountId, String menuId});
typedef CustomerOrderListKey = ({String accountId, bool activeOnly});
typedef CustomerOrderDetailKey = ({String accountId, String orderId});

final customerRepositoryProvider = Provider<CustomerRepository>(
  (ref) => CustomerApiRepository(ref.watch(authRepositoryProvider)),
);

final checkoutAttemptStoreProvider = Provider<CheckoutAttemptStore>((ref) {
  if (kIsWeb) return MemoryCheckoutAttemptStore();
  return const SecureCheckoutAttemptStore(FlutterSecureStorage(), _apiBase);
});

final customerStallDetailProvider = FutureProvider.autoDispose
    .family<CustomerStallDetailBundle, CustomerStallKey>((ref, key) {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        key.accountId,
      );
      return ref
          .watch(customerRepositoryProvider)
          .fetchStallDetail(session, stallId: key.stallId);
    }, retry: (_, _) => null);

final customerStallPhotoProvider = FutureProvider.autoDispose
    .family<Uint8List?, CustomerStallKey>((ref, key) {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        key.accountId,
      );
      return ref
          .watch(customerRepositoryProvider)
          .fetchStallPhoto(session, stallId: key.stallId);
    }, retry: (_, _) => null);

final customerMenuDetailProvider = FutureProvider.autoDispose
    .family<CustomerMenuDetailBundle, CustomerMenuKey>((ref, key) {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        key.accountId,
      );
      return ref
          .watch(customerRepositoryProvider)
          .fetchMenuDetail(session, menuId: key.menuId);
    }, retry: (_, _) => null);

final customerMenuPhotoProvider = FutureProvider.autoDispose
    .family<Uint8List?, CustomerMenuKey>((ref, key) {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        key.accountId,
      );
      return ref
          .watch(customerRepositoryProvider)
          .fetchMenuPhoto(session, menuId: key.menuId);
    }, retry: (_, _) => null);

final customerCartProvider = FutureProvider.autoDispose
    .family<CustomerCart, String>((ref, accountId) {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        accountId,
      );
      return ref.watch(customerRepositoryProvider).fetchCart(session);
    }, retry: (_, _) => null);

final customerOrdersProvider = FutureProvider.autoDispose
    .family<List<CustomerOrderSummary>, CustomerOrderListKey>((ref, key) async {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        key.accountId,
      );
      final page = await ref
          .watch(customerRepositoryProvider)
          .listOrders(session, activeOnly: key.activeOnly, limit: 50);
      return page.items;
    }, retry: (_, _) => null);

final customerOrderDetailProvider = FutureProvider.autoDispose
    .family<CustomerOrderDetail, CustomerOrderDetailKey>((ref, key) {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        key.accountId,
      );
      return ref
          .watch(customerRepositoryProvider)
          .fetchOrderDetail(session, orderId: key.orderId);
    }, retry: (_, _) => null);

final customerOwnerApplicationProvider = FutureProvider.autoDispose
    .family<CustomerOwnerApplicationState, String>((ref, accountId) {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        accountId,
      );
      return ref
          .watch(customerRepositoryProvider)
          .fetchOwnerApplicationState(session);
    }, retry: (_, _) => null);
