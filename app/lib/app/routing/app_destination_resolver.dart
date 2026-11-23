import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_account.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
import 'package:kantin_cerdas/features/auth/presentation/pages/splash_screen.dart';

sealed class AppDestination {
  const AppDestination();
}

final class AppSplashDestination extends AppDestination {
  const AppSplashDestination(this.phase);
  final SplashPhase phase;
}

final class AppSessionRecoveryDestination extends AppDestination {
  const AppSessionRecoveryDestination(this.error);
  final Object error;
}

final class AppCredentialsDestination extends AppDestination {
  const AppCredentialsDestination();
}

final class AppProfileCompletionDestination extends AppDestination {
  const AppProfileCompletionDestination(this.account);
  final AuthAccount account;
}

final class AppCustomerHomeDestination extends AppDestination {
  const AppCustomerHomeDestination(this.session);
  final AuthSession session;
}

final class AppOwnerHomeDestination extends AppDestination {
  const AppOwnerHomeDestination(this.session);
  final AuthSession session;
}

final class AppAdminHomeDestination extends AppDestination {
  const AppAdminHomeDestination(this.session);
  final AuthSession session;
}

final class AppAccountDestination extends AppDestination {
  const AppAccountDestination(this.account);
  final AuthAccount account;
}

/// Resolves the app-level destination from the current authentication state
/// and Owner/Customer shell switch state without constructing widgets.
AppDestination resolveAppDestination({
  required AsyncValue<AuthSession?> session,
  bool ownerCustomerView = false,
}) {
  return session.when(
    skipLoadingOnRefresh: false,
    data: (activeSession) => switch (activeSession) {
      null => const AppCredentialsDestination(),
      AuthSession(:final account) when !account.profileComplete =>
        AppProfileCompletionDestination(account),

      AuthSession(:final account) when account.role == AuthRole.customer =>
        AppCustomerHomeDestination(activeSession),

      AuthSession(:final account)
          when account.role == AuthRole.owner && ownerCustomerView =>
        AppCustomerHomeDestination(activeSession),

      AuthSession(:final account) when account.role == AuthRole.owner =>
        AppOwnerHomeDestination(activeSession),

      AuthSession(:final account) when account.role == AuthRole.admin =>
        AppAdminHomeDestination(activeSession),

      AuthSession(:final account) => AppAccountDestination(account),
    },

    loading: () => const AppSplashDestination(SplashPhase.session),
    error: (error, _) => AppSessionRecoveryDestination(error),
  );
}
