import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/media/image_security_validator.dart';
import 'package:kantin_cerdas/features/customer/data/models/menu_item_model.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/menu_item.dart';
import 'package:kantin_cerdas/features/customer/domain/validation/customer_input_limits.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/menu_category.dart';

/// Memvalidasi data menu sebelum digunakan oleh domain.
extension MenuItemModelMapper on MenuItemModel {
  MenuItem toEntity() {
    if (id.trim().isEmpty ||
        name.trim().isEmpty ||
        stallId.trim().isEmpty ||
        stallName.trim().isEmpty) {
      throw const DataParsingException('Identitas menu dan stan wajib terisi.');
    }

    if (!CustomerInputLimits.validPrice(price)) {
      throw const DataParsingException(
        'Harga menu harus 1 sampai 10.000.000 rupiah.',
      );
    }

    final String? safeImageUrl;
    try {
      safeImageUrl = ImageSecurityValidator.normalizeSafeImageUrl(
        imageUrl,
        fieldName: 'image_url',
      );
    } on FormatException catch (error) {
      throw DataParsingException(error.message);
    }

    return MenuItem(
      id: id,
      name: name,
      stallId: stallId,
      stallName: stallName,
      block: block,
      price: price,
      waitTime: waitTime,
      description: description,
      category: MenuCategory.normalizeLabel(category),
      available: available,
      imageUrl: safeImageUrl,
    );
  }
}
