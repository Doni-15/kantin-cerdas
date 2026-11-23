import 'package:kantin_cerdas/features/auth/data/auth_repository.dart';
import 'package:kantin_cerdas/features/catalog/domain/catalog_models.dart';

export 'package:kantin_cerdas/features/catalog/domain/catalog_models.dart';

class CatalogRepository {
  const CatalogRepository(this._auth);
  final AuthRepository _auth;

  Future<CatalogPage> list(
    AuthSession session,
    CatalogKind kind, {
    String query = '',
    String? stallId,
    String? cursor,
  }) async {
    final result = await _auth.readAuthenticated(
      session,
      ['catalog', kind.path],
      query: {
        if (query.isNotEmpty) 'q': query,
        'stall_id': ?stallId,
        'cursor': ?cursor,
      },
    );
    return _decode(() {
      final data = result as Map<String, dynamic>;
      final items = [
        for (final row in data['items'] as List<dynamic>)
          switch (kind) {
            CatalogKind.stalls => CatalogStall.fromJson(
              row as Map<String, dynamic>,
            ),
            CatalogKind.menu => CatalogMenuItem.fromJson(
              row as Map<String, dynamic>,
            ),
          },
      ];
      final next = data['next_cursor'];
      if (next != null &&
          (items.isEmpty || next != items.last.id || next == cursor)) {
        throw const FormatException('Invalid catalog cursor');
      }
      return (
        items: List<CatalogItem>.unmodifiable(items),
        nextCursor: next as String?,
      );
    });
  }

  Future<CatalogStall> stall(AuthSession session, String id) async {
    final result = await _auth.readAuthenticated(session, [
      'catalog',
      'stalls',
      readCatalogId(id),
    ]);
    return _decode(() {
      final stall = CatalogStall.fromJson(result as Map<String, dynamic>);
      if (stall.id != id) throw const FormatException('Unexpected stall');
      return stall;
    });
  }
}

T _decode<T>(T Function() read) {
  const error = AuthException(
    'INVALID_CATALOG_RESPONSE',
    'Katalog mengirim data yang tidak valid. Coba lagi.',
  );
  try {
    return read();
  } on FormatException {
    throw error;
  } on TypeError {
    throw error;
  }
}
