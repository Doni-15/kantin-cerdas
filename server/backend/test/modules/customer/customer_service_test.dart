import 'dart:typed_data';

import 'package:kantin_cerdas_backend/src/modules/customer/application/customer_service.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/domain/customer_errors.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/domain/customer_store.dart';
import 'package:test/test.dart';

const _customerId = '11111111-1111-1111-1111-111111111111';
const _stallId = '22222222-2222-2222-2222-222222222222';
const _menuId = '33333333-3333-3333-3333-333333333333';
const _itemId = '44444444-4444-4444-4444-444444444444';
const _orderId = '55555555-5555-5555-5555-555555555555';
const _attemptId = '66666666-6666-6666-6666-666666666666';

void main() {
  late _SpyCustomerStore store;
  late List<String> mediaPaths;
  late CustomerService service;

  setUp(() {
    store = _SpyCustomerStore();
    mediaPaths = [];
    service = CustomerService(
      store: store,
      readMedia: (path) async {
        mediaPaths.add(path);
        return Uint8List.fromList([1, 2, 3]);
      },
    );
  });

  test(
    'delegates every CustomerStore operation with supplied IDs and inputs',
    () async {
      await service.getStallDetail(_stallId);
      await service.getMenuDetail(_menuId);
      await service.getCart(_customerId);
      await service.addCartItem(
        _customerId,
        menuId: _menuId,
        quantity: 2,
        itemNote: 'tanpa sambal',
        replaceStall: true,
      );
      await service.updateCartItem(
        _customerId,
        itemId: _itemId,
        quantity: 3,
        itemNote: 'sedikit pedas',
      );
      await service.setCartNote(_customerId, generalNote: 'antar ke meja');
      await service.acknowledgeCartPrices(_customerId, expectedVersion: 7);
      await service.clearCart(_customerId);
      await service.createCheckoutAttempt(_customerId, expectedVersion: 8);
      await service.getOrderByAttempt(_customerId, attemptId: _attemptId);
      await service.checkout(
        _customerId,
        customerName: 'Customer',
        attemptId: _attemptId,
        expectedVersion: 8,
      );
      await service.listOrders(
        _customerId,
        scope: 'history',
        limit: 20,
        offset: 5,
      );
      await service.getOrder(_customerId, orderId: _orderId);
      await service.cancelOrder(_customerId, orderId: _orderId);
      await service.getOwnerApplicationState(_customerId);
      await service.submitOwnerApplication(
        _customerId,
        plannedStallName: 'Kantin Baru',
        plannedLocation: 'Blok C',
        reason: 'Menyediakan makanan sehat',
      );
      await service.getAdminActiveOrderIndicator(_customerId);

      expect(store.invocations.map((call) => call.memberName), [
        #getStallDetail,
        #getMenuDetail,
        #getCart,
        #addCartItem,
        #updateCartItem,
        #setCartNote,
        #acknowledgeCartPrices,
        #clearCart,
        #createCheckoutAttempt,
        #getOrderByAttempt,
        #checkout,
        #listOrders,
        #getOrder,
        #cancelOrder,
        #getOwnerApplicationState,
        #submitOwnerApplication,
        #getAdminActiveOrderIndicator,
      ]);

      for (final call in store.invocations.skip(2)) {
        expect(call.positionalArguments.first, _customerId);
      }
      expect(store.invocations[3].namedArguments[#menuId], _menuId);
      expect(store.invocations[3].namedArguments[#quantity], 2);
      expect(store.invocations[3].namedArguments[#replaceStall], isTrue);
      expect(store.invocations[10].namedArguments[#attemptId], _attemptId);
      expect(store.invocations[11].namedArguments[#scope], 'history');
      expect(
        store.invocations[15].namedArguments[#plannedStallName],
        'Kantin Baru',
      );
      expect(store.invocations[16].positionalArguments.single, _customerId);
    },
  );

  test(
    'turns missing stall, menu, and order records into domain failures',
    () async {
      store.stallDetail = null;
      store.menuDetail = null;
      store.order = null;

      await expectLater(
        service.getStallDetail(_stallId),
        throwsA(
          isA<CustomerFailure>().having(
            (failure) => failure.code,
            'code',
            CustomerFailureCode.stallNotFound,
          ),
        ),
      );
      await expectLater(
        service.getMenuDetail(_menuId),
        throwsA(
          isA<CustomerFailure>().having(
            (failure) => failure.code,
            'code',
            CustomerFailureCode.menuNotFound,
          ),
        ),
      );
      await expectLater(
        service.getOrder(_customerId, orderId: _orderId),
        throwsA(
          isA<CustomerFailure>().having(
            (failure) => failure.code,
            'code',
            CustomerFailureCode.orderNotFound,
          ),
        ),
      );
    },
  );

  test('reads private photos only when a stored path is present', () async {
    store.stallPhotoPath = 'stalls/$_stallId/photo.jpg';
    store.menuPhotoPath = 'menus/$_menuId/photo.jpg';

    final stallPhoto = await service.readStallPhoto(_stallId);
    final menuPhoto = await service.readMenuPhoto(_menuId);

    expect(stallPhoto, Uint8List.fromList([1, 2, 3]));
    expect(menuPhoto, Uint8List.fromList([1, 2, 3]));
    expect(mediaPaths, [
      'stalls/$_stallId/photo.jpg',
      'menus/$_menuId/photo.jpg',
    ]);

    store.stallPhotoPath = '  ';
    store.menuPhotoPath = null;
    expect(await service.readStallPhoto(_stallId), isNull);
    expect(await service.readMenuPhoto(_menuId), isNull);
    expect(mediaPaths, hasLength(2));
  });
}

class _SpyCustomerStore implements CustomerStore {
  final invocations = <Invocation>[];
  Map<String, Object?>? stallDetail = {'stall': const {}};
  Map<String, Object?>? menuDetail = {'menu': const {}};
  Map<String, Object?>? order = {'id': _orderId};
  String? stallPhotoPath;
  String? menuPhotoPath;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    invocations.add(invocation);
    return switch (invocation.memberName) {
      #getStallDetail => Future<Map<String, Object?>?>.value(stallDetail),
      #getMenuDetail => Future<Map<String, Object?>?>.value(menuDetail),
      #getStallPhotoPath => Future<String?>.value(stallPhotoPath),
      #getMenuPhotoPath => Future<String?>.value(menuPhotoPath),
      #getOrder => Future<Map<String, Object?>?>.value(order),
      _ => Future<Map<String, Object?>>.value({'ok': true}),
    };
  }
}
