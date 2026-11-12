import 'package:flutter/material.dart';

class KcLogo extends StatelessWidget {
  const KcLogo({
    super.key,
    this.size = 100,
    this.assetPath = 'assets/images/logos/app_logo.png',
  });

  final double size;
  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.restaurant_menu,
          size: size * 0.7,
          color: Theme.of(context).colorScheme.primary,
        );
      },
    );
  }
}
