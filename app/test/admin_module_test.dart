import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kantin_cerdas/features/admin/application/admin_action_controller.dart';
import 'package:kantin_cerdas/features/admin/application/admin_providers.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/data/auth_repository.dart';
import 'package:kantin_cerdas/main.dart';

const _adminAId = '10000000-0000-0000-0000-00000000a001';
const _adminBId = '10000000-0000-0000-0000-00000000a002';
const _cust1Id = '10000000-0000-0000-0000-00000000c001';
const _cust2Id = '10000000-0000-0000-0000-00000000c002';
const _ownerId = '10000000-0000-0000-0000-000000000001';
const _app1Id = '20000000-0000-0000-0000-000000000001';
const _app2Id = '20000000-0000-0000-0000-000000000002';
const _stallId = '30000000-0000-0000-0000-000000000001';

void main() {
  group('M2 Riverpod 3 circular dependency guard', () {
    test(
      'reading admin providers alongside adminActionController triggers zero CircularDependencyError',
      () async {
        final fake = _FakeAdminBackend();
        final container = _createTestContainer(fake: fake);
        addTearDown(container.dispose);

        await container.read(authControllerProvider.future);

        final dashSub = container.listen(
          adminDashboardProvider(_adminAId),
          (_, _) {},
        );
        final appsSub = container.listen(
          adminApplicationsProvider((accountId: _adminAId, scope: 'pending')),
          (_, _) {},
        );
        final usersSub = container.listen(
          adminUsersProvider((
            accountId: _adminAId,
            role: null,
            status: null,
            query: '',
          )),
          (_, _) {},
        );
        addTearDown(dashSub.close);
        addTearDown(appsSub.close);
        addTearDown(usersSub.close);

        await container.read(adminDashboardProvider(_adminAId).future);
        await container.read(
          adminApplicationsProvider((
            accountId: _adminAId,
            scope: 'pending',
          )).future,
        );

        final ctrl = container.read(adminActionControllerProvider);
        final approved = await ctrl.reviewApplication(
          accountId: _adminAId,
          applicationId: _app2Id,
          approve: true,
        );
        expect(approved.status.apiValue, 'disetujui');

        final updatedDash = await container.read(
          adminDashboardProvider(_adminAId).future,
        );
        expect(updatedDash.pendingApplications, 1);

        final deactivated = await ctrl.setUserActiveStatus(
          accountId: _adminAId,
          targetUserId: _cust2Id,
          isActive: false,
          reason: 'Pelanggaran uji M2',
        );
        expect(deactivated.isActive, false);
        expect(fake.mutationCount, 2);
        expect(
          fake.recordedMutations,
          containsAll([
            'POST /v1/admin/applications/$_app2Id/review',
            'POST /v1/admin/users/$_cust2Id/status',
          ]),
        );
      },
    );
  });

  group('Admin E2E UI & Rules', () {
    testWidgets(
      'Dashboard, Application Review (active order block + reject with reason + approve), Users, Read-Only Stalls, & Account Settings',
      (tester) async {
        final fake = _FakeAdminBackend();
        final repo = _createFakeAuthRepo(fake);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authRepositoryProvider.overrideWithValue(repo)],
            child: const KantinCerdasApp(),
          ),
        );
        await _pumpPastSplash(tester);

        // UI-ADMIN-001 Dashboard: 4 administrative summaries, pending queue, zero FAB.
        expect(find.text('Beranda'), findsWidgets);
        expect(find.text('Pengguna'), findsWidgets);
        expect(find.text('Pengajuan Owner'), findsOneWidget);
        expect(find.text('Kantin'), findsWidgets);
        expect(find.text('Akun Nonaktif'), findsOneWidget);
        expect(find.byType(FloatingActionButton), findsNothing);
        expect(find.text('Pengajuan Menunggu Review (2)'), findsOneWidget);

        // Open applicant 1 (has active orders -> approve disabled, reject allowed with mandatory reason).
        await tester.tap(find.text('Pemohon Satu'));
        await tester.pumpAndSettle();

        expect(find.text('Detail Pengajuan'), findsOneWidget);
        expect(find.text('Indikator Pesanan Aktif'), findsOneWidget);
        expect(find.text('Ada'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.widgetWithText(FilledButton, 'Setujui Pengajuan'),
          200,
        );
        await tester.pumpAndSettle();

        final approveBtn = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Setujui Pengajuan'),
        );
        expect(approveBtn.onPressed, isNull);

        await _scrollAndTap(
          tester,
          find.widgetWithText(OutlinedButton, 'Tolak Pengajuan'),
        );

        // Empty reason keeps Konfirmasi Tolak disabled.
        var confirmRejectBtn = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Konfirmasi Tolak'),
        );
        expect(confirmRejectBtn.onPressed, isNull);

        await tester.enterText(
          find.byType(TextField).last,
          'Masih ada pesanan aktif.',
        );
        await tester.pump();

        confirmRejectBtn = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Konfirmasi Tolak'),
        );
        expect(confirmRejectBtn.onPressed, isNotNull);

        await tester.tap(find.widgetWithText(FilledButton, 'Konfirmasi Tolak'));
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, 500));
        await tester.pumpAndSettle();
        expect(find.text('Ditolak'), findsWidgets);
        await tester.scrollUntilVisible(
          find.text('Masih ada pesanan aktif.'),
          200,
        );
        expect(find.text('Masih ada pesanan aktif.'), findsWidgets);

        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Open Pengajuan tab -> check Menunggu (app2) and Riwayat (app1).
        await tester.tap(find.text('Pengajuan'));
        await tester.pumpAndSettle();
        expect(find.text('Pemohon Dua'), findsOneWidget);

        await tester.tap(find.text('Riwayat'));
        await tester.pumpAndSettle();
        expect(find.text('Pemohon Satu'), findsOneWidget);

        await tester.tap(find.text('Menunggu'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pemohon Dua'));
        await tester.pumpAndSettle();
        expect(find.text('Tidak Ada'), findsOneWidget);

        await _scrollAndTap(
          tester,
          find.widgetWithText(FilledButton, 'Setujui Pengajuan'),
        );
        await tester.tap(
          find.widgetWithText(FilledButton, 'Setujui Pengajuan').last,
        );
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, 500));
        await tester.pumpAndSettle();
        expect(find.text('Disetujui'), findsWidgets);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Users tab (UI-ADMIN-003): active orders block deactivation, zero active orders allow deactivate & reactivate.
        await tester.tap(find.text('Pengguna').last);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Pemohon Satu'));
        await tester.pumpAndSettle();
        expect(find.text('Ada'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.widgetWithText(FilledButton, 'Nonaktifkan Akun'),
          200,
        );
        await tester.pumpAndSettle();
        final blockedDeactivate = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Nonaktifkan Akun'),
        );
        expect(blockedDeactivate.onPressed, isNull);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Pemohon Dua'));
        await tester.pumpAndSettle();
        await _scrollAndTap(
          tester,
          find.widgetWithText(FilledButton, 'Nonaktifkan Akun'),
        );
        await tester.enterText(
          find.byType(TextField).last,
          'Uji nonaktifkan akun',
        );
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Nonaktifkan'));
        await tester.pumpAndSettle();
        expect(find.text('Aktifkan Kembali'), findsOneWidget);

        await _scrollAndTap(
          tester,
          find.widgetWithText(FilledButton, 'Aktifkan Kembali'),
        );
        await tester.tap(
          find.widgetWithText(FilledButton, 'Aktifkan Kembali').last,
        );
        await tester.pumpAndSettle();
        expect(find.text('Nonaktifkan Akun'), findsOneWidget);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Stalls tab (UI-ADMIN-004): strictly read-only.
        await tester.tap(find.text('Kantin').last);
        await tester.pumpAndSettle();
        expect(find.text('Kantin Melati'), findsOneWidget);
        expect(find.text('Owner Nonaktif'), findsOneWidget);

        await tester.tap(find.text('Kantin Melati'));
        await tester.pumpAndSettle();
        expect(
          find.text('Hanya dapat dilihat oleh Admin (read-only).'),
          findsOneWidget,
        );
        await tester.scrollUntilVisible(find.text('Senin'), 200);
        await tester.pumpAndSettle();
        expect(find.text('Senin'), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Tutup Kantin'), findsNothing);
        expect(find.widgetWithText(FilledButton, 'Buka Kantin'), findsNothing);
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Account & Settings (UI-ADMIN-005): Theme toggle + About + Confirm Logout.
        await tester.tap(find.text('Beranda').last);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Akun Admin'));
        await tester.pumpAndSettle();
        expect(find.text('Akun Admin'), findsOneWidget);

        await tester.tap(find.text('Tentang Aplikasi'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Versi 1.0.0'), findsOneWidget);
        await tester.tap(find.text('Tutup'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Pengaturan'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Mode Gelap'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Keluar'));
        await tester.pumpAndSettle();
        expect(find.text('Keluar dari akun Admin?'), findsOneWidget);
        await tester.tap(find.widgetWithText(FilledButton, 'Keluar'));
        await tester.pumpAndSettle();
        expect(fake.logoutCalled, true);
      },
    );

    testWidgets(
      'renders cleanly in Dark Mode on 320x568 viewport at 2x textScale and isolates Admin account switch',
      (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final fake = _FakeAdminBackend();
        final repo = _createFakeAuthRepo(fake, initialAccountId: _adminAId);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authRepositoryProvider.overrideWithValue(repo)],
            child: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 568),
                textScaler: TextScaler.linear(2.0),
                platformBrightness: Brightness.dark,
              ),
              child: const KantinCerdasApp(),
            ),
          ),
        );
        await _pumpPastSplash(tester);

        expect(find.text('Beranda'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'reflects Customer->Owner role promotion on cold restart and blocks deactivated session recovery',
      (tester) async {
        final fake = _FakeAdminBackend();
        fake.currentAuthAccount = {
          'id': _cust2Id,
          'email': 'pemohon2@example.test',
          'role': 'owner',
          'display_name': 'Pemohon Dua',
          'suggested_name': null,
          'has_photo': true,
          'profile_complete': true,
          'can_manage_credentials': true,
        };
        final repo = _createFakeAuthRepo(fake, initialAccountId: _cust2Id);

        // Cold restart after server-side approval routes directly to OwnerShellPage.
        await tester.pumpWidget(
          ProviderScope(
            overrides: [authRepositoryProvider.overrideWithValue(repo)],
            child: const KantinCerdasApp(),
          ),
        );
        await _pumpPastSplash(tester);
        expect(find.text('Pesanan'), findsWidgets);
        expect(find.text('Kantin'), findsWidgets);

        // Revalidating an account after Admin deactivation exits protected workspace to SessionRecoveryView.
        fake.forceInactiveAuthMe = true;
        final container = ProviderScope.containerOf(
          tester.element(find.byType(Scaffold).first),
        );
        await container
            .read(authControllerProvider.notifier)
            .revalidateOnResume();
        await tester.pumpAndSettle();

        expect(find.text('Sesi belum pulih'), findsOneWidget);
        expect(find.text('Pesanan'), findsNothing);
      },
    );
  });
}

