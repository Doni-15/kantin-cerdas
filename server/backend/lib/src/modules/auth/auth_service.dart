import 'dart:io';
import 'package:supabase/supabase.dart';

import 'package:kantin_cerdas_backend/src/core/errors/api_exception.dart';
import 'package:kantin_cerdas_backend/src/core/supabase/supabase_service.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/auth_validated_input.dart';
import 'package:kantin_cerdas_backend/src/modules/auth/authenticated_actor.dart';

/// Layanan bisnis domain Autentikasi & Sesi (`/v1/auth/*`).
final class AuthService {
  final SupabaseService _supabase;
  const AuthService(this._supabase);

  static const String _userColumns =
    'id, auth_uid, username, email, name, role, is_active, session_epoch, version, avatar_url'
  ;

  /// 1. POST `/v1/auth/register` — Registrasi akun atomik + Auto-Rollback.
  Future<Map<String, Object?>> register(ValidatedRegisterInput input) async {
    final usernameKey = input.username.toLowerCase();
    final emailKey = input.email.toLowerCase();

    // A. Pemeriksaan awal ke public.users agar tidak membuat akun yatim di GoTrue
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

    // B. Buat akun di Supabase Auth dengan emailConfirm: true (pengamanan ganda)
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

    // C. Simpan profil ke public.users lewat RPC transaksional.
    //    Jika gagal karena kondisi balapan (race condition), hapus kembali akun GoTrue!
    final Map<String, Object?> userJson;
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
      userJson = Map<String, Object?>.from(rpcResult as Map);
    } catch (e) {
      try {
        await _supabase.adminClient.auth.admin.deleteUser(authUid);
      } 
      catch (_) {
        // Abaikan error kompensasi sekunder agar exception asli tetap dikembalikan.
      }
      rethrow;
    }

    // D. Login otomatis menggunakan stateless client untuk menerbitkan token sesi
    final session = await _signInWithEmailPassword(
      email: input.email,
      password: input.password,
    );

    return _buildLoginResponse(session: session, userJson: userJson);
  }

  /// 2. POST `/v1/auth/login` — Login menggunakan Username ATAU Email.
  Future<Map<String, Object?>> login(ValidatedLoginInput input) async {
    // A. Cari profil di public.users berdasarkan email_key atau username_key
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

    // B. Verifikasi password ke Supabase Auth terlebih dahulu
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

    // C. Setelah password terbukti benar, periksa apakah akun sedang dinonaktifkan admin
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
  /// Dipakai oleh `GET /v1/auth/me` serta Middleware Auth di seluruh endpoint.
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

  /// 4. POST `/v1/auth/refresh` — Tukar refresh_token dengan sesi baru & cek status aktif.
  Future<Map<String, Object?>> refreshSession(String refreshToken) async {
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

      return _buildLoginResponse(session: session, userJson: actor.toUserJson());
    } finally {
      await tempClient.dispose();
    }
  }

  /// 5. POST `/v1/auth/logout` — Cabut sesi aktif saat ini.
  Future<void> logout(String? accessToken) async {
    if (accessToken == null || accessToken.trim().isEmpty) return;
    await _safeSignOutToken(accessToken.trim());
  }

  /// 6. POST `/v1/auth/change-password` — Verifikasi password lama lalu ganti password baru.
  Future<void> changePassword(
    AuthenticatedActor actor,
    ValidatedChangePasswordInput input,
  ) async {
    // A. Verifikasi current_password tanpa mengganggu sesi aktif
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

    // B. Perbarui password di Supabase Auth
    await _supabase.adminClient.auth.admin.updateUserById(
      actor.authUid,
      attributes: AdminUserAttributes(password: input.newPassword),
    );
  }

  /// 7. POST `/v1/auth/password-reset` — Kirim email reset secara netral (anti-enumerasi).
  Future<void> requestPasswordReset(String email) async {
    final tempClient = _supabase.createStatelessAuthClient();
    try {
      await tempClient.auth.resetPasswordForEmail(email);
    } catch (e) {
      // Sesuai SPESIFIKASI_BACKEND.md Bab 5: selalu kembalikan respons netral
      // baik email terdaftar maupun tidak agar tidak membocorkan eksistensi akun.
      // Kegagalan tetap dicatat di log server (tanpa alamat email).
      stderr.writeln('[WARN] Gagal mengirim email reset password: $e');
    } finally {
      await tempClient.dispose();
    }
  }

  /// 8. PUT `/v1/auth/profile/avatar` — Perbarui avatar_url secara idempoten lewat RPC.
  Future<Map<String, Object?>> updateProfileAvatar(
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

    return Map<String, Object?>.from(result as Map);
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

  /// Mencabut sesi milik [accessToken] lewat Admin API GoTrue.
  /// (`client.auth.signOut` pada klien tanpa `currentSession` tidak menghubungi
  /// server, sehingga sesi tidak benar-benar dicabut.)
  Future<void> _safeSignOutToken(String accessToken) async {
    try {
      await _supabase.adminClient.auth.admin.signOut(
        accessToken,
        scope: SignOutScope.local,
      );
    } catch (_) {
      // Abaikan bila token memang sudah kedaluwarsa atau dicabut.
    }
  }

  /// True jika GoTrue benar-benar menolak kredensial/token (status 4xx tertentu).
  /// Galat jaringan (status null), 429, dan 5xx BUKAN penolakan, supaya gangguan
  /// Supabase tidak diterjemahkan menjadi "password salah" atau memaksa logout.
  bool _isRejection(AuthException e) {
    final status = int.tryParse(e.statusCode ?? '');
    return status == 400 ||
        status == 401 ||
        status == 403 ||
        status == 404 ||
        status == 422;
  }

  /// Menerjemahkan galat Supabase Auth non-penolakan: 429 -> 429, lainnya -> 503.
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

  Map<String, Object?> _buildLoginResponse({
    required Session session,
    required Map<String, Object?> userJson,
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
}