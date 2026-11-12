import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/core/media/image_security_validator.dart';
import 'package:kantin_cerdas/core/media/media_upload_failure.dart';
import 'package:kantin_cerdas/core/media/media_upload_repository.dart';
import 'package:kantin_cerdas/core/network/api_exception_mapper.dart';
import 'package:kantin_cerdas/core/network/app_environment.dart';
import 'package:kantin_cerdas/core/network/dio_client_provider.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';
import 'package:kantin_cerdas/core/utils/mutation_id_generator.dart';

/// Implementasi konkret [MediaUploadRepository] yang mengirim gambar melalui
/// `multipart/form-data` ke `POST /v1/media/images`.
final class DioMediaUploadRepository implements MediaUploadRepository {
  const DioMediaUploadRepository({this.dio});

  final Dio? dio;
  static const Duration _uploadTimeout = Duration(seconds: 30);

  @override
  bool get isConfigured => dio != null && AppEnvironment.isApiConfigured;

  @override
  Future<String> uploadImage(ValidatedUploadImage image) async {
    final client = dio;
    if (!isConfigured || client == null) {
      throw const MediaNotConfiguredFailure();
    }

    // Validasi ulang nama file kanonis untuk menjamin tidak ada manipulasi
    if (!ImageSecurityValidator.isSafeGeneratedFileName(image.safeFileName)) {
      throw const MediaInvalidImageFailure(
        MediaValidationReason.invalidActorId,
      );
    }

    final mutationId = generateSecureMutationId();
    final formData = FormData.fromMap(<String, Object?>{
      'category': image.category.slug,
      'file_name': image.safeFileName,
      'file': MultipartFile.fromBytes(
        image.bytes,
        filename: image.safeFileName,
        contentType: DioMediaType.parse(image.mimeType),
      ),
    });

    try {
      final response = await client
          .post<Object?>(
            '/v1/media/images',
            data: formData,
            options: Options(
              headers: <String, Object?>{'Idempotency-Key': mutationId},
            ),
          )
          .timeout(_uploadTimeout);

      final body = asJsonMap(response.data, fieldName: 'media_upload');
      final rawUrl = body['image_url'] ?? body['imageUrl'] ?? body['url'];
      if (rawUrl is! String) {
        throw const MediaUnexpectedFailure();
      }
      final safeUrl = ImageSecurityValidator.normalizeSafeImageUrl(
        rawUrl,
        fieldName: 'image_url',
      );
      if (safeUrl == null) {
        throw const MediaUnexpectedFailure();
      }
      return safeUrl;
    } on MediaUploadFailure {
      rethrow;
    } on FormatException {
      throw const MediaUnexpectedFailure();
    } on TimeoutException {
      throw const MediaNetworkFailure();
    } on DioException catch (error) {
      throw _mapApiException(mapDioException(error));
    } catch (_) {
      throw const MediaUnexpectedFailure();
    }
  }

  MediaUploadFailure _mapApiException(ApiException error) {
    return switch (error.type) {
      ApiExceptionType.connection ||
      ApiExceptionType.timeout => const MediaNetworkFailure(),
      ApiExceptionType.response => switch (error.statusCode) {
        401 || 403 => const MediaUnauthorizedFailure(),
        429 => const MediaRateLimitedFailure(),
        413 => const MediaInvalidImageFailure(
          MediaValidationReason.fileTooLarge,
        ),
        415 => const MediaInvalidImageFailure(
          MediaValidationReason.unsupportedFormat,
        ),
        400 || 422 => const MediaInvalidImageFailure(
          MediaValidationReason.corruptedHeader,
        ),
        _
            when error.code == 'RATE_LIMITED' ||
                error.code == 'TOO_MANY_REQUESTS' =>
          const MediaRateLimitedFailure(),
        final int code when code >= 500 && code <= 599 =>
          const MediaServerFailure(),
        _ => const MediaUnexpectedFailure(),
      },
      ApiExceptionType.cancelled ||
      ApiExceptionType.unexpected => const MediaUnexpectedFailure(),
    };
  }
}

final dioMediaUploadRepositoryProvider = Provider<MediaUploadRepository>((ref) {
  return DioMediaUploadRepository(dio: ref.watch(dioClientProvider));
});
