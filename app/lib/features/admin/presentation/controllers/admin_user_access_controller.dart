import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/pending_admin_mutation.dart';
import 'package:kantin_cerdas/features/admin/presentation/controllers/admin_mutation_controller.dart';
import 'package:kantin_cerdas/features/admin/presentation/controllers/admin_user_access_state.dart';

/// View state kompatibel untuk notice per target; pengiriman dimiliki coordinator.
final adminUserAccessControllerProvider =
    Provider<Map<String, AdminUserAccessState>>((ref) {
      final action = ref.watch(adminMutationProvider);
      final request = action.request;
      if (request == null || request.kind != AdminMutationKind.changeAccess) {
        return const {};
      }
      return Map.unmodifiable({
        request.targetId: AdminUserAccessState(
          busy: action.busy,
          unresolvedVersion: action.unresolved ? request.expectedVersion : null,
          error: action.error,
          reconciled: action.reconciled,
          savedIsActive: action.succeeded ? request.isActive : null,
        ),
      });
    });
