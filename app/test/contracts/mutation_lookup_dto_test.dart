import 'package:flutter_test/flutter_test.dart';
import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/features/admin/data/models/admin_models.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/canteen_application_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/models/customer_order_models.dart';
import 'package:kantin_cerdas/features/customer/data/models/food_preferences_model.dart';
import 'package:kantin_cerdas/features/customer/data/models/stall_model.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_cancellation_lookup.dart';
import 'package:kantin_cerdas/features/orders/data/models/canteen_application_model.dart';
import 'package:kantin_cerdas/features/owner/data/models/owner_models.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_mutation_lookup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(
    'Kontrak DTO lookup mutasi (CRIT-NEW-01, HIGH-NEW-02, PROD-NEW-08..09)',
    () {
      test(
        '5 DTO Lookup Mutasi baru, prep_time_min, normalisasi string kosong, dan validasi UTC ketat (CRIT-NEW-01, HIGH-NEW-02, PROD-NEW-08..09)',
        () {
          final adminLookup =
              AdminMutationLookupModel.fromJson(<String, Object?>{
                'mutation_id': 'adm-mut-1',
                'actor_id': 'admin-1',
                'kind': 'change_access',
                'target_id': 'usr-1',
                'expected_version': 2,
                'reason': 'Penonaktifan akun uji',
                'is_active': false,
                'target_role': 'customer',
                'outcome': 'applied',
                'result_version': 3,
                'result_is_active': false,
                'result_role': 'customer',
              }).toEntity();
          expect(adminLookup.request.mutationId, 'adm-mut-1');
          expect(adminLookup.resultVersion, 3);
          expect(adminLookup.isActive, isFalse);

          final ownerLookup =
              OwnerMutationLookupModel.fromJson(<String, Object?>{
                'mutation_id': 'own-mut-1',
                'owner_id': 'owner-1',
                'stall_id': 'stall-1',
                'kind': 'delete_menu',
                'target_id': 'm-1',
                'expected_version': 4,
                'outcome': 'not_applied',
              }).toEntity();
          expect(ownerLookup.outcome, OwnerMutationOutcome.notApplied);

          final appLookup = CanteenApplicationLookupModel.fromJson(
            <String, Object?>{
              'customer_id': 'cust-1',
              'submission_id': 'sub-app-1',
              'status': 'submitted',
              'receipt': <String, Object?>{
                'id': 'app-1',
                'applicant_id': 'cust-1',
                'name': 'Warung Cerdas',
                'description': 'Aneka masakan soto higienis',
                'location': 'Blok B',
                'phone': '081234567890',
                'status': 'submitted',
                'reason': '   ',
                'created_at': '2026-11-02T01:00:00Z',
                'version': 1,
              },
            },
          ).toEntity();
          expect(
            appLookup.status,
            CanteenApplicationSubmissionStatus.submitted,
          );
          expect(appLookup.receipt?.reason, isNull);

          final cancelLookup =
              OrderCancellationLookupModel.fromJson(<String, Object?>{
                'mutation_id': 'cancel-1',
                'customer_id': 'cust-1',
                'stall_id': 'stall-1',
                'order_number': 'KC-101',
                'order_id': 'ord-1',
                'expected_version': 1,
                'status': 'not_cancelled',
              }).toEntity();
          expect(cancelLookup.outcome, OrderCancellationOutcome.notApplied);

          final prefsLookup = FoodPreferencesLookupModel.fromJson(
            <String, Object?>{
              'mutation_id': 'pref-1',
              'customer_id': 'cust-1',
              'expected_version': 1,
              'max_budget_idr': 25000,
              'vegetarian': true,
              'avoid_ingredients': <Object?>['cabai'],
              'status': 'saved',
              'saved': <String, Object?>{
                'customer_id': 'cust-1',
                'version': 2,
                'max_budget_idr': 25000,
                'vegetarian': true,
                'avoid_ingredients': <Object?>['cabai'],
              },
            },
          ).toEntity();
          expect(prefsLookup.outcome, FoodPreferencesOutcome.applied);
          expect(prefsLookup.snapshot?.version, 2);

          // prep_time_min (int -> "$min mnt")
          final stallFromPrepMin = StallModel.fromJson(<String, Object?>{
            'id': 's-1',
            'name': 'Stan Cepat',
            'block': 'Blok A',
            'prep_time_min': 12,
            'description': 'Cepat saji',
            'is_open': true,
            'menus': <Object?>[],
          });
          expect(stallFromPrepMin.waitTime, '12 mnt');

          // Timestamp tanpa zona waktu eksplisit ditolak
          expect(
            () => CanteenApplicationModel.fromJson(<String, Object?>{
              'id': 'app-1',
              'applicant_id': 'cust-1',
              'name': 'Warung Cerdas',
              'description': 'Aneka masakan soto higienis',
              'location': 'Blok B',
              'phone': '081234567890',
              'status': 'submitted',
              'created_at': '2026-11-02T01:00:00',
              'version': 1,
            }).toEntity(),
            throwsA(isA<DataParsingException>()),
          );
        },
      );
    },
  );
}
