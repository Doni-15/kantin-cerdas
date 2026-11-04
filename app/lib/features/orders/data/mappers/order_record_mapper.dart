import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';
import 'package:kantin_cerdas/features/orders/data/models/order_record_model.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:kantin_cerdas/features/orders/domain/validation/order_record_rules.dart';

extension OrderLineModelMapper on OrderLineModel {
  OrderLine toEntity() {
    try {
      return OrderLine(
        menuId: menuId,
        name: name,
        quantity: quantity,
        unitPriceIdr: unitPriceIdr,
        note: note,
      );
    } on ArgumentError catch (e) {
      throw DataParsingException(e.message?.toString() ?? 'Item tidak valid.');
    }
  }
}

extension OrderRecordModelMapper on OrderRecordModel {
  OrderRecord toEntity() {
    final parsedCreated = parseStrictUtcDateTime(
      createdAtIso,
      fieldName: 'created_at',
    );
    final parsedUpdated = parseStrictUtcDateTime(
      updatedAtIso,
      fieldName: 'updated_at',
    );

    final parsedStatus = OrderStatus.tryFromRaw(status);
    if (parsedStatus == null) {
      throw const DataParsingException('Status pesanan tidak dikenali.');
    }

    final parsedPayment = OrderPaymentStatus.tryFromRaw(paymentStatus);
    if (parsedPayment == null) {
      throw const DataParsingException(
        'Status pembayaran pesanan tidak dikenali.',
      );
    }

    try {
      final record = OrderRecord(
        id: id,
        orderNumber: orderNumber,
        customerId: customerId,
        customerName: customerName,
        stallId: stallId,
        stallName: stallName,
        items: items.map((item) => item.toEntity()).toList(growable: false),
        status: parsedStatus,
        paymentStatus: parsedPayment,
        totalPriceIdr: totalPriceIdr,
        note: note,
        createdAt: parsedCreated,
        updatedAt: parsedUpdated,
        version: version,
        rejectionReason: rejectionReason,
      );
      if (!OrderRecordRules.hasConsistentSnapshot(record)) {
        throw const DataParsingException(
          'Snapshot pesanan tidak konsisten dengan aturan domain.',
        );
      }
      return record;
    } on ArgumentError catch (e) {
      throw DataParsingException(
        e.message?.toString() ?? 'Pesanan tidak valid.',
      );
    }
  }
}

extension OrderRecordPageModelMapper on OrderRecordPageModel {
  OrderRecordPage toEntity() {
    try {
      return OrderRecordPage(
        items: items.map((item) => item.toEntity()).toList(growable: false),
        nextCursor: nextCursor,
      );
    } on ArgumentError catch (e) {
      throw DataParsingException(
        e.message?.toString() ?? 'Halaman pesanan tidak valid.',
      );
    }
  }
}
