import 'package:flutter/material.dart';

class KcInlineProgressIndicator extends StatelessWidget {
  const KcInlineProgressIndicator({
    super.key,
    this.size = 18,
    this.strokeWidth = 2,
  });

  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CircularProgressIndicator(strokeWidth: strokeWidth),
  );
}
