import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';
import 'package:kantin_cerdas/theme/kc_colors.dart';
import 'package:kantin_cerdas/widgets/kc_status_badge.dart';

class OwnerStatusBadge extends StatelessWidget {
  const OwnerStatusBadge({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  factory OwnerStatusBadge.forOrderStatus(
    BuildContext context,
    OwnerOrderStatus status,
  ) {
    final colors = Theme.of(context).colorScheme;
    final statusColors = KcStatusColors.of(context);
    final (fg, bg) = switch (status) {
      OwnerOrderStatus.menungguKonfirmasi => (
        statusColors.waiting,
        statusColors.waitingContainer,
      ),
      OwnerOrderStatus.diproses => (
        statusColors.processing,
        statusColors.processingContainer,
      ),
      OwnerOrderStatus.siapDiambil => (
        statusColors.ready,
        statusColors.readyContainer,
      ),
      OwnerOrderStatus.selesai => (
        statusColors.completed,
        statusColors.completedContainer,
      ),
      OwnerOrderStatus.ditolak ||
      OwnerOrderStatus.gagalDipenuhi ||
      OwnerOrderStatus.gagalDiambil => (
        colors.onErrorContainer,
        colors.errorContainer,
      ),
      OwnerOrderStatus.dibatalkan || OwnerOrderStatus.tidakDiambil => (
        colors.onSurfaceVariant,
        colors.surfaceContainerHighest,
      ),
    };
    return OwnerStatusBadge(
      label: status.label,
      foreground: fg,
      background: bg,
    );
  }

  factory OwnerStatusBadge.forStallOpen(
    BuildContext context, {
    required bool isListed,
    required bool isOpen,
  }) {
    final colors = Theme.of(context).colorScheme;
    final statusColors = KcStatusColors.of(context);
    if (!isListed) {
      return OwnerStatusBadge(
        label: 'Belum Diterbitkan',
        foreground: statusColors.warning,
        background: statusColors.warningContainer,
      );
    }
    return isOpen
        ? OwnerStatusBadge(
            label: 'Buka',
            foreground: statusColors.success,
            background: statusColors.successContainer,
          )
        : OwnerStatusBadge(
            label: 'Tutup',
            foreground: colors.onSurfaceVariant,
            background: colors.surfaceContainerHighest,
          );
  }

  @override
  Widget build(BuildContext context) {
    return KcStatusBadge(
      label: label,
      foreground: foreground,
      background: background,
      showDot: true,
    );
  }
}
