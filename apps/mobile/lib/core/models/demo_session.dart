enum DemoRole { student, manager }

/// Sesi contoh lokal; bukan autentikasi backend.
class DemoSession {
  const DemoSession.student()
    : role = DemoRole.student,
      name = 'Doni',
      email = 'doni@example.com',
      stallId = null;

  const DemoSession.manager()
    : role = DemoRole.manager,
      name = 'Bu Rina',
      email = 'rina@example.com',
      stallId = 'dapur-bu-rina';

  final DemoRole role;
  final String name;
  final String email;
  final String? stallId;
}
