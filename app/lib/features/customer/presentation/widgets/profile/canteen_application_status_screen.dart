import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/profile/canteen_application_status_view.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/profile/canteen_application_summary.dart';

class CanteenApplicationStatusScreen extends StatelessWidget {
  const CanteenApplicationStatusScreen({
    super.key,
    required this.application,
  });

  final CanteenApplication application;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Status Pengajuan'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          CanteenApplicationStatusView(
            status: application.status,
            rejectionReason: application.rejectionReason,
          ),
          const SizedBox(height: 24),
          CanteenApplicationSummary(
            name: application.name,
            description: application.description,
            address: application.address,
          ),
        ],
      ),
    );
  }
}
