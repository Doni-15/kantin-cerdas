import 'package:flutter/material.dart';

class CategoryFilterChip extends StatelessWidget {
  const CategoryFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(
        right: 8,
      ),
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainer,
          foregroundColor: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
          side: BorderSide(
            color: selected
                ? theme.colorScheme.primary
                : Colors.transparent,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),
        ),
        child: Text(
          label,
        ),
      ),
    );
  }
}