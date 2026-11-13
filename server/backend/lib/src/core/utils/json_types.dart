import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';

/// Alias tipe objek JSON standar di seluruh modul backend.
typedef JsonMap = Map<String, Object?>;

/// Mengonversi hasil RPC database menjadi [JsonMap] atau melempar 500 `DATABASE_ERROR`.
JsonMap asDatabaseMap(Object? rpcResult, String label) {
  if (rpcResult is Map) {
    return JsonMap.from(rpcResult);
  }
  throw ApiException(
    statusCode: 500,
    code: 'DATABASE_ERROR',
    message: 'Format $label dari database tidak valid.',
  );
}