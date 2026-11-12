import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/core/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/features/admin/data/datasources/admin_datasource.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_application_review.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_mutation_lookup.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_user_access_change.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_assistant_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_order_tracking_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/food_preferences_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/models/assistant_reply_model.dart';
import 'package:kantin_cerdas/features/customer/data/repositories/customer_assistant_repository_impl.dart';
import 'package:kantin_cerdas/features/customer/data/repositories/customer_order_tracking_repository_impl.dart';
import 'package:kantin_cerdas/features/customer/data/repositories/food_preferences_repository_impl.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_cancellation.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences_snapshot.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_order_cancellation_failure.dart';
import 'package:kantin_cerdas/features/owner/data/datasources/owner_datasource.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_menu.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_order_transition.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_stall.dart';

import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/features/admin/data/datasources/admin_api_datasource.dart';
import 'package:kantin_cerdas/features/admin/data/mappers/admin_failure_mapper.dart';
import 'package:kantin_cerdas/features/admin/data/models/admin_models.dart';
import 'package:kantin_cerdas/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:kantin_cerdas/features/admin/domain/failures/admin_failure.dart';
import 'package:kantin_cerdas/features/auth/data/mappers/auth_failure_mapper.dart';
import 'package:kantin_cerdas/features/auth/data/models/login_response_model.dart';
import 'package:kantin_cerdas/features/auth/data/models/user_model.dart';
import 'package:kantin_cerdas/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kantin_cerdas/features/auth/data/storage/auth_tokens.dart';
import 'package:kantin_cerdas/features/auth/data/storage/secure_token_storage.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';
import 'package:kantin_cerdas/features/auth/domain/usecases/update_profile_avatar_usecase.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/canteen_application_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_catalog_api_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_catalog_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_order_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/mappers/customer_catalog_mapper.dart';
import 'package:kantin_cerdas/features/customer/data/mappers/customer_failure_mapper.dart';
import 'package:kantin_cerdas/features/customer/data/models/customer_catalog_model.dart';
import 'package:kantin_cerdas/features/customer/data/models/customer_order_models.dart';
import 'package:kantin_cerdas/features/customer/data/models/food_preferences_model.dart';
import 'package:kantin_cerdas/features/customer/data/models/menu_item_model.dart';
import 'package:kantin_cerdas/features/customer/data/models/stall_model.dart';
import 'package:kantin_cerdas/features/customer/data/repositories/canteen_application_repository_impl.dart';
import 'package:kantin_cerdas/features/customer/data/repositories/customer_catalog_repository_impl.dart';
import 'package:kantin_cerdas/features/customer/data/repositories/customer_order_repository_impl.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_price_confirmation.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_cancellation_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_draft.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_submission_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/pending_canteen_application.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/canteen_application_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_catalog_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_feature_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_order_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/food_preferences_failure.dart';
import 'package:kantin_cerdas/features/customer/presentation/mappers/customer_catalog_message.dart';
import 'package:kantin_cerdas/features/orders/data/mappers/order_record_mapper.dart';
import 'package:kantin_cerdas/features/orders/data/models/canteen_application_model.dart';
import 'package:kantin_cerdas/features/orders/data/models/order_record_model.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:kantin_cerdas/features/owner/data/datasources/owner_api_datasource.dart';
import 'package:kantin_cerdas/features/owner/data/mappers/owner_failure_mapper.dart';
import 'package:kantin_cerdas/features/owner/data/models/owner_models.dart';
import 'package:kantin_cerdas/features/owner/data/repositories/owner_repository_impl.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_mutation_lookup.dart';
import 'package:kantin_cerdas/features/owner/domain/failures/owner_failure.dart';

import '../support/auth_test_doubles.dart';

class _StubCatalogDataSource implements CustomerCatalogDataSource {
  const _StubCatalogDataSource(this.loader);

  final Future<CustomerCatalogModel> Function() loader;

  @override
  Future<CustomerCatalogModel> getCatalog() => loader();
}

class _StubCustomerOrderDataSource implements CustomerOrderDataSource {
  const _StubCustomerOrderDataSource({required this.onCreateOrder});

  final Future<String> Function(
    OrderDraft draft,
    String submissionId,
    CustomerOrderPriceConfirmation confirmation,
  )
  onCreateOrder;

  @override
  bool get isCheckoutConfigured => true;

