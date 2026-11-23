import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:kantin_cerdas_backend/src/core/media/avatar_image.dart';
import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_client_factory.dart';
import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_storage_helper.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/domain/avatar_store.dart';
import 'package:supabase/supabase.dart';

class SupabaseAvatarStore implements AvatarStore {
  const SupabaseAvatarStore(
    this._factory, {
    required this.timeout,
    http.Client? client,
  }) : _httpClient = client;

  final SupabaseClientFactory _factory;
  final Duration timeout;
  final http.Client? _httpClient;

  @override
  Future<Uint8List?> read(String accountId) => _call((storage) async {
    try {
      return await storage.download(_objectPath(accountId));
    } on StorageException catch (error) {
      if (isStorageObjectMissing(error)) return null;
      rethrow;
    }
  });

  @override
  Future<bool> exists(String accountId) =>
      _call((storage) => storage.exists(_objectPath(accountId)));

  @override
  Future<void> write(String accountId, Uint8List jpeg, {bool replace = true}) =>
      _call((storage) async {
        await storage.uploadBinary(
          _objectPath(accountId),
          jpeg,
          retryAttempts: 0,
          fileOptions: FileOptions(
            upsert: replace,
            contentType: 'image/jpeg',
            cacheControl: '0',
          ),
        );
      });

  @override
  Future<Uint8List> importGooglePhoto(
    String accountId,
    Uri url, {
    required int maxBytes,
  }) async {
    final client = _httpClient ?? http.Client();
    final Uint8List jpeg;
    try {
      jpeg = await _downloadGooglePhoto(client, url, maxBytes).timeout(timeout);
    } on Exception {
      throw AuthFailure.unavailable;
    } finally {
      if (_httpClient == null) client.close();
    }
    try {
      await write(accountId, jpeg, replace: false);
      return jpeg;
    } on AuthFailure catch (failure) {
      if (failure != AuthFailure.unavailable) rethrow;
      // Another request may have stored a photo first, or the upload may
      // have committed before its response was lost.
      final saved = await read(accountId);
      if (saved == null) rethrow;
      return saved;
    }
  }

  Future<Uint8List> _downloadGooglePhoto(
    http.Client client,
    Uri url,
    int maxBytes,
  ) async {
    final request = http.Request('GET', url)..followRedirects = false;
    final response = await client.send(request);
    final type = response.headers['content-type']?.split(';').first;
    if (response.statusCode != 200 ||
        type == null ||
        !const {'image/jpeg', 'image/png', 'image/webp'}.contains(type)) {
      throw AuthFailure.unavailable;
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.stream) {
      if (bytes.length + chunk.length > maxBytes) throw AuthFailure.unavailable;
      bytes.add(chunk);
    }
    return await normalizeAvatar(bytes.takeBytes(), type) ??
        (throw AuthFailure.unavailable);
  }

  String _objectPath(String accountId) {
    if (!RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    ).hasMatch(accountId)) {
      throw AuthFailure.invalidSession;
    }
    return '$accountId/avatar.jpg';
  }

  Future<T> _call<T>(Future<T> Function(StorageFileApi) action) =>
      runSupabaseStorage(
        factory: _factory,
        httpClient: _httpClient,
        bucketName: 'kantin-avatars',
        timeout: timeout,
        action: action,
        onUnavailable: () => AuthFailure.unavailable,
      );
}
