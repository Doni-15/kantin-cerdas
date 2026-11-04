import 'package:flutter/material.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';
import 'package:kantin_cerdas/theme/kc_sizes.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

/// Item navigasi bersama. Pemilihan tab dikelola oleh widget pemanggil.
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
    assert(debugCheckHasMaterial(context));

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final navigationTheme = NavigationBarTheme.of(context);
    final states = <WidgetState>{if (isSelected) WidgetState.selected};

    final baseLabelStyle =
        theme.textTheme.labelMedium ??
        const TextStyle(fontSize: 12, height: 4 / 3);

    final labelStyle =
        navigationTheme.labelTextStyle?.resolve(states) ??
        baseLabelStyle.copyWith(
          color: isSelected ? colors.onSurface : colors.onSurfaceVariant,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
        );

    final iconTheme = IconThemeData(
      size: 24,
      color: isSelected ? colors.onSecondaryContainer : colors.onSurfaceVariant,
    ).merge(navigationTheme.iconTheme?.resolve(states));

    final indicatorColor = isSelected
        ? navigationTheme.indicatorColor ?? colors.secondaryContainer
        : Colors.transparent;

    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(KcRadius.control),
          child: ExcludeSemantics(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: KcSizes.minimumTouchTarget,
                minHeight: KcSizes.minimumTouchTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KcSpacing.xs / 2,
                  vertical: KcSpacing.xs,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 64),
                      child: SizedBox(
                        width: double.infinity,
                        height: 32,
                        child: Ink(
                          decoration: ShapeDecoration(
                            color: indicatorColor,
                            shape:
                                navigationTheme.indicatorShape ??
                                const StadiumBorder(),
                          ),
                          child: IconTheme(
                            data: iconTheme,
                            child: Icon(isSelected ? selectedIcon : icon),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: KcSpacing.xs),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: labelStyle,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
