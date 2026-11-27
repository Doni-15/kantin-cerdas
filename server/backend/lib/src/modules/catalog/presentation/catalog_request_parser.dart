import 'package:kantin_cerdas_backend/src/core/http/http_helpers.dart';
import 'package:kantin_cerdas_backend/src/modules/catalog/domain/catalog_store.dart';
import 'package:shelf/shelf.dart';

const _defaultCatalogLimit = 20;
const _maxCatalogLimit = 40;
const _maxCatalogQueryLength = 100;

typedef CatalogListQuery = ({
String query,
String? after,
String? stallId,
int limit,
});

String requireCatalogUuid(String raw) {
  final value = tryNormalizeUuid(raw);
  if (value == null) {
    throw const CatalogFailure(CatalogFailureCode.invalidQuery);
  }
  return value;
}

String? optionalCatalogUuidQuery(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  return requireCatalogUuid(raw);
}

CatalogListQuery parseCatalogListQuery(
    Request request, {
      required CatalogCollection collection,
    }) {
  final params = request.url.queryParametersAll;

  final allowedParameters = collection == CatalogCollection.stalls
      ? const {'q', 'limit', 'cursor'}
      : const {'q', 'limit', 'cursor', 'stall_id'};

  // Reject unknown and duplicated query parameters.
  if (params.keys.any((key) => !allowedParameters.contains(key)) ||
      params.values.any((values) => values.length != 1)) {
    throw const CatalogFailure(CatalogFailureCode.invalidQuery);
  }

  String? valueOf(String key) => params[key]?.single;

  final query = _readCatalogSearchQuery(valueOf('q'));
  final limit = _readCatalogLimit(valueOf('limit'));
  final after = optionalCatalogUuidQuery(valueOf('cursor'));

  final stallId = collection == CatalogCollection.menu
      ? optionalCatalogUuidQuery(valueOf('stall_id'))
      : null;

  return (
  query: query,
  after: after,
  stallId: stallId,
  limit: limit,
  );
}

String _readCatalogSearchQuery(String? raw) {
  if (raw == null) return '';

  if (hasStrictControlChars(raw)) {
    throw const CatalogFailure(CatalogFailureCode.invalidQuery);
  }

  final value = raw.trim();

  if (value.runes.length > _maxCatalogQueryLength) {
    throw const CatalogFailure(CatalogFailureCode.invalidQuery);
  }

  return value;
}

int _readCatalogLimit(String? raw) {
  if (raw == null || raw.isEmpty) {
    return _defaultCatalogLimit;
  }

  final value = int.tryParse(raw);

  if (value == null || value < 1 || value > _maxCatalogLimit) {
    throw const CatalogFailure(CatalogFailureCode.invalidQuery);
  }

  return value;
}
