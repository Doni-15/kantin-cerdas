import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_cancellation.dart';

/// Metadata request pembatalan, tidak berisi token atau instruksi pembayaran.
class PendingOrderCancellation {
  PendingOrderCancellation({
    required this.customerId,
    required this.mutationId,
    required this.stallId,
    required this.orderNumber,
    required this.input,
  }) {
    if ([
      customerId,
      mutationId,
      stallId,
      orderNumber,
    ].any((value) => value.trim().isEmpty)) {
      throw ArgumentError('Penanda pembatalan tidak valid.');
    }
  }
  final String customerId;
  final String mutationId;
  final String stallId;
  final String orderNumber;
  final CustomerOrderCancellation input;
  String get orderId => input.orderId;
  int get expectedVersion => input.expectedVersion;
  bool matches(PendingOrderCancellation other) =>
      customerId == other.customerId &&
      mutationId == other.mutationId &&
      stallId == other.stallId &&
      orderNumber == other.orderNumber &&
      orderId == other.orderId &&
      expectedVersion == other.expectedVersion;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingOrderCancellation &&
          other.customerId == customerId &&
          other.mutationId == mutationId &&
          other.stallId == stallId &&
          other.orderNumber == orderNumber &&
          other.input == input);

  @override
  int get hashCode =>
      Object.hash(customerId, mutationId, stallId, orderNumber, input);
}
