import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_bottom_navigation.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';

import 'package:kantin_cerdas/features/admin/presentation/pages/admin_profile_page.dart';
import 'package:kantin_cerdas/features/admin/presentation/pages/admin_users_page.dart';
import 'package:kantin_cerdas/features/admin/presentation/pages/admin_dashboard_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    required this.user,
  });

  final User user;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  AdminTab _currentTab = AdminTab.dashboard;

  Widget get _currentPage {
    return switch (_currentTab) {
      AdminTab.dashboard => const AdminDashboardPage(),
      AdminTab.users => const AdminUsersPage(),
      AdminTab.profile => AdminProfilePage(
        user: widget.user,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentPage,
      bottomNavigationBar: AdminBottomNavigation(
        currentTab: _currentTab,
        onTabSelected: (tab) {
          setState(() {
            _currentTab = tab;
          });
        },
      ),
    );
  }
}