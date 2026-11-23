import 'dart:math' as math;

import 'package:flutter/material.dart';

class SplashEmblemRingsPainter extends CustomPainter {
  SplashEmblemRingsPainter(this.progress, this.color)
    : super(repaint: progress);

  final Animation<double> progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 3;
    final motion = Curves.easeOutCubic.transform(progress.value);
    final paint = Paint()
      ..color = color.withValues(alpha: 0.19)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(
      center,
      radius - 8,
      paint..color = color.withValues(alpha: 0.09),
    );

    paint
      ..color = color.withValues(alpha: 0.68)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;
    final ring = Rect.fromCircle(center: center, radius: radius);
    final start = -math.pi / 2 + motion * 1.8;
    final sweep = 0.32 + motion * 0.74;
    canvas.drawArc(ring, start, sweep, false, paint);
    canvas.drawArc(ring, start + math.pi, sweep * 0.64, false, paint);
  }

  @override
  bool shouldRepaint(SplashEmblemRingsPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.progress != progress;
}
