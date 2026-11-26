import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/catalog/domain/catalog_store.dart';
import 'package:kantin_cerdas_backend/src/modules/catalog/presentation/catalog_request_parser.dart';
import 'package:kantin_cerdas_backend/src/modules/catalog/presentation/routes/catalog_route_context.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

void registerCatalogMenuRoutes(
    Router router, {
      required CatalogRouteContext context,
    }) {
  router.get('/menu', (Request request) async {
    // 1. Validasi autentikasi dan kelengkapan profil.
    await context.requireActor(request);

    // 2. Validasi parameter permintaan.
    final params = parseCatalogListQuery(
      request,
      collection: CatalogCollection.menu,
    );

    // 3. Ambil data menu menggunakan cursor pagination.
    final page = await context.readPage(
      collection: CatalogCollection.menu,
      query: params.query,
      after: params.after,
      stallId: params.stallId,
      limit: params.limit,
    );

    // 4. Kembalikan respons sesuai kontrak CatalogRepository.
    return ApiResponse.success(
      data: {
        'items': page.items,
        'next_cursor': page.nextCursor,
      },
      headers: noStoreHeaders,
    );
  });
}
