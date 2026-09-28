import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_canteen_page.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_dashboard_page.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_orders_page.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_profile_page.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_bottom_navigation.dart';

class OwnerShell extends StatefulWidget {
  const OwnerShell({
    super.key,
    required this.user,
  });

  final User user;

  @override
  State<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends State<OwnerShell> {
  OwnerTab _currentTab = OwnerTab.dashboard;

  Widget get _currentPage {
    return switch (_currentTab) {
      OwnerTab.dashboard => const OwnerDashboardPage(),
      OwnerTab.canteen => const OwnerCanteenPage(),
      OwnerTab.orders => const OwnerOrdersPage(),
      OwnerTab.profile => const OwnerProfilePage(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentPage,

      bottomNavigationBar: OwnerBottomNavigation(
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