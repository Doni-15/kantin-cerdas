import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/session/role_read_session.dart';
import 'package:kantin_cerdas/core/session/shared_data_revision_provider.dart';
import 'package:kantin_cerdas/core/session/user_role.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences_snapshot.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/food_preferences_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/providers/customer_domain_providers.dart';

export 'package:kantin_cerdas/features/customer/domain/providers/customer_domain_providers.dart'
    show foodPreferencesRepositoryProvider;

final foodPreferencesProvider =
    FutureProvider.autoDispose<FoodPreferencesSnapshot?>((ref) async {
      ref.watch(sharedDataRevisionProvider);
      final session = RoleReadSession.capture(
        ref,
        rolePredicate: (role) => role.canUseCustomerFeatures,
        forbiddenError: () => const FoodPreferencesForbiddenFailure(),
      );
      final repository = ref.watch(foodPreferencesRepositoryProvider);
      try {
        final snapshot = await repository.getMyPreferences().timeout(
          const Duration(seconds: 30),
        );
        session.check(ref);
        if (snapshot != null && snapshot.customerId != session.actorId) {
          throw const FoodPreferencesForbiddenFailure();
        }
        return snapshot;
      } on TimeoutException {
        throw const FoodPreferencesReadTimeoutFailure();
      }
    }, retry: (_, _) => null);
