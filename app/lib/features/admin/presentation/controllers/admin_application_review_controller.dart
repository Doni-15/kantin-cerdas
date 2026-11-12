import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/pending_admin_mutation.dart';
import 'package:kantin_cerdas/features/admin/presentation/controllers/admin_mutation_controller.dart';
import 'package:kantin_cerdas/features/admin/presentation/controllers/admin_application_review_state.dart';

/// View state kompatibel untuk notice per target; pengiriman dimiliki coordinator.
final adminApplicationReviewControllerProvider =
    Provider<Map<String, AdminApplicationReviewState>>((ref) {
      final action = ref.watch(adminMutationProvider);
      final request = action.request;
      if (request == null ||
          request.kind != AdminMutationKind.reviewApplication) {
        return const {};
      }
      return Map.unmodifiable({
        request.targetId: AdminApplicationReviewState(
          busy: action.busy,
          unresolvedVersion: action.unresolved ? request.expectedVersion : null,
          error: action.error,
          reconciled: action.reconciled,
          saved: action.succeeded,
        ),
      });
    });
