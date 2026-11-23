import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kantin_cerdas_backend/src/app/bootstrap.dart';
import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/errors/owner_errors.dart';
import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_client_factory.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/avatar_store.dart';
import 'package:kantin_cerdas_backend/src/modules/catalog/domain/catalog_store.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/data/supabase_owner_store.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/domain/owner_store.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../../config_test.dart' show validEnvironment;

const _ownerAId = '10000000-0000-0000-0000-000000000001';
const _ownerBId = '10000000-0000-0000-0000-000000000002';
const _customerId = '10000000-0000-0000-0000-000000000003';
const _adminId = '10000000-0000-0000-0000-000000000004';
const _incompleteOwnerId = '10000000-0000-0000-0000-000000000006';

void main() {
  late _MemoryOwnerStore store;
  late _MemoryMediaStore media;
  late Handler app;

  setUp(() {
    store = _MemoryOwnerStore();
    media = _MemoryMediaStore();
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
    app = buildAppHandlerWithOwner(
      config,
      authGateway: _FakeAuthGateway(),
      avatarStore: _FakeAvatarStore(),
      catalogStore: _FakeCatalogStore(),
      ownerStore: store,
      ownerMediaStore: media,
    );
  });

  group('Authorization & Ownership Guards', () {
    test(
      'rejects unauthenticated, customer, admin, inactive, incomplete',
      () async {
        await _expectError(
          await _req(app, 'GET', '/v1/owner/stall'),
          401,
          'INVALID_SESSION',
        );
        await _expectError(
          await _req(app, 'GET', '/v1/owner/stall', token: 'token-customer'),
          403,
          'OWNER_ROLE_REQUIRED',
        );
        await _expectError(
          await _req(app, 'GET', '/v1/owner/stall', token: 'token-admin'),
          403,
          'OWNER_ROLE_REQUIRED',
        );
        await _expectError(
          await _req(app, 'GET', '/v1/owner/stall', token: 'token-inactive'),
          403,
          'ACCOUNT_INACTIVE',
        );
        await _expectError(
          await _req(app, 'GET', '/v1/owner/stall', token: 'token-incomplete'),
          409,
          'PROFILE_INCOMPLETE',
        );
      },
    );

    test(
      'Owner B cannot access or mutate Owner A stall, category, menu, or order',
      () async {
        await _req(
          app,
          'POST',
          '/v1/owner/stall',
          token: 'token-owner-a',
          body: {'name': 'Kantin A', 'campus': 'USU', 'block': 'A-01'},
        );
        final catsRes = await _req(
          app,
          'GET',
          '/v1/owner/categories',
          token: 'token-owner-a',
        );
        final catId =
            ((await _decodeData(catsRes) as Map)['items'] as List).first['id']
                as String;
        final menuRes = await _req(
          app,
          'POST',
          '/v1/owner/menus',
          token: 'token-owner-a',
          body: {
            'name': 'Nasi Uduk',
            'category_id': catId,
            'price': 15000,
            'is_available': true,
          },
        );
        final menuId = (await _decodeData(menuRes) as Map)['id'] as String;
        final orderId = store.seedOrder(
          ownerId: _ownerAId,
          orderNumber: '0042',
        );

        await _req(
          app,
          'POST',
          '/v1/owner/stall',
          token: 'token-owner-b',
          body: {'name': 'Kantin B', 'campus': 'USU', 'block': 'B-01'},
        );

        await _expectError(
          await _req(
            app,
            'PUT',
            '/v1/owner/categories/$catId',
            token: 'token-owner-b',
            body: {'name': 'Bajak'},
          ),
          404,
          'CATEGORY_NOT_FOUND',
        );
        await _expectError(
          await _req(
            app,
            'PUT',
            '/v1/owner/menus/$menuId',
            token: 'token-owner-b',
            body: {
              'name': 'Bajak',
              'category_id': catId,
              'price': 1000,
              'is_available': true,
            },
          ),
          404,
          'MENU_NOT_FOUND',
        );
        await _expectError(
          await _req(
            app,
            'GET',
            '/v1/owner/orders/$orderId',
            token: 'token-owner-b',
          ),
          404,
          'ORDER_NOT_FOUND',
        );
        await _expectError(
          await _req(
            app,
            'GET',
            '/v1/owner/orders/lookup?code=0042',
            token: 'token-owner-b',
          ),
          404,
          'ORDER_NOT_FOUND',
        );
        await _expectError(
          await _req(
            app,
            'POST',
            '/v1/owner/orders/$orderId/accept',
            token: 'token-owner-b',
          ),
          404,
          'ORDER_NOT_FOUND',
        );
      },
    );
  });

  group('Stall, Publish, Open/Close, Categories & Menus', () {
    test(
      'enforces one stall per owner, publish gate, starts closed, and no unpublish',
      () async {
        final empty = await _req(
          app,
          'GET',
          '/v1/owner/stall',
          token: 'token-owner-a',
        );
        expect((await _decodeData(empty) as Map)['stall'], isNull);

        final created = await _req(
          app,
          'POST',
          '/v1/owner/stall',
          token: 'token-owner-a',
          body: {
            'name': 'Dapur A',
            'campus': 'USU',
            'block': 'Blok A',
            'wait_minutes': 12,
          },
        );
        expect(created.statusCode, 201);
        final createdStall =
            (await _decodeData(created) as Map)['stall'] as Map;
        expect(createdStall['is_listed'], isFalse);
        expect(createdStall['is_open'], isFalse);

        // Concurrent or duplicate second stall creation fails
        await _expectError(
          await _req(
            app,
            'POST',
            '/v1/owner/stall',
            token: 'token-owner-a',
            body: {'name': 'Dapur A2', 'campus': 'USU', 'block': 'Blok B'},
          ),
          409,
          'STALL_ALREADY_EXISTS',
        );

        // Cannot open before publish
        await _expectError(
          await _req(
            app,
            'PUT',
            '/v1/owner/stall/open-status',
            token: 'token-owner-a',
            body: {'is_open': true},
          ),
          409,
          'STALL_NOT_PUBLISHED',
        );

        // Cannot publish without available menu
        await _expectError(
          await _req(
            app,
            'POST',
            '/v1/owner/stall/publish',
            token: 'token-owner-a',
          ),
          422,
          'PUBLISH_MENU_REQUIRED',
        );

        // Add sold-out menu -> still rejected
        final cats =
            ((await _decodeData(
                      await _req(
                        app,
                        'GET',
                        '/v1/owner/categories',
                        token: 'token-owner-a',
                      ),
                    )
                    as Map)['items']
                as List);
        expect(cats.map((c) => c['name']), ['Makanan', 'Minuman', 'Camilan']);
        final catId = cats.first['id'] as String;

        final menuRes = await _req(
          app,
          'POST',
          '/v1/owner/menus',
          token: 'token-owner-a',
          body: {
            'name': 'Bakso',
            'category_id': catId,
            'price': 15000,
            'is_available': false,
          },
        );
        final menuId = (await _decodeData(menuRes) as Map)['id'] as String;
        await _expectError(
          await _req(
            app,
            'POST',
            '/v1/owner/stall/publish',
            token: 'token-owner-a',
          ),
          422,
          'PUBLISH_MENU_REQUIRED',
        );

        // Mark available -> publish succeeds and starts Tutup
        await _req(
          app,
          'PUT',
          '/v1/owner/menus/$menuId/availability',
          token: 'token-owner-a',
          body: {'is_available': true},
        );
        final published = await _req(
          app,
          'POST',
          '/v1/owner/stall/publish',
          token: 'token-owner-a',
        );
        final pubStall = (await _decodeData(published) as Map)['stall'] as Map;
        expect(pubStall['is_listed'], isTrue);
        expect(pubStall['is_open'], isFalse);

        // Re-publish fails with 409 STALL_ALREADY_PUBLISHED
        await _expectError(
          await _req(
            app,
            'POST',
            '/v1/owner/stall/publish',
            token: 'token-owner-a',
          ),
          409,
          'STALL_ALREADY_PUBLISHED',
        );

        // No unpublish route
        final unpublish = await _req(
          app,
          'POST',
          '/v1/owner/stall/unpublish',
          token: 'token-owner-a',
        );
        expect(unpublish.statusCode, 404);

        // Update stall profile via PUT /v1/owner/stall
        final updatedStallRes = await _req(
          app,
          'PUT',
          '/v1/owner/stall',
          token: 'token-owner-a',
          body: {
            'name': 'Dapur A Baru',
            'campus': 'USU',
            'block': 'Blok A-09',
            'description': 'Menu rumahan',
            'wait_minutes': 20,
          },
        );
        final updatedStall =
            (await _decodeData(updatedStallRes) as Map)['stall'] as Map;
        expect(updatedStall['name'], 'Dapur A Baru');
        expect(updatedStall['wait_minutes'], 20);
        await _expectError(
          await _req(
            app,
            'PUT',
            '/v1/owner/stall',
            token: 'token-owner-a',
            body: {
              'name': 'Dapur A',
              'campus': 'USU',
              'block': 'A',
              'wait_minutes': 241,
            },
          ),
          400,
          'INVALID_INPUT',
        );

        // Manual open & close toggle works
        final opened = await _req(
          app,
          'PUT',
          '/v1/owner/stall/open-status',
          token: 'token-owner-a',
          body: {'is_open': true},
        );
        expect(
          ((await _decodeData(opened) as Map)['stall'] as Map)['is_open'],
          isTrue,
        );

        // Informative schedule does not close an open stall; rejects invalid schedules
        await _expectError(
          await _req(
            app,
            'PUT',
            '/v1/owner/stall/schedule',
            token: 'token-owner-a',
            body: {
              'schedules': [
                {
                  'day_of_week': 1,
                  'is_open_day': true,
                  'open_time': '17:00',
                  'close_time': '08:00',
                },
              ],
            },
          ),
          400,
          'INVALID_SCHEDULE',
        );
        final scheduleBody = {
          'schedules': [
            {
              'day_of_week': 1,
              'is_open_day': true,
              'open_time': '08:00',
              'close_time': '17:00',
            },
            for (var d = 2; d <= 7; d++)
              {
                'day_of_week': d,
                'is_open_day': false,
                'open_time': null,
                'close_time': null,
              },
          ],
        };
        final schRes = await _req(
          app,
          'PUT',
          '/v1/owner/stall/schedule',
          token: 'token-owner-a',
          body: scheduleBody,
        );
        expect(
          ((await _decodeData(schRes) as Map)['stall'] as Map)['is_open'],
          isTrue,
        );

        final closed = await _req(
          app,
          'PUT',
          '/v1/owner/stall/open-status',
          token: 'token-owner-a',
          body: {'is_open': false},
        );
        expect(
          ((await _decodeData(closed) as Map)['stall'] as Map)['is_open'],
          isFalse,
        );
      },
    );

    test(
      'protects category with archived menu, supports photo upload and restore',
      () async {
        await _req(
          app,
          'POST',
          '/v1/owner/stall',
          token: 'token-owner-a',
          body: {'name': 'Dapur A', 'campus': 'USU', 'block': 'A-01'},
        );
        final catRes = await _req(
          app,
          'POST',
          '/v1/owner/categories',
          token: 'token-owner-a',
          body: {'name': 'Paket Hemat'},
        );
        final customCatId = (await _decodeData(catRes) as Map)['id'] as String;
        final menuRes = await _req(
          app,
          'POST',
          '/v1/owner/menus',
          token: 'token-owner-a',
          body: {
            'name': 'Paket 1',
            'category_id': customCatId,
            'price': 12000,
            'is_available': true,
          },
        );
        final menuId = (await _decodeData(menuRes) as Map)['id'] as String;

        // Check stall & menu photo 204 before upload
        final emptyStallPhoto = await _req(
          app,
          'GET',
          '/v1/owner/stall/photo',
          token: 'token-owner-a',
        );
        expect(emptyStallPhoto.statusCode, 204);
        final emptyMenuPhoto = await _req(
          app,
          'GET',
          '/v1/owner/menus/$menuId/photo',
          token: 'token-owner-a',
        );
        expect(emptyMenuPhoto.statusCode, 204);

        // Reject unsupported media type & corrupt image bytes
        await _expectError(
          await _reqRaw(
            app,
            'PUT',
            '/v1/owner/stall/photo',
            token: 'token-owner-a',
            contentType: 'image/gif',
            bytes: Uint8List.fromList([1, 2, 3]),
          ),
          415,
          'UNSUPPORTED_MEDIA_TYPE',
        );
        await _expectError(
          await _reqRaw(
            app,
            'PUT',
            '/v1/owner/menus/$menuId/photo',
            token: 'token-owner-a',
            contentType: 'image/png',
            bytes: Uint8List.fromList([0, 1, 2, 3]),
          ),
          422,
          'INVALID_MEDIA_PHOTO',
        );

        // Upload stall and menu photos, read, then delete both
        final png = _validPngBytes();
        final stallPhotoPut = await _reqRaw(
          app,
          'PUT',
          '/v1/owner/stall/photo',
          token: 'token-owner-a',
          contentType: 'image/png',
          bytes: png,
        );
        expect(stallPhotoPut.statusCode, 200);
        expect(stallPhotoPut.headers['content-type'], 'image/jpeg');
        final stallPhotoGet = await _req(
          app,
          'GET',
          '/v1/owner/stall/photo',
          token: 'token-owner-a',
        );
        expect(stallPhotoGet.statusCode, 200);
        expect(stallPhotoGet.headers['content-type'], 'image/jpeg');

        final menuPhotoPut = await _reqRaw(
          app,
          'PUT',
          '/v1/owner/menus/$menuId/photo',
          token: 'token-owner-a',
          contentType: 'image/png',
          bytes: png,
        );
        expect(menuPhotoPut.statusCode, 200);
        final menuPhotoGet = await _req(
          app,
          'GET',
          '/v1/owner/menus/$menuId/photo',
          token: 'token-owner-a',
        );
        expect(menuPhotoGet.statusCode, 200);

        final stallPhotoDel = await _req(
          app,
          'DELETE',
          '/v1/owner/stall/photo',
          token: 'token-owner-a',
        );
        expect(
          ((await _decodeData(stallPhotoDel) as Map)['stall']
              as Map)['has_photo'],
          isFalse,
        );
        final menuPhotoDel = await _req(
          app,
          'DELETE',
          '/v1/owner/menus/$menuId/photo',
          token: 'token-owner-a',
        );
        expect((await _decodeData(menuPhotoDel) as Map)['has_photo'], isFalse);

        // Rename category & reject duplicate category name (case-insensitive)
        await _expectError(
          await _req(
            app,
            'POST',
            '/v1/owner/categories',
            token: 'token-owner-a',
            body: {'name': 'paket hemat'},
          ),
          409,
          'CATEGORY_NAME_EXISTS',
        );
        final renamedCat =
            await _decodeData(
                  await _req(
                    app,
                    'PUT',
                    '/v1/owner/categories/$customCatId',
                    token: 'token-owner-a',
                    body: {'name': 'Paket Spesial'},
                  ),
                )
                as Map;
        expect(renamedCat['name'], 'Paket Spesial');

        // List active menus via GET /v1/owner/menus
        final activeMenus =
            await _decodeData(
                  await _req(
                    app,
                    'GET',
                    '/v1/owner/menus?archived=false&q=Paket',
                    token: 'token-owner-a',
                  ),
                )
                as Map;
        expect((activeMenus['items'] as List).length, 1);
        await _expectError(
          await _req(
            app,
            'GET',
            '/v1/owner/menus?archived=invalid',
            token: 'token-owner-a',
          ),
          400,
          'INVALID_INPUT',
        );

        // Archive menu -> category STILL cannot be deleted
        final archived = await _req(
          app,
          'POST',
          '/v1/owner/menus/$menuId/archive',
          token: 'token-owner-a',
        );
        expect((await _decodeData(archived) as Map)['is_archived'], isTrue);
        final archivedList =
            await _decodeData(
                  await _req(
                    app,
                    'GET',
                    '/v1/owner/menus?archived=true',
                    token: 'token-owner-a',
                  ),
                )
                as Map;
        expect((archivedList['items'] as List).length, 1);
        await _expectError(
          await _req(
            app,
            'DELETE',
            '/v1/owner/categories/$customCatId',
            token: 'token-owner-a',
          ),
          409,
          'CATEGORY_NOT_EMPTY',
        );

        // No permanent delete route
        final delMenu = await _req(
          app,
          'DELETE',
          '/v1/owner/menus/$menuId',
          token: 'token-owner-a',
        );
        expect(delMenu.statusCode, 404);

        // Move menu to Makanan, then category delete succeeds
        final cats =
            ((await _decodeData(
                      await _req(
                        app,
                        'GET',
                        '/v1/owner/categories',
                        token: 'token-owner-a',
                      ),
                    )
                    as Map)['items']
                as List);
        final makananId =
            cats.firstWhere((c) => c['name'] == 'Makanan')['id'] as String;
        await _req(
          app,
          'PUT',
          '/v1/owner/menus/$menuId',
          token: 'token-owner-a',
          body: {
            'name': 'Paket 1',
            'category_id': makananId,
            'price': 13000,
            'is_available': true,
          },
        );
        final deleted = await _req(
          app,
          'DELETE',
          '/v1/owner/categories/$customCatId',
          token: 'token-owner-a',
        );
        expect(deleted.statusCode, 200);

        // Restore menu
        final restored = await _req(
          app,
          'POST',
          '/v1/owner/menus/$menuId/restore',
          token: 'token-owner-a',
        );
        expect((await _decodeData(restored) as Map)['is_archived'], isFalse);
      },
    );
  });

  group('Dashboard, Lookup, and Order Transitions', () {
    test(
      'dashboard has no finance metrics and order transitions follow ORDER-001..017A',
      () async {
        await _req(
          app,
          'POST',
          '/v1/owner/stall',
          token: 'token-owner-a',
          body: {
            'name': 'Dapur A',
            'campus': 'USU',
            'block': 'A-01',
            'wait_minutes': 15,
          },
        );
        final o1 = store.seedOrder(ownerId: _ownerAId, orderNumber: '0042');
        final o2 = store.seedOrder(ownerId: _ownerAId, orderNumber: '0043');
        final o3 = store.seedOrder(ownerId: _ownerAId, orderNumber: '0044');
        final o4 = store.seedOrder(ownerId: _ownerAId, orderNumber: '0045');
        final o5 = store.seedOrder(ownerId: _ownerAId, orderNumber: '0046');

        final dash =
            await _decodeData(
                  await _req(
                    app,
                    'GET',
                    '/v1/owner/dashboard',
                    token: 'token-owner-a',
                  ),
                )
                as Map;
        expect(dash.containsKey('revenue'), isFalse);
        expect(dash.containsKey('sales'), isFalse);
        expect((dash['active_counts'] as Map)['menunggu_konfirmasi'], 5);

        // List active orders + filter + invalid scope
        final activeOrders =
            await _decodeData(
                  await _req(
                    app,
                    'GET',
                    '/v1/owner/orders?scope=active&status=menunggu_konfirmasi',
                    token: 'token-owner-a',
                  ),
                )
                as Map;
        expect((activeOrders['items'] as List).length, 5);
        await _expectError(
          await _req(
            app,
            'GET',
            '/v1/owner/orders?scope=invalid',
            token: 'token-owner-a',
          ),
          400,
          'INVALID_INPUT',
        );

        // Happy-path GET /orders/<id> and lookup preserves leading zeros without mutation
        final detailO1 =
            await _decodeData(
                  await _req(
                    app,
                    'GET',
                    '/v1/owner/orders/$o1',
                    token: 'token-owner-a',
                  ),
                )
                as Map;
        expect((detailO1['items'] as List).length, 1);
        final lookup =
            await _decodeData(
                  await _req(
                    app,
                    'GET',
                    '/v1/owner/orders/lookup?code=0042',
                    token: 'token-owner-a',
                  ),
                )
                as Map;
        expect(lookup['order_number'], '0042');
        expect(lookup['status'], 'menunggu_konfirmasi');
        await _expectError(
          await _req(
            app,
            'GET',
            '/v1/owner/orders/lookup?code=',
            token: 'token-owner-a',
          ),
          400,
          'INVALID_INPUT',
        );

        // Accept -> Ready -> Complete (requires both cash and food flags)
        final accepted =
            await _decodeData(
                  await _req(
                    app,
                    'POST',
                    '/v1/owner/orders/$o1/accept',
                    token: 'token-owner-a',
                  ),
                )
                as Map;
        expect(accepted['status'], 'diproses');
        expect(accepted['prep_estimate_minutes'], 15);

        await _req(
          app,
          'POST',
          '/v1/owner/orders/$o1/ready',
          token: 'token-owner-a',
        );
        await _expectError(
          await _req(
            app,
            'POST',
            '/v1/owner/orders/$o1/fail-fulfillment',
            token: 'token-owner-a',
            body: {'reason': 'Habis'},
          ),
          409,
          'INVALID_ORDER_TRANSITION',
        );
        await _expectError(
          await _req(
            app,
            'POST',
            '/v1/owner/orders/$o1/complete',
            token: 'token-owner-a',
            body: {'cash_received': true, 'food_handed_over': false},
          ),
          422,
          'COMPLETE_CONFIRMATION_REQUIRED',
        );
        final completed =
            await _decodeData(
                  await _req(
                    app,
                    'POST',
                    '/v1/owner/orders/$o1/complete',
                    token: 'token-owner-a',
                    body: {'cash_received': true, 'food_handed_over': true},
                  ),
                )
                as Map;
        expect(completed['status'], 'selesai');
        expect(completed['payment_status'], 'lunas');

        // Order 2: Accept -> Ready -> Gagal Diambil (mandatory reason, Belum Lunas)
        await _req(
          app,
          'POST',
          '/v1/owner/orders/$o2/accept',
          token: 'token-owner-a',
        );
        await _req(
          app,
          'POST',
          '/v1/owner/orders/$o2/ready',
          token: 'token-owner-a',
        );
        await _expectError(
          await _req(
            app,
            'POST',
            '/v1/owner/orders/$o2/fail-pickup',
            token: 'token-owner-a',
            body: {'reason': '   '},
          ),
          422,
          'REASON_REQUIRED',
        );
        final failedPickup =
            await _decodeData(
                  await _req(
                    app,
                    'POST',
                    '/v1/owner/orders/$o2/fail-pickup',
                    token: 'token-owner-a',
                    body: {'reason': 'Makanan terjatuh saat disiapkan'},
                  ),
                )
                as Map;
        expect(failedPickup['status'], 'gagal_diambil');
        expect(failedPickup['payment_status'], 'belum_lunas');
        expect(
          failedPickup['status_reason'],
          'Makanan terjatuh saat disiapkan',
        );

        // Order 3: Reject (requires reason)
        await _expectError(
          await _req(
            app,
            'POST',
            '/v1/owner/orders/$o3/reject',
            token: 'token-owner-a',
            body: {'reason': ''},
          ),
          422,
          'REASON_REQUIRED',
        );
        final rejected =
            await _decodeData(
                  await _req(
                    app,
                    'POST',
                    '/v1/owner/orders/$o3/reject',
                    token: 'token-owner-a',
                    body: {'reason': 'Stok habis'},
                  ),
                )
                as Map;
        expect(rejected['status'], 'ditolak');
        expect(rejected['payment_status'], 'belum_lunas');

        // Order 4: Accept -> fail_fulfillment (happy path)
        await _req(
          app,
          'POST',
          '/v1/owner/orders/$o4/accept',
          token: 'token-owner-a',
        );
        await _expectError(
          await _req(
            app,
            'POST',
            '/v1/owner/orders/$o4/fail-fulfillment',
            token: 'token-owner-a',
            body: {'reason': ' '},
          ),
          422,
          'REASON_REQUIRED',
        );
        final failedFulfill =
            await _decodeData(
                  await _req(
                    app,
                    'POST',
                    '/v1/owner/orders/$o4/fail-fulfillment',
                    token: 'token-owner-a',
                    body: {'reason': 'Listrik padam'},
                  ),
                )
                as Map;
        expect(failedFulfill['status'], 'gagal_dipenuhi');
        expect(failedFulfill['payment_status'], 'belum_lunas');

        // Order 5: Accept -> Ready -> not_picked_up (and invalid state guard)
        await _expectError(
          await _req(
            app,
            'POST',
            '/v1/owner/orders/$o5/not-picked-up',
            token: 'token-owner-a',
          ),
          409,
          'INVALID_ORDER_TRANSITION',
        );
        await _req(
          app,
          'POST',
          '/v1/owner/orders/$o5/accept',
          token: 'token-owner-a',
        );
        await _req(
          app,
          'POST',
          '/v1/owner/orders/$o5/ready',
          token: 'token-owner-a',
        );
        final notPicked =
            await _decodeData(
                  await _req(
                    app,
                    'POST',
                    '/v1/owner/orders/$o5/not-picked-up',
                    token: 'token-owner-a',
                  ),
                )
                as Map;
        expect(notPicked['status'], 'tidak_diambil');
        expect(notPicked['payment_status'], 'belum_lunas');

        // All 5 are now in history, 0 active
        final dashAfter =
            await _decodeData(
                  await _req(
                    app,
                    'GET',
                    '/v1/owner/dashboard',
                    token: 'token-owner-a',
                  ),
                )
                as Map;
        expect(dashAfter['active_counts'], {
          'menunggu_konfirmasi': 0,
          'diproses': 0,
          'siap_diambil': 0,
        });
        final history =
            await _decodeData(
                  await _req(
                    app,
                    'GET',
                    '/v1/owner/orders?scope=history',
                    token: 'token-owner-a',
                  ),
                )
                as Map;
        expect((history['items'] as List).length, 5);
      },
    );
  });

  group('SupabaseOwnerStore RPC mapping', () {
    test(
      'maps Postgrest KC_* exceptions and masks unexpected DB details',
      () async {
        final config = AppConfig.fromEnv(EnvConfig.fromMap(validEnvironment()));
        final client = MockClient((request) async {
          if (request.url.path.endsWith('kc_owner_get_stall')) {
            return http.Response(
              jsonEncode({
                'code': '42501',
                'message':
                    'internal postgres relation catalog_stalls detail secret_col',
                'details': 'stacktrace',
              }),
              500,
              headers: {'content-type': 'application/json'},
              request: request,
            );
          }
          return http.Response(
            jsonEncode({
              'code': 'P0001',
              'message': 'KC_CATEGORY_NOT_EMPTY',
              'details': 'KC_CATEGORY_NOT_EMPTY',
            }),
            400,
            headers: {'content-type': 'application/json'},
            request: request,
          );
        });
        addTearDown(client.close);
        final supabaseStore = SupabaseOwnerStore(
          SupabaseClientFactory(config: config.supabase),
          httpClient: client,
        );
        await expectLater(
          () => supabaseStore.deleteCategory(
            _ownerAId,
            categoryId: '00000000-0000-0000-0000-000000000001',
          ),
          throwsA(
            isA<OwnerFailure>().having(
              (e) => e.code,
              'code',
              OwnerFailureCode.categoryNotEmpty,
            ),
          ),
        );
        await expectLater(
          () => supabaseStore.getStall(_ownerAId),
          throwsA(
            isA<OwnerFailure>()
                .having((e) => e.code, 'code', OwnerFailureCode.unavailable)
                .having((e) => e.message, 'message', isNull),
          ),
        );
      },
    );
  });
}

