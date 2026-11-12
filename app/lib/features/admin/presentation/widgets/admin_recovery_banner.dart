import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/admin/presentation/controllers/admin_mutation_controller.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_mutation_recovery_panel.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_session_dialog.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

/// Akses recovery tidak bergantung pada keberhasilan pembacaan data pengajuan/pengguna.
class AdminRecoveryBanner extends ConsumerStatefulWidget {
  const AdminRecoveryBanner({super.key});
  @override
  ConsumerState<AdminRecoveryBanner> createState() =>
      _AdminRecoveryBannerState();
}

class _AdminRecoveryBannerState extends ConsumerState<AdminRecoveryBanner> {
  bool _dialogOpen = false;
  Future<void> _open() async {
    if (_dialogOpen) {
      return;
    }
    setState(() => _dialogOpen = true);
    try {
      await showAdminDialog<void>(
        context: context,
        ref: ref,
        builder: (dialogContext) => AlertDialog(
          scrollable: true,
          title: const Text('Pemulihan perubahan'),
          content: const AdminMutationRecoveryPanel(),
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
    final state = ref.watch(adminMutationProvider);
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
          label: const Text('Periksa perubahan tertunda'),
        ),
      ),
    );
  }
}
