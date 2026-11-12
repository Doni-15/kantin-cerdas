import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';
import 'package:kantin_cerdas/features/customer/data/mappers/menu_item_mapper.dart';
import 'package:kantin_cerdas/features/customer/data/models/menu_item_model.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/assistant_reply.dart';

class AssistantReplyModel {
  const AssistantReplyModel({required this.message, required this.menus});

  factory AssistantReplyModel.fromJson(Map<String, Object?> json) {
    final message = json['message'];
    final rawMenus = json['menus'] ?? const <Object?>[];
    if (message is! String || rawMenus is! List<Object?>) {
      throw const DataParsingException('Format balasan asisten tidak valid.');
    }
    final menus = <MenuItemModel>[];
    for (final raw in rawMenus) {
      menus.add(MenuItemModel.fromJson(asJsonMap(raw, fieldName: 'menus')));
    }
    return AssistantReplyModel(message: message, menus: menus);
  }

  final String message;
  final List<MenuItemModel> menus;

  AssistantReply toEntity() {
    try {
      return AssistantReply(
        message: message,
        menus: menus.map((m) => m.toEntity()).toList(growable: false),
      );
    } on ArgumentError catch (e) {
      throw DataParsingException(
        e.message?.toString() ?? 'Balasan asisten tidak valid.',
      );
    }
  }
}
