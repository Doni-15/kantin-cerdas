import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kantin_cerdas/app/router/auth_redirect.dart';
import 'package:kantin_cerdas/app/router/route_error_page.dart';
import 'package:kantin_cerdas/app/router/routes.dart';

import 'package:kantin_cerdas/features/admin/presentation/pages/admin_application_detail_page.dart';
import 'package:kantin_cerdas/features/admin/presentation/pages/admin_applications_page.dart';
import 'package:kantin_cerdas/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:kantin_cerdas/features/admin/presentation/pages/admin_profile_page.dart';
import 'package:kantin_cerdas/features/admin/presentation/pages/admin_user_detail_page.dart';
import 'package:kantin_cerdas/features/admin/presentation/pages/admin_users_page.dart';

import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/account_security_page.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/change_password_page.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/login_page.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/password_reset_page.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/register_page.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/register_profile_page.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/session_restore_page.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';

import 'package:kantin_cerdas/features/customer/presentation/pages/customer_ai_chat_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_canteen_application_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_cart_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_food_preferences_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_history_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_home_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_order_confirmation_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_order_detail_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_order_success_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_orders_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_profile_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_search_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_stall_detail_page.dart';

import 'package:kantin_cerdas/features/owner/presentation/pages/owner_canteen_page.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_dashboard_page.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_order_detail_page.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_orders_page.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_profile_page.dart';
import 'package:kantin_cerdas/features/owner/presentation/pages/owner_stall_settings_page.dart';

import 'package:kantin_cerdas/features/settings/presentation/pages/help_page.dart';
import 'package:kantin_cerdas/features/settings/presentation/pages/settings_page.dart';
import 'package:kantin_cerdas/features/settings/presentation/pages/terms_page.dart';

