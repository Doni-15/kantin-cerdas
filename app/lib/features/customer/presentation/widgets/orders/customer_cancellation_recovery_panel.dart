import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/customer/presentation/controllers/customer_order_cancellation_controller.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/orders/customer_order_cancellation_notice.dart';

class CustomerCancellationRecoveryPanel extends ConsumerWidget {
  const CustomerCancellationRecoveryPanel({super.key, this.orderId});
  final String? orderId;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customerOrderCancellationProvider);
    if (!state.hasNotice ||
        (orderId != null &&
            state.request != null &&
            state.request!.orderId != orderId &&
            !state.busy &&
            !state.unresolved &&
            !state.journalLoading &&
            state.journalError == null)) {
      return const SizedBox.shrink();
    }
    return CustomerOrderCancellationNotice(
      state: state,
      onRecover: state.busy
          ? null
          : () => ref
                .read(customerOrderCancellationControllerProvider.notifier)
                .recover(),
      onReloadJournal: state.busy
          ? null
          : () => ref
                .read(customerOrderCancellationControllerProvider.notifier)
                .reloadJournal(),
    );
  }
}
