import 'dart:typed_data';

final class ValidatedMediaUploadInput {
  final String mutationId;
  final String category;
  final String objectPath;
  final String mimeType;
  final Uint8List bytes;

  const ValidatedMediaUploadInput({
    required this.mutationId,
    required this.category,
    required this.objectPath,
    required this.mimeType,
    required this.bytes,
  });

  int get sizeBytes => bytes.length;
}
