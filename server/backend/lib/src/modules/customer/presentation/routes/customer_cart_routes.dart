import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/customer_request_parser.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/routes/customer_route_context.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

const _maxCartQuantity = 999;
const _maxDraftVersion = 2147483647;

void registerCustomerCartRoutes(
  Router router, {
  required CustomerRouteContext context,
}) {
  router.get('/cart', (Request request) async {
    final customer = await context.requireActor(request);
    return ApiResponse.success(
      data: await context.service.getCart(customer.id),
      headers: noStoreHeaders,
    );
  });

  router.post('/cart/items', (Request request) async {
    final customer = await context.requireActor(request);
    final body = await readCustomerJsonBody(request);
    final menuId = requireCustomerUuid(
      readCustomerRequiredText(body, 'menu_item_id', maxLength: 36),
    );
    return ApiResponse.success(
      statusCode: 201,
      data: await context.service.addCartItem(
        customer.id,
        menuId: menuId,
        quantity: readCustomerIntField(
          body,
          'quantity',
          min: 1,
          max: _maxCartQuantity,
          defaultValue: 1,
        ),
        itemNote: readCustomerOptionalText(
          body,
          'item_note',
          maxLength: 300,
        ),
        replaceStall: readCustomerBoolField(
          body,
          'replace_stall',
          defaultValue: false,
        ),
      ),
      headers: noStoreHeaders,
    );
  });

  router.put('/cart/items/<id>', (Request request, String id) async {
    final customer = await context.requireActor(request);
    final itemId = requireCustomerUuid(id);
    final body = await readCustomerJsonBody(request);
    return ApiResponse.success(
      data: await context.service.updateCartItem(
        customer.id,
        itemId: itemId,
        quantity: readCustomerIntField(
          body,
          'quantity',
          min: 0,
          max: _maxCartQuantity,
        ),
        itemNote: readCustomerPatchOptionalText(
          body,
          'item_note',
          maxLength: 300,
        ),
      ),
      headers: noStoreHeaders,
    );
  });

  router.delete('/cart/items/<id>', (Request request, String id) async {
    final customer = await context.requireActor(request);
    final itemId = requireCustomerUuid(id);
    return ApiResponse.success(
      data: await context.service.updateCartItem(
        customer.id,
        itemId: itemId,
        quantity: 0,
      ),
      headers: noStoreHeaders,
    );
  });

  router.put('/cart/note', (Request request) async {
    final customer = await context.requireActor(request);
    final body = await readCustomerJsonBody(request);
    return ApiResponse.success(
      data: await context.service.setCartNote(
        customer.id,
        generalNote: readCustomerOptionalText(
          body,
          'general_note',
          maxLength: 500,
        ),
      ),
      headers: noStoreHeaders,
    );
  });

  router.post('/cart/acknowledge-prices', (Request request) async {
    final customer = await context.requireActor(request);
    final body = await readCustomerJsonBody(request);
    final expectedVersion = body['expected_version'] == null
        ? null
        : readCustomerIntField(
            body,
            'expected_version',
            min: 1,
            max: _maxDraftVersion,
          );
    return ApiResponse.success(
      data: await context.service.acknowledgeCartPrices(
        customer.id,
        expectedVersion: expectedVersion,
      ),
      headers: noStoreHeaders,
    );
  });

  router.delete('/cart', (Request request) async {
    final customer = await context.requireActor(request);
    return ApiResponse.success(
      data: await context.service.clearCart(customer.id),
      headers: noStoreHeaders,
    );
  });
}
