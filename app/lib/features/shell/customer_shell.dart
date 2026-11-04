import 'package:kantin_cerdas/features/customer/presentation/widgets/orders/customer_cancellation_banner.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/checkout/customer_checkout_banner.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_bottom_navigation.dart';

class CustomerShell extends StatelessWidget {
  const CustomerShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  CustomerTab get _currentTab {
    return switch (location) {
      Routes.customerOrders => CustomerTab.orders,
      Routes.customerHistory => CustomerTab.history,
      Routes.customerProfile => CustomerTab.profile,
      Routes.customerAiChat => CustomerTab.ai,
      _ => CustomerTab.home,
    };
  }

  void _selectTab(BuildContext context, CustomerTab tab) {
    final target = switch (tab) {
      CustomerTab.home => Routes.customerHome,
      CustomerTab.orders => Routes.customerOrders,
      CustomerTab.ai => Routes.customerAiChat,
      CustomerTab.history => Routes.customerHistory,
      CustomerTab.profile => Routes.customerProfile,
    };

    if (target != location) {
      context.go(target);
    }
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
              Expanded(child: child),
            ],
          ),
        ),
        floatingActionButton: isAiChat
            ? null
            : FloatingActionButton(
                tooltip: 'Asisten AI',
                shape: const CircleBorder(),
                onPressed: () {
                  _selectTab(context, CustomerTab.ai);
                },
                child: const Icon(Icons.smart_toy_outlined),
              ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: isAiChat
            ? null
            : CustomerBottomNavigation(
                currentTab: currentTab,
                onTabSelected: (tab) {
                  _selectTab(context, tab);
                },
              ),
      ),
    );
  }
}
