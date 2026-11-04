import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_bottom_navigation.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_recovery_banner.dart';

/// Layout dan navigasi utama untuk pemilik kantin.
class OwnerShell extends StatelessWidget {
  const OwnerShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  OwnerTab get _currentTab {
    return switch (location) {
      Routes.ownerCanteen => OwnerTab.canteen,
      Routes.ownerOrders => OwnerTab.orders,
      Routes.ownerProfile => OwnerTab.profile,
      _ => OwnerTab.dashboard,
    };
  }

  void _selectTab(BuildContext context, OwnerTab tab) {
    final target = switch (tab) {
      OwnerTab.dashboard => Routes.ownerDashboard,
      OwnerTab.canteen => Routes.ownerCanteen,
      OwnerTab.orders => Routes.ownerOrders,
      OwnerTab.profile => Routes.ownerProfile,
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
            const OwnerRecoveryBanner(),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: OwnerBottomNavigation(
        currentTab: _currentTab,
        onTabSelected: (tab) => _selectTab(context, tab),
      ),
    );
  }
}