  @override
  Future<String> createOrder({
    required OrderDraft draft,
    required String submissionId,
    required CustomerOrderPriceConfirmation confirmation,
  }) => onCreateOrder(draft, submissionId, confirmation);

  @override
  Future<OrderSubmissionLookup> lookupSubmission({
    required String submissionId,
  }) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleUserModel = UserModel(
    id: 'usr-1',
    username: 'doni_student',
    email: 'doni@kantincerdas.ac.id',
    name: 'Doni Mahasiswa',
    role: 'customer',
    isActive: true,
  );

  group('AuthFailureMapper (HIGH-01)', () {
    test(
      'memetakan 403 ACCOUNT_DISABLED, 409 USERNAME/EMAIL_TAKEN, 429, dan INVALID_CURRENT_PASSWORD',
      () {
        expect(
          mapAuthApiException(
            ApiException(
              type: ApiExceptionType.response,
              statusCode: 403,
              code: 'ACCOUNT_DISABLED',
            ),
            operation: AuthApiOperation.login,
          ),
          isA<AuthAccountDisabledFailure>(),
        );

        expect(
          mapAuthApiException(
            ApiException(
              type: ApiExceptionType.response,
              statusCode: 409,
              code: 'USERNAME_TAKEN',
            ),
            operation: AuthApiOperation.register,
          ),
          isA<AuthUsernameTakenFailure>(),
        );

        expect(
          mapAuthApiException(
            ApiException(
              type: ApiExceptionType.response,
              statusCode: 409,
              code: 'EMAIL_TAKEN',
            ),
            operation: AuthApiOperation.register,
          ),
          isA<AuthEmailTakenFailure>(),
        );

        expect(
          mapAuthApiException(
            ApiException(
              type: ApiExceptionType.response,
              statusCode: 400,
              code: 'INVALID_CURRENT_PASSWORD',
            ),
            operation: AuthApiOperation.changePassword,
          ),
          isA<AuthInvalidCurrentPasswordFailure>(),
        );

        expect(
          mapAuthApiException(
            ApiException(
              type: ApiExceptionType.response,
              statusCode: 429,
              code: 'RATE_LIMITED',
            ),
            operation: AuthApiOperation.login,
          ),
          isA<AuthRateLimitedFailure>(),
        );
      },
    );
  });

