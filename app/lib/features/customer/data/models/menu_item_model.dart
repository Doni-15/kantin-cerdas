import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';

/// Representasi data menu sebelum dipetakan menjadi entity domain.
class MenuItemModel {
  const MenuItemModel({
    required this.id,
    required this.name,
    required this.stallId,
    required this.stallName,
    required this.block,
    required this.price,
    required this.waitTime,
    required this.description,
    required this.category,
    required this.available,
    this.imageUrl,
  });

  factory MenuItemModel.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final name = json['name'];
    final stallId = json['stall_id'] ?? json['stallId'];
    final stallName = json['stall_name'] ?? json['stallName'];
    final block = json['block'] ?? '';
    final price = json['price_idr'] ?? json['priceIdr'] ?? json['price'];
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
      throw const DataParsingException('Format data menu katalog tidak valid.');
    }

    final description = json['description'] ?? '';
    final category = json['category'] ?? '';
    final available =
        json['is_available'] ?? json['isAvailable'] ?? json['available'];
    final imageUrl = normalizeOptionalText(
      json['image_url'] ?? json['imageUrl'],
      fieldName: 'image_url',
    );

    if (id is! String ||
        name is! String ||
        stallId is! String ||
        stallName is! String ||
        block is! String ||
        price is! int ||
        description is! String ||
        category is! String ||
        available is! bool) {
      throw const DataParsingException('Format data menu katalog tidak valid.');
    }

    return MenuItemModel(
      id: id,
      name: name,
      stallId: stallId,
      stallName: stallName,
      block: block,
      price: price,
      waitTime: waitTime,
      description: description,
      category: category,
      available: available,
      imageUrl: imageUrl,
    );
  }

  final String id;
  final String name;
  final String stallId;
  final String stallName;
  final String block;

  /// Harga yang sudah dinormalisasi menjadi rupiah utuh oleh lapisan data.
  final int price;

  final String waitTime;
  final String description;
  final String category;
  final bool available;
  final String? imageUrl;
}
