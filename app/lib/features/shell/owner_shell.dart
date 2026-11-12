import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_bottom_navigation.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_recovery_banner.dart';

/// Layout dan navigasi utama untuk pemilik kantin.
class OwnerShell extends StatelessWidget {
  const OwnerShell({super.key, required this.navigationShell});

  /// Urutan branch pada router harus sama dengan urutan [OwnerTab].
  final StatefulNavigationShell navigationShell;

  OwnerTab get _currentTab => OwnerTab.values[navigationShell.currentIndex];

  void _selectTab(OwnerTab tab) {
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
            const OwnerRecoveryBanner(),
            Expanded(child: navigationShell),
          ],
        ),
      ),
      bottomNavigationBar: OwnerBottomNavigation(
        currentTab: _currentTab,
        onTabSelected: _selectTab,
      ),
    );
  }
}
