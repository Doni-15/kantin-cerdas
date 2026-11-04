import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';

String adminUserRoleLabel(UserRole role) => switch (role) {
  UserRole.customer => 'Pelanggan',
  UserRole.owner => 'Pemilik stan',
  UserRole.admin => 'Admin',
};
String adminUserAccessLabel(bool isActive) => isActive ? 'Aktif' : 'Nonaktif';
