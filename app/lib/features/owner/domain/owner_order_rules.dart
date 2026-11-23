import 'package:kantin_cerdas/features/owner/domain/owner_models.dart';

enum OwnerOrderAction {
  accept('Terima Pesanan', false),
  reject('Tolak Pesanan', true),
  ready('Siap Diambil', false),
  failFulfillment('Gagal Dipenuhi', true),
  complete('Selesaikan Pesanan', false),
  notPickedUp('Tidak Diambil', false),
  failPickup('Gagal Diambil', true);

  const OwnerOrderAction(this.label, this.requiresReason);

  final String label;
  final bool requiresReason;
}

abstract final class OwnerOrderRules {
  static List<OwnerOrderAction> allowedActions(OwnerOrderStatus status) =>
      switch (status) {
        OwnerOrderStatus.menungguKonfirmasi => const [
          OwnerOrderAction.accept,
          OwnerOrderAction.reject,
        ],
        OwnerOrderStatus.diproses => const [
          OwnerOrderAction.ready,
          OwnerOrderAction.failFulfillment,
        ],
        OwnerOrderStatus.siapDiambil => const [
          OwnerOrderAction.complete,
          OwnerOrderAction.notPickedUp,
          OwnerOrderAction.failPickup,
        ],
        OwnerOrderStatus.selesai ||
        OwnerOrderStatus.dibatalkan ||
        OwnerOrderStatus.ditolak ||
        OwnerOrderStatus.gagalDipenuhi ||
        OwnerOrderStatus.tidakDiambil ||
        OwnerOrderStatus.gagalDiambil => const [],
      };
}
