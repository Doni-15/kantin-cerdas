import 'package:kantin_cerdas/features/customer/domain/entities/menu_item.dart';

class Stall {
  const Stall({
    required this.id,
    required this.name,
    required this.block,
    required this.waitTime,
    required this.description,
    required this.menus,
    this.isOpen = true,
  });

  final String id;
  final String name;
  final String block;
  final String waitTime;
  final String description;

  final List<MenuItem> menus;

  final bool isOpen;
}