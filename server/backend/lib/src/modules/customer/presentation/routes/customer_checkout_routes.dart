import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/domain/customer_errors.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/customer_request_parser.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/routes/customer_route_context.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

const _maxDraftVersion = 2147483647;

void registerCustomerCheckoutRoutes(
  Router router, {
  required CustomerRouteContext context,
}) {
  router.post('/checkout/attempts', (Request request) async {
    final customer = await context.requireActor(request);
    final body = await readCustomerJsonBody(request);
    final expectedVersion = readCustomerIntField(
      body,
      'expected_version',
      min: 1,
      max: _maxDraftVersion,
    );
    return ApiResponse.success(
      statusCode: 201,
      data: await context.service.createCheckoutAttempt(
        customer.id,
        expectedVersion: expectedVersion,
      ),
      headers: noStoreHeaders,
    );
  });

  router.get('/orders/attempts/<id>', (Request request, String id) async {
    final customer = await context.requireActor(request);
    final attemptId = requireCustomerUuid(id);
    final attempt = await context.service.getOrderByAttempt(
      customer.id,
      attemptId: attemptId,
    );
    if (attempt == null) {
      throw const CustomerFailure(CustomerFailureCode.orderNotFound);
    }
    return ApiResponse.success(data: attempt, headers: noStoreHeaders);
  });

  router.post('/orders', (Request request) async {
    final customer = await context.requireActor(request);
    final body = await readCustomerJsonBody(request);
    final attemptId = requireCustomerUuid(
      readCustomerRequiredText(body, 'attempt_id', maxLength: 36),
    );
    final expectedVersion = readCustomerIntField(
      body,
      'expected_version',
      min: 1,
      max: _maxDraftVersion,
    );
    final result = await context.service.checkout(
      customer.id,
      customerName: customer.displayName!,
      attemptId: attemptId,
      expectedVersion: expectedVersion,
    );
    final replayed = result['replayed'];
    if (replayed is! bool) {
      throw const CustomerFailure(CustomerFailureCode.unavailable);
    }
    return ApiResponse.success(
      statusCode: replayed ? 200 : 201,
      data: result,
      headers: noStoreHeaders,
    );
  });
}
