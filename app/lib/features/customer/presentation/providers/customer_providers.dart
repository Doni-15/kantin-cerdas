import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/storage/local_storage_provider.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/canteen_application_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/canteen_application_dummy_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/repositories/canteen_application_repository_impl.dart';
import 'package:kantin_cerdas/features/customer/domain/repositories/canteen_application_repository.dart';
import 'package:kantin_cerdas/features/customer/domain/usecases/submit_canteen_application_usecase.dart';

/// Satu-satunya tempat yang perlu diubah saat dummy diganti API.
/// `currentUserId` hilang karena Backend membaca user dari access token.
final canteenApplicationDataSourceProvider =
    Provider<CanteenApplicationDataSource>((ref) {
      return CanteenApplicationDummyDataSource(
        currentUserId: () => ref.read(authStateProvider)?.id,
        storage: ref.watch(localStorageProvider),
      );
    });

final canteenApplicationRepositoryProvider =
    Provider<CanteenApplicationRepository>((ref) {
      return CanteenApplicationRepositoryImpl(
        ref.watch(canteenApplicationDataSourceProvider),
      );
    });

final submitCanteenApplicationUseCaseProvider =
    Provider<SubmitCanteenApplicationUseCase>((ref) {
      return SubmitCanteenApplicationUseCase(
        ref.watch(canteenApplicationRepositoryProvider),
      );
    });
