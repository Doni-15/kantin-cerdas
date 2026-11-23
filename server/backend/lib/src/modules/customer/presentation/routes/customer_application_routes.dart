import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/customer_request_parser.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/routes/customer_route_context.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

void registerCustomerApplicationRoutes(
  Router router, {
  required CustomerRouteContext context,
}) {
  // --- Owner Applications (CUSTOMER-006A, ADMIN-001, ADMIN-002) ---
  router.get('/owner-application', (Request request) async {
    final customer = await context.requireActor(request);
    return ApiResponse.success(
      data: await context.service.getOwnerApplicationState(customer.id),
      headers: noStoreHeaders,
    );
  });

  router.post('/owner-application', (Request request) async {
    final customer = await context.requireActor(
      request,
      strictCustomerRole: true,
    );
    final body = await readCustomerJsonBody(request);
    return ApiResponse.success(
      statusCode: 201,
      data: await context.service.submitOwnerApplication(
        customer.id,
        plannedStallName: readCustomerRequiredText(
          body,
          'planned_stall_name',
          maxLength: 120,
        ),
        plannedLocation: readCustomerRequiredText(
          body,
          'planned_location',
          maxLength: 120,
        ),
        reason: readCustomerRequiredText(
          body,
          'reason',
          maxLength: 500,
          allowNewlines: true,
        ),
      ),
      headers: noStoreHeaders,
    );
  });
}
