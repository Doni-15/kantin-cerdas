import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_error_mapper.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_account.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
import 'package:kantin_cerdas/features/customer/application/customer_providers.dart';
import 'package:kantin_cerdas/features/notifications/application/notification_providers.dart';
import 'package:kantin_cerdas/features/notifications/domain/notification_models.dart';
import 'package:kantin_cerdas/features/notifications/domain/notifications_repository.dart';
import 'package:kantin_cerdas/features/owner/application/owner_providers.dart';

/// Account-scoped Realtime & Push synchronization coordinator (ORDER-017, R2).
///
/// Keyed by `(accountId)` via Riverpod autoDispose family so switching accounts
/// or logging out tears down the stream, clears deduplication state, and revokes
/// active push device registrations with zero cross-account leakage.
class RealtimeOrderSyncNotifier extends Notifier<RealtimeSyncState> {
  RealtimeOrderSyncNotifier(this._accountId);

  final String _accountId;

  static const _maxDedupIds = 500;
  final Queue<String> _seenEventOrder = Queue<String>();
  final Set<String> _seenEventIds = <String>{};

  RealtimeStreamHandle? _streamHandle;
  StreamSubscription<RealtimeStreamFrame>? _streamSub;
  StreamSubscription<String>? _tokenRefreshSub;
  Timer? _reconnectTimer;
  List<AuthPreLogoutCallback>? _logoutHooks;
  AuthPreLogoutCallback? _logoutHook;

  var _disposed = false;
  var _attempt = 0;
  var _hadGrantOrDevice = false;
  String? _registeredDeviceId;
  String? _lastRegisteredToken;
  AuthRole? _activeRole;

  @override
  RealtimeSyncState build() {
    _disposed = false;
    _attempt = 0;
    _hadGrantOrDevice = false;
    _registeredDeviceId = null;
    _lastRegisteredToken = null;
    _seenEventOrder.clear();
    _seenEventIds.clear();

    final hooks = ref.read(authPreLogoutHooksProvider);
    _logoutHooks = hooks;
    _logoutHook = _handleBeforeLogout;
    hooks.add(_logoutHook!);

    ref.onDispose(_disposeInternal);

    final session = ref.read(authControllerProvider).asData?.value;
    if (session != null &&
        session.account.id == _accountId &&
        (session.account.role == AuthRole.customer ||
            session.account.role == AuthRole.owner)) {
      _activeRole = session.account.role;
      Future<void>.microtask(() => _start(session));
      return const RealtimeSyncState(mode: RealtimeConnectionMode.connecting);
    }

    return const RealtimeSyncState(mode: RealtimeConnectionMode.idle);
  }

  /// Forces an immediate catch-up / reconnect check (e.g. on app resume).
  Future<void> reconnectNow() async {
    if (_disposed) return;
    final session = _currentMatchingSession();
    if (session == null) return;
    if (state.mode == RealtimeConnectionMode.revoked) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _attempt = 0;
    await _closeStream();
    await _connectLoop(session, refreshAuthoritativeState: true);
  }

  Future<void> _start(AuthSession session) async {
    if (_disposed) return;
    await _registerPushDeviceIfAvailable(session);
    if (_disposed) return;
    await _connectLoop(session, refreshAuthoritativeState: false);
  }

