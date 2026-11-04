import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/features/admin/data/datasources/admin_api_datasource.dart';
import 'package:kantin_cerdas/features/admin/data/mappers/admin_failure_mapper.dart';
import 'package:kantin_cerdas/features/admin/data/models/admin_models.dart';
import 'package:kantin_cerdas/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:kantin_cerdas/features/admin/domain/failures/admin_failure.dart';
import 'package:kantin_cerdas/features/auth/data/datasources/auth_datasource.dart';
import 'package:kantin_cerdas/features/auth/data/mappers/auth_failure_mapper.dart';
import 'package:kantin_cerdas/features/auth/data/models/login_response_model.dart';
import 'package:kantin_cerdas/features/auth/data/models/user_model.dart';
import 'package:kantin_cerdas/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:kantin_cerdas/features/auth/data/storage/auth_tokens.dart';
import 'package:kantin_cerdas/features/auth/data/storage/secure_token_storage.dart';
import 'package:kantin_cerdas/features/auth/data/storage/token_storage.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';
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

class _MemoryTokenStorage implements TokenStorage {
  _MemoryTokenStorage([this.stored]);

  AuthTokens? stored;
  int clearCount = 0;

  @override
  Future<AuthTokens?> read() async => stored;

  @override
  Future<void> save(AuthTokens tokens) async {
    stored = tokens;
  }

  @override
  Future<void> clear() async {
    clearCount++;
    stored = null;
  }
}

class _StubAuthDataSource implements AuthDataSource {
  const _StubAuthDataSource({
    this.onLogin,
    this.onRefreshSession,
    this.onLogout,
  });

  final Future<LoginResponseModel> Function(String identifier, String password)?
  onLogin;
  final Future<LoginResponseModel> Function(String refreshToken)?
  onRefreshSession;
  final Future<void> Function(String accessToken, String? refreshToken)?
  onLogout;

  @override
  Future<LoginResponseModel> login({
    required String identifier,
    required String password,
  }) => onLogin!(identifier, password);

  @override
  Future<UserModel> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<void> requestPasswordReset({required String email}) =>
      throw UnimplementedError();

  @override
  Future<UserModel> getCurrentUser({required String accessToken}) =>
      throw UnimplementedError();

  @override
  Future<LoginResponseModel> refreshSession({required String refreshToken}) =>
      onRefreshSession!(refreshToken);

  @override
  Future<void> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) => throw UnimplementedError();

  @override
  Future<UserModel> updateProfileAvatar({
    required String accessToken,
    required String? avatarUrl,
  }) => throw UnimplementedError();

  @override
  Future<void> logout({required String accessToken, String? refreshToken}) =>
      onLogout != null
      ? onLogout!(accessToken, refreshToken)
      : Future<void>.value();
}

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
        final tokenStorage = _MemoryTokenStorage();
        final expiry = DateTime.now().toUtc().add(const Duration(hours: 1));
        final repo = AuthRepositoryImpl(
          tokenStorage: tokenStorage,
          dataSource: _StubAuthDataSource(
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
        final tokenStorage = _MemoryTokenStorage(
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
          dataSource: _StubAuthDataSource(
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
        final tokenStorage = _MemoryTokenStorage(
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
          dataSource: _StubAuthDataSource(
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
        final tokenStorage = _MemoryTokenStorage(
          const AuthTokens(accessToken: 'acc-active', refreshToken: 'ref-1'),
        );
        final repo = AuthRepositoryImpl(
          tokenStorage: tokenStorage,
          dataSource: _StubAuthDataSource(
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
              ),
            ],
            menus: const [menuModel],
          );

          final entity = validModel.toEntity();
          expect(entity.menus.single.category, 'Mi');
          expect(entity.stalls.single.name, 'Stan Nusantara');

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
