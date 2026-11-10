final class ValidatedRegisterInput {
  final String name;
  final String username;
  final String email;
  final String password;

  const ValidatedRegisterInput({
    required this.name,
    required this.username,
    required this.email,
    required this.password,
  });
}

final class ValidatedLoginInput {
  final String identifier;
  final String password;
  final bool isEmail;

  const ValidatedLoginInput({
    required this.identifier,
    required this.password,
    required this.isEmail,
  });
}

final class ValidatedChangePasswordInput {
  final String currentPassword;
  final String newPassword;

  const ValidatedChangePasswordInput({
    required this.currentPassword,
    required this.newPassword,
  });
}

final class ValidatedAvatarUpdateInput {
  final String mutationId;
  final String? avatarUrl;
  final int? expectedVersion;

  const ValidatedAvatarUpdateInput({
    required this.mutationId,
    required this.avatarUrl,
    required this.expectedVersion,
  });
}