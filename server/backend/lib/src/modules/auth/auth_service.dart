import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:supabase/supabase.dart';

import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/supabase/supabase_service.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/auth_validator.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/authenticated_actor.dart';

typedef JsonMap = Map<String, Object?>;

/// Layanan bisnis domain Autentikasi & Sesi (`/v1/auth/*`).
final class AuthService {
  final SupabaseService _supabase;
  const AuthService(this._supabase);

  static const String _userColumns =
      'id, auth_uid, username, email, name, role, is_active, session_epoch, version, avatar_url';

  static final RegExp _nonSafeActorChars = RegExp(r'[^a-z0-9_-]');

  /// 0. POST `/v1/auth/availability` — Cek ketersediaan email / username (Langkah 1 Registrasi).
  Future<JsonMap> checkAvailability({
    String? email,
    String? username,
  }) async {
    var emailAvailable = true;
    var usernameAvailable = true;

    if (email != null && email.isNotEmpty) {
      final existing = await _supabase.adminClient
          .from('users')
          .select('id')
          .eq('email_key', email.toLowerCase())
          .maybeSingle();
      emailAvailable = existing == null;
    }

    if (username != null && username.isNotEmpty) {
      final existing = await _supabase.adminClient
          .from('users')
          .select('id')
          .eq('username_key', username.toLowerCase())
          .maybeSingle();
      usernameAvailable = existing == null;
    }

    return <String, Object?>{
      if (email != null) 'email_available': emailAvailable,
      if (username != null) 'username_available': usernameAvailable,
    };
  }

  /// 1. POST `/v1/auth/register` — Registrasi akun atomik + Auto-Rollback + Upload Avatar Opsional.
  Future<JsonMap> register(ValidatedRegisterInput input) async {
    final usernameKey = input.username.toLowerCase();
    final emailKey = input.email.toLowerCase();

    final existingByUsername = await _supabase.adminClient
        .from('users')
        .select('id')
        .eq('username_key', usernameKey)
        .maybeSingle();
    if (existingByUsername != null) {
      throw ApiException.conflict(
        code: 'USERNAME_TAKEN',
        message: 'Username sudah digunakan.',
        fieldErrors: const {'username': 'Username sudah digunakan.'},
      );
    }

    final existingByEmail = await _supabase.adminClient
        .from('users')
        .select('id')
        .eq('email_key', emailKey)
        .maybeSingle();
    if (existingByEmail != null) {
      throw ApiException.conflict(
        code: 'EMAIL_TAKEN',
        message: 'Email sudah digunakan.',
        fieldErrors: const {'email': 'Email sudah digunakan.'},
      );
    }

    final UserResponse createdAuth = await _supabase.adminClient.auth.admin
        .createUser(
          AdminUserAttributes(
            email: input.email,
            password: input.password,
            emailConfirm: true,
            userMetadata: {'username': input.username, 'name': input.name},
          ),
        );

    final authUid = createdAuth.user?.id;
    if (authUid == null || authUid.isEmpty) {
      throw const ApiException(
        statusCode: 500,
        code: 'AUTH_CREATION_FAILED',
        message: 'Gagal membuat kredensial pengguna baru.',
      );
    }

    JsonMap userJson;
    try {
      final rpcResult = await _supabase.adminClient.rpc<dynamic>(
        'rpc_register_user_profile',
        params: {
          'p_auth_uid': authUid,
          'p_username': input.username,
          'p_email': input.email,
          'p_name': input.name,
        },
      );
      userJson = JsonMap.from(rpcResult as Map);
    } catch (e) {
      try {
        await _supabase.adminClient.auth.admin.deleteUser(authUid);
      } catch (_) {}
      rethrow;
    }

    // Jika pengguna memilih foto profil pada Langkah 2 registrasi,
    // unggah ke bucket 'kantin-media', daftarkan ke media_assets, dan perbarui avatar_url.
    final avatarBytes = input.avatarBytes;
    final avatarMime = input.avatarMimeType;
    final avatarExt = input.avatarExtension;
    final userId = userJson['id']?.toString() ?? '';

    if (avatarBytes != null &&
        avatarMime != null &&
        avatarExt != null &&
        userId.isNotEmpty) {
      try {
        final sanitizedActor = _sanitizeActorId(userId);
        final objectPath =
            '${sanitizedActor}_profile_avatar_${_generateUuidV4()}.$avatarExt';
        final sha256Hex = sha256.convert(avatarBytes).toString();

        await _supabase.adminClient.storage.from('kantin-media').uploadBinary(
              objectPath,
              avatarBytes,
              fileOptions: FileOptions(
                contentType: avatarMime,
                upsert: false,
              ),
            );

        final publicUrl = _supabase.adminClient.storage
            .from('kantin-media')
            .getPublicUrl(objectPath);

        await _supabase.adminClient.rpc<dynamic>(
          'rpc_register_media_asset',
          params: {
            'p_actor_id': userId,
            'p_mutation_id': AuthValidator.generateSecureMutationId48(),
            'p_category': 'profile_avatar',
            'p_object_path': objectPath,
            'p_public_url': publicUrl,
            'p_mime_type': avatarMime,
            'p_size_bytes': avatarBytes.length,
            'p_sha256_hex': sha256Hex,
          },
        );

        final updatedUser = await _supabase.adminClient.rpc<dynamic>(
          'rpc_update_profile_avatar',
          params: {
            'p_actor_id': userId,
            'p_mutation_id': AuthValidator.generateSecureMutationId48(),
            'p_avatar_url': publicUrl,
            'p_expected_version': 1,
          },
        );
        userJson = JsonMap.from(updatedUser as Map);
      } catch (e) {
        stderr.writeln(
          '[WARN] Gagal menyimpan foto profil awal saat registrasi ($userId): $e',
        );
      }
    }

    return userJson;
  }

