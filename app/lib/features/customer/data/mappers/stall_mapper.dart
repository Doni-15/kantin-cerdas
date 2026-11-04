import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/media/image_security_validator.dart';
import 'package:kantin_cerdas/features/customer/data/mappers/menu_item_mapper.dart';
import 'package:kantin_cerdas/features/customer/data/models/stall_model.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/stall.dart';

/// Memvalidasi data stan beserta relasi menunya sebelum digunakan domain.
extension StallModelMapper on StallModel {
  Stall toEntity() {
    if (id.trim().isEmpty || name.trim().isEmpty) {
      throw const DataParsingException('Identitas stan wajib terisi.');
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

    final menuIds = <String>{};

    final mappedMenus = menus
        .map((menu) {
          if (menu.stallId != id) {
            throw const DataParsingException(
              'Menu tidak sesuai dengan stan induknya.',
            );
          }

          if (!menuIds.add(menu.id)) {
            throw const DataParsingException(
              'ID menu dalam satu stan tidak boleh duplikat.',
            );
          }

          return menu.toEntity();
        })
        .toList(growable: false);

    return Stall(
      id: id,
      name: name,
      block: block,
      waitTime: waitTime,
      description: description,
      menus: mappedMenus,
      isOpen: isOpen,
      imageUrl: safeImageUrl,
    );
  }
}
