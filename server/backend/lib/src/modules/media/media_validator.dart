import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:mime/mime.dart';
import 'package:shelf/shelf.dart';

import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/constants/security_constants.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/security/image_guard.dart';
import 'package:kantin_cerdas_backend/src/core/security/media_paths.dart';
import 'package:kantin_cerdas_backend/src/modules/media/media_validated_input.dart';

/// Validator keamanan Zero-Trust & parser `multipart/form-data` untuk modul Media.
final class MediaValidator {
  const MediaValidator._();

  /// Memvalidasi request `POST /v1/media/images` secara menyeluruh.
  static Future<ValidatedMediaUploadInput> validateUploadRequest({
    required Request request,
    required String actorId,
    required String actorRole,
    required StorageConfig storage,
  }) async {
    // 1. Idempotency-Key (48 hex huruf kecil, sesuai 010_storage.sql)
    final rawMutationId = (request.headers['idempotency-key'] ?? '').trim();
    if (!SecurityConstants.idempotencyKeyPattern.hasMatch(rawMutationId)) {
      throw ApiException.unprocessable(
        'Header Idempotency-Key wajib berupa 48 karakter hex huruf kecil.',
        code: 'INVALID_INPUT',
      );
    }

    // 2. Content-Type multipart/form-data + boundary
    final boundary = _extractBoundary(request.headers['content-type'] ?? '');
    if (boundary == null) {
      throw ApiException.badRequest(
        'Content-Type wajib berupa multipart/form-data dengan boundary yang valid.',
        code: 'INVALID_MULTIPART',
      );
    }

    // 3. Parse multipart (streaming, dengan batas ukuran per bagian)
    final parsed = await _parseMultipart(request, boundary);

    // 4. Kategori media & hak akses role
    final category = (parsed.fields['category'] ?? '').trim();
    if (!SecurityConstants.allowedCategories.contains(category)) {
      throw ApiException.unprocessable(
        'Kategori media tidak valid. Gunakan profile_avatar, menu_photo, atau stall_photo.',
        code: 'INVALID_INPUT',
        fieldErrors: const {'category': 'Kategori media tidak valid.'},
      );
    }

    if ((category == 'menu_photo' || category == 'stall_photo') &&
        actorRole != 'owner' &&
        actorRole != 'admin') {
      throw ApiException.forbidden(
        'Hanya pemilik stan (owner) yang dapat mengunggah foto menu atau stan.',
        'FORBIDDEN_ROLE',
      );
    }

    // 5. Validasi + sanitasi gambar (pipeline bersama)
    final fileBytes = parsed.fileBytes;
    if (fileBytes == null) {
      throw ApiException.unprocessable(
        'File gambar kosong atau tidak ditemukan pada field "file".',
        code: 'INVALID_IMAGE',
      );
    }
    final image = ImageGuard.validate(fileBytes, storage);

    // 6. Path kanonis: actor terautentikasi + kategori + UUID dari Idempotency-Key.
    //    `file_name` dari client sengaja diabaikan.
    final objectPath = MediaPaths.buildObjectPath(
      actorId: actorId,
      category: category,
      mutationId: rawMutationId,
      extension: image.extension,
    );

    return ValidatedMediaUploadInput(
      mutationId: rawMutationId,
      category: category,
      objectPath: objectPath,
      mimeType: image.mimeType,
      bytes: image.bytes,
    );
  }

