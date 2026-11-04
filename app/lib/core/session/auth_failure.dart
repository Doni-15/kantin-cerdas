/// Kegagalan domain pada operasi autentikasi dan manajemen sesi.
sealed class AuthFailure implements Exception {
  const AuthFailure();

  @override
  String toString() => runtimeType.toString();
}

final class AuthInvalidCredentialsFailure extends AuthFailure {
  const AuthInvalidCredentialsFailure();
}

final class AuthAccountDisabledFailure extends AuthFailure {
  const AuthAccountDisabledFailure();
}

final class AuthUsernameTakenFailure extends AuthFailure {
  const AuthUsernameTakenFailure();
}

final class AuthEmailTakenFailure extends AuthFailure {
  const AuthEmailTakenFailure();
}

final class AuthInvalidCurrentPasswordFailure extends AuthFailure {
  const AuthInvalidCurrentPasswordFailure();
}

final class AuthSessionExpiredFailure extends AuthFailure {
  const AuthSessionExpiredFailure();
}

/// Kesalahan input berdasarkan nama field yang digunakan aplikasi.
final class AuthValidationFailure extends AuthFailure {
  AuthValidationFailure(Map<String, String> fieldErrors)
    : fieldErrors = Map<String, String>.unmodifiable(fieldErrors);

  final Map<String, String> fieldErrors;
}

/// Koneksi gagal atau permintaan melewati batas waktu.
final class AuthNetworkFailure extends AuthFailure {
  const AuthNetworkFailure();
}

/// Layanan backend gagal memproses permintaan.
final class AuthServerFailure extends AuthFailure {
  const AuthServerFailure();
}

/// Penyimpanan, pembacaan, atau penghapusan sesi lokal gagal.
final class AuthStorageFailure extends AuthFailure {
  const AuthStorageFailure();
}

/// Kegagalan yang belum memiliki kategori khusus.
final class AuthUnexpectedFailure extends AuthFailure {
  const AuthUnexpectedFailure();
}

final class AuthOperationInProgressFailure extends AuthFailure {
  const AuthOperationInProgressFailure();
}

final class AuthOperationSupersededFailure extends AuthFailure {
  const AuthOperationSupersededFailure();
}

/// Layanan membatasi frekuensi permintaan. Bukan bukti keberadaan akun.
final class AuthRateLimitedFailure extends AuthFailure {
  const AuthRateLimitedFailure();
}

/// Permintaan email mungkin diterima, tetapi respons tidak terkonfirmasi.
final class AuthPasswordResetUnconfirmedFailure extends AuthFailure {
  const AuthPasswordResetUnconfirmedFailure();
}

final class AuthNotConfiguredFailure extends AuthFailure {
  const AuthNotConfiguredFailure();
}
