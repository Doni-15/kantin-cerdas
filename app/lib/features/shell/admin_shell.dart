import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_bottom_navigation.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_recovery_banner.dart';

/// Layout dan navigasi utama untuk admin.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  AdminTab get _currentTab {
    return switch (location) {
      Routes.adminUsers => AdminTab.users,
      Routes.adminProfile => AdminTab.profile,
      _ => AdminTab.dashboard,
    };
  }

  void _selectTab(BuildContext context, AdminTab tab) {
    final target = switch (tab) {
      AdminTab.dashboard => Routes.adminDashboard,
      AdminTab.users => Routes.adminUsers,
      AdminTab.profile => Routes.adminProfile,
    };

    if (target != location) {
      context.go(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AdminRecoveryBanner(),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavigation(
        currentTab: _currentTab,
        onTabSelected: (tab) => _selectTab(context, tab),
      ),
    );
  }
}
