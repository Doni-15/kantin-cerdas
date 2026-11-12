import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/owner/domain/repositories/owner_mutation_journal.dart';
import 'package:kantin_cerdas/features/owner/domain/repositories/owner_repository.dart';

final ownerRepositoryProvider = Provider<OwnerRepository>((ref) {
  throw UnimplementedError(
    'ownerRepositoryProvider must be overridden via production or test overrides.',
  );
});

final ownerMutationJournalRepositoryProvider = Provider<OwnerMutationJournal>((
  ref,
) {
  throw UnimplementedError(
    'ownerMutationJournalRepositoryProvider must be overridden via production or test overrides.',
  );
});
