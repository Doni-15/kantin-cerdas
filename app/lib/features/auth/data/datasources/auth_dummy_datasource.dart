import 'package:kantin_cerdas/features/auth/data/datasources/auth_datasource.dart';
import 'package:kantin_cerdas/core/errors/api_exception.dart';
import 'package:kantin_cerdas/core/storage/local_storage.dart';
import 'package:kantin_cerdas/features/auth/data/models/login_response_model.dart';
import 'package:kantin_cerdas/features/auth/data/models/user_model.dart';
import 'package:kantin_cerdas/features/auth/domain/validators/auth_validator.dart';

/// Meniru Backend Auth.
///
/// - Bicara dalam bentuk JSON (snake_case) lalu di-parse dengan `fromJson`,
///   sehingga jalur parsing Model ikut teruji sebelum Backend ada.
/// - Melempar `ApiException` dengan status code seperti Backend.
/// - Menyimpan kredensial per akun, session, dan masa berlaku token.
///
/// Akun seed (password semuanya `123456`): admin, owner, customer, inactive.
///
/// Skenario error (isi kolom identifier saat login / username saat register):
///   `offline`  -> tidak ada koneksi
///   `timeout`  -> request timeout
///   `error500` -> server error
class AuthDummyDataSource implements AuthDataSource {
  AuthDummyDataSource({
    this.latency = const Duration(seconds: 1),
    this.storage,
  }) {
    _restore();
  }

  /// Jeda jaringan buatan. Gunakan `Duration.zero` di unit test.
  final Duration latency;

  /// Jika diisi, akun hasil register, session, dan penghitung id disimpan di
  /// sini sehingga bertahan setelah aplikasi ditutup (meniru database Backend).
  final LocalStorage? storage;

  /// Dummy: dibuat panjang agar session bertahan selama pengembangan.
  /// Backend nyata memakai access token pendek + refresh token.
  static const _accessTokenLifetime = Duration(days: 7);

  final List<_DummyAccount> _accounts = [
    _DummyAccount(
      password: '123456',
      json: {
        'id': 1,
        'username': 'admin',
        'email': 'admin@kantincerdas.com',
        'name': 'Doni (Admin)',
        'role': 'admin',
        'is_active': true,
      },
    ),
    _DummyAccount(
      password: '123456',
      json: {
        'id': 2,
        'username': 'owner',
        'email': 'pemilik@kantincerdas.com',
        'name': 'Budi (Pemilik Kantin)',
        'role': 'owner',
        'is_active': true,
      },
    ),
    _DummyAccount(
      password: '123456',
      json: {
        'id': 3,
        'username': 'customer',
        'email': 'customer@kantincerdas.com',
        'name': 'Andi (Customer)',
        'role': 'customer',
        'is_active': true,
      },
    ),
    _DummyAccount(
      password: '123456',
      json: {
        'id': 4,
        'username': 'inactive',
        'email': 'inactive@kantincerdas.com',
        'name': 'Akun Nonaktif',
        'role': 'customer',
        'is_active': false,
      },
    ),
  ];

  final Map<String, _DummySession> _sessions = {};

  /// Akun seed memakai id 1..4; akun hasil register mulai dari sini.
  static const _firstRegisteredId = 5;

  int _nextId = _firstRegisteredId;
  int _tokenSequence = 0;

  void _restore() {
    final state = storage?.readJson(StorageKeys.authDummyState);

    if (state == null) {
      return;
    }

    try {
      final accounts = <_DummyAccount>[];
      for (final item in state['accounts'] as List<dynamic>) {
        final map = item as Map<String, dynamic>;

        accounts.add(
          _DummyAccount(
            password: map['password'] as String,
            json: Map<String, dynamic>.from(map['json'] as Map),
          ),
        );
      }

      final sessions = <String, _DummySession>{};
      for (final item in state['sessions'] as List<dynamic>) {
        final map = item as Map<String, dynamic>;

        final session = _DummySession(
          userId: map['user_id'] as int,
          accessToken: map['access_token'] as String,
          refreshToken: map['refresh_token'] as String,
          expiresAt: DateTime.parse(map['expires_at'] as String),
        );

        sessions[session.accessToken] = session;
      }

      // Password akun seed yang pernah diubah (akun seed sendiri tidak disimpan).
      final seedPasswords = <int, String>{};
      final rawSeedPasswords = state['seed_passwords'];

      if (rawSeedPasswords is Map) {
        for (final entry in rawSeedPasswords.entries) {
          seedPasswords[int.parse(entry.key as String)] = entry.value as String;
        }
      }

      final nextId = state['next_id'] as int;
      final tokenSequence = state['token_sequence'] as int;

      _accounts.addAll(accounts);
      seedPasswords.forEach(_setPassword);
      _sessions.addAll(sessions);
      _nextId = nextId;
      _tokenSequence = tokenSequence;
    } on Object {
      // Data tersimpan rusak: mulai dari kondisi awal.
    }
  }

