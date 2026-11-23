import 'package:kantin_cerdas/features/auth/domain/models/auth_json.dart';

enum AuthRole {
  customer('Pelanggan'),
  owner('Pemilik stan'),
  admin('Administrator');

  const AuthRole(this.label);
  final String label;
}

class AuthAccount {
  AuthAccount.fromJson(Map<String, dynamic> json)
    : id = requiredAuthText(json, 'id'),
      email = requiredAuthText(json, 'email'),
      role = switch (json['role']) {
        'customer' => AuthRole.customer,
        'owner' => AuthRole.owner,
        'admin' => AuthRole.admin,
        _ => throw const FormatException('Unknown account role'),
      },
      displayName = optionalAuthText(json, 'display_name'),
      suggestedName = optionalAuthText(json, 'suggested_name'),
      hasPhoto = json['has_photo'] == true,
      profileComplete = json['profile_complete'] == true,
      googlePhoto = optionalAuthText(json, 'google_photo'),
      canManageCredentials = json['can_manage_credentials'] == true;

  final String id;
  final String email;
  final AuthRole role;
  final String? displayName;
  final String? suggestedName;
  final bool hasPhoto;
  final bool profileComplete;
  final String? googlePhoto;
  final bool canManageCredentials;
}
