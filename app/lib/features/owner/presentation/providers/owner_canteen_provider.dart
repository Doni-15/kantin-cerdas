import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kantin_cerdas/features/owner/data/datasources/owner_canteen_dummy_data.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_menu_item.dart';

final ownerCanteenProvider =
    NotifierProvider<OwnerCanteenController, OwnerCanteenState>(
  OwnerCanteenController.new,
);

class OwnerCanteenState {
  const OwnerCanteenState({
    required this.menus,
    this.isStallOpen = true,
    this.preparationTime = '5–10 menit',
  });

  final List<OwnerMenuItem> menus;

  final bool isStallOpen;

  final String preparationTime;

  OwnerCanteenState copyWith({
    List<OwnerMenuItem>? menus,
    bool? isStallOpen,
    String? preparationTime,
  }) {
    return OwnerCanteenState(
      menus: menus ?? this.menus,
      isStallOpen: isStallOpen ?? this.isStallOpen,
      preparationTime:
          preparationTime ?? this.preparationTime,
    );
  }
}

class OwnerCanteenController
    extends Notifier<OwnerCanteenState> {
  @override
  OwnerCanteenState build() {
    return const OwnerCanteenState(
      menus: OwnerCanteenDummyData.menus,
    );
  }

  void updateMenuAvailability(
    String menuId,
    bool available,
  ) {
    final updatedMenus = state.menus.map(
      (menu) {
        if (menu.id == menuId) {
          return menu.copyWith(
            available: available,
          );
        }

        return menu;
      },
    ).toList();

    state = state.copyWith(
      menus: updatedMenus,
    );
  }

  void updateStallStatus(bool isOpen) {
    state = state.copyWith(
      isStallOpen: isOpen,
    );
  }

  void updatePreparationTime(String time) {
    state = state.copyWith(
      preparationTime: time,
    );
  }
}