import 'dart:async';
import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/owner/domain/failures/owner_failure.dart';
import 'package:kantin_cerdas/features/owner/presentation/mappers/owner_labels.dart';

class OwnerLoadError extends StatelessWidget {
  const OwnerLoadError({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final unavailable = error is OwnerNotConfiguredFailure;
    return KcStatusPanel(
      title: unavailable ? 'Layanan belum tersedia' : 'Data belum dapat dimuat',
      message: error is TimeoutException
          ? 'Permintaan terlalu lama. Coba muat ulang data.'
          : ownerFailureMessage(error),
      icon: Icons.cloud_off_outlined,
      action: unavailable
          ? null
          : OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
    );
  }
}
