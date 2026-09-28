import 'package:flutter/material.dart';

import 'kc_logo.dart';

class KcBrand extends StatelessWidget {
  const KcBrand({
    super.key,
    this.logoSize = 48,
  });

  final double logoSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        KcLogo(
          size: logoSize,
        ),
        const SizedBox(width: 12),
        Text(
          'KantinCerdas',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}