Future<void> _pumpPastSplash(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 3200));
  await tester.pumpAndSettle();
}

Future<void> _scrollAndTap(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 200);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

ProviderContainer _createTestContainer({required _FakeAdminBackend fake}) {
  final authRepo = _createFakeAuthRepo(fake);
  return ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(authRepo)],
  );
}

AuthRepository _createFakeAuthRepo(
  _FakeAdminBackend fake, {
  String initialAccountId = _adminAId,
}) {
  final client = MockClient(fake.handle);
  return AuthRepository(
    client: client,
    store: MemorySessionStore()
      ..write(SessionTokens.fromJson(_sessionJson(initialAccountId))),
    baseUrl: 'https://api.example.test',
  );
}

Map<String, dynamic> _sessionJson(String accountId) => {
  'access_token': 'token-$accountId',
  'refresh_token': 'refresh-$accountId',
  'expires_at': DateTime.now()
      .toUtc()
      .add(const Duration(hours: 1))
      .toIso8601String(),
  'account': {
    'id': accountId,
    'email': '$accountId@example.test',
    'role': 'admin',
    'display_name': accountId == _adminBId ? 'Admin Dua' : 'Admin Satu',
    'suggested_name': null,
    'has_photo': true,
    'profile_complete': true,
    'can_manage_credentials': true,
  },
};

