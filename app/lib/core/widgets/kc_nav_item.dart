import 'package:flutter/material.dart';

class KcNavItem extends StatelessWidget {
  const KcNavItem({
    super.key,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final iconColor = isSelected
      ? colorScheme.onSecondaryContainer
      : colorScheme.onSurfaceVariant;
        
    final labelColor = isSelected
      ? colorScheme.primary
      : colorScheme.onSurfaceVariant;
        
    final indicatorColor = isSelected
      ? colorScheme.secondaryContainer
      : Colors.transparent;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: indicatorColor,
              borderRadius: BorderRadius.circular(16),
            ),

            child: Icon(
              isSelected ? selectedIcon : icon,
              color: iconColor,
              size: 24,
            ),
            
          ),

          const SizedBox(height: 4),

          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: labelColor,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}