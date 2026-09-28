import 'package:flutter/material.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_ai_chat_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_history_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_home_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_orders_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_profile_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/customer_bottom_navigation.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({
    super.key,
    required this.user,
  });

  final User user;

  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  CustomerTab _currentTab = CustomerTab.home;

  Widget get _currentPage {
    return switch (_currentTab) {
      CustomerTab.home => const CustomerHomePage(),
      CustomerTab.orders => const CustomerOrdersPage(),
      CustomerTab.ai => const CustomerAiChatPage(),
      CustomerTab.history => const CustomerHistoryPage(),
      CustomerTab.profile => const CustomerProfilePage(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentPage,

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _currentTab = CustomerTab.ai;
          });
        },
        child: const Icon(
          Icons.smart_toy_outlined,
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: CustomerBottomNavigation(
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