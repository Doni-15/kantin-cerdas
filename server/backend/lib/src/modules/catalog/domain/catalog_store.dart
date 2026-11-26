enum CatalogCollection {
  stalls,
  menu,
}

class CatalogEntry {
  const CatalogEntry({
    required this.id,
    required this.item,
  });

  final String id;
  final Map<String, Object?> item;
}

abstract interface class CatalogStore {
  Future<List<CatalogEntry>> read(
      CatalogCollection collection, {
        required String query,
        required String? after,
        required String? stallId,
        required int limit,
      });
}

enum CatalogFailureCode {
  invalidQuery,
  stallNotFound,
  unavailable,
}

class CatalogFailure implements Exception {
  const CatalogFailure(this.code, [this.message]);

  final CatalogFailureCode code;
  final String? message;

  @override
  String toString() =>
      'CatalogFailure(${code.name}${message == null ? '' : ': $message'})';
}
