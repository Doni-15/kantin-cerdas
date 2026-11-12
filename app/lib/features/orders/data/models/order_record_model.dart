import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';

class OrderLineModel {
  const OrderLineModel({
    required this.menuId,
    required this.name,
    required this.quantity,
    required this.unitPriceIdr,
    required this.note,
  });

  factory OrderLineModel.fromJson(Map<String, Object?> json) {
    final menuId = json['menu_id'] ?? json['menuId'];
    final name = json['name'];
    final quantity = json['quantity'];
    final unitPrice = json['unit_price_idr'] ?? json['unitPriceIdr'];
    final note = json['note'] ?? '';

    if (menuId is! String ||
        name is! String ||
        quantity is! int ||
        unitPrice is! int ||
        note is! String) {
      throw const DataParsingException('Format item pesanan tidak valid.');
    }

    return OrderLineModel(
      menuId: menuId,
      name: name,
      quantity: quantity,
      unitPriceIdr: unitPrice,
      note: note,
    );
  }

  final String menuId;
  final String name;
  final int quantity;
  final int unitPriceIdr;
  final String note;
}

class OrderRecordModel {
  const OrderRecordModel({
    required this.id,
    required this.orderNumber,
    required this.customerId,
    required this.customerName,
    required this.stallId,
    required this.stallName,
    required this.items,
    required this.status,
    required this.paymentStatus,
    required this.totalPriceIdr,
    required this.note,
    required this.createdAtIso,
    required this.updatedAtIso,
    required this.version,
    this.rejectionReason,
  });

  factory OrderRecordModel.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final orderNumber = json['order_number'] ?? json['orderNumber'];
    final customerId = json['customer_id'] ?? json['customerId'];
    final customerName = json['customer_name'] ?? json['customerName'] ?? '';
    final stallId = json['stall_id'] ?? json['stallId'];
    final stallName = json['stall_name'] ?? json['stallName'];
    final rawItems = json['items'];
    final status = json['status'];
    final paymentStatus = json['payment_status'] ?? json['paymentStatus'];
    final totalPrice = json['total_price_idr'] ?? json['totalPriceIdr'];
    final note = json['note'] ?? '';
    final createdAt = json['created_at'] ?? json['createdAt'];
    final updatedAt = json['updated_at'] ?? json['updatedAt'];
    final version = json['version'];
    final rejectionReason = normalizeOptionalText(
      json['rejection_reason'] ?? json['rejectionReason'],
      fieldName: 'rejection_reason',
    );

    if (id is! String ||
        orderNumber is! String ||
        customerId is! String ||
        customerName is! String ||
        stallId is! String ||
        stallName is! String ||
        rawItems is! List<Object?> ||
        status is! String ||
        paymentStatus is! String ||
        totalPrice is! int ||
        note is! String ||
        createdAt is! String ||
        updatedAt is! String ||
        version is! int) {
      throw const DataParsingException('Format data pesanan tidak valid.');
    }

    final items = <OrderLineModel>[];
    for (final raw in rawItems) {
      items.add(OrderLineModel.fromJson(asJsonMap(raw, fieldName: 'items')));
    }

    return OrderRecordModel(
      id: id,
      orderNumber: orderNumber,
      customerId: customerId,
      customerName: customerName,
      stallId: stallId,
      stallName: stallName,
      items: items,
      status: status,
      paymentStatus: paymentStatus,
      totalPriceIdr: totalPrice,
      note: note,
      createdAtIso: createdAt,
      updatedAtIso: updatedAt,
      version: version,
      rejectionReason: rejectionReason,
    );
  }

  final String id;
  final String orderNumber;
  final String customerId;
  final String customerName;
  final String stallId;
  final String stallName;
  final List<OrderLineModel> items;
  final String status;
  final String paymentStatus;
  final int totalPriceIdr;
  final String note;
  final String createdAtIso;
  final String updatedAtIso;
  final int version;
  final String? rejectionReason;
}

class OrderRecordPageModel {
  const OrderRecordPageModel({required this.items, this.nextCursor});

  factory OrderRecordPageModel.fromJson(Map<String, Object?> json) {
    final rawItems = json['items'];
    final nextCursor = normalizeOptionalText(
      json['next_cursor'] ?? json['nextCursor'],
      fieldName: 'next_cursor',
    );
    if (rawItems is! List<Object?>) {
      throw const DataParsingException('Format halaman pesanan tidak valid.');
    }
    final items = <OrderRecordModel>[];
    for (final raw in rawItems) {
      items.add(OrderRecordModel.fromJson(asJsonMap(raw, fieldName: 'items')));
    }
    return OrderRecordPageModel(items: items, nextCursor: nextCursor);
  }

  final List<OrderRecordModel> items;
  final String? nextCursor;
}
