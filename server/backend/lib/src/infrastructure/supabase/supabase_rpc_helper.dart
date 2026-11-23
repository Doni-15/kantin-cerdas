import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_client_factory.dart';
import 'package:supabase/supabase.dart';

Future<T> runSupabaseRpc<T>({
  required SupabaseClientFactory factory,
  http.Client? httpClient,
  required String fn,
  required Map<String, Object?> params,
  required T Function(dynamic result) decode,
  required Object Function(PostgrestException error) onPostgrestError,
  required Object Function() onUnavailable,
}) async {
  final client = factory.createServerClient(httpClient: httpClient);
  try {
    final result = await client.rpc<dynamic>(fn, params: params);
    return decode(result);
  } on PostgrestException catch (error) {
    throw onPostgrestError(error);
  } on TimeoutException {
    throw onUnavailable();
  } on IOException {
    throw onUnavailable();
  } on http.ClientException {
    throw onUnavailable();
  } on FormatException {
    throw onUnavailable();
  } on TypeError {
    throw onUnavailable();
  } finally {
    await client.dispose();
  }
}

Map<String, Object?> decodeRpcObject(
  dynamic result,
  Object Function() onInvalid,
) {
  if (result is Map<String, Object?>) return result;
  if (result is Map) return Map<String, Object?>.from(result);
  throw onInvalid();
}

Map<String, Object?>? decodeRpcNullableObject(
  dynamic result,
  Object Function() onInvalid,
) {
  if (result == null) return null;
  return decodeRpcObject(result, onInvalid);
}

List<Map<String, Object?>> decodeRpcList(
  dynamic result,
  Object Function() onInvalid,
) {
  if (result is! List) {
    throw onInvalid();
  }
  return [for (final row in result) decodeRpcObject(row, onInvalid)];
}

String? decodeRpcNullableText(dynamic result, Object Function() onInvalid) {
  if (result == null) return null;
  if (result is String) return result;
  throw onInvalid();
}

T? matchPostgrestErrorToken<T>(
  PostgrestException error,
  Map<String, T> mapping,
) {
  final token = '${error.message} ${error.details ?? ''}';
  for (final entry in mapping.entries) {
    if (token.contains(entry.key)) {
      return entry.value;
    }
  }
  return null;
}
