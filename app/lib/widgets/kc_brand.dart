import 'package:flutter/material.dart';

class KcAppLogo extends StatelessWidget {
  const KcAppLogo({super.key, required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/logos/app_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
      excludeFromSemantics: true,
    );
  }
}

class KcBrandName extends StatelessWidget {
  const KcBrandName({super.key, this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Text.rich(
      TextSpan(
        style: (style ?? theme.textTheme.headlineMedium)?.copyWith(
          letterSpacing: -0.5,
        ),
        children: [
          TextSpan(
            text: 'Kantin',
            style: TextStyle(color: colors.primary),
          ),
          TextSpan(
            text: 'Cerdas',
            style: TextStyle(color: colors.secondary),
          ),
        ],
      ),
      semanticsLabel: 'Kantin Cerdas',
      textAlign: TextAlign.center,
    );
  }
}
