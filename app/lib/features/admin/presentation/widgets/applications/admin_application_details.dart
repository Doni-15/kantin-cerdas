import 'package:flutter/material.dart';
import 'package:kantin_cerdas/core/utils/wib_date_formatter.dart';
import 'package:kantin_cerdas/features/admin/presentation/mappers/admin_application_labels.dart';
import 'package:kantin_cerdas/core/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AdminApplicationDetails extends StatelessWidget {
  const AdminApplicationDetails({super.key, required this.application});
  final CanteenApplication application;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(KcSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            application.name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Text(adminApplicationLabel(application.status)),
          Text('Diajukan ${formatWib(application.createdAt)}'),
          const SizedBox(height: KcSpacing.md),
          Text(application.description),
          const SizedBox(height: KcSpacing.md),
          Text('Lokasi: ${application.location}'),
          SelectableText('Kontak: ${application.phone}'),
          SelectableText('ID pemohon: ${application.applicantId}'),
          SelectableText('ID pengajuan: ${application.id}'),
          if (application.reason?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: KcSpacing.md),
            Text('Alasan: ${application.reason}'),
          ],
        ],
      ),
    ),
  );
}
