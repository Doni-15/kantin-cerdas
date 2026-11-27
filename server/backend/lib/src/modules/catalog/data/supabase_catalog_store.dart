import 'package:http/http.dart' as http;
import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_client_factory.dart';
import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_rpc_helper.dart';
import 'package:kantin_cerdas_backend/src/modules/catalog/domain/catalog_store.dart';

class SupabaseCatalogStore implements CatalogStore {
  const SupabaseCatalogStore(
      this._factory, {
        http.Client? httpClient,
      }) : _httpClient = httpClient;

  final SupabaseClientFactory _factory;
  final http.Client? _httpClient;

  @override
  Future<List<CatalogEntry>> read(
      CatalogCollection collection, {
        required String query,
        required String? after,
        required String? stallId,
        required int limit,
      }) {
    final function = switch (collection) {
      CatalogCollection.stalls => 'kc_catalog_stalls',
      CatalogCollection.menu => 'kc_catalog_menu',
    };

    return runSupabaseRpc<List<CatalogEntry>>(
      factory: _factory,
      httpClient: _httpClient,
      fn: function,
      params: {
        'p_query': query,
        'p_after': after,
        'p_stall_id': stallId,
        'p_limit': limit,
      },
      decode: _decodeCatalogEntries,
      onPostgrestError: (_) =>
      const CatalogFailure(CatalogFailureCode.unavailable),
      onUnavailable: () =>
      const CatalogFailure(CatalogFailureCode.unavailable),
    );
  }

  List<CatalogEntry> _decodeCatalogEntries(dynamic result) {
    const invalid = CatalogFailure(
      CatalogFailureCode.unavailable,
    );

    final rows = decodeRpcList(result, () => invalid);
    final entries = <CatalogEntry>[];

    for (final row in rows) {
      // RPC harus menghasilkan tepat dua kolom:
      // id dan item.
      if (row.length != 2 ||
          !row.containsKey('id') ||
          !row.containsKey('item')) {
        throw invalid;
      }

      // Validasi ID hasil query.
      final rawId = row['id'];

      if (rawId is! String) {
        throw invalid;
      }

      final id = tryNormalizeUuid(rawId);

      if (id == null) {
        throw invalid;
      }

      // Validasi objek JSON dari kolom item.
      final item = decodeRpcObject(
        row['item'],
            () => invalid,
      );

      // ID di dalam item harus sama dengan ID hasil query.
      final itemId = item['id'];

      if (itemId is! String ||
          tryNormalizeUuid(itemId) != id) {
        throw invalid;
      }

      entries.add(
        CatalogEntry(
          id: id,
          item: item,
        ),
      );
    }

    return List.unmodifiable(entries);
  }
}
