import 'dart:typed_data';

import 'package:kantin_cerdas/features/admin/data/admin_error_mapper.dart';
import 'package:kantin_cerdas/features/admin/domain/admin_models.dart';
import 'package:kantin_cerdas/features/admin/domain/admin_repository.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/auth/data/auth_repository.dart';

class AdminApiRepository implements AdminRepository {
  const AdminApiRepository(this._auth);

  final AuthRepository _auth;

  @override
  Future<AdminDashboardSummary> fetchDashboard(AuthSession session) async {
    final data = await _send(session, 'GET', ['admin', 'dashboard']);
    return _decode(() => AdminDashboardSummary.fromJson(_asMap(data)));
  }

  @override
  Future<List<AdminOwnerApplication>> listApplications(
    AuthSession session, {
    required String scope,
    int limit = 50,
    int offset = 0,
  }) async {
    final data = await _send(
      session,
      'GET',
      ['admin', 'applications'],
      query: {'scope': scope, 'limit': '$limit', 'offset': '$offset'},
    );
    return _decode(() {
      final items = _asMap(data)['items'] as List? ?? const [];
      return [
        for (final item in items) AdminOwnerApplication.fromJson(_asMap(item)),
      ];
    });
  }

  @override
  Future<AdminOwnerApplication> fetchApplication(
    AuthSession session, {
    required String applicationId,
  }) async {
    final data = await _send(session, 'GET', [
      'admin',
      'applications',
      applicationId,
    ]);
    return _decode(() => AdminOwnerApplication.fromJson(_asMap(data)));
  }

  @override
  Future<AdminOwnerApplication> reviewApplication(
    AuthSession session, {
    required String applicationId,
    required String decision,
    String? rejectionReason,
  }) async {
    final data = await _send(
      session,
      'POST',
      ['admin', 'applications', applicationId, 'review'],
      body: {'decision': decision, 'rejection_reason': ?rejectionReason},
    );
    return _decode(() => AdminOwnerApplication.fromJson(_asMap(data)));
  }

  @override
  Future<List<AdminManagedUser>> listUsers(
    AuthSession session, {
    String? role,
    String? status,
    String query = '',
    int limit = 50,
    int offset = 0,
  }) async {
    final trimmedQuery = query.trim();
    final data = await _send(
      session,
      'GET',
      ['admin', 'users'],
      query: {
        'role': ?role,
        'status': ?status,
        if (trimmedQuery.isNotEmpty) 'q': trimmedQuery,
        'limit': '$limit',
        'offset': '$offset',
      },
    );
    return _decode(() {
      final items = _asMap(data)['items'] as List? ?? const [];
      return [
        for (final item in items) AdminManagedUser.fromJson(_asMap(item)),
      ];
    });
  }

  @override
  Future<AdminManagedUser> fetchUser(
    AuthSession session, {
    required String userId,
  }) async {
    final data = await _send(session, 'GET', ['admin', 'users', userId]);
    return _decode(() => AdminManagedUser.fromJson(_asMap(data)));
  }

  @override
  Future<AdminManagedUser> setUserActiveStatus(
    AuthSession session, {
    required String targetUserId,
    required bool isActive,
    String? reason,
  }) async {
    final data = await _send(
      session,
      'POST',
      ['admin', 'users', targetUserId, 'status'],
      body: {'is_active': isActive, 'reason': ?reason},
    );
    return _decode(() => AdminManagedUser.fromJson(_asMap(data)));
  }

  @override
  Future<List<AdminStallSummary>> listStalls(
    AuthSession session, {
    String query = '',
    int limit = 50,
    int offset = 0,
  }) async {
    final trimmedQuery = query.trim();
    final data = await _send(
      session,
      'GET',
      ['admin', 'stalls'],
      query: {
        if (trimmedQuery.isNotEmpty) 'q': trimmedQuery,
        'limit': '$limit',
        'offset': '$offset',
      },
    );
    return _decode(() {
      final items = _asMap(data)['items'] as List? ?? const [];
      return [
        for (final item in items) AdminStallSummary.fromJson(_asMap(item)),
      ];
    });
  }

  @override
  Future<AdminStallSummary> fetchStall(
    AuthSession session, {
    required String stallId,
  }) async {
    final data = await _send(session, 'GET', ['admin', 'stalls', stallId]);
    return _decode(() => AdminStallSummary.fromJson(_asMap(data)));
  }

  @override
  Future<Uint8List?> fetchStallPhoto(
    AuthSession session, {
    required String stallId,
  }) => _auth.sendAuthenticatedMedia(session, 'GET', [
    'admin',
    'stalls',
    stallId,
    'photo',
  ], onEnvelopeError: mapAdminEnvelopeError);

  @override
  Future<List<AdminActionLog>> listActionLogs(
    AuthSession session, {
    String? targetUserId,
    int limit = 50,
    int offset = 0,
  }) async {
    final data = await _send(
      session,
      'GET',
      ['admin', 'action-logs'],
      query: {
        'target_user_id': ?targetUserId,
        'limit': '$limit',
        'offset': '$offset',
      },
    );
    return _decode(() {
      final items = _asMap(data)['items'] as List? ?? const [];
      return [for (final item in items) AdminActionLog.fromJson(_asMap(item))];
    });
  }

  Future<Object?> _send(
    AuthSession session,
    String method,
    List<String> path, {
    Map<String, String>? query,
    Object? body,
  }) => _auth.sendAuthenticated(
    session,
    method,
    path,
    query: query,
    body: body,
    onEnvelopeError: mapAdminEnvelopeError,
  );

  Map<String, dynamic> _asMap(Object? raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw authBadResponseException;
  }

  T _decode<T>(T Function() parser) {
    try {
      return parser();
    } on FormatException {
      throw authBadResponseException;
    } on TypeError {
      throw authBadResponseException;
    }
  }
}
