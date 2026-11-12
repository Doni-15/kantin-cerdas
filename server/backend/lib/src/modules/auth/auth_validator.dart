import 'dart:convert';

import 'dart:typed_data';

import 'package:characters/characters.dart';
import 'package:kantin_cerdas_backend/src/core/constants/security_constants.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/security/image_guard.dart';
import 'package:kantin_cerdas_backend/src/core/security/media_paths.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/auth_validated_input.dart';

export 'package:kantin_cerdas_backend/src/modules/auth/auth_validated_input.dart';

final class AuthValidator {
  const AuthValidator._();

  /// Memvalidasi body JSON `POST /v1/auth/availability`.
  static ({String? email, String? username}) validateAvailability(Map<String, Object?> body) {
    final rawEmail = _readString(body['email']).trim().toLowerCase();
    final rawUsername = _readString(body['username']).trim().toLowerCase();

    if (rawEmail.isEmpty && rawUsername.isEmpty) {
      throw ApiException.unprocessable(
        'Minimal salah satu dari email atau username wajib diisi.',
        code: 'INVALID_INPUT',
      );
    }

    if (rawEmail.isNotEmpty &&
        (rawEmail.length < 3 || rawEmail.length > 254 || !SecurityConstants.emailPattern.hasMatch(rawEmail))) {
      throw ApiException.unprocessable(
        'Format alamat email tidak valid.',
        code: 'INVALID_INPUT',
        fieldErrors: const {'email': 'Format alamat email tidak valid.'},
      );
    }

    if (rawUsername.isNotEmpty &&
        (rawUsername.length < 3 ||
            rawUsername.length > 20 ||
            !SecurityConstants.usernamePattern.hasMatch(rawUsername))) {
      throw ApiException.unprocessable(
        'Format username tidak valid.',
        code: 'INVALID_INPUT',
        fieldErrors: const {'username': 'Format username tidak valid.'},
      );
    }

    return (
      email: rawEmail.isEmpty ? null : rawEmail,
      username: rawUsername.isEmpty ? null : rawUsername,
    );
  }

  /// Memvalidasi body JSON `POST /v1/auth/register`.
  static ValidatedRegisterInput validateRegister(
    Map<String, Object?> body,
    StorageConfig storage,
  ) {
    final fieldErrors = <String, String>{};

    final rawName = _readString(body['name']).trim();
    final rawUsername = _readString(body['username']).trim();
    final rawEmail = _readString(body['email']).trim().toLowerCase();
    final rawPassword = _readString(body['password']);

    final nameGraphemes = rawName.characters.length;
    if (rawName.isEmpty) {
      fieldErrors['name'] = 'Nama lengkap wajib diisi.';
    } else if (nameGraphemes > 120 || rawName.length > 480) {
      fieldErrors['name'] = 'Nama lengkap maksimal 120 karakter.';
    }

    if (rawUsername.isEmpty) {
      fieldErrors['username'] = 'Username wajib diisi.';
    } else if (rawUsername.length < 3 || rawUsername.length > 20) {
      fieldErrors['username'] =
          'Username wajib terdiri dari 3 hingga 20 karakter.';
    } else if (!SecurityConstants.usernamePattern.hasMatch(rawUsername)) {
      fieldErrors['username'] =
          'Username hanya boleh menggunakan huruf, angka, titik (.), atau garis bawah (_).';
    }

    final emailGraphemes = rawEmail.characters.length;
    if (rawEmail.isEmpty) {
      fieldErrors['email'] = 'Alamat email wajib diisi.';
    } else if (rawEmail.length < 3 ||
        emailGraphemes > 254 ||
        rawEmail.length > 254 ||
        !SecurityConstants.emailPattern.hasMatch(rawEmail)) {
      fieldErrors['email'] = 'Format alamat email tidak valid.';
    }

    final passwordGraphemes = rawPassword.characters.length;
    if (rawPassword.isEmpty) {
      fieldErrors['password'] = 'Password wajib diisi.';
    } else if (passwordGraphemes < 6 || passwordGraphemes > 128) {
      fieldErrors['password'] =
          'Password wajib terdiri dari 6 hingga 128 karakter.';
    }

    Uint8List? avatarBytes;
    String? avatarMimeType;
    String? avatarExtension;

    final rawAvatarBase64 = _readString(
      body['avatar_base64'] ?? body['avatarBase64'],
    ).trim();
    if (rawAvatarBase64.isNotEmpty) {
      try {
        final decoded = base64Decode(rawAvatarBase64);
        final validatedAvatar = ImageGuard.validate(decoded, storage);
        avatarBytes = validatedAvatar.bytes;
        avatarMimeType = validatedAvatar.mimeType;
        avatarExtension = validatedAvatar.extension;
      } on ApiException catch (e) {
        fieldErrors['avatar'] = e.message;
      } on FormatException {
        fieldErrors['avatar'] = 'Encoding Base64 foto profil tidak valid.';
      }
    }

    if (fieldErrors.isNotEmpty) {
      throw ApiException.unprocessable(
        fieldErrors.values.first,
        code: 'INVALID_INPUT',
        fieldErrors: fieldErrors,
      );
    }

    return ValidatedRegisterInput(
      name: rawName,
      username: rawUsername,
      email: rawEmail,
      password: rawPassword,
      avatarBytes: avatarBytes,
      avatarMimeType: avatarMimeType,
      avatarExtension: avatarExtension,
    );
  }

