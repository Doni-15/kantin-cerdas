import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_order_transition.dart';
import 'package:kantin_cerdas/features/owner/presentation/controllers/owner_mutation_controller.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/orders/owner_order_decision_dialog.dart';
import 'package:kantin_cerdas/features/owner/presentation/widgets/owner_session_dialog.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class OwnerOrderActions extends ConsumerStatefulWidget {
  const OwnerOrderActions({super.key, required this.order});
  final OrderRecord order;

  @override
  ConsumerState<OwnerOrderActions> createState() => _OwnerOrderActionsState();
}

class _OwnerOrderActionsState extends ConsumerState<OwnerOrderActions> {
  bool _dialogOpen = false;

  Future<void> _change(OrderStatus target) async {
    if (_dialogOpen ||
        ref.read(ownerMutationProvider).blocked ||
        !OwnerOrderTransition.canMoveTo(widget.order, target)) {
      return;
    }
    final session = OwnerDialogSession(ref);
    final actor = session.ownerId;
    if (actor == null || !session.isCurrent(ref)) {
      return;
    }
    final order = widget.order;
    setState(() => _dialogOpen = true);
    try {
      final input = await showOwnerDialog<OwnerOrderTransition>(
        context: context,
        ref: ref,
        builder: (_) => OwnerOrderDecisionDialog(
          order: order,
          target: target,
          ownerId: actor,
          sessionGeneration: session.generation,
        ),
      );
      if (!mounted || !session.isCurrent(ref) || input == null) {
        return;
      }
      final ok = await ref
          .read(ownerMutationControllerProvider.notifier)
          .transition(order, input);
      if (mounted && ok && session.isCurrent(ref)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status pesanan diperbarui.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _dialogOpen = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocked =
        ref.watch(ownerMutationProvider.select((s) => s.blocked)) ||
        _dialogOpen;
    final order = widget.order;
    return Wrap(
      spacing: KcSpacing.xs,
      runSpacing: KcSpacing.xs,
      children: [
        if (OwnerOrderTransition.canMoveTo(order, OrderStatus.processing))
          FilledButton(
            onPressed: blocked ? null : () => _change(OrderStatus.processing),
            child: const Text('Terima pesanan'),
          ),
        if (OwnerOrderTransition.canMoveTo(order, OrderStatus.rejected))
          OutlinedButton(
            onPressed: blocked ? null : () => _change(OrderStatus.rejected),
            child: const Text('Tolak pesanan'),
          ),
        if (OwnerOrderTransition.canMoveTo(order, OrderStatus.ready))
          FilledButton(
            onPressed: blocked ? null : () => _change(OrderStatus.ready),
            child: const Text('Tandai siap diambil'),
          ),
        if (OwnerOrderTransition.canMoveTo(order, OrderStatus.completed))
          FilledButton(
            onPressed: blocked ? null : () => _change(OrderStatus.completed),
            child: const Text('Selesaikan pesanan'),
          ),
      ],
    );
  }
}
