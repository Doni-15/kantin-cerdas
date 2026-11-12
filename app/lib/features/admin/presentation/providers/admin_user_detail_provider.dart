import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/session/shared_data_revision_provider.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_user_record.dart';
import 'package:kantin_cerdas/features/admin/domain/failures/admin_failure.dart';
import 'package:kantin_cerdas/features/admin/presentation/providers/admin_providers.dart';
import 'package:kantin_cerdas/features/admin/presentation/providers/admin_read_session.dart';

final adminUserDetailProvider = FutureProvider.autoDispose
    .family<AdminUserRecord?, String>((ref, id) async {
      ref.watch(sharedDataRevisionProvider);
      final session = AdminReadSession(ref);
      if (id.trim().isEmpty) {
        throw const AdminInvalidDataFailure();
      }
      final repository = ref.watch(adminRepositoryProvider);
      try {
        final record = await repository
            .getUser(userId: id)
            .timeout(const Duration(seconds: 30));
        session.check(ref);
        if (record != null && record.user.id != id) {
          throw const AdminInvalidDataFailure();
        }
        return record;
      } on TimeoutException {
        throw const AdminReadTimeoutFailure();
      }
    }, retry: (_, _) => null);
