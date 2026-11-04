import 'package:kantin_cerdas/features/auth/presentation/widgets/refresh_session_button.dart';
import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/utils/wib_date_formatter.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CanteenApplicationStatusCard extends StatelessWidget {
  const CanteenApplicationStatusCard({super.key, required this.application});
  final CanteenApplication application;
  @override
  Widget build(BuildContext context) {
    final status = switch (application.status) {
      CanteenApplicationStatus.submitted => 'Pengajuan terkirim',
      CanteenApplicationStatus.reviewing => 'Sedang ditinjau',
      CanteenApplicationStatus.approved => 'Disetujui',
      CanteenApplicationStatus.rejected => 'Perlu diperbaiki',
    };
    return Semantics(
      liveRegion: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(KcSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(status, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: KcSpacing.sm),
              Text(application.name),
              Text(application.location),
              Text(application.phone),
              Text('Diajukan ${formatWib(application.createdAt)}'),
              if (application.reason?.trim().isNotEmpty ?? false) ...[
                const SizedBox(height: KcSpacing.sm),
                Text('Catatan admin: ${application.reason}'),
              ],
              if (application.status == CanteenApplicationStatus.approved) ...[
                const SizedBox(height: KcSpacing.sm),
                const Text(
                  'Pengajuan sudah disetujui. Periksa akses akun untuk membaca role terbaru dari layanan.',
                ),
                const SizedBox(height: KcSpacing.sm),
                const RefreshSessionButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
