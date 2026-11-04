import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_assistant_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/mappers/customer_failure_mapper.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/assistant_reply.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_feature_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/repositories/customer_assistant_repository.dart';

final class CustomerAssistantRepositoryImpl
    implements CustomerAssistantRepository {
  const CustomerAssistantRepositoryImpl({required this._dataSource});

  final CustomerAssistantDataSource _dataSource;

  @override
  Future<AssistantReply> recommend(String message) async {
    if (message.trim().isEmpty) {
      throw const CustomerFeatureRejectedFailure();
    }
    try {
      final model = await _dataSource.recommend(message.trim());
      return model.toEntity();
    } on CustomerFeatureFailure {
      rethrow;
    } on DataParsingException {
      throw const CustomerFeatureInvalidDataFailure();
    } on ApiException catch (e) {
      throw mapCustomerReadApiException(e, mapBadRequestToRejected: true);
    } catch (_) {
      throw const CustomerFeatureInvalidDataFailure();
    }
  }
}
