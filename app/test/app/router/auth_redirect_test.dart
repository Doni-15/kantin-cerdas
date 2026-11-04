import '../../support/simulation_harness.dart';

void main() {
  User user(UserRole role, {bool active = true}) => User(
    id: 'u',
    username: 'u',
    email: 'u@example.test',
    name: 'U',
    role: role,
    isActive: active,
  );
  test(
    'owner retains personal routes; customer/admin cannot manage a stall',
    () {
      expect(
        authDestinationForRole(Routes.customerOrders, UserRole.owner),
        Routes.customerOrders,
      );
      expect(
        authDestinationForRole(Routes.ownerDashboard, UserRole.customer),
        isNull,
      );
      expect(
        authDestinationForRole(Routes.customerOrders, UserRole.admin),
        isNull,
      );
      expect(authDestinationForRole(Routes.adminUsers, UserRole.owner), isNull);
    },
  );
  test('external, nested and unknown destinations are rejected', () {
    for (final path in [
      'https://evil.test',
      '//evil.test',
      '/customer/unknown',
      '/customer/home?next=/admin/users',
    ]) {
      expect(validatedAuthDestination(path), isNull);
    }
  });
  test('loading/error/disabled sessions cannot enter private routes', () {
    for (final state in [
      const AsyncLoading<User?>(),
      AsyncError<User?>(StateError('x'), StackTrace.current),
      AsyncData<User?>(user(UserRole.customer, active: false)),
    ]) {
      expect(
        authRedirect(authState: state, path: Routes.customerOrders),
        isNotNull,
      );
    }
  });
  test('public pages remain accessible and role redirects have no loop', () {
    expect(
      authRedirect(authState: const AsyncData<User?>(null), path: Routes.help),
      isNull,
    );
    for (final role in UserRole.values) {
      final state = AsyncData<User?>(user(role));
      final home = authRedirect(authState: state, path: Routes.login)!;
      expect(authRedirect(authState: state, path: home), isNull);
    }
  });
}
