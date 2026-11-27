import 'package:kantin_cerdas_backend/src/core/http/api_response.dart';
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/catalog/domain/catalog_store.dart';
import 'package:kantin_cerdas_backend/src/modules/catalog/presentation/catalog_request_parser.dart';
import 'package:kantin_cerdas_backend/src/modules/catalog/presentation/routes/catalog_route_context.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

void registerCatalogStallRoutes(
    Router router, {
      required CatalogRouteContext context,
    }) {
  // GET /stalls
  // Mengambil daftar kantin yang tersedia di katalog.
  router.get('/stalls', (Request request) async {
    await context.requireActor(request);

    final params = parseCatalogListQuery(
      request,
      collection: CatalogCollection.stalls,
    );

    final page = await context.readPage(
      collection: CatalogCollection.stalls,
      query: params.query,
      after: params.after,
      stallId: params.stallId,
      limit: params.limit,
    );

    return ApiResponse.success(
      data: {
        'items': page.items,
        'next_cursor': page.nextCursor,
      },
      headers: noStoreHeaders,
    );
  });

  // GET /stalls/:id
  // Mengambil detail kantin berdasarkan UUID.
  router.get('/stalls/<id>', (Request request, String id) async {
    await context.requireActor(request);

    final stallId = requireCatalogUuid(id);

    final entries = await context.store.read(
      CatalogCollection.stalls,
      query: '',
      after: null,
      stallId: stallId,
      limit: 1,
    );

    if (entries.isEmpty) {
      throw const CatalogFailure(
        CatalogFailureCode.stallNotFound,
      );
    }

    return ApiResponse.success(
      data: entries.first.item,
      headers: noStoreHeaders,
    );
  });
}
