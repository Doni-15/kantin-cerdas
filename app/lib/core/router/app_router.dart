import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/core/router/app_entry_page.dart';
import 'package:kantin_cerdas/core/router/routes.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/login_page.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/register_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_home_page.dart';

final appRouter = GoRouter(
  initialLocation: Routes.login,
  routes: [
    GoRoute(
      path: Routes.login,
      builder: (context, state) {
        return const LoginPage();
      },
    ),

    GoRoute(
      path: Routes.register,
      builder: (context, state) => const RegisterPage(),
    ),

    GoRoute(
      path: Routes.app,
      builder: (context, state) => const AppEntryPage(),
    ),

    GoRoute(
      path: Routes.home,
      builder: (context, state) => const CustomerHomePage(),
    ),
  ],
);
