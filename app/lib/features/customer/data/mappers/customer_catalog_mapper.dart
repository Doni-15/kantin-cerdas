import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/features/customer/data/mappers/menu_item_mapper.dart';
import 'package:kantin_cerdas/features/customer/data/mappers/stall_mapper.dart';
import 'package:kantin_cerdas/features/customer/data/models/customer_catalog_model.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_catalog.dart';

extension CustomerCatalogModelMapper on CustomerCatalogModel {
  CustomerCatalog toEntity() {
    try {
      return CustomerCatalog(
        menus: menus.map((menu) => menu.toEntity()).toList(growable: false),
        stalls: stalls.map((stall) => stall.toEntity()).toList(growable: false),
      );
    } on FormatException catch (error) {
      throw DataParsingException(error.message);
    }
  }
}
