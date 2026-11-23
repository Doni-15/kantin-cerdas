import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/admin/domain/admin_models.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AdminCompactSummaryGrid extends StatelessWidget {
  const AdminCompactSummaryGrid({
    super.key,
    required this.summary,
    required this.onTapUsers,
    required this.onTapApplications,
    required this.onTapStalls,
  });

  final AdminDashboardSummary summary;
  final VoidCallback onTapUsers;
  final VoidCallback onTapApplications;
  final VoidCallback onTapStalls;

  @override
  Widget build(BuildContext context) {
    final items = [
      (label: 'Pengguna', value: '${summary.totalUsers}', onTap: onTapUsers),
      (
        label: 'Pengajuan Owner',
        value: '${summary.pendingApplications}',
        onTap: onTapApplications,
      ),
      (label: 'Kantin', value: '${summary.totalStalls}', onTap: onTapStalls),
      (
        label: 'Akun Nonaktif',
        value: '${summary.inactiveUsers}',
        onTap: onTapUsers,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i += 2) ...[
            if (i > 0) const Divider(height: 1),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _SummaryCell(
                      label: items[i].label,
                      value: items[i].value,
                      onTap: items[i].onTap,
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: _SummaryCell(
                      label: items[i + 1].label,
                      value: items[i + 1].value,
                      onTap: items[i + 1].onTap,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KcSpacing.sm,
          vertical: KcSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
