import 'package:flutter/material.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AuthRegistrationProgress extends StatelessWidget {
  const AuthRegistrationProgress({
    super.key,
    required this.step,
    required this.onBack,
  });

  final int step;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: KcSpacing.lg),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Kembali',
                onPressed: onBack,
                icon: const BackButtonIcon(),
              ),
              Flexible(child: Text('Langkah $step dari 2')),
            ],
          ),
          ExcludeSemantics(
            child: Row(
              spacing: KcSpacing.xs,
              children: [
                Expanded(child: LinearProgressIndicator(value: 1)),
                Expanded(
                  child: LinearProgressIndicator(
                    value: step == 2 ? 1 : 0,
                    backgroundColor: colors.outlineVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