  /// Memvalidasi body JSON `POST /v1/auth/login`.
  static ValidatedLoginInput validateLogin(Map<String, Object?> body) {
    final fieldErrors = <String, String>{};

    final rawIdentifier = _readString(
      body['identifier'] ?? body['username'] ?? body['email'],
    ).trim();
    final rawPassword = _readString(body['password']);

    if (rawIdentifier.isEmpty) {
      fieldErrors['identifier'] = 'Username atau email wajib diisi.';
    } else if (rawIdentifier.characters.length > 254) {
      fieldErrors['identifier'] = 'Username atau email terlalu panjang.';
    }

    if (rawPassword.isEmpty) {
      fieldErrors['password'] = 'Password wajib diisi.';
    } else if (rawPassword.characters.length > 128) {
      fieldErrors['password'] = 'Password maksimal 128 karakter.';
    }

    if (fieldErrors.isNotEmpty) {
      throw ApiException.unprocessable(
        fieldErrors.values.first,
        code: 'INVALID_INPUT',
        fieldErrors: fieldErrors,
      );
    }

    final isEmail = rawIdentifier.contains('@');
    if (isEmail && !SecurityConstants.emailPattern.hasMatch(rawIdentifier)) {
      throw ApiException.unprocessable(
        'Format alamat email tidak valid.',
        code: 'INVALID_INPUT',
        fieldErrors: const {'identifier': 'Format alamat email tidak valid.'},
      );
    }
    if (!isEmail &&
        (rawIdentifier.length < 3 ||
            rawIdentifier.length > 20 ||
            !SecurityConstants.usernamePattern.hasMatch(rawIdentifier))) {
      throw ApiException.unprocessable(
        'Format username tidak valid.',
        code: 'INVALID_INPUT',
        fieldErrors: const {'identifier': 'Format username tidak valid.'},
      );
    }

    return ValidatedLoginInput(
      identifier: isEmail ? rawIdentifier.toLowerCase() : rawIdentifier,
      password: rawPassword,
      isEmail: isEmail,
    );
  }

  /// Memvalidasi body JSON `POST /v1/auth/refresh`.
  static String validateRefreshToken(Map<String, Object?> body) {
    final token = _readString(
      body['refresh_token'] ?? body['refreshToken'],
    ).trim();

    if (token.isEmpty) {
      throw ApiException.unauthenticated(
        'Refresh token wajib disertakan.',
        'INVALID_TOKEN',
      );
    }
    return token;
  }