  /// 2. POST `/v1/auth/login` — Login menggunakan Username ATAU Email.
  Future<JsonMap> login(ValidatedLoginInput input) async {
    final lookupColumn = input.isEmail ? 'email_key' : 'username_key';
    final lookupValue = input.identifier.toLowerCase();

    final row = await _supabase.adminClient
        .from('users')
        .select(_userColumns)
        .eq(lookupColumn, lookupValue)
        .maybeSingle();

    if (row == null) {
      throw const ApiException(
        statusCode: 401,
        code: 'INVALID_CREDENTIALS',
        message: 'Username/email atau password salah.',
      );
    }

    final actor = AuthenticatedActor.fromRow(row);

    final Session session;
    try {
      session = await _signInWithEmailPassword(
        email: actor.email,
        password: input.password,
      );
    } on AuthException catch (e) {
      if (!_isRejection(e)) throw _authInfraError(e);
      throw const ApiException(
        statusCode: 401,
        code: 'INVALID_CREDENTIALS',
        message: 'Username/email atau password salah.',
      );
    }

    if (!actor.isActive) {
      await _safeSignOutToken(session.accessToken);
      throw const ApiException(
        statusCode: 403,
        code: 'ACCOUNT_DISABLED',
        message: 'Akun pengguna sedang dinonaktifkan.',
      );
    }

    return _buildLoginResponse(session: session, userJson: actor.toUserJson());
  }

  /// 3. Verifikasi Bearer Token & ambil profil otoritatif dari `public.users`.
  Future<AuthenticatedActor> verifyAccessTokenAndGetUser(
    String accessToken,
  ) async {
    final cleanToken = accessToken.trim();
    if (cleanToken.isEmpty) {
      throw ApiException.unauthenticated(
        'Token akses wajib disertakan.',
        'UNAUTHENTICATED',
      );
    }

    final UserResponse userRes;
    try {
      userRes = await _supabase.adminClient.auth.getUser(cleanToken);
    } on AuthException catch (e) {
      if (!_isRejection(e)) throw _authInfraError(e);

      final lower = e.message.toLowerCase();
      if (lower.contains('expired')) {
        throw ApiException.unauthenticated(
          'Token akses telah kedaluwarsa.',
          'TOKEN_EXPIRED',
        );
      }
      throw ApiException.unauthenticated(
        'Token akses tidak valid.',
        'INVALID_TOKEN',
      );
    }

    final authUser = userRes.user;
    if (authUser == null) {
      throw ApiException.unauthenticated(
        'Sesi pengguna tidak ditemukan.',
        'INVALID_TOKEN',
      );
    }

    final row = await _supabase.adminClient
        .from('users')
        .select(_userColumns)
        .eq('auth_uid', authUser.id)
        .maybeSingle();

    if (row == null) {
      throw ApiException.unauthenticated(
        'Profil pengguna tidak ditemukan.',
        'UNAUTHENTICATED',
      );
    }

    final actor = AuthenticatedActor.fromRow(row);
    if (!actor.isActive) {
      throw const ApiException(
        statusCode: 403,
        code: 'ACCOUNT_DISABLED',
        message: 'Akun pengguna sedang dinonaktifkan.',
      );
    }

    return actor;
  }

  /// 4. POST `/v1/auth/refresh`
  Future<JsonMap> refreshSession(String refreshToken) async {
    final tempClient = _supabase.createStatelessAuthClient();
    try {
      final AuthResponse response;
      try {
        response = await tempClient.auth.refreshSession(refreshToken);
      } on AuthException catch (e) {
        if (!_isRejection(e)) throw _authInfraError(e);
        throw ApiException.unauthenticated(
          'Sesi telah berakhir. Silakan login kembali.',
          'INVALID_TOKEN',
        );
      }

      final session = response.session;
      final authUser = response.user ?? session?.user;
      if (session == null || authUser == null) {
        throw ApiException.unauthenticated(
          'Gagal memperbarui sesi.',
          'INVALID_TOKEN',
        );
      }

      final row = await _supabase.adminClient
          .from('users')
          .select(_userColumns)
          .eq('auth_uid', authUser.id)
          .maybeSingle();

      if (row == null) {
        throw ApiException.unauthenticated(
          'Profil pengguna tidak ditemukan.',
          'UNAUTHENTICATED',
        );
      }

      final actor = AuthenticatedActor.fromRow(row);
      if (!actor.isActive) {
        await _safeSignOutToken(session.accessToken);
        throw const ApiException(
          statusCode: 403,
          code: 'ACCOUNT_DISABLED',
          message: 'Akun pengguna sedang dinonaktifkan.',
        );
      }

      return _buildLoginResponse(
        session: session,
        userJson: actor.toUserJson(),
      );
    } finally {
      await tempClient.dispose();
    }
  }

