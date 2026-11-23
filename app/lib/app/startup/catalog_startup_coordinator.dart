import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
import 'package:kantin_cerdas/features/auth/presentation/auth_presentation.dart';
import 'package:kantin_cerdas/features/catalog/application/catalog_providers.dart';
import 'package:kantin_cerdas/features/catalog/domain/catalog_models.dart';
import 'package:kantin_cerdas/features/customer/presentation/customer_presentation.dart';

const catalogStartupBudget = Duration(milliseconds: 1500);

final catalogStartupProvider = FutureProvider.autoDispose.family<void, String>((
  ref,
  accountId,
) async {
  final firstPage = ref.watch(firstStallPageProvider(accountId).future);
  try {
    await firstPage.timeout(catalogStartupBudget);
  } on TimeoutException {
    // The catalog takes over the request when the startup budget expires.
  } on AuthException {
    // The catalog shows the error and offers a retry.
  }
}, retry: (_, _) => null);

Widget buildCustomerHomeDestination(WidgetRef ref, AuthSession session) {
  final accountId = session.account.id;
  if (ref.watch(catalogStartupProvider(accountId)).isLoading) {
    return const SplashScreen(phase: SplashPhase.catalog);
  }
  final pageProvider = firstStallPageProvider(accountId);
  final firstPage = ref.watch(pageProvider);
  final FutureOr<CatalogPage> initialPage =
      firstPage.asData?.value ?? ref.read(pageProvider.future);
  return CustomerShellPage(
    key: ValueKey((session.account.id, session.account.role)),
    session: session,
    initialPage: initialPage,
  );
}
