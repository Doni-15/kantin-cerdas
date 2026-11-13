import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_summary.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_user_record.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/pending_admin_mutation.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/cart_item.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/cart_state.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_cancellation.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_price_confirmation.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences_snapshot.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/menu_item.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_draft.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/pending_canteen_application.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/pending_food_preferences.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/pending_order_cancellation.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_menu.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_order_transition.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_stall.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/pending_owner_mutation.dart';

void main() {
  group('Kesetaraan Nilai (== & hashCode) Entitas Domain', () {
    test(
      'User, MenuItem, CartState, OwnerMenu, dan FoodPreferencesSnapshot setara berdasarkan nilai',
      () {
        const userA = User(
          id: 'u1',
          username: 'doni_user',
          email: 'doni@example.test',
          name: 'Doni',
          role: UserRole.customer,
          isActive: true,
        );
        const userB = User(
          id: 'u1',
          username: 'doni_user',
          email: 'doni@example.test',
          name: 'Doni',
          role: UserRole.customer,
          isActive: true,
        );
        expect(userA, equals(userB));
        expect(userA.hashCode, equals(userB.hashCode));
        expect(
          AdminUserRecord(user: userA, version: 2),
          equals(AdminUserRecord(user: userB, version: 2)),
        );

        const menuA = MenuItem(
          id: 'm1',
          name: 'Nasi Goreng',
          stallId: 's1',
          stallName: 'Stan 1',
          block: 'A',
          price: 12000,
          waitTime: '5 mnt',
          description: 'Enak',
          category: 'Nasi',
          available: true,
        );
        const menuB = MenuItem(
          id: 'm1',
          name: 'Nasi Goreng',
          stallId: 's1',
          stallName: 'Stan 1',
          block: 'A',
          price: 12000,
          waitTime: '5 mnt',
          description: 'Enak',
          category: 'Nasi',
          available: true,
        );
        expect(menuA, equals(menuB));
        expect(
          CartState(
            items: [CartItem(menu: menuA, quantity: 2)],
            orderNote: 'Pedas',
          ),
          equals(
            CartState(
              items: [CartItem(menu: menuB, quantity: 2)],
              orderNote: 'Pedas',
            ),
          ),
        );

        final ownerMenuA = OwnerMenu(
          id: 'm1',
          stallId: 's1',
          name: 'Nasi Goreng',
          description: 'Enak',
          category: MenuCategory.rice,
          priceIdr: 12000,
          isAvailable: true,
          version: 1,
        );
        final ownerMenuB = OwnerMenu(
          id: 'm1',
          stallId: 's1',
          name: 'Nasi Goreng',
          description: 'Enak',
          category: MenuCategory.rice,
          priceIdr: 12000,
          isAvailable: true,
          version: 1,
        );
        expect(ownerMenuA, equals(ownerMenuB));

        final snapA = FoodPreferencesSnapshot(
          customerId: 'u1',
          version: 3,
          preferences: FoodPreferences(
            maxBudgetIdr: 20000,
            vegetarian: false,
            avoidIngredients: const ['kacang', 'udang'],
          ),
        );
        final snapB = FoodPreferencesSnapshot(
          customerId: 'u1',
          version: 3,
          preferences: FoodPreferences(
            maxBudgetIdr: 20000,
            vegetarian: false,
            avoidIngredients: const ['kacang', 'udang'],
          ),
        );
        expect(snapA, equals(snapB));
        expect(
          AdminSummary(
            users: 10,
            stalls: 3,
            openStalls: 2,
            pendingApplications: 1,
            activeOrders: 4,
          ),
          equals(
            AdminSummary(
              users: 10,
              stalls: 3,
              openStalls: 2,
              pendingApplications: 1,
              activeOrders: 4,
            ),
          ),
        );

        final draftA = OrderDraft(
          stallId: 's1',
          items: [OrderDraftItem(menuId: 'm1', quantity: 2, note: 'Pedas')],
          orderNote: 'Bungkus',
        );
        final draftB = OrderDraft(
          stallId: 's1',
          items: [OrderDraftItem(menuId: 'm1', quantity: 2, note: 'Pedas')],
          orderNote: 'Bungkus',
        );
        final confirmA = CustomerOrderPriceConfirmation(
          draft: draftA,
          unitPricesIdr: const {'m1': 12000},
        );
        final confirmB = CustomerOrderPriceConfirmation(
          draft: draftB,
          unitPricesIdr: const {'m1': 12000},
        );
        expect(confirmA, equals(confirmB));
        expect(confirmA.hashCode, equals(confirmB.hashCode));

        final pendingOwnerA = PendingOwnerMutation(
          mutationId: 'mut-1',
          ownerId: 'own-1',
          stallId: 's1',
          kind: OwnerMutationKind.deleteMenu,
          targetId: 'm1',
          expectedVersion: 2,
        );
        final pendingOwnerB = PendingOwnerMutation(
          mutationId: 'mut-1',
          ownerId: 'own-1',
          stallId: 's1',
          kind: OwnerMutationKind.deleteMenu,
          targetId: 'm1',
          expectedVersion: 2,
        );
        expect(pendingOwnerA, equals(pendingOwnerB));

        final pendingAdminA = PendingAdminMutation(
          mutationId: 'adm-1',
          adminId: 'admin-1',
          kind: AdminMutationKind.changeAccess,
          targetId: 'u1',
          expectedVersion: 1,
          isActive: true,
          targetRole: UserRole.owner,
          reason: 'Aktivasi akun',
        );
        final pendingAdminB = PendingAdminMutation(
          mutationId: 'adm-1',
          adminId: 'admin-1',
          kind: AdminMutationKind.changeAccess,
          targetId: 'u1',
          expectedVersion: 1,
          isActive: true,
          targetRole: UserRole.owner,
          reason: 'Aktivasi akun',
        );
        expect(pendingAdminA, equals(pendingAdminB));

        expect(
          PendingOrderCancellation(
            mutationId: 'c1',
            customerId: 'u1',
            stallId: 's1',
            orderNumber: 'KC-101',
            input: CustomerOrderCancellation(orderId: 'o1', expectedVersion: 1),
          ),
          equals(
            PendingOrderCancellation(
              mutationId: 'c1',
              customerId: 'u1',
              stallId: 's1',
              orderNumber: 'KC-101',
              input: CustomerOrderCancellation(
                orderId: 'o1',
                expectedVersion: 1,
              ),
            ),
          ),
        );

        expect(
          PendingCanteenApplication(
            customerId: 'u1',
            submissionId: 'sub-1',
            draft: CanteenApplicationDraft(
              name: 'Stan A',
              description: 'Nasi Goreng',
              location: 'Blok A',
              phone: '081234567890',
            ),
            previousId: 'app-0',
            previousVersion: 1,
          ),
          equals(
            PendingCanteenApplication(
              customerId: 'u1',
              submissionId: 'sub-1',
              draft: CanteenApplicationDraft(
                name: 'Stan A',
                description: 'Nasi Goreng',
                location: 'Blok A',
                phone: '081234567890',
              ),
              previousId: 'app-0',
              previousVersion: 1,
            ),
          ),
        );

        expect(
          PendingFoodPreferences(
            mutationId: 'pf-1',
            customerId: 'u1',
            update: FoodPreferencesUpdate(
              expectedVersion: 1,
              preferences: FoodPreferences(
                maxBudgetIdr: 20000,
                vegetarian: false,
                avoidIngredients: const ['udang'],
              ),
            ),
          ),
          equals(
            PendingFoodPreferences(
              mutationId: 'pf-1',
              customerId: 'u1',
              update: FoodPreferencesUpdate(
                expectedVersion: 1,
                preferences: FoodPreferences(
                  maxBudgetIdr: 20000,
                  vegetarian: false,
                  avoidIngredients: const ['udang'],
                ),
              ),
            ),
          ),
        );

        expect(
          OwnerStallInput(
            id: 's1',
            name: 'Stan A',
            block: 'Blok A',
            prepTimeMin: 10,
            description: 'Enak',
            isOpen: true,
            expectedVersion: 1,
          ),
          equals(
            OwnerStallInput(
              id: 's1',
              name: 'Stan A',
              block: 'Blok A',
              prepTimeMin: 10,
              description: 'Enak',
              isOpen: true,
              expectedVersion: 1,
            ),
          ),
        );

        expect(
          OwnerOrderTransition(
            orderId: 'o1',
            status: OrderStatus.processing,
            expectedVersion: 1,
          ),
          equals(
            OwnerOrderTransition(
              orderId: 'o1',
              status: OrderStatus.processing,
              expectedVersion: 1,
            ),
          ),
        );
      },
    );
  });
}
