import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kantin_cerdas_backend/src/app/bootstrap.dart';
import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_client_factory.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/data/supabase_admin_store.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/domain/admin_errors.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/domain/admin_store.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/avatar_store.dart';
import 'package:kantin_cerdas_backend/src/modules/catalog/domain/catalog_store.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/domain/customer_store.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/domain/owner_store.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../../config_test.dart' show validEnvironment;

const _adminId = '11111111-1111-1111-1111-111111111111';
const _admin2Id = '22222222-2222-2222-2222-222222222222';
const _custId = '33333333-3333-3333-3333-333333333333';
const _ownerId = '44444444-4444-4444-4444-444444444444';
const _appId = '55555555-5555-5555-5555-555555555555';
const _stallId = '66666666-6666-6666-6666-666666666666';

void main() {
  late _FakeAuthGateway auth;
  late _FakeAvatarStore avatars;
  late _FakeMediaStore media;
  late _FakeAdminStore adminStore;
  late Handler app;

  setUp(() {
    final config = AppConfig.fromEnv(
      EnvConfig.fromMap(
        validEnvironment(
          overrides: {
            'RATE_LIMIT_ENABLED': 'false',
            'LOG_REQUEST_ENABLED': 'false',
          },
        ),
      ),
    );
    auth = _FakeAuthGateway();
    avatars = _FakeAvatarStore();
    media = _FakeMediaStore();
    adminStore = _FakeAdminStore();
    app = buildAppHandlerWithAllModules(
      config,
      authGateway: auth,
      avatarStore: avatars,
      catalogStore: _StubCatalogStore(),
      ownerStore: _StubOwnerStore(),
      ownerMediaStore: media,
      customerStore: _StubCustomerStore(),
      adminStore: adminStore,
    );
  });

  test(
    'enforces active admin role, bearer auth, and complete profile',
    () async {
      expect((await _send(app, 'GET', '/admin/dashboard')).statusCode, 401);

      avatars.hasAvatar[_adminId] = false;
      final incomplete = await _send(
        app,
        'GET',
        '/admin/dashboard',
        bearer: 'tok-admin1',
      );
      expect(incomplete.statusCode, 409);

      final custRes = await _send(
        app,
        'GET',
        '/admin/dashboard',
        bearer: 'tok-cust',
      );
      expect(custRes.statusCode, 403);
      expect(await _errorCode(custRes), 'ADMIN_ROLE_REQUIRED');

      final ownerRes = await _send(
        app,
        'GET',
        '/admin/dashboard',
        bearer: 'tok-owner',
      );
      expect(ownerRes.statusCode, 403);
      expect(await _errorCode(ownerRes), 'ADMIN_ROLE_REQUIRED');
    },
  );

  test(
    'dashboard & applications workflow respects ADMIN-001/002/005',
    () async {
      final dash = await _send(
        app,
        'GET',
        '/admin/dashboard',
        bearer: 'tok-admin1',
      );
      expect(dash.statusCode, 200);
      expect((await _data(dash))['pending_applications'], 1);

      final badScope = await _send(
        app,
        'GET',
        '/admin/applications?scope=invalid',
        bearer: 'tok-admin1',
      );
      expect(badScope.statusCode, 400);

      final listRes = await _send(
        app,
        'GET',
        '/admin/applications?scope=pending',
        bearer: 'tok-admin1',
      );
      expect(listRes.statusCode, 200);
      expect(((await _data(listRes))['items'] as List).length, 1);

      // Reject without reason fails 422 REASON_REQUIRED.
      final noReason = await _send(
        app,
        'POST',
        '/admin/applications/$_appId/review',
        bearer: 'tok-admin1',
        body: {'decision': 'ditolak', 'rejection_reason': '   '},
      );
      expect(noReason.statusCode, 422);
      expect(await _errorCode(noReason), 'REASON_REQUIRED');

      // Approve when applicant has active orders -> 409 ACTIVE_ORDERS_PRESENT.
      adminStore.custActiveOrders = 1;
      final blockedApprove = await _send(
        app,
        'POST',
        '/admin/applications/$_appId/review',
        bearer: 'tok-admin1',
        body: {'decision': 'disetujui'},
      );
      expect(blockedApprove.statusCode, 409);
      expect(await _errorCode(blockedApprove), 'ACTIVE_ORDERS_PRESENT');

      // Once orders clear -> approve succeeds.
      adminStore.custActiveOrders = 0;
      final approveRes = await _send(
        app,
        'POST',
        '/admin/applications/$_appId/review',
        bearer: 'tok-admin1',
        body: {'decision': 'disetujui'},
      );
      expect(approveRes.statusCode, 200);
      expect((await _data(approveRes))['status'], 'disetujui');
      expect(adminStore.userRoles[_custId], 'owner');
    },
  );

  test(
    'user activation/deactivation enforces reason, active orders, and last-admin protection',
    () async {
      // Self-deactivation blocked.
      final selfDeact = await _send(
        app,
        'POST',
        '/admin/users/$_adminId/status',
        bearer: 'tok-admin1',
        body: {'is_active': false, 'reason': 'Uji mandiri'},
      );
      expect(selfDeact.statusCode, 409);
      expect(await _errorCode(selfDeact), 'SELF_DEACTIVATION_NOT_ALLOWED');

      // Deactivate without reason fails 422 REASON_REQUIRED.
      final missingReason = await _send(
        app,
        'POST',
        '/admin/users/$_custId/status',
        bearer: 'tok-admin1',
        body: {'is_active': false, 'reason': ''},
      );
      expect(missingReason.statusCode, 422);
      expect(await _errorCode(missingReason), 'REASON_REQUIRED');

      // Active orders block customer deactivation (409).
      adminStore.custActiveOrders = 2;
      final blockedCust = await _send(
        app,
        'POST',
        '/admin/users/$_custId/status',
        bearer: 'tok-admin1',
        body: {'is_active': false, 'reason': 'Pelanggaran aturan'},
      );
      expect(blockedCust.statusCode, 409);
      expect(await _errorCode(blockedCust), 'ACTIVE_ORDERS_PRESENT');

      // Reactivate & deactivate clean flow + audit log visibility.
      adminStore.custActiveOrders = 0;
      final deactCust = await _send(
        app,
        'POST',
        '/admin/users/$_custId/status',
        bearer: 'tok-admin1',
        body: {'is_active': false, 'reason': 'Audit akun'},
      );
      expect(deactCust.statusCode, 200);
      expect((await _data(deactCust))['is_active'], false);

      final reactCust = await _send(
        app,
        'POST',
        '/admin/users/$_custId/status',
        bearer: 'tok-admin1',
        body: {'is_active': true},
      );
      expect(reactCust.statusCode, 200);
      expect((await _data(reactCust))['is_active'], true);

      final logs = await _send(
        app,
        'GET',
        '/admin/action-logs?target_user_id=$_custId',
        bearer: 'tok-admin1',
      );
      expect(logs.statusCode, 200);
      expect(((await _data(logs))['items'] as List).length, 2);

      // No account delete route exists (ADMIN-003).
      final deleteRes = await _send(
        app,
        'DELETE',
        '/admin/users/$_custId',
        bearer: 'tok-admin1',
      );
      expect(deleteRes.statusCode, 404);
    },
  );

  test(
    'stalls monitoring is strictly read-only and maps Postgrest errors',
    () async {
      final list = await _send(
        app,
        'GET',
        '/admin/stalls',
        bearer: 'tok-admin1',
      );
      expect(list.statusCode, 200);
      expect(((await _data(list))['items'] as List).length, 1);

      final detail = await _send(
        app,
        'GET',
        '/admin/stalls/$_stallId',
        bearer: 'tok-admin1',
      );
      expect(detail.statusCode, 200);
      expect((await _data(detail))['name'], 'Kantin Read Only');

      final noPhoto = await _send(
        app,
        'GET',
        '/admin/stalls/$_stallId/photo',
        bearer: 'tok-admin1',
      );
      expect(noPhoto.statusCode, 204);

      // Zero mutation routes on stalls or orders under /v1/admin/.
      final mutateStall = await _send(
        app,
        'PATCH',
        '/admin/stalls/$_stallId',
        bearer: 'tok-admin1',
        body: {'is_open': false},
      );
      expect(mutateStall.statusCode, 404);

      final rpcStore = SupabaseAdminStore(
        SupabaseClientFactory(
          config: AppConfig.fromEnv(
            EnvConfig.fromMap(validEnvironment()),
          ).supabase,
        ),
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'code': 'P0001',
              'details': 'KC_LAST_ADMIN_PROTECTED',
              'hint': null,
              'message': 'KC_LAST_ADMIN_PROTECTED',
            }),
            400,
            headers: {'content-type': 'application/json'},
            request: request,
          ),
        ),
      );
      await expectLater(
        () => rpcStore.setUserActiveStatus(
          _adminId,
          targetUserId: _admin2Id,
          isActive: false,
          reason: 'Uji last admin',
        ),
        throwsA(
          isA<AdminFailure>().having(
            (f) => f.code,
            'code',
            AdminFailureCode.lastAdminProtected,
          ),
        ),
      );
    },
  );
}

