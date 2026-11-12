import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:characters/characters.dart';
import 'package:kantin_cerdas_backend/src/core/constants/security_constants.dart';
import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/config/app_config.dart';
import 'package:kantin_cerdas_backend/src/core/security/image_guard.dart';
import 'package:kantin_cerdas_backend/src/core/security/media_paths.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/auth_validated_input.dart';

export 'package:kantin_cerdas_backend/src/modules/auth/auth_validated_input.dart';

/// Validator input domain Auth yang selaras 100% dengan `SPESIFIKASI_BACKEND.md`,
/// `AuthValidator` di Flutter, dan `CHECK CONSTRAINT` di Migrasi 002 & 009.
final class AuthValidator {
  const AuthValidator._();

  static const int _minAvatarBytes = 32;
  static const int _maxAvatarBytes = 2 * 1024 * 1024; // 2 MB
  static const int _maxDimensionPx = 8192;

  static final RegExp _usernamePattern = RegExp(r'^[a-zA-Z0-9._]+$');
  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final RegExp _idempotencyKeyPattern = RegExp(r'^[a-f0-9]{48}$');
  static final RegExp _unsafeUrlChars = RegExp(r'[\x00-\x20\x7f<">\x27\\`@]');
  static final RegExp _safeStorageUrlPattern = RegExp(
    r'^https://[a-zA-Z0-9.-]+(:[0-9]{1,5})?/storage/v1/object/public/kantin-media/[a-z0-9_-]{1,64}_(profile_avatar|menu_photo|stall_photo)_[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\.(jpg|jpeg|png|webp)$',
  );

  static const List<String> _forbiddenScriptTokens = <String>[
    '<script',
    '</script',
    '<?php',
    '<?=',
    '<svg',
    '<!doctype',
    '<html',
    '<iframe',
    '<object',
    '<embed',
    'javascript:',
    'vbscript:',
    'data:text/html',
    'onerror=',
    'onload=',
  ];

