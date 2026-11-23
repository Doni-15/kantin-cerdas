enum CatalogKind {
  stalls('stalls', 'Stan'),
  menu('menu', 'Menu');

  const CatalogKind(this.path, this.label);
  final String path;
  final String label;
}

typedef CatalogPage = ({List<CatalogItem> items, String? nextCursor});

sealed class CatalogItem {
  CatalogItem.fromJson(Map<String, dynamic> json)
    : id = readCatalogId(json['id']),
      name = json['name'] as String,
      block = json['block'] as String,
      description = json['description'] as String,
      waitMinutes = json['wait_minutes'] as int;

  final String id;
  final String name;
  final String block;
  final String description;
  final int waitMinutes;
}

final class CatalogStall extends CatalogItem {
  CatalogStall.fromJson(super.json)
    : isOpen = json['is_open'] as bool,
      super.fromJson();

  final bool isOpen;
}

final class CatalogMenuItem extends CatalogItem {
  CatalogMenuItem.fromJson(super.json)
    : stallId = readCatalogId(json['stall_id']),
      stallName = json['stall_name'] as String,
      category = json['category'] as String,
      price = json['price'] as int,
      isAvailable = json['is_available'] as bool,
      stallIsOpen = json['stall_is_open'] as bool,
      super.fromJson();

  final String stallId;
  final String stallName;
  final String category;
  final int price;
  final bool isAvailable;
  final bool stallIsOpen;
}

final _uuid = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

String readCatalogId(Object? value) {
  if (value is String && _uuid.hasMatch(value)) return value;
  throw const FormatException('Invalid catalog ID');
}
