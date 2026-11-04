import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/media/image_picker_port.dart';
import 'package:kantin_cerdas/core/media/image_security_validator.dart';
import 'package:kantin_cerdas/core/media/media_upload_category.dart';
import 'package:kantin_cerdas/core/media/media_upload_failure.dart';

/// Implementasi konkret [ImagePickerPort] menggunakan jembatan platform native
/// Android (`com.kantincerdas.app/image_picker`).
final class DeviceImagePickerAdapter implements ImagePickerPort {
  const DeviceImagePickerAdapter({MethodChannel? channel})
    : _channel = channel ?? _defaultChannel;

  static const MethodChannel _defaultChannel = MethodChannel(
    'com.kantincerdas.app/image_picker',
  );

  final MethodChannel _channel;

  @override
  Future<RawPickedImage?> pickImage(ImagePickSource source) async {
    try {
      final result = await _channel.invokeMethod<Object?>(
        'pickImage',
        <String, Object?>{
          'source': source.name,
          'maxBytes': ImageSecurityValidator.maxImageBytes,
        },
      );
      if (result == null) {
        return null;
      }
      if (result is Uint8List) {
        return RawPickedImage(bytes: result);
      }
      if (result is Map<Object?, Object?>) {
        final rawBytes = result['bytes'];
        if (rawBytes is Uint8List) {
          return RawPickedImage(bytes: rawBytes);
        }
      }
      throw const MediaInvalidImageFailure(MediaValidationReason.emptyFile);
    } on PlatformException catch (error) {
      return switch (error.code) {
        'FILE_TOO_LARGE' => throw const MediaInvalidImageFailure(
          MediaValidationReason.fileTooLarge,
        ),
        'EMPTY_FILE' || 'INVALID_IMAGE' => throw const MediaInvalidImageFailure(
          MediaValidationReason.emptyFile,
        ),
        'PERMISSION_DENIED' ||
        'CAMERA_UNAVAILABLE' => throw const MediaPickerPermissionFailure(),
        _ => throw const MediaUnexpectedFailure(),
      };
    } on MissingPluginException {
      throw const MediaNotConfiguredFailure();
    }
  }
}

final deviceImagePickerAdapterProvider = Provider<ImagePickerPort>((ref) {
  return const DeviceImagePickerAdapter();
});