  group('AuthRepositoryImpl (LOW-03)', () {
    test(
      'login menyimpan pasangan token ke TokenStorage dan mengembalikan User',
      () async {
        final tokenStorage = MemoryTokenStorage();
        final expiry = DateTime.now().toUtc().add(const Duration(hours: 1));
        final repo = AuthRepositoryImpl(
          tokenStorage: tokenStorage,
          dataSource: StubAuthDataSource(
            onLogin: (identifier, password) async => LoginResponseModel(
              user: sampleUserModel,
              accessToken: 'acc-123',
              refreshToken: 'ref-456',
              expiresAt: expiry,
            ),
          ),
        );

        final user = await repo.login(
          identifier: 'doni_student',
          password: 'Password123',
        );
        expect(user.id, 'usr-1');
        expect(user.role, UserRole.customer);
        expect(tokenStorage.stored?.accessToken, 'acc-123');
        expect(tokenStorage.stored?.refreshToken, 'ref-456');
      },
    );

    test(
      'restoreSession memperbarui token kedaluwarsa via refreshSession dan mengembalikan User',
      () async {
        final tokenStorage = MemoryTokenStorage(
          AuthTokens(
            accessToken: 'expired-acc',
            refreshToken: 'valid-ref',
            expiresAt: DateTime.now().toUtc().subtract(
              const Duration(minutes: 10),
            ),
          ),
        );
        final freshExpiry = DateTime.now().toUtc().add(
          const Duration(minutes: 45),
        );
        final repo = AuthRepositoryImpl(
          tokenStorage: tokenStorage,
          dataSource: StubAuthDataSource(
            onRefreshSession: (refreshToken) async {
              expect(refreshToken, 'valid-ref');
              return LoginResponseModel(
                user: sampleUserModel,
                accessToken: 'new-acc-999',
                refreshToken: 'new-ref-999',
                expiresAt: freshExpiry,
              );
            },
          ),
        );

        final restored = await repo.restoreSession();
        expect(restored?.id, 'usr-1');
        expect(tokenStorage.stored?.accessToken, 'new-acc-999');
        expect(tokenStorage.stored?.refreshToken, 'new-ref-999');
      },
    );

    test(
      'restoreSession membersihkan TokenStorage dan mengembalikan null ketika refresh gagal 401',
      () async {
        final tokenStorage = MemoryTokenStorage(
          AuthTokens(
            accessToken: 'expired-acc',
            refreshToken: 'revoked-ref',
            expiresAt: DateTime.now().toUtc().subtract(
              const Duration(minutes: 5),
            ),
          ),
        );
        final repo = AuthRepositoryImpl(
          tokenStorage: tokenStorage,
          dataSource: StubAuthDataSource(
            onRefreshSession: (_) async => throw ApiException(
              type: ApiExceptionType.response,
              statusCode: 401,
              code: 'TOKEN_EXPIRED',
            ),
          ),
        );

        final restored = await repo.restoreSession();
        expect(restored, isNull);
        expect(tokenStorage.stored, isNull);
        expect(tokenStorage.clearCount, greaterThanOrEqualTo(1));
      },
    );

    test(
      'logout selalu menghapus sesi lokal meskipun pencabutan token jarak jauh gagal',
      () async {
        final tokenStorage = MemoryTokenStorage(
          const AuthTokens(accessToken: 'acc-active', refreshToken: 'ref-1'),
        );
        final repo = AuthRepositoryImpl(
          tokenStorage: tokenStorage,
          dataSource: StubAuthDataSource(
            onLogout: (accessToken, refreshToken) async {
              throw ApiException(type: ApiExceptionType.connection);
            },
          ),
        );

        await repo.logout();
        expect(tokenStorage.stored, isNull);
        expect(tokenStorage.clearCount, 1);
      },
    );

    test(
      'single-flight refresh mencegah duplikasi POST /v1/auth/refresh dan changePassword/updateProfileAvatar me-refresh saat menerima 401 TOKEN_EXPIRED',
      () async {
        final tokenStorage = MemoryTokenStorage(
          const AuthTokens(
            accessToken: 'stale-acc',
            refreshToken: 'ref-shared',
          ),
        );
        var refreshCalls = 0;
        var changePasswordCalls = 0;
        final refreshCompleter = Completer<LoginResponseModel>();
        final freshExpiry = DateTime.now().toUtc().add(
          const Duration(minutes: 45),
        );

        final repo = AuthRepositoryImpl(
          tokenStorage: tokenStorage,
          dataSource: StubAuthDataSource(
            onRefreshSession: (refreshToken) {
              refreshCalls++;
              expect(refreshToken, 'ref-shared');
              return refreshCompleter.future;
            },
            onChangePassword: (accessToken, _, _) async {
              changePasswordCalls++;
              if (accessToken == 'stale-acc') {
                throw ApiException(
                  type: ApiExceptionType.response,
                  statusCode: 401,
                  code: 'TOKEN_EXPIRED',
                );
              }
              expect(accessToken, 'fresh-acc');
            },
            onUpdateProfileAvatar: (accessToken, avatarUrl) async {
              expect(accessToken, 'fresh-acc');
              return UserModel(
                id: sampleUserModel.id,
                username: sampleUserModel.username,
                email: sampleUserModel.email,
                name: sampleUserModel.name,
                role: sampleUserModel.role,
                isActive: sampleUserModel.isActive,
                avatarUrl: avatarUrl,
              );
            },
          ),
        );

        final futureRefresh = repo.refreshTokens('ref-shared');
        final futureChangePassword = repo.changePassword(
          currentPassword: 'Password123',
          newPassword: 'PasswordBaru123',
        );

        refreshCompleter.complete(
          LoginResponseModel(
            user: sampleUserModel,
            accessToken: 'fresh-acc',
            refreshToken: 'fresh-ref',
            expiresAt: freshExpiry,
          ),
        );

        final refreshedTokens = await futureRefresh;
        await futureChangePassword;

        expect(refreshCalls, 1);
        expect(changePasswordCalls, 2);
        expect(refreshedTokens?.accessToken, 'fresh-acc');
        expect(tokenStorage.stored?.accessToken, 'fresh-acc');

        final useCase = UpdateProfileAvatarUseCase(repo);
        final updatedUser = await useCase.execute(
          avatarUrl:
              'https://cdn.kantincerdas.ac.id/usr-1_profile_avatar_12345678.webp',
        );
        expect(
          updatedUser.avatarUrl,
          'https://cdn.kantincerdas.ac.id/usr-1_profile_avatar_12345678.webp',
        );
      },
    );
  });