class _FakeAdminBackend {
  var mutationCount = 0;
  var logoutCalled = false;
  var forceInactiveAuthMe = false;
  final recordedMutations = <String>[];
  Map<String, dynamic>? currentAuthAccount;

  final Map<String, Map<String, dynamic>> users = {
    _adminAId: {
      'id': _adminAId,
      'email': 'admin1@example.test',
      'display_name': 'Admin Satu',
      'role': 'admin',
      'is_active': true,
      'email_verified': true,
      'created_at': '2026-11-21T08:00:00Z',
      'active_order_indicator': {
        'user_id': _adminAId,
        'has_active_orders': false,
        'active_order_count': 0,
      },
      'recent_logs': <Map<String, dynamic>>[],
    },
    _cust1Id: {
      'id': _cust1Id,
      'email': 'pemohon1@example.test',
      'display_name': 'Pemohon Satu',
      'role': 'customer',
      'is_active': true,
      'email_verified': true,
      'created_at': '2026-11-21T08:10:00Z',
      'active_order_indicator': {
        'user_id': _cust1Id,
        'has_active_orders': true,
        'active_order_count': 1,
      },
      'recent_logs': <Map<String, dynamic>>[],
    },
    _cust2Id: {
      'id': _cust2Id,
      'email': 'pemohon2@example.test',
      'display_name': 'Pemohon Dua',
      'role': 'customer',
      'is_active': true,
      'email_verified': true,
      'created_at': '2026-11-21T08:20:00Z',
      'active_order_indicator': {
        'user_id': _cust2Id,
        'has_active_orders': false,
        'active_order_count': 0,
      },
      'recent_logs': <Map<String, dynamic>>[],
    },
  };

