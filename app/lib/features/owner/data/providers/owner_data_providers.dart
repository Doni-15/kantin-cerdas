import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/network/dio_client_provider.dart';
import 'package:kantin_cerdas/core/storage/secure_storage_provider.dart';
import 'package:kantin_cerdas/features/owner/data/datasources/owner_api_datasource.dart';
import 'package:kantin_cerdas/features/owner/data/datasources/owner_datasource.dart';
import 'package:kantin_cerdas/features/owner/data/repositories/owner_repository_impl.dart';
import 'package:kantin_cerdas/features/owner/data/storage/secure_owner_mutation_journal.dart';
import 'package:kantin_cerdas/features/owner/domain/repositories/owner_mutation_journal.dart';
import 'package:kantin_cerdas/features/owner/domain/repositories/owner_repository.dart';

export 'package:kantin_cerdas/features/owner/domain/providers/owner_domain_providers.dart'
    show ownerMutationJournalRepositoryProvider, ownerRepositoryProvider;

final ownerDataSourceProvider = Provider<OwnerDataSource>((ref) {
  return OwnerApiDataSource(dio: ref.watch(dioClientProvider));
});

final ownerRepositoryImplProvider = Provider<OwnerRepository>((ref) {
  return OwnerRepositoryImpl(dataSource: ref.watch(ownerDataSourceProvider));
});

final secureOwnerMutationJournalProvider = Provider<OwnerMutationJournal>((
  ref,
) {
  return SecureOwnerMutationJournal(ref.watch(secureStorageProvider));
});
