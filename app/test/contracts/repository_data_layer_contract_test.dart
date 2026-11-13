import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/features/admin/data/datasources/admin_api_datasource.dart';
import 'package:kantin_cerdas/features/admin/data/datasources/admin_datasource.dart';
import 'package:kantin_cerdas/features/admin/data/models/admin_models.dart';
import 'package:kantin_cerdas/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_application_review.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_mutation_lookup.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_user_access_change.dart';
import 'package:kantin_cerdas/features/admin/domain/failures/admin_failure.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_assistant_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_order_tracking_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/food_preferences_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/models/assistant_reply_model.dart';
import 'package:kantin_cerdas/features/customer/data/models/customer_order_models.dart';
import 'package:kantin_cerdas/features/customer/data/models/food_preferences_model.dart';
import 'package:kantin_cerdas/features/customer/data/repositories/customer_assistant_repository_impl.dart';
import 'package:kantin_cerdas/features/customer/data/repositories/customer_order_tracking_repository_impl.dart';
import 'package:kantin_cerdas/features/customer/data/repositories/food_preferences_repository_impl.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_cancellation.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences_snapshot.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_cancellation_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_feature_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_order_cancellation_failure.dart';
import 'package:kantin_cerdas/features/orders/data/models/canteen_application_model.dart';
import 'package:kantin_cerdas/features/orders/data/models/order_record_model.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:kantin_cerdas/features/owner/data/datasources/owner_api_datasource.dart';
import 'package:kantin_cerdas/features/owner/data/datasources/owner_datasource.dart';
import 'package:kantin_cerdas/features/owner/data/models/owner_models.dart';
import 'package:kantin_cerdas/features/owner/data/repositories/owner_repository_impl.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_menu.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_mutation_lookup.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_order_transition.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_stall.dart';
import 'package:kantin_cerdas/features/owner/domain/failures/owner_failure.dart';

class _StubCustomerOrderTrackingDataSource
    implements CustomerOrderTrackingDataSource {
  const _StubCustomerOrderTrackingDataSource({
    required this.onListMyOrders,
    required this.onGetMyOrder,
    required this.onCancelMyOrder,
    required this.onLookupCancellation,
  });

  final Future<OrderRecordPageModel> Function({
    required bool history,
    String? cursor,
    int limit,
  })
  onListMyOrders;
  final Future<OrderRecordModel?> Function(String orderId) onGetMyOrder;
  final Future<OrderRecordModel> Function(
    CustomerOrderCancellation cancellation,
    String mutationId,
  )
  onCancelMyOrder;
  final Future<OrderCancellationLookup> Function(String mutationId)
  onLookupCancellation;

  @override
  bool get isConfigured => true;

  @override
  bool get isCancellationConfigured => true;

  @override
  Future<OrderRecordPageModel> listMyOrders({
    required bool history,
    String? cursor,
    int limit = 30,
  }) => onListMyOrders(history: history, cursor: cursor, limit: limit);

  @override
  Future<OrderRecordModel?> getMyOrder({required String orderId}) =>
      onGetMyOrder(orderId);

  @override
  Future<OrderRecordModel> cancelMyOrder(
    CustomerOrderCancellation cancellation, {
    required String mutationId,
  }) => onCancelMyOrder(cancellation, mutationId);

  @override
  Future<OrderCancellationLookup> lookupCancellation({
    required String mutationId,
  }) => onLookupCancellation(mutationId);
}

class _StubFoodPreferencesDataSource implements FoodPreferencesDataSource {
  const _StubFoodPreferencesDataSource({
    required this.onGet,
    required this.onSave,
    required this.onLookup,
  });

  final Future<FoodPreferencesSnapshotModel?> Function() onGet;
  final Future<FoodPreferencesSnapshotModel> Function(
    FoodPreferencesUpdate update,
    String mutationId,
  )
  onSave;
  final Future<FoodPreferencesLookup> Function(String mutationId) onLookup;

  @override
  bool get isSaveConfigured => true;

  @override
  Future<FoodPreferencesSnapshotModel?> getMyPreferences() => onGet();

