import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/features/admin/data/models/admin_models.dart';
import 'package:kantin_cerdas/features/customer/data/models/food_preferences_model.dart';
import 'package:kantin_cerdas/features/orders/data/mappers/order_record_mapper.dart';
import 'package:kantin_cerdas/features/orders/data/models/order_record_model.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:kantin_cerdas/features/owner/data/models/owner_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Kontrak JSON DTO ke Entity (CRIT-01, LOW-03)', () {
    test(
      'OrderRecordModel, OwnerMenuModel, AdminSummaryModel, dan FoodPreferencesSnapshotModel memvalidasi JSON ke Entity',
      () {
        final orderModel = OrderRecordModel.fromJson(<String, Object?>{
          'id': 'ord-1',
          'order_number': 'KC-101',
          'customer_id': 'cust-1',
          'customer_name': 'Doni',
          'stall_id': 'stall-1',
          'stall_name': 'Kantin Nusantara',
          'status': 'waiting',
          'payment_status': 'unpaid',
          'total_price_idr': 25000,
          'note': 'Tanpa bawang',
          'created_at': '2026-11-02T01:00:00Z',
          'updated_at': '2026-11-02T01:00:00Z',
          'version': 1,
          'items': <Object?>[
            <String, Object?>{
              'menu_id': 'm-1',
              'name': 'Mi Goreng',
              'quantity': 1,
              'unit_price_idr': 25000,
              'note': '',
            },
          ],
        });
        final orderEntity = orderModel.toEntity();
        expect(orderEntity.id, 'ord-1');
        expect(orderEntity.status, OrderStatus.waiting);
        expect(orderEntity.totalPriceIdr, 25000);

        final ownerMenu = OwnerMenuModel.fromJson(<String, Object?>{
          'id': 'm-1',
          'stall_id': 'stall-1',
          'name': 'Mie Aceh',
          'description': 'Rempah khas',
          'category': 'Mie',
          'price_idr': 20000,
          'is_available': true,
          'version': 2,
        }).toEntity();
        expect(ownerMenu.category.label, 'Mi');

        final summary = AdminSummaryModel.fromJson(<String, Object?>{
          'users': 12,
          'stalls': 4,
          'open_stalls': 3,
          'pending_applications': 1,
          'active_orders': 5,
        }).toEntity();
        expect(summary.openStalls, 3);

        final prefs = FoodPreferencesSnapshotModel.fromJson(<String, Object?>{
          'customer_id': 'cust-1',
          'version': 1,
          'max_budget_idr': 30000,
          'vegetarian': false,
          'avoid_ingredients': <Object?>['udang'],
        }).toEntity();
        expect(prefs.preferences.avoidIngredients, const ['udang']);
      },
    );
  });
}
