/// Satu sumber aturan validasi Auth.
/// Dipakai UI (feedback cepat), UseCase (pengaman), dan dummy (meniru 422 Backend).
abstract final class AuthValidator {
  static const minPasswordLength = 6;
  static const minUsernameLength = 3;
  static const maxUsernameLength = 20;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _usernamePattern = RegExp(r'^[a-z0-9_.]+$');

  static String? identifier(String value) {
    if (value.trim().isEmpty) {
      return 'Username atau email wajib diisi';
    }

    return null;
  }

  /// Login sengaja tidak membatasi panjang password agar akun lama tetap bisa masuk.
  static String? loginPassword(String value) {
    if (value.isEmpty) {
      return 'Password wajib diisi';
    }

    return null;
  }

  static String? name(String value) {
    if (value.trim().isEmpty) {
      return 'Nama wajib diisi';
    }

    return null;
  }

  static String? email(String value) {
    final email = value.trim();

    if (email.isEmpty) {
      return 'Email wajib diisi';
    }

    if (!_emailPattern.hasMatch(email)) {
      return 'Format email tidak valid';
    }

    return null;
  }

  /// Input dinormalisasi ke huruf kecil sebelum dicek.
  static String? username(String value) {
    final username = value.trim().toLowerCase();

    if (username.isEmpty) {
      return 'Username wajib diisi';
    }

    if (username.length < minUsernameLength ||
        username.length > maxUsernameLength) {
      return 'Username harus $minUsernameLength-$maxUsernameLength karakter';
    }

    if (!_usernamePattern.hasMatch(username)) {
      return 'Username hanya boleh huruf, angka, titik, dan underscore';
    }

    return null;
  }

  static String? password(String value) {
    if (value.isEmpty) {
      return 'Password wajib diisi';
    }

    if (value.length < minPasswordLength) {
      return 'Password minimal $minPasswordLength karakter';
    }

    return null;
  }

  /// Password saat ini: hanya wajib diisi (panjang tidak dicek, sama seperti login).
  static String? currentPassword(String value) {
    if (value.isEmpty) {
      return 'Password saat ini wajib diisi';
    }

    return null;
  }

  /// Password baru: aturan sama dengan registrasi dan harus berbeda dari
  /// password saat ini.
  static String? newPassword(String current, String value) {
    if (value.isEmpty) {
      return 'Password baru wajib diisi';
    }

    final error = password(value);
    if (error != null) {
      return error;
    }

    if (value == current) {
      return 'Password baru tidak boleh sama dengan password saat ini';
    }

    return null;
  }

  static String? confirmPassword(String password, String confirmation) {
    if (confirmation.isEmpty) {
      return 'Konfirmasi password wajib diisi';
    }

    if (password != confirmation) {
      return 'Konfirmasi password tidak sesuai';
    }

    return null;
  }
}
