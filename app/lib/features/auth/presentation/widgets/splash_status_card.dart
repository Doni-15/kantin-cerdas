import 'package:flutter/material.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

enum SplashPhase {
  session('Menyiapkan sesi…', Icons.shield_outlined),
  catalog('Memuat daftar stan…', Icons.storefront_outlined),
  ready('Siap dibuka', Icons.check_rounded);

  const SplashPhase(this.label, this.icon);
  final String label;
  final IconData icon;
}

class SplashStatusCard extends StatelessWidget {
  const SplashStatusCard({
    super.key,
    required this.phase,
    required this.animate,
  });

  final SplashPhase phase;
  final bool animate;

  static const _maxStatusWidth = 290.0;
  static const _phaseSwitchDuration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: _maxStatusWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KcSpacing.md,
            vertical: KcSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                liveRegion: true,
                child: AnimatedSwitcher(
                  duration: animate ? _phaseSwitchDuration : Duration.zero,
                  child: Row(
                    key: ValueKey(phase),
                    children: [
                      ExcludeSemantics(
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: colors.primaryContainer,
                          foregroundColor: colors.onPrimaryContainer,
                          child: Icon(phase.icon, size: 18),
                        ),
                      ),
                      const SizedBox(width: KcSpacing.sm),
                      Expanded(
                        child: Text(
                          phase.label,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (animate) ...[
                const SizedBox(height: KcSpacing.sm),
                ExcludeSemantics(
                  child: LinearProgressIndicator(
                    value: phase == SplashPhase.ready ? 1 : null,
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(2),
                    color: colors.primary,
                    backgroundColor: colors.primaryContainer,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
