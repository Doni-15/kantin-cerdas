import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_nav_item.dart';

enum CustomerTab {
  home,
  orders,
  ai,
  history,
  profile,
}

class CustomerBottomNavigation extends StatelessWidget {
  const CustomerBottomNavigation({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final CustomerTab currentTab;
  final ValueChanged<CustomerTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            Expanded(
              child: KcNavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Home',
                isSelected: currentTab == CustomerTab.home,
                onTap: () => onTabSelected(CustomerTab.home),
              ),
            ),

            Expanded(
              child: KcNavItem(
                icon: Icons.receipt_long_outlined,
                selectedIcon: Icons.receipt_long,
                label: 'Pesanan',
                isSelected: currentTab == CustomerTab.orders,
                onTap: () => onTabSelected(CustomerTab.orders),
              ),
            ),

            const SizedBox(width: 72),

            Expanded(
              child: KcNavItem(
                icon: Icons.history_outlined,
                selectedIcon: Icons.history,
                label: 'Riwayat',
                isSelected: currentTab == CustomerTab.history,
                onTap: () => onTabSelected(CustomerTab.history),
              ),
            ),
            
            Expanded(
              child: KcNavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'Profil',
                isSelected: currentTab == CustomerTab.profile,
                onTap: () => onTabSelected(CustomerTab.profile),
              ),
            ),
          ],
        ),
      ),
    );
  }
}