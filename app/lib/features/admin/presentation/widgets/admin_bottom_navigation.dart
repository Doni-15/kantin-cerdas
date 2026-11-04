import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_nav_item.dart';

enum AdminTab { dashboard, users, profile }

/// Navigasi admin. Perpindahan route ditangani oleh AdminShell.
class AdminBottomNavigation extends StatelessWidget {
  const AdminBottomNavigation({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  static const _defaultHeight = 80.0;

  final AdminTab currentTab;
  final ValueChanged<AdminTab> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navigationTheme = NavigationBarTheme.of(context);

    final labelStyle =
        navigationTheme.labelTextStyle?.resolve(const <WidgetState>{
          WidgetState.selected,
        }) ??
        theme.textTheme.labelMedium;

    final fontSize = labelStyle?.fontSize ?? 12.0;
    final lineHeight = labelStyle?.height ?? 1.0;
    final scaledFontSize = MediaQuery.textScalerOf(context).scale(fontSize);
    final extraLabelHeight = (scaledFontSize - fontSize) * lineHeight;

    // Tambahkan ruang ketika pengguna memperbesar ukuran teks.
    final barHeight =
        (navigationTheme.height ?? _defaultHeight) +
        (extraLabelHeight > 0 ? extraLabelHeight : 0.0);

    return BottomAppBar(
      color:
          navigationTheme.backgroundColor ??
          theme.colorScheme.surfaceContainerLow,
      elevation: navigationTheme.elevation ?? 0,
      surfaceTintColor: navigationTheme.surfaceTintColor,
      shadowColor: navigationTheme.shadowColor,
      padding: EdgeInsets.zero,
      height: barHeight,
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
    );
  }
}
