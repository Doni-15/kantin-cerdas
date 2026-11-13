import 'dart:io';
import 'dart:typed_data';

import 'package:supabase/supabase.dart';

import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/security/media_paths.dart';
import 'package:kantin_cerdas_backend/src/core/supabase/supabase_service.dart';
import 'package:kantin_cerdas_backend/src/core/utils/json_types.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/auth_validator.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/authenticated_actor.dart';
import 'package:kantin_cerdas_backend/src/modules/media/media_service.dart';
import 'package:kantin_cerdas_backend/src/modules/media/media_validated_input.dart';

/// Layanan bisnis domain Autentikasi & Sesi (`/v1/auth/*`).
///
/// Seluruh penyimpanan objek media ke Supabase Storage dan pencatatan
/// `rpc_register_media_asset` didelegasikan ke [MediaService] (SRP & DRY).
final class AuthService {
  final SupabaseService _supabase;
  final MediaService mediaService;

  const AuthService(this._supabase, {required this.mediaService});

  static const String _userColumns =
      'id, auth_uid, username, email, name, role, is_active, session_epoch, version, avatar_url';

  /// 0. POST `/v1/auth/availability` — Cek ketersediaan email / username (Langkah 1 Registrasi).
  Future<JsonMap> checkAvailability({String? email, String? username}) async {
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

    final createdAuth = await _createOrReclaimOrphanAuthUser(input);
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
      // Rollback kredensial Auth agar tidak tersisa akun tanpa profil.
      // Kegagalan rollback dicatat (bukan disenyapkan); akun yatim yang tersisa
      // dibersihkan oleh _createOrReclaimOrphanAuthUser pada registrasi berikutnya.
      try {
        await _supabase.adminClient.auth.admin.deleteUser(authUid);
      } catch (rollbackError) {
        stderr.writeln(
          '[WARN] Rollback registrasi gagal menghapus akun Auth $authUid: $rollbackError',
        );
      }
      rethrow;
    }

    // Foto profil opsional (Langkah 2). Didelegasikan ke MediaService.
    final avatarBytes = input.avatarBytes;
    final avatarMime = input.avatarMimeType;
    final avatarExt = input.avatarExtension;
    final userId = userJson['id']?.toString() ?? '';

    bool? avatarSaved;
    if (avatarBytes != null &&
        avatarMime != null &&
        avatarExt != null &&
        userId.isNotEmpty) {
      final actor = AuthenticatedActor(
        id: userId,
        authUid: authUid,
        username: input.username,
        email: input.email,
        name: input.name,
        role: 'customer',
        isActive: true,
        sessionEpoch: 1,
        version: 1,
        avatarUrl: null,
      );

      final updated = await _saveInitialAvatar(
        actor: actor,
        bytes: avatarBytes,
        mimeType: avatarMime,
        extension: avatarExt,
      );
      avatarSaved = updated != null;
      if (updated != null) userJson = updated;
    }

