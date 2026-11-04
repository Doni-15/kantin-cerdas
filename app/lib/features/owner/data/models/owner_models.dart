import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_menu.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_mutation_lookup.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_stall.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/pending_owner_mutation.dart';

class OwnerStallModel {
  const OwnerStallModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.block,
    required this.description,
    required this.isOpen,
    required this.prepTimeMin,
    required this.version,
    this.imageUrl,
  });

  factory OwnerStallModel.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final ownerId = json['owner_id'] ?? json['ownerId'];
    final name = json['name'];
    final block = json['block'];
    final description = json['description'] ?? '';
    final isOpen = json['is_open'] ?? json['isOpen'];
    final prepTimeMin = json['prep_time_min'] ?? json['prepTimeMin'];
    final version = json['version'];
    final imageUrl = normalizeOptionalText(
      json['image_url'] ?? json['imageUrl'],
      fieldName: 'image_url',
    );

    if (id is! String ||
        ownerId is! String ||
        name is! String ||
        block is! String ||
        description is! String ||
        isOpen is! bool ||
        prepTimeMin is! int ||
        version is! int) {
      throw const DataParsingException('Format data stan pemilik tidak valid.');
    }

    return OwnerStallModel(
      id: id,
      ownerId: ownerId,
      name: name,
      block: block,
      description: description,
      isOpen: isOpen,
      prepTimeMin: prepTimeMin,
      version: version,
      imageUrl: imageUrl,
    );
  }

  final String id;
  final String ownerId;
  final String name;
  final String block;
  final String description;
  final bool isOpen;
  final int prepTimeMin;
  final int version;
  final String? imageUrl;

  OwnerStall toEntity() {
    try {
      return OwnerStall(
        id: id,
        ownerId: ownerId,
        name: name,
        block: block,
        description: description,
        isOpen: isOpen,
        prepTimeMin: prepTimeMin,
        version: version,
        imageUrl: imageUrl,
      );
    } on ArgumentError catch (e) {
      throw DataParsingException(
        e.message?.toString() ?? 'Data stan pemilik tidak valid.',
      );
    }
  }
}

class OwnerMenuModel {
  const OwnerMenuModel({
    required this.id,
    required this.stallId,
    required this.name,
    required this.description,
    required this.category,
    required this.priceIdr,
    required this.isAvailable,
    required this.version,
    this.imageUrl,
  });

  factory OwnerMenuModel.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final stallId = json['stall_id'] ?? json['stallId'];
    final name = json['name'];
    final description = json['description'] ?? '';
    final category = json['category'];
    final priceIdr = json['price_idr'] ?? json['priceIdr'];
    final isAvailable = json['is_available'] ?? json['isAvailable'];
    final version = json['version'];
    final imageUrl = normalizeOptionalText(
      json['image_url'] ?? json['imageUrl'],
      fieldName: 'image_url',
    );

    if (id is! String ||
        stallId is! String ||
        name is! String ||
        description is! String ||
        category is! String ||
        priceIdr is! int ||
        isAvailable is! bool ||
        version is! int) {
      throw const DataParsingException('Format menu pemilik tidak valid.');
    }

    return OwnerMenuModel(
      id: id,
      stallId: stallId,
      name: name,
      description: description,
      category: category,
      priceIdr: priceIdr,
      isAvailable: isAvailable,
      version: version,
      imageUrl: imageUrl,
    );
  }

  final String id;
  final String stallId;
  final String name;
  final String description;
  final String category;
  final int priceIdr;
  final bool isAvailable;
  final int version;
  final String? imageUrl;

  OwnerMenu toEntity() {
    final parsedCategory = MenuCategory.tryFromRaw(category);
    if (parsedCategory == null) {
      throw const DataParsingException('Kategori menu pemilik tidak dikenali.');
    }
    try {
      return OwnerMenu(
        id: id,
        stallId: stallId,
        name: name,
        description: description,
        category: parsedCategory,
        priceIdr: priceIdr,
        isAvailable: isAvailable,
        version: version,
        imageUrl: imageUrl,
      );
    } on ArgumentError catch (e) {
      throw DataParsingException(
        e.message?.toString() ?? 'Menu pemilik tidak valid.',
      );
    }
  }
}

class OwnerMenuPageModel {
  const OwnerMenuPageModel({required this.items, this.nextCursor});

  factory OwnerMenuPageModel.fromJson(Map<String, Object?> json) {
    final rawItems = json['items'];
    final nextCursor = normalizeOptionalText(
      json['next_cursor'] ?? json['nextCursor'],
      fieldName: 'next_cursor',
    );
    if (rawItems is! List<Object?>) {
      throw const DataParsingException('Format halaman menu tidak valid.');
    }
    final items = <OwnerMenuModel>[];
    for (final raw in rawItems) {
      items.add(OwnerMenuModel.fromJson(asJsonMap(raw, fieldName: 'items')));
    }
    return OwnerMenuPageModel(items: items, nextCursor: nextCursor);
  }

  final List<OwnerMenuModel> items;
  final String? nextCursor;

  OwnerMenuPage toEntity() {
    try {
      return OwnerMenuPage(
        items: items.map((m) => m.toEntity()).toList(growable: false),
        nextCursor: nextCursor,
      );
    } on ArgumentError catch (e) {
      throw DataParsingException(
        e.message?.toString() ?? 'Halaman menu tidak valid.',
      );
    }
  }
}