  /// Memvalidasi body JSON `POST /v1/auth/availability`.
  static ({String? email, String? username}) validateAvailability(
    Map<String, Object?> body,
  ) {
    final rawEmail = _readString(body['email']).trim().toLowerCase();
    final rawUsername = _readString(body['username']).trim().toLowerCase();

    if (rawEmail.isEmpty && rawUsername.isEmpty) {
      throw ApiException.unprocessable(
        'Minimal salah satu dari email atau username wajib diisi.',
        code: 'INVALID_INPUT',
      );
    }

    if (rawEmail.isNotEmpty &&
        (rawEmail.length < 3 ||
            rawEmail.length > 254 ||
            !_emailPattern.hasMatch(rawEmail))) {
      throw ApiException.unprocessable(
        'Format alamat email tidak valid.',
        code: 'INVALID_INPUT',
        fieldErrors: const {'email': 'Format alamat email tidak valid.'},
      );
    }

    if (rawUsername.isNotEmpty &&
        (rawUsername.length < 3 ||
            rawUsername.length > 20 ||
            !_usernamePattern.hasMatch(rawUsername))) {
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
    // Password TIDAK di-trim agar spasi yang disengaja pengguna tidak hilang
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
    } else if (!_usernamePattern.hasMatch(rawUsername)) {
      fieldErrors['username'] =
          'Username hanya boleh menggunakan huruf, angka, titik (.), atau garis bawah (_).';
    }

    final emailGraphemes = rawEmail.characters.length;
    if (rawEmail.isEmpty) {
      fieldErrors['email'] = 'Alamat email wajib diisi.';
    } else if (rawEmail.length < 3 ||
        emailGraphemes > 254 ||
        rawEmail.length > 254 ||
        !_emailPattern.hasMatch(rawEmail)) {
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
        final validatedAvatar = _validateAvatarBinary(decoded);
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

  static ({Uint8List bytes, String mimeType, String extension})
  _validateAvatarBinary(Uint8List bytes) {
    if (bytes.length < _minAvatarBytes) {
      throw ApiException.unprocessable(
        'File foto profil kosong atau rusak.',
        code: 'INVALID_IMAGE',
      );
    }
    if (bytes.length > _maxAvatarBytes) {
      throw ApiException.unprocessable(
        'Ukuran foto profil melebihi batas maksimal 2 MB.',
        code: 'INVALID_IMAGE',
      );
    }

    String? mimeType;
    String? extension;

    if (bytes.length >= 12) {
      if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
        mimeType = 'image/jpeg';
        extension = 'jpg';
      } else if (bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47 &&
          bytes[4] == 0x0D &&
          bytes[5] == 0x0A &&
          bytes[6] == 0x1A &&
          bytes[7] == 0x0A) {
        mimeType = 'image/png';
        extension = 'png';
      } else if (bytes[0] == 0x52 &&
          bytes[1] == 0x49 &&
          bytes[2] == 0x46 &&
          bytes[3] == 0x46 &&
          bytes[8] == 0x57 &&
          bytes[9] == 0x45 &&
          bytes[10] == 0x42 &&
          bytes[11] == 0x50) {
        mimeType = 'image/webp';
        extension = 'webp';
      }
    }

    if (mimeType == null || extension == null) {
      throw ApiException.unprocessable(
        'Format foto profil wajib berupa JPEG, PNG, atau WebP.',
        code: 'INVALID_IMAGE',
      );
    }

    if (!_verifyImageStructure(bytes, extension)) {
      throw ApiException.unprocessable(
        'Struktur biner foto profil rusak atau tidak lengkap.',
        code: 'INVALID_IMAGE',
      );
    }

    if (_containsScriptPayload(bytes)) {
      throw ApiException.unprocessable(
        'Foto profil ditolak karena mengandung payload skrip berbahaya.',
        code: 'INVALID_IMAGE',
      );
    }

    return (bytes: bytes, mimeType: mimeType, extension: extension);
  }

  static bool _verifyImageStructure(Uint8List bytes, String extension) {
    switch (extension) {
      case 'jpg':
        if (bytes.length < 20) return false;
        var end = bytes.length - 1;
        while (end > 4 && bytes[end] == 0x00) {
          end--;
        }
        return bytes[end - 1] == 0xFF && bytes[end] == 0xD9;
      case 'png':
        if (bytes.length < 33) return false;
        final hasIhdr =
            bytes[12] == 0x49 &&
            bytes[13] == 0x48 &&
            bytes[14] == 0x44 &&
            bytes[15] == 0x52;
        if (!hasIhdr) return false;
        final width =
            (bytes[16] << 24) |
            (bytes[17] << 16) |
            (bytes[18] << 8) |
            bytes[19];
        final height =
            (bytes[20] << 24) |
            (bytes[21] << 16) |
            (bytes[22] << 8) |
            bytes[23];
        if (width < 1 ||
            width > _maxDimensionPx ||
            height < 1 ||
            height > _maxDimensionPx) {
          return false;
        }
        final tailStart = bytes.length - 12;
        return bytes[tailStart + 4] == 0x49 &&
            bytes[tailStart + 5] == 0x45 &&
            bytes[tailStart + 6] == 0x4E &&
            bytes[tailStart + 7] == 0x44;
      case 'webp':
        if (bytes.length < 20) return false;
        return bytes[12] == 0x56 &&
            bytes[13] == 0x50 &&
            bytes[14] == 0x38 &&
            (bytes[15] == 0x20 || bytes[15] == 0x4C || bytes[15] == 0x58);
      default:
        return false;
    }
  }

  static bool _containsScriptPayload(Uint8List bytes) {
    final asciiLower = StringBuffer();
    for (var i = 0; i < bytes.length; i++) {
      final byte = bytes[i];
      if (byte >= 0x41 && byte <= 0x5A) {
        asciiLower.writeCharCode(byte + 32);
      } else if (byte >= 0x20 && byte <= 0x7E) {
        asciiLower.writeCharCode(byte);
      } else if (byte == 0x09 || byte == 0x0A || byte == 0x0D) {
        asciiLower.writeCharCode(0x20);
      } else {
        asciiLower.writeCharCode(0x00);
      }
    }
    final content = asciiLower.toString();
    for (final token in _forbiddenScriptTokens) {
      if (content.contains(token)) return true;
    }
    return false;
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
            !_usernamePattern.hasMatch(rawIdentifier))) {
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
        !_emailPattern.hasMatch(rawEmail)) {
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
    var mutationId = (idempotencyKeyHeader ??
            _readString(body['mutation_id'] ?? body['mutationId']))
        .trim();

    if (mutationId.isEmpty) {
      mutationId = generateSecureMutationId48();
    } else if (!_idempotencyKeyPattern.hasMatch(mutationId)) {
      throw ApiException.unprocessable(
        'Header Idempotency-Key wajib berupa 48 karakter hex huruf kecil.',
        code: 'INVALID_INPUT',
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

  static String generateSecureMutationId48() {
    final random = Random.secure();
    return List<String>.generate(
      24,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  static bool _isSafeImageUrl(String url) {
    if (url.isEmpty || url.length > 512) return false;
    if (SecurityConstants.unsafeUrlChars.hasMatch(url)) return false;

    final lower = url.toLowerCase();
    if (lower.contains('..') ||
        lower.contains('%2e%2e') ||
        lower.contains('%5c')) {
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