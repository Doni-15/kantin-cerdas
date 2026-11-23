import 'package:kantin_cerdas/features/ai/data/ai_error_mapper.dart';
import 'package:kantin_cerdas/features/ai/domain/ai_models.dart';
import 'package:kantin_cerdas/features/ai/domain/ai_repository.dart';
import 'package:kantin_cerdas/features/auth/data/auth_repository.dart';

class AiApiRepository implements AiRepository {
  const AiApiRepository(this._auth);

  final AuthRepository _auth;

  @override
  Future<AiStatusSnapshot> fetchStatus(AuthSession session) async {
    final data = await _auth.sendAuthenticated(session, 'GET', const [
      'ai',
      'status',
    ], onEnvelopeError: mapAiEnvelopeError);
    return _decode(
      () => AiStatusSnapshot.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<AiChatResult> sendChat(
    AuthSession session, {
    required String message,
    int? maxBudget,
    bool includeUnavailable = false,
  }) async {
    final data = await _auth.sendAuthenticated(
      session,
      'POST',
      const ['ai', 'chat'],
      body: {
        'message': message,
        'max_budget': ?maxBudget,
        'include_unavailable': includeUnavailable,
      },
      onEnvelopeError: mapAiEnvelopeError,
    );
    return _decode(() => AiChatResult.fromJson(data as Map<String, dynamic>));
  }

  @override
  Future<({List<AiMenuRecommendation> items, AiQuotaSnapshot quota})>
  fetchRecommendations(
    AuthSession session, {
    String query = '',
    int? maxBudget,
    bool includeUnavailable = false,
  }) async {
    final queryParams = <String, String>{
      if (query.trim().isNotEmpty) 'q': query.trim(),
      if (maxBudget != null) 'max_budget': '$maxBudget',
      if (includeUnavailable) 'include_unavailable': 'true',
    };
    final data = await _auth.sendAuthenticated(
      session,
      'GET',
      const ['ai', 'recommendations'],
      query: queryParams.isEmpty ? null : queryParams,
      onEnvelopeError: mapAiEnvelopeError,
    );
    return _decode(() {
      final map = data as Map<String, dynamic>;
      final rawItems = map['items'] as List<dynamic>? ?? const [];
      return (
        items: [
          for (final item in rawItems)
            AiMenuRecommendation.fromJson(item as Map<String, dynamic>),
        ],
        quota: AiQuotaSnapshot.fromJson(
          map['quota'] as Map<String, dynamic>? ?? const {},
        ),
      );
    });
  }

  T _decode<T>(T Function() parse) {
    try {
      return parse();
    } on TypeError {
      throw const AuthException(
        'INVALID_RESPONSE',
        'Format respons Food Assistant tidak dikenali.',
      );
    } on FormatException {
      throw const AuthException(
        'INVALID_RESPONSE',
        'Format respons Food Assistant tidak dikenali.',
      );
    }
  }
}
