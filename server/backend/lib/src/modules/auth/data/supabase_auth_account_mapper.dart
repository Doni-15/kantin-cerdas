import 'package:kantin_cerdas_backend/src/modules/auth/domain/auth_gateway.dart';
import 'package:supabase/supabase.dart';

AuthAccount mapSupabaseUserToAccount(User user) {
  final email = user.email;
  if (email == null || email.isEmpty || user.emailConfirmedAt == null) {
    throw AuthFailure.emailNotVerified;
  }
  final role = switch (user.appMetadata['kantin_role']) {
    'owner' => AccountRole.owner,
    'admin' => AccountRole.admin,
    _ => AccountRole.customer,
  };
  final metadata = user.userMetadata;
  final identities = user.identities ?? const [];
  final googleIdentity = identities
      .where((item) => item.provider == 'google')
      .firstOrNull;
  final googleData = googleIdentity?.identityData;
  return AuthAccount(
    id: user.id,
    email: email,
    role: role,
    displayName: _sanitizeDisplayName(metadata?['display_name']),
    suggestedName: _sanitizeDisplayName(
      metadata?['registration_name'] ??
          googleData?['full_name'] ??
          googleData?['name'] ??
          (googleIdentity != null
              ? (metadata?['full_name'] ?? metadata?['name'])
              : null),
    ),
    googlePhoto: _allowlistedGooglePhoto(
      googleData?['picture'] ??
          googleData?['avatar_url'] ??
          (googleIdentity != null
              ? (metadata?['picture'] ?? metadata?['avatar_url'])
              : null),
    ),
    canManageCredentials: identities.any((item) => item.provider == 'email'),
  );
}

Uri? _allowlistedGooglePhoto(Object? value) {
  if (value is! String || value.length > 2048) return null;
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.scheme != 'https' ||
      !RegExp(r'^lh[0-9]+\.googleusercontent\.com$').hasMatch(uri.host) ||
      uri.hasPort ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment) {
    return null;
  }
  return uri;
}

String? _sanitizeDisplayName(Object? value) {
  if (value is! String || value.length > 240) return null;
  final name = value.trim();
  if (name.isEmpty ||
      name.runes.length > 80 ||
      RegExp(r'[\x00-\x1f\x7f]').hasMatch(name)) {
    return null;
  }
  return name;
}
