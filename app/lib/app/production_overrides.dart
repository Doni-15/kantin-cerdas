import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:kantin_cerdas/core/media/device_image_picker_adapter.dart';
import 'package:kantin_cerdas/core/media/image_picker_port.dart';
import 'package:kantin_cerdas/core/media/media_upload_api_service.dart';
import 'package:kantin_cerdas/core/media/media_upload_repository.dart';
import 'package:kantin_cerdas/features/admin/data/providers/admin_data_providers.dart';
import 'package:kantin_cerdas/features/auth/data/providers/auth_data_providers.dart';
import 'package:kantin_cerdas/features/customer/data/providers/customer_data_providers.dart';
import 'package:kantin_cerdas/features/owner/data/providers/owner_data_providers.dart';

/// Menyusun override produksi untuk menghubungkan kontrak domain ke layer data.
List<Override> buildProductionOverrides() => <Override>[
  imagePickerPortProvider.overrideWith((ref) {
    return ref.watch(deviceImagePickerAdapterProvider);
  }),
  mediaUploadRepositoryProvider.overrideWith((ref) {
    return ref.watch(dioMediaUploadRepositoryProvider);
  }),
  tokenStorageProvider.overrideWith((ref) {
    return ref.watch(secureTokenStorageProvider);
  }),
  authRepositoryProvider.overrideWith((ref) {
    return ref.watch(authRepositoryImplProvider);
  }),
  authTokenRefresherProvider.overrideWith((ref) {
    return ref.watch(authRepositoryImplProvider).refreshTokens;
  }),
  adminRepositoryProvider.overrideWith((ref) {
    return ref.watch(adminRepositoryImplProvider);
  }),
  adminMutationJournalRepositoryProvider.overrideWith((ref) {
    return ref.watch(secureAdminMutationJournalProvider);
  }),
  ownerRepositoryProvider.overrideWith((ref) {
    return ref.watch(ownerRepositoryImplProvider);
  }),
  ownerMutationJournalRepositoryProvider.overrideWith((ref) {
    return ref.watch(secureOwnerMutationJournalProvider);
  }),
  customerCatalogRepositoryProvider.overrideWith((ref) {
    return ref.watch(customerCatalogRepositoryImplProvider);
  }),
  customerOrderRepositoryProvider.overrideWith((ref) {
    return ref.watch(customerOrderRepositoryImplProvider);
  }),
  customerOrderTrackingRepositoryProvider.overrideWith((ref) {
    return ref.watch(customerOrderTrackingRepositoryImplProvider);
  }),
  customerAssistantRepositoryProvider.overrideWith((ref) {
    return ref.watch(customerAssistantRepositoryImplProvider);
  }),
  canteenApplicationRepositoryProvider.overrideWith((ref) {
    return ref.watch(canteenApplicationRepositoryImplProvider);
  }),
  foodPreferencesRepositoryProvider.overrideWith((ref) {
    return ref.watch(foodPreferencesRepositoryImplProvider);
  }),
  orderSubmissionJournalProvider.overrideWith((ref) {
    return ref.watch(secureOrderSubmissionJournalProvider);
  }),
  orderCancellationJournalRepositoryProvider.overrideWith((ref) {
    return ref.watch(secureOrderCancellationJournalProvider);
  }),
  canteenApplicationJournalRepositoryProvider.overrideWith((ref) {
    return ref.watch(secureCanteenApplicationJournalProvider);
  }),
  foodPreferencesJournalRepositoryProvider.overrideWith((ref) {
    return ref.watch(secureFoodPreferencesJournalProvider);
  }),
];
