import 'package:kantin_cerdas_backend/src/core/config/env_config.dart';

class StorageConfig {
  const StorageConfig._({
    required this.bucketName,
    required this.maxUploadBytes,
    required this.allowedImageTypes,
    required this.maxFilesPerUser,
    required this.publicBaseUrl,
  });

  final String bucketName;
  final int maxUploadBytes;
  final List<String> allowedImageTypes;
  final int maxFilesPerUser;
  final Uri publicBaseUrl;

  factory StorageConfig.fromEnv(EnvConfig env) {
    final bucketName = _readString(
      env,
      'STORAGE_BUCKET_NAME',
      defaultValue: 'kantin-media',
    );

    if (!RegExp(r'^[a-z0-9][a-z0-9_-]{1,61}[a-z0-9]$').hasMatch(bucketName)) {
      throw const FormatException('STORAGE_BUCKET_NAME tidak valid.');
    }

    final publicBaseUrl = _readPublicBaseUrl(
      _readRequiredString(env, 'STORAGE_PUBLIC_BASE_URL'),
      bucketName,
    );

    return StorageConfig._(
      bucketName: bucketName,
      maxUploadBytes: _readInt(
        env,
        'STORAGE_MAX_UPLOAD_BYTES',
        defaultValue: 2097152,
        min: 1,
        max: 1073741824,
      ),
      allowedImageTypes: List.unmodifiable(
        _readImageTypes(
          env['STORAGE_ALLOWED_IMAGE_TYPES'] ??
              'image/jpeg,image/png,image/webp',
        ),
      ),
      maxFilesPerUser: _readInt(
        env,
        'STORAGE_MAX_FILES_PER_USER',
        defaultValue: 200,
        min: 1,
        max: 100000,
      ),
      publicBaseUrl: publicBaseUrl,
    );
  }

  static String _readString(
    EnvConfig env,
    String key, {
    required String defaultValue,
  }) {
    final value = env[key]?.trim();

    if (value == null || value.isEmpty) {
      return defaultValue;
    }

    return value;
  }

  static String _readRequiredString(EnvConfig env, String key) {
    final value = env[key]?.trim();

    if (value == null || value.isEmpty) {
      throw FormatException('$key wajib diisi.');
    }

    return value;
  }

  static Uri _readPublicBaseUrl(String value, String bucketName) {
    final uri = Uri.tryParse(value);
    final expectedPath = '/storage/v1/object/public/$bucketName';

    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.path.replaceFirst(RegExp(r'/$'), '') != expectedPath) {
      throw FormatException(
        'STORAGE_PUBLIC_BASE_URL harus berupa HTTPS URL '
        'untuk bucket $bucketName dengan path $expectedPath.',
      );
    }

    return uri;
  }

  static List<String> _readImageTypes(String rawValue) {
    final types = rawValue
        .split(',')
        .map((value) => value.trim().toLowerCase())
        .toList();

    if (types.isEmpty || types.any((type) => type.isEmpty)) {
      throw const FormatException(
        'STORAGE_ALLOWED_IMAGE_TYPES tidak boleh kosong.',
      );
    }

    const allowedTypes = {'image/jpeg', 'image/png', 'image/webp'};

    for (final type in types) {
      if (!allowedTypes.contains(type)) {
        throw FormatException('Tipe file tidak didukung: $type.');
      }
    }

    if (types.toSet().length != types.length) {
      throw const FormatException(
        'STORAGE_ALLOWED_IMAGE_TYPES tidak boleh berisi duplikasi.',
      );
    }

    return types;
  }

  static int _readInt(
    EnvConfig env,
    String key, {
    required int defaultValue,
    required int min,
    required int max,
  }) {
    final rawValue = env[key];

    if (rawValue == null || rawValue.trim().isEmpty) {
      return defaultValue;
    }

    final value = int.tryParse(rawValue.trim());

    if (value == null || value < min || value > max) {
      throw FormatException('$key harus berupa angka antara $min dan $max.');
    }

    return value;
  }
}
