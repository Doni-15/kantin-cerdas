import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/domain/customer_errors.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/customer_request_parser.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/routes/customer_route_context.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

void registerCustomerOrderRoutes(
  Router router, {
  required CustomerRouteContext context,
}) {
  router.get('/orders', (Request request) async {
    final customer = await context.requireActor(request);
    final params = request.url.queryParameters;
    final scope = params['scope'] ?? 'active';
    if (scope != 'active' && scope != 'history') {
      throw const CustomerFailure(CustomerFailureCode.invalidInput);
    }
    final limit = int.tryParse(params['limit'] ?? '30', radix: 10);
    final offset = int.tryParse(params['offset'] ?? '0', radix: 10);
    if (limit == null ||
        limit < 1 ||
        limit > 100 ||
        offset == null ||
        offset < 0) {
      throw const CustomerFailure(CustomerFailureCode.invalidInput);
    }
    return ApiResponse.success(
      data: await context.service.listOrders(
        customer.id,
        scope: scope,
        limit: limit,
        offset: offset,
      ),
      headers: noStoreHeaders,
    );
  });

  router.get('/orders/<id>', (Request request, String id) async {
    final customer = await context.requireActor(request);
    final orderId = requireCustomerUuid(id);
    return ApiResponse.success(
      data: await context.service.getOrder(customer.id, orderId: orderId),
      headers: noStoreHeaders,
    );
  });

  router.post('/orders/<id>/cancel', (Request request, String id) async {
    final customer = await context.requireActor(request);
    final orderId = requireCustomerUuid(id);
    return ApiResponse.success(
      data: await context.service.cancelOrder(customer.id, orderId: orderId),
      headers: noStoreHeaders,
    );
  });
}
