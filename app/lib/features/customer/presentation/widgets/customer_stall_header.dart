import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_status_badge.dart';
import 'package:kantin_cerdas/theme/kc_radius.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerStallHeader extends StatelessWidget {
  const CustomerStallHeader({
    super.key,
    required this.stall,
    required this.photoBytes,
    required this.onShowSchedule,
  });

  final CustomerStallSummary stall;
  final Uint8List? photoBytes;
  final VoidCallback onShowSchedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(KcRadius.card),
              child: Container(
                width: 84,
                height: 84,
                color: theme.colorScheme.surfaceContainerHighest,
                child: photoBytes != null
                    ? Image.memory(
                        photoBytes!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            const Icon(Icons.storefront_outlined, size: 36),
                      )
                    : const Icon(Icons.storefront_outlined, size: 36),
              ),
            ),
            const SizedBox(width: KcSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stall.name, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Lokasi: Blok ${stall.block}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: KcSpacing.xs,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      CustomerStatusChip.openClosed(
                        context,
                        isOpen: stall.isOpen,
                      ),
                      if (stall.waitMinutes > 0)
                        Text(
                          'Estimasi ± ${stall.waitMinutes} menit',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (stall.description.isNotEmpty) ...[
          const SizedBox(height: KcSpacing.sm),
          Text(stall.description, style: theme.textTheme.bodyMedium),
        ],
        const SizedBox(height: KcSpacing.xs),
        TextButton.icon(
          onPressed: onShowSchedule,
          icon: const Icon(Icons.schedule_outlined, size: 18),
          label: const Text('Lihat jadwal operasional'),
        ),
      ],
    );
  }
}

class CustomerStallNoticeBanner extends StatelessWidget {
  const CustomerStallNoticeBanner({
    super.key,
    required this.icon,
    required this.message,
    this.isError = false,
  });

  final IconData icon;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: KcSpacing.xs),
      padding: const EdgeInsets.all(KcSpacing.sm),
      decoration: BoxDecoration(
        color: isError ? scheme.errorContainer : scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(KcRadius.small),
        border: Border.all(
          color: isError ? scheme.error : scheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isError ? scheme.onErrorContainer : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: KcSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isError ? scheme.onErrorContainer : scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