  Future<void> _persist() async {
    await storage?.writeJson(StorageKeys.authDummyState, {
      'next_id': _nextId,
      'token_sequence': _tokenSequence,
      // Akun seed tidak disimpan utuh, hanya password-nya (bisa diubah user).
      'seed_passwords': {
        for (final account in _accounts)
          if (account.id < _firstRegisteredId)
            '${account.id}': account.password,
      },
      'accounts': [
        for (final account in _accounts)
          if (account.id >= _firstRegisteredId)
            {'password': account.password, 'json': account.json},
      ],
      'sessions': [
        for (final session in _sessions.values)
          {
            'user_id': session.userId,
            'access_token': session.accessToken,
            'refresh_token': session.refreshToken,
            'expires_at': session.expiresAt.toIso8601String(),
          },
      ],
    });
  }

  @override
  Future<LoginResponseModel> login({
    required String identifier,
    required String password,
  }) async {
    await Future<void>.delayed(latency);
    _throwIfSimulated(identifier);

    final key = identifier.trim().toLowerCase();

    final account = _accounts
        .where(
          (account) =>
              account.username.toLowerCase() == key ||
              account.email.toLowerCase() == key,
        )
        .firstOrNull;

    // Backend tidak membedakan "user tidak ada" dan "password salah".
    if (account == null || account.password != password) {
      throw const ApiException(
        statusCode: 401,
        code: ApiErrorCode.invalidCredentials,
      );
    }

    // Status akun baru dibuka setelah kredensial benar.
    if (!account.isActive) {
      throw const ApiException(
        statusCode: 403,
        code: ApiErrorCode.accountDisabled,
      );
    }

    final session = _createSession(account);
    await _persist();

    // Bentuk response persis seperti JSON Backend.
    final json = <String, dynamic>{
      'access_token': session.accessToken,
      'refresh_token': session.refreshToken,
      'expires_in': _accessTokenLifetime.inSeconds,
      'user': Map<String, dynamic>.from(account.json),
    };

    return LoginResponseModel.fromJson(json);
  }

