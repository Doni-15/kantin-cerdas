import 'dart:async';
import 'dart:collection';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_account.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
import 'package:kantin_cerdas/features/customer/application/customer_providers.dart';
import 'package:kantin_cerdas/features/notifications/application/notification_providers.dart';
import 'package:kantin_cerdas/features/notifications/domain/push_messaging_client.dart';
import 'package:kantin_cerdas/features/notifications/domain/push_notification_payload.dart';
import 'package:kantin_cerdas/features/owner/application/owner_providers.dart';

export 'package:kantin_cerdas/features/notifications/data/firebase_push_messaging_client.dart'
    show initializeFirebaseMessagingSafely;

class PushForegroundNotice {
  const PushForegroundNotice({
    required this.noticeId,
    required this.payload,
    required this.destination,
  });

  final int noticeId;
  final PushNotificationPayload payload;
  final AuthorizedPushDestination destination;
}

class PushCoordinatorState {
  const PushCoordinatorState({
    this.foregroundNotice,
    this.pendingNavigation,
    this.initialized = false,
  });

  final PushForegroundNotice? foregroundNotice;
  final PushNotificationPayload? pendingNavigation;
  final bool initialized;

  PushCoordinatorState copyWith({
    PushForegroundNotice? foregroundNotice,
    bool clearForegroundNotice = false,
    PushNotificationPayload? pendingNavigation,
    bool clearPendingNavigation = false,
    bool? initialized,
  }) {
    return PushCoordinatorState(
      foregroundNotice: clearForegroundNotice
          ? null
          : (foregroundNotice ?? this.foregroundNotice),
      pendingNavigation: clearPendingNavigation
          ? null
          : (pendingNavigation ?? this.pendingNavigation),
      initialized: initialized ?? this.initialized,
    );
  }
}

/// Coordinates FCM foreground notifications, background/cold-start taps,
/// event deduplication, authoritative REST invalidation, and auth-gated
/// navigation without duplicating Order UI.
class PushNotificationCoordinator extends Notifier<PushCoordinatorState> {
  static const _maxDedupIds = 500;

  final Queue<String> _seenForegroundOrder = Queue<String>();
  final Set<String> _seenForegroundIds = <String>{};
  final Queue<String> _seenOpenedOrder = Queue<String>();
  final Set<String> _seenOpenedIds = <String>{};

  StreamSubscription<PushNotificationPayload>? _foregroundSub;
  StreamSubscription<PushNotificationPayload>? _openedSub;
  var _disposed = false;
  var _noticeCounter = 0;

  @override
  PushCoordinatorState build() {
    _disposed = false;
    final client = ref.watch(pushMessagingClientProvider);
    ref.onDispose(_disposeInternal);
    Future<void>.microtask(() => _attach(client));
    return const PushCoordinatorState();
  }

  Future<void> _attach(PushMessagingClient client) async {
    if (_disposed) return;
    final ready = await client.ensureInitialized();
    if (_disposed) return;

    if (!ready) {
      state = state.copyWith(initialized: false);
      return;
    }

    _foregroundSub = client.onForegroundMessage.listen(
      _handleForegroundMessage,
      onError: (Object _, StackTrace _) {},
    );
    _openedSub = client.onMessageOpenedApp.listen(
      _handleNotificationTap,
      onError: (Object _, StackTrace _) {},
    );

    final initial = await client.getInitialMessage();
    if (_disposed) return;
    state = state.copyWith(initialized: true);
    if (initial != null) {
      _handleNotificationTap(initial);
    }
  }

  void _handleForegroundMessage(PushNotificationPayload payload) {
    if (_disposed) return;
    if (!_recordUnique(
      _seenForegroundIds,
      _seenForegroundOrder,
      payload.eventId,
    )) {
      return;
    }

    final session = ref.read(authControllerProvider).asData?.value;
    final destination = resolveAuthorizedPushDestination(
      session: session,
      payload: payload,
    );
    if (destination == null) {
      // Unauthenticated, incomplete profile, Admin, or role mismatch -> ignore.
      return;
    }

    // Backend REST remains source of truth (ORDER-017): refresh order providers.
    _refreshAuthoritativeOrderState(destination);

    _noticeCounter++;
    state = state.copyWith(
      foregroundNotice: PushForegroundNotice(
        noticeId: _noticeCounter,
        payload: payload,
        destination: destination,
      ),
    );
  }

  void _handleNotificationTap(PushNotificationPayload payload) {
    if (_disposed) return;
    if (!_recordUnique(_seenOpenedIds, _seenOpenedOrder, payload.eventId)) {
      return;
    }
    state = state.copyWith(pendingNavigation: payload);
  }

  /// Resolves and consumes a pending notification tap ONLY when authentication
  /// and role authorization succeed; drops unauthorized taps immediately.
  AuthorizedPushDestination? consumePendingNavigation(AuthSession? session) {
    final pending = state.pendingNavigation;
    if (pending == null) return null;
    state = state.copyWith(clearPendingNavigation: true);

    final destination = resolveAuthorizedPushDestination(
      session: session,
      payload: pending,
    );
    if (destination != null) {
      _refreshAuthoritativeOrderState(destination);
    }
    return destination;
  }

  void dismissForegroundNotice(int noticeId) {
    if (_disposed) return;
    if (state.foregroundNotice?.noticeId == noticeId) {
      state = state.copyWith(clearForegroundNotice: true);
    }
  }

  /// Clears pending navigation & foreground notices on logout, account switch,
  /// or role change so stale notifications never cross session boundaries (R2).
  void clearForSessionChange() {
    if (_disposed) return;
    _seenForegroundIds.clear();
    _seenForegroundOrder.clear();
    _seenOpenedIds.clear();
    _seenOpenedOrder.clear();
    if (state.foregroundNotice != null || state.pendingNavigation != null) {
      state = state.copyWith(
        clearForegroundNotice: true,
        clearPendingNavigation: true,
      );
    }
  }

  void _refreshAuthoritativeOrderState(AuthorizedPushDestination destination) {
    final accountId = destination.accountId;
    final orderId = destination.orderId;
    if (destination.targetRole == PushTargetRole.owner) {
      ref.invalidate(ownerDashboardProvider(accountId));
      ref.invalidate(ownerOrdersProvider);
      ref.invalidate(
        ownerOrderDetailProvider((accountId: accountId, orderId: orderId)),
      );
      return;
    }

    ref.invalidate(
      customerOrdersProvider((accountId: accountId, activeOnly: true)),
    );
    ref.invalidate(
      customerOrdersProvider((accountId: accountId, activeOnly: false)),
    );
    ref.invalidate(
      customerOrderDetailProvider((accountId: accountId, orderId: orderId)),
    );
    final role = ref.read(authControllerProvider).asData?.value?.account.role;
    if (role == AuthRole.owner) {
      ref.invalidate(ownerDashboardProvider(accountId));
    }
  }

  static bool _recordUnique(Set<String> seen, Queue<String> order, String id) {
    if (id.isEmpty) return true;
    if (!seen.add(id)) return false;
    order.addLast(id);
    while (order.length > _maxDedupIds) {
      seen.remove(order.removeFirst());
    }
    return true;
  }

  void _disposeInternal() {
    _disposed = true;
    unawaited(_foregroundSub?.cancel());
    unawaited(_openedSub?.cancel());
    _foregroundSub = null;
    _openedSub = null;
    _seenForegroundIds.clear();
    _seenForegroundOrder.clear();
    _seenOpenedIds.clear();
    _seenOpenedOrder.clear();
  }
}
