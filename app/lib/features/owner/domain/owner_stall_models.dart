import 'dart:typed_data';

class OwnerScheduleDay {
  const OwnerScheduleDay({
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

  factory OwnerScheduleDay.fromJson(Map<String, dynamic> json) =>
      OwnerScheduleDay(
        dayOfWeek: json['day_of_week'] as int,
        isOpenDay: json['is_open_day'] == true,
        openTime: json['open_time'] as String?,
        closeTime: json['close_time'] as String?,
      );

  Map<String, Object?> toJson() => {
    'day_of_week': dayOfWeek,
    'is_open_day': isOpenDay,
    'open_time': isOpenDay ? openTime : null,
    'close_time': isOpenDay ? closeTime : null,
  };
}

class OwnerPublishEligibility {
  const OwnerPublishEligibility({
    required this.canPublish,
    required this.missingProfileFields,
    required this.availableMenuCount,
  });

  final bool canPublish;
  final List<String> missingProfileFields;
  final int availableMenuCount;

  factory OwnerPublishEligibility.fromJson(Map<String, dynamic> json) =>
      OwnerPublishEligibility(
        canPublish: json['can_publish'] == true,
        missingProfileFields: List<String>.unmodifiable(
          (json['missing_profile_fields'] as List<dynamic>? ?? const [])
              .cast<String>(),
        ),
        availableMenuCount: json['available_menu_count'] as int? ?? 0,
      );
}

class OwnerStall {
  const OwnerStall({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.campus,
    required this.block,
    required this.description,
    required this.waitMinutes,
    required this.isListed,
    required this.isOpen,
    required this.hasPhoto,
  });

  final String id;
  final String ownerId;
  final String name;
  final String campus;
  final String block;
  final String description;
  final int waitMinutes;
  final bool isListed;
  final bool isOpen;
  final bool hasPhoto;

  factory OwnerStall.fromJson(Map<String, dynamic> json) => OwnerStall(
    id: json['id'] as String,
    ownerId: json['owner_id'] as String,
    name: json['name'] as String,
    campus: json['campus'] as String? ?? '',
    block: json['block'] as String,
    description: json['description'] as String? ?? '',
    waitMinutes: json['wait_minutes'] as int? ?? 0,
    isListed: json['is_listed'] == true,
    isOpen: json['is_open'] == true,
    hasPhoto: json['has_photo'] == true,
  );
}

class OwnerStallBundle {
  const OwnerStallBundle({
    required this.stall,
    required this.schedules,
    required this.publishEligibility,
  });

  final OwnerStall? stall;
  final List<OwnerScheduleDay> schedules;
  final OwnerPublishEligibility publishEligibility;

  factory OwnerStallBundle.fromJson(Map<String, dynamic> json) {
    final rawStall = json['stall'];
    final rawSchedules = json['schedules'] as List<dynamic>? ?? const [];
    final rawEligibility =
        json['publish_eligibility'] as Map<String, dynamic>? ?? const {};
    return OwnerStallBundle(
      stall: rawStall is Map<String, dynamic>
          ? OwnerStall.fromJson(rawStall)
          : null,
      schedules: List<OwnerScheduleDay>.unmodifiable([
        for (final item in rawSchedules)
          OwnerScheduleDay.fromJson(item as Map<String, dynamic>),
      ]),
      publishEligibility: OwnerPublishEligibility.fromJson(rawEligibility),
    );
  }
}

class OwnerCategory {
  const OwnerCategory({
    required this.id,
    required this.stallId,
    required this.name,
    required this.sortOrder,
    required this.activeMenuCount,
    required this.archivedMenuCount,
    required this.totalMenuCount,
    required this.canDelete,
  });

  final String id;
  final String stallId;
  final String name;
  final int sortOrder;
  final int activeMenuCount;
  final int archivedMenuCount;
  final int totalMenuCount;
  final bool canDelete;

  factory OwnerCategory.fromJson(Map<String, dynamic> json) => OwnerCategory(
    id: json['id'] as String,
    stallId: json['stall_id'] as String,
    name: json['name'] as String,
    sortOrder: json['sort_order'] as int? ?? 0,
    activeMenuCount: json['active_menu_count'] as int? ?? 0,
    archivedMenuCount: json['archived_menu_count'] as int? ?? 0,
    totalMenuCount: json['total_menu_count'] as int? ?? 0,
    canDelete: json['can_delete'] == true,
  );
}

class OwnerMenuItem {
  const OwnerMenuItem({
    required this.id,
    required this.stallId,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.description,
    required this.price,
    required this.isAvailable,
    required this.isArchived,
    required this.hasPhoto,
  });

  final String id;
  final String stallId;
  final String? categoryId;
  final String categoryName;
  final String name;
  final String description;
  final int price;
  final bool isAvailable;
  final bool isArchived;
  final bool hasPhoto;

  factory OwnerMenuItem.fromJson(Map<String, dynamic> json) => OwnerMenuItem(
    id: json['id'] as String,
    stallId: json['stall_id'] as String,
    categoryId: json['category_id'] as String?,
    categoryName: json['category_name'] as String,
    name: json['name'] as String,
    description: json['description'] as String? ?? '',
    price: json['price'] as int,
    isAvailable: json['is_available'] == true,
    isArchived: json['is_archived'] == true,
    hasPhoto: json['has_photo'] == true,
  );
}

class PickedOwnerPhoto {
  const PickedOwnerPhoto({
    required this.name,
    required this.bytes,
    required this.mediaType,
  });

  final String name;
  final Uint8List bytes;
  final String mediaType;
}

typedef OwnerPhotoPicker = Future<PickedOwnerPhoto?> Function();
