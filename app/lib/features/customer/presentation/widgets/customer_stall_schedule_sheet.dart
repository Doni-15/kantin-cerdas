import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

void showCustomerStallScheduleSheet(
  BuildContext context,
  List<CustomerScheduleDay> schedules,
) {
  showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            KcSpacing.md,
            KcSpacing.xs,
            KcSpacing.md,
            KcSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Jam Operasional (Informatif)',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Status Buka/Tutup kantin tetap dikendalikan langsung oleh pemilik kantin.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: KcSpacing.sm),
              if (schedules.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: KcSpacing.md),
                  child: Text('Jadwal operasional belum diatur.'),
                )
              else
                for (final day in schedules)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(
                            day.dayLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            day.isOpenDay
                                ? '${day.openTime ?? '-'} – ${day.closeTime ?? '-'}'
                                : 'Libur / Tutup',
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      );
    },
  );
}
