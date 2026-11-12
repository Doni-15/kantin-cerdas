import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';
import 'package:kantin_cerdas/features/customer/data/models/menu_item_model.dart';

/// Representasi data stan sebelum dipetakan menjadi entity domain.
class StallModel {
  StallModel({
    required this.id,
    required this.name,
    required this.block,
    required this.waitTime,
    required this.description,
    required List<MenuItemModel> menus,
    required this.isOpen,
    this.imageUrl,
  }) : menus = List<MenuItemModel>.unmodifiable(menus);

  factory StallModel.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final name = json['name'];
    final block = json['block'] ?? '';
    final rawWaitTime = json['wait_time'] ?? json['waitTime'];
    final rawPrepMin = json['prep_time_min'] ?? json['prepTimeMin'];
    final String waitTime;
    if (rawWaitTime is String && rawWaitTime.trim().isNotEmpty) {
      waitTime = rawWaitTime;
    } else if (rawPrepMin is int && rawPrepMin > 0) {
      waitTime = '$rawPrepMin mnt';
    } else if (rawWaitTime is String) {
      waitTime = rawWaitTime;
    } else if (rawWaitTime == null && rawPrepMin == null) {
      waitTime = '';
    } else {
      throw const DataParsingException('Format data stan katalog tidak valid.');
    }

    final description = json['description'] ?? '';
    final rawMenus = json['menus'];
    final isOpen = json['is_open'] ?? json['isOpen'];
    final imageUrl = normalizeOptionalText(
      json['image_url'] ?? json['imageUrl'],
      fieldName: 'image_url',
    );

    if (id is! String ||
        name is! String ||
        block is! String ||
        description is! String ||
        rawMenus is! List<Object?> ||
        isOpen is! bool) {
      throw const DataParsingException('Format data stan katalog tidak valid.');
    }

    final menus = <MenuItemModel>[];
    for (final raw in rawMenus) {
      menus.add(MenuItemModel.fromJson(asJsonMap(raw, fieldName: 'menus')));
    }

    return StallModel(
      id: id,
      name: name,
      block: block,
      waitTime: waitTime,
      description: description,
      menus: menus,
      isOpen: isOpen,
      imageUrl: imageUrl,
    );
  }

  final String id;
  final String name;
  final String block;
  final String waitTime;
  final String description;

  /// Salinan daftar model menu yang tidak dapat diubah.
  final List<MenuItemModel> menus;

  /// Status buka yang diberikan oleh sumber data.
  final bool isOpen;

  final String? imageUrl;
}