  group('SecureTokenStorage (LOW-03)', () {
    test(
      'menyimpan, membaca kembali, dan menghapus AuthTokens di FlutterSecureStorage',
      () async {
        FlutterSecureStorage.setMockInitialValues(<String, String>{});
        final storage = SecureTokenStorage(
          storage: const FlutterSecureStorage(),
        );
        final expiresAt = DateTime.utc(2027, 1, 15, 8, 30);

        await storage.save(
          AuthTokens(
            accessToken: 'tok-abc',
            refreshToken: 'ref-xyz',
            expiresAt: expiresAt,
          ),
        );

        final loaded = await storage.read();
        expect(loaded?.accessToken, 'tok-abc');
        expect(loaded?.refreshToken, 'ref-xyz');
        expect(loaded?.expiresAt, expiresAt);

        await storage.clear();
        expect(await storage.read(), isNull);
      },
    );

    test(
      'melempar DataParsingException ketika JSON di penyimpanan rusak atau token kosong',
      () async {
        FlutterSecureStorage.setMockInitialValues(<String, String>{
          'kantin_cerdas.auth.tokens.v1': '{corrupted-json',
        });
        final storage = SecureTokenStorage(
          storage: const FlutterSecureStorage(),
        );

        await expectLater(storage.read(), throwsA(isA<DataParsingException>()));
        await expectLater(
          storage.save(const AuthTokens(accessToken: '   ')),
          throwsA(isA<DataParsingException>()),
        );
      },
    );
  });

  group(
    'CustomerCatalogMapper & CustomerCatalogRepositoryImpl (LOW-03, HIGH-03, HIGH-05)',
    () {
      test(
        'CustomerCatalogRepositoryImpl meneruskan CustomerCatalogNotConfiguredFailure secara spesifik',
        () async {
          const repo = CustomerCatalogRepositoryImpl(
            dataSource: CustomerCatalogApiDataSource(),
          );
          await expectLater(
            repo.getCatalog(),
            throwsA(isA<CustomerCatalogNotConfiguredFailure>()),
          );
          expect(
            customerCatalogErrorTitle(
              const CustomerCatalogNotConfiguredFailure(),
            ),
            'Layanan katalog belum terhubung',
          );
          expect(
            customerCatalogErrorTitle(const CustomerCatalogNetworkFailure()),
            'Koneksi katalog terputus',
          );
        },
      );

      test(
        'CustomerCatalogMapper memetakan katalog valid dan menolak data harga negatif',
        () async {
          const menuModel = MenuItemModel(
            id: 'menu-1',
            name: 'Mie Goreng Spesial',
            stallId: 'stall-1',
            stallName: 'Stan Nusantara',
            block: 'Blok A',
            price: 18000,
            waitTime: '10 menit',
            description: 'Mie goreng telur',
            category: 'Mie',
            available: true,
            imageUrl:
                'https://cdn.kantincerdas.ac.id/owner-1_menu_photo_12345678.jpg',
          );
          final validModel = CustomerCatalogModel(
            stalls: [
              StallModel(
                id: 'stall-1',
                name: 'Stan Nusantara',
                block: 'Blok A',
                waitTime: '10 menit',
                description: 'Aneka masakan lokal',
                menus: const [menuModel],
                isOpen: true,
                imageUrl:
                    'https://cdn.kantincerdas.ac.id/owner-1_stall_photo_12345678.webp',
              ),
            ],
            menus: const [menuModel],
          );

          final entity = validModel.toEntity();
          expect(entity.menus.single.category, 'Mi');
          expect(
            entity.menus.single.imageUrl,
            'https://cdn.kantincerdas.ac.id/owner-1_menu_photo_12345678.jpg',
          );
          expect(entity.stalls.single.name, 'Stan Nusantara');
          expect(
            entity.stalls.single.imageUrl,
            'https://cdn.kantincerdas.ac.id/owner-1_stall_photo_12345678.webp',
          );
          expect(
            entity.stallById('stall-1')?.imageUrl,
            'https://cdn.kantincerdas.ac.id/owner-1_stall_photo_12345678.webp',
          );

          final invalidRepo = CustomerCatalogRepositoryImpl(
            dataSource: _StubCatalogDataSource(
              () async => CustomerCatalogModel(
                stalls: const [],
                menus: const [
                  MenuItemModel(
                    id: 'menu-bad',
                    name: 'Nasi Goreng',
                    stallId: 'stall-1',
                    stallName: 'Stan Nusantara',
                    block: 'Blok A',
                    price: -5000,
                    waitTime: '10 menit',
                    description: 'Pedas',
                    category: 'Nasi',
                    available: true,
                  ),
                ],
              ),
            ),
          );

          await expectLater(
            invalidRepo.getCatalog(),
            throwsA(isA<CustomerCatalogUnexpectedFailure>()),
          );
        },
      );
    },
  );

