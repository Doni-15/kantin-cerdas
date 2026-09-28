import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_nav_item.dart';

enum OwnerTab {
  dashboard,
  canteen,
  orders,
  profile,
}

class OwnerBottomNavigation extends StatelessWidget {
  const OwnerBottomNavigation({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final OwnerTab currentTab;
  final ValueChanged<OwnerTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            Expanded(
              child: KcNavItem(
                icon: Icons.dashboard_outlined,
                selectedIcon: Icons.dashboard,
                label: 'Dashboard',
                isSelected: currentTab == OwnerTab.dashboard,
                onTap: () => onTabSelected(OwnerTab.dashboard),
              ),
            ),

            Expanded(
              child: KcNavItem(
                icon: Icons.store_outlined,
                selectedIcon: Icons.store,
                label: 'Kantin',
                isSelected: currentTab == OwnerTab.canteen,
                onTap: () => onTabSelected(OwnerTab.canteen),
              ),
            ),

            Expanded(
              child: KcNavItem(
                icon: Icons.receipt_long_outlined,
                selectedIcon: Icons.receipt_long,
                label: 'Pesanan',
                isSelected: currentTab == OwnerTab.orders,
                onTap: () => onTabSelected(OwnerTab.orders),
              ),
            ),

            Expanded(
              child: KcNavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'Profil',
                isSelected: currentTab == OwnerTab.profile,
                onTap: () => onTabSelected(OwnerTab.profile),
              ),
            ),
            
          ],
        ),
      ),
    );
  }
}