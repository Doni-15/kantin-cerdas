import 'dart:async';

import 'package:characters/characters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/session/shared_data_revision_provider.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_summary.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_user_page.dart';
import 'package:kantin_cerdas/features/admin/domain/failures/admin_failure.dart';
import 'package:kantin_cerdas/features/admin/domain/providers/admin_domain_providers.dart';
import 'package:kantin_cerdas/features/admin/presentation/providers/admin_read_session.dart';

export 'package:kantin_cerdas/features/admin/domain/providers/admin_domain_providers.dart'
    show adminRepositoryProvider;

final adminSummaryProvider = FutureProvider.autoDispose<AdminSummary>((
  ref,
) async {
  ref.watch(sharedDataRevisionProvider);
  final session = AdminReadSession(ref);
  final repository = ref.watch(adminRepositoryProvider);
  try {
    final summary = await repository.getSummary().timeout(
      const Duration(seconds: 30),
    );
    session.check(ref);
    return summary;
  } on TimeoutException {
    throw const AdminReadTimeoutFailure();
  }
}, retry: (_, _) => null);

typedef AdminUserQuery = ({String search, String? cursor});
final adminUsersProvider = FutureProvider.autoDispose
    .family<AdminUserPage, AdminUserQuery>((ref, query) async {
      ref.watch(sharedDataRevisionProvider);
      final session = AdminReadSession(ref);
      if (query.search.characters.length > 120) {
        throw const AdminInvalidDataFailure();
      }
      if (query.cursor != null && query.cursor!.trim().isEmpty) {
        throw const AdminInvalidDataFailure();
      }
      final repository = ref.watch(adminRepositoryProvider);
      try {
        final page = await repository
            .listUsers(search: query.search, cursor: query.cursor, limit: 30)
            .timeout(const Duration(seconds: 30));
        session.check(ref);
        if (page.users.length > 30 ||
            (page.nextCursor != null && page.nextCursor == query.cursor) ||
            page.users.map((user) => user.id).toSet().length !=
                page.users.length) {
          throw const AdminInvalidDataFailure();
        }
        return page;
      } on TimeoutException {
        throw const AdminReadTimeoutFailure();
      }
    }, retry: (_, _) => null);