  group('CustomerOrderRepositoryImpl & DTO/Repository Lainnya (CRIT-01, LOW-03)', () {
    test(
      'CustomerOrderRepositoryImpl memvalidasi konfirmasi harga dan meneruskan idempotency submissionId',
      () async {
        final draft = OrderDraft(
          stallId: 'stall-1',
          items: [OrderDraftItem(menuId: 'm-1', quantity: 2)],
        );
        final confirmation = CustomerOrderPriceConfirmation(
          draft: draft,
          unitPricesIdr: const {'m-1': 20000},
        );

        String? capturedSubmissionId;
        final repo = CustomerOrderRepositoryImpl(
          dataSource: _StubCustomerOrderDataSource(
            onCreateOrder: (d, submissionId, c) async {
              capturedSubmissionId = submissionId;
              return 'ord-created-1';
            },
          ),
        );

        final orderId = await repo.createOrder(
          draft: draft,
          submissionId: 'sub-idempotent-001',
          confirmation: confirmation,
        );
        expect(orderId, 'ord-created-1');
        expect(capturedSubmissionId, 'sub-idempotent-001');

        await expectLater(
          repo.createOrder(
            draft: draft,
            submissionId: '   ',
            confirmation: confirmation,
          ),
          throwsA(isA<CustomerOrderPreSendFailure>()),
        );
      },
    );

    test(
      'OrderRecordModel, OwnerMenuModel, AdminSummaryModel, dan FoodPreferencesSnapshotModel memvalidasi JSON ke Entity',
      () {
        final orderModel = OrderRecordModel.fromJson(<String, Object?>{
          'id': 'ord-1',
          'order_number': 'KC-101',
          'customer_id': 'cust-1',
          'customer_name': 'Doni',
          'stall_id': 'stall-1',
          'stall_name': 'Kantin Nusantara',
          'status': 'waiting',
          'payment_status': 'unpaid',
          'total_price_idr': 25000,
          'note': 'Tanpa bawang',
          'created_at': '2026-11-02T01:00:00Z',
          'updated_at': '2026-11-02T01:00:00Z',
          'version': 1,
          'items': <Object?>[
            <String, Object?>{
              'menu_id': 'm-1',
              'name': 'Mi Goreng',
              'quantity': 1,
              'unit_price_idr': 25000,
              'note': '',
            },
          ],
        });
        final orderEntity = orderModel.toEntity();
        expect(orderEntity.id, 'ord-1');
        expect(orderEntity.status, OrderStatus.waiting);
        expect(orderEntity.totalPriceIdr, 25000);

        final ownerMenu = OwnerMenuModel.fromJson(<String, Object?>{
          'id': 'm-1',
          'stall_id': 'stall-1',
          'name': 'Mie Aceh',
          'description': 'Rempah khas',
          'category': 'Mie',
          'price_idr': 20000,
          'is_available': true,
          'version': 2,
        }).toEntity();
        expect(ownerMenu.category.label, 'Mi');

        final summary = AdminSummaryModel.fromJson(<String, Object?>{
          'users': 12,
          'stalls': 4,
          'open_stalls': 3,
          'pending_applications': 1,
          'active_orders': 5,
        }).toEntity();
        expect(summary.openStalls, 3);

        final prefs = FoodPreferencesSnapshotModel.fromJson(<String, Object?>{
          'customer_id': 'cust-1',
          'version': 1,
          'max_budget_idr': 30000,
          'vegetarian': false,
          'avoid_ingredients': <Object?>['udang'],
        }).toEntity();
        expect(prefs.preferences.avoidIngredients, const ['udang']);
      },
    );

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
      '5 DTO Lookup Mutasi baru, prep_time_min, normalisasi string kosong, dan validasi UTC ketat (CRIT-NEW-01, HIGH-NEW-02, PROD-NEW-08..09)',
      () {
        final adminLookup = AdminMutationLookupModel.fromJson(<String, Object?>{
          'mutation_id': 'adm-mut-1',
          'actor_id': 'admin-1',
          'kind': 'change_access',
          'target_id': 'usr-1',
          'expected_version': 2,
          'reason': 'Penonaktifan akun uji',
          'is_active': false,
          'target_role': 'customer',
          'outcome': 'applied',
          'result_version': 3,
          'result_is_active': false,
          'result_role': 'customer',
        }).toEntity();
        expect(adminLookup.request.mutationId, 'adm-mut-1');
        expect(adminLookup.resultVersion, 3);
        expect(adminLookup.isActive, isFalse);

        final ownerLookup = OwnerMutationLookupModel.fromJson(<String, Object?>{
          'mutation_id': 'own-mut-1',
          'owner_id': 'owner-1',
          'stall_id': 'stall-1',
          'kind': 'delete_menu',
          'target_id': 'm-1',
          'expected_version': 4,
          'outcome': 'not_applied',
        }).toEntity();
        expect(ownerLookup.outcome, OwnerMutationOutcome.notApplied);

        final appLookup = CanteenApplicationLookupModel.fromJson(
          <String, Object?>{
            'customer_id': 'cust-1',
            'submission_id': 'sub-app-1',
            'status': 'submitted',
            'receipt': <String, Object?>{
              'id': 'app-1',
              'applicant_id': 'cust-1',
              'name': 'Warung Cerdas',
              'description': 'Aneka masakan soto higienis',
              'location': 'Blok B',
              'phone': '081234567890',
              'status': 'submitted',
              'reason': '   ',
              'created_at': '2026-11-02T01:00:00Z',
              'version': 1,
            },
          },
        ).toEntity();
        expect(appLookup.status, CanteenApplicationSubmissionStatus.submitted);
        expect(appLookup.receipt?.reason, isNull);

        final cancelLookup =
            OrderCancellationLookupModel.fromJson(<String, Object?>{
              'mutation_id': 'cancel-1',
              'customer_id': 'cust-1',
              'stall_id': 'stall-1',
              'order_number': 'KC-101',
              'order_id': 'ord-1',
              'expected_version': 1,
              'status': 'not_cancelled',
            }).toEntity();
        expect(cancelLookup.outcome, OrderCancellationOutcome.notApplied);

        final prefsLookup = FoodPreferencesLookupModel.fromJson(
          <String, Object?>{
            'mutation_id': 'pref-1',
            'customer_id': 'cust-1',
            'expected_version': 1,
            'max_budget_idr': 25000,
            'vegetarian': true,
            'avoid_ingredients': <Object?>['cabai'],
            'status': 'saved',
            'saved': <String, Object?>{
              'customer_id': 'cust-1',
              'version': 2,
              'max_budget_idr': 25000,
              'vegetarian': true,
              'avoid_ingredients': <Object?>['cabai'],
            },
          },
        ).toEntity();
        expect(prefsLookup.outcome, FoodPreferencesOutcome.applied);
        expect(prefsLookup.snapshot?.version, 2);

        // prep_time_min (int -> "$min mnt")
        final stallFromPrepMin = StallModel.fromJson(<String, Object?>{
          'id': 's-1',
          'name': 'Stan Cepat',
          'block': 'Blok A',
          'prep_time_min': 12,
          'description': 'Cepat saji',
          'is_open': true,
          'menus': <Object?>[],
        });
        expect(stallFromPrepMin.waitTime, '12 mnt');

        // Timestamp tanpa zona waktu eksplisit ditolak
        expect(
          () => CanteenApplicationModel.fromJson(<String, Object?>{
            'id': 'app-1',
            'applicant_id': 'cust-1',
            'name': 'Warung Cerdas',
            'description': 'Aneka masakan soto higienis',
            'location': 'Blok B',
            'phone': '081234567890',
            'status': 'submitted',
            'created_at': '2026-11-02T01:00:00',
            'version': 1,
          }).toEntity(),
          throwsA(isA<DataParsingException>()),
        );
      },
    );

    test(
      'proteksi error HTML reverse-proxy (hasBackendErrorCode == false) tidak dianggap definitif atau null (PROD-NEW-06)',
      () async {
        // Error 409 HTML proxy tanpa kode error backend tidak boleh dipetakan ke OwnerConflictFailure
        final proxyConflict = mapOwnerMutationApiException(
          ApiException(type: ApiExceptionType.response, statusCode: 409),
        );
        expect(proxyConflict, isA<OwnerUnconfirmedFailure>());

        // Error 404 HTML proxy pada lookup pengajuan tetap menjadi UnconfirmedFailure
        final appRepo = CanteenApplicationRepositoryImpl(
          dataSource: _StubCanteenApplicationDataSource(
            onGetMy: () async => throw ApiException(
              type: ApiExceptionType.response,
              statusCode: 404,
            ),
            onLookup: (_) async => throw ApiException(
              type: ApiExceptionType.response,
              statusCode: 404,
              code: 'NOT_FOUND',
            ),
          ),
        );
        await expectLater(
          appRepo.getMyApplication(),
          throwsA(isA<CustomerFeatureInvalidDataFailure>()),
        );
        await expectLater(
          appRepo.lookupSubmission(submissionId: 'sub-404'),
          throwsA(isA<CanteenApplicationUnconfirmedFailure>()),
        );
      },
    );

    test(
      'pemetaan HTTP 429 dan 5xx pada mappers baca menghasilkan *ReadTimeoutFailure dan createOrder memetakan ApiException secara akurat',
      () async {
        for (final statusCode in <int>[429, 500, 502, 503]) {
          final err = ApiException(
            type: ApiExceptionType.response,
            statusCode: statusCode,
          );
          expect(
            mapCustomerReadApiException(err),
            isA<CustomerFeatureReadTimeoutFailure>(),
          );
          expect(
            mapFoodPreferencesReadApiException(err),
            isA<FoodPreferencesReadTimeoutFailure>(),
          );
          expect(mapOwnerReadApiException(err), isA<OwnerReadTimeoutFailure>());
          expect(mapAdminReadApiException(err), isA<AdminReadTimeoutFailure>());
        }

        final draft = OrderDraft(
          stallId: 'stall-1',
          items: [OrderDraftItem(menuId: 'm-1', quantity: 1)],
        );
        final confirmation = CustomerOrderPriceConfirmation(
          draft: draft,
          unitPricesIdr: const {'m-1': 15000},
        );

        final repo404Backend = CustomerOrderRepositoryImpl(
          dataSource: _StubCustomerOrderDataSource(
            onCreateOrder: (d, submissionId, c) async => throw ApiException(
              type: ApiExceptionType.response,
              statusCode: 404,
              code: 'STALL_NOT_FOUND',
            ),
          ),
        );
        await expectLater(
          repo404Backend.createOrder(
            draft: draft,
            submissionId: 'sub-404-backend',
            confirmation: confirmation,
          ),
          throwsA(isA<CustomerOrderRejectedFailure>()),
        );

        final repo404Proxy = CustomerOrderRepositoryImpl(
          dataSource: _StubCustomerOrderDataSource(
            onCreateOrder: (d, submissionId, c) async => throw ApiException(
              type: ApiExceptionType.response,
              statusCode: 404,
            ),
          ),
        );
        await expectLater(
          repo404Proxy.createOrder(
            draft: draft,
            submissionId: 'sub-404-proxy',
            confirmation: confirmation,
          ),
          throwsA(isA<CustomerOrderUnconfirmedFailure>()),
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

class _StubCanteenApplicationDataSource
    implements CanteenApplicationDataSource {
  const _StubCanteenApplicationDataSource({
    required this.onGetMy,
    required this.onLookup,
  });

  final Future<CanteenApplicationModel?> Function() onGetMy;
  final Future<CanteenApplicationLookup> Function(String submissionId) onLookup;

  @override
  bool get isSubmissionConfigured => true;

  @override
  Future<CanteenApplicationModel?> getMyApplication() => onGetMy();

  @override
  Future<CanteenApplicationModel> submit(
    PendingCanteenApplication submission,
  ) => throw UnimplementedError();

  @override
  Future<CanteenApplicationLookup> lookupSubmission({
    required String submissionId,
  }) => onLookup(submissionId);
}

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
