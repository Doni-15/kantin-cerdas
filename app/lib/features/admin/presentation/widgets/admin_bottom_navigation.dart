import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_nav_item.dart';

enum AdminTab {
  dashboard,
  users,
  profile,
}

class AdminBottomNavigation extends StatelessWidget {
  const AdminBottomNavigation({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  final AdminTab currentTab;
  final ValueChanged<AdminTab> onTabSelected;

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
                isSelected: currentTab == AdminTab.dashboard,
                onTap: () => onTabSelected(AdminTab.dashboard),
              ),
            ),

            Expanded(
              child: KcNavItem(
                icon: Icons.people_outline,
                selectedIcon: Icons.people,
                label: 'Pengguna',
                isSelected: currentTab == AdminTab.users,
                onTap: () => onTabSelected(AdminTab.users),
              ),
            ),
            
            Expanded(
              child: KcNavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'Profil',
                isSelected: currentTab == AdminTab.profile,
                onTap: () => onTabSelected(AdminTab.profile),
              ),
            ),
          ],
        ),
      ),
    );
  }
}