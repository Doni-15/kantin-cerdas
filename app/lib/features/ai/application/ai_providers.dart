import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/ai/application/ai_chat_controller.dart';
import 'package:kantin_cerdas/features/ai/data/ai_api_repository.dart';
import 'package:kantin_cerdas/features/ai/domain/ai_repository.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';

final aiRepositoryProvider = Provider<AiRepository>(
  (ref) => AiApiRepository(ref.watch(authRepositoryProvider)),
);

final aiChatControllerProvider = NotifierProvider.autoDispose
    .family<AiChatController, AiChatState, String>(AiChatController.new);
