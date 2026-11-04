import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/customer/presentation/controllers/customer_order_cancellation_controller.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/orders/customer_cancellation_recovery_panel.dart';
import 'package:kantin_cerdas/core/widgets/kc_role_session_dialog.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

/// Akses recovery tidak bergantung pada keberhasilan pembacaan detail pesanan.
class CustomerCancellationBanner extends ConsumerStatefulWidget {
  const CustomerCancellationBanner({super.key});
  @override
  ConsumerState<CustomerCancellationBanner> createState() =>
      _CustomerCancellationBannerState();
}

class _CustomerCancellationBannerState
    extends ConsumerState<CustomerCancellationBanner> {
  bool _dialogOpen = false;
  Future<void> _open() async {
    if (_dialogOpen) {
      return;
    }
    setState(() => _dialogOpen = true);
    try {
      await showKcRoleDialog<void>(
        context: context,
        ref: ref,
        role: UserRole.customer,
        builder: (dialogContext) => AlertDialog(
          scrollable: true,
          title: const Text('Pemulihan pembatalan'),
          content: const CustomerCancellationRecoveryPanel(),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _dialogOpen = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerOrderCancellationProvider);
    if (!state.unresolved && state.journalError == null) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: KcSpacing.md,
        vertical: KcSpacing.xs,
      ),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: _dialogOpen ? null : _open,
          icon: const Icon(Icons.sync_problem_outlined),
          label: const Text('Periksa pembatalan tertunda'),
        ),
      ),
    );
  }
}
