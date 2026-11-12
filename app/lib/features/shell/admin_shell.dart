import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_bottom_navigation.dart';
import 'package:kantin_cerdas/features/admin/presentation/widgets/admin_recovery_banner.dart';

/// Layout dan navigasi utama untuk admin.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.navigationShell});

  /// Urutan branch pada router harus sama dengan urutan [AdminTab].
  final StatefulNavigationShell navigationShell;

  AdminTab get _currentTab => AdminTab.values[navigationShell.currentIndex];

  void _selectTab(AdminTab tab) {
    navigationShell.goBranch(
      tab.index,
      initialLocation: tab.index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AdminRecoveryBanner(),
            Expanded(child: navigationShell),
          ],
        ),
      ),
      bottomNavigationBar: AdminBottomNavigation(
        currentTab: _currentTab,
        onTabSelected: _selectTab,
      ),
    );
  }
}
