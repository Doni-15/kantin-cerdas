import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/theme/theme_mode_provider.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class KcThemeModeCard extends ConsumerWidget {
  const KcThemeModeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currentMode = ref.watch(themeModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tampilan Aplikasi', style: theme.textTheme.titleMedium),
        const SizedBox(height: KcSpacing.xs),
        Card(
          clipBehavior: Clip.antiAlias,
          child: RadioGroup<ThemeMode>(
            groupValue: currentMode,
            onChanged: (mode) {
              if (mode != null) {
                ref.read(themeModeProvider.notifier).setThemeMode(mode);
              }
            },
            child: const Column(
              children: [
                RadioListTile<ThemeMode>(
                  title: Text('Ikuti sistem'),
                  value: ThemeMode.system,
                ),
                Divider(height: 1),
                RadioListTile<ThemeMode>(
                  title: Text('Mode Terang'),
                  value: ThemeMode.light,
                ),
                Divider(height: 1),
                RadioListTile<ThemeMode>(
                  title: Text('Mode Gelap'),
                  value: ThemeMode.dark,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
