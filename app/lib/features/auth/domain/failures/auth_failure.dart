/// Error yang dipahami Controller/UI. Teks untuk user ada di Presentation
/// (lihat auth_error_message.dart), bukan di sini.
sealed class AuthFailure implements Exception {
  const AuthFailure();

  @override
  String toString() => runtimeType.toString();
}

final class InvalidCredentialsFailure extends AuthFailure {
  const InvalidCredentialsFailure();
}

final class AccountDisabledFailure extends AuthFailure {
  const AccountDisabledFailure();
}

final class UsernameTakenFailure extends AuthFailure {
  const UsernameTakenFailure();
}

final class EmailTakenFailure extends AuthFailure {
  const EmailTakenFailure();
}

/// Input tidak valid. Key = nama field (name, username, email, password, identifier).
final class ValidationFailure extends AuthFailure {
  const ValidationFailure(this.fieldErrors);

  final Map<String, String> fieldErrors;
}

/// Tidak ada koneksi atau timeout.
final class NetworkFailure extends AuthFailure {
  const NetworkFailure();
}

/// Server error atau response tidak sesuai kontrak.
final class UnknownFailure extends AuthFailure {
  const UnknownFailure();
}

/// Password saat ini yang dimasukkan user tidak cocok.
final class InvalidCurrentPasswordFailure extends AuthFailure {
  const InvalidCurrentPasswordFailure();
}

/// Token tidak ada / ditolak / kedaluwarsa saat aksi yang butuh login.
final class SessionExpiredFailure extends AuthFailure {
  const SessionExpiredFailure();
}