  /// 5. POST `/v1/auth/logout`
  Future<void> logout(String? accessToken) async {
    if (accessToken == null || accessToken.trim().isEmpty) return;
    await _safeSignOutToken(accessToken.trim());
  }

  /// 6. POST `/v1/auth/change-password`
  Future<void> changePassword(
    AuthenticatedActor actor,
    ValidatedChangePasswordInput input,
  ) async {
    try {
      final session = await _signInWithEmailPassword(
        email: actor.email,
        password: input.currentPassword,
      );
      await _safeSignOutToken(session.accessToken);
    } on AuthException catch (e) {
      if (!_isRejection(e)) throw _authInfraError(e);
      throw const ApiException(
        statusCode: 401,
        code: 'INVALID_CURRENT_PASSWORD',
        message: 'Password saat ini salah.',
        fieldErrors: {'current_password': 'Password saat ini salah.'},
      );
    }

    await _supabase.adminClient.auth.admin.updateUserById(
      actor.authUid,
      attributes: AdminUserAttributes(password: input.newPassword),
    );
  }

  /// 7. POST `/v1/auth/password-reset`
  Future<void> requestPasswordReset(String email) async {
    final tempClient = _supabase.createStatelessAuthClient();
    try {
      await tempClient.auth.resetPasswordForEmail(email);
    } catch (e) {
      stderr.writeln('[WARN] Gagal mengirim email reset password: $e');
    } finally {
      await tempClient.dispose();
    }
  }

  /// 8. PUT `/v1/auth/profile/avatar`
  Future<JsonMap> updateProfileAvatar(
    AuthenticatedActor actor,
    ValidatedAvatarUpdateInput input,
  ) async {
    final result = await _supabase.adminClient.rpc<dynamic>(
      'rpc_update_profile_avatar',
      params: {
        'p_actor_id': actor.id,
        'p_mutation_id': input.mutationId,
        'p_avatar_url': input.avatarUrl,
        'p_expected_version': input.expectedVersion,
      },
    );

    return JsonMap.from(result as Map);
  }

  Future<Session> _signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final tempClient = _supabase.createStatelessAuthClient();
    try {
      final res = await tempClient.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final session = res.session;
      if (session == null) {
        throw const ApiException(
          statusCode: 401,
          code: 'INVALID_CREDENTIALS',
          message: 'Username/email atau password salah.',
        );
      }
      return session;
    } finally {
      await tempClient.dispose();
    }
  }

  Future<void> _safeSignOutToken(String accessToken) async {
    try {
      await _supabase.adminClient.auth.admin.signOut(
        accessToken,
        scope: SignOutScope.local,
      );
    } catch (_) {}
  }

  bool _isRejection(AuthException e) {
    final status = int.tryParse(e.statusCode ?? '');
    return status == 400 ||
        status == 401 ||
        status == 403 ||
        status == 404 ||
        status == 422;
  }

  ApiException _authInfraError(AuthException e) {
    if (e.statusCode == '429' || (e.code ?? '') == 'over_request_rate_limit') {
      return ApiException.rateLimited();
    }
    return const ApiException(
      statusCode: 503,
      code: 'AUTH_UNAVAILABLE',
      message: 'Layanan autentikasi sedang tidak tersedia. Silakan coba lagi.',
    );
  }

  JsonMap _buildLoginResponse({
    required Session session,
    required JsonMap userJson,
  }) {
    final expiresAtIso = session.expiresAt != null
        ? DateTime.fromMillisecondsSinceEpoch(
            session.expiresAt! * 1000,
            isUtc: true,
          ).toIso8601String()
        : null;

    return <String, Object?>{
      'access_token': session.accessToken,
      'refresh_token': session.refreshToken,
      if (expiresAtIso != null) 'expires_at': expiresAtIso,
      'user': userJson,
    };
  }

  static String _sanitizeActorId(String rawActorId) {
    final cleaned = rawActorId
        .trim()
        .toLowerCase()
        .replaceAll(_nonSafeActorChars, '')
        .replaceAll(RegExp(r'^[-_]+|[-_]+$'), '');
    if (cleaned.isEmpty) return 'user';
    return cleaned.length > 32 ? cleaned.substring(0, 32) : cleaned;
  }

  static String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40;
    bytes[8] = (bytes[8] & 0x3F) | 0x80;

    String hex(int start, int end) => bytes
        .sublist(start, end)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }
}