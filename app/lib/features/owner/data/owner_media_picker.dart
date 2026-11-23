import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';

export 'package:kantin_cerdas/features/owner/domain/owner_models.dart'
    show OwnerPhotoPicker, PickedOwnerPhoto;

const _maxMediaBytes = 2 * 1024 * 1024;

Future<PickedOwnerPhoto?> pickOwnerPhotoFromDevice() async {
  const typeGroup = XTypeGroup(
    label: 'Foto kantin atau menu',
    extensions: ['jpg', 'jpeg', 'png', 'webp'],
    mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
    uniformTypeIdentifiers: [
      'public.jpeg',
      'public.png',
      'org.webmproject.webp',
    ],
  );
  try {
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return null;
    if (await file.length() > _maxMediaBytes) throw _tooLarge;
    final builder = BytesBuilder(copy: false);
    await for (final chunk in file.openRead()) {
      if (builder.length + chunk.length > _maxMediaBytes) throw _tooLarge;
      builder.add(chunk);
    }
    final bytes = builder.takeBytes();
    final mediaType = _detectImageType(bytes);
    if (mediaType == null) {
      throw const AuthException(
        'INVALID_MEDIA_PHOTO',
        'Gunakan foto JPEG, PNG, atau WebP.',
      );
    }
    return PickedOwnerPhoto(
      name: file.name,
      bytes: bytes,
      mediaType: mediaType,
    );
  } on AuthException {
    rethrow;
  } catch (_) {
    throw const AuthException(
      'PHOTO_PICK_FAILED',
      'Foto tidak dapat dibuka. Pilih foto lain.',
    );
  }
}

String? _detectImageType(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xff &&
      bytes[1] == 0xd8 &&
      bytes[2] == 0xff) {
    return 'image/jpeg';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      String.fromCharCodes(bytes.take(8).skip(1)) == 'PNG\r\n\x1a\n') {
    return 'image/png';
  }
  if (bytes.length >= 12 &&
      String.fromCharCodes(bytes.take(4)) == 'RIFF' &&
      String.fromCharCodes(bytes.take(12).skip(8)) == 'WEBP') {
    return 'image/webp';
  }
  return null;
}

const _tooLarge = AuthException(
  'PHOTO_TOO_LARGE',
  'Ukuran foto maksimal 2 MB.',
);
