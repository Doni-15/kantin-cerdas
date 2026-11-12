import 'package:characters/characters.dart';
import 'package:kantin_cerdas/core/media/image_security_validator.dart';

class OwnerStall {
  OwnerStall({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.block,
    required this.description,
    required this.isOpen,
    required this.prepTimeMin,
    required this.version,
    String? imageUrl,
  }) : imageUrl = _validateOptionalImageUrl(imageUrl) {
    if (id.trim().isEmpty ||
        ownerId.trim().isEmpty ||
        name.trim().isEmpty ||
        prepTimeMin < 1 ||
        prepTimeMin > 180 ||
        version < 1) {
      throw ArgumentError('Data stan tidak valid.');
    }
  }
  final String id;
  final String ownerId;
  final String name;
  final String block;
  final String description;
  final bool isOpen;
  final int prepTimeMin;
  final int version;
  final String? imageUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OwnerStall &&
          other.id == id &&
          other.ownerId == ownerId &&
          other.name == name &&
          other.block == block &&
          other.description == description &&
          other.isOpen == isOpen &&
          other.prepTimeMin == prepTimeMin &&
          other.version == version &&
          other.imageUrl == imageUrl);

  @override
  int get hashCode => Object.hash(
    id,
    ownerId,
    name,
    block,
    description,
    isOpen,
    prepTimeMin,
    version,
    imageUrl,
  );
}

class OwnerStallInput {
  OwnerStallInput({
    required this.id,
    required String name,
    required String block,
    required String description,
    required this.isOpen,
    required this.prepTimeMin,
    required this.expectedVersion,
    String? imageUrl,
  }) : name = name.trim(),
       block = block.trim(),
       description = description.trim(),
       imageUrl = _validateOptionalImageUrl(imageUrl) {
    if (id.trim().isEmpty ||
        this.name.isEmpty ||
        this.name.characters.length > 120 ||
        this.block.isEmpty ||
        this.block.characters.length > 120 ||
        this.description.characters.length > 1000 ||
        prepTimeMin < 1 ||
        prepTimeMin > 180 ||
        expectedVersion < 1) {
      throw ArgumentError('Isian stan tidak valid.');
    }
  }
  final String id;
  final String name;
  final String block;
  final String description;
  final bool isOpen;
  final int prepTimeMin;
  final String? imageUrl;

  /// Identitas pemilik tidak boleh berubah akibat penyimpanan form.
  bool acceptsResult(OwnerStall saved, {required String ownerId}) =>
      saved.id == id &&
      saved.ownerId == ownerId &&
      saved.version > expectedVersion &&
      saved.name == name &&
      saved.block == block &&
      saved.description == description &&
      saved.isOpen == isOpen &&
      saved.prepTimeMin == prepTimeMin &&
      saved.imageUrl == imageUrl;

  final int expectedVersion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OwnerStallInput &&
          other.id == id &&
          other.name == name &&
          other.block == block &&
          other.description == description &&
          other.isOpen == isOpen &&
          other.prepTimeMin == prepTimeMin &&
          other.expectedVersion == expectedVersion &&
          other.imageUrl == imageUrl);

  @override
  int get hashCode => Object.hash(
    id,
    name,
    block,
    description,
    isOpen,
    prepTimeMin,
    expectedVersion,
    imageUrl,
  );
}

String? _validateOptionalImageUrl(String? rawUrl) {
  try {
    return ImageSecurityValidator.normalizeSafeImageUrl(
      rawUrl,
      fieldName: 'image_url',
    );
  } on FormatException catch (error) {
    throw ArgumentError(error.message);
  }
}
