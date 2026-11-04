import 'package:characters/characters.dart';
import 'package:kantin_cerdas/core/media/image_security_validator.dart';
import 'package:kantin_cerdas/core/utils/collection_equality.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/menu_category.dart';

export 'package:kantin_cerdas/features/orders/domain/entities/menu_category.dart';

class OwnerMenu {
  OwnerMenu({
    required this.id,
    required this.stallId,
    required this.name,
    required this.description,
    required this.category,
    required this.priceIdr,
    required this.isAvailable,
    required this.version,
    String? imageUrl,
  }) : imageUrl = _validateOptionalImageUrl(imageUrl) {
    if (id.trim().isEmpty ||
        stallId.trim().isEmpty ||
        name.trim().isEmpty ||
        priceIdr < 1 ||
        priceIdr > 10000000 ||
        version < 1) {
      throw ArgumentError('Menu tidak valid.');
    }
  }
  final String id;
  final String stallId;
  final String name;
  final String description;
  final MenuCategory category;
  final int priceIdr;
  final bool isAvailable;
  final int version;
  final String? imageUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OwnerMenu &&
          other.id == id &&
          other.stallId == stallId &&
          other.name == name &&
          other.description == description &&
          other.category == category &&
          other.priceIdr == priceIdr &&
          other.isAvailable == isAvailable &&
          other.version == version &&
          other.imageUrl == imageUrl);

  @override
  int get hashCode => Object.hash(
    id,
    stallId,
    name,
    description,
    category,
    priceIdr,
    isAvailable,
    version,
    imageUrl,
  );
}

class OwnerMenuInput {
  OwnerMenuInput({
    this.id,
    required this.stallId,
    required String name,
    required String description,
    required this.category,
    required this.priceIdr,
    required this.isAvailable,
    this.expectedVersion,
    String? imageUrl,
  }) : name = name.trim(),
       description = description.trim(),
       imageUrl = _validateOptionalImageUrl(imageUrl) {
    if (stallId.trim().isEmpty ||
        this.name.isEmpty ||
        this.name.characters.length > 120 ||
        this.description.characters.length > 1000 ||
        priceIdr < 1 ||
        priceIdr > 10000000 ||
        (id == null) != (expectedVersion == null) ||
        (id != null && id!.trim().isEmpty) ||
        (expectedVersion != null && expectedVersion! < 1)) {
      throw ArgumentError('Isian menu tidak valid.');
    }
  }

  /// Sukses wajib mencerminkan seluruh isian dan versi hasil penyimpanan.
  bool acceptsResult(OwnerMenu saved) =>
      saved.stallId == stallId &&
      (id == null
          ? saved.version >= 1
          : saved.id == id && saved.version > expectedVersion!) &&
      saved.name == name &&
      saved.description == description &&
      saved.category == category &&
      saved.priceIdr == priceIdr &&
      saved.isAvailable == isAvailable &&
      saved.imageUrl == imageUrl;

  final String? id;
  final String stallId;
  final String name;
  final String description;
  final MenuCategory category;
  final int priceIdr;
  final bool isAvailable;
  final int? expectedVersion;
  final String? imageUrl;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OwnerMenuInput &&
          other.id == id &&
          other.stallId == stallId &&
          other.name == name &&
          other.description == description &&
          other.category == category &&
          other.priceIdr == priceIdr &&
          other.isAvailable == isAvailable &&
          other.expectedVersion == expectedVersion &&
          other.imageUrl == imageUrl);

  @override
  int get hashCode => Object.hash(
    id,
    stallId,
    name,
    description,
    category,
    priceIdr,
    isAvailable,
    expectedVersion,
    imageUrl,
  );
}

class OwnerMenuPage {
  OwnerMenuPage({required List<OwnerMenu> items, this.nextCursor})
    : items = List.unmodifiable(items) {
    if (items.map((item) => item.id).toSet().length != items.length ||
        (nextCursor != null && nextCursor!.trim().isEmpty)) {
      throw ArgumentError('Halaman menu tidak valid.');
    }
  }
  final List<OwnerMenu> items;
  final String? nextCursor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OwnerMenuPage &&
          other.nextCursor == nextCursor &&
          listEquals(other.items, items));

  @override
  int get hashCode => Object.hash(nextCursor, Object.hashAll(items));
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
