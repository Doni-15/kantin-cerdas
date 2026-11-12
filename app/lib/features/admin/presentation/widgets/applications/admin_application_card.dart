import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/core/utils/wib_date_formatter.dart';
import 'package:kantin_cerdas/features/admin/presentation/mappers/admin_application_labels.dart';
import 'package:kantin_cerdas/core/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class AdminApplicationCard extends StatelessWidget {
  const AdminApplicationCard({super.key, required this.application});
  final CanteenApplication application;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(KcSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            application.name,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(application.location),
          Text(adminApplicationLabel(application.status)),
          Text('Diajukan ${formatWib(application.createdAt)}'),
          const SizedBox(height: KcSpacing.sm),
          OutlinedButton(
            onPressed: () => context.push(
              Routes.adminApplicationDetailLocation(application.id),
            ),
            child: const Text('Buka pengajuan'),
          ),
        ],
      ),
    ),
  );
}
