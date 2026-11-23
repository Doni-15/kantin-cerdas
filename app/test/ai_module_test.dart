import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kantin_cerdas/core/theme/theme_mode_provider.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/data/auth_repository.dart';
import 'package:kantin_cerdas/features/customer/application/customer_providers.dart';
import 'package:kantin_cerdas/features/customer/data/checkout_attempt_store.dart';
import 'package:kantin_cerdas/main.dart';

const _splashMinimum = Duration(milliseconds: 3000);
const _custAId = '10000000-0000-0000-0000-000000000021';
const _custBId = '10000000-0000-0000-0000-000000000022';
const _stallOpenId = '20000000-0000-0000-0000-000000000021';
const _stallClosedId = '20000000-0000-0000-0000-000000000022';
const _menuOrderableId = '40000000-0000-0000-0000-000000000021';
const _menuClosedId = '40000000-0000-0000-0000-000000000022';

void main() {
  group('AI Food Assistant Flutter Flows', () {
    testWidgets(
      'FAB opens Food Assistant, runs catalog fallback, opens Lihat Detail without mutating cart, preserves draft on error, and isolates accounts',
      (tester) async {
        _viewport(tester, const Size(412, 915));
        final fake = _FakeAiBackend();
        await _launchCustomer(tester, fake, accountId: _custAId, name: 'Sari');

        // Open Food Assistant via center-docked robot FAB (UI-CUSTOMER-001 -> UI-AI-001).
        expect(find.byTooltip('Food Assistant'), findsOneWidget);
        await _tap(tester, find.byTooltip('Food Assistant'));
        expect(find.text('Food Assistant'), findsOneWidget);
        expect(find.text('Mode Katalog'), findsOneWidget);

        // Quick prompt triggers catalog fallback with budget filter <= Rp20.000.
        await _tap(tester, find.text('Menu ≤ Rp20.000'));
        expect(find.text('Nasi Ayam Geprek'), findsOneWidget);
        expect(find.text('Rp18.000'), findsOneWidget);
        expect(find.text('Tersedia · Kantin Buka'), findsOneWidget);
        expect(find.text('Kantin Segar · Blok A-1'), findsOneWidget);
        expect(fake.cartMutationCount, 0);

        // Tap Lihat Detail -> navigates to real CustomerMenuDetailPage without touching cart.
        await _tap(tester, find.widgetWithText(FilledButton, 'Lihat Detail'));
        expect(find.text('Nasi Ayam Geprek'), findsWidgets);
        expect(
          find.widgetWithText(FilledButton, 'Tambah ke Keranjang'),
          findsOneWidget,
        );
        expect(fake.cartMutationCount, 0);

        // Navigate back to Food Assistant.
        await _tap(tester, find.byType(BackButton));
        expect(find.text('Food Assistant'), findsOneWidget);

        // Verify read-only order refusal & unavailable status card.
        await _tap(tester, find.text('Info tutup / habis'));
        expect(find.text('Kantin Tutup (Informasi)'), findsOneWidget);
        await tester.enterText(
          find.byType(TextField),
          'Tolong checkout nasi ayam',
        );
        await _tap(tester, find.byIcon(Icons.send_rounded));
        expect(
          find.textContaining(
            'bersifat read-only sehingga tidak dapat menambahkan item',
          ),
          findsOneWidget,
        );
        expect(fake.cartMutationCount, 0);

        // Offline/network error preserves typed draft cleanly!
        fake.simulateChatError = true;
        await tester.enterText(find.byType(TextField), 'Cari minuman dingin');
        await _tap(tester, find.byIcon(Icons.send_rounded));
        expect(find.text('Cari minuman dingin'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        fake.simulateChatError = false;

        // Account switch (Customer A -> Customer B) isolates AI chat state cleanly.
        await _launchCustomer(tester, fake, accountId: _custBId, name: 'Bima');
        await _tap(tester, find.byTooltip('Food Assistant'));
        expect(
          find.text('Halo! Mau cari makanan apa hari ini?'),
          findsOneWidget,
        );
        expect(find.text('Nasi Ayam Geprek'), findsNothing);
        expect(find.text('Tolong checkout nasi ayam'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Food Assistant adapts to Brightness.dark and 320x568 viewport at textScale=2.0 without overflow',
      (tester) async {
        _viewport(tester, const Size(320, 568));
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final fake = _FakeAiBackend();
        await _launchCustomer(
          tester,
          fake,
          accountId: _custAId,
          name: 'Sari',
          themeMode: ThemeMode.dark,
        );
        await _tap(tester, find.byTooltip('Food Assistant'));
        expect(find.text('Food Assistant'), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'Carikan ayam');
        await _tap(tester, find.byIcon(Icons.send_rounded));
        await tester.scrollUntilVisible(
          find.text('Nasi Ayam Geprek'),
          150,
          scrollable: find.descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          ),
        );
        expect(find.text('Nasi Ayam Geprek'), findsOneWidget);
      },
    );
  });
}

Future<void> _launchCustomer(
  WidgetTester tester,
  _FakeAiBackend fake, {
  required String accountId,
  required String name,
  ThemeMode themeMode = ThemeMode.light,
}) async {
  final sessionStore = MemorySessionStore();
  await sessionStore.write(
    SessionTokens.fromJson({
      'access_token': 'tok-$accountId',
      'refresh_token': 'ref-$accountId',
      'expires_at': DateTime.now()
          .toUtc()
          .add(const Duration(hours: 1))
          .toIso8601String(),
      'user': {
        'id': accountId,
        'email': '$accountId@example.test',
        'role': 'customer',
        'display_name': name,
        'has_photo': true,
        'profile_complete': true,
      },
    }),
  );
  final client = MockClient(fake.handle);
  addTearDown(client.close);

  final authRepo = AuthRepository(
    client: client,
    store: sessionStore,
    baseUrl: 'https://api.example.test',
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepo),
        checkoutAttemptStoreProvider.overrideWithValue(
          MemoryCheckoutAttemptStore(),
        ),
        themeModeProvider.overrideWith(() => _FixedThemeNotifier(themeMode)),
      ],
      child: const KantinCerdasApp(),
    ),
  );
  await tester.pump(_splashMinimum);
  await tester.pumpAndSettle();
}

class _FixedThemeNotifier extends ThemeModeNotifier {
  _FixedThemeNotifier(this._mode);
  final ThemeMode _mode;

  @override
  ThemeMode build() => _mode;
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder.first), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

void _viewport(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class _FakeAiBackend {
  int cartMutationCount = 0;
  bool simulateChatError = false;

  Future<http.Response> handle(http.Request req) async {
    final accountId =
        req.headers['authorization']?.replaceFirst('Bearer tok-', '') ??
        _custAId;
    final path = req.url.path;

    if (path == '/v1/auth/me') {
      return _ok({
        'id': accountId,
        'email': '$accountId@example.test',
        'role': 'customer',
        'display_name': accountId == _custBId ? 'Bima' : 'Sari',
        'suggested_name': null,
        'has_photo': true,
        'profile_complete': true,
      });
    }
    if (path == '/v1/auth/profile/photo') return http.Response('', 204);
    if (path == '/v1/catalog/stalls') {
      return _ok({
        'items': [_openStall],
        'next_cursor': null,
      });
    }
    if (path == '/v1/customer/cart' && req.method == 'GET') {
      return _ok({
        'stall': null,
        'items': const [],
        'general_note': '',
        'draft_version': 1,
        'subtotal': 0,
        'total_quantity': 0,
        'has_blocking_issues': false,
        'price_changed': false,
      });
    }
    if (path.startsWith('/v1/customer/cart/') ||
        path == '/v1/customer/orders' && req.method == 'POST') {
      cartMutationCount += 1;
      return _ok(null);
    }
    if (path == '/v1/customer/menus/$_menuOrderableId') {
      return _ok({
        'menu': {
          'id': _menuOrderableId,
          'stall_id': _stallOpenId,
          'name': 'Nasi Ayam Geprek',
          'description': 'Ayam crispy dengan sambal geprek',
          'category': 'Makanan Berat',
          'price': 18000,
          'is_available': true,
          'is_archived': false,
          'has_photo': false,
        },
        'stall': _openStall,
      });
    }

    if (path == '/v1/ai/status') {
      return _ok({
        'provider_enabled': false,
        'provider_ready': false,
        'model': 'gemini-3.5-flash-lite',
        'fallback_active': true,
        'reason_code': 'provider_disabled',
        'reason_message': 'Layanan AI eksternal dinonaktifkan.',
        'quota': _quotaPayload,
      });
    }

    if (path == '/v1/ai/chat' && req.method == 'POST') {
      if (simulateChatError) {
        throw const SocketException('Offline test');
      }
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final message = (body['message'] as String? ?? '').toLowerCase();

      if (message.contains('checkout')) {
        return _ok({
          'status': 'catalog_fallback',
          'reply':
              'Food Assistant bersifat read-only sehingga tidak dapat menambahkan item ke keranjang atau melakukan checkout otomatis.',
          'recommendations': [_orderableRec],
          'is_general_culinary': false,
          'is_verified_catalog_data': true,
          'has_uncertainty_notice': false,
          'fallback_used': true,
          'fallback_reason': 'read_only_transaction_boundary',
          'applied_max_budget': null,
          'provider_enabled': false,
          'provider_model': 'gemini-3.5-flash-lite',
          'quota': _quotaPayload,
        });
      }
      if (message.contains('tutup')) {
        return _ok({
          'status': 'catalog_fallback',
          'reply': 'Menampilkan info menu dari kantin tutup.',
          'recommendations': [_closedRec],
          'is_general_culinary': false,
          'is_verified_catalog_data': true,
          'has_uncertainty_notice': false,
          'fallback_used': true,
          'fallback_reason': 'provider_disabled',
          'applied_max_budget': null,
          'provider_enabled': false,
          'provider_model': 'gemini-3.5-flash-lite',
          'quota': _quotaPayload,
        });
      }
      return _ok({
        'status': 'catalog_fallback',
        'reply': 'Berikut menu sesuai budget maksimal Rp20.000.',
        'recommendations': [_orderableRec],
        'is_general_culinary': false,
        'is_verified_catalog_data': true,
        'has_uncertainty_notice': false,
        'fallback_used': true,
        'fallback_reason': 'provider_disabled',
        'applied_max_budget': 20000,
        'provider_enabled': false,
        'provider_model': 'gemini-3.5-flash-lite',
        'quota': _quotaPayload,
      });
    }

    return http.Response(
      jsonEncode({
        'success': false,
        'error': {'code': 'ROUTE_NOT_FOUND', 'message': 'Not found: $path'},
      }),
      404,
      headers: {'content-type': 'application/json'},
    );
  }

  static const _quotaPayload = {
    'jakarta_date': '2026-11-22',
    'daily_limit': 10,
    'used_today': 0,
    'remaining_today': 10,
    'reset_schedule': '00:00 WIB (Asia/Jakarta)',
    'project_cap_configured': false,
    'project_quota_known': false,
  };

  static const _openStall = {
    'id': _stallOpenId,
    'name': 'Kantin Segar',
    'campus': 'USU',
    'block': 'Blok A-1',
    'description': 'Menu sehat harian',
    'wait_minutes': 10,
    'is_open': true,
    'owner_is_active': true,
    'has_photo': false,
  };

  static const _orderableRec = {
    'id': _menuOrderableId,
    'name': 'Nasi Ayam Geprek',
    'description': 'Ayam crispy sambal geprek',
    'category': 'Makanan Berat',
    'price': 18000,
    'has_photo': false,
    'is_available': true,
    'is_orderable': true,
    'unavailable_reason': null,
    'availability_label': 'Tersedia · Kantin Buka',
    'stall': {
      'id': _stallOpenId,
      'name': 'Kantin Segar',
      'block': 'Blok A-1',
      'wait_minutes': 10,
      'is_open': true,
      'owner_is_active': true,
    },
  };

  static const _closedRec = {
    'id': _menuClosedId,
    'name': 'Mie Goreng Malam',
    'description': 'Buka sore',
    'category': 'Makanan Berat',
    'price': 15000,
    'has_photo': false,
    'is_available': true,
    'is_orderable': false,
    'unavailable_reason': 'stall_closed',
    'availability_label': 'Kantin Tutup (Informasi)',
    'stall': {
      'id': _stallClosedId,
      'name': 'Warung Malam',
      'block': 'Blok B-2',
      'wait_minutes': 12,
      'is_open': false,
      'owner_is_active': true,
    },
  };

  http.Response _ok(Object? data) => http.Response(
    jsonEncode({'success': true, 'data': data}),
    200,
    headers: {'content-type': 'application/json'},
  );
}
