import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_cancellation.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_price_confirmation.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_cancellation_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_draft.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_submission_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/pending_order_cancellation.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';

class OrderCreateRequestModel {
  const OrderCreateRequestModel({
    required this.submissionId,
    required this.stallId,
    required this.orderNote,
    required this.totalPriceIdr,
    required this.items,
  });

  factory OrderCreateRequestModel.fromDomain({
    required OrderDraft draft,
    required String submissionId,
    required CustomerOrderPriceConfirmation confirmation,
  }) {
    return OrderCreateRequestModel(
      submissionId: submissionId,
      stallId: draft.stallId,
      orderNote: draft.orderNote,
      totalPriceIdr: confirmation.totalPriceIdr,
      items: [
        for (final item in draft.items)
          <String, Object?>{
            'menu_id': item.menuId,
            'quantity': item.quantity,
            'unit_price_idr': confirmation.unitPricesIdr[item.menuId],
            'note': item.note,
          },
      ],
    );
  }

  final String submissionId;
  final String stallId;
  final String orderNote;
  final int totalPriceIdr;
  final List<Map<String, Object?>> items;

  Map<String, Object?> toJson() => <String, Object?>{
    'submission_id': submissionId,
    'stall_id': stallId,
    'order_note': orderNote,
    'payment_method': 'CASH_ON_PICKUP',
    'total_price_idr': totalPriceIdr,
    'items': items,
  };
}

class OrderSubmissionLookupModel {
  const OrderSubmissionLookupModel({
    required this.customerId,
    required this.submissionId,
    required this.status,
    this.orderId,
  });

  factory OrderSubmissionLookupModel.fromJson(Map<String, Object?> json) {
    final customerId = json['customer_id'] ?? json['customerId'];
    final submissionId = json['submission_id'] ?? json['submissionId'];
    final status = json['status'] ?? json['outcome'];
    final orderId = normalizeOptionalText(
      json['order_id'] ?? json['orderId'],
      fieldName: 'order_id',
    );

    if (customerId is! String || submissionId is! String || status is! String) {
      throw const DataParsingException('Format lookup pengiriman tidak valid.');
    }

    return OrderSubmissionLookupModel(
      customerId: customerId,
      submissionId: submissionId,
      status: status,
      orderId: orderId,
    );
  }

  final String customerId;
  final String submissionId;
  final String status;
  final String? orderId;

  OrderSubmissionLookup toEntity() {
    final parsedStatus = switch (status.trim().toLowerCase()) {
      'pending' => OrderSubmissionStatus.pending,
      'confirmed' || 'applied' => OrderSubmissionStatus.confirmed,
      'not_created' ||
      'notcreated' ||
      'not_applied' ||
      'notapplied' => OrderSubmissionStatus.notCreated,
      _ => throw const DataParsingException(
        'Status lookup pengiriman tidak dikenali.',
      ),
    };
    try {
      return OrderSubmissionLookup(
        customerId: customerId,
        submissionId: submissionId,
        status: parsedStatus,
        orderId: orderId,
      );
    } on ArgumentError catch (e) {
      throw DataParsingException(
        e.message?.toString() ?? 'Lookup pengiriman tidak valid.',
      );
    }
  }
}

class OrderCancellationLookupModel {
  const OrderCancellationLookupModel({
    required this.customerId,
    required this.mutationId,
    required this.stallId,
    required this.orderNumber,
    required this.orderId,
    required this.expectedVersion,
    required this.outcome,
    this.resultVersion,
    this.orderStatus,
    this.paymentStatus,
  });

  factory OrderCancellationLookupModel.fromJson(Map<String, Object?> json) {
    final req = tryAsJsonMap(json['request']) ?? json;
    final input = tryAsJsonMap(req['input']) ?? req;
    final customerId =
        req['customer_id'] ??
        req['customerId'] ??
        json['customer_id'] ??
        json['customerId'];
    final mutationId =
        req['mutation_id'] ??
        req['mutationId'] ??
        json['mutation_id'] ??
        json['mutationId'];
    final stallId = req['stall_id'] ?? req['stallId'];
    final orderNumber = req['order_number'] ?? req['orderNumber'];
    final orderId = input['order_id'] ?? input['orderId'];
    final expectedVersion =
        input['expected_version'] ?? input['expectedVersion'];
    final outcome = json['outcome'] ?? json['status'];
    final resultVersion = json['result_version'] ?? json['resultVersion'];
    final orderStatus = normalizeOptionalText(
      json['order_status'] ?? json['orderStatus'],
      fieldName: 'order_status',
    );
    final paymentStatus = normalizeOptionalText(
      json['payment_status'] ?? json['paymentStatus'],
      fieldName: 'payment_status',
    );

    if (customerId is! String ||
        mutationId is! String ||
        stallId is! String ||
        orderNumber is! String ||
        orderId is! String ||
        expectedVersion is! int ||
        outcome is! String ||
        (resultVersion != null && resultVersion is! int)) {
      throw const DataParsingException('Format lookup pembatalan tidak valid.');
    }

    return OrderCancellationLookupModel(
      customerId: customerId,
      mutationId: mutationId,
      stallId: stallId,
      orderNumber: orderNumber,
      orderId: orderId,
      expectedVersion: expectedVersion,
      outcome: outcome,
      resultVersion: resultVersion as int?,
      orderStatus: orderStatus,
      paymentStatus: paymentStatus,
    );
  }

  final String customerId;
  final String mutationId;
  final String stallId;
  final String orderNumber;
  final String orderId;
  final int expectedVersion;
  final String outcome;
  final int? resultVersion;
  final String? orderStatus;
  final String? paymentStatus;

  OrderCancellationLookup toEntity() {
    final parsedOutcome = switch (outcome.trim().toLowerCase()) {
      'pending' => OrderCancellationOutcome.pending,
      'applied' => OrderCancellationOutcome.applied,
      'not_applied' ||
      'notapplied' ||
      'not_cancelled' ||
      'notcancelled' => OrderCancellationOutcome.notApplied,
      _ => throw const DataParsingException(
        'Outcome lookup pembatalan tidak dikenali.',
      ),
    };
    final parsedStatus = orderStatus == null
        ? null
        : (OrderStatus.tryFromRaw(orderStatus) ??
              (throw const DataParsingException(
                'Status pesanan lookup pembatalan tidak valid.',
              )));
    final parsedPayment = paymentStatus == null
        ? null
        : (OrderPaymentStatus.tryFromRaw(paymentStatus) ??
              (throw const DataParsingException(
                'Status pembayaran lookup pembatalan tidak valid.',
              )));
    try {
      return OrderCancellationLookup(
        request: PendingOrderCancellation(
          customerId: customerId,
          mutationId: mutationId,
          stallId: stallId,
          orderNumber: orderNumber,
          input: CustomerOrderCancellation(
            orderId: orderId,
            expectedVersion: expectedVersion,
          ),
        ),
        outcome: parsedOutcome,
        resultVersion: resultVersion,
        status: parsedStatus,
        paymentStatus: parsedPayment,
      );
    } on ArgumentError catch (e) {
      throw DataParsingException(
        e.message?.toString() ?? 'Data lookup pembatalan tidak valid.',
      );
    }
  }
}
