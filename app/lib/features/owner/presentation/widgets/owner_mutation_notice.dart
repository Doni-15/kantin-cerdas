import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_mutation_recovery_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/owner/presentation/controllers/owner_mutation_controller.dart';
import 'package:kantin_cerdas/features/owner/presentation/mappers/owner_labels.dart';

class OwnerMutationNotice extends ConsumerWidget {
  const OwnerMutationNotice({
    super.key,
    required this.operationPrefix,
    this.exactOperation = false,
  });
  final String operationPrefix;
  final bool exactOperation;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(ownerMutationProvider);
    final matches = exactOperation
        ? state.operation == operationPrefix
        : state.operation.startsWith(operationPrefix);
    if (state.busy && matches) {
      return const KcStatusPanel(
        title: 'Mengirim perubahan',
        message: 'Menunggu konfirmasi hasil perubahan.',
        loading: true,
      );
    }
    if (state.uncertain || state.journalLoading || state.journalError != null) {
      return const OwnerMutationRecoveryPanel();
    }
    if (!state.configured) {
      return const KcStatusPanel(
        title: 'Layanan belum tersedia',
        message: 'Pengiriman perubahan belum tersedia saat ini.',
      );
    }
    if (state.succeeded && matches && state.operation == 'stall:save') {
      return const KcStatusPanel(
        title: 'Pengaturan stan tersimpan',
        message: 'Perubahan informasi dan status stan sudah dikonfirmasi.',
        icon: Icons.check_circle_outline,
      );
    }
    if (state.error == null || !matches) {
      return const SizedBox.shrink();
    }
    return KcStatusPanel(
      title: 'Perubahan belum tersimpan',
      message: ownerFailureMessage(state.error!),
      icon: Icons.info_outline,
    );
  }
}
