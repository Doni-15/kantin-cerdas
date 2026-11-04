import 'package:flutter_riverpod/misc.dart' show Override;
import 'simulation.dart';
import 'package:kantin_cerdas/core/media/image_picker_port.dart';
import 'package:kantin_cerdas/core/media/media_upload_repository.dart';
import 'package:kantin_cerdas/features/admin/presentation/providers/admin_mutation_journal_provider.dart';
import 'package:kantin_cerdas/features/admin/presentation/providers/admin_providers.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_providers.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/canteen_application_journal_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_catalog_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_checkout_journal_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_feature_providers.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_order_providers.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/food_preferences_journal_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/food_preferences_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/order_cancellation_journal_provider.dart';
import 'package:kantin_cerdas/features/owner/presentation/providers/owner_mutation_journal_provider.dart';
import 'package:kantin_cerdas/features/owner/presentation/providers/owner_providers.dart';

List<Override> simulationOverrides(
  SimulationStore store, {
  ImagePickerPort? imagePicker,
  MediaUploadRepository? mediaUpload,
}) => [
  imagePickerPortProvider.overrideWithValue(
    imagePicker ?? SimulationImagePickerPort(store),
  ),
  mediaUploadRepositoryProvider.overrideWithValue(
    mediaUpload ?? SimulationMediaUploadRepository(store),
  ),
  authRepositoryProvider.overrideWithValue(SimulationAuthRepository(store)),
  customerCatalogRepositoryProvider.overrideWithValue(
    SimulationCatalogRepository(store),
  ),
  customerOrderRepositoryProvider.overrideWithValue(
    SimulationOrderRepository(store),
  ),
  customerOrderTrackingRepositoryProvider.overrideWithValue(
    SimulationTrackingRepository(store),
  ),
  customerAssistantRepositoryProvider.overrideWithValue(
    SimulationAssistantRepository(store),
  ),
  canteenApplicationRepositoryProvider.overrideWithValue(
    SimulationApplicationRepository(store),
  ),
  foodPreferencesRepositoryProvider.overrideWithValue(
    SimulationPreferencesRepository(store),
  ),
  ownerRepositoryProvider.overrideWithValue(SimulationOwnerRepository(store)),
  adminRepositoryProvider.overrideWithValue(SimulationAdminRepository(store)),
  adminMutationJournalRepositoryProvider.overrideWithValue(
    SimulationAdminMutationJournal(SimulationKeyValueStorage(store)),
  ),
  ownerMutationJournalRepositoryProvider.overrideWithValue(
    SimulationOwnerMutationJournal(SimulationKeyValueStorage(store)),
  ),
  foodPreferencesJournalRepositoryProvider.overrideWithValue(
    SimulationFoodPreferencesJournal(SimulationKeyValueStorage(store)),
  ),
  canteenApplicationJournalRepositoryProvider.overrideWithValue(
    SimulationCanteenApplicationJournal(SimulationKeyValueStorage(store)),
  ),
  orderSubmissionJournalProvider.overrideWithValue(
    SimulationOrderSubmissionJournal(SimulationKeyValueStorage(store)),
  ),
  orderCancellationJournalRepositoryProvider.overrideWithValue(
    SimulationOrderCancellationJournal(SimulationKeyValueStorage(store)),
  ),
];