Future<Response> _req(
  Handler app,
  String method,
  String path, {
  String? token,
  Object? body,
}) async {
  final headers = <String, String>{
    'host': 'api.example.test',
    if (token != null) 'authorization': 'Bearer $token',
    if (body != null) 'content-type': 'application/json',
  };
  return await app(
    Request(
      method,
      Uri.parse('https://api.example.test$path'),
      headers: headers,
      body: body == null ? null : jsonEncode(body),
    ),
  );
}

Future<Response> _reqRaw(
  Handler app,
  String method,
  String path, {
  required String token,
  required String contentType,
  required Uint8List bytes,
}) async {
  return await app(
    Request(
      method,
      Uri.parse('https://api.example.test$path'),
      headers: {
        'host': 'api.example.test',
        'authorization': 'Bearer $token',
        'content-type': contentType,
      },
      body: Stream<List<int>>.value(bytes),
    ),
  );
}

Future<Object?> _decodeData(Response response) async {
  final json =
      jsonDecode(await response.readAsString()) as Map<String, dynamic>;
  expect(json['success'], isTrue, reason: 'Expected success, got $json');
  return json['data'];
}

Future<void> _expectError(Response response, int status, String code) async {
  expect(response.statusCode, status);
  final json =
      jsonDecode(await response.readAsString()) as Map<String, dynamic>;
  expect(json['success'], isFalse);
  expect((json['error'] as Map)['code'], code);
}

