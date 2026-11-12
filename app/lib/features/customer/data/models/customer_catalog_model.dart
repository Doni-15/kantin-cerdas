import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';
import 'package:kantin_cerdas/features/customer/data/models/menu_item_model.dart';
import 'package:kantin_cerdas/features/customer/data/models/stall_model.dart';

/// Representasi data katalog sebelum dipetakan menjadi entity domain.
class CustomerCatalogModel {
  CustomerCatalogModel({
    required List<MenuItemModel> menus,
    required List<StallModel> stalls,
  }) : menus = List<MenuItemModel>.unmodifiable(menus),
       stalls = List<StallModel>.unmodifiable(stalls);

  factory CustomerCatalogModel.fromJson(Map<String, Object?> json) {
    final rawMenus = json['menus'];
    final rawStalls = json['stalls'];
    if (rawMenus is! List<Object?> || rawStalls is! List<Object?>) {
      throw const DataParsingException(
        'Payload katalog harus memuat menus dan stalls.',
      );
    }
    final menus = <MenuItemModel>[];
    for (final raw in rawMenus) {
      menus.add(MenuItemModel.fromJson(asJsonMap(raw, fieldName: 'menus')));
    }
    final stalls = <StallModel>[];
    for (final raw in rawStalls) {
      stalls.add(StallModel.fromJson(asJsonMap(raw, fieldName: 'stalls')));
    }
    return CustomerCatalogModel(menus: menus, stalls: stalls);
  }

  final List<MenuItemModel> menus;
  final List<StallModel> stalls;
}
