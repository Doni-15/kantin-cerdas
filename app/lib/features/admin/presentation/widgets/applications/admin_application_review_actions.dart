import 'package:kantin_cerdas/features/admin/presentation/controllers/admin_mutation_controller.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_session_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_application_review.dart';
import 'package:kantin_cerdas/features/admin/presentation/controllers/admin_application_review_controller.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/applications/admin_application_review_dialog.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/core/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AdminApplicationReviewActions extends ConsumerStatefulWidget {
  const AdminApplicationReviewActions({super.key, required this.application});
  final CanteenApplication application;
  @override
  ConsumerState<AdminApplicationReviewActions> createState() =>
      _AdminApplicationReviewActionsState();
}

class _AdminApplicationReviewActionsState
    extends ConsumerState<AdminApplicationReviewActions> {
  bool _confirming = false;
  String _reason = '';
  Future<void> _decide(bool approve) async {
    if (_confirming || ref.read(adminMutationProvider).blocked) {
      return;
    }
    final application = widget.application;
    final session = ref.read(authStateProvider.notifier);
    final generation = session.sessionGeneration;
    final revision = ref.read(adminMutationProvider).revision;
    setState(() => _confirming = true);
    try {
      final reason = await showAdminDialog<String>(
        context: context,
        ref: ref,
        builder: (context) => AdminApplicationReviewDialog(
          approve: approve,
          name: application.name,
          initialReason: _reason,
        ),
      );
      if (!mounted ||
          reason == null ||
          !identical(session, ref.read(authStateProvider.notifier)) ||
          generation != session.sessionGeneration ||
          revision != ref.read(adminMutationProvider).revision ||
          ref.read(adminMutationProvider).blocked) {
        return;
      }
      if (!approve) {
        _reason = reason;
      }
      await ref
          .read(adminMutationControllerProvider.notifier)
          .review(
            AdminApplicationReview(
              applicationId: application.id,
              expectedVersion: application.version,
              status: approve
                  ? CanteenApplicationStatus.approved
                  : CanteenApplicationStatus.rejected,
              reason: reason,
            ),
          );
    } finally {
      if (mounted) {
        setState(() => _confirming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final attempt = ref.watch(
      adminApplicationReviewControllerProvider,
    )[widget.application.id];
    if (!widget.application.status.canBeReviewed) {
      return const Text('Pengajuan ini sudah memiliki keputusan akhir.');
    }
    final shared = ref.watch(adminMutationProvider);
    if (!shared.configured) {
      return const Text('Layanan perubahan admin belum tersedia saat ini.');
    }
    if (shared.journalLoading) {
      return const Text('Sedang memeriksa penanda perubahan tersimpan.');
    }
    final blocked =
        _confirming || shared.blocked || (attempt?.blocked ?? false);
    return Wrap(
      spacing: KcSpacing.sm,
      runSpacing: KcSpacing.sm,
      children: [
        FilledButton.icon(
          onPressed: blocked ? null : () => _decide(true),
          icon: const Icon(Icons.check),
          label: const Text('Setujui'),
        ),
        OutlinedButton.icon(
          onPressed: blocked ? null : () => _decide(false),
          icon: const Icon(Icons.close),
          label: const Text('Tolak'),
        ),
      ],
    );
  }
}
