import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_nav_item.dart';

enum OwnerTab { dashboard, canteen, orders, profile }

/// Navigasi pemilik kantin. Perpindahan route ditangani oleh OwnerShell.
class OwnerBottomNavigation extends StatelessWidget {
  const OwnerBottomNavigation({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  static const _defaultHeight = 80.0;

  final OwnerTab currentTab;
  final ValueChanged<OwnerTab> onTabSelected;

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
    );
  }
}
