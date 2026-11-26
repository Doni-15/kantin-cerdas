import 'package:kantin_cerdas_backend/src/core/auth/auth_guard.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/avatar_store.dart';
import 'package:kantin_cerdas_backend/src/modules/catalog/domain/catalog_store.dart';
import 'package:shelf/shelf.dart';

class CatalogRouteContext {
  const CatalogRouteContext({
    required this.auth,
    required this.avatars,
    required this.store,
  });

  final AuthGateway auth;
  final AvatarStore avatars;
  final CatalogStore store;

  Future<AuthAccount> requireActor(Request request) async {
    final actor = await auth.account(requireBearer(request));

    if (actor.displayName == null || !await avatars.exists(actor.id)) {
      throw AuthFailure.profileIncomplete;
    }

    return actor;
  }

  Future<({List<Map<String, Object?>> items, String? nextCursor})> readPage({
    required CatalogCollection collection,
    required String query,
    required String? after,
    required String? stallId,
    required int limit,
  }) async {
    final entries = await store.read(
      collection,
      query: query,
      after: after,
      stallId: stallId,
      limit: limit + 1,
    );

    final hasMore = entries.length > limit;

    final pageEntries = hasMore
        ? entries.take(limit).toList(growable: false)
        : entries;

    return (
    items: List<Map<String, Object?>>.unmodifiable(
      pageEntries.map((entry) => entry.item),
    ),
    nextCursor: hasMore && pageEntries.isNotEmpty
        ? pageEntries.last.id
        : null,
    );
  }
}
