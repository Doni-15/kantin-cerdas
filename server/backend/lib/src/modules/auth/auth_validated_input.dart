import 'dart:typed_data';

/// Hasil input registrasi yang sudah dinormalisasi dan tervalidasi.
final class ValidatedRegisterInput {
  final String name;
  final String username;
  final String email;
  final String password;
  final Uint8List? avatarBytes;
  final String? avatarMimeType;
  final String? avatarExtension;

  const ValidatedRegisterInput({
    required this.name,
    required this.username,
    required this.email,
    required this.password,
    this.avatarBytes,
    this.avatarMimeType,
    this.avatarExtension,
  });
}

/// Hasil input login yang sudah dinormalisasi dan tervalidasi.
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

/// Hasil input ubah password yang sudah tervalidasi.
final class ValidatedChangePasswordInput {
  final String currentPassword;
  final String newPassword;

  const ValidatedChangePasswordInput({
    required this.currentPassword,
    required this.newPassword,
  });
}

/// Hasil input pembaruan foto profil (avatar) yang sudah tervalidasi.
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