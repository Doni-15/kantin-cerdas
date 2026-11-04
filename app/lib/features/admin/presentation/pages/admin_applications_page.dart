import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/applications/admin_application_feed.dart';

class AdminApplicationsPage extends StatelessWidget {
  const AdminApplicationsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Pengajuan kantin'),
      leading: BackButton(
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(Routes.adminDashboard);
          }
        },
      ),
    ),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: const AdminApplicationFeed(),
        ),
      ),
    ),
  );
}
