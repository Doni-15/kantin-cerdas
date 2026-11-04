import 'package:kantin_cerdas/features/customer/data/models/assistant_reply_model.dart';

abstract interface class CustomerAssistantDataSource {
  bool get isConfigured;
  Future<AssistantReplyModel> recommend(String message);
}
