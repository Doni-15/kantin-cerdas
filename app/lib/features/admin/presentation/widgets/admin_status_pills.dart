import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/admin/domain/admin_models.dart';
import 'package:kantin_cerdas/theme/kc_colors.dart';
import 'package:kantin_cerdas/widgets/kc_status_badge.dart';

class AdminStatusPill extends StatelessWidget {
  const AdminStatusPill({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return KcStatusBadge(
      label: label,
      foreground: foreground,
      background: background,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      textStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: foreground,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

AdminStatusPill buildApplicationStatusPill(
  BuildContext context,
  AdminApplicationStatus status,
) {
  final statusColors = KcStatusColors.of(context);
  final scheme = Theme.of(context).colorScheme;
  return switch (status) {
    AdminApplicationStatus.menungguReview => AdminStatusPill(
      label: status.label,
      foreground: statusColors.warning,
      background: statusColors.warningContainer,
    ),
    AdminApplicationStatus.disetujui => AdminStatusPill(
      label: status.label,
      foreground: statusColors.success,
      background: statusColors.successContainer,
    ),
    AdminApplicationStatus.ditolak => AdminStatusPill(
      label: status.label,
      foreground: scheme.onErrorContainer,
      background: scheme.errorContainer,
    ),
  };
}

AdminStatusPill buildAccountStatusPill(BuildContext context, bool isActive) {
  final statusColors = KcStatusColors.of(context);
  final scheme = Theme.of(context).colorScheme;
  return isActive
      ? AdminStatusPill(
          label: 'Aktif',
          foreground: statusColors.success,
          background: statusColors.successContainer,
        )
      : AdminStatusPill(
          label: 'Nonaktif',
          foreground: scheme.onErrorContainer,
          background: scheme.errorContainer,
        );
}
