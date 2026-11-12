import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/utils/pagination_validator.dart';
import 'package:kantin_cerdas/features/orders/data/mappers/order_record_mapper.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:kantin_cerdas/features/owner/data/datasources/owner_datasource.dart';
import 'package:kantin_cerdas/features/owner/data/mappers/owner_failure_mapper.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_menu.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_mutation_lookup.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_order_transition.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_stall.dart';
import 'package:kantin_cerdas/features/owner/domain/failures/owner_failure.dart';
import 'package:kantin_cerdas/features/owner/domain/repositories/owner_repository.dart';

final class OwnerRepositoryImpl implements OwnerRepository {
  const OwnerRepositoryImpl({required this._dataSource});

  final OwnerDataSource _dataSource;

  @override
  bool get isMutationConfigured => _dataSource.isMutationConfigured;

  @override
  Future<OwnerStall?> getMyStall() async {
    try {
      final model = await _dataSource.getMyStall();
      return model?.toEntity();
    } on OwnerFailure {
      rethrow;
    } on DataParsingException {
      throw const OwnerInvalidDataFailure();
    } on ApiException catch (e) {
      throw mapOwnerReadApiException(e);
    } catch (_) {
      throw const OwnerInvalidDataFailure();
    }
  }

  @override
  Future<OwnerMenuPage> listMenus({
    required String stallId,
    required String search,
    bool? available,
    String? cursor,
    int limit = 30,
  }) async {
    try {
      final page = await _dataSource.listMenus(
        stallId: stallId,
        search: search,
        available: available,
        cursor: cursor,
        limit: limit,
      );
      final entity = page.toEntity();
      validateCursorPageBounds(
        limit: limit,
        requestCursor: cursor,
        itemCount: entity.items.length,
        nextCursor: entity.nextCursor,
      );
      return entity;
    } on OwnerFailure {
      rethrow;
    } on DataParsingException {
      throw const OwnerInvalidDataFailure();
    } on ApiException catch (e) {
      throw mapOwnerReadApiException(e);
    } catch (_) {
      throw const OwnerInvalidDataFailure();
    }
  }

  @override
  Future<OwnerMenu> saveMenu(
    OwnerMenuInput input, {
    required String mutationId,
  }) async {
    if (!isMutationConfigured) {
      throw const OwnerNotConfiguredFailure();
    }
    try {
      final model = await _dataSource.saveMenu(input, mutationId: mutationId);
      return model.toEntity();
    } on OwnerFailure {
      rethrow;
    } on ApiException catch (e) {
      throw mapOwnerMutationApiException(e);
    } catch (_) {
      throw const OwnerUnconfirmedFailure();
    }
  }

  @override
  Future<void> deleteMenu({
    required String id,
    required int expectedVersion,
    required String mutationId,
  }) async {
    if (!isMutationConfigured) {
      throw const OwnerNotConfiguredFailure();
    }
    try {
      await _dataSource.deleteMenu(
        id: id,
        expectedVersion: expectedVersion,
        mutationId: mutationId,
      );
    } on OwnerFailure {
      rethrow;
    } on ApiException catch (e) {
      throw mapOwnerMutationApiException(e);
    } catch (_) {
      throw const OwnerUnconfirmedFailure();
    }
  }

  @override
  Future<OwnerStall> saveStall(
    OwnerStallInput input, {
    required String mutationId,
  }) async {
    if (!isMutationConfigured) {
      throw const OwnerNotConfiguredFailure();
    }
    try {
      final model = await _dataSource.saveStall(input, mutationId: mutationId);
      return model.toEntity();
    } on OwnerFailure {
      rethrow;
    } on ApiException catch (e) {
      throw mapOwnerMutationApiException(e);
    } catch (_) {
      throw const OwnerUnconfirmedFailure();
    }
  }

  @override
  Future<OrderRecordPage> listOrders({
    required String stallId,
    OrderStatus? status,
    String? cursor,
    int limit = 30,
  }) async {
    try {
      final page = await _dataSource.listOrders(
        stallId: stallId,
        status: status,
        cursor: cursor,
        limit: limit,
      );
      final entity = page.toEntity();
      validateCursorPageBounds(
        limit: limit,
        requestCursor: cursor,
        itemCount: entity.items.length,
        nextCursor: entity.nextCursor,
      );
      return entity;
    } on OwnerFailure {
      rethrow;
    } on DataParsingException {
      throw const OwnerInvalidDataFailure();
    } on ApiException catch (e) {
      throw mapOwnerReadApiException(e);
    } catch (_) {
      throw const OwnerInvalidDataFailure();
    }
  }

  @override
  Future<OrderRecord?> getMyOrder({
    required String stallId,
    required String orderId,
  }) async {
    try {
      final model = await _dataSource.getMyOrder(
        stallId: stallId,
        orderId: orderId,
      );
      return model?.toEntity();
    } on OwnerFailure {
      rethrow;
    } on DataParsingException {
      throw const OwnerInvalidDataFailure();
    } on ApiException catch (e) {
      throw mapOwnerReadApiException(e);
    } catch (_) {
      throw const OwnerInvalidDataFailure();
    }
  }

  @override
  Future<OrderRecord> transitionOrder(
    OwnerOrderTransition input, {
    required String mutationId,
  }) async {
    if (!isMutationConfigured) {
      throw const OwnerNotConfiguredFailure();
    }
    try {
      final model = await _dataSource.transitionOrder(
        input,
        mutationId: mutationId,
      );
      return model.toEntity();
    } on OwnerFailure {
      rethrow;
    } on ApiException catch (e) {
      throw mapOwnerMutationApiException(e);
    } catch (_) {
      throw const OwnerUnconfirmedFailure();
    }
  }

  @override
  Future<OwnerMutationLookup> lookupMutation({
    required String mutationId,
  }) async {
    if (!isMutationConfigured) {
      throw const OwnerNotConfiguredFailure();
    }
    if (mutationId.trim().isEmpty) {
      throw const OwnerUnconfirmedFailure();
    }
    try {
      final result = await _dataSource.lookupMutation(mutationId: mutationId);
      if (result.request.mutationId != mutationId) {
        throw const OwnerUnconfirmedFailure();
      }
      return result;
    } on OwnerFailure {
      rethrow;
    } catch (_) {
      throw const OwnerUnconfirmedFailure();
    }
  }
}
