import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/auth/data/auth_repository.dart';
import 'package:kantin_cerdas/features/notifications/data/sse_frame_parser.dart';
import 'package:kantin_cerdas/features/notifications/domain/notification_models.dart';
import 'package:kantin_cerdas/features/notifications/domain/notifications_repository.dart';

class NotificationsApiRepository implements NotificationsRepository {
  const NotificationsApiRepository(this._auth);

  final AuthRepository _auth;

  @override
  Future<RealtimeChannelGrant> fetchChannelGrant(AuthSession session) async {
    final data = await _auth.sendAuthenticated(session, 'GET', const [
      'notifications',
      'realtime',
      'grant',
    ], onEnvelopeError: _mapNotificationEnvelopeError);
    return _decode(
      () => RealtimeChannelGrant.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<RealtimeSignalsPage> pollSignals(
    AuthSession session, {
    required int afterSeq,
    int limit = 50,
  }) async {
    final data = await _auth.sendAuthenticated(
      session,
      'GET',
      const ['notifications', 'realtime', 'signals'],
      query: {'after_seq': '$afterSeq', 'limit': '$limit'},
      onEnvelopeError: _mapNotificationEnvelopeError,
    );
    return _decode(
      () => RealtimeSignalsPage.fromJson(data as Map<String, dynamic>),
    );
  }

  @override
  Future<RealtimeStreamHandle> openRealtimeStream(
    AuthSession session, {
    required int afterSeq,
  }) async {
    final opened = await _auth.openAuthenticatedStream(
      session,
      const ['notifications', 'realtime', 'stream'],
      query: {'after_seq': '$afterSeq'},
      accept: 'text/event-stream',
    );
    final frames = parseRealtimeSseStream(opened.stream);
    return RealtimeStreamHandle(
      frames: frames,
      close: () async => opened.abort(),
    );
  }

  @override
  Future<void> registerPushDevice(
    AuthSession session, {
    required String deviceId,
    required String fcmToken,
  }) async {
    await _auth.sendAuthenticated(
      session,
      'POST',
      const ['notifications', 'devices'],
      body: {
        'device_id': deviceId,
        'fcm_token': fcmToken,
        'platform': 'android',
      },
      onEnvelopeError: _mapNotificationEnvelopeError,
    );
  }

  @override
  Future<void> revokePushDevice(
    AuthSession session, {
    required String deviceId,
    bool rotateTopics = true,
  }) async {
    await _auth.sendAuthenticated(
      session,
      'DELETE',
      ['notifications', 'devices', deviceId],
      query: {'rotate_topic': rotateTopics ? 'true' : 'false'},
      onEnvelopeError: _mapNotificationEnvelopeError,
    );
  }

  T _decode<T>(T Function() parse) {
    try {
      return parse();
    } on TypeError {
      throw const AuthException(
        'INVALID_RESPONSE',
        'Format respons realtime tidak dikenali.',
      );
    } on FormatException {
      throw const AuthException(
        'INVALID_RESPONSE',
        'Format respons realtime tidak dikenali.',
      );
    }
  }
}

AuthException _mapNotificationEnvelopeError(
  int statusCode,
  Map<String, dynamic> envelope,
) {
  final error = envelope['error'];
  if (error is Map<String, dynamic>) {
    final code = (error['code'] as String?)?.trim() ?? '';
    final message = (error['message'] as String?)?.trim() ?? '';
    if (code.isNotEmpty) {
      return AuthException(
        code,
        message.isEmpty ? 'Gagal mengakses layanan realtime.' : message,
      );
    }
  }
  if (statusCode == 404) {
    return const AuthException('ROUTE_NOT_FOUND', 'Route tidak tersedia.');
  }
  return mapAuthEnvelopeError(statusCode, envelope);
}
