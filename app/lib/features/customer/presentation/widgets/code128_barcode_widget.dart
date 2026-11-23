import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/customer/domain/code128_encoder.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

/// Displays an ISO/IEC 15417 Code 128 barcode with mandatory quiet zones on a
/// pure white background for optical scanning reliability even in Dark Mode.
class Code128BarcodeCard extends StatelessWidget {
  const Code128BarcodeCard({
    super.key,
    required this.value,
    this.caption = 'Tunjukkan kode ini saat mengambil makanan di kantin.',
  });

  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final encoded = Code128Encoder.encodeCodeB(value);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(KcSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bukti Pengambilan (Code 128)',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: KcSpacing.xs),
            Text(
              caption,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: KcSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: KcSpacing.sm,
                vertical: KcSpacing.md,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(KcRadius.small),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  Semantics(
                    label: 'Barcode Code 128 nomor pesanan $value',
                    child: SizedBox(
                      height: 84,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _Code128Painter(encoded.modules),
                      ),
                    ),
                  ),
                  const SizedBox(height: KcSpacing.xs),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.black,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Code128Painter extends CustomPainter {
  const _Code128Painter(this.modules);

  final List<bool> modules;
  static const int _quietModules = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final totalModules = modules.length + _quietModules * 2;
    if (totalModules <= 0) return;

    final moduleWidth = size.width / totalModules;
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    var i = 0;
    while (i < modules.length) {
      if (!modules[i]) {
        i++;
        continue;
      }
      final start = i;
      while (i < modules.length && modules[i]) {
        i++;
      }
      final left = (_quietModules + start) * moduleWidth;
      final right = (_quietModules + i) * moduleWidth;
      canvas.drawRect(Rect.fromLTRB(left, 0, right, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _Code128Painter oldDelegate) =>
      oldDelegate.modules != modules;
}
