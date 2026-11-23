import 'package:kantin_cerdas/features/customer/domain/customer_catalog_models.dart';

enum CustomerCartBlocker {
  stallUnlisted('Kantin tidak lagi tersedia.'),
  stallClosed('Kantin sedang tutup dan tidak menerima pesanan baru.'),
  ownerInactive('Kantin sementara tidak menerima pesanan.'),
  hasArchivedItem(
    'Ada menu tidak tersedia (diarsipkan) di keranjang. Hapus item tersebut untuk melanjutkan.',
  ),
  hasUnavailableItem(
    'Ada menu berstatus Habis di keranjang. Hapus item tersebut untuk melanjutkan.',
  ),
  hasPriceChange(
    'Ada perubahan harga menu di keranjang. Setujui harga terbaru sebelum checkout.',
  );

  const CustomerCartBlocker(this.message);
  final String message;

  static CustomerCartBlocker? fromApi(String raw) => switch (raw) {
    'stall_unlisted' => stallUnlisted,
    'stall_closed' => stallClosed,
    'owner_inactive' => ownerInactive,
    'has_archived_item' => hasArchivedItem,
    'has_unavailable_item' => hasUnavailableItem,
    'has_price_change' => hasPriceChange,
    _ => null,
  };
}

class CustomerCartItem {
  const CustomerCartItem({
    required this.id,
    required this.menuItemId,
    required this.menuName,
    required this.categoryName,
    required this.quantity,
    required this.itemNote,
    required this.seenUnitPrice,
    required this.currentUnitPrice,
    required this.lineTotal,
    required this.priceChanged,
    required this.isAvailable,
    required this.isArchived,
    required this.hasPhoto,
  });

  final String id;
  final String menuItemId;
  final String menuName;
  final String categoryName;
  final int quantity;
  final String itemNote;
  final int seenUnitPrice;
  final int currentUnitPrice;
  final int lineTotal;
  final bool priceChanged;
  final bool isAvailable;
  final bool isArchived;
  final bool hasPhoto;

  bool get isOrderable => !isArchived && isAvailable;

  factory CustomerCartItem.fromJson(Map<String, dynamic> json) =>
      CustomerCartItem(
        id: json['id'] as String,
        menuItemId: json['menu_item_id'] as String,
        menuName: json['menu_name'] as String,
        categoryName: json['category_name'] as String? ?? '',
        quantity: json['quantity'] as int,
        itemNote: json['item_note'] as String? ?? '',
        seenUnitPrice: json['seen_unit_price'] as int,
        currentUnitPrice: json['current_unit_price'] as int,
        lineTotal: json['line_total'] as int,
        priceChanged: json['price_changed'] == true,
        isAvailable: json['is_available'] == true,
        isArchived: json['is_archived'] == true,
        hasPhoto: json['has_photo'] == true,
      );
}

class CustomerCart {
  const CustomerCart({
    required this.stall,
    required this.items,
    required this.generalNote,
    required this.draftVersion,
    required this.subtotal,
    required this.seenSubtotal,
    required this.itemCount,
    required this.canCheckout,
    required this.blockers,
  });

  static const empty = CustomerCart(
    stall: null,
    items: [],
    generalNote: '',
    draftVersion: 0,
    subtotal: 0,
    seenSubtotal: 0,
    itemCount: 0,
    canCheckout: false,
    blockers: [],
  );

  final CustomerStallSummary? stall;
  final List<CustomerCartItem> items;
  final String generalNote;
  final int draftVersion;
  final int subtotal;
  final int seenSubtotal;
  final int itemCount;
  final bool canCheckout;
  final List<CustomerCartBlocker> blockers;

  bool get isEmpty => items.isEmpty;

  factory CustomerCart.fromJson(Map<String, dynamic> json) {
    final rawStall = json['stall'];
    return CustomerCart(
      stall: rawStall is Map<String, dynamic>
          ? CustomerStallSummary.fromJson(rawStall)
          : null,
      items: List<CustomerCartItem>.unmodifiable([
        for (final row in json['items'] as List<dynamic>? ?? const [])
          CustomerCartItem.fromJson(row as Map<String, dynamic>),
      ]),
      generalNote: json['general_note'] as String? ?? '',
      draftVersion: json['draft_version'] as int? ?? 0,
      subtotal: json['subtotal'] as int? ?? 0,
      seenSubtotal: json['seen_subtotal'] as int? ?? 0,
      itemCount: json['item_count'] as int? ?? 0,
      canCheckout: json['can_checkout'] == true,
      blockers: List<CustomerCartBlocker>.unmodifiable([
        for (final raw in json['blockers'] as List<dynamic>? ?? const [])
          ?CustomerCartBlocker.fromApi(raw as String),
      ]),
    );
  }
}