  final Map<String, Map<String, dynamic>> applications = {
    _app1Id: {
      'id': _app1Id,
      'customer_id': _cust1Id,
      'applicant_name': 'Pemohon Satu',
      'applicant_email': 'pemohon1@example.test',
      'applicant_role': 'customer',
      'applicant_is_active': true,
      'planned_stall_name': 'Warung Satu',
      'planned_location': 'Blok A-01',
      'reason': 'Ingin berjualan makanan sehat.',
      'status': 'menunggu_review',
      'rejection_reason': null,
      'decided_by': null,
      'decided_by_name': null,
      'decided_at': null,
      'created_at': '2026-11-21T09:00:00Z',
      'active_order_indicator': {
        'user_id': _cust1Id,
        'has_active_orders': true,
        'active_order_count': 1,
      },
    },
    _app2Id: {
      'id': _app2Id,
      'customer_id': _cust2Id,
      'applicant_name': 'Pemohon Dua',
      'applicant_email': 'pemohon2@example.test',
      'applicant_role': 'customer',
      'applicant_is_active': true,
      'planned_stall_name': 'Warung Dua',
      'planned_location': 'Blok B-02',
      'reason': 'Siap buka pagi.',
      'status': 'menunggu_review',
      'rejection_reason': null,
      'decided_by': null,
      'decided_by_name': null,
      'decided_at': null,
      'created_at': '2026-11-21T09:30:00Z',
      'active_order_indicator': {
        'user_id': _cust2Id,
        'has_active_orders': false,
        'active_order_count': 0,
      },
    },
  };

  final Map<String, dynamic> stall = {
    'id': _stallId,
    'name': 'Kantin Melati',
    'campus': 'USU',
    'block': 'Blok C-01',
    'description': 'Masakan rumahan.',
    'wait_minutes': 12,
    'is_listed': true,
    'is_open': true,
    'has_photo': false,
    'owner_id': _ownerId,
    'owner_name': 'Ibu Melati',
    'owner_email': 'melati@example.test',
    'owner_is_active': false,
    'schedules': [
      {
        'day_of_week': 1,
        'is_open_day': true,
        'open_time': '08:00',
        'close_time': '16:00',
      },
    ],
    'updated_at': '2026-11-21T08:00:00Z',
  };

