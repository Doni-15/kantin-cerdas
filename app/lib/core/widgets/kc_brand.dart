import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_logo.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class KcBrand extends StatelessWidget {
  const KcBrand({super.key, this.logoSize = 48});

  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        KcLogo(size: logoSize),
        const SizedBox(width: KcSpacing.sm),
        Flexible(
          child: Text(
            'KantinCerdas',
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
