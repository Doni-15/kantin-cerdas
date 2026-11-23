import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_client_factory.dart';
import 'package:supabase/supabase.dart';

bool isStorageObjectMissing(StorageException error) {
  if (error.statusCode != '404' && error.statusCode != '400') return false;
  final body = error.message.trim();
  if (body.startsWith('{') && body.length <= 4096) {
    // Binary download leaves the provider's error body as JSON text.
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final code = decoded['code'] ?? decoded['error'];
        if (code == 'NoSuchBucket') return false;
        if (code == 'NoSuchKey') return true;
        final message = decoded['message'];
        return message is String &&
            message.trim().toLowerCase() == 'object not found';
      }
    } on FormatException {
      return false;
    }
  }
  return body.trim().toLowerCase() == 'object not found';
}

Future<T> runSupabaseStorage<T>({
  required SupabaseClientFactory factory,
  http.Client? httpClient,
  required String bucketName,
  required Duration timeout,
  required Future<T> Function(StorageFileApi storage) action,
  required Object Function() onUnavailable,
}) async {
  final client = factory.createServerClient(httpClient: httpClient);
  try {
    return await action(client.storage.from(bucketName)).timeout(timeout);
  } on StorageException {
    throw onUnavailable();
  } on TimeoutException {
    throw onUnavailable();
  } on SocketException {
    throw onUnavailable();
  } on http.ClientException {
    throw onUnavailable();
  } finally {
    await client.dispose();
  }
}
