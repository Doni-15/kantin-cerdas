import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/customer/domain/customer_models.dart';
import 'package:kantin_cerdas/theme/kc_colors.dart';
import 'package:kantin_cerdas/widgets/kc_status_badge.dart';

class CustomerStatusChip extends StatelessWidget {
  const CustomerStatusChip({
    super.key,
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  factory CustomerStatusChip.openClosed(
    BuildContext context, {
    required bool isOpen,
  }) {
    final statusColors = Theme.of(context).extension<KcStatusColors>()!;
    final scheme = Theme.of(context).colorScheme;
    return isOpen
        ? CustomerStatusChip(
            label: 'Buka',
            foreground: statusColors.success,
            background: statusColors.successContainer,
          )
        : CustomerStatusChip(
            label: 'Tutup',
            foreground: scheme.onSurfaceVariant,
            background: scheme.surfaceContainerHighest,
          );
  }

  factory CustomerStatusChip.orderStatus(
    BuildContext context,
    CustomerOrderStatus status,
  ) {
    final statusColors = Theme.of(context).extension<KcStatusColors>()!;
    final scheme = Theme.of(context).colorScheme;
    final (fg, bg) = switch (status) {
      CustomerOrderStatus.menungguKonfirmasi => (
        statusColors.waiting,
        statusColors.waitingContainer,
      ),
      CustomerOrderStatus.diproses => (
        statusColors.processing,
        statusColors.processingContainer,
      ),
      CustomerOrderStatus.siapDiambil => (
        statusColors.ready,
        statusColors.readyContainer,
      ),
      CustomerOrderStatus.selesai => (
        statusColors.success,
        statusColors.successContainer,
      ),
      CustomerOrderStatus.ditolak ||
      CustomerOrderStatus.gagalDipenuhi ||
      CustomerOrderStatus.gagalDiambil => (scheme.error, scheme.errorContainer),
      CustomerOrderStatus.dibatalkan || CustomerOrderStatus.tidakDiambil => (
        scheme.onSurfaceVariant,
        scheme.surfaceContainerHighest,
      ),
    };
    return CustomerStatusChip(
      label: status.label,
      foreground: fg,
      background: bg,
    );
  }

  factory CustomerStatusChip.availability(
    BuildContext context, {
    required bool isAvailable,
    bool isArchived = false,
  }) {
    final statusColors = Theme.of(context).extension<KcStatusColors>()!;
    final scheme = Theme.of(context).colorScheme;
    if (isArchived) {
      return CustomerStatusChip(
        label: 'Tidak Tersedia',
        foreground: scheme.error,
        background: scheme.errorContainer,
      );
    }
    return isAvailable
        ? CustomerStatusChip(
            label: 'Tersedia',
            foreground: statusColors.success,
            background: statusColors.successContainer,
          )
        : CustomerStatusChip(
            label: 'Habis',
            foreground: scheme.error,
            background: scheme.errorContainer,
          );
  }

  @override
  Widget build(BuildContext context) {
    return KcStatusBadge(
      label: label,
      foreground: foreground,
      background: background,
      textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: foreground,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
