import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/customer_request_parser.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/presentation/routes/customer_route_context.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

void registerCustomerCatalogRoutes(
  Router router, {
  required CustomerRouteContext context,
}) {
  router.get('/stalls/<id>', (Request request, String id) async {
    await context.requireActor(request);
    final stallId = requireCustomerUuid(id);
    return ApiResponse.success(
      data: await context.service.getStallDetail(stallId),
      headers: noStoreHeaders,
    );
  });

  router.get('/menus/<id>', (Request request, String id) async {
    await context.requireActor(request);
    final menuId = requireCustomerUuid(id);
    return ApiResponse.success(
      data: await context.service.getMenuDetail(menuId),
      headers: noStoreHeaders,
    );
  });

  router.get('/stalls/<id>/photo', (Request request, String id) async {
    await context.requireActor(request);
    final stallId = requireCustomerUuid(id);
    await context.service.getStallDetail(stallId);
    return jpegDownloadResponse(await context.service.readStallPhoto(stallId));
  });

  router.get('/menus/<id>/photo', (Request request, String id) async {
    await context.requireActor(request);
    final menuId = requireCustomerUuid(id);
    await context.service.getMenuDetail(menuId);
    return jpegDownloadResponse(await context.service.readMenuPhoto(menuId));
  });
}
