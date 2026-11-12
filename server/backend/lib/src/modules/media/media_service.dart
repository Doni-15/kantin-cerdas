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

    // 1. Replay: mutation_id yang sudah selesai mengembalikan hasil lama.
    final Map<String, dynamic>? existingReceipt;
    try {
      existingReceipt = await supabase.adminClient
          .from('mutation_receipts')
          .select('status, response_body')
          .eq('family', 'media-images')
          .eq('mutation_id', input.mutationId)
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
        existingReceipt['status'] == 'COMPLETED' &&
        existingReceipt['response_body'] is Map) {
      final prior = JsonMap.from(existingReceipt['response_body'] as Map);

      // Best-effort: bila respons lama menyimpan hash, key yang dipakai ulang
      // untuk file berbeda ditolak (bukan diam-diam mengembalikan hasil lama).
      final priorHash = prior['sha256_hex'] ?? prior['sha256'];
      if (priorHash is String && priorHash.toLowerCase() != sha256Hex) {
        throw ApiException.conflict(
          code: 'IDEMPOTENCY_KEY_REUSED',
          message: 'Idempotency-Key ini sudah dipakai untuk file yang berbeda.',
        );
      }
      return prior;
    }

    // 2. Pra-cek kuota (hemat bandwidth). Otoritas akhir tetap RPC di database.
    await _assertWithinQuota(actor.id);

    // 3. Unggah. upsert:false => tidak pernah menimpa file milik asset lain.
    //    Path berasal dari Idempotency-Key, jadi "sudah ada" berarti retry
    //    dari request yang sama.
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
      // Hanya hapus file yang DIUNGGAH OLEH REQUEST INI. File yang sudah ada
      // sebelumnya (retry) mungkin sudah terdaftar dan dipakai.
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
      // Row kemungkinan sudah tercatat, jadi file TIDAK dihapus.
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

  /// Retry dengan key sama: pastikan objek yang sudah ada identik dengan
  /// kiriman ini. Berbeda => Idempotency-Key dipakai ulang untuk file lain.
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

  /// Pra-cek kuota via daftar objek berawalan `<actor>_`. Gagal membaca
  /// daftar tidak memblokir upload (fail-open); RPC tetap menegakkan kuota.
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