Uint8List _validPngBytes() => Uint8List.fromList([
  // 1x1 transparent PNG
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
  0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
  0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
  0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
  0x42, 0x60, 0x82,
]);

class _FakeAuthGateway implements AuthGateway {
  @override
  Future<AuthAccount> account(String accessToken) async =>
      switch (accessToken) {
        'token-owner-a' => const AuthAccount(
          id: _ownerAId,
          email: 'ownera@example.test',
          role: AccountRole.owner,
          displayName: 'Owner A',
        ),
        'token-owner-b' => const AuthAccount(
          id: _ownerBId,
          email: 'ownerb@example.test',
          role: AccountRole.owner,
          displayName: 'Owner B',
        ),
        'token-customer' => const AuthAccount(
          id: _customerId,
          email: 'cust@example.test',
          role: AccountRole.customer,
          displayName: 'Customer',
        ),
        'token-admin' => const AuthAccount(
          id: _adminId,
          email: 'admin@example.test',
          role: AccountRole.admin,
          displayName: 'Admin',
        ),
        'token-inactive' => throw AuthFailure.inactiveAccount,
        'token-incomplete' => const AuthAccount(
          id: _incompleteOwnerId,
          email: 'incomplete@example.test',
          role: AccountRole.owner,
          displayName: 'Incomplete',
        ),
        _ => throw AuthFailure.invalidSession,
      };

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAvatarStore implements AvatarStore {
  @override
  Future<bool> exists(String accountId) async =>
      accountId != _incompleteOwnerId;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCatalogStore implements CatalogStore {
  @override
  Future<List<CatalogEntry>> read(
    CatalogCollection collection, {
    required String query,
    required String? after,
    required String? stallId,
    required int limit,
  }) async => const [];
}

class _MemoryMediaStore implements OwnerMediaStore {
  final Map<String, Uint8List> files = {};

  @override
  Future<void> delete(String objectPath) async => files.remove(objectPath);

  @override
  Future<Uint8List?> read(String objectPath) async => files[objectPath];

  @override
  Future<void> write(String objectPath, Uint8List jpegBytes) async =>
      files[objectPath] = jpegBytes;
}

class _MemoryOwnerStore implements OwnerStore {
  final Map<String, Map<String, Object?>> _stallsByOwner = {};
  final Map<String, List<Map<String, Object?>>> _schedulesByStall = {};
  final Map<String, List<Map<String, Object?>>> _categoriesByStall = {};
  final Map<String, List<Map<String, Object?>>> _menusByStall = {};
  final Map<String, Map<String, Object?>> _ordersById = {};
  var _seq = 1;

  String _nextUuid(int prefix) {
    final n = (_seq++).toString().padLeft(12, '0');
    return '${prefix.toString().padLeft(8, '0')}-0000-0000-0000-$n';
  }

  String seedOrder({required String ownerId, required String orderNumber}) {
    final stall = _stallsByOwner[ownerId]!;
    final id = _nextUuid(3);
    _ordersById[id] = {
      'id': id,
      'order_number': orderNumber,
      'stall_id': stall['id'],
      'owner_id': ownerId,
      'customer_name': 'Budi',
      'status': 'menunggu_konfirmasi',
      'payment_status': 'belum_lunas',
      'general_note': '',
      'total_amount': 15000,
      'prep_estimate_minutes': null,
      'status_reason': null,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'accepted_at': null,
      'ready_at': null,
      'terminal_at': null,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
      'item_summary': '1x Nasi Uduk',
      'item_count': 1,
      'items': [
        {
          'id': _nextUuid(4),
          'menu_item_id': null,
          'menu_name': 'Nasi Uduk',
          'unit_price': 15000,
          'quantity': 1,
          'line_total': 15000,
          'item_note': '',
        },
      ],
      'events': [
        {
          'id': _nextUuid(5),
          'from_status': null,
          'to_status': 'menunggu_konfirmasi',
          'actor_role': 'customer',
          'reason': null,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        },
      ],
    };
    return id;
  }

  @override
  Future<Map<String, Object?>> getStall(String ownerId) async {
    final stall = _stallsByOwner[ownerId];
    if (stall == null) {
      return {
        'stall': null,
        'schedules': const <Object>[],
        'publish_eligibility': {
          'can_publish': false,
          'missing_profile_fields': ['name', 'campus', 'block'],
          'available_menu_count': 0,
        },
      };
    }
    final stallId = stall['id'] as String;
    final menus = _menusByStall[stallId] ?? const [];
    final availableCount = menus
        .where((m) => m['is_archived'] == false && m['is_available'] == true)
        .length;
    return {
      'stall': Map<String, Object?>.from(stall),
      'schedules': _schedulesByStall[stallId] ?? const [],
      'publish_eligibility': {
        'can_publish': stall['is_listed'] == false && availableCount >= 1,
        'missing_profile_fields': const <String>[],
        'available_menu_count': availableCount,
      },
    };
  }

  @override
  Future<Map<String, Object?>> createStall(
    String ownerId, {
    required String name,
    required String campus,
    required String block,
    required String description,
    required int waitMinutes,
  }) async {
    if (_stallsByOwner.containsKey(ownerId)) {
      throw const OwnerFailure(OwnerFailureCode.stallAlreadyExists);
    }
    final stallId = _nextUuid(1);
    _stallsByOwner[ownerId] = {
      'id': stallId,
      'owner_id': ownerId,
      'name': name,
      'campus': campus,
      'block': block,
      'description': description,
      'wait_minutes': waitMinutes,
      'is_listed': false,
      'is_open': false,
      'has_photo': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    _categoriesByStall[stallId] = [
      for (final (i, label) in [(1, 'Makanan'), (2, 'Minuman'), (3, 'Camilan')])
        {
          'id': _nextUuid(2),
          'stall_id': stallId,
          'name': label,
          'sort_order': i,
          'active_menu_count': 0,
          'archived_menu_count': 0,
          'total_menu_count': 0,
          'can_delete': true,
        },
    ];
    _schedulesByStall[stallId] = [
      for (var d = 1; d <= 7; d++)
        {
          'day_of_week': d,
          'is_open_day': false,
          'open_time': null,
          'close_time': null,
        },
    ];
    _menusByStall[stallId] = [];
    return getStall(ownerId);
  }

  @override
  Future<Map<String, Object?>> updateStall(
    String ownerId, {
    required String name,
    required String campus,
    required String block,
    required String description,
    required int waitMinutes,
  }) async {
    final stall = _stallsByOwner[ownerId];
    if (stall == null) throw const OwnerFailure(OwnerFailureCode.stallNotFound);
    stall['name'] = name;
    stall['campus'] = campus;
    stall['block'] = block;
    stall['description'] = description;
    stall['wait_minutes'] = waitMinutes;
    return getStall(ownerId);
  }

  @override
  Future<Map<String, Object?>> setStallPhoto(
    String ownerId, {
    required String? photoPath,
  }) async {
    final stall = _stallsByOwner[ownerId];
    if (stall == null) throw const OwnerFailure(OwnerFailureCode.stallNotFound);
    stall['has_photo'] = photoPath != null;
    return getStall(ownerId);
  }

  @override
  Future<Map<String, Object?>> setStallSchedule(
    String ownerId,
    List<OwnerScheduleInput> schedules,
  ) async {
    final stall = _stallsByOwner[ownerId];
    if (stall == null) throw const OwnerFailure(OwnerFailureCode.stallNotFound);
    _schedulesByStall[stall['id'] as String] = [
      for (final s in schedules)
        {
          'day_of_week': s.dayOfWeek,
          'is_open_day': s.isOpenDay,
          'open_time': s.openTime,
          'close_time': s.closeTime,
        },
    ];
    return getStall(ownerId);
  }

  @override
  Future<Map<String, Object?>> publishStall(String ownerId) async {
    final stall = _stallsByOwner[ownerId];
    if (stall == null) throw const OwnerFailure(OwnerFailureCode.stallNotFound);
    if (stall['is_listed'] == true) {
      throw const OwnerFailure(OwnerFailureCode.stallAlreadyPublished);
    }
    final menus = _menusByStall[stall['id'] as String] ?? const [];
    final hasAvail = menus.any(
      (m) => m['is_archived'] == false && m['is_available'] == true,
    );
    if (!hasAvail) {
      throw const OwnerFailure(OwnerFailureCode.publishMenuRequired);
    }
    stall['is_listed'] = true;
    stall['is_open'] = false;
    return getStall(ownerId);
  }

  @override
  Future<Map<String, Object?>> setStallOpen(
    String ownerId, {
    required bool isOpen,
  }) async {
    final stall = _stallsByOwner[ownerId];
    if (stall == null) throw const OwnerFailure(OwnerFailureCode.stallNotFound);
    if (stall['is_listed'] != true) {
      throw const OwnerFailure(OwnerFailureCode.stallNotPublished);
    }
    stall['is_open'] = isOpen;
    return getStall(ownerId);
  }

  @override
  Future<List<Map<String, Object?>>> listCategories(String ownerId) async {
    final stall = _stallsByOwner[ownerId];
    if (stall == null) throw const OwnerFailure(OwnerFailureCode.stallNotFound);
    final stallId = stall['id'] as String;
    final menus = _menusByStall[stallId] ?? const [];
    return [
      for (final cat in _categoriesByStall[stallId]!)
        {
          ...cat,
          'active_menu_count': menus
              .where(
                (m) =>
                    m['category_id'] == cat['id'] && m['is_archived'] == false,
              )
              .length,
          'archived_menu_count': menus
              .where(
                (m) =>
                    m['category_id'] == cat['id'] && m['is_archived'] == true,
              )
              .length,
          'total_menu_count': menus
              .where((m) => m['category_id'] == cat['id'])
              .length,
          'can_delete': menus
              .where((m) => m['category_id'] == cat['id'])
              .isEmpty,
        },
    ];
  }

  @override
  Future<Map<String, Object?>> createCategory(
    String ownerId, {
    required String name,
  }) async {
    final stall = _stallsByOwner[ownerId];
    if (stall == null) throw const OwnerFailure(OwnerFailureCode.stallNotFound);
    final cats = _categoriesByStall[stall['id'] as String]!;
    if (cats.any(
      (c) => (c['name'] as String).toLowerCase() == name.toLowerCase(),
    )) {
      throw const OwnerFailure(OwnerFailureCode.categoryNameExists);
    }
    final cat = {
      'id': _nextUuid(2),
      'stall_id': stall['id'],
      'name': name,
      'sort_order': cats.length + 1,
      'active_menu_count': 0,
      'archived_menu_count': 0,
      'total_menu_count': 0,
      'can_delete': true,
    };
    cats.add(cat);
    return cat;
  }

  @override
  Future<Map<String, Object?>> renameCategory(
    String ownerId, {
    required String categoryId,
    required String name,
  }) async {
    final stall = _stallsByOwner[ownerId];
    if (stall == null) throw const OwnerFailure(OwnerFailureCode.stallNotFound);
    final cats = _categoriesByStall[stall['id'] as String]!;
    final cat = cats.where((c) => c['id'] == categoryId).firstOrNull;
    if (cat == null) {
      throw const OwnerFailure(OwnerFailureCode.categoryNotFound);
    }
    cat['name'] = name;
    return cat;
  }

  @override
  Future<void> deleteCategory(
    String ownerId, {
    required String categoryId,
  }) async {
    final stall = _stallsByOwner[ownerId];
    if (stall == null) throw const OwnerFailure(OwnerFailureCode.stallNotFound);
    final stallId = stall['id'] as String;
    final cats = _categoriesByStall[stallId]!;
    final cat = cats.where((c) => c['id'] == categoryId).firstOrNull;
    if (cat == null) {
      throw const OwnerFailure(OwnerFailureCode.categoryNotFound);
    }
    final menus = _menusByStall[stallId] ?? const [];
    if (menus.any((m) => m['category_id'] == categoryId)) {
      throw const OwnerFailure(OwnerFailureCode.categoryNotEmpty);
    }
    cats.removeWhere((c) => c['id'] == categoryId);
  }

  @override
  Future<List<Map<String, Object?>>> listMenus(
    String ownerId, {
    bool? archived,
    required String query,
  }) async {
    final stall = _stallsByOwner[ownerId];
    if (stall == null) throw const OwnerFailure(OwnerFailureCode.stallNotFound);
    final menus = _menusByStall[stall['id'] as String] ?? const [];
    return menus
        .where((m) => archived == null || m['is_archived'] == archived)
        .toList();
  }

  @override
  Future<Map<String, Object?>> createMenu(
    String ownerId, {
    required String name,
    required String categoryId,
    required int price,
    required bool isAvailable,
    required String description,
  }) async {
    final stall = _stallsByOwner[ownerId];
    if (stall == null) throw const OwnerFailure(OwnerFailureCode.stallNotFound);
    final stallId = stall['id'] as String;
    final cat = _categoriesByStall[stallId]!
        .where((c) => c['id'] == categoryId)
        .firstOrNull;
    if (cat == null) {
      throw const OwnerFailure(OwnerFailureCode.categoryNotFound);
    }
    final menu = <String, Object?>{
      'id': _nextUuid(6),
      'stall_id': stallId,
      'category_id': categoryId,
      'category_name': cat['name'],
      'name': name,
      'description': description,
      'price': price,
      'is_available': isAvailable,
      'is_archived': false,
      'has_photo': false,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    _menusByStall[stallId]!.add(menu);
    return menu;
  }

  @override
  Future<Map<String, Object?>> updateMenu(
    String ownerId, {
    required String menuId,
    required String name,
    required String categoryId,
    required int price,
    required bool isAvailable,
    required String description,
  }) async {
    final stall = _stallsByOwner[ownerId];
    if (stall == null) throw const OwnerFailure(OwnerFailureCode.stallNotFound);
    final stallId = stall['id'] as String;
    final menu = _menusByStall[stallId]!
        .where((m) => m['id'] == menuId)
        .firstOrNull;
    if (menu == null) throw const OwnerFailure(OwnerFailureCode.menuNotFound);
    final cat = _categoriesByStall[stallId]!
        .where((c) => c['id'] == categoryId)
        .firstOrNull;
    if (cat == null) {
      throw const OwnerFailure(OwnerFailureCode.categoryNotFound);
    }
    menu['name'] = name;
    menu['category_id'] = categoryId;
    menu['category_name'] = cat['name'];
    menu['price'] = price;
    menu['is_available'] = isAvailable;
    menu['description'] = description;
    return menu;
  }

  @override
  Future<Map<String, Object?>> setMenuAvailability(
    String ownerId, {
    required String menuId,
    required bool isAvailable,
  }) async {
    final stall = _stallsByOwner[ownerId];
    if (stall == null) throw const OwnerFailure(OwnerFailureCode.stallNotFound);
    final menu = _menusByStall[stall['id'] as String]!
        .where((m) => m['id'] == menuId)
        .firstOrNull;
    if (menu == null) throw const OwnerFailure(OwnerFailureCode.menuNotFound);
    menu['is_available'] = isAvailable;
    return menu;
  }

  @override
  Future<Map<String, Object?>> archiveMenu(
    String ownerId, {
    required String menuId,
  }) async {
    final stall = _stallsByOwner[ownerId];
    if (stall == null) throw const OwnerFailure(OwnerFailureCode.stallNotFound);
    final menu = _menusByStall[stall['id'] as String]!
        .where((m) => m['id'] == menuId)
        .firstOrNull;
    if (menu == null) throw const OwnerFailure(OwnerFailureCode.menuNotFound);
    menu['is_archived'] = true;
    return menu;
  }

  @override
  Future<Map<String, Object?>> restoreMenu(
    String ownerId, {
    required String menuId,
  }) async {
    final stall = _stallsByOwner[ownerId];
    if (stall == null) throw const OwnerFailure(OwnerFailureCode.stallNotFound);
    final menu = _menusByStall[stall['id'] as String]!
        .where((m) => m['id'] == menuId)
        .firstOrNull;
    if (menu == null) throw const OwnerFailure(OwnerFailureCode.menuNotFound);
    menu['is_archived'] = false;
    return menu;
  }

  @override
  Future<Map<String, Object?>> setMenuPhoto(
    String ownerId, {
    required String menuId,
    required String? photoPath,
  }) async {
    final stall = _stallsByOwner[ownerId];
    if (stall == null) throw const OwnerFailure(OwnerFailureCode.stallNotFound);
    final menu = _menusByStall[stall['id'] as String]!
        .where((m) => m['id'] == menuId)
        .firstOrNull;
    if (menu == null) throw const OwnerFailure(OwnerFailureCode.menuNotFound);
    menu['has_photo'] = photoPath != null;
    return menu;
  }

  @override
  Future<Map<String, Object?>> getDashboard(String ownerId) async {
    final stallData = await getStall(ownerId);
    final orders = _ordersById.values
        .where((o) => o['owner_id'] == ownerId)
        .toList();
    return {
      ...stallData,
      'active_counts': {
        'menunggu_konfirmasi': orders
            .where((o) => o['status'] == 'menunggu_konfirmasi')
            .length,
        'diproses': orders.where((o) => o['status'] == 'diproses').length,
        'siap_diambil': orders
            .where((o) => o['status'] == 'siap_diambil')
            .length,
      },
      'attention_orders': orders
          .where(
            (o) => const {
              'menunggu_konfirmasi',
              'diproses',
              'siap_diambil',
            }.contains(o['status']),
          )
          .toList(),
      'server_time': DateTime.now().toUtc().toIso8601String(),
    };
  }

  @override
  Future<Map<String, Object?>> listOrders(
    String ownerId, {
    required String scope,
    String? status,
    required String query,
    required int limit,
    required int offset,
  }) async {
    const active = {'menunggu_konfirmasi', 'diproses', 'siap_diambil'};
    final items = _ordersById.values.where((o) {
      if (o['owner_id'] != ownerId) return false;
      final isAct = active.contains(o['status']);
      if (scope == 'active' && !isAct) return false;
      if (scope == 'history' && isAct) return false;
      if (status != null && o['status'] != status) return false;
      return true;
    }).toList();
    return {'items': items, 'has_more': false};
  }

  @override
  Future<Map<String, Object?>?> lookupOrder(
    String ownerId, {
    required String orderNumber,
  }) async {
    return _ordersById.values
        .where(
          (o) => o['owner_id'] == ownerId && o['order_number'] == orderNumber,
        )
        .firstOrNull;
  }

  @override
  Future<Map<String, Object?>?> getOrder(
    String ownerId, {
    required String orderId,
  }) async {
    final order = _ordersById[orderId];
    if (order == null || order['owner_id'] != ownerId) return null;
    return order;
  }

  @override
  Future<Map<String, Object?>> transitionOrder(
    String ownerId, {
    required String orderId,
    required String action,
    String? reason,
    bool cashReceived = false,
    bool foodHandedOver = false,
  }) async {
    final order = _ordersById[orderId];
    if (order == null || order['owner_id'] != ownerId) {
      throw const OwnerFailure(OwnerFailureCode.orderNotFound);
    }
    final current = order['status'] as String;
    switch (action) {
      case 'accept':
        if (current != 'menunggu_konfirmasi') {
          throw const OwnerFailure(OwnerFailureCode.invalidOrderTransition);
        }
        order['status'] = 'diproses';
        order['prep_estimate_minutes'] =
            _stallsByOwner[ownerId]?['wait_minutes'];
      case 'reject':
        if (current != 'menunggu_konfirmasi') {
          throw const OwnerFailure(OwnerFailureCode.invalidOrderTransition);
        }
        order['status'] = 'ditolak';
        order['status_reason'] = reason;
      case 'ready':
        if (current != 'diproses') {
          throw const OwnerFailure(OwnerFailureCode.invalidOrderTransition);
        }
        order['status'] = 'siap_diambil';
      case 'fail_fulfillment':
        if (current != 'diproses') {
          throw const OwnerFailure(OwnerFailureCode.invalidOrderTransition);
        }
        order['status'] = 'gagal_dipenuhi';
        order['status_reason'] = reason;
      case 'not_picked_up':
        if (current != 'siap_diambil') {
          throw const OwnerFailure(OwnerFailureCode.invalidOrderTransition);
        }
        order['status'] = 'tidak_diambil';
      case 'complete':
        if (current != 'siap_diambil') {
          throw const OwnerFailure(OwnerFailureCode.invalidOrderTransition);
        }
        if (!cashReceived || !foodHandedOver) {
          throw const OwnerFailure(
            OwnerFailureCode.completeConfirmationRequired,
          );
        }
        order['status'] = 'selesai';
        order['payment_status'] = 'lunas';
      case 'fail_pickup':
        if (current != 'siap_diambil') {
          throw const OwnerFailure(OwnerFailureCode.invalidOrderTransition);
        }
        order['status'] = 'gagal_diambil';
        order['status_reason'] = reason;
      default:
        throw const OwnerFailure(OwnerFailureCode.invalidOrderTransition);
    }
    return order;
  }
}
