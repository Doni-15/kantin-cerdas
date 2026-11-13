// Fixture bersama untuk test provider berhalaman: repository admin/owner yang
// sengaja mengembalikan 31 item (melebihi batas 30) dan `ProviderContainer`
// yang sudah menunggu sesi login simulasi selesai.
import 'dart:async';

import 'simulation_harness.dart';

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
