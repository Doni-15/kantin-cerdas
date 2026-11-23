import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/error_presenter.dart';
import 'package:kantin_cerdas/features/ai/application/ai_providers.dart';
import 'package:kantin_cerdas/features/ai/domain/ai_models.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/application/services/require_account_session.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';

class AiChatState {
  const AiChatState({
    this.isLoadingStatus = true,
    this.isSending = false,
    this.status,
    this.messages = const [],
    this.errorMessage,
    this.statusLoadError,
  });

  final bool isLoadingStatus;
  final bool isSending;
  final AiStatusSnapshot? status;
  final List<AiChatMessage> messages;
  final String? errorMessage;
  final Object? statusLoadError;

  AiChatState copyWith({
    bool? isLoadingStatus,
    bool? isSending,
    AiStatusSnapshot? status,
    List<AiChatMessage>? messages,
    String? errorMessage,
    bool clearError = false,
    Object? statusLoadError,
    bool clearStatusError = false,
  }) => AiChatState(
    isLoadingStatus: isLoadingStatus ?? this.isLoadingStatus,
    isSending: isSending ?? this.isSending,
    status: status ?? this.status,
    messages: messages ?? this.messages,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    statusLoadError: clearStatusError
        ? null
        : (statusLoadError ?? this.statusLoadError),
  );
}

class AiChatController extends Notifier<AiChatState> {
  AiChatController(this.accountId);

  final String accountId;
  var _msgSeq = 0;

  @override
  AiChatState build() {
    Future.microtask(loadStatus);
    return const AiChatState();
  }

  Future<void> loadStatus() async {
    if (!ref.mounted) return;
    state = state.copyWith(isLoadingStatus: true, clearStatusError: true);
    try {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        accountId,
      );
      final snapshot = await ref
          .read(aiRepositoryProvider)
          .fetchStatus(session);
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoadingStatus: false,
        status: snapshot,
        clearStatusError: true,
      );
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoadingStatus: false, statusLoadError: error);
    }
  }

  Future<bool> sendMessage(
    String rawText, {
    int? maxBudget,
    bool includeUnavailable = false,
  }) async {
    final text = rawText.trim();
    if (text.isEmpty || state.isSending) return false;

    state = state.copyWith(isSending: true, clearError: true);
    try {
      final session = requireAccountSession(
        ref.read(authControllerProvider).asData?.value,
        accountId,
      );
      final result = await ref
          .read(aiRepositoryProvider)
          .sendChat(
            session,
            message: text,
            maxBudget: maxBudget,
            includeUnavailable: includeUnavailable,
          );
      if (!ref.mounted) return false;

      final currentStatus = state.status;
      final updatedStatus = currentStatus == null
          ? null
          : AiStatusSnapshot(
              providerEnabled: result.providerEnabled,
              providerReady:
                  result.status == AiResponseStatus.aiResponse ||
                  (currentStatus.providerReady &&
                      result.status != AiResponseStatus.quotaExhausted),
              model: result.providerModel.isNotEmpty
                  ? result.providerModel
                  : currentStatus.model,
              fallbackActive: result.fallbackUsed,
              reasonCode: result.fallbackReason ?? currentStatus.reasonCode,
              reasonMessage: currentStatus.reasonMessage,
              quota: result.quota,
            );

      final userMsg = AiChatMessage(
        id: 'u-${++_msgSeq}',
        isUser: true,
        text: text,
      );
      final assistantMsg = AiChatMessage(
        id: 'a-${++_msgSeq}',
        isUser: false,
        text: result.reply,
        status: result.status,
        recommendations: result.recommendations,
        isGeneralCulinary: result.isGeneralCulinary,
        hasUncertaintyNotice: result.hasUncertaintyNotice,
        fallbackUsed: result.fallbackUsed,
        appliedMaxBudget: result.appliedMaxBudget,
      );

      state = state.copyWith(
        isSending: false,
        status: updatedStatus,
        messages: [...state.messages, userMsg, assistantMsg],
        clearError: true,
      );
      return true;
    } on AuthException catch (error) {
      if (!ref.mounted) return false;
      state = state.copyWith(isSending: false, errorMessage: error.message);
      return false;
    } catch (error) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isSending: false,
        errorMessage: presentAppError(
          error,
          fallback: 'Gagal mengirim pesan. Periksa koneksi jaringan Anda.',
        ),
      );
      return false;
    }
  }

  void clearError() {
    if (!ref.mounted) return;
    state = state.copyWith(clearError: true);
  }
}
