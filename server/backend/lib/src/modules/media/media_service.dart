import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:supabase/supabase.dart';

import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/security/media_paths.dart';
import 'package:kantin_cerdas_backend/src/core/supabase/supabase_service.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/authenticated_actor.dart';
import 'package:kantin_cerdas_backend/src/modules/media/media_validated_input.dart';

typedef JsonMap = Map<String, Object?>;

/// Layanan bisnis domain Media (`POST /v1/media/images`).
final class MediaService {
  final SupabaseService supabase;
  final AppConfig config;

  const MediaService({
    required this.supabase,
    required this.config,
  });

  Future<JsonMap> uploadAndRegisterImage({
    required AuthenticatedActor actor,
    required ValidatedMediaUploadInput input,
  }) async {
    final bucket = config.storage.bucketName;
    final sha256Hex = sha256.convert(input.bytes).toString();

    // 1. Replay: request_id yang sudah selesai ('applied') mengembalikan hasil lama.
    //    Kolom di tabel public.mutation_receipts (002_tables.sql):
    //    family, request_id, actor_id, outcome, request_snapshot, response_snapshot
    final Map<String, dynamic>? existingReceipt;
    try {
      existingReceipt = await supabase.adminClient
          .from('mutation_receipts')
          .select('outcome, request_snapshot, response_snapshot')
          .eq('family', 'media-images')
          .eq('request_id', input.mutationId)
          .eq('actor_id', actor.id)
          .maybeSingle();
    } on PostgrestException catch (e) {
      stderr.writeln(
        '[ERROR] Cek mutation_receipts gagal: code=${e.code} '
        'message=${e.message} details=${e.details} hint=${e.hint}',
      );
      rethrow;
    }

    if (existingReceipt != null &&
        existingReceipt['outcome'] == 'applied' &&
        existingReceipt['response_snapshot'] is Map) {
      final priorResponse =
          JsonMap.from(existingReceipt['response_snapshot'] as Map);
      final reqSnap = existingReceipt['request_snapshot'];
      final priorHash = reqSnap is Map ? reqSnap['sha256_hex'] : null;

      if (priorHash is String && priorHash.toLowerCase() != sha256Hex) {
        throw ApiException.conflict(
          code: 'IDEMPOTENCY_KEY_REUSED',
          message: 'Idempotency-Key ini sudah dipakai untuk file yang berbeda.',
        );
      }
      return priorResponse;
    }

    // 2. Pra-cek kuota (hemat bandwidth). Otoritas akhir tetap RPC di database.
    await _assertWithinQuota(actor.id);

    // 3. Unggah. upsert:false => tidak pernah menimpa file milik asset lain.
    var uploadedByThisRequest = false;
    try {
      await supabase.adminClient.storage.from(bucket).uploadBinary(
            input.objectPath,
            input.bytes,
            fileOptions: FileOptions(
              contentType: input.mimeType,
              upsert: false,
            ),
          );
      uploadedByThisRequest = true;
    } on StorageException catch (e) {
      if (_isAlreadyExists(e)) {
        await _assertExistingObjectMatches(bucket, input.objectPath, sha256Hex);
      } else {
        stderr.writeln('[ERROR] Supabase Storage upload gagal: $e');
        throw const ApiException(
          statusCode: 502,
          code: 'STORAGE_UPLOAD_FAILED',
          message: 'Gagal menyimpan file gambar ke penyimpanan media.',
        );
      }
    }

    final publicUrl = supabase.adminClient.storage
        .from(bucket)
        .getPublicUrl(input.objectPath);

    // 4. Catat aset media & tegakkan kuota lewat RPC PostgreSQL.
    final dynamic rpcResult;
    try {
      rpcResult = await supabase.adminClient.rpc<dynamic>(
        'rpc_register_media_asset',
        params: {
          'p_actor_id': actor.id,
          'p_mutation_id': input.mutationId,
          'p_category': input.category,
          'p_object_path': input.objectPath,
          'p_public_url': publicUrl,
          'p_mime_type': input.mimeType,
          'p_size_bytes': input.sizeBytes,
          'p_sha256_hex': sha256Hex,
        },
      );
    } on PostgrestException catch (e) {
      stderr.writeln(
        '[ERROR] rpc_register_media_asset ditolak DB: code=${e.code} '
        'message=${e.message} details=${e.details} hint=${e.hint}',
      );
      if (uploadedByThisRequest) {
        try {
          await supabase.adminClient.storage
              .from(bucket)
              .remove(<String>[input.objectPath]);
        } catch (err) {
          stderr.writeln(
            '[WARN] Cleanup orphan gagal untuk ${input.objectPath}: $err',
          );
        }
      }
      rethrow;
    }

    if (rpcResult is! Map) {
      stderr.writeln(
        '[ERROR] rpc_register_media_asset mengembalikan tipe tak terduga: '
        '${rpcResult.runtimeType}',
      );
      throw const ApiException(
        statusCode: 500,
        code: 'MEDIA_REGISTER_FAILED',
        message: 'Gagal mendaftarkan aset media.',
      );
    }
    return JsonMap.from(rpcResult);
  }

  bool _isAlreadyExists(StorageException e) {
    final message = e.message.toLowerCase();
    return e.statusCode == '409' ||
        message.contains('already exists') ||
        message.contains('duplicate');
  }

  Future<void> _assertExistingObjectMatches(
    String bucket,
    String objectPath,
    String expectedSha256Hex,
  ) async {
    try {
      final existing =
          await supabase.adminClient.storage.from(bucket).download(objectPath);
      if (sha256.convert(existing).toString() != expectedSha256Hex) {
        throw ApiException.conflict(
          code: 'IDEMPOTENCY_KEY_REUSED',
          message: 'Idempotency-Key ini sudah dipakai untuk file yang berbeda.',
        );
      }
    } on StorageException catch (e) {
      stderr.writeln('[ERROR] Verifikasi objek yang sudah ada gagal: $e');
      throw const ApiException(
        statusCode: 502,
        code: 'STORAGE_UPLOAD_FAILED',
        message: 'Gagal memverifikasi file di penyimpanan media.',
      );
    }
  }

  Future<void> _assertWithinQuota(String actorId) async {
    final max = config.storage.maxFilesPerUser;
    final prefix = '${MediaPaths.sanitizeActorId(actorId)}_';
    try {
      final files = await supabase.adminClient.storage
          .from(config.storage.bucketName)
          .list(searchOptions: SearchOptions(limit: max + 1, search: prefix));
      final count = files.where((f) => f.name.startsWith(prefix)).length;
      if (count >= max) {
        throw ApiException.conflict(
          code: 'MEDIA_QUOTA_EXCEEDED',
          message: 'Kuota penyimpanan media Anda sudah penuh ($max file).',
        );
      }
    } on StorageException catch (e) {
      stderr.writeln('[WARN] Pra-cek kuota media dilewati: $e');
    }
  }
}