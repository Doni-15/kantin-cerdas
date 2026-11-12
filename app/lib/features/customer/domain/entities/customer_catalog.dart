import 'package:kantin_cerdas/core/media/image_security_validator.dart';
import 'package:kantin_cerdas/core/utils/collection_equality.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/menu_item.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/stall.dart';
import 'package:kantin_cerdas/features/customer/domain/validation/customer_input_limits.dart';

/// Snapshot lengkap: daftar umum dan detail memakai objek menu yang sama.
/// Katalog bertentangan ditolak, bukan dipilih salah satunya.
class CustomerCatalog {
  factory CustomerCatalog({
    required List<MenuItem> menus,
    required List<Stall> stalls,
  }) {
    final stallIndex = <String, Stall>{};
    for (final stall in stalls) {
      if (stall.id.trim().isEmpty ||
          stall.name.trim().isEmpty ||
          stallIndex.containsKey(stall.id)) {
        throw const FormatException('Identitas stan kosong atau duplikat.');
      }
      ImageSecurityValidator.normalizeSafeImageUrl(
        stall.imageUrl,
        fieldName: 'image_url',
      );
      stallIndex[stall.id] = stall;
    }
    final menuIndex = <String, MenuItem>{};
    for (final menu in menus) {
      final stall = stallIndex[menu.stallId];
      if (menu.id.trim().isEmpty ||
          menu.name.trim().isEmpty ||
          menuIndex.containsKey(menu.id) ||
          stall == null ||
          menu.stallName != stall.name ||
          menu.block != stall.block ||
          !CustomerInputLimits.validPrice(menu.price)) {
        throw const FormatException(
          'Identitas, harga, atau relasi menu tidak valid.',
        );
      }
      final safeMenuImageUrl = ImageSecurityValidator.normalizeSafeImageUrl(
        menu.imageUrl,
        fieldName: 'image_url',
      );
      menuIndex[menu.id] = safeMenuImageUrl == menu.imageUrl
          ? menu
          : MenuItem(
              id: menu.id,
              name: menu.name,
              stallId: menu.stallId,
              stallName: menu.stallName,
              block: menu.block,
              price: menu.price,
              waitTime: menu.waitTime,
              description: menu.description,
              category: menu.category,
              available: menu.available,
              imageUrl: safeMenuImageUrl,
            );
    }
    final nestedIds = <String>{};
    final canonicalStalls = <Stall>[];
    for (final stall in stalls) {
      final safeStallImageUrl = ImageSecurityValidator.normalizeSafeImageUrl(
        stall.imageUrl,
        fieldName: 'image_url',
      );
      final canonicalMenus = <MenuItem>[];
      for (final nested in stall.menus) {
        final safeNestedImageUrl = ImageSecurityValidator.normalizeSafeImageUrl(
          nested.imageUrl,
          fieldName: 'image_url',
        );
        final normalizedNested = safeNestedImageUrl == nested.imageUrl
            ? nested
            : MenuItem(
                id: nested.id,
                name: nested.name,
                stallId: nested.stallId,
                stallName: nested.stallName,
                block: nested.block,
                price: nested.price,
                waitTime: nested.waitTime,
                description: nested.description,
                category: nested.category,
                available: nested.available,
                imageUrl: safeNestedImageUrl,
              );
        final menu = menuIndex[nested.id];
        if (menu == null ||
            nested.stallId != stall.id ||
            !nestedIds.add(nested.id) ||
            menu != normalizedNested) {
          throw const FormatException(
            'Menu detail berbeda dari daftar katalog.',
          );
        }
        canonicalMenus.add(menu);
      }
      canonicalStalls.add(
        Stall(
          id: stall.id,
          name: stall.name,
          block: stall.block,
          waitTime: stall.waitTime,
          description: stall.description,
          menus: canonicalMenus,
          isOpen: stall.isOpen,
          imageUrl: safeStallImageUrl,
        ),
      );
    }
    if (nestedIds.length != menuIndex.length) {
      throw const FormatException(
        'Menu katalog tidak lengkap pada detail stan.',
      );
    }
    return CustomerCatalog._(menuIndex, canonicalStalls);
  }
  CustomerCatalog._(
    Map<String, MenuItem> menuIndex,
    List<Stall> canonicalStalls,
  ) : menus = List.unmodifiable(menuIndex.values),
      stalls = List.unmodifiable(canonicalStalls),
      _menusById = Map.unmodifiable(menuIndex),
      _stallsById = Map.unmodifiable({
        for (final stall in canonicalStalls) stall.id: stall,
      });
  final List<MenuItem> menus;
  final List<Stall> stalls;
  final Map<String, MenuItem> _menusById;
  final Map<String, Stall> _stallsById;
  MenuItem? menuById(String id) => _menusById[id];
  Stall? stallById(String id) => _stallsById[id];
  bool canOrder(String menuId) {
    final menu = menuById(menuId);
    return menu != null &&
        menu.available &&
        _stallsById[menu.stallId]?.isOpen == true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomerCatalog &&
          listEquals(other.menus, menus) &&
          listEquals(other.stalls, stalls));

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(menus), Object.hashAll(stalls));
}
