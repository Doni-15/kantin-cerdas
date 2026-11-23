import 'package:kantin_cerdas_backend/src/core/auth/auth_guard.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/errors/owner_errors.dart';
import 'package:kantin_cerdas_backend/src/core/errors/owner_failure_mapper.dart';
import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/avatar_store.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/application/customer_service.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/domain/customer_errors.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/customer_failure_mapper.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/routes/customer_application_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/routes/customer_cart_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/routes/customer_catalog_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/routes/customer_checkout_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/routes/customer_order_routes.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/routes/customer_route_context.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

Handler buildCustomerHandler(
  AuthGateway auth, {
  required AvatarStore avatars,
  required CustomerService service,
}) {
  final router = Router(notFoundHandler: notFoundNoStoreResponse);
  final context = CustomerRouteContext(
    auth: auth,
    avatars: avatars,
    service: service,
  );

  registerCustomerCatalogRoutes(router, context: context);
  registerCustomerCartRoutes(router, context: context);
  registerCustomerCheckoutRoutes(router, context: context);
  registerCustomerOrderRoutes(router, context: context);
  registerCustomerApplicationRoutes(router, context: context);

  return (request) async {
    final ApiException error;
    try {
      return await router.call(request);
    } on AuthFailure catch (failure) {
      error = authFailureException(failure);
    } on CustomerFailure catch (failure) {
      error = customerFailureException(failure);
    } on OwnerFailure catch (failure) {
      error = ownerFailureException(failure);
    } on ApiException catch (exception) {
      error = exception;
    } on FormatException {
      error = customerFailureException(
        const CustomerFailure(CustomerFailureCode.invalidInput),
      );
    }
    return ApiResponse.error(
      statusCode: error.statusCode,
      code: error.code,
      message: error.message,
      headers: noStoreHeaders,
    );
  };
}