    return <String, Object?>{
      ...userJson,
      if (avatarSaved != null) 'avatar_saved': avatarSaved,
    };
  }

  /// Umur minimum akun Auth tanpa profil sebelum boleh dianggap sisa registrasi
  /// yang gagal. Mencegah penghapusan akun yang registrasinya sedang berjalan
  /// (jeda antara `createUser` dan `rpc_register_user_profile`).
  static const Duration _orphanMinAge = Duration(minutes: 10);
  static const int _orphanScanPageSize = 200;
  static const int _orphanScanMaxPages = 25;

  /// Membuat akun di Supabase Auth. Apabila `public.users` sudah terbukti tidak
  /// memiliki email tersebut tetapi `auth.users` masih menyimpan akun yatim,
  /// akun yatim dibersihkan lalu dibuat ulang HANYA bila terbukti sisa
  /// registrasi backend yang gagal (lihat [_isReclaimableOrphan]). Akun lain
  /// (mis. admin/owner yang dibuat manual lewat Dashboard sebelum bootstrap
  /// profil) tidak pernah dihapus oleh endpoint publik ini.
  Future<UserResponse> _createOrReclaimOrphanAuthUser(
    ValidatedRegisterInput input,
  ) async {
    final attributes = AdminUserAttributes(
      email: input.email,
      password: input.password,
      emailConfirm: true,
      userMetadata: {'username': input.username, 'name': input.name},
    );

    try {
      return await _supabase.adminClient.auth.admin.createUser(attributes);
    } on AuthException catch (e) {
      final code = (e.code ?? '').toLowerCase();
      final lower = e.message.toLowerCase();
      final isAlreadyExists =
          code == 'user_already_exists' ||
          code == 'email_exists' ||
          lower.contains('already registered') ||
          lower.contains('already been registered');
      if (!isAlreadyExists) rethrow;

      final checkAgain = await _supabase.adminClient
          .from('users')
          .select('id')
          .eq('email_key', input.email.toLowerCase())
          .maybeSingle();
      if (checkAgain != null) {
        throw ApiException.conflict(
          code: 'EMAIL_TAKEN',
          message: 'Email sudah digunakan.',
          fieldErrors: const {'email': 'Email sudah digunakan.'},
        );
      }

      final targetEmail = input.email.toLowerCase();
      User? existing;
      for (
        var page = 1;
        page <= _orphanScanMaxPages && existing == null;
        page++
      ) {
        final users = await _supabase.adminClient.auth.admin.listUsers(
          page: page,
          perPage: _orphanScanPageSize,
        );
        for (final u in users) {
          if ((u.email ?? '').toLowerCase() == targetEmail) {
            existing = u;
            break;
          }
        }
        if (users.length < _orphanScanPageSize) break;
      }

      if (existing == null || !_isReclaimableOrphan(existing)) {
        throw ApiException.conflict(
          code: 'EMAIL_TAKEN',
          message: 'Email sudah digunakan.',
          fieldErrors: const {'email': 'Email sudah digunakan.'},
        );
      }

      stderr.writeln(
        '[WARN] Membersihkan akun Auth yatim ${existing.id} (tanpa profil, '
        'tanpa login, dibuat ${existing.createdAt}) pada registrasi ulang.',
      );
      await _supabase.adminClient.auth.admin.deleteUser(existing.id);

      return await _supabase.adminClient.auth.admin.createUser(attributes);
    }
  }

  /// Akun Auth dianggap sisa registrasi gagal hanya bila SEMUA terpenuhi:
  /// dibuat oleh endpoint register (metadata `username` ada), belum pernah
  /// login, dan sudah lebih tua dari [_orphanMinAge].
  bool _isReclaimableOrphan(User user) {
    final metadata = user.userMetadata;
    if (metadata == null || metadata['username'] is! String) return false;
    if (user.lastSignInAt != null) return false;

    final created = DateTime.tryParse(user.createdAt);
    if (created == null) return false;
    return DateTime.now().toUtc().difference(created.toUtc()) >= _orphanMinAge;
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
  ///
  /// Setelah password diganti, seluruh sesi LAIN milik pengguna dicabut
  /// ([accessToken] = sesi saat ini, yang dipertahankan). Tanpa ini, refresh
  /// token yang sudah dicuri tetap berlaku walau korban mengganti password.
  Future<void> changePassword(
    AuthenticatedActor actor,
    ValidatedChangePasswordInput input, {
    String? accessToken,
  }) async {
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

    final currentToken = accessToken?.trim() ?? '';
    if (currentToken.isNotEmpty) {
      try {
        await _supabase.adminClient.auth.admin.signOut(
          currentToken,
          scope: SignOutScope.others,
        );
      } catch (e) {
        // Password sudah berhasil diganti; kegagalan pencabutan sesi lain
        // dicatat agar operator dapat menindaklanjuti, bukan menggagalkan request.
        stderr.writeln(
          '[WARN] Password diubah tetapi sesi lain gagal dicabut (${actor.id}): $e',
        );
      }
    }
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

  /// Menyimpan foto profil awal saat registrasi dengan mendelegasikan unggahan
  /// dan pencatatan `media_assets` sepenuhnya ke [MediaService] (tanpa duplikasi).
  Future<JsonMap?> _saveInitialAvatar({
    required AuthenticatedActor actor,
    required Uint8List bytes,
    required String mimeType,
    required String extension,
  }) async {
    final mutationId = MediaPaths.generateMutationId48();
    final objectPath = MediaPaths.buildObjectPath(
      actorId: actor.id,
      category: 'profile_avatar',
      mutationId: mutationId,
      extension: extension,
    );

    try {
      final uploaded = await mediaService.uploadAndRegisterImage(
        actor: actor,
        input: ValidatedMediaUploadInput(
          mutationId: mutationId,
          category: 'profile_avatar',
          objectPath: objectPath,
          mimeType: mimeType,
          bytes: bytes,
        ),
      );

      final publicUrl = uploaded['image_url']?.toString();
      if (publicUrl == null || publicUrl.isEmpty) {
        return null;
      }

      return await updateProfileAvatar(
        actor,
        ValidatedAvatarUpdateInput(
          mutationId: MediaPaths.generateMutationId48(),
          avatarUrl: publicUrl,
          expectedVersion: 1,
        ),
      );
    } catch (e) {
      stderr.writeln(
        '[WARN] Gagal menyimpan foto profil awal saat registrasi (${actor.id}): $e',
      );
      return null;
    }
  }
}
