import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';
import 'package:kantin_cerdas_backend/src/core/config/storage_config.dart';
import 'package:test/test.dart';

void main() {
  const validValues = {
    'STORAGE_BUCKET_NAME': 'kantin-media',
    'STORAGE_PUBLIC_BASE_URL':
        'https://example.supabase.co/storage/v1/object/public/kantin-media',
  };

  group('StorageConfig', () {
    test('uses expected defaults', () {
      final config = StorageConfig.fromEnv(EnvConfig.fromMap(validValues));

      expect(config.bucketName, 'kantin-media');
      expect(config.maxUploadBytes, 2097152);
      expect(config.allowedImageTypes, [
        'image/jpeg',
        'image/png',
        'image/webp',
      ]);
      expect(config.maxFilesPerUser, 200);
      expect(
        config.publicBaseUrl.toString(),
        validValues['STORAGE_PUBLIC_BASE_URL'],
      );
    });

    test('reads custom storage settings', () {
      final config = StorageConfig.fromEnv(
        EnvConfig.fromMap({
          ...validValues,
          'STORAGE_MAX_UPLOAD_BYTES': '5242880',
          'STORAGE_ALLOWED_IMAGE_TYPES': 'image/png,image/webp',
          'STORAGE_MAX_FILES_PER_USER': '100',
        }),
      );

      expect(config.maxUploadBytes, 5242880);
      expect(config.allowedImageTypes, ['image/png', 'image/webp']);
      expect(config.maxFilesPerUser, 100);
    });

    test('normalizes MIME types', () {
      final config = StorageConfig.fromEnv(
        EnvConfig.fromMap({
          ...validValues,
          'STORAGE_ALLOWED_IMAGE_TYPES': 'IMAGE/PNG, IMAGE/JPEG',
        }),
      );

      expect(config.allowedImageTypes, ['image/png', 'image/jpeg']);
    });

    test('rejects invalid bucket name', () {
      expect(
        () => StorageConfig.fromEnv(
          EnvConfig.fromMap({
            ...validValues,
            'STORAGE_BUCKET_NAME': 'Invalid Bucket',
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects unsupported MIME type', () {
      expect(
        () => StorageConfig.fromEnv(
          EnvConfig.fromMap({
            ...validValues,
            'STORAGE_ALLOWED_IMAGE_TYPES': 'image/gif',
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects duplicate MIME types', () {
      expect(
        () => StorageConfig.fromEnv(
          EnvConfig.fromMap({
            ...validValues,
            'STORAGE_ALLOWED_IMAGE_TYPES': 'image/png,image/png',
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid upload size', () {
      expect(
        () => StorageConfig.fromEnv(
          EnvConfig.fromMap({...validValues, 'STORAGE_MAX_UPLOAD_BYTES': '0'}),
        ),
        throwsFormatException,
      );
    });

    test('rejects invalid user file quota', () {
      expect(
        () => StorageConfig.fromEnv(
          EnvConfig.fromMap({
            ...validValues,
            'STORAGE_MAX_FILES_PER_USER': '-1',
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects non-HTTPS public URL', () {
      expect(
        () => StorageConfig.fromEnv(
          EnvConfig.fromMap({
            ...validValues,
            'STORAGE_PUBLIC_BASE_URL':
                'http://example.supabase.co/storage/v1/object/public/kantin-media',
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects URL for a different bucket', () {
      expect(
        () => StorageConfig.fromEnv(
          EnvConfig.fromMap({
            ...validValues,
            'STORAGE_PUBLIC_BASE_URL':
                'https://example.supabase.co/storage/v1/object/public/other-bucket',
          }),
        ),
        throwsFormatException,
      );
    });

    test('rejects missing public URL', () {
      expect(
        () => StorageConfig.fromEnv(
          EnvConfig.fromMap({'STORAGE_BUCKET_NAME': 'kantin-media'}),
        ),
        throwsFormatException,
      );
    });
  });
}