  Future<void> _registerPushDeviceIfAvailable(AuthSession session) async {
    if (_disposed || !_matchesActiveAccount(session)) return;
    final tokenSource = ref.read(pushTokenSourceProvider);
    try {
      final fcmToken = (await tokenSource.getAndroidFcmToken())?.trim();
      if (_disposed || !_matchesActiveAccount(session)) return;
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _sendPushDeviceRegistration(session, fcmToken);
      }
      if (_disposed) return;
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = tokenSource.onTokenRefresh.listen((refreshedToken) {
        final clean = refreshedToken.trim();
        if (_disposed || clean.isEmpty || clean == _lastRegisteredToken) {
          return;
        }
        final latestSession = _currentMatchingSession();
        if (latestSession == null) return;
        unawaited(_sendPushDeviceRegistration(latestSession, clean));
      }, onError: (Object _, StackTrace _) {});
    } catch (_) {
      // Best-effort: notification permission denied or Firebase unavailable never blocks realtime/orders.
    }
  }

  Future<void> _sendPushDeviceRegistration(
    AuthSession session,
    String fcmToken,
  ) async {
    if (_disposed || !_matchesActiveAccount(session)) return;
    try {
      final deviceId =
          _registeredDeviceId ??
          await ref.read(pushTokenSourceProvider).getOrCreateDeviceId();
      if (_disposed || !_matchesActiveAccount(session)) return;
      await ref
          .read(notificationsRepositoryProvider)
          .registerPushDevice(session, deviceId: deviceId, fcmToken: fcmToken);
      _registeredDeviceId = deviceId;
      _lastRegisteredToken = fcmToken;
      _hadGrantOrDevice = true;
    } catch (_) {
      // Best-effort: backend error or offline network never interrupts checkout/order flows.
    }
  }

  Future<void> _connectLoop(
    AuthSession session, {
    required bool refreshAuthoritativeState,
  }) async {
    if (_disposed) return;
    if (!_matchesActiveAccount(session)) {
      _transitionRevoked();
      return;
    }

    final repo = ref.read(notificationsRepositoryProvider);

    try {
      final grant = await repo.fetchChannelGrant(session);
      if (_disposed) return;
      _hadGrantOrDevice = true;

      var cursor = state.lastSeq;
      if (cursor == 0 && grant.lastSeq > 0) {
        cursor = grant.lastSeq;
      }

      if (refreshAuthoritativeState) {
        // Recover any missed signals and refresh authoritative order data from backend REST.
        final catchUp = await repo.pollSignals(session, afterSeq: cursor);
        if (_disposed) return;
        for (final signal in catchUp.items) {
          _applySignal(signal);
        }
        if (catchUp.lastSeq > cursor) {
          cursor = catchUp.lastSeq;
        }
        _invalidateAllOrdersForRole(session.account.role);
      }

      if (_disposed) return;
      state = state.copyWith(
        mode: RealtimeConnectionMode.connecting,
        lastSeq: cursor,
        customerEpoch: grant.customerEpoch,
        stallEpoch: grant.stallEpoch,
      );

      final handle = await repo.openRealtimeStream(session, afterSeq: cursor);
      if (_disposed) {
        await handle.close();
        return;
      }

      _streamHandle = handle;
      _attempt = 0;
      state = state.copyWith(mode: RealtimeConnectionMode.live);

      _streamSub = handle.frames.listen(
        _onFrame,
        onError: (Object error, StackTrace _) {
          _handleStreamClosed(error);
        },
        onDone: () {
          _handleStreamClosed(null);
        },
        cancelOnError: true,
      );
    } on AuthException catch (error) {
      if (_disposed) return;
      if (_isUnsupportedRoute(error)) {
        state = state.copyWith(mode: RealtimeConnectionMode.restFallback);
        return;
      }
      if (_isRevocationError(error)) {
        _transitionRevoked();
        return;
      }
      _scheduleReconnect();
    } catch (_) {
      if (_disposed) return;
      _scheduleReconnect();
    }
  }

  void _onFrame(RealtimeStreamFrame frame) {
    if (_disposed) return;
    switch (frame) {
      case RealtimeConnectedFrame(
        :final lastSeq,
        :final customerEpoch,
        :final stallEpoch,
      ):
        final nextSeq = lastSeq > state.lastSeq ? lastSeq : state.lastSeq;
        state = state.copyWith(
          mode: RealtimeConnectionMode.live,
          lastSeq: nextSeq,
          customerEpoch: customerEpoch,
          stallEpoch: stallEpoch,
        );
      case RealtimeOrderSignalFrame(:final signal):
        _applySignal(signal);
      case RealtimeTopicRotatedFrame(:final customerEpoch, :final stallEpoch):
        state = state.copyWith(
          customerEpoch: customerEpoch,
          stallEpoch: stallEpoch,
        );
      case RealtimeSessionRevokedFrame():
        _transitionRevoked();
    }
  }

  void _applySignal(RealtimeOrderSignal signal) {
    if (_disposed) return;
    // Strict deduplication by eventId and monotonic sequence cursor.
    if (signal.eventId.isNotEmpty && _seenEventIds.contains(signal.eventId)) {
      return;
    }
    if (signal.seq > 0 && signal.seq <= state.lastSeq) {
      return;
    }

    if (signal.eventId.isNotEmpty) {
      _seenEventIds.add(signal.eventId);
      _seenEventOrder.addLast(signal.eventId);
      while (_seenEventOrder.length > _maxDedupIds) {
        _seenEventIds.remove(_seenEventOrder.removeFirst());
      }
    }

    final nextSeq = signal.seq > state.lastSeq ? signal.seq : state.lastSeq;
    state = state.copyWith(
      lastSeq: nextSeq,
      receivedSignals: state.receivedSignals + 1,
      lastOrderId: signal.orderId,
      lastStatus: signal.toStatus,
    );

    // Backend REST remains source of truth (ORDER-017, RT-TECH-003):
    // invalidate only the authorized providers for the active account.
    if (signal.targetsCustomer) {
      ref.invalidate(
        customerOrdersProvider((accountId: _accountId, activeOnly: true)),
      );
      ref.invalidate(
        customerOrdersProvider((accountId: _accountId, activeOnly: false)),
      );
      if (signal.orderId.isNotEmpty) {
        ref.invalidate(
          customerOrderDetailProvider((
            accountId: _accountId,
            orderId: signal.orderId,
          )),
        );
      }
    }

    if (_activeRole == AuthRole.owner && signal.targetsOwner) {
      ref.invalidate(ownerDashboardProvider(_accountId));
      ref.invalidate(ownerOrdersProvider);
      if (signal.orderId.isNotEmpty) {
        ref.invalidate(
          ownerOrderDetailProvider((
            accountId: _accountId,
            orderId: signal.orderId,
          )),
        );
      }
    }
  }

  void _invalidateAllOrdersForRole(AuthRole role) {
    ref.invalidate(
      customerOrdersProvider((accountId: _accountId, activeOnly: true)),
    );
    ref.invalidate(
      customerOrdersProvider((accountId: _accountId, activeOnly: false)),
    );
    if (role == AuthRole.owner) {
      ref.invalidate(ownerDashboardProvider(_accountId));
      ref.invalidate(ownerOrdersProvider);
    }
  }

  void _handleStreamClosed(Object? error) {
    if (_disposed || state.mode == RealtimeConnectionMode.revoked) return;
    unawaited(_closeStream());
    if (error is AuthException && _isRevocationError(error)) {
      _transitionRevoked();
      return;
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || state.mode == RealtimeConnectionMode.revoked) return;
    if (_reconnectTimer != null) return;
    final session = _currentMatchingSession();
    if (session == null) {
      _transitionRevoked();
      return;
    }

    final schedule = ref.read(realtimeReconnectBackoffProvider);
    final index = _attempt < schedule.length ? _attempt : schedule.length - 1;
    final delay = schedule[index];
    _attempt++;
    state = state.copyWith(mode: RealtimeConnectionMode.reconnecting);

    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (_disposed) return;
      final latestSession = _currentMatchingSession();
      if (latestSession == null) {
        _transitionRevoked();
        return;
      }
      unawaited(_connectLoop(latestSession, refreshAuthoritativeState: true));
    });
  }

  Future<void> _handleBeforeLogout(AuthSession session) async {
    if (session.account.id != _accountId) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _tokenRefreshSub?.cancel();
    _tokenRefreshSub = null;
    await _closeStream();
    _seenEventIds.clear();
    _seenEventOrder.clear();

    if (!_hadGrantOrDevice) return;
    try {
      final deviceId =
          _registeredDeviceId ??
          await ref.read(pushTokenSourceProvider).getOrCreateDeviceId();
      await ref
          .read(notificationsRepositoryProvider)
          .revokePushDevice(session, deviceId: deviceId, rotateTopics: true);
    } catch (_) {
      // Logout must never be blocked if revoke request fails offline.
    } finally {
      _hadGrantOrDevice = false;
      _registeredDeviceId = null;
      _lastRegisteredToken = null;
      if (!_disposed) {
        state = state.copyWith(mode: RealtimeConnectionMode.revoked);
      }
    }
  }

  void _transitionRevoked() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    unawaited(_tokenRefreshSub?.cancel());
    _tokenRefreshSub = null;
    unawaited(_closeStream());
    _seenEventIds.clear();
    _seenEventOrder.clear();
    if (!_disposed) {
      state = state.copyWith(mode: RealtimeConnectionMode.revoked);
    }
  }

  Future<void> _closeStream() async {
    final sub = _streamSub;
    _streamSub = null;
    final handle = _streamHandle;
    _streamHandle = null;
    try {
      await sub?.cancel();
    } catch (_) {}
    try {
      await handle?.close();
    } catch (_) {}
  }

  void _disposeInternal() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    unawaited(_tokenRefreshSub?.cancel());
    _tokenRefreshSub = null;
    if (_logoutHook != null) {
      _logoutHooks?.remove(_logoutHook);
      _logoutHook = null;
    }
    _logoutHooks = null;
    _lastRegisteredToken = null;
    unawaited(_closeStream());
    _seenEventIds.clear();
    _seenEventOrder.clear();
  }

  AuthSession? _currentMatchingSession() {
    final current = ref.read(authControllerProvider).asData?.value;
    if (current == null || !_matchesActiveAccount(current)) return null;
    return current;
  }

  bool _matchesActiveAccount(AuthSession session) {
    return session.account.id == _accountId &&
        (session.account.role == AuthRole.customer ||
            session.account.role == AuthRole.owner);
  }

  static bool _isUnsupportedRoute(AuthException error) {
    return error.code == 'ROUTE_NOT_FOUND' || error.code == 'NOT_CONFIGURED';
  }

  static bool _isRevocationError(AuthException error) {
    return error.code == 'INVALID_SESSION' ||
        error.code == 'ACCOUNT_INACTIVE' ||
        error.code == 'NOTIFICATION_ROLE_NOT_ALLOWED' ||
        error.code == 'EMAIL_NOT_VERIFIED';
  }
}
