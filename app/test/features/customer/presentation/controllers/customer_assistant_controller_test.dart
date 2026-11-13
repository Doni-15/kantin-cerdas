import 'dart:async';

import 'package:kantin_cerdas/features/customer/presentation/controllers/customer_assistant_controller.dart';

import '../../../../support/paged_session_container.dart';
import '../../../../support/simulation_harness.dart';

class DeferredAssistant implements CustomerAssistantRepository {
  final reply = Completer<AssistantReply>();
  @override
  Future<AssistantReply> recommend(String message) => reply.future;
}

void main() {
  group('CustomerAssistantController dan sesi', () {
    test(
      'assistant clears private state on logout and ignores the late reply',
      () async {
        final repo = DeferredAssistant();
        final c = await makeContainer(
          SimulationStore.memory(),
          'pelanggan',
          assistant: repo,
        );
        c.listen(customerAssistantControllerProvider, (_, _) {});
        final pending = c
            .read(customerAssistantControllerProvider.notifier)
            .send('Menu siang');
        await c.read(authStateProvider.notifier).logout();
        final empty = c.read(customerAssistantControllerProvider);
        expect(empty.turns, isEmpty);
        expect(empty.pending, isNull);
        repo.reply.complete(
          AssistantReply(message: 'Jawaban sesi lama', menus: []),
        );
        expect(await pending, isFalse);
        expect(c.read(customerAssistantControllerProvider).turns, isEmpty);
      },
    );
  });
}
