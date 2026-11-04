import 'package:flutter/material.dart';

import 'package:kantin_cerdas/core/widgets/kc_nav_item.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

enum CustomerTab { home, orders, ai, history, profile }

class CustomerBottomNavigation extends StatelessWidget {
  const CustomerBottomNavigation({
    super.key,
    required this.currentTab,
    required this.onTabSelected,
  });

  static const _defaultHeight = 80.0;
  static const _fabSpace = 72.0;

  final CustomerTab currentTab;
  final ValueChanged<CustomerTab> onTabSelected;

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

    // Tambahkan ruang vertikal ketika ukuran teks diperbesar.
    final extraLabelHeight = (scaledFontSize - fontSize) * lineHeight;
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
      shape: const CircularNotchedRectangle(),
      notchMargin: KcSpacing.xs,
      padding: EdgeInsets.zero,
      height: barHeight,
      child: Row(
        children: [
          Expanded(
            child: KcNavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: 'Home',
              isSelected: currentTab == CustomerTab.home,
              onTap: () {
                onTabSelected(CustomerTab.home);
              },
            ),
          ),
          Expanded(
            child: KcNavItem(
              icon: Icons.receipt_long_outlined,
              selectedIcon: Icons.receipt_long,
              label: 'Pesanan',
              isSelected: currentTab == CustomerTab.orders,
              onTap: () {
                onTabSelected(CustomerTab.orders);
              },
            ),
          ),
          const SizedBox(width: _fabSpace),
          Expanded(
            child: KcNavItem(
              icon: Icons.history_outlined,
              selectedIcon: Icons.history,
              label: 'Riwayat',
              isSelected: currentTab == CustomerTab.history,
              onTap: () {
                onTabSelected(CustomerTab.history);
              },
            ),
          ),
          Expanded(
            child: KcNavItem(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: 'Profil',
              isSelected: currentTab == CustomerTab.profile,
              onTap: () {
                onTabSelected(CustomerTab.profile);
              },
            ),
          ),
        ],
      ),
    );
  }
}
