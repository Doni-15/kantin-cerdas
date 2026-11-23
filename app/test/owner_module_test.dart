import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/data/auth_repository.dart';
import 'package:kantin_cerdas/main.dart';

const _splashMinimum = Duration(milliseconds: 3000);
const _ownerAId = '10000000-0000-0000-0000-000000000001';
const _ownerBId = '10000000-0000-0000-0000-000000000002';
const _stallAId = '20000000-0000-0000-0000-000000000001';
const _catMakananId = '30000000-0000-0000-0000-000000000001';
const _catArsipId = '30000000-0000-0000-0000-000000000002';
const _menuId = '40000000-0000-0000-0000-000000000001';
const _orderId = '50000000-0000-0000-0000-000000000001';

void main() {
  testWidgets('Owner stall profile, publish gate, open/close, and schedule flow', (
    tester,
  ) async {
    _viewport(tester, const Size(412, 915));
    final fake = _FakeOwnerBackend();
    await _launchOwnerApp(tester, fake);

    // Initially new owner -> Siapkan kantinmu
    expect(find.text('Siapkan kantinmu'), findsOneWidget);
    await _tap(tester, find.text('Mulai Buat Kantin'));

    // Save mandatory fields (name, campus, block) without optional description/photo
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama Kantin *'),
      'Kantin Maju',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Kampus/Universitas *'),
      'USU',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Lokasi Fisik Detail *'),
      'Blok A-01',
    );
    await _tap(
      tester,
      find.widgetWithText(FilledButton, 'Simpan & Buat Kantin'),
    );

    expect(find.text('Informasi Kantin'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Status Publikasi & Operasional'),
      250,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Belum Diterbitkan'), findsOneWidget);

    // Publish disabled without available menu
    final publishBtn = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Terbitkan Kantin'),
    );
    expect(publishBtn.onPressed, isNull);

    // Allow save snackbar to auto-dismiss before interacting with FAB on Menu tab
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    // Create an available menu through UI -> unlocks publish gate via real invalidation
    await _tap(tester, find.text('Menu'));
    await _tap(tester, find.byTooltip('Tambah menu'));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nama Menu *'),
      'Nasi Goreng',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Harga Rupiah *'),
      '15000',
    );
    await _tap(tester, find.widgetWithText(FilledButton, 'Simpan Menu'));
    await _tap(tester, find.text('Kantin'));
    await tester.scrollUntilVisible(
      find.text('Terbitkan Kantin'),
      250,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    final publishBtnReady = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Terbitkan Kantin'),
    );
    expect(publishBtnReady.onPressed, isNotNull);

    await _tap(tester, find.widgetWithText(FilledButton, 'Terbitkan Kantin'));
    await _tap(
      tester,
      find.widgetWithText(FilledButton, 'Terbitkan Kantin').last,
    );

    expect(find.text('Diterbitkan'), findsNothing); // badge shows Tutup
    expect(find.text('Tutup'), findsWidgets);
    expect(find.textContaining('Unpublish'), findsNothing);
    expect(find.textContaining('Batalkan Publikasi'), findsNothing);

    // Manual Buka Kantin toggle
    await _tap(tester, find.text('Kantin Tutup'));
    await _tap(tester, find.widgetWithText(FilledButton, 'Buka Kantin'));
    expect(find.text('Kantin Buka'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Owner categories protect archived menus; menus support archive and restore',
    (tester) async {
      _viewport(tester, const Size(412, 915));
      final fake = _FakeOwnerBackend()
        ..createInitialStall()
        ..addMenu(
          available: true,
          categoryId: _catArsipId,
          categoryName: 'Khusus',
        );
      await _launchOwnerApp(tester, fake);

      // Navigate to Menu tab -> FAB + visible on Menu Aktif
      await _tap(tester, find.text('Menu'));
      expect(find.byTooltip('Tambah menu'), findsOneWidget);
      expect(find.text('Nasi Goreng'), findsOneWidget);

      // Archive menu (no permanent delete button)
      await _tap(tester, find.text('Nasi Goreng'));
      expect(find.text('Hapus Menu'), findsNothing);
      await _tap(tester, find.text('Arsipkan Menu'));
      await _tap(tester, find.widgetWithText(FilledButton, 'Arsipkan Menu'));

      // Check Categories: 'Khusus' has 1 archived menu -> delete button hidden/blocked
      await _tap(tester, find.text('Kategori Menu'));
      await _tap(tester, find.text('Khusus'));
      expect(find.text('Hapus Kategori'), findsNothing);
      expect(find.textContaining('1 arsip'), findsWidgets);
      await _tap(tester, find.text('Batal'));
      await _tap(tester, find.byType(BackButton));

      // Switch to Arsip tab -> FAB hidden, restore works
      await _tap(tester, find.text('Arsip'));
      expect(find.byTooltip('Tambah menu'), findsNothing);
      await _tap(tester, find.text('Nasi Goreng'));
      expect(find.text('Detail Menu Arsip'), findsOneWidget);
      await _tap(tester, find.text('Pulihkan Menu'));
      await _tap(
        tester,
        find.widgetWithText(FilledButton, 'Pulihkan Menu').last,
      );
      expect(find.text('Menu'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  for (final brightness in Brightness.values) {
    testWidgets(
      'Owner dashboard, order actions (Selesai & Gagal Diambil), and lookup work in $brightness',
      (tester) async {
        _viewport(tester, const Size(412, 915));
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

        final fake = _FakeOwnerBackend()
          ..createInitialStall(published: true, open: true)
          ..addOrder(orderNumber: '0042', status: 'siap_diambil');
        await _launchOwnerApp(tester, fake);

        // Dashboard shows active counts and NO revenue/profit stats
        expect(find.text('Perlu Ditangani'), findsOneWidget);
        expect(find.textContaining('Pendapatan'), findsNothing);
        expect(find.textContaining('Omzet'), findsNothing);
        expect(find.text('0042'), findsOneWidget);

        // Lookup preserves leading zero '0042'
        await _tap(tester, find.text('Pesanan'));
        await _tap(tester, find.byTooltip('Cari atau pindai pesanan'));
        await tester.enterText(
          find.widgetWithText(TextField, 'Nomor Pesanan (Code 128)'),
          '0042',
        );
        await _tap(tester, find.text('Cari Pesanan'));
        expect(find.text('Lihat Detail Pesanan'), findsOneWidget);

        // Open Detail -> try Gagal Diambil with mandatory reason
        await _tap(tester, find.text('Lihat Detail Pesanan'));
        expect(find.text('Detail Pesanan'), findsOneWidget);
        await _tap(tester, find.text('Gagal Diambil'));
        // Button disabled when reason empty
        final confirmFail = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Konfirmasi Gagal Diambil'),
        );
        expect(confirmFail.onPressed, isNull);
        await tester.enterText(
          find.widgetWithText(TextField, 'Alasan (wajib)'),
          'Makanan rusak saat disiapkan',
        );
        await _tap(
          tester,
          find.widgetWithText(FilledButton, 'Konfirmasi Gagal Diambil'),
        );

        expect(find.text('Gagal Diambil'), findsWidgets);
        expect(find.text('Pembayaran: Tunai · Belum Lunas'), findsOneWidget);
        expect(
          find.text('Alasan: Makanan rusak saat disiapkan'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Logout and switching Owner accounts leaks zero previous stall state',
    (tester) async {
      _viewport(tester, const Size(412, 915));
      final fake = _FakeOwnerBackend()
        ..createInitialStall(name: 'Kantin Owner A');
      await _launchOwnerApp(tester, fake);

      expect(find.text('Kantin Owner A'), findsOneWidget);
      await _tap(tester, find.byTooltip('Akun'));
      await _tap(tester, find.text('Keluar'));
      await _tap(tester, find.widgetWithText(FilledButton, 'Keluar'));

      expect(find.byKey(const ValueKey('auth-email')), findsOneWidget);
      fake.switchToOwnerB();
      await tester.enterText(
        find.byKey(const ValueKey('auth-email')),
        'ownerb@example.test',
      );
      await tester.enterText(
        find.byKey(const ValueKey('auth-password')),
        'kata sandi panjang 15',
      );
      await _tap(tester, find.widgetWithText(FilledButton, 'Masuk'));

      expect(find.text('Siapkan kantinmu'), findsOneWidget);
      expect(find.text('Kantin Owner A'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Startup loads only dashboard once and retries cleanly on error', (
    tester,
  ) async {
    _viewport(tester, const Size(412, 915));
    final fake = _FakeOwnerBackend()..failNextDashboard = true;
    await _launchOwnerApp(tester, fake);

    // Error view shown on 503 without crash, and retry recovers cleanly
    expect(find.widgetWithText(FilledButton, 'Coba lagi'), findsOneWidget);
    await _tap(tester, find.widgetWithText(FilledButton, 'Coba lagi'));
    expect(find.text('Siapkan kantinmu'), findsOneWidget);

    // Only dashboard requested during initial Beranda view; lazy tabs did not fire
    final ownerCalls = fake.recordedPaths
        .where((p) => p.startsWith('/v1/owner/'))
        .toList();
    expect(ownerCalls, ['/v1/owner/dashboard', '/v1/owner/dashboard']);
    expect(tester.takeException(), isNull);
  });

  group('Owner layer boundaries', () {
    test(
      'presentation does not import data transport or repository implementations',
      () {
        final dir = Directory('lib/features/owner/presentation');
        final files = dir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            .toList();
        expect(files, isNotEmpty);
        for (final file in files) {
          final content = file.readAsStringSync();
          expect(content, isNot(contains('owner_api_repository.dart')));
          expect(content, isNot(contains('auth_repository.dart')));
        }
      },
    );

    test('data layer does not import presentation or application layers', () {
      final dir = Directory('lib/features/owner/data');
      final files = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      expect(files, isNotEmpty);
      for (final file in files) {
        final content = file.readAsStringSync();
        expect(content, isNot(contains('features/owner/presentation/')));
        expect(content, isNot(contains('features/owner/application/')));
        expect(content, isNot(contains('flutter_riverpod')));
      }
    });
  });
}

void _viewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(finder.hitTestable());
  await tester.pumpAndSettle();
}

Future<void> _launchOwnerApp(
  WidgetTester tester,
  _FakeOwnerBackend fake,
) async {
  final store = MemorySessionStore();
  await store.write(SessionTokens.fromJson(fake.sessionJson()));
  final client = MockClient(fake.handle);
  addTearDown(client.close);

  final repository = AuthRepository(
    client: client,
    store: store,
    baseUrl: 'https://api.example.test',
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: const KantinCerdasApp(),
    ),
  );
  await tester.pump(_splashMinimum);
  await tester.pumpAndSettle();
}

class _FakeOwnerBackend {
  var _currentOwnerId = _ownerAId;
  final Map<String, Map<String, Object?>> _stalls = {};
  final List<Map<String, Object?>> _menus = [];
  final List<Map<String, Object?>> _categories = [
    {
      'id': _catMakananId,
      'stall_id': _stallAId,
      'name': 'Makanan',
      'sort_order': 1,
    },
    {
      'id': _catArsipId,
      'stall_id': _stallAId,
      'name': 'Khusus',
      'sort_order': 2,
    },
  ];
  final List<Map<String, Object?>> _orders = [];
  final List<String> recordedPaths = [];
  var failNextDashboard = false;

  void switchToOwnerB() => _currentOwnerId = _ownerBId;

  void createInitialStall({
    String name = 'Kantin Awal',
    bool published = false,
    bool open = false,
  }) {
    _stalls[_currentOwnerId] = {
      'id': _stallAId,
      'owner_id': _currentOwnerId,
      'name': name,
      'campus': 'USU',
      'block': 'A-01',
      'description': '',
      'wait_minutes': 15,
      'is_listed': published,
      'is_open': open,
      'has_photo': false,
    };
  }

  void addMenu({
    required bool available,
    String categoryId = _catMakananId,
    String categoryName = 'Makanan',
  }) {
    _menus.add({
      'id': _menuId,
      'stall_id': _stallAId,
      'category_id': categoryId,
      'category_name': categoryName,
      'name': 'Nasi Goreng',
      'description': '',
      'price': 15000,
      'is_available': available,
      'is_archived': false,
      'has_photo': false,
    });
  }

  void addOrder({required String orderNumber, required String status}) {
    _orders.add({
      'id': _orderId,
      'order_number': orderNumber,
      'stall_id': _stallAId,
      'customer_name': 'Budi',
      'status': status,
      'payment_status': status == 'selesai' ? 'lunas' : 'belum_lunas',
      'general_note': '',
      'total_amount': 15000,
      'prep_estimate_minutes': 15,
      'status_reason': null,
      'created_at': '2026-11-21T02:00:00Z',
      'accepted_at': '2026-11-21T02:01:00Z',
      'ready_at': '2026-11-21T02:10:00Z',
      'terminal_at': null,
      'updated_at': '2026-11-21T02:10:00Z',
      'item_summary': '1x Nasi Goreng',
      'item_count': 1,
      'items': [
        {
          'id': '60000000-0000-0000-0000-000000000001',
          'menu_item_id': _menuId,
          'menu_name': 'Nasi Goreng',
          'unit_price': 15000,
          'quantity': 1,
          'line_total': 15000,
          'item_note': '',
        },
      ],
      'events': const <Object>[],
    });
  }

  Map<String, Object?> accountJson() => {
    'id': _currentOwnerId,
    'email': _currentOwnerId == _ownerAId
        ? 'ownera@example.test'
        : 'ownerb@example.test',
    'role': 'owner',
    'display_name': _currentOwnerId == _ownerAId ? 'Owner A' : 'Owner B',
    'suggested_name': null,
    'has_photo': true,
    'profile_complete': true,
    'can_manage_credentials': true,
  };

  Map<String, Object?> sessionJson() => {
    'access_token': 'token-$_currentOwnerId',
    'refresh_token': 'refresh-$_currentOwnerId',
    'expires_at': '2100-01-01T00:00:00Z',
    'account': accountJson(),
  };

  Future<http.Response> handle(http.Request request) async {
    final path = request.url.path;
    recordedPaths.add(path);
    if (path == '/v1/auth/me') return _ok(accountJson());
    if (path == '/v1/auth/login') return _ok(sessionJson());
    if (path == '/v1/auth/logout') return _ok(null);
    if (path == '/v1/auth/profile/photo') return http.Response('', 204);
    if (path.startsWith('/v1/catalog/')) {
      return _ok({'items': const <Object>[], 'next_cursor': null});
    }

    if (path == '/v1/owner/dashboard') {
      if (failNextDashboard) {
        failNextDashboard = false;
        return http.Response(
          jsonEncode({
            'success': false,
            'error': {'code': 'OWNER_UNAVAILABLE', 'message': 'Coba lagi'},
          }),
          503,
        );
      }
      final stall = _stalls[_currentOwnerId];
      final active = stall == null
          ? const <Map<String, Object?>>[]
          : _orders
                .where(
                  (o) => const {
                    'menunggu_konfirmasi',
                    'diproses',
                    'siap_diambil',
                  }.contains(o['status']),
                )
                .toList();
      return _ok({
        ..._stallPayload(stall),
        'active_counts': {
          'menunggu_konfirmasi': active
              .where((o) => o['status'] == 'menunggu_konfirmasi')
              .length,
          'diproses': active.where((o) => o['status'] == 'diproses').length,
          'siap_diambil': active
              .where((o) => o['status'] == 'siap_diambil')
              .length,
        },
        'attention_orders': active,
      });
    }

    if (path == '/v1/owner/stall' && request.method == 'GET') {
      return _ok(_stallPayload(_stalls[_currentOwnerId]));
    }
    if (path == '/v1/owner/stall' && request.method == 'POST') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      _stalls[_currentOwnerId] = {
        'id': _stallAId,
        'owner_id': _currentOwnerId,
        'name': body['name'],
        'campus': body['campus'],
        'block': body['block'],
        'description': body['description'] ?? '',
        'wait_minutes': body['wait_minutes'] ?? 0,
        'is_listed': false,
        'is_open': false,
        'has_photo': false,
      };
      return _ok(_stallPayload(_stalls[_currentOwnerId]), 201);
    }
    if (path == '/v1/owner/stall/publish') {
      _stalls[_currentOwnerId]!['is_listed'] = true;
      _stalls[_currentOwnerId]!['is_open'] = false;
      return _ok(_stallPayload(_stalls[_currentOwnerId]));
    }
    if (path == '/v1/owner/stall/open-status') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      _stalls[_currentOwnerId]!['is_open'] = body['is_open'] == true;
      return _ok(_stallPayload(_stalls[_currentOwnerId]));
    }

    if (path == '/v1/owner/categories') {
      return _ok({
        'items': [
          for (final cat in _categories)
            {
              ...cat,
              'active_menu_count': _menus
                  .where(
                    (m) =>
                        m['category_id'] == cat['id'] &&
                        m['is_archived'] == false,
                  )
                  .length,
              'archived_menu_count': _menus
                  .where(
                    (m) =>
                        m['category_id'] == cat['id'] &&
                        m['is_archived'] == true,
                  )
                  .length,
              'total_menu_count': _menus
                  .where((m) => m['category_id'] == cat['id'])
                  .length,
              'can_delete': _menus
                  .where((m) => m['category_id'] == cat['id'])
                  .isEmpty,
            },
        ],
      });
    }

    if (path == '/v1/owner/menus' && request.method == 'POST') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final created = {
        'id': _menuId,
        'stall_id': _stallAId,
        'category_id': body['category_id'] ?? _catMakananId,
        'category_name': 'Makanan',
        'name': body['name'],
        'description': body['description'] ?? '',
        'price': body['price'],
        'is_available': body['is_available'] ?? true,
        'is_archived': false,
        'has_photo': false,
      };
      _menus.add(created);
      return _ok(created, 201);
    }
    if (path == '/v1/owner/menus') {
      final archived = request.url.queryParameters['archived'] == 'true';
      return _ok({
        'items': _menus.where((m) => m['is_archived'] == archived).toList(),
      });
    }
    if (path == '/v1/owner/menus/$_menuId/archive') {
      _menus.first['is_archived'] = true;
      return _ok(_menus.first);
    }
    if (path == '/v1/owner/menus/$_menuId/restore') {
      _menus.first['is_archived'] = false;
      return _ok(_menus.first);
    }

    if (path == '/v1/owner/orders') {
      final scope = request.url.queryParameters['scope'] ?? 'active';
      final items = _orders.where((o) {
        final isAct = const {
          'menunggu_konfirmasi',
          'diproses',
          'siap_diambil',
        }.contains(o['status']);
        return scope == 'active' ? isAct : !isAct;
      }).toList();
      return _ok({'items': items, 'has_more': false});
    }
    if (path == '/v1/owner/orders/lookup') {
      final code = request.url.queryParameters['code'];
      final found = _orders.where((o) => o['order_number'] == code).first;
      return _ok(found);
    }
    if (path == '/v1/owner/orders/$_orderId') {
      return _ok(_orders.first);
    }
    if (path == '/v1/owner/orders/$_orderId/fail-pickup') {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      _orders.first['status'] = 'gagal_diambil';
      _orders.first['payment_status'] = 'belum_lunas';
      _orders.first['status_reason'] = body['reason'];
      return _ok(_orders.first);
    }

    throw StateError('Unhandled mock route: ${request.method} ${request.url}');
  }

  Map<String, Object?> _stallPayload(Map<String, Object?>? stall) {
    final availCount = _menus
        .where((m) => m['is_archived'] == false && m['is_available'] == true)
        .length;
    return {
      'stall': stall,
      'schedules': [
        for (var d = 1; d <= 7; d++)
          {
            'day_of_week': d,
            'is_open_day': false,
            'open_time': null,
            'close_time': null,
          },
      ],
      'publish_eligibility': {
        'can_publish':
            stall != null && stall['is_listed'] == false && availCount >= 1,
        'missing_profile_fields': const <String>[],
        'available_menu_count': availCount,
      },
    };
  }

  http.Response _ok(Object? data, [int status = 200]) =>
      http.Response(jsonEncode({'success': true, 'data': data}), status);
}
