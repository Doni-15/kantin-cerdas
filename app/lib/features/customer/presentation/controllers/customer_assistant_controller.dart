import 'package:characters/characters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/assistant_reply.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_feature_providers.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_read_session.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_feature_failure.dart';

class AssistantTurn {
  const AssistantTurn({required this.question, required this.reply});
  final String question;
  final AssistantReply reply;
}

class CustomerAssistantState {
  CustomerAssistantState({
    List<AssistantTurn> turns = const [],
    this.pending,
    this.error,
  }) : turns = List.unmodifiable(turns);
  final List<AssistantTurn> turns;
  final String? pending;
  final Object? error;
  bool get busy => pending != null;
}

final customerAssistantControllerProvider =
    NotifierProvider.autoDispose<
      CustomerAssistantController,
      CustomerAssistantState
    >(CustomerAssistantController.new, retry: (_, _) => null);

class CustomerAssistantController extends Notifier<CustomerAssistantState> {
  int _generation = 0;
  CustomerReadSession? _session;
  @override
  CustomerAssistantState build() {
    _generation++;
    _session = null;
    try {
      _session = CustomerReadSession(ref);
    } on CustomerFeatureFailure {
      // Router closes protected screens; discard conversation immediately.
    }
    return CustomerAssistantState();
  }

  Future<bool> send(String input) async {
    final message = input.trim();
    if (!_current(_generation) ||
        state.busy ||
        message.isEmpty ||
        message.characters.length > 500) {
      return false;
    }
    final generation = _generation;
    final repository = ref.read(customerAssistantRepositoryProvider);
    final turns = state.turns;
    state = CustomerAssistantState(turns: turns, pending: message);
    try {
      final reply = await repository
          .recommend(message)
          .timeout(const Duration(seconds: 30));
      if (!_current(generation)) return false;
      state = CustomerAssistantState(
        turns: [
          ...turns,
          AssistantTurn(question: message, reply: reply),
        ],
      );
      return true;
    } catch (error) {
      if (!_current(generation)) return false;
      state = CustomerAssistantState(turns: turns, error: error);
      return false;
    }
  }

  bool _current(int generation) {
    if (!ref.mounted || generation != _generation || _session == null) {
      return false;
    }
    try {
      _session!.check(ref);
      return true;
    } on CustomerFeatureFailure {
      return false;
    }
  }

  void clear({required CustomerAssistantState expectedState}) {
    if (!_current(_generation) ||
        state.busy ||
        !identical(state, expectedState)) {
      return;
    }
    _generation++;
    state = CustomerAssistantState();
  }
}