  @override
  Future<FoodPreferencesSnapshotModel> saveMyPreferences(
    FoodPreferencesUpdate update, {
    required String mutationId,
  }) => onSave(update, mutationId);

  @override
  Future<FoodPreferencesLookup> lookupSave({required String mutationId}) =>
      onLookup(mutationId);
}

class _StubCustomerAssistantDataSource implements CustomerAssistantDataSource {
  const _StubCustomerAssistantDataSource({required this.onRecommend});

  final Future<AssistantReplyModel> Function(String message) onRecommend;

  @override
  bool get isConfigured => true;

  @override
  Future<AssistantReplyModel> recommend(String message) => onRecommend(message);
}

class _StubOwnerDataSource implements OwnerDataSource {
  const _StubOwnerDataSource({
    required this.onGetMyStall,
    required this.onSaveStall,
    required this.onSaveMenu,
  });

  final Future<OwnerStallModel?> Function() onGetMyStall;
  final Future<OwnerStallModel> Function(
    OwnerStallInput input,
    String mutationId,
  )
  onSaveStall;
  final Future<OwnerMenuModel> Function(OwnerMenuInput input, String mutationId)
  onSaveMenu;

  @override
  bool get isMutationConfigured => true;

  @override
  Future<OwnerStallModel?> getMyStall() => onGetMyStall();

  @override
  Future<OwnerMenuPageModel> listMenus({
    required String stallId,
    required String search,
    bool? available,
    String? cursor,
    int limit = 30,
  }) => throw UnimplementedError();

  @override
  Future<OwnerMenuModel> saveMenu(
    OwnerMenuInput input, {
    required String mutationId,
  }) => onSaveMenu(input, mutationId);

  @override
  Future<void> deleteMenu({
    required String id,
    required int expectedVersion,
    required String mutationId,
  }) => throw UnimplementedError();

  @override
  Future<OwnerStallModel> saveStall(
    OwnerStallInput input, {
    required String mutationId,
  }) => onSaveStall(input, mutationId);

  @override
  Future<OrderRecordPageModel> listOrders({
    required String stallId,
    OrderStatus? status,
    String? cursor,
    int limit = 30,
  }) => throw UnimplementedError();

  @override
  Future<OrderRecordModel?> getMyOrder({
    required String stallId,
    required String orderId,
  }) => throw UnimplementedError();

  @override
  Future<OrderRecordModel> transitionOrder(
    OwnerOrderTransition input, {
    required String mutationId,
  }) => throw UnimplementedError();

  @override
  Future<OwnerMutationLookup> lookupMutation({required String mutationId}) =>
      throw UnimplementedError();
}

class _StubAdminDataSource implements AdminDataSource {
  const _StubAdminDataSource({
    required this.onGetSummary,
    required this.onSetUserAccess,
    required this.onReviewApplication,
  });

  final Future<AdminSummaryModel> Function() onGetSummary;
  final Future<AdminUserRecordModel> Function(
    AdminUserAccessChange change,
    String mutationId,
  )
  onSetUserAccess;
  final Future<CanteenApplicationModel> Function(
    AdminApplicationReview review,
    String mutationId,
  )
  onReviewApplication;

  @override
  bool get isMutationConfigured => true;

  @override
  Future<AdminSummaryModel> getSummary() => onGetSummary();

  @override
  Future<AdminUserPageModel> listUsers({
    required String search,
    String? cursor,
    int limit = 30,
  }) => throw UnimplementedError();

  @override
  Future<AdminUserRecordModel?> getUser({required String userId}) =>
      throw UnimplementedError();

  @override
  Future<AdminUserRecordModel> setUserAccess(
    AdminUserAccessChange change, {
    required String mutationId,
  }) => onSetUserAccess(change, mutationId);

  @override
  Future<AdminApplicationPageModel> listApplications({
    CanteenApplicationStatus? status,
    String? cursor,
    int limit = 30,
  }) => throw UnimplementedError();

  @override
  Future<CanteenApplicationModel?> getApplication({
    required String applicationId,
  }) => throw UnimplementedError();

