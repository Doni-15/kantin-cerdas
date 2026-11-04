import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';

enum OwnerMutationKind { saveMenu, deleteMenu, saveStall, transitionOrder }

/// Identitas intent, bukan payload untuk mengirim ulang request.
class PendingOwnerMutation {
  PendingOwnerMutation({
    required this.ownerId,
    required this.mutationId,
    required this.stallId,
    required this.kind,
    this.targetId,
    this.expectedVersion,
    this.orderStatus,
  }) {
    if (ownerId.trim().isEmpty ||
        mutationId.trim().isEmpty ||
        stallId.trim().isEmpty ||
        (targetId == null) != (expectedVersion == null) ||
        (targetId != null && targetId!.trim().isEmpty) ||
        (expectedVersion != null && expectedVersion! < 1) ||
        (kind != OwnerMutationKind.saveMenu && targetId == null) ||
        (kind == OwnerMutationKind.saveStall && targetId != stallId) ||
        (kind == OwnerMutationKind.transitionOrder) != (orderStatus != null) ||
        orderStatus == OrderStatus.waiting ||
        orderStatus == OrderStatus.cancelled) {
      throw ArgumentError('Identitas perubahan owner tidak valid.');
    }
  }
  final String ownerId;
  final String mutationId;
  final String stallId;
  final OwnerMutationKind kind;
  final String? targetId;
  final int? expectedVersion;
  final OrderStatus? orderStatus;

  static String operationOf(OwnerMutationKind kind, {String? targetId}) =>
      switch (kind) {
        OwnerMutationKind.saveMenu => 'menu:save',
        OwnerMutationKind.deleteMenu => 'menu:delete',
        OwnerMutationKind.saveStall => 'stall:save',
        OwnerMutationKind.transitionOrder => 'order:$targetId',
      };

  String get operation => operationOf(kind, targetId: targetId);

  bool matches(PendingOwnerMutation other) =>
      ownerId == other.ownerId &&
      mutationId == other.mutationId &&
      stallId == other.stallId &&
      kind == other.kind &&
      targetId == other.targetId &&
      expectedVersion == other.expectedVersion &&
      orderStatus == other.orderStatus;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingOwnerMutation && matches(other));

  @override
  int get hashCode => Object.hash(
    ownerId,
    mutationId,
    stallId,
    kind,
    targetId,
    expectedVersion,
    orderStatus,
  );
}
