import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/app/routing/app_destination_resolver.dart';
import 'package:kantin_cerdas/app/startup/catalog_startup_coordinator.dart';
import 'package:kantin_cerdas/features/admin/presentation/admin_presentation.dart';
import 'package:kantin_cerdas/features/auth/application/services/auth_email_link_service.dart';
import 'package:kantin_cerdas/features/auth/presentation/auth_presentation.dart';
import 'package:kantin_cerdas/features/owner/presentation/owner_presentation.dart';

/// Builds the concrete widget for a resolved [AppDestination].
Widget buildAppDestinationScreen({
  required WidgetRef ref,
  required AppDestination destination,
  required AuthEmailLinkReturnState linkReturnState,
}) {
  return switch (destination) {
    AppSplashDestination(:final phase) => SplashScreen(phase: phase),
    AppSessionRecoveryDestination(:final error) => SessionRecoveryView(
      error: error,
    ),
    AppCredentialsDestination() => AuthCredentialsForm(
      initialNotice: linkReturnState.emailNotice,
      requestNewLink: linkReturnState.requestNewLink,
      returnGeneration: linkReturnState.returnGeneration,
    ),
    AppProfileCompletionDestination(:final account) => AuthProfileForm(
      key: ValueKey(account.id),
      account: account,
    ),
    AppCustomerHomeDestination(:final session) => buildCustomerHomeDestination(
      ref,
      session,
    ),
    AppOwnerHomeDestination(:final session) => OwnerShellPage(
      key: ValueKey((session.account.id, session.account.role)),
      session: session,
    ),
    AppAdminHomeDestination(:final session) => AdminShellPage(
      key: ValueKey((session.account.id, session.account.role)),
      session: session,
    ),
    AppAccountDestination(:final account) => AuthAccountScreen(
      key: ValueKey(account.id),
      account: account,
    ),
  };
}