import 'package:kantin_cerdas/features/shell/admin_shell.dart';
import 'package:kantin_cerdas/features/shell/customer_shell.dart';
import 'package:kantin_cerdas/features/shell/owner_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authRefresh = ValueNotifier<int>(0);

  final authSubscription = ref.listen<AsyncValue<User?>>(authStateProvider, (
    previous,
    next,
  ) {
    authRefresh.value++;
  });

  final router = GoRouter(
    initialLocation: Routes.app,
    refreshListenable: authRefresh,
    redirect: (context, state) {
      return authRedirect(
        authState: ref.read(authStateProvider),
        path: state.uri.path,
        uri: state.uri,
      );
    },
    errorBuilder: (context, state) => const RouteErrorPage(),
    routes: [
      GoRoute(path: '/', redirect: (context, state) => Routes.app),
      GoRoute(
        path: Routes.app,
        builder: (context, state) => const SessionRestorePage(),
      ),

      // Autentikasi.
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: Routes.resetPassword,
        builder: (context, state) => const PasswordResetPage(),
      ),
      GoRoute(
        path: Routes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: Routes.registerProfile,
        builder: (context, state) => const RegisterProfilePage(),
      ),

      // Halaman publik.
      GoRoute(path: Routes.help, builder: (context, state) => const HelpPage()),
      GoRoute(
        path: Routes.terms,
        builder: (context, state) => const TermsPage(),
      ),

      // Halaman bersama untuk seluruh akun aktif.
      GoRoute(
        path: Routes.settings,
        builder: (context, state) =>
            _withActiveUser((user) => const SettingsPage()),
      ),
      GoRoute(
        path: Routes.accountSecurity,
        builder: (context, state) =>
            _withActiveUser((user) => const AccountSecurityPage()),
      ),
      GoRoute(
        path: Routes.changePassword,
        builder: (context, state) =>
            _withActiveUser((user) => const ChangePasswordPage()),
      ),

      // Navigasi utama customer.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => _withActiveUser(
          (user) => CustomerShell(navigationShell: navigationShell),
          role: UserRole.customer,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.customerHome,
                pageBuilder: (context, state) => _tabPage(
                  state,
                  _withActiveUser(
                    (user) => const CustomerHomePage(),
                    role: UserRole.customer,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.customerOrders,
                pageBuilder: (context, state) => _tabPage(
                  state,
                  _withActiveUser(
                    (user) => const CustomerOrdersPage(),
                    role: UserRole.customer,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.customerAiChat,
                pageBuilder: (context, state) => _tabPage(
                  state,
                  _withActiveUser(
                    (user) => CustomerAiChatPage(
                      onBackToHome: () {
                        context.go(Routes.customerHome);
                      },
                    ),
                    role: UserRole.customer,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.customerHistory,
                pageBuilder: (context, state) => _tabPage(
                  state,
                  _withActiveUser(
                    (user) => const CustomerHistoryPage(),
                    role: UserRole.customer,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.customerProfile,
                pageBuilder: (context, state) => _tabPage(
                  state,
                  _withActiveUser(
                    (user) => CustomerProfilePage(user: user),
                    role: UserRole.customer,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),

      // Halaman customer di luar bottom navigation.
      GoRoute(
        path: Routes.customerOrderDetail,
        builder: (context, state) => _withActiveUser(
          (user) => CustomerOrderDetailPage(
            orderId: state.pathParameters['orderId']!,
          ),
          role: UserRole.customer,
        ),
      ),
      GoRoute(
        path: Routes.customerSearch,
        builder: (context, state) => _withActiveUser(
          (user) => const CustomerSearchPage(),
          role: UserRole.customer,
        ),
      ),
      GoRoute(
        path: Routes.customerCart,
        builder: (context, state) => _withActiveUser(
          (user) => const CustomerCartPage(),
          role: UserRole.customer,
        ),
      ),
      GoRoute(
        path: Routes.customerStallDetail,
        builder: (context, state) => _withActiveUser(
          (user) => CustomerStallDetailPage(
            stallId: state.pathParameters['stallId']!,
          ),
          role: UserRole.customer,
        ),
      ),
      GoRoute(
        path: Routes.customerFoodPreferences,
        builder: (context, state) => _withActiveUser(
          (user) => const CustomerFoodPreferencesPage(),
          role: UserRole.customer,
        ),
      ),
      GoRoute(
        path: Routes.customerCanteenApplication,
        builder: (context, state) => _withActiveUser(
          (user) => const CustomerCanteenApplicationPage(),
          role: UserRole.customer,
        ),
      ),
      GoRoute(
        path: Routes.customerOrderConfirmation,
        builder: (context, state) => _withActiveUser(
          (user) => const CustomerOrderConfirmationPage(),
          role: UserRole.customer,
        ),
      ),
      GoRoute(
        path: Routes.customerOrderSuccess,
        builder: (context, state) => _withActiveUser(
          (user) => CustomerOrderSuccessPage(
            orderId: state.pathParameters['orderId']!,
          ),
          role: UserRole.customer,
        ),
      ),

      // Navigasi utama owner.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => _withActiveUser(
          (user) => OwnerShell(navigationShell: navigationShell),
          role: UserRole.owner,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.ownerDashboard,
                pageBuilder: (context, state) => _tabPage(
                  state,
                  _withActiveUser(
                    (user) => OwnerDashboardPage(ownerName: user.name),
                    role: UserRole.owner,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.ownerCanteen,
                pageBuilder: (context, state) => _tabPage(
                  state,
                  _withActiveUser(
                    (user) => const OwnerCanteenPage(),
                    role: UserRole.owner,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.ownerOrders,
                pageBuilder: (context, state) => _tabPage(
                  state,
                  _withActiveUser(
                    (user) => const OwnerOrdersPage(),
                    role: UserRole.owner,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.ownerProfile,
                pageBuilder: (context, state) => _tabPage(
                  state,
                  _withActiveUser(
                    (user) => OwnerProfilePage(user: user),
                    role: UserRole.owner,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.ownerOrderDetail,
        builder: (context, state) => _withActiveUser(
          (user) =>
              OwnerOrderDetailPage(orderId: state.pathParameters['orderId']!),
          role: UserRole.owner,
        ),
      ),
      GoRoute(
        path: Routes.ownerStallSettings,
        builder: (context, state) => _withActiveUser(
          (user) => const OwnerStallSettingsPage(),
          role: UserRole.owner,
        ),
      ),

      GoRoute(
        path: Routes.adminApplications,
        builder: (context, state) => _withActiveUser(
          (user) => const AdminApplicationsPage(),
          role: UserRole.admin,
        ),
      ),
      GoRoute(
        path: Routes.adminApplicationDetail,
        builder: (context, state) => _withActiveUser(
          (user) => AdminApplicationDetailPage(
            applicationId: state.pathParameters['applicationId']!,
          ),
          role: UserRole.admin,
        ),
      ),

      GoRoute(
        path: Routes.adminUserDetail,
        builder: (context, state) => _withActiveUser(
          (user) =>
              AdminUserDetailPage(userId: state.pathParameters['userId']!),
          role: UserRole.admin,
        ),
      ),

      // Navigasi utama admin.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => _withActiveUser(
          (user) => AdminShell(navigationShell: navigationShell),
          role: UserRole.admin,
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.adminDashboard,
                pageBuilder: (context, state) => _tabPage(
                  state,
                  _withActiveUser(
                    (user) => const AdminDashboardPage(),
                    role: UserRole.admin,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.adminUsers,
                pageBuilder: (context, state) => _tabPage(
                  state,
                  _withActiveUser(
                    (user) => const AdminUsersPage(),
                    role: UserRole.admin,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.adminProfile,
                pageBuilder: (context, state) => _tabPage(
                  state,
                  _withActiveUser(
                    (user) => AdminProfilePage(user: user),
                    role: UserRole.admin,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(() {
    authSubscription.close();
    router.dispose();
    authRefresh.dispose();
  });

  return router;
});

NoTransitionPage<void> _tabPage(GoRouterState state, Widget child) {
  return NoTransitionPage<void>(key: state.pageKey, child: child);
}

Widget _withActiveUser(Widget Function(User user) builder, {UserRole? role}) {
  return Consumer(
    builder: (context, ref, child) {
      final authState = ref.watch(authStateProvider);
      final session = ref.watch(authStateProvider.notifier);
      final user = authState.asData?.value;

      if (authState.isLoading ||
          authState.hasError ||
          user == null ||
          !user.isActive ||
          (role != null && !user.role.allows(role))) {
        return const SessionRestorePage();
      }

      return KeyedSubtree(
        key: ValueKey((user.id, user.role, session, session.sessionGeneration)),
        child: builder(user),
      );
    },
  );
}
