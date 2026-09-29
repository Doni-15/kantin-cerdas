import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/core/router/app_entry_page.dart';
import 'package:kantin_cerdas/core/router/routes.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/change_password_page.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/login_page.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/register_page.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_canteen_application_page.dart';
import 'package:kantin_cerdas/features/customer/presentation/pages/customer_home_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Router mengevaluasi ulang redirect setiap auth state berubah:
  // login / sesi dipulihkan -> /app, logout -> /login.
  final authChanges = ValueNotifier<User?>(ref.read(authStateProvider));

  ref.listen<User?>(
    authStateProvider,
    (previous, next) => authChanges.value = next,
  );
  ref.onDispose(authChanges.dispose);

  return GoRouter(
    initialLocation: Routes.login,
    refreshListenable: authChanges,
    redirect: (context, state) {
      final isLoggedIn = ref.read(authStateProvider) != null;
      final location = state.matchedLocation;
      final atAuthPage =
          location == Routes.login || location == Routes.register;

      if (!isLoggedIn) {
        return atAuthPage ? null : Routes.login;
      }

      if (atAuthPage) {
        return Routes.app;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginPage(),
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
      GoRoute(
        path: Routes.canteenApplication,
        builder: (context, state) => const CustomerCanteenApplicationPage(),
      ),
      GoRoute(
        path: Routes.changePassword,
        builder: (context, state) => const ChangePasswordPage(),
      ),
    ],
  );
});
