import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/admin/domain/repositories/admin_mutation_journal.dart';
import 'package:kantin_cerdas/features/admin/domain/repositories/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  throw UnimplementedError(
    'adminRepositoryProvider must be overridden via production or test overrides.',
  );
});

final adminMutationJournalRepositoryProvider = Provider<AdminMutationJournal>((
  ref,
) {
  throw UnimplementedError(
    'adminMutationJournalRepositoryProvider must be overridden via production or test overrides.',
  );
});
