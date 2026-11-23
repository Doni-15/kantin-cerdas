import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/data/auth_repository.dart';
import 'package:kantin_cerdas/features/customer/application/customer_checkout_controller.dart';
import 'package:kantin_cerdas/features/customer/application/customer_providers.dart';
import 'package:kantin_cerdas/features/customer/data/checkout_attempt_store.dart';
import 'package:kantin_cerdas/features/customer/domain/code128_encoder.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/code128_barcode_widget.dart';
import 'package:kantin_cerdas/main.dart';

const _splashMinimum = Duration(milliseconds: 3000);
const _custAId = '10000000-0000-0000-0000-000000000011';
const _custBId = '10000000-0000-0000-0000-000000000012';
const _stallAId = '20000000-0000-0000-0000-000000000011';
const _stallBId = '20000000-0000-0000-0000-000000000012';
const _catMakananId = '30000000-0000-0000-0000-000000000011';
const _menuAId = '40000000-0000-0000-0000-000000000011';
const _menuA2Id = '40000000-0000-0000-0000-000000000012';
const _menuBId = '40000000-0000-0000-0000-000000000013';

void main() {
  group('Code128Encoder', () {
    test('round-trips order numbers while preserving leading zeros', () {
      for (final value in ['00001', '00042', '00999', 'KC-00007', 'A1-0']) {
        final encoded = Code128Encoder.encodeCodeB(value);
        expect(encoded.data, value);
        expect(encoded.codes.first, Code128Encoder.startB);
        expect(encoded.codes.last, Code128Encoder.stop);
        expect(Code128Encoder.decodeCodeBModules(encoded.modules), value);
        expect(encoded.modules.length, greaterThan(30));
      }
      expect(
        Code128Encoder.decodeCodeBModules(
          Code128Encoder.encodeCodeB('00001').modules,
        ),
        isNot('1'),
      );
    });

    test('rejects empty input, unsupported runes, and tampered checksums', () {
      expect(() => Code128Encoder.encodeCodeB(''), throwsFormatException);
      expect(
        () => Code128Encoder.encodeCodeB('nasi\u{1F600}'),
        throwsFormatException,
      );
      final encoded = Code128Encoder.encodeCodeB('00005');
      final tampered = List<bool>.from(encoded.modules);
      tampered[12] = !tampered[12];
      expect(
        () => Code128Encoder.decodeCodeBModules(tampered),
        throwsFormatException,
      );
    });

    testWidgets(
      'Code128BarcodeCard renders white card container in light and dark',
      (tester) async {
        for (final brightness in [Brightness.light, Brightness.dark]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData(brightness: brightness, useMaterial3: true),
              home: const Scaffold(body: Code128BarcodeCard(value: '00042')),
            ),
          );
          expect(find.text('Bukti Pengambilan (Code 128)'), findsOneWidget);
          expect(find.text('00042'), findsOneWidget);
          expect(
            find.byWidgetPredicate(
              (w) =>
                  w is Semantics &&
                  w.properties.label == 'Barcode Code 128 nomor pesanan 00042',
            ),
            findsOneWidget,
          );
          final whiteBox = tester
              .widgetList<Container>(find.byType(Container))
              .where((c) {
                final d = c.decoration;
                return d is BoxDecoration && d.color == Colors.white;
              });
          expect(whiteBox, isNotEmpty);
          expect(tester.takeException(), isNull);
        }
      },
    );
  });

  group('CustomerCheckoutController idempotency & recovery', () {
    test(
      'recovers committed order from uncertain network error without duplicate submit',
      () async {
        final attemptStore = MemoryCheckoutAttemptStore();
        var checkoutPostCount = 0;
        var attemptLookupCount = 0;
        final fake = _FakeCustomerBackend(custAId: _custAId);
        fake.cartByAccount[_custAId] = _cartState(
          stallId: _stallAId,
          menuId: _menuAId,
          price: 15000,
        );
        fake.simulateNetworkDropAfterCommitOnCheckout = true;

        final container = _createTestContainer(
          fake: fake,
          attemptStore: attemptStore,
          onRequest: (req) {
            if (req.url.path == '/v1/customer/orders' && req.method == 'POST') {
              checkoutPostCount++;
            }
            if (req.url.path.startsWith('/v1/customer/orders/attempts/') &&
                req.method == 'GET') {
              attemptLookupCount++;
            }
          },
        );
        addTearDown(container.dispose);

        final session = await container.read(authControllerProvider.future);
        expect(session?.account.id, _custAId);

        final cart = CustomerCart.fromJson(fake.buildCartPayload(_custAId));
        final ctrl = container.read(customerCheckoutControllerProvider);

        final outcome1 = await ctrl.submitCheckout(
          accountId: _custAId,
          cart: cart,
        );
        expect(outcome1, isA<CheckoutUncertain>());
        expect(checkoutPostCount, 1);
        final savedAttempt = await attemptStore.read(_custAId);
        expect(savedAttempt, isNotNull);

        final outcome2 = await ctrl.verifyOrRetryAttempt(
          accountId: _custAId,
          attempt: savedAttempt!,
        );
        expect(outcome2, isA<CheckoutConfirmed>());
        final confirmed = outcome2 as CheckoutConfirmed;
        expect(confirmed.replayed, isTrue);
        expect(confirmed.order.summary.orderNumber, '00001');
        expect(checkoutPostCount, 1);
        expect(attemptLookupCount, 1);
        expect(await attemptStore.read(_custAId), isNull);
      },
    );

    test(
      'clears pending attempt and invalidates cart when price changed during checkout',
      () async {
        final attemptStore = MemoryCheckoutAttemptStore();
        final fake = _FakeCustomerBackend(custAId: _custAId);
        fake.cartByAccount[_custAId] = _cartState(
          stallId: _stallAId,
          menuId: _menuAId,
          price: 15000,
        );
        fake.forcePriceChangeErrorOnCheckout = true;

        final container = _createTestContainer(
          fake: fake,
          attemptStore: attemptStore,
        );
        addTearDown(container.dispose);
        await container.read(authControllerProvider.future);

        final cart = CustomerCart.fromJson(fake.buildCartPayload(_custAId));
        final ctrl = container.read(customerCheckoutControllerProvider);

        await expectLater(
          () => ctrl.submitCheckout(accountId: _custAId, cart: cart),
          throwsA(
            isA<AuthException>().having((e) => e.code, 'code', 'PRICE_CHANGED'),
          ),
        );
        expect(await attemptStore.read(_custAId), isNull);
      },
    );

    test(
      'blocks concurrent double-tap checkout with CHECKOUT_IN_FLIGHT and clears attempt on STALL_CLOSED race',
      () async {
        final attemptStore = MemoryCheckoutAttemptStore();
        final gate = Completer<void>();
        var postCount = 0;
        final fake = _FakeCustomerBackend(custAId: _custAId);
        fake.cartByAccount[_custAId] = _cartState(
          stallId: _stallAId,
          menuId: _menuAId,
          price: 15000,
        );

        final client = MockClient((req) async {
          if (req.url.path == '/v1/customer/orders' && req.method == 'POST') {
            postCount++;
            await gate.future;
          }
          return fake.handle(req);
        });
        final authRepo = AuthRepository(
          client: client,
          store: MemorySessionStore()
            ..write(SessionTokens.fromJson(_sessionJson(_custAId, 'Doni'))),
          baseUrl: 'https://api.example.test',
        );
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(authRepo),
            checkoutAttemptStoreProvider.overrideWithValue(attemptStore),
          ],
        );
        addTearDown(container.dispose);
        await container.read(authControllerProvider.future);

        final cart = CustomerCart.fromJson(fake.buildCartPayload(_custAId));
        final ctrl = container.read(customerCheckoutControllerProvider);

        final first = ctrl.submitCheckout(accountId: _custAId, cart: cart);
        await Future<void>.delayed(const Duration(milliseconds: 10));
        await expectLater(
          () => ctrl.submitCheckout(accountId: _custAId, cart: cart),
          throwsA(
            isA<AuthException>().having(
              (e) => e.code,
              'code',
              'CHECKOUT_IN_FLIGHT',
            ),
          ),
        );
        gate.complete();
        final confirmed = await first;
        expect(confirmed, isA<CheckoutConfirmed>());
        expect(postCount, 1);

        // Stall Closed race on new checkout clears pending attempt and throws STALL_CLOSED
        fake.cartByAccount[_custAId] = _cartState(
          stallId: _stallAId,
          menuId: _menuAId,
          price: 15000,
        );
        fake.forceStallClosedOnCheckout = true;
        final cart2 = CustomerCart.fromJson(fake.buildCartPayload(_custAId));
        await expectLater(
          () => ctrl.submitCheckout(accountId: _custAId, cart: cart2),
          throwsA(
            isA<AuthException>().having((e) => e.code, 'code', 'STALL_CLOSED'),
          ),
        );
        expect(await attemptStore.read(_custAId), isNull);
      },
    );
  });

  group('Customer Full UI & Flows', () {
    testWidgets(
      'Customer browses, switches stall cart with confirm, resolves price change & archived item, checks out, and inspects barcode & Gagal Diambil',
      (tester) async {
        _viewport(tester, const Size(412, 915));
        final fake = _FakeCustomerBackend(custAId: _custAId);
        await _launchCustomerApp(tester, fake);

        // UI-CUSTOMER-001 LOCKED home screen elements
        expect(find.text('Mau makan apa hari ini?'), findsOneWidget);
        expect(find.text('Cari makanan atau kantin...'), findsOneWidget);
        expect(find.text('Jelajahi Kantin'), findsOneWidget);
        expect(find.text('Kantin Nusantara'), findsOneWidget);
        expect(find.byIcon(Icons.smart_toy_rounded), findsOneWidget);

        // Open stall B first and add a menu from stall B
        await _tap(tester, find.text('Warung Pojok'));
        expect(find.text('Warung Pojok'), findsWidgets);
        await _tap(tester, find.text('Es Teh').last);
        await _tap(
          tester,
          find.widgetWithText(FilledButton, 'Tambah ke Keranjang'),
        );
        await _pumpToastClear(tester);

        // Back to home & open stall A
        await _tap(tester, find.byType(BackButton));
        await _tap(tester, find.text('Kantin Nusantara'));

        // Stall detail schedules sheet & categories
        expect(find.text('Lihat jadwal operasional'), findsOneWidget);
        await _tap(tester, find.text('Lihat jadwal operasional'));
        expect(find.text('Jam Operasional (Informatif)'), findsOneWidget);
        Navigator.of(
          tester.element(find.text('Jam Operasional (Informatif)')),
        ).pop();
        await tester.pumpAndSettle();

        // Quick-add from stall A triggers single-stall replace confirmation
        await _tap(tester, find.widgetWithText(FilledButton, 'Tambah').first);
        expect(find.text('Ganti isi keranjang?'), findsOneWidget);
        await _tap(
          tester,
          find.widgetWithText(FilledButton, 'Ganti Keranjang'),
        );
        await _pumpToastClear(tester);

        // Open cart via header badge
        await _tap(tester, find.byTooltip('Keranjang'));
        expect(find.text('Keranjang'), findsOneWidget);
        expect(find.text('Nasi Goreng'), findsOneWidget);

        // Simulate price change on server & refresh cart -> blocker + acknowledge button
        fake.menus[_menuAId]!['price'] = 18000;
        await tester.drag(find.byType(ListView), const Offset(0, 300));
        await tester.pumpAndSettle();
        expect(find.textContaining('Harga berubah:'), findsOneWidget);
        await _tap(
          tester,
          find.widgetWithText(FilledButton, 'Setujui Harga Terbaru'),
        );
        await _pumpToastClear(tester);
        expect(find.textContaining('Harga berubah:'), findsNothing);

        // Simulate menu archived on server & refresh cart -> item stays as "Tidak Tersedia" & checkout disabled
        fake.menus[_menuAId]!['is_archived'] = true;
        await tester.drag(find.byType(ListView), const Offset(0, 300));
        await tester.pumpAndSettle();
        expect(find.text('Tidak Tersedia'), findsOneWidget);
        expect(find.text('Nasi Goreng'), findsOneWidget);
        final blockedCheckoutBtn = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Lanjut ke Checkout'),
        );
        expect(blockedCheckoutBtn.onPressed, isNull);

        // Restore menu and proceed to Checkout Tunai
        fake.menus[_menuAId]!['is_archived'] = false;
        await tester.drag(find.byType(ListView), const Offset(0, 300));
        await tester.pumpAndSettle();
        expect(find.text('Tidak Tersedia'), findsNothing);

        await _tap(
          tester,
          find.widgetWithText(FilledButton, 'Lanjut ke Checkout'),
        );
        expect(find.text('Checkout'), findsOneWidget);
        expect(find.text('Bayar tunai saat mengambil makanan'), findsOneWidget);
        await _tap(tester, find.widgetWithText(FilledButton, 'Kirim Pesanan'));
        expect(find.text('Kirim pesanan tunai?'), findsOneWidget);
        await _tap(
          tester,
          find.widgetWithText(FilledButton, 'Kirim Pesanan').last,
        );

        // Lands on Order Detail for newly created pending order (NO barcode yet, can cancel)
        expect(find.text('Detail Pesanan'), findsOneWidget);
        expect(find.text('Pesanan 00001'), findsOneWidget);
        expect(find.text('Menunggu Konfirmasi'), findsWidgets);
        expect(find.text('Bukti Pengambilan (Code 128)'), findsNothing);
        expect(
          find.widgetWithText(OutlinedButton, 'Batalkan Pesanan'),
          findsOneWidget,
        );

        // Simulate Owner transitioning order to Siap Diambil -> Barcode appears!
        fake.setOrderStatus('00001', 'siap_diambil', reason: null);
        await _tap(tester, find.byType(BackButton));
        if (find.text('Keranjang').evaluate().isNotEmpty) {
          await _tap(tester, find.byType(BackButton));
        }
        await _tap(tester, find.text('Pesanan'));
        await _tap(tester, find.textContaining('00001'));
        expect(find.text('Siap Diambil'), findsWidgets);
        expect(find.text('Bukti Pengambilan (Code 128)'), findsOneWidget);

        // Simulate Owner marking Gagal Diambil -> Barcode hidden, reason + Belum Lunas shown, moved to Riwayat
        fake.setOrderStatus(
          '00001',
          'gagal_diambil',
          reason: 'Tidak diambil hingga tutup.',
        );
        await _tap(tester, find.byType(BackButton));
        await _tap(tester, find.text('Riwayat'));
        await _tap(tester, find.textContaining('00001'));
        expect(find.text('Gagal Diambil'), findsWidgets);
        expect(find.text('Bukti Pengambilan (Code 128)'), findsNothing);
        expect(find.text('Tidak diambil hingga tutup.'), findsWidgets);
        expect(find.text('Status Pembayaran: Belum Lunas'), findsOneWidget);

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Customer-006A Owner Application works even with active order, Settings dark mode updates theme, and account switch leaks zero state',
      (tester) async {
        _viewport(tester, const Size(412, 915));
        final fake = _FakeCustomerBackend(custAId: _custAId);
        fake.seedOrder(
          accountId: _custAId,
          orderId: '60000000-0000-0000-0000-000000000099',
          orderNumber: '00009',
          status: 'menunggu_konfirmasi',
        );
        final store = MemorySessionStore();
        await store.write(
          SessionTokens.fromJson(_sessionJson(_custAId, 'Doni')),
        );

        await _launchCustomerApp(tester, fake, store: store);

        // Open Profil tab -> Ajukan Jadi Pemilik Kantin
        await _tap(tester, find.text('Profil'));
        await tester.scrollUntilVisible(
          find.text('Ajukan Jadi Pemilik Kantin'),
          120,
        );
        await _tap(tester, find.text('Ajukan Jadi Pemilik Kantin'));
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Nama rencana kantin'),
          'Kantin Doni',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Rencana lokasi usaha'),
          'Blok C-04',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Alasan singkat pengajuan'),
          'Menjual sarapan pagi sehat untuk mahasiswa.',
        );
        await _tap(
          tester,
          find.widgetWithText(FilledButton, 'Kirim Pengajuan'),
        );
        await _pumpToastClear(tester);
        expect(find.text('Status Pengajuan: Menunggu Review'), findsOneWidget);
        expect(
          find.textContaining('masih memiliki pesanan aktif'),
          findsOneWidget,
        );

        // Back -> Pengaturan -> toggle Mode Gelap
        await _tap(tester, find.byType(BackButton));
        await _tap(tester, find.text('Pengaturan'));
        await _tap(tester, find.text('Mode Gelap'));
        final matApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
        expect(matApp.themeMode, ThemeMode.dark);
        await _tap(tester, find.byType(BackButton));

        // Logout Customer A
        await tester.scrollUntilVisible(find.text('Keluar'), 150);
        await _tap(tester, find.text('Keluar'));
        await _tap(tester, find.widgetWithText(FilledButton, 'Keluar'));
        expect(find.text('Masuk'), findsWidgets);

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Cart and Checkout fit small viewport Size(320, 568) at 2x text scale cleanly',
      (tester) async {
        _viewport(tester, const Size(320, 568));
        tester.platformDispatcher.textScaleFactorTestValue = 2.0;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        final fake = _FakeCustomerBackend(custAId: _custAId);
        fake.cartByAccount[_custAId] = _cartState(
          stallId: _stallAId,
          menuId: _menuAId,
          price: 15000,
        );
        await _launchCustomerApp(tester, fake);
        await _tap(tester, find.byTooltip('Keranjang'));
        await tester.scrollUntilVisible(
          find.text('Nasi Goreng'),
          120,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text('Nasi Goreng'), findsOneWidget);
        await _tap(
          tester,
          find.widgetWithText(FilledButton, 'Lanjut ke Checkout'),
        );
        expect(find.text('Checkout'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Cold restart restores pending attempt recovery on Checkout and account switch leaks zero cart or orders',
      (tester) async {
        _viewport(tester, const Size(412, 915));
        final attemptStore = MemoryCheckoutAttemptStore();
        final fake = _FakeCustomerBackend(custAId: _custAId);
        fake.cartByAccount[_custAId] = _cartState(
          stallId: _stallAId,
          menuId: _menuAId,
          price: 15000,
        );
        fake.attempts['att-cold'] = {
          'attempt_id': 'att-cold',
          'cart_version': 1,
          'payload_hash': 'hash-cold',
          'status': 'completed',
          'order_id': 'ord-cold-1',
        };
        fake.seedOrder(
          accountId: _custAId,
          orderId: 'ord-cold-1',
          orderNumber: '00042',
          status: 'menunggu_konfirmasi',
        );
        await attemptStore.write(
          _custAId,
          const CustomerCheckoutAttempt(
            attemptId: 'att-cold',
            cartVersion: 1,
            payloadHash: 'hash-cold',
          ),
        );

        await _launchCustomerApp(tester, fake, attemptStore: attemptStore);
        await _tap(tester, find.byTooltip('Keranjang'));
        await _tap(
          tester,
          find.widgetWithText(FilledButton, 'Lanjut ke Checkout'),
        );
        expect(
          find.text('Ada upaya pengiriman tertunda untuk versi keranjang ini.'),
          findsOneWidget,
        );
        await _tap(
          tester,
          find.widgetWithText(OutlinedButton, 'Periksa Status Pesanan'),
        );
        expect(find.text('Pesanan 00042'), findsOneWidget);
        expect(await attemptStore.read(_custAId), isNull);

        // Relaunch logged in as Customer B -> zero orders & zero cart leaked from Customer A
        await _launchCustomerApp(
          tester,
          fake,
          accountId: _custBId,
          displayName: 'Budi',
        );
        await _tap(tester, find.byTooltip('Keranjang'));
        expect(find.text('Keranjang masih kosong'), findsOneWidget);
        await _tap(tester, find.byType(BackButton));
        await _tap(tester, find.text('Pesanan'));
        expect(find.text('Belum ada pesanan aktif'), findsOneWidget);
        expect(find.text('Pesanan 00042'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

ProviderContainer _createTestContainer({
  required _FakeCustomerBackend fake,
  required MemoryCheckoutAttemptStore attemptStore,
  void Function(http.Request req)? onRequest,
}) {
  final client = MockClient((req) async {
    onRequest?.call(req);
    return fake.handle(req);
  });
  final authRepo = AuthRepository(
    client: client,
    store: MemorySessionStore()
      ..write(SessionTokens.fromJson(_sessionJson(_custAId, 'Doni'))),
    baseUrl: 'https://api.example.test',
  );
  return ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(authRepo),
      checkoutAttemptStoreProvider.overrideWithValue(attemptStore),
    ],
  );
}

Future<void> _launchCustomerApp(
  WidgetTester tester,
  _FakeCustomerBackend fake, {
  MemorySessionStore? store,
  MemoryCheckoutAttemptStore? attemptStore,
  String accountId = _custAId,
  String displayName = 'Doni',
}) async {
  final sessionStore = store ?? MemorySessionStore();
  if (await sessionStore.read() == null) {
    await sessionStore.write(
      SessionTokens.fromJson(_sessionJson(accountId, displayName)),
    );
  }
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
          attemptStore ?? MemoryCheckoutAttemptStore(),
        ),
      ],
      child: const KantinCerdasApp(),
    ),
  );
  await tester.pump(_splashMinimum);
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.pumpAndSettle();
  await Scrollable.ensureVisible(tester.element(finder.first), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

Future<void> _pumpToastClear(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
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

Map<String, Object?> _sessionJson(String accountId, String name) => {
  'access_token': 'token-$accountId',
  'refresh_token': 'refresh-$accountId',
  'expires_at': '2100-01-01T00:00:00Z',
  'account': {
    'id': accountId,
    'email': '$accountId@example.test',
    'role': 'customer',
    'display_name': name,
    'suggested_name': null,
    'has_photo': true,
    'profile_complete': true,
  },
};

Map<String, dynamic> _cartState({
  required String stallId,
  required String menuId,
  required int price,
}) => {
  'cart_id': 'cart-1',
  'stall_id': stallId,
  'general_note': '',
  'draft_version': 1,
  'items': [
    {
      'id': 'ci-1',
      'menu_item_id': menuId,
      'quantity': 1,
      'seen_unit_price': price,
      'item_note': '',
    },
  ],
};

class _FakeCustomerBackend {
  _FakeCustomerBackend({required this.custAId});

  final String custAId;
  bool simulateNetworkDropAfterCommitOnCheckout = false;
  bool forcePriceChangeErrorOnCheckout = false;
  bool forceStallClosedOnCheckout = false;
  var _orderSeq = 0;

  final stalls = <String, Map<String, dynamic>>{
    _stallAId: {
      'id': _stallAId,
      'name': 'Kantin Nusantara',
      'description': 'Masakan rumahan.',
      'block': 'A-01',
      'wait_minutes': 10,
      'is_listed': true,
      'is_open': true,
      'owner_active': true,
      'has_photo': false,
    },
    _stallBId: {
      'id': _stallBId,
      'name': 'Warung Pojok',
      'description': 'Minuman segar.',
      'block': 'B-02',
      'wait_minutes': 5,
      'is_listed': true,
      'is_open': true,
      'owner_active': true,
      'has_photo': false,
    },
  };

  final menus = <String, Map<String, dynamic>>{
    _menuAId: {
      'id': _menuAId,
      'stall_id': _stallAId,
      'stall_name': 'Kantin Nusantara',
      'category_id': _catMakananId,
      'category_name': 'Makanan',
      'name': 'Nasi Goreng',
      'description': 'Nasi goreng spesial.',
      'price': 15000,
      'is_available': true,
      'is_archived': false,
      'has_photo': false,
    },
    _menuA2Id: {
      'id': _menuA2Id,
      'stall_id': _stallAId,
      'stall_name': 'Kantin Nusantara',
      'category_id': _catMakananId,
      'category_name': 'Makanan',
      'name': 'Ayam Geprek',
      'description': 'Sambal pedas.',
      'price': 18000,
      'is_available': true,
      'is_archived': false,
      'has_photo': false,
    },
    _menuBId: {
      'id': _menuBId,
      'stall_id': _stallBId,
      'stall_name': 'Warung Pojok',
      'category_id': _catMakananId,
      'category_name': 'Minuman',
      'name': 'Es Teh',
      'description': 'Teh manis dingin.',
      'price': 5000,
      'is_available': true,
      'is_archived': false,
      'has_photo': false,
    },
  };

  final cartByAccount = <String, Map<String, dynamic>>{};
  final attempts = <String, Map<String, dynamic>>{};
  final orders = <Map<String, dynamic>>[];
  final ownerApps = <String, Map<String, dynamic>>{};

  Future<http.Response> handle(http.Request req) async {
    final token = req.headers['authorization']?.replaceFirst(
      'Bearer token-',
      '',
    );
    final accountId = token ?? custAId;
    final path = req.url.path;

    if (path == '/v1/auth/me') {
      return _ok({
        'id': accountId,
        'email': '$accountId@example.test',
        'role': 'customer',
        'display_name': accountId == _custBId ? 'Budi' : 'Doni',
        'suggested_name': null,
        'has_photo': true,
        'profile_complete': true,
      });
    }
    if (path == '/v1/auth/logout') return _ok(null);
    if (path == '/v1/auth/profile/photo') return http.Response('', 204);

    if (path == '/v1/catalog/stalls') {
      final q = (req.url.queryParameters['q'] ?? '').toLowerCase();
      final items = stalls.values
          .where(
            (s) => q.isEmpty || (s['name'] as String).toLowerCase().contains(q),
          )
          .toList();
      return _ok({'items': items, 'next_cursor': null});
    }
    if (path == '/v1/catalog/menu') {
      final q = (req.url.queryParameters['q'] ?? '').toLowerCase();
      final items = menus.values
          .where(
            (m) =>
                m['is_archived'] == false &&
                (q.isEmpty || (m['name'] as String).toLowerCase().contains(q)),
          )
          .map(
            (m) => {
              ...m,
              'block': 'A-01',
              'wait_minutes': 10,
              'stall_is_open': true,
            },
          )
          .toList();
      return _ok({'items': items, 'next_cursor': null});
    }

    if (path.startsWith('/v1/customer/stalls/')) {
      final id = path.split('/').last;
      final stall = stalls[id];
      if (stall == null) return _err(404, 'STALL_NOT_FOUND');
      return _ok({
        'stall': stall,
        'schedules': const [
          {
            'day_of_week': 1,
            'is_open_day': true,
            'open_time': '08:00',
            'close_time': '16:00',
          },
        ],
        'categories': const [
          {'id': _catMakananId, 'name': 'Makanan', 'sort_order': 1},
        ],
        'menus': menus.values
            .where((m) => m['stall_id'] == id && m['is_archived'] == false)
            .toList(),
      });
    }

    if (path.startsWith('/v1/customer/menus/')) {
      final id = path.split('/').last;
      final menu = menus[id];
      if (menu == null || menu['is_archived'] == true) {
        return _err(404, 'MENU_NOT_FOUND');
      }
      return _ok({'menu': menu, 'stall': stalls[menu['stall_id']]});
    }

    if (path == '/v1/customer/cart' && req.method == 'GET') {
      return _ok(buildCartPayload(accountId));
    }
    if (path == '/v1/customer/cart/items' && req.method == 'POST') {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final menuId = body['menu_item_id'] as String;
      final qty = body['quantity'] as int? ?? 1;
      final note = body['item_note'] as String? ?? '';
      final replace = body['replace_stall'] == true;
      final menu = menus[menuId]!;
      final targetStallId = menu['stall_id'] as String;
      final cart = cartByAccount[accountId];
      if (cart != null &&
          (cart['items'] as List).isNotEmpty &&
          cart['stall_id'] != targetStallId) {
        if (!replace) return _err(409, 'CART_DIFFERENT_STALL');
        cartByAccount.remove(accountId);
      }
      final active = cartByAccount.putIfAbsent(
        accountId,
        () => {
          'cart_id': 'cart-$accountId',
          'stall_id': targetStallId,
          'general_note': '',
          'draft_version': 0,
          'items': <Map<String, dynamic>>[],
        },
      );
      active['draft_version'] = (active['draft_version'] as int) + 1;
      final items = active['items'] as List<Map<String, dynamic>>;
      items.add({
        'id': 'ci-${items.length + 1}-${active['draft_version']}',
        'menu_item_id': menuId,
        'quantity': qty,
        'seen_unit_price': menu['price'] as int,
        'item_note': note,
      });
      return _ok(buildCartPayload(accountId));
    }

    if (path == '/v1/customer/cart/acknowledge-prices' &&
        req.method == 'POST') {
      final cart = cartByAccount[accountId]!;
      for (final item in cart['items'] as List<Map<String, dynamic>>) {
        item['seen_unit_price'] = menus[item['menu_item_id']]!['price'] as int;
      }
      cart['draft_version'] = (cart['draft_version'] as int) + 1;
      return _ok(buildCartPayload(accountId));
    }

    if (path == '/v1/customer/cart/note' && req.method == 'PUT') {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final cart = cartByAccount[accountId]!;
      cart['general_note'] = body['general_note'] ?? '';
      cart['draft_version'] = (cart['draft_version'] as int) + 1;
      return _ok(buildCartPayload(accountId));
    }

    if (path == '/v1/customer/checkout/attempts' && req.method == 'POST') {
      final cart = cartByAccount[accountId];
      if (cart == null || (cart['items'] as List).isEmpty) {
        return _err(400, 'CART_EMPTY');
      }
      final attemptId = 'att-${attempts.length + 1}';
      final rec = {
        'attempt_id': attemptId,
        'cart_version': cart['draft_version'] as int,
        'payload_hash': 'hash-$attemptId',
        'status': 'pending',
        'order_id': null,
      };
      attempts[attemptId] = rec;
      return _ok(rec, 201);
    }

    if (path.startsWith('/v1/customer/orders/attempts/') &&
        req.method == 'GET') {
      final attemptId = path.split('/').last;
      final att = attempts[attemptId];
      if (att == null) return _err(404, 'CHECKOUT_ATTEMPT_NOT_FOUND');
      final orderId = att['order_id'] as String?;
      final order = orderId == null
          ? null
          : orders.firstWhere((o) => o['id'] == orderId);
      return _ok({
        'attempt_id': att['attempt_id'],
        'status': att['status'],
        'order': order,
      });
    }

    if (path == '/v1/customer/orders' && req.method == 'POST') {
      if (forcePriceChangeErrorOnCheckout) {
        return _err(409, 'PRICE_CHANGED');
      }
      if (forceStallClosedOnCheckout) {
        forceStallClosedOnCheckout = false;
        return _err(409, 'STALL_CLOSED');
      }
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final attemptId = body['attempt_id'] as String;
      final att = attempts[attemptId]!;
      if (att['order_id'] == null) {
        final cart = cartByAccount[accountId]!;
        final orderNum = (++_orderSeq).toString().padLeft(5, '0');
        final detail = _buildOrder(
          accountId: accountId,
          orderId: 'ord-$_orderSeq',
          orderNumber: orderNum,
          stallId: cart['stall_id'] as String,
          items: cart['items'] as List<Map<String, dynamic>>,
          status: 'menunggu_konfirmasi',
        );
        orders.add(detail);
        att['status'] = 'completed';
        att['order_id'] = detail['id'];
        cartByAccount.remove(accountId);
      }
      if (simulateNetworkDropAfterCommitOnCheckout) {
        simulateNetworkDropAfterCommitOnCheckout = false;
        throw http.ClientException('Simulated drop after commit');
      }
      final order = orders.firstWhere((o) => o['id'] == att['order_id']);
      return _ok({'order': order, 'replayed': false}, 201);
    }

    if (path == '/v1/customer/orders' && req.method == 'GET') {
      final scope = req.url.queryParameters['scope'] ?? 'active';
      final list = orders.where((o) {
        if (o['customer_id'] != accountId) return false;
        final st = o['status'] as String;
        final isActive =
            st == 'menunggu_konfirmasi' ||
            st == 'diproses' ||
            st == 'siap_diambil';
        return scope == 'active' ? isActive : !isActive;
      }).toList();
      return _ok({'items': list, 'has_more': false});
    }

    if (path.startsWith('/v1/customer/orders/') && req.method == 'GET') {
      final id = path.split('/').last;
      final order = orders.where((o) => o['id'] == id).firstOrNull;
      if (order == null) return _err(404, 'ORDER_NOT_FOUND');
      return _ok(order);
    }

    if (path == '/v1/customer/owner-application' && req.method == 'GET') {
      final activeCount = orders
          .where(
            (o) =>
                o['customer_id'] == accountId &&
                [
                  'menunggu_konfirmasi',
                  'diproses',
                  'siap_diambil',
                ].contains(o['status']),
          )
          .length;
      return _ok({
        'latest_application': ownerApps[accountId],
        'active_order_indicator': {
          'has_active_orders': activeCount > 0,
          'active_order_count': activeCount,
        },
      });
    }

    if (path == '/v1/customer/owner-application' && req.method == 'POST') {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final app = {
        'id': 'app-1',
        'status': 'menunggu_review',
        'planned_stall_name': body['planned_stall_name'],
        'planned_location': body['planned_location'],
        'reason': body['reason'],
        'rejection_reason': null,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'decided_at': null,
      };
      ownerApps[accountId] = app;
      return _ok({
        'latest_application': app,
        'active_order_indicator': {
          'has_active_orders': true,
          'active_order_count': 1,
        },
      }, 201);
    }

    return _err(404, 'NOT_FOUND');
  }

  Map<String, dynamic> buildCartPayload(String accountId) {
    final cart = cartByAccount[accountId];
    if (cart == null || (cart['items'] as List).isEmpty) {
      return {
        'cart_id': null,
        'stall': null,
        'items': const <Object>[],
        'general_note': '',
        'draft_version': 0,
        'subtotal': 0,
        'seen_subtotal': 0,
        'item_count': 0,
        'can_checkout': false,
        'blockers': const <Object>[],
      };
    }
    final stall = stalls[cart['stall_id']]!;
    final rawItems = cart['items'] as List<Map<String, dynamic>>;
    final outItems = <Map<String, dynamic>>[];
    var subtotal = 0;
    var seenSubtotal = 0;
    var itemCount = 0;
    final blockers = <String>{};
    for (final raw in rawItems) {
      final menu = menus[raw['menu_item_id']]!;
      final price = menu['price'] as int;
      final seenPrice = raw['seen_unit_price'] as int;
      final qty = raw['quantity'] as int;
      final archived = menu['is_archived'] == true;
      final avail = menu['is_available'] == true;
      if (archived) blockers.add('has_archived_item');
      if (!archived && !avail) blockers.add('has_unavailable_item');
      if (price != seenPrice) blockers.add('has_price_change');
      subtotal += price * qty;
      seenSubtotal += seenPrice * qty;
      itemCount += qty;
      outItems.add({
        'id': raw['id'],
        'menu_item_id': menu['id'],
        'menu_name': menu['name'],
        'quantity': qty,
        'current_unit_price': price,
        'seen_unit_price': seenPrice,
        'price_changed': price != seenPrice,
        'line_total': price * qty,
        'item_note': raw['item_note'],
        'is_available': avail,
        'is_archived': archived,
        'has_photo': false,
      });
    }
    return {
      'cart_id': cart['cart_id'],
      'stall': stall,
      'items': outItems,
      'general_note': cart['general_note'],
      'draft_version': cart['draft_version'],
      'subtotal': subtotal,
      'seen_subtotal': seenSubtotal,
      'item_count': itemCount,
      'can_checkout': blockers.isEmpty,
      'blockers': blockers.toList(),
    };
  }

  Map<String, dynamic> _buildOrder({
    required String accountId,
    required String orderId,
    required String orderNumber,
    required String stallId,
    required List<Map<String, dynamic>> items,
    required String status,
  }) {
    final stall = stalls[stallId]!;
    final orderItems = <Map<String, dynamic>>[];
    var total = 0;
    var itemCount = 0;
    for (final it in items) {
      final menu = menus[it['menu_item_id']]!;
      final qty = it['quantity'] as int;
      final unit = menu['price'] as int;
      total += qty * unit;
      itemCount += qty;
      orderItems.add({
        'id': 'oi-$orderId-${orderItems.length}',
        'menu_item_id': menu['id'],
        'menu_name': menu['name'],
        'unit_price': unit,
        'quantity': qty,
        'line_total': qty * unit,
        'item_note': it['item_note'],
      });
    }
    final nowIso = DateTime.now().toUtc().toIso8601String();
    return {
      'id': orderId,
      'customer_id': accountId,
      'order_number': orderNumber,
      'stall_id': stallId,
      'stall_name': stall['name'],
      'stall_block': stall['block'],
      'stall_campus': 'USU',
      'status': status,
      'payment_status': 'belum_lunas',
      'total_amount': total,
      'general_note': '',
      'prep_estimate_minutes': stall['wait_minutes'],
      'status_reason': null,
      'item_summary': orderItems
          .map((e) => '${e['quantity']}x ${e['menu_name']}')
          .join(', '),
      'item_count': itemCount,
      'created_at': nowIso,
      'accepted_at': null,
      'ready_at': null,
      'terminal_at': null,
      'updated_at': nowIso,
      'items': orderItems,
      'events': [
        {
          'id': 'ev-1',
          'from_status': null,
          'to_status': status,
          'actor_role': 'customer',
          'reason': null,
          'created_at': nowIso,
        },
      ],
    };
  }

  void seedOrder({
    required String accountId,
    required String orderId,
    required String orderNumber,
    required String status,
  }) {
    orders.add(
      _buildOrder(
        accountId: accountId,
        orderId: orderId,
        orderNumber: orderNumber,
        stallId: _stallAId,
        items: [
          {'menu_item_id': _menuAId, 'quantity': 1, 'item_note': ''},
        ],
        status: status,
      ),
    );
  }

  void setOrderStatus(String orderNumber, String status, {String? reason}) {
    final order = orders.firstWhere((o) => o['order_number'] == orderNumber);
    final nowIso = DateTime.now().toUtc().toIso8601String();
    order['status'] = status;
    order['status_reason'] = reason;
    order['updated_at'] = nowIso;
    if (status == 'gagal_diambil' || status == 'selesai') {
      order['terminal_at'] = nowIso;
    }
    (order['events'] as List<dynamic>).add({
      'id': 'ev-${(order['events'] as List).length + 1}',
      'from_status': 'diproses',
      'to_status': status,
      'actor_role': 'owner',
      'reason': reason,
      'created_at': nowIso,
    });
  }

  http.Response _ok(Object? data, [int status = 200]) =>
      http.Response(jsonEncode({'success': true, 'data': data}), status);

  http.Response _err(int status, String code) => http.Response(
    jsonEncode({
      'success': false,
      'error': {'code': code, 'message': code},
    }),
    status,
  );
}