Future<Response> _send(
  Handler handler,
  String method,
  String path, {
  String? bearer,
  Object? body,
}) async {
  final headers = <String, String>{'host': 'api.example.test'};
  if (bearer != null) headers['authorization'] = 'Bearer $bearer';
  String? encoded;
  if (body != null) {
    headers['content-type'] = 'application/json';
    encoded = jsonEncode(body);
  }
  return await handler(
    Request(
      method,
      Uri.parse('https://api.example.test/v1$path'),
      headers: headers,
      body: encoded,
    ),
  );
}

Future<Map<String, dynamic>> _data(Response response) async {
  final body =
      jsonDecode(await response.readAsString()) as Map<String, dynamic>;
  return body['data'] as Map<String, dynamic>;
}

Future<String?> _errorCode(Response response) async {
  final body =
      jsonDecode(await response.readAsString()) as Map<String, dynamic>;
  return (body['error'] as Map<String, dynamic>?)?['code'] as String?;
}

class _FakeAuthGateway implements AuthGateway {
  @override
  Future<AuthAccount> account(String accessToken) async {
    return switch (accessToken) {
      'tok-admin1' => const AuthAccount(
        id: _adminId,
        email: 'admin1@example.com',
        role: AccountRole.admin,
        displayName: 'Admin Satu',
      ),
      'tok-cust' => const AuthAccount(
        id: _custId,
        email: 'cust@example.com',
        role: AccountRole.customer,
        displayName: 'Cust Satu',
      ),
      'tok-owner' => const AuthAccount(
        id: _ownerId,
        email: 'owner@example.com',
        role: AccountRole.owner,
        displayName: 'Owner Satu',
      ),
      _ => throw AuthFailure.invalidSession,
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAvatarStore implements AvatarStore {
  final Map<String, bool> hasAvatar = {
    _adminId: true,
    _custId: true,
    _ownerId: true,
  };

  @override
  Future<bool> exists(String userId) async => hasAvatar[userId] ?? false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMediaStore implements OwnerMediaStore {
  @override
  Future<Uint8List?> read(String objectPath) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubCatalogStore implements CatalogStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubOwnerStore implements OwnerStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StubCustomerStore implements CustomerStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAdminStore implements AdminStore {
  int custActiveOrders = 0;
  String appStatus = 'menunggu_review';
  String? appRejectionReason;
  final Map<String, bool> activeUsers = {
    _adminId: true,
    _admin2Id: true,
    _custId: true,
    _ownerId: true,
  };
  final Map<String, String> userRoles = {
    _adminId: 'admin',
    _admin2Id: 'admin',
    _custId: 'customer',
    _ownerId: 'owner',
  };
  final List<Map<String, Object?>> logs = [];

  @override
  Future<Map<String, Object?>> getDashboard(String adminId) async => {
    'total_users': activeUsers.length,
    'active_users': activeUsers.values.where((e) => e).length,
    'inactive_users': activeUsers.values.where((e) => !e).length,
    'pending_applications': appStatus == 'menunggu_review' ? 1 : 0,
    'total_stalls': 1,
    'published_stalls': 1,
    'open_stalls': 1,
    'recent_pending_applications': appStatus == 'menunggu_review'
        ? [
            {
              'id': _appId,
              'customer_id': _custId,
              'applicant_name': 'Cust Satu',
              'applicant_email': 'cust@example.com',
              'planned_stall_name': 'Warung Baru',
              'planned_location': 'Blok C',
              'status': 'menunggu_review',
              'created_at': '2026-11-21T10:00:00Z',
            },
          ]
        : [],
  };

  @override
  Future<Map<String, Object?>> listApplications(
    String adminId, {
    required String scope,
    required int limit,
    required int offset,
  }) async => {
    'items': [await getApplication(adminId, applicationId: _appId)],
    'scope': scope,
    'limit': limit,
    'offset': offset,
  };

  @override
  Future<Map<String, Object?>> getApplication(
    String adminId, {
    required String applicationId,
  }) async => {
    'id': _appId,
    'customer_id': _custId,
    'applicant_name': 'Cust Satu',
    'applicant_email': 'cust@example.com',
    'applicant_role': userRoles[_custId],
    'applicant_is_active': activeUsers[_custId],
    'planned_stall_name': 'Warung Baru',
    'planned_location': 'Blok C',
    'reason': 'Siap berjualan',
    'status': appStatus,
    'rejection_reason': appRejectionReason,
    'decided_by': appStatus == 'menunggu_review' ? null : adminId,
    'decided_by_name': appStatus == 'menunggu_review' ? null : 'Admin Satu',
    'decided_at': appStatus == 'menunggu_review'
        ? null
        : '2026-11-21T10:05:00Z',
    'created_at': '2026-11-21T10:00:00Z',
    'active_order_indicator': {
      'user_id': _custId,
      'has_active_orders': custActiveOrders > 0,
      'active_order_count': custActiveOrders,
    },
  };

  @override
  Future<Map<String, Object?>> reviewApplication(
    String adminId, {
    required String applicationId,
    required String decision,
    String? rejectionReason,
  }) async {
    if (decision == 'disetujui' && custActiveOrders > 0) {
      throw const AdminFailure(AdminFailureCode.activeOrdersPresent);
    }
    appStatus = decision;
    appRejectionReason = decision == 'ditolak' ? rejectionReason : null;
    if (decision == 'disetujui') {
      userRoles[_custId] = 'owner';
    }
    logs.add({
      'id': 'log-${logs.length + 1}',
      'admin_id': adminId,
      'admin_name': 'Admin Satu',
      'action_type': decision == 'disetujui'
          ? 'application_approved'
          : 'application_rejected',
      'target_user_id': _custId,
      'target_user_name': 'Cust Satu',
      'target_application_id': _appId,
      'reason': appRejectionReason,
      'summary': decision == 'disetujui'
          ? 'Pengajuan Owner disetujui'
          : 'Pengajuan Owner ditolak',
      'created_at': '2026-11-21T10:05:00Z',
    });
    return getApplication(adminId, applicationId: applicationId);
  }

  @override
  Future<Map<String, Object?>> listUsers(
    String adminId, {
    String? role,
    String? status,
    String? query,
    required int limit,
    required int offset,
  }) async => {'items': [], 'limit': limit, 'offset': offset};

  @override
  Future<Map<String, Object?>> getUser(
    String adminId, {
    required String userId,
  }) async => {
    'id': userId,
    'email': 'cust@example.com',
    'display_name': 'Cust Satu',
    'role': userRoles[userId] ?? 'customer',
    'is_active': activeUsers[userId] ?? true,
    'email_verified': true,
    'created_at': '2026-11-21T09:00:00Z',
    'active_order_indicator': {
      'user_id': userId,
      'has_active_orders': userId == _custId && custActiveOrders > 0,
      'active_order_count': userId == _custId ? custActiveOrders : 0,
    },
    'recent_logs': logs.where((l) => l['target_user_id'] == userId).toList(),
  };

  @override
  Future<Map<String, Object?>> setUserActiveStatus(
    String adminId, {
    required String targetUserId,
    required bool isActive,
    String? reason,
  }) async {
    if (!isActive && targetUserId == _custId && custActiveOrders > 0) {
      throw const AdminFailure(AdminFailureCode.activeOrdersPresent);
    }
    activeUsers[targetUserId] = isActive;
    logs.add({
      'id': 'log-${logs.length + 1}',
      'admin_id': adminId,
      'admin_name': 'Admin Satu',
      'action_type': isActive ? 'user_reactivated' : 'user_deactivated',
      'target_user_id': targetUserId,
      'target_user_name': 'Cust Satu',
      'target_application_id': null,
      'reason': reason,
      'summary': isActive
          ? 'Akun diaktifkan kembali Admin'
          : 'Akun dinonaktifkan Admin',
      'created_at': '2026-11-21T10:10:00Z',
    });
    return getUser(adminId, userId: targetUserId);
  }

  @override
  Future<Map<String, Object?>> listStalls(
    String adminId, {
    String? query,
    required int limit,
    required int offset,
  }) async => {
    'items': [await getStall(adminId, stallId: _stallId)],
    'limit': limit,
    'offset': offset,
  };

  @override
  Future<Map<String, Object?>> getStall(
    String adminId, {
    required String stallId,
  }) async => {
    'id': _stallId,
    'name': 'Kantin Read Only',
    'campus': 'USU',
    'block': 'Blok A',
    'description': 'Deskripsi',
    'wait_minutes': 10,
    'is_listed': true,
    'is_open': true,
    'has_photo': false,
    'owner_id': _ownerId,
    'owner_name': 'Owner Satu',
    'owner_email': 'owner@example.com',
    'owner_is_active': true,
    'schedules': [],
    'updated_at': '2026-11-21T10:00:00Z',
  };

  @override
  Future<String?> getStallPhotoPath(
    String adminId, {
    required String stallId,
  }) async => null;

  @override
  Future<Map<String, Object?>> listActionLogs(
    String adminId, {
    String? targetUserId,
    required int limit,
    required int offset,
  }) async => {
    'items': targetUserId == null
        ? logs
        : logs.where((l) => l['target_user_id'] == targetUserId).toList(),
    'limit': limit,
    'offset': offset,
  };
}
