import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/application/services/require_account_session.dart';
import 'package:kantin_cerdas/features/owner/data/owner_api_repository.dart';
import 'package:kantin_cerdas/features/owner/data/owner_media_picker.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_repository.dart';

typedef OwnerBarcodeScanner = Future<String?> Function();

typedef OwnerMenuQuery = ({String accountId, bool archived, String query});
typedef OwnerMenuPhotoKey = ({String accountId, String menuId});
typedef OwnerOrderListQuery = ({
  String accountId,
  bool activeOnly,
  OwnerOrderStatus? status,
  String query,
});
typedef OwnerOrderDetailKey = ({String accountId, String orderId});

final ownerRepositoryProvider = Provider<OwnerRepository>(
  (ref) => OwnerApiRepository(ref.watch(authRepositoryProvider)),
);

final ownerPhotoPickerProvider = Provider<OwnerPhotoPicker>(
  (ref) => pickOwnerPhotoFromDevice,
);

/// Default barcode scanner delegate; returns `null` when native camera scanning
/// is not integrated, allowing manual Code 128 input fallback (UI-OWNER-007).
final ownerBarcodeScannerProvider = Provider<OwnerBarcodeScanner>(
  (ref) =>
      () async => null,
);

/// Tracks whether an authenticated Owner is temporarily browsing Customer mode
/// (`true`) or inside the Owner shell (`false`, default).
final ownerCustomerViewProvider = NotifierProvider.autoDispose
    .family<OwnerCustomerViewNotifier, bool, String>(
      OwnerCustomerViewNotifier.new,
    );

class OwnerCustomerViewNotifier extends Notifier<bool> {
  OwnerCustomerViewNotifier(String accountId);

  @override
  bool build() => false;

  void switchToCustomer() => state = true;
  void switchToOwner() => state = false;
}

final ownerDashboardProvider = FutureProvider.autoDispose
    .family<OwnerDashboard, String>((ref, accountId) {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        accountId,
      );
      return ref.watch(ownerRepositoryProvider).fetchDashboard(session);
    }, retry: (_, _) => null);

final ownerStallProvider = FutureProvider.autoDispose
    .family<OwnerStallBundle, String>((ref, accountId) {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        accountId,
      );
      return ref.watch(ownerRepositoryProvider).fetchStall(session);
    }, retry: (_, _) => null);

final ownerStallPhotoProvider = FutureProvider.autoDispose
    .family<Uint8List?, String>((ref, accountId) {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        accountId,
      );
      return ref.watch(ownerRepositoryProvider).fetchStallPhoto(session);
    }, retry: (_, _) => null);

final ownerCategoriesProvider = FutureProvider.autoDispose
    .family<List<OwnerCategory>, String>((ref, accountId) {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        accountId,
      );
      return ref.watch(ownerRepositoryProvider).listCategories(session);
    }, retry: (_, _) => null);

final ownerMenusProvider = FutureProvider.autoDispose
    .family<List<OwnerMenuItem>, OwnerMenuQuery>((ref, query) {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        query.accountId,
      );
      return ref
          .watch(ownerRepositoryProvider)
          .listMenus(session, archived: query.archived, query: query.query);
    }, retry: (_, _) => null);

final ownerMenuPhotoProvider = FutureProvider.autoDispose
    .family<Uint8List?, OwnerMenuPhotoKey>((ref, key) {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        key.accountId,
      );
      return ref
          .watch(ownerRepositoryProvider)
          .fetchMenuPhoto(session, menuId: key.menuId);
    }, retry: (_, _) => null);

final ownerOrdersProvider = FutureProvider.autoDispose
    .family<List<OwnerOrderSummary>, OwnerOrderListQuery>((ref, query) {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        query.accountId,
      );
      return ref
          .watch(ownerRepositoryProvider)
          .listOrders(
            session,
            activeOnly: query.activeOnly,
            status: query.status,
            query: query.query,
          );
    }, retry: (_, _) => null);

final ownerOrderDetailProvider = FutureProvider.autoDispose
    .family<OwnerOrderDetail, OwnerOrderDetailKey>((ref, key) {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        key.accountId,
      );
      return ref
          .watch(ownerRepositoryProvider)
          .fetchOrderDetail(session, orderId: key.orderId);
    }, retry: (_, _) => null);
