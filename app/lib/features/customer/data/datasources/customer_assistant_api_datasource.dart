import 'package:dio/dio.dart';
import 'package:kantin_cerdas/core/network/api_exception_mapper.dart';
import 'package:kantin_cerdas/core/network/app_environment.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';
import 'package:kantin_cerdas/features/customer/data/datasources/customer_assistant_datasource.dart';
import 'package:kantin_cerdas/features/customer/data/models/assistant_reply_model.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_feature_failure.dart';

final class CustomerAssistantApiDataSource
    implements CustomerAssistantDataSource {
  const CustomerAssistantApiDataSource({this.dio});

  final Dio? dio;

  @override
  bool get isConfigured => dio != null && AppEnvironment.isApiConfigured;

  @override
  Future<AssistantReplyModel> recommend(String message) async {
    final client = dio;
    if (!isConfigured || client == null) {
      throw const CustomerFeatureNotConfiguredFailure();
    }
    try {
      final response = await client.post<Object?>(
        '/v1/customer/assistant/recommend',
        data: <String, Object?>{'message': message},
      );
      return AssistantReplyModel.fromJson(
        asJsonMap(response.data, fieldName: 'assistant_reply'),
      );
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}
