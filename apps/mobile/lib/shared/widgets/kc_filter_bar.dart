import 'package:flutter/material.dart';
import 'package:kantincerdas/shared/design_system/kantin_cerdas_motion.dart';
import 'package:kantincerdas/shared/design_system/kantin_cerdas_size.dart';
import 'package:kantincerdas/shared/design_system/kantin_cerdas_spacing.dart';

class KcFilterBar extends StatelessWidget {
  const KcFilterBar({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<String> options;
  final Set<String> selected;
  final void Function(String option, bool selected)? onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final animation = KantinCerdasMotion.styleOf(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in options)
            Padding(
              padding: const EdgeInsets.only(right: KantinCerdasSpacing.space2),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: KantinCerdasSize.minimumTouchTarget,
                  minHeight: KantinCerdasSize.minimumTouchTarget,
                ),
                child: FilterChip(
                  label: Text(option),
                  selected: selected.contains(option),
                  onSelected: onSelected == null
                      ? null
                      : (value) => onSelected!(option, value),
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  visualDensity: VisualDensity.standard,
                  backgroundColor: colors.surface,
                  selectedColor: colors.secondaryContainer,
                  checkmarkColor: colors.onSecondaryContainer,
                  labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected.contains(option)
                        ? colors.onSecondaryContainer
                        : colors.onSurface,
                  ),
                  chipAnimationStyle: ChipAnimationStyle(
                    enableAnimation: animation,
                    selectAnimation: animation,
                    avatarDrawerAnimation: animation,
                    deleteDrawerAnimation: animation,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
