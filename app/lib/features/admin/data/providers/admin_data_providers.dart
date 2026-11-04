import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/network/dio_client_provider.dart';
import 'package:kantin_cerdas/core/storage/secure_storage_provider.dart';
import 'package:kantin_cerdas/features/admin/data/datasources/admin_api_datasource.dart';
import 'package:kantin_cerdas/features/admin/data/datasources/admin_datasource.dart';
import 'package:kantin_cerdas/features/admin/data/repositories/admin_repository_impl.dart';
import 'package:kantin_cerdas/features/admin/data/storage/secure_admin_mutation_journal.dart';
import 'package:kantin_cerdas/features/admin/domain/repositories/admin_mutation_journal.dart';
import 'package:kantin_cerdas/features/admin/domain/repositories/admin_repository.dart';

export 'package:kantin_cerdas/features/admin/domain/providers/admin_domain_providers.dart'
    show adminMutationJournalRepositoryProvider, adminRepositoryProvider;

final adminDataSourceProvider = Provider<AdminDataSource>((ref) {
  return AdminApiDataSource(dio: ref.watch(dioClientProvider));
});

final adminRepositoryImplProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(dataSource: ref.watch(adminDataSourceProvider));
});

final secureAdminMutationJournalProvider = Provider<AdminMutationJournal>((
  ref,
) {
  return SecureAdminMutationJournal(ref.watch(secureStorageProvider));
});
