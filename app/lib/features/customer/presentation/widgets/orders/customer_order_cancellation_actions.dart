import 'package:kantin_cerdas/core/widgets/kc_role_session_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_cancellation.dart';
import 'package:kantin_cerdas/features/customer/presentation/controllers/customer_order_cancellation_controller.dart';
import 'package:kantin_cerdas/features/customer/presentation/widgets/orders/customer_order_cancellation_dialog.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';

class CustomerOrderCancellationActions extends ConsumerStatefulWidget {
  const CustomerOrderCancellationActions({super.key, required this.order});
  final OrderRecord order;
  @override
  ConsumerState<CustomerOrderCancellationActions> createState() =>
      _CustomerOrderCancellationActionsState();
}

class _CustomerOrderCancellationActionsState
    extends ConsumerState<CustomerOrderCancellationActions> {
  bool _confirming = false;
  Future<void> _cancel() async {
    final attempt = ref.read(customerOrderCancellationProvider);
    if (_confirming || attempt.blocked) {
      return;
    }
    final order = widget.order;
    final session = KcRoleSession(ref, role: UserRole.customer);
    final revision = attempt.revision;
    if (!session.isCurrent(ref) ||
        !CustomerOrderCancellation.canCancel(
          order,
          customerId: session.actorId!,
        )) {
      return;
    }
    setState(() => _confirming = true);
    try {
      final confirmed = await showKcRoleDialog<bool>(
        context: context,
        ref: ref,
        role: UserRole.customer,
        builder: (_) => CustomerOrderCancellationDialog(
          orderNumber: order.orderNumber,
          stallName: order.stallName,
        ),
      );
      if (!mounted || confirmed != true || !session.isCurrent(ref)) {
        return;
      }
      final latest = ref.read(customerOrderCancellationProvider);
      if (latest.blocked || latest.revision != revision) {
        return;
      }
      await ref
          .read(customerOrderCancellationControllerProvider.notifier)
          .cancel(
            CustomerOrderCancellation(
              orderId: order.id,
              expectedVersion: order.version,
            ),
            revision: revision,
          );
    } finally {
      if (mounted) {
        setState(() => _confirming = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider);
    final user = auth.asData?.value;
    final attempt = ref.watch(customerOrderCancellationProvider);
    if (auth.isLoading ||
        auth.hasError ||
        user == null ||
        !user.isActive ||
        !user.role.canUseCustomerFeatures ||
        user.id != widget.order.customerId ||
        widget.order.status.isTerminal) {
      return const SizedBox.shrink();
    }
    if (widget.order.status != OrderStatus.waiting) {
      return const Text(
        'Pembatalan tidak tersedia karena pesanan sudah diproses stan.',
      );
    }
    if (!CustomerOrderCancellation.canCancel(
      widget.order,
      customerId: user.id,
    )) {
      return const Text(
        'Pembatalan belum tersedia untuk status pembayaran ini. '
        'Muat ulang status atau hubungi stan untuk bantuan.',
      );
    }
    if (!attempt.configured) {
      return const Text('Layanan pembatalan belum tersedia saat ini.');
    }
    final blocked =
        _confirming ||
        attempt.blocked ||
        (attempt.confirmed && attempt.request?.orderId == widget.order.id);
    return OutlinedButton.icon(
      onPressed: blocked ? null : _cancel,
      icon: const Icon(Icons.cancel_outlined),
      label: const Text('Batalkan pesanan'),
    );
  }
}
