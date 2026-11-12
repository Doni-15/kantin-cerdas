import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/controllers/customer_order_controller.dart';

/// Panggil dari build halaman cart/confirmation, bukan panel yang dapat dibuang
/// saat journal mengunci keranjang. Controller menolak hasil sesi usang.
void listenCustomerCheckoutResult(BuildContext context, WidgetRef ref) {
  ref.listen<AsyncValue<String?>>(customerOrderControllerProvider, (
    previous,
    next,
  ) {
    final orderId = next.isLoading || next.hasError ? null : next.asData?.value;
    if (orderId == null ||
        previous?.asData?.value == orderId ||
        !context.mounted ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    final auth = ref.read(authStateProvider);
    final user = auth.asData?.value;
    if (auth.isLoading ||
        auth.hasError ||
        user == null ||
        !user.isActive ||
        !user.role.canUseCustomerFeatures) {
      return;
    }
    context.go(Routes.customerOrderSuccessLocation(orderId));
  });
}
