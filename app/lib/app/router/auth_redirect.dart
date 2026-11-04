import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/app/router/auth_destination.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';

/// Redirect hanya menentukan navigasi; otorisasi data tetap wajib di server.
String? authRedirect({
  required AsyncValue<User?> authState,
  required String path,
  Uri? uri,
}) {
  final location = uri ?? Uri(path: path);
  final isAuthPage =
      path == Routes.login ||
      path == Routes.register ||
      path == Routes.registerProfile ||
      path == Routes.resetPassword;
  final isPublicPage =
      isAuthPage || path == Routes.help || path == Routes.terms;
  final isEntry = path == Routes.app;
  final savedDestination = authDestinationFrom(location);
  final currentDestination = validatedAuthDestination(location.toString());
  final session = authState.asData;

  if (authState.isLoading || authState.hasError || session == null) {
    if (isPublicPage || isEntry) {
      return null;
    }
    return authLocation(Routes.app, destination: currentDestination);
  }

  final user = session.value;
  if (user == null || !user.isActive) {
    if (isPublicPage) {
      return null;
    }
    return authLocation(
      Routes.login,
      destination: isEntry ? savedDestination : currentDestination,
    );
  }

  final home = switch (user.role) {
    UserRole.customer => Routes.customerHome,
    UserRole.owner => Routes.ownerDashboard,
    UserRole.admin => Routes.adminDashboard,
  };
  if (isAuthPage || isEntry) {
    return authDestinationForRole(savedDestination, user.role) ?? home;
  }
  final requiredRole = requiredRouteRole(path);
  return requiredRole != null && !user.role.allows(requiredRole) ? home : null;
}
