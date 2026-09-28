import 'package:flutter/material.dart';

class KcLogo extends StatelessWidget {
  const KcLogo({
    super.key,
    this.size = 100,
    this.assetPath = 'assets/images/logos/in_app_logo.png'
  });

  final double size;
  final String assetPath ;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}