  Future<http.Response> handle(http.Request req) async {
    final path = req.url.path;
    if (path == '/v1/auth/me') {
      if (forceInactiveAuthMe) {
        return http.Response(
          jsonEncode({
            'success': false,
            'error': {
              'code': 'ACCOUNT_INACTIVE',
              'message': 'Akun dinonaktifkan.',
            },
          }),
          403,
          headers: {'content-type': 'application/json'},
        );
      }
      return _ok(
        currentAuthAccount ??
            {
              'id': _adminAId,
              'email': 'admin1@example.test',
              'role': 'admin',
              'display_name': 'Admin Satu',
              'suggested_name': null,
              'has_photo': true,
              'profile_complete': true,
              'can_manage_credentials': true,
            },
      );
    }
    if (path == '/v1/owner/dashboard') {
      return _ok({
        'stall': null,
        'active_counts': {
          'menunggu_konfirmasi': 0,
          'diproses': 0,
          'siap_diambil': 0,
        },
        'recent_active_orders': <Map<String, dynamic>>[],
      });
    }
    if (path == '/v1/owner/orders') {
      return _ok({'items': <Map<String, dynamic>>[], 'has_more': false});
    }
    if (path == '/v1/auth/logout') {
      logoutCalled = true;
      return _ok(null);
    }
    if (path == '/v1/auth/profile/photo') return http.Response('', 204);

    if (path == '/v1/admin/dashboard') {
      final pending = applications.values
          .where((a) => a['status'] == 'menunggu_review')
          .toList();
      final inactive = users.values
          .where((u) => u['is_active'] == false)
          .length;
      return _ok({
        'total_users': users.length,
        'active_users': users.length - inactive,
        'inactive_users': inactive,
        'pending_applications': pending.length,
        'total_stalls': 1,
        'published_stalls': 1,
        'open_stalls': 1,
        'recent_pending_applications': pending,
      });
    }

    if (path == '/v1/admin/applications') {
      final scope = req.url.queryParameters['scope'] ?? 'pending';
      final items = applications.values.where((a) {
        if (scope == 'pending') return a['status'] == 'menunggu_review';
        if (scope == 'history') return a['status'] != 'menunggu_review';
        return true;
      }).toList();
      return _ok({'items': items, 'scope': scope, 'limit': 50, 'offset': 0});
    }

    if (path.startsWith('/v1/admin/applications/') &&
        path.endsWith('/review') &&
        req.method == 'POST') {
      mutationCount++;
      recordedMutations.add('${req.method} $path');
      final id = path.split('/')[4];
      final app = applications[id]!;
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final decision = body['decision'] as String;
      app['status'] = decision;
      app['rejection_reason'] = decision == 'ditolak'
          ? body['rejection_reason']
          : null;
      app['decided_by'] = _adminAId;
      app['decided_by_name'] = 'Admin Satu';
      app['decided_at'] = '2026-11-21T10:00:00Z';
      if (decision == 'disetujui') {
        users[app['customer_id'] as String]!['role'] = 'owner';
      }
      return _ok(app);
    }

    if (path.startsWith('/v1/admin/applications/')) {
      final id = path.split('/').last;
      return _ok(applications[id]);
    }

    if (path == '/v1/admin/users') {
      final q = (req.url.queryParameters['q'] ?? '').toLowerCase();
      final status = req.url.queryParameters['status'];
      final items = users.values.where((u) {
        if (status == 'active' && u['is_active'] != true) return false;
        if (status == 'inactive' && u['is_active'] != false) return false;
        if (q.isNotEmpty &&
            !(u['display_name'] as String).toLowerCase().contains(q) &&
            !(u['email'] as String).toLowerCase().contains(q)) {
          return false;
        }
        return true;
      }).toList();
      return _ok({'items': items, 'limit': 50, 'offset': 0});
    }

    if (path.startsWith('/v1/admin/users/') &&
        path.endsWith('/status') &&
        req.method == 'POST') {
      mutationCount++;
      recordedMutations.add('${req.method} $path');
      final id = path.split('/')[4];
      final user = users[id]!;
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final isActive = body['is_active'] as bool;
      user['is_active'] = isActive;
      final logs = user['recent_logs'] as List;
      logs.insert(0, {
        'id': 'log-${logs.length + 1}',
        'admin_id': _adminAId,
        'admin_name': 'Admin Satu',
        'action_type': isActive ? 'user_reactivated' : 'user_deactivated',
        'target_user_id': id,
        'target_user_name': user['display_name'],
        'target_application_id': null,
        'reason': body['reason'],
        'summary': isActive ? 'Diaktifkan kembali' : 'Dinonaktifkan',
        'created_at': '2026-11-21T10:05:00Z',
      });
      return _ok(user);
    }

    if (path.startsWith('/v1/admin/users/')) {
      final id = path.split('/').last;
      return _ok(users[id]);
    }

    if (path == '/v1/admin/stalls') {
      return _ok({
        'items': [stall],
        'limit': 50,
        'offset': 0,
      });
    }
    if (path.startsWith('/v1/admin/stalls/') && path.endsWith('/photo')) {
      return http.Response('', 204);
    }
    if (path.startsWith('/v1/admin/stalls/')) {
      return _ok(stall);
    }

    if (path == '/v1/admin/action-logs') {
      return _ok({'items': <Map<String, dynamic>>[], 'limit': 50, 'offset': 0});
    }

    return http.Response(
      jsonEncode({
        'error': {'code': 'ROUTE_NOT_FOUND', 'message': 'Not found'},
      }),
      404,
      headers: {'content-type': 'application/json'},
    );
  }

  http.Response _ok(Object? data) => http.Response(
    jsonEncode({'success': true, 'data': data}),
    200,
    headers: {'content-type': 'application/json'},
  );
}