  static String? _extractBoundary(String contentType) {
    final lower = contentType.toLowerCase();
    if (!lower.startsWith('multipart/form-data')) return null;

    final parts = contentType.split(';');
    for (var i = 1; i < parts.length; i++) {
      final segment = parts[i].trim();
      if (segment.toLowerCase().startsWith('boundary=')) {
        var value = segment.substring('boundary='.length).trim();
        if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
          value = value.substring(1, value.length - 1);
        }
        if (value.isNotEmpty && value.length <= 70) return value;
      }
    }
    return null;
  }

  /// Parse multipart dengan `package:mime`.
  ///
  /// Catatan penting (sudah diuji):
  /// 1. Parser melempar error di dalam callback stream untuk input rusak
  ///    tertentu (mis. boundary dengan LF saja). Tanpa [runZonedGuarded] error
  ///    itu menjadi "unhandled" dan MEMATIKAN proses server.
  /// 2. Setiap bagian harus dikonsumsi tanpa di-await secara berurutan,
  ///    karena body terpotong akan membuat `await for` pada bagian menggantung
  ///    selamanya. Karena itu bagian dibaca paralel lalu di-await sesudah loop.
  static Future<({Map<String, String> fields, Uint8List? fileBytes})>
  _parseMultipart(Request request, String boundary) {
    final done =
        Completer<({Map<String, String> fields, Uint8List? fileBytes})>();

    void fail(Object error, StackTrace st) {
      if (!done.isCompleted) done.completeError(error, st);
    }

    runZonedGuarded(() async {
      try {
        final pending =
            <({String? name, bool isFile, Future<_PartData> data})>[];
        final capped = _cap(
          request.read(),
          SecurityConstants.maxMultipartEnvelopeBytes,
        );

        await for (final part in capped.transform(
          MimeMultipartTransformer(boundary),
        )) {
          if (pending.length >= SecurityConstants.maxMultipartParts) {
            throw ApiException.badRequest(
              'Terlalu banyak bagian pada body multipart.',
              code: 'INVALID_MULTIPART',
            );
          }

          final disposition = _parseContentDisposition(
            part.headers['content-disposition'] ?? '',
          );
          final isFile = disposition.name == 'file' || disposition.hasFilename;
          final data = _readPart(
            part,
            isFile
                ? SecurityConstants.maxImageBytes + 1
                : SecurityConstants.maxMultipartFieldBytes,
          )..ignore();
          pending.add((name: disposition.name, isFile: isFile, data: data));
        }

        final fields = <String, String>{};
        Uint8List? fileBytes;
        for (final p in pending) {
          final result = await p.data;
          if (result.tooLarge) {
            throw p.isFile
                ? const ApiException(
                    statusCode: 413,
                    code: 'FILE_TOO_LARGE',
                    message: 'Ukuran file gambar melebihi batas maksimal 2 MB.',
                  )
                : ApiException.badRequest(
                    'Field multipart terlalu besar.',
                    code: 'INVALID_MULTIPART',
                  );
          }
          final name = p.name;
          if (name == null || name.isEmpty) continue;
          if (p.isFile) {
            fileBytes ??= result.bytes;
          } else {
            fields[name] = utf8.decode(result.bytes!, allowMalformed: true);
          }
        }

        if (!done.isCompleted) {
          done.complete((fields: fields, fileBytes: fileBytes));
        }
      } catch (e, st) {
        fail(e, st);
      }
    }, fail);

    return done.future.catchError(
      (Object e, StackTrace st) =>
          Future<({Map<String, String> fields, Uint8List? fileBytes})>.error(
            e is ApiException
                ? e
                : ApiException.badRequest(
                    'Body multipart/form-data tidak lengkap atau rusak.',
                    code: 'INVALID_MULTIPART',
                  ),
            st,
          ),
    );
  }

  /// Membaca satu bagian; TIDAK pernah melempar (lihat catatan di atas).
  /// Kelebihan ukuran hanya menandai [_PartData.tooLarge] dan sisa data dibuang.
  static Future<_PartData> _readPart(Stream<List<int>> part, int limit) async {
    final builder = BytesBuilder(copy: false);
    var tooLarge = false;
    await for (final chunk in part) {
      if (tooLarge) continue;
      if (builder.length + chunk.length > limit) {
        tooLarge = true;
        continue;
      }
      builder.add(chunk);
    }
    return _PartData(tooLarge ? null : builder.takeBytes(), tooLarge);
  }

  static Stream<List<int>> _cap(Stream<List<int>> source, int max) async* {
    var total = 0;
    await for (final chunk in source) {
      total += chunk.length;
      if (total > max) {
        throw const ApiException(
          statusCode: 413,
          code: 'FILE_TOO_LARGE',
          message: 'Ukuran permintaan melebihi batas maksimal yang diizinkan.',
        );
      }
      yield chunk;
    }
  }

  static ({String? name, bool hasFilename}) _parseContentDisposition(
    String header,
  ) {
    String? name;
    var hasFilename = false;

    if (header.toLowerCase().startsWith('form-data')) {
      final nameMatch = RegExp(r'\bname="([^"]+)"').firstMatch(header);
      if (nameMatch != null) name = nameMatch.group(1);
      if (RegExp(r'\bfilename=').hasMatch(header)) hasFilename = true;
    }
    return (name: name, hasFilename: hasFilename);
  }
}

final class _PartData {
  final Uint8List? bytes;
  final bool tooLarge;
  const _PartData(this.bytes, this.tooLarge);
}
