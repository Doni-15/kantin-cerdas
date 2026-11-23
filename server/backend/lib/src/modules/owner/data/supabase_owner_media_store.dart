import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:kantin_cerdas_backend/src/core/errors/owner_errors.dart';
import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_client_factory.dart';
import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_storage_helper.dart';
import 'package:kantin_cerdas_backend/src/modules/owner/domain/owner_store.dart';
import 'package:supabase/supabase.dart';

class SupabaseOwnerMediaStore implements OwnerMediaStore {
  const SupabaseOwnerMediaStore(
    this._factory, {
    required this.bucketName,
    required this.timeout,
    http.Client? client,
  }) : _httpClient = client;

  final SupabaseClientFactory _factory;
  final String bucketName;
  final Duration timeout;
  final http.Client? _httpClient;

  static final _validPath = RegExp(
    r'^(stalls|menus)/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/(cover|photo)\.jpg$',
  );

  @override
  Future<Uint8List?> read(String objectPath) => _call((storage) async {
    _validatePath(objectPath);
    try {
      return await storage.download(objectPath);
    } on StorageException catch (error) {
      if (isStorageObjectMissing(error)) return null;
      rethrow;
    }
  });

  @override
  Future<void> write(String objectPath, Uint8List jpegBytes) =>
      _call((storage) async {
        _validatePath(objectPath);
        await storage.uploadBinary(
          objectPath,
          jpegBytes,
          retryAttempts: 0,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
            cacheControl: '0',
          ),
        );
      });

  @override
  Future<void> delete(String objectPath) => _call((storage) async {
    _validatePath(objectPath);
    try {
      await storage.remove([objectPath]);
    } on StorageException catch (error) {
      if (isStorageObjectMissing(error)) return;
      rethrow;
    }
  });

  void _validatePath(String objectPath) {
    if (!_validPath.hasMatch(objectPath)) {
      throw const OwnerFailure(OwnerFailureCode.invalidInput);
    }
  }

  Future<T> _call<T>(Future<T> Function(StorageFileApi) action) =>
      runSupabaseStorage(
        factory: _factory,
        httpClient: _httpClient,
        bucketName: bucketName,
        timeout: timeout,
        action: action,
        onUnavailable: () => const OwnerFailure(OwnerFailureCode.unavailable),
      );
}
