import 'package:kantin_cerdas/features/catalog/domain/catalog_models.dart';

class CustomerScheduleDay {
  const CustomerScheduleDay({
    required this.dayOfWeek,
    required this.isOpenDay,
    this.openTime,
    this.closeTime,
  });

  final int dayOfWeek;
  final bool isOpenDay;
  final String? openTime;
  final String? closeTime;

  String get dayLabel => switch (dayOfWeek) {
    1 => 'Senin',
    2 => 'Selasa',
    3 => 'Rabu',
    4 => 'Kamis',
    5 => 'Jumat',
    6 => 'Sabtu',
    7 => 'Minggu',
    _ => 'Hari $dayOfWeek',
  };

  factory CustomerScheduleDay.fromJson(Map<String, dynamic> json) =>
      CustomerScheduleDay(
        dayOfWeek: json['day_of_week'] as int,
        isOpenDay: json['is_open_day'] == true,
        openTime: json['open_time'] as String?,
        closeTime: json['close_time'] as String?,
      );
}

class CustomerCategory {
  const CustomerCategory({
    required this.id,
    required this.name,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final int sortOrder;

  factory CustomerCategory.fromJson(Map<String, dynamic> json) =>
      CustomerCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        sortOrder: json['sort_order'] as int? ?? 0,
      );
}

class CustomerStallSummary {
  const CustomerStallSummary({
    required this.id,
    required this.name,
    required this.block,
    required this.description,
    required this.waitMinutes,
    required this.isListed,
    required this.isOpen,
    required this.ownerActive,
    required this.hasPhoto,
  });

  final String id;
  final String name;
  final String block;
  final String description;
  final int waitMinutes;
  final bool isListed;
  final bool isOpen;
  final bool ownerActive;
  final bool hasPhoto;

  bool get canAcceptOrders => isListed && isOpen && ownerActive;

  factory CustomerStallSummary.fromCatalogStall(CatalogStall stall) =>
      CustomerStallSummary(
        id: stall.id,
        name: stall.name,
        block: stall.block,
        description: stall.description,
        waitMinutes: stall.waitMinutes,
        isListed: true,
        isOpen: stall.isOpen,
        ownerActive: true,
        hasPhoto: false,
      );

  factory CustomerStallSummary.fromJson(Map<String, dynamic> json) =>
      CustomerStallSummary(
        id: json['id'] as String,
        name: json['name'] as String,
        block: json['block'] as String,
        description: json['description'] as String? ?? '',
        waitMinutes: json['wait_minutes'] as int? ?? 0,
        isListed: json['is_listed'] != false,
        isOpen: json['is_open'] == true,
        ownerActive: json['owner_active'] != false,
        hasPhoto: json['has_photo'] == true,
      );
}

class CustomerMenuSummary {
  const CustomerMenuSummary({
    required this.id,
    required this.stallId,
    required this.categoryName,
    required this.name,
    required this.description,
    required this.price,
    required this.isAvailable,
    required this.hasPhoto,
    this.categoryId,
  });

  final String id;
  final String stallId;
  final String? categoryId;
  final String categoryName;
  final String name;
  final String description;
  final int price;
  final bool isAvailable;
  final bool hasPhoto;

  factory CustomerMenuSummary.fromJson(Map<String, dynamic> json) =>
      CustomerMenuSummary(
        id: json['id'] as String,
        stallId: json['stall_id'] as String,
        categoryId: json['category_id'] as String?,
        categoryName:
            json['category_name'] as String? ??
            json['category'] as String? ??
            '',
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        price: json['price'] as int,
        isAvailable: json['is_available'] == true,
        hasPhoto: json['has_photo'] == true,
      );
}

class CustomerStallDetailBundle {
  const CustomerStallDetailBundle({
    required this.stall,
    required this.schedules,
    required this.categories,
    required this.menus,
  });

  final CustomerStallSummary stall;
  final List<CustomerScheduleDay> schedules;
  final List<CustomerCategory> categories;
  final List<CustomerMenuSummary> menus;

  factory CustomerStallDetailBundle.fromJson(Map<String, dynamic> json) =>
      CustomerStallDetailBundle(
        stall: CustomerStallSummary.fromJson(
          json['stall'] as Map<String, dynamic>,
        ),
        schedules: List<CustomerScheduleDay>.unmodifiable([
          for (final item in json['schedules'] as List<dynamic>? ?? const [])
            CustomerScheduleDay.fromJson(item as Map<String, dynamic>),
        ]),
        categories: List<CustomerCategory>.unmodifiable([
          for (final item in json['categories'] as List<dynamic>? ?? const [])
            CustomerCategory.fromJson(item as Map<String, dynamic>),
        ]),
        menus: List<CustomerMenuSummary>.unmodifiable([
          for (final item in json['menus'] as List<dynamic>? ?? const [])
            CustomerMenuSummary.fromJson(item as Map<String, dynamic>),
        ]),
      );
}

class CustomerMenuDetailBundle {
  const CustomerMenuDetailBundle({required this.menu, required this.stall});

  final CustomerMenuSummary menu;
  final CustomerStallSummary stall;

  factory CustomerMenuDetailBundle.fromJson(
    Map<String, dynamic> json,
  ) => CustomerMenuDetailBundle(
    menu: CustomerMenuSummary.fromJson(json['menu'] as Map<String, dynamic>),
    stall: CustomerStallSummary.fromJson(json['stall'] as Map<String, dynamic>),
  );
}
