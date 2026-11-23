import 'package:flutter/material.dart';

class CustomerBottomNavBar extends StatelessWidget {
  const CustomerBottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onSelectTab,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      padding: EdgeInsets.zero,
      height: 64,
      child: Row(
        children: [
          Expanded(
            child: _BottomNavSlot(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: 'Beranda',
              selected: selectedIndex == 0,
              onTap: () => onSelectTab(0),
            ),
          ),
          Expanded(
            child: _BottomNavSlot(
              icon: Icons.search,
              selectedIcon: Icons.search,
              label: 'Cari',
              selected: selectedIndex == 1,
              onTap: () => onSelectTab(1),
            ),
          ),
          const SizedBox(width: 56),
          Expanded(
            child: _BottomNavSlot(
              icon: Icons.receipt_long_outlined,
              selectedIcon: Icons.receipt_long,
              label: 'Pesanan',
              selected: selectedIndex == 2,
              onTap: () => onSelectTab(2),
            ),
          ),
          Expanded(
            child: _BottomNavSlot(
              icon: Icons.person_outline,
              selectedIcon: Icons.person,
              label: 'Profil',
              selected: selectedIndex == 3,
              onTap: () => onSelectTab(3),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavSlot extends StatelessWidget {
  const _BottomNavSlot({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? selectedIcon : icon, color: color, size: 22),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