  @override
  Future<CanteenApplicationModel> reviewApplication(
    AdminApplicationReview review, {
    required String mutationId,
  }) => onReviewApplication(review, mutationId);

  @override
  Future<AdminMutationLookup> lookupMutation({required String mutationId}) =>
      throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Kontrak repository layer data (H-4)', () {
    test(
      'OwnerRepositoryImpl dan AdminRepositoryImpl default tetap unconfigured tanpa data palsu',
      () async {
        const ownerRepo = OwnerRepositoryImpl(dataSource: OwnerApiDataSource());
        expect(ownerRepo.isMutationConfigured, isFalse);
        await expectLater(
          ownerRepo.getMyStall(),
          throwsA(isA<OwnerNotConfiguredFailure>()),
        );

        const adminRepo = AdminRepositoryImpl(dataSource: AdminApiDataSource());
        expect(adminRepo.isMutationConfigured, isFalse);
        await expectLater(
          adminRepo.getSummary(),
          throwsA(isA<AdminNotConfiguredFailure>()),
        );
      },
    );

    test(
      'H-4: OwnerRepositoryImpl, AdminRepositoryImpl, CustomerOrderTrackingRepositoryImpl, FoodPreferencesRepositoryImpl, dan CustomerAssistantRepositoryImpl memvalidasi operasi langsung, batas kursor, dan lookupId',
      () async {
        // 1. CustomerOrderTrackingRepositoryImpl
        final sampleOrderModel = OrderRecordModel.fromJson(<String, Object?>{
          'id': 'ord-101',
          'order_number': 'KC-101',
          'customer_id': 'cust-1',
          'customer_name': 'Doni',
          'stall_id': 'stall-1',
          'stall_name': 'Kantin Nusantara',
          'status': 'waiting',
          'payment_status': 'unpaid',
          'total_price_idr': 20000,
          'note': '',
          'created_at': '2026-11-02T01:00:00Z',
          'updated_at': '2026-11-02T01:00:00Z',
          'version': 1,
          'items': <Object?>[
            <String, Object?>{
              'menu_id': 'm-1',
              'name': 'Nasi Goreng',
              'quantity': 1,
              'unit_price_idr': 20000,
              'note': '',
            },
          ],
        });

        final trackingRepo = CustomerOrderTrackingRepositoryImpl(
          dataSource: _StubCustomerOrderTrackingDataSource(
            onListMyOrders: ({required history, cursor, limit = 30}) async =>
                OrderRecordPageModel(
                  items: <OrderRecordModel>[sampleOrderModel],
                  nextCursor: 'cursor-next-1',
                ),
            onGetMyOrder: (orderId) async => sampleOrderModel,
            onCancelMyOrder: (cancellation, mutationId) async =>
                OrderRecordModel.fromJson(<String, Object?>{
                  'id': cancellation.orderId,
                  'order_number': 'KC-101',
                  'customer_id': 'cust-1',
                  'customer_name': 'Doni',
                  'stall_id': 'stall-1',
                  'stall_name': 'Kantin Nusantara',
                  'status': 'cancelled',
                  'payment_status': 'notCharged',
                  'total_price_idr': 20000,
                  'note': '',
                  'created_at': '2026-11-02T01:00:00Z',
                  'updated_at': '2026-11-02T01:05:00Z',
                  'version': 2,
                  'items': <Object?>[
                    <String, Object?>{
                      'menu_id': 'm-1',
                      'name': 'Nasi Goreng',
                      'quantity': 1,
                      'unit_price_idr': 20000,
                      'note': '',
                    },
                  ],
                }),
            onLookupCancellation: (mutationId) async =>
                OrderCancellationLookupModel.fromJson(<String, Object?>{
                  'mutation_id': 'wrong-id',
                  'customer_id': 'cust-1',
                  'stall_id': 'stall-1',
                  'order_number': 'KC-101',
                  'order_id': 'ord-101',
                  'expected_version': 1,
                  'status': 'not_cancelled',
                }).toEntity(),
          ),
        );

        final ordersPage = await trackingRepo.listMyOrders(history: false);
        expect(ordersPage.items.single.id, 'ord-101');
        expect(ordersPage.nextCursor, 'cursor-next-1');

        final cancelledOrder = await trackingRepo.cancelMyOrder(
          CustomerOrderCancellation(orderId: 'ord-101', expectedVersion: 1),
          mutationId: 'mut-cancel-1',
        );
        expect(cancelledOrder.status, OrderStatus.cancelled);
        expect(cancelledOrder.version, 2);

        // Mismatched mutationId pada lookup wajib ditolak sebagai UnknownFailure
        await expectLater(
          trackingRepo.lookupCancellation(mutationId: 'mut-cancel-1'),
          throwsA(isA<CustomerOrderCancellationUnknownFailure>()),
        );

        // 2. FoodPreferencesRepositoryImpl
        final prefsModel = FoodPreferencesSnapshotModel.fromJson(
          <String, Object?>{
            'customer_id': 'cust-1',
            'version': 2,
            'max_budget_idr': 25000,
            'vegetarian': true,
            'avoid_ingredients': <Object?>['kacang'],
          },
        );
        final prefsRepo = FoodPreferencesRepositoryImpl(
          dataSource: _StubFoodPreferencesDataSource(
            onGet: () async => prefsModel,
            onSave: (update, mutationId) async => prefsModel,
            onLookup: (mutationId) async =>
                FoodPreferencesLookupModel.fromJson(<String, Object?>{
                  'mutation_id': mutationId,
                  'customer_id': 'cust-1',
                  'expected_version': 1,
                  'max_budget_idr': 25000,
                  'vegetarian': true,
                  'avoid_ingredients': <Object?>['kacang'],
                  'status': 'saved',
                  'saved': <String, Object?>{
                    'customer_id': 'cust-1',
                    'version': 2,
                    'max_budget_idr': 25000,
                    'vegetarian': true,
                    'avoid_ingredients': <Object?>['kacang'],
                  },
                }).toEntity(),
          ),
        );

        final loadedPrefs = await prefsRepo.getMyPreferences();
        expect(loadedPrefs?.version, 2);
        final savedPrefs = await prefsRepo.saveMyPreferences(
          FoodPreferencesUpdate(
            preferences: FoodPreferences(
              maxBudgetIdr: 25000,
              vegetarian: true,
              avoidIngredients: const <String>['kacang'],
            ),
            expectedVersion: 1,
          ),
          mutationId: 'mut-pref-1',
        );
        expect(savedPrefs.preferences.vegetarian, isTrue);
        final lookupPrefs = await prefsRepo.lookupSave(
          mutationId: 'mut-pref-1',
        );
        expect(lookupPrefs.outcome, FoodPreferencesOutcome.applied);

        // 3. CustomerAssistantRepositoryImpl
        final assistantRepo = CustomerAssistantRepositoryImpl(
          dataSource: _StubCustomerAssistantDataSource(
            onRecommend: (msg) async =>
                AssistantReplyModel.fromJson(<String, Object?>{
                  'message': 'Rekomendasi hemat untuk: $msg',
                  'menus': <Object?>[
                    <String, Object?>{
                      'id': 'm-1',
                      'stall_id': 'stall-1',
                      'stall_name': 'Kantin Nusantara',
                      'name': 'Nasi Goreng',
                      'description': 'Gurih dan hangat',
                      'price_idr': 20000,
                      'category': 'Nasi',
                      'is_available': true,
                    },
                  ],
                }),
          ),
        );
        await expectLater(
          assistantRepo.recommend('   '),
          throwsA(isA<CustomerFeatureRejectedFailure>()),
        );
        final assistantReply = await assistantRepo.recommend('Menu hemat');
        expect(assistantReply.menus.single.id, 'm-1');

        // 4. OwnerRepositoryImpl
        final ownerRepo = OwnerRepositoryImpl(
          dataSource: _StubOwnerDataSource(
            onGetMyStall: () async =>
                OwnerStallModel.fromJson(<String, Object?>{
                  'id': 'stall-1',
                  'owner_id': 'owner-1',
                  'name': 'Kantin Nusantara',
                  'block': 'Blok A',
                  'description': 'Masakan rumahan',
                  'is_open': true,
                  'prep_time_min': 15,
                  'version': 1,
                }),
            onSaveStall: (input, mutationId) async =>
                OwnerStallModel.fromJson(<String, Object?>{
                  'id': input.id,
                  'owner_id': 'owner-1',
                  'name': input.name,
                  'block': input.block,
                  'description': input.description,
                  'is_open': input.isOpen,
                  'prep_time_min': input.prepTimeMin,
                  'version': input.expectedVersion + 1,
                }),
            onSaveMenu: (input, mutationId) async =>
                OwnerMenuModel.fromJson(<String, Object?>{
                  'id': input.id ?? 'm-new',
                  'stall_id': input.stallId,
                  'name': input.name,
                  'description': input.description,
                  'category': 'Nasi',
                  'price_idr': input.priceIdr,
                  'is_available': input.isAvailable,
                  'version': (input.expectedVersion ?? 0) + 1,
                }),
          ),
        );
        final myStall = await ownerRepo.getMyStall();
        expect(myStall?.id, 'stall-1');
        final updatedStall = await ownerRepo.saveStall(
          OwnerStallInput(
            id: 'stall-1',
            name: 'Kantin Nusantara Baru',
            block: 'Blok A',
            description: 'Masakan rumahan segar',
            isOpen: true,
            prepTimeMin: 12,
            expectedVersion: 1,
          ),
          mutationId: 'mut-stall-1',
        );
        expect(updatedStall.version, 2);
        final createdMenu = await ownerRepo.saveMenu(
          OwnerMenuInput(
            stallId: 'stall-1',
            name: 'Ayam Bakar',
            description: 'Bumbu madu',
            category: MenuCategory.rice,
            priceIdr: 22000,
            isAvailable: true,
          ),
          mutationId: 'mut-menu-1',
        );
        expect(createdMenu.id, 'm-new');

        // 5. AdminRepositoryImpl
        final adminRepo = AdminRepositoryImpl(
          dataSource: _StubAdminDataSource(
            onGetSummary: () async =>
                AdminSummaryModel.fromJson(<String, Object?>{
                  'users': 10,
                  'stalls': 3,
                  'open_stalls': 2,
                  'pending_applications': 1,
                  'active_orders': 4,
                }),
            onSetUserAccess: (change, mutationId) async =>
                AdminUserRecordModel.fromJson(<String, Object?>{
                  'user': <String, Object?>{
                    'id': change.userId,
                    'username': 'doni_student',
                    'email': 'doni@kantincerdas.ac.id',
                    'name': 'Doni Mahasiswa',
                    'role': 'customer',
                    'is_active': change.isActive,
                  },
                  'version': change.expectedVersion + 1,
                }),
            onReviewApplication: (review, mutationId) async =>
                CanteenApplicationModel.fromJson(<String, Object?>{
                  'id': review.applicationId,
                  'applicant_id': 'cust-1',
                  'name': 'Warung Cerdas',
                  'description': 'Menu sehat kampus',
                  'location': 'Blok C',
                  'phone': '081234567890',
                  'status': 'approved',
                  'created_at': '2026-11-02T01:00:00Z',
                  'version': review.expectedVersion + 1,
                }),
          ),
        );
        final summary = await adminRepo.getSummary();
        expect(summary.users, 10);
        final updatedAccess = await adminRepo.setUserAccess(
          AdminUserAccessChange(
            userId: 'usr-1',
            expectedVersion: 1,
            isActive: false,
            reason: 'Pelanggaran aturan kantin',
          ),
          mutationId: 'mut-adm-1',
        );
        expect(updatedAccess.user.isActive, isFalse);
        expect(updatedAccess.version, 2);
        final reviewedApp = await adminRepo.reviewApplication(
          AdminApplicationReview(
            applicationId: 'app-1',
            expectedVersion: 1,
            status: CanteenApplicationStatus.approved,
          ),
          mutationId: 'mut-adm-2',
        );
        expect(reviewedApp.status, CanteenApplicationStatus.approved);
        expect(reviewedApp.version, 2);
      },
    );
  });
}
