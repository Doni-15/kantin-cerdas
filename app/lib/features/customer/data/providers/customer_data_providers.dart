import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/network/dio_client_provider.dart';
import 'package:kantin_cerdas/core/storage/secure_storage_provider.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/canteen_application_api_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/canteen_application_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_assistant_api_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_assistant_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_catalog_api_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_catalog_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_order_api_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_order_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_order_tracking_api_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_order_tracking_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/food_preferences_api_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/food_preferences_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/repositories/canteen_application_repository_impl.dart';
import 'package:kantin_cerdas/features/customer/data/repositories/customer_assistant_repository_impl.dart';
import 'package:kantin_cerdas/features/customer/data/repositories/customer_catalog_repository_impl.dart';
import 'package:kantin_cerdas/features/customer/data/repositories/customer_order_repository_impl.dart';
import 'package:kantin_cerdas/features/customer/data/repositories/customer_order_tracking_repository_impl.dart';
import 'package:kantin_cerdas/features/customer/data/repositories/food_preferences_repository_impl.dart';
import 'package:kantin_cerdas/features/customer/data/storage/secure_canteen_application_journal.dart';
import 'package:kantin_cerdas/features/customer/data/storage/secure_food_preferences_journal.dart';
import 'package:kantin_cerdas/features/customer/data/storage/secure_order_cancellation_journal.dart';
import 'package:kantin_cerdas/features/customer/data/storage/secure_order_submission_journal.dart';
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

export 'package:kantin_cerdas/features/customer/domain/providers/customer_domain_providers.dart'
    show
        canteenApplicationJournalRepositoryProvider,
        canteenApplicationRepositoryProvider,
        customerAssistantRepositoryProvider,
        customerCatalogRepositoryProvider,
        customerOrderRepositoryProvider,
        customerOrderTrackingRepositoryProvider,
        foodPreferencesJournalRepositoryProvider,
        foodPreferencesRepositoryProvider,
        orderCancellationJournalRepositoryProvider,
        orderSubmissionJournalProvider;

final customerCatalogDataSourceProvider = Provider<CustomerCatalogDataSource>((
  ref,
) {
  return CustomerCatalogApiDataSource(dio: ref.watch(dioClientProvider));
});

final customerCatalogRepositoryImplProvider =
    Provider<CustomerCatalogRepository>((ref) {
      return CustomerCatalogRepositoryImpl(
        dataSource: ref.watch(customerCatalogDataSourceProvider),
      );
    });

final customerOrderDataSourceProvider = Provider<CustomerOrderDataSource>((
  ref,
) {
  return CustomerOrderApiDataSource(dio: ref.watch(dioClientProvider));
});

final customerOrderRepositoryImplProvider = Provider<CustomerOrderRepository>((
  ref,
) {
  return CustomerOrderRepositoryImpl(
    dataSource: ref.watch(customerOrderDataSourceProvider),
  );
});

final customerOrderTrackingDataSourceProvider =
    Provider<CustomerOrderTrackingDataSource>((ref) {
      return CustomerOrderTrackingApiDataSource(
        dio: ref.watch(dioClientProvider),
      );
    });

final customerOrderTrackingRepositoryImplProvider =
    Provider<CustomerOrderTrackingRepository>((ref) {
      return CustomerOrderTrackingRepositoryImpl(
        dataSource: ref.watch(customerOrderTrackingDataSourceProvider),
      );
    });

final customerAssistantDataSourceProvider =
    Provider<CustomerAssistantDataSource>((ref) {
      return CustomerAssistantApiDataSource(dio: ref.watch(dioClientProvider));
    });

final customerAssistantRepositoryImplProvider =
    Provider<CustomerAssistantRepository>((ref) {
      return CustomerAssistantRepositoryImpl(
        dataSource: ref.watch(customerAssistantDataSourceProvider),
      );
    });

final canteenApplicationDataSourceProvider =
    Provider<CanteenApplicationDataSource>((ref) {
      return CanteenApplicationApiDataSource(dio: ref.watch(dioClientProvider));
    });

final canteenApplicationRepositoryImplProvider =
    Provider<CanteenApplicationRepository>((ref) {
      return CanteenApplicationRepositoryImpl(
        dataSource: ref.watch(canteenApplicationDataSourceProvider),
      );
    });

final foodPreferencesDataSourceProvider = Provider<FoodPreferencesDataSource>((
  ref,
) {
  return FoodPreferencesApiDataSource(dio: ref.watch(dioClientProvider));
});

final foodPreferencesRepositoryImplProvider =
    Provider<FoodPreferencesRepository>((ref) {
      return FoodPreferencesRepositoryImpl(
        dataSource: ref.watch(foodPreferencesDataSourceProvider),
      );
    });

final secureOrderSubmissionJournalProvider = Provider<OrderSubmissionJournal>((
  ref,
) {
  return SecureOrderSubmissionJournal(ref.watch(secureStorageProvider));
});

final secureOrderCancellationJournalProvider =
    Provider<OrderCancellationJournal>((ref) {
      return SecureOrderCancellationJournal(ref.watch(secureStorageProvider));
    });

final secureCanteenApplicationJournalProvider =
    Provider<CanteenApplicationJournal>((ref) {
      return SecureCanteenApplicationJournal(ref.watch(secureStorageProvider));
    });

final secureFoodPreferencesJournalProvider = Provider<FoodPreferencesJournal>((
  ref,
) {
  return SecureFoodPreferencesJournal(ref.watch(secureStorageProvider));
});