class OwnerMutationLookupModel {
  const OwnerMutationLookupModel({
    required this.ownerId,
    required this.mutationId,
    required this.stallId,
    required this.kind,
    required this.outcome,
    this.targetId,
    this.expectedVersion,
    this.orderStatus,
    this.resultId,
    this.resultVersion,
    this.resultOrderStatus,
    this.paymentStatus,
  });

  factory OwnerMutationLookupModel.fromJson(Map<String, Object?> json) {
    final req = tryAsJsonMap(json['request']) ?? json;
    final ownerId =
        req['owner_id'] ??
        req['ownerId'] ??
        json['owner_id'] ??
        json['ownerId'];
    final mutationId =
        req['mutation_id'] ??
        req['mutationId'] ??
        json['mutation_id'] ??
        json['mutationId'];
    final stallId = req['stall_id'] ?? req['stallId'];
    final kind = req['kind'] ?? json['kind'];
    final targetId = normalizeOptionalText(
      req['target_id'] ?? req['targetId'],
      fieldName: 'target_id',
    );
    final expectedVersion = req['expected_version'] ?? req['expectedVersion'];
    final orderStatus = normalizeOptionalText(
      req['order_status'] ?? req['orderStatus'],
      fieldName: 'order_status',
    );
    final outcome = json['outcome'] ?? json['status'];
    final resultId = normalizeOptionalText(
      json['result_id'] ?? json['resultId'],
      fieldName: 'result_id',
    );
    final resultVersion = json['result_version'] ?? json['resultVersion'];
    final resultOrderStatus = normalizeOptionalText(
      json['result_order_status'] ?? json['resultOrderStatus'],
      fieldName: 'result_order_status',
    );
    final paymentStatus = normalizeOptionalText(
      json['payment_status'] ?? json['paymentStatus'],
      fieldName: 'payment_status',
    );

    if (ownerId is! String ||
        mutationId is! String ||
        stallId is! String ||
        kind is! String ||
        outcome is! String ||
        (expectedVersion != null && expectedVersion is! int) ||
        (resultVersion != null && resultVersion is! int)) {
      throw const DataParsingException('Format lookup mutasi owner invalid.');
    }

    return OwnerMutationLookupModel(
      ownerId: ownerId,
      mutationId: mutationId,
      stallId: stallId,
      kind: kind,
      outcome: outcome,
      targetId: targetId,
      expectedVersion: expectedVersion as int?,
      orderStatus: orderStatus,
      resultId: resultId,
      resultVersion: resultVersion as int?,
      resultOrderStatus: resultOrderStatus,
      paymentStatus: paymentStatus,
    );
  }

  final String ownerId;
  final String mutationId;
  final String stallId;
  final String kind;
  final String outcome;
  final String? targetId;
  final int? expectedVersion;
  final String? orderStatus;
  final String? resultId;
  final int? resultVersion;
  final String? resultOrderStatus;
  final String? paymentStatus;

  OwnerMutationLookup toEntity() {
    final parsedKind = switch (kind.trim()) {
      'save_menu' || 'saveMenu' => OwnerMutationKind.saveMenu,
      'delete_menu' || 'deleteMenu' => OwnerMutationKind.deleteMenu,
      'save_stall' || 'saveStall' => OwnerMutationKind.saveStall,
      'transition_order' ||
      'transitionOrder' => OwnerMutationKind.transitionOrder,
      _ => throw const DataParsingException('Jenis mutasi owner tidak valid.'),
    };
    OrderStatus? parseOrderStatus(String? raw) => raw == null
        ? null
        : (OrderStatus.tryFromRaw(raw) ??
              (throw const DataParsingException(
                'Status pesanan mutasi owner tidak valid.',
              )));
    final parsedOrderStatus = parseOrderStatus(orderStatus);
    final parsedResultOrderStatus = parseOrderStatus(resultOrderStatus);
    final parsedPaymentStatus = paymentStatus == null
        ? null
        : (OrderPaymentStatus.tryFromRaw(paymentStatus) ??
              (throw const DataParsingException(
                'Status pembayaran mutasi owner tidak valid.',
              )));
    final parsedOutcome = switch (outcome.trim().toLowerCase()) {
      'pending' => OwnerMutationOutcome.pending,
      'applied' => OwnerMutationOutcome.applied,
      'not_applied' || 'notapplied' => OwnerMutationOutcome.notApplied,
      _ => throw const DataParsingException(
        'Outcome lookup mutasi owner tidak dikenali.',
      ),
    };

    try {
      return OwnerMutationLookup(
        request: PendingOwnerMutation(
          ownerId: ownerId,
          mutationId: mutationId,
          stallId: stallId,
          kind: parsedKind,
          targetId: targetId,
          expectedVersion: expectedVersion,
          orderStatus: parsedOrderStatus,
        ),
        outcome: parsedOutcome,
        resultId: resultId,
        resultVersion: resultVersion,
        orderStatus: parsedResultOrderStatus,
        paymentStatus: parsedPaymentStatus,
      );
    } on ArgumentError catch (e) {
      throw DataParsingException(
        e.message?.toString() ?? 'Data lookup mutasi owner tidak valid.',
      );
    }
  }
}
