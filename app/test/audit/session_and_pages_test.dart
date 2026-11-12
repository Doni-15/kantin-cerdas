import 'dart:async';
import '../support/simulation_harness.dart';
import 'package:kantin_cerdas/features/customer/presentation/controllers/customer_assistant_controller.dart';

class LargeAdminPage extends SimulationAdminRepository {
  LargeAdminPage(super.store);
  @override
  Future<AdminUserPage> listUsers({
    required String search,
    String? cursor,
    int limit = 30,
  }) async => AdminUserPage(
    users: [
      for (var i = 0; i < 31; i++)
        User(
          id: 'u$i',
          username: 'u$i',
          email: 'u$i@example.test',
          name: 'User $i',
          role: UserRole.customer,
          isActive: true,
        ),
    ],
  );
  @override
  Future<AdminApplicationPage> listApplications({
    CanteenApplicationStatus? status,
    String? cursor,
    int limit = 30,
  }) async => AdminApplicationPage(
    items: [
      for (var i = 0; i < 31; i++)
        CanteenApplication(
          id: 'a$i',
          applicantId: 'u$i',
          name: 'Stan $i',
          description: 'Makanan',
          location: 'A',
          phone: '081234567890',
          status: CanteenApplicationStatus.submitted,
          createdAt: DateTime.utc(2026),
          version: 1,
        ),
    ],
  );
}

class LargeOwnerPage extends SimulationOwnerRepository {
  LargeOwnerPage(super.store);
  @override
  Future<OwnerMenuPage> listMenus({
    required String stallId,
    required String search,
    bool? available,
    String? cursor,
    int limit = 30,
  }) async => OwnerMenuPage(
    items: [
      for (var i = 0; i < 31; i++)
        OwnerMenu(
          id: 'm$i',
          stallId: stallId,
          name: 'Menu $i',
          description: '',
          category: OwnerMenuCategory.rice,
          priceIdr: 10000,
          isAvailable: true,
          version: 1,
        ),
    ],
  );
}

class DeferredAssistant implements CustomerAssistantRepository {
  final reply = Completer<AssistantReply>();
  @override
  Future<AssistantReply> recommend(String message) => reply.future;
}

Future<ProviderContainer> makeContainer(
  SimulationStore store,
  String username, {
  CustomerAssistantRepository? assistant,
}) async {
  final auth = SimulationAuthRepository(store);
  await auth.login(identifier: username, password: 'Simulasi123!');
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      adminRepositoryProvider.overrideWithValue(LargeAdminPage(store)),
      ownerRepositoryProvider.overrideWithValue(LargeOwnerPage(store)),
      if (assistant != null)
        customerAssistantRepositoryProvider.overrideWithValue(assistant),
    ],
  );
  addTearDown(container.dispose);
  final ready = Completer<void>();
  container.listen(authStateProvider, (_, next) {
    if (!next.isLoading && !ready.isCompleted) {
      if (next.hasError) {
        ready.completeError(next.error!, next.stackTrace);
      } else {
        ready.complete();
      }
    }
  }, fireImmediately: true);
  await ready.future.timeout(const Duration(seconds: 3));
  return container;
}

void main() {
  testWidgets('logout cancels an earlier delayed simulation login', (
    tester,
  ) async {
    final store = SimulationStore.memory()
      ..latency = const Duration(seconds: 1);
    final auth = SimulationAuthRepository(store);
    final pending = auth.login(
      identifier: 'pelanggan',
      password: 'Simulasi123!',
    );
    final rejected = expectLater(
      pending,
      throwsA(isA<AuthOperationSupersededFailure>()),
    );
    await auth.logout();
    await tester.pump(const Duration(seconds: 1));
    await rejected;
    expect(store.sessionUser, isNull);
  });
  testWidgets('reset cannot be undone by a pending simulation login', (
    tester,
  ) async {
    final store = SimulationStore.memory()
      ..latency = const Duration(seconds: 1);
    final auth = SimulationAuthRepository(store);
    final pending = auth.login(
      identifier: 'pelanggan',
      password: 'Simulasi123!',
    );
    final rejected = expectLater(
      pending,
      throwsA(isA<AuthOperationSupersededFailure>()),
    );
    await store.reset();
    await tester.pump(const Duration(seconds: 1));
    await rejected;
    expect(store.sessionUser, isNull);
  });
  testWidgets('a delayed login cannot replace a newer account', (tester) async {
    final store = SimulationStore.memory()
      ..latency = const Duration(seconds: 1);
    final auth = SimulationAuthRepository(store);
    final old = auth.login(identifier: 'pelanggan', password: 'Simulasi123!');
    final rejected = expectLater(
      old,
      throwsA(isA<AuthOperationSupersededFailure>()),
    );
    store.latency = Duration.zero;
    final owner = await auth.login(
      identifier: 'pemilik',
      password: 'Simulasi123!',
    );
    await tester.pump(const Duration(seconds: 1));
    await rejected;
    expect(store.sessionUser!.id, owner.id);
  });
  test(
    'admin user feed rejects a page larger than the requested limit',
    () async {
      final c = await makeContainer(SimulationStore.memory(), 'admin');
      final p = adminUsersProvider((search: '', cursor: null));
      c.listen(p, (_, _) {});
      await expectLater(
        c.read(p.future),
        throwsA(isA<AdminInvalidDataFailure>()),
      );
    },
  );
  test(
    'admin application feed rejects a page larger than the requested limit',
    () async {
      final c = await makeContainer(SimulationStore.memory(), 'admin');
      final p = adminApplicationsProvider((status: null, cursor: null));
      c.listen(p, (_, _) {});
      await expectLater(
        c.read(p.future),
        throwsA(isA<AdminInvalidDataFailure>()),
      );
    },
  );
  test(
    'owner menu feed rejects a page larger than the requested limit',
    () async {
      final c = await makeContainer(SimulationStore.memory(), 'pemilik');
      final p = ownerMenusProvider((search: '', available: null, cursor: null));
      c.listen(p, (_, _) {});
      await expectLater(
        c.read(p.future),
        throwsA(isA<OwnerInvalidDataFailure>()),
      );
    },
  );
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
}