  /// Memvalidasi body JSON `POST /v1/auth/change-password`.
  static ValidatedChangePasswordInput validateChangePassword(
    Map<String, Object?> body,
  ) {
    final fieldErrors = <String, String>{};

    final currentPassword = _readString(
      body['current_password'] ?? body['currentPassword'],
    );
    final newPassword = _readString(
      body['new_password'] ?? body['newPassword'],
    );

    if (currentPassword.isEmpty) {
      fieldErrors['current_password'] = 'Password saat ini wajib diisi.';
    }

    final newLen = newPassword.characters.length;
    if (newPassword.isEmpty) {
      fieldErrors['new_password'] = 'Password baru wajib diisi.';
    } else if (newLen < 6 || newLen > 128) {
      fieldErrors['new_password'] =
          'Password baru wajib terdiri dari 6 hingga 128 karakter.';
    } else if (currentPassword.isNotEmpty && currentPassword == newPassword) {
      fieldErrors['new_password'] =
          'Password baru harus berbeda dari password saat ini.';
    }

    if (fieldErrors.isNotEmpty) {
      throw ApiException.unprocessable(
        fieldErrors.values.first,
        code: 'INVALID_INPUT',
        fieldErrors: fieldErrors,
      );
    }

    return ValidatedChangePasswordInput(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  /// Memvalidasi body JSON `POST /v1/auth/password-reset`.
  static String validatePasswordResetEmail(Map<String, Object?> body) {
    final rawEmail = _readString(body['email']).trim().toLowerCase();
    if (rawEmail.isEmpty ||
        rawEmail.length < 3 ||
        rawEmail.characters.length > 254 ||
        rawEmail.length > 254 ||
        !SecurityConstants.emailPattern.hasMatch(rawEmail)) {
      throw ApiException.unprocessable(
        'Format alamat email tidak valid.',
        code: 'INVALID_INPUT',
        fieldErrors: const {'email': 'Format alamat email tidak valid.'},
      );
    }
    return rawEmail;
  }

  /// Memvalidasi header `Idempotency-Key` dan body JSON `PUT /v1/auth/profile/avatar`.
  ///
  /// - `Idempotency-Key` WAJIB (kunci acak otomatis membuat retry menjadi
  ///   mutasi baru).
  /// - Key `avatar_url` WAJIB ada: `null` = hapus foto, string = URL baru.
  ///   Body `{}` atau salah ketik nama key ditolak, bukan menghapus avatar.
  /// - URL harus berada di bawah `STORAGE_PUBLIC_BASE_URL` dan merupakan
  ///   avatar milik actor yang sedang login.
  static ValidatedAvatarUpdateInput validateAvatarUpdate({
    required String? idempotencyKeyHeader,
    required Map<String, Object?> body,
    required String actorId,
    required String publicBaseUrl,
  }) {
    var mutationId = (idempotencyKeyHeader ?? '').trim();
    if (mutationId.isEmpty) {
      mutationId = _readString(body['mutation_id'] ?? body['mutationId']).trim();
    }
    if (!SecurityConstants.idempotencyKeyPattern.hasMatch(mutationId)) {
      throw ApiException.unprocessable(
        'Header Idempotency-Key wajib berupa 48 karakter hex huruf kecil.',
        code: 'INVALID_INPUT',
      );
    }

    final hasUrlKey =
        body.containsKey('avatar_url') || body.containsKey('avatarUrl');
    if (!hasUrlKey) {
      throw ApiException.unprocessable(
        'Field avatar_url wajib ada (isi null untuk menghapus foto profil).',
        code: 'INVALID_INPUT',
        fieldErrors: const {'avatar_url': 'Field avatar_url wajib ada.'},
      );
    }

    final rawUrlObj = body.containsKey('avatar_url')
        ? body['avatar_url']
        : body['avatarUrl'];
    String? cleanUrl;
    if (rawUrlObj != null) {
      if (rawUrlObj is! String) {
        throw ApiException.unprocessable(
          'Field avatar_url harus berupa teks URL atau null.',
          code: 'INVALID_IMAGE_URL',
        );
      }
      final trimmed = rawUrlObj.trim();
      if (trimmed.isNotEmpty) {
        if (!_isOwnedAvatarUrl(trimmed, publicBaseUrl, actorId)) {
          throw ApiException.unprocessable(
            'URL foto profil tidak valid atau bukan foto profil milik akun ini.',
            code: 'INVALID_IMAGE_URL',
            fieldErrors: const {
              'avatar_url': 'URL foto profil tidak valid.',
            },
          );
        }
        cleanUrl = trimmed;
      }
    }

    final rawVersion = body['expected_version'] ?? body['expectedVersion'];
    int? expectedVersion;
    if (rawVersion != null) {
      if (rawVersion is int && rawVersion >= 1) {
        expectedVersion = rawVersion;
      } else {
        throw ApiException.unprocessable(
          'Field expected_version harus berupa bilangan bulat >= 1.',
          code: 'INVALID_INPUT',
        );
      }
    }

    return ValidatedAvatarUpdateInput(
      mutationId: mutationId,
      avatarUrl: cleanUrl,
      expectedVersion: expectedVersion,
    );
  }

  static String generateSecureMutationId48() =>
      MediaPaths.generateMutationId48();

  static bool _isOwnedAvatarUrl(String url, String publicBaseUrl, String actorId) {
    if (url.isEmpty || url.length > 512) return false;
    if (SecurityConstants.unsafeUrlChars.hasMatch(url)) return false;

    final lower = url.toLowerCase();
    if (lower.contains('..') ||
        lower.contains('%2e') ||
        lower.contains('%5c') ||
        lower.contains('%2f')) {
      return false;
    }

    return MediaPaths.isOwnedAvatarUrl(
      url,
      publicBaseUrl: publicBaseUrl,
      actorId: actorId,
    );
  }

  static String _readString(Object? value) {
    if (value is String) return value;
    return '';
  }
}