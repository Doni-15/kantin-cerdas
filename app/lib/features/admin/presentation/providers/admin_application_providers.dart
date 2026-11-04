import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/core/session/shared_data_revision_provider.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_application_page.dart';
import 'package:kantin_cerdas/features/admin/domain/failures/admin_failure.dart';
import 'package:kantin_cerdas/features/admin/presentation/providers/admin_providers.dart';
import 'package:kantin_cerdas/features/admin/presentation/providers/admin_read_session.dart';

typedef AdminApplicationQuery = ({
  CanteenApplicationStatus? status,
  String? cursor,
});

final adminApplicationsProvider = FutureProvider.autoDispose
    .family<AdminApplicationPage, AdminApplicationQuery>((ref, query) async {
      ref.watch(sharedDataRevisionProvider);
      final session = AdminReadSession(ref);
      if (query.cursor != null && query.cursor!.trim().isEmpty) {
        throw const AdminInvalidDataFailure();
      }
      final repository = ref.watch(adminRepositoryProvider);
      try {
        final page = await repository
            .listApplications(
              status: query.status,
              cursor: query.cursor,
              limit: 30,
            )
            .timeout(const Duration(seconds: 30));
        session.check(ref);
        if (page.items.length > 30 ||
            page.items.map((item) => item.id).toSet().length !=
                page.items.length ||
            (page.nextCursor != null && page.nextCursor == query.cursor) ||
            (query.status != null &&
                page.items.any((item) => item.status != query.status))) {
          throw const AdminInvalidDataFailure();
        }
        return page;
      } on TimeoutException {
        throw const AdminReadTimeoutFailure();
      }
    }, retry: (_, _) => null);

final adminApplicationDetailProvider = FutureProvider.autoDispose
    .family<CanteenApplication?, String>((ref, id) async {
      ref.watch(sharedDataRevisionProvider);
      final session = AdminReadSession(ref);
      if (id.trim().isEmpty) {
        throw const AdminInvalidDataFailure();
      }
      final repository = ref.watch(adminRepositoryProvider);
      try {
        final application = await repository
            .getApplication(applicationId: id)
            .timeout(const Duration(seconds: 30));
        session.check(ref);
        if (application != null && application.id != id) {
          throw const AdminInvalidDataFailure();
        }
        return application;
      } on TimeoutException {
        throw const AdminReadTimeoutFailure();
      }
    }, retry: (_, _) => null);
