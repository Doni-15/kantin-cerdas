import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_summary.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AdminSummaryGrid extends StatelessWidget {
  const AdminSummaryGrid({super.key, required this.summary});

  final AdminSummary summary;

  @override
  Widget build(BuildContext context) {
    final metrics = [
      (label: 'Pengguna', value: summary.users, icon: Icons.people_outline),
      (
        label: 'Stan terdaftar',
        value: summary.stalls,
        icon: Icons.storefront_outlined,
      ),
      (
        label: 'Stan buka',
        value: summary.openStalls,
        icon: Icons.store_outlined,
      ),
      (
        label: 'Pengajuan menunggu',
        value: summary.pendingApplications,
        icon: Icons.assignment_outlined,
      ),
      (
        label: 'Pesanan aktif',
        value: summary.activeOrders,
        icon: Icons.receipt_long_outlined,
      ),
    ];
    final theme = Theme.of(context);
    final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 && scale <= 1.3
            ? 3
            : constraints.maxWidth >= 420 && scale <= 1.5
            ? 2
            : 1;
        final width =
            (constraints.maxWidth - KcSpacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: KcSpacing.sm,
          runSpacing: KcSpacing.sm,
          children: [
            for (final metric in metrics)
              SizedBox(
                width: width,
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(KcSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExcludeSemantics(
                          child: Icon(
                            metric.icon,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: KcSpacing.sm),
                        Text(
                          '${metric.value}',
                          style: theme.textTheme.headlineMedium,
                        ),
                        Text(metric.label),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
