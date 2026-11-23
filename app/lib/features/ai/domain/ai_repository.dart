import 'package:kantin_cerdas/features/ai/domain/ai_models.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';

abstract class AiRepository {
  Future<AiStatusSnapshot> fetchStatus(AuthSession session);

  Future<AiChatResult> sendChat(
    AuthSession session, {
    required String message,
    int? maxBudget,
    bool includeUnavailable = false,
  });

  Future<({List<AiMenuRecommendation> items, AiQuotaSnapshot quota})>
  fetchRecommendations(
    AuthSession session, {
    String query = '',
    int? maxBudget,
    bool includeUnavailable = false,
  });
}
