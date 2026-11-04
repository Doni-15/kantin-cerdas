import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/customer/domain/repositories/canteen_application_journal.dart';
import 'package:kantin_cerdas/features/customer/domain/repositories/canteen_application_repository.dart';
import 'package:kantin_cerdas/features/customer/domain/repositories/customer_assistant_repository.dart';
import 'package:kantin_cerdas/features/customer/domain/repositories/customer_catalog_repository.dart';
import 'package:kantin_cerdas/features/customer/domain/repositories/customer_order_repository.dart';
import 'package:kantin_cerdas/features/customer/domain/repositories/customer_order_tracking_repository.dart';
import 'package:kantin_cerdas/features/customer/domain/repositories/food_preferences_journal.dart';
import 'package:kantin_cerdas/features/customer/domain/repositories/food_preferences_repository.dart';
import 'package:kantin_cerdas/features/customer/domain/repositories/order_cancellation_journal.dart';
import 'package:kantin_cerdas/features/customer/domain/repositories/order_submission_journal.dart';

final customerCatalogRepositoryProvider = Provider<CustomerCatalogRepository>((
  ref,
) {
  throw UnimplementedError(
    'customerCatalogRepositoryProvider must be overridden via production or test overrides.',
  );
});

final customerOrderRepositoryProvider = Provider<CustomerOrderRepository>((
  ref,
) {
  throw UnimplementedError(
    'customerOrderRepositoryProvider must be overridden via production or test overrides.',
  );
});

final customerOrderTrackingRepositoryProvider =
    Provider<CustomerOrderTrackingRepository>((ref) {
      throw UnimplementedError(
        'customerOrderTrackingRepositoryProvider must be overridden via production or test overrides.',
      );
    });

final customerAssistantRepositoryProvider = Provider<CustomerAssistantRepository>((
  ref,
) {
  throw UnimplementedError(
    'customerAssistantRepositoryProvider must be overridden via production or test overrides.',
  );
});

final canteenApplicationRepositoryProvider =
    Provider<CanteenApplicationRepository>((ref) {
      throw UnimplementedError(
        'canteenApplicationRepositoryProvider must be overridden via production or test overrides.',
      );
    });

final foodPreferencesRepositoryProvider = Provider<FoodPreferencesRepository>((
  ref,
) {
  throw UnimplementedError(
    'foodPreferencesRepositoryProvider must be overridden via production or test overrides.',
  );
});

final orderSubmissionJournalProvider = Provider<OrderSubmissionJournal>((ref) {
  throw UnimplementedError(
    'orderSubmissionJournalProvider must be overridden via production or test overrides.',
  );
});

final orderCancellationJournalRepositoryProvider =
    Provider<OrderCancellationJournal>((ref) {
      throw UnimplementedError(
        'orderCancellationJournalRepositoryProvider must be overridden via production or test overrides.',
      );
    });

final canteenApplicationJournalRepositoryProvider =
    Provider<CanteenApplicationJournal>((ref) {
      throw UnimplementedError(
        'canteenApplicationJournalRepositoryProvider must be overridden via production or test overrides.',
      );
    });

final foodPreferencesJournalRepositoryProvider = Provider<FoodPreferencesJournal>((
  ref,
) {
  throw UnimplementedError(
    'foodPreferencesJournalRepositoryProvider must be overridden via production or test overrides.',
  );
});