  @override
  Future<UserModel> register({
    required String name,
    required String username,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(latency);
    _throwIfSimulated(username);

    final normalizedName = name.trim();
    final normalizedUsername = username.trim().toLowerCase();
    final normalizedEmail = email.trim().toLowerCase();

    // Validasi sisi server (422). Aturan sama dengan yang dipakai UI/UseCase.
    final fieldErrors = <String, String>{};

    final nameError = AuthValidator.name(normalizedName);
    if (nameError != null) fieldErrors['name'] = nameError;

    final usernameError = AuthValidator.username(normalizedUsername);
    if (usernameError != null) fieldErrors['username'] = usernameError;

    final emailError = AuthValidator.email(normalizedEmail);
    if (emailError != null) fieldErrors['email'] = emailError;

    final passwordError = AuthValidator.password(password);
    if (passwordError != null) fieldErrors['password'] = passwordError;

    if (fieldErrors.isNotEmpty) {
      throw ApiException(
        statusCode: 422,
        code: ApiErrorCode.validationError,
        fieldErrors: fieldErrors,
      );
    }

    if (_accounts.any(
      (account) => account.username.toLowerCase() == normalizedUsername,
    )) {
      throw const ApiException(
        statusCode: 409,
        code: ApiErrorCode.usernameTaken,
      );
    }

    if (_accounts.any(
      (account) => account.email.toLowerCase() == normalizedEmail,
    )) {
      throw const ApiException(statusCode: 409, code: ApiErrorCode.emailTaken);
    }

    final json = <String, dynamic>{
      'id': _nextId++,
      'username': normalizedUsername,
      'email': normalizedEmail,
      'name': normalizedName,
      'role': 'customer',
      'is_active': true,
    };

    // Password ikut disimpan agar akun baru bisa login dengan password-nya sendiri.
    _accounts.add(_DummyAccount(password: password, json: json));
    await _persist();

    return UserModel.fromJson(Map<String, dynamic>.from(json));
  }

  @override
  Future<UserModel> getCurrentUser({required String accessToken}) async {
    await Future<void>.delayed(latency);

    final session = _sessions[accessToken];

    if (session == null) {
      throw const ApiException(
        statusCode: 401,
        code: ApiErrorCode.tokenInvalid,
      );
    }

    if (DateTime.now().isAfter(session.expiresAt)) {
      _sessions.remove(accessToken);

      throw const ApiException(
        statusCode: 401,
        code: ApiErrorCode.tokenExpired,
      );
    }

    final account = _accounts
        .where((account) => account.id == session.userId)
        .firstOrNull;

    if (account == null) {
      throw const ApiException(
        statusCode: 401,
        code: ApiErrorCode.tokenInvalid,
      );
    }

    if (!account.isActive) {
      throw const ApiException(
        statusCode: 403,
        code: ApiErrorCode.accountDisabled,
      );
    }

    return UserModel.fromJson(Map<String, dynamic>.from(account.json));
  }

  @override
  Future<void> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) async {
    await Future<void>.delayed(latency);

    final session = _sessions[accessToken];

    if (session == null) {
      throw const ApiException(
        statusCode: 401,
        code: ApiErrorCode.tokenInvalid,
      );
    }

    if (DateTime.now().isAfter(session.expiresAt)) {
      _sessions.remove(accessToken);

      throw const ApiException(
        statusCode: 401,
        code: ApiErrorCode.tokenExpired,
      );
    }

    final account = _accounts
        .where((account) => account.id == session.userId)
        .firstOrNull;

    if (account == null) {
      throw const ApiException(
        statusCode: 401,
        code: ApiErrorCode.tokenInvalid,
      );
    }

    if (!account.isActive) {
      throw const ApiException(
        statusCode: 403,
        code: ApiErrorCode.accountDisabled,
      );
    }

    // Validasi sisi server (422). Aturan sama dengan yang dipakai UI/UseCase.
    final fieldErrors = <String, String>{};

    final currentError = AuthValidator.currentPassword(currentPassword);
    if (currentError != null) fieldErrors['current_password'] = currentError;

    final newError = AuthValidator.newPassword(currentPassword, newPassword);
    if (newError != null) fieldErrors['new_password'] = newError;

    if (fieldErrors.isNotEmpty) {
      throw ApiException(
        statusCode: 422,
        code: ApiErrorCode.validationError,
        fieldErrors: fieldErrors,
      );
    }

    if (account.password != currentPassword) {
      throw const ApiException(
        statusCode: 400,
        code: ApiErrorCode.wrongPassword,
      );
    }

    _setPassword(account.id, newPassword);
    await _persist();
  }

  /// Mengganti password akun (objek akun immutable, jadi diganti utuh).
  void _setPassword(int id, String password) {
    final index = _accounts.indexWhere((account) => account.id == id);

    if (index == -1) {
      return;
    }

    _accounts[index] = _DummyAccount(
      password: password,
      json: _accounts[index].json,
    );
  }

  @override
  Future<void> logout({required String refreshToken}) async {
    await Future<void>.delayed(latency);

    _sessions.removeWhere((_, session) => session.refreshToken == refreshToken);
    await _persist();
  }

  _DummySession _createSession(_DummyAccount account) {
    final sequence = _tokenSequence++;

    final session = _DummySession(
      userId: account.id,
      accessToken: 'dummy-access-${account.username}-$sequence',
      refreshToken: 'dummy-refresh-${account.username}-$sequence',
      expiresAt: DateTime.now().add(_accessTokenLifetime),
    );

    _sessions[session.accessToken] = session;

    return session;
  }

  void _throwIfSimulated(String key) {
    switch (key.trim().toLowerCase()) {
      case 'offline':
        throw const ApiException(statusCode: 0, code: ApiErrorCode.network);
      case 'timeout':
        throw const ApiException(statusCode: 0, code: ApiErrorCode.timeout);
      case 'error500':
        throw const ApiException(
          statusCode: 500,
          code: ApiErrorCode.serverError,
        );
    }
  }
}

class _DummyAccount {
  const _DummyAccount({required this.password, required this.json});

  final String password;
  final Map<String, dynamic> json;

  int get id => json['id'] as int;
  String get username => json['username'] as String;
  String get email => json['email'] as String;
  bool get isActive => json['is_active'] as bool;
}

class _DummySession {
  const _DummySession({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final int userId;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
}
