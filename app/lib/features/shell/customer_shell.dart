import 'package:kantin_cerdas/features/customer/presentation/widgets/orders/customer_cancellation_banner.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/checkout/customer_checkout_banner.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_bottom_navigation.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.navigationShell});

  /// Urutan branch pada router harus sama dengan urutan [CustomerTab].
  final StatefulNavigationShell navigationShell;

  CustomerTab get _currentTab =>
      CustomerTab.values[navigationShell.currentIndex];

  void _selectTab(CustomerTab tab) {
    navigationShell.goBranch(
      tab.index,
      initialLocation: tab.index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = _currentTab;
    final isAiChat = currentTab == CustomerTab.ai;

    return PopScope<Object?>(
      canPop: !isAiChat,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isAiChat) {
          context.go(Routes.customerHome);
        }
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const CustomerCheckoutBanner(),
              const CustomerCancellationBanner(),
              Expanded(child: navigationShell),
            ],
          ),
        ),
        floatingActionButton: isAiChat
            ? null
            : FloatingActionButton(
                tooltip: 'Asisten AI',
                shape: const CircleBorder(),
                onPressed: () {
                  _selectTab(CustomerTab.ai);
                },
                child: const Icon(Icons.smart_toy_outlined),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: isAiChat
            ? null
            : CustomerBottomNavigation(
                currentTab: currentTab,
                onTabSelected: (tab) {
                  _selectTab(tab);
                },
              ),
      ),
    );
  }
}
