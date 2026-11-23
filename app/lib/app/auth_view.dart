import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/app/lifecycle/auth_session_lifecycle.dart';
import 'package:kantin_cerdas/app/navigation/app_destination_view.dart';
import 'package:kantin_cerdas/app/navigation/auth_email_link_overlay.dart';
import 'package:kantin_cerdas/app/navigation/push_notification_navigator.dart';
import 'package:kantin_cerdas/app/routing/app_destination_resolver.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/auth/application/providers/auth_email_links_provider.dart';
import 'package:kantin_cerdas/features/auth/application/services/auth_email_link_service.dart';
import 'package:kantin_cerdas/features/auth/domain/auth_email_link.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_account.dart';
import 'package:kantin_cerdas/features/auth/domain/models/auth_session.dart';
import 'package:kantin_cerdas/features/auth/presentation/widgets/splash_transition.dart';
import 'package:kantin_cerdas/features/notifications/application/notification_providers.dart';
import 'package:kantin_cerdas/features/owner/application/owner_providers.dart';

class AuthView extends ConsumerStatefulWidget {
  const AuthView({super.key});

  @override
  ConsumerState<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends ConsumerState<AuthView> {
  AuthEmailLink? _emailLink;
  var _linkReturnState = const AuthEmailLinkReturnState();
  late final AppLifecycleListener _lifecycle;
  var _navigationScheduled = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = createAuthSessionLifecycleListener(ref);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _schedulePendingPushCheck(AsyncValue<AuthSession?> sessionAsync) {
    if (_navigationScheduled || sessionAsync.isLoading) return;
    final pending = ref
        .read(pushNotificationCoordinatorProvider)
        .pendingNavigation;
    if (pending == null) return;
    _navigationScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigationScheduled = false;
      if (!mounted) return;

      final currentSessionAsync = ref.read(authControllerProvider);
      if (currentSessionAsync.isLoading) return;

      final destination = ref
          .read(pushNotificationCoordinatorProvider.notifier)
          .consumePendingNavigation(currentSessionAsync.asData?.value);

      if (destination != null) {
        openAuthorizedPushDestination(
          context: context,
          ref: ref,
          destination: destination,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      final prevId = previous?.asData?.value?.account.id;
      final prevRole = previous?.asData?.value?.account.role;
      final nextAccount = next.asData?.value?.account;

      if (prevId != null &&
          (nextAccount == null ||
              nextAccount.id != prevId ||
              nextAccount.role != prevRole)) {
        ref
            .read(pushNotificationCoordinatorProvider.notifier)
            .clearForSessionChange();

        Navigator.maybeOf(context)?.popUntil((route) => route.isFirst);
      }

      if (!next.isLoading) {
        _schedulePendingPushCheck(next);
      }
    });

    ref.listen(pushNotificationCoordinatorProvider, (previous, next) {
      final notice = next.foregroundNotice;

      if (notice != null &&
          notice.noticeId != previous?.foregroundNotice?.noticeId) {
        showAuthorizedPushForegroundNotice(
          context: context,
          ref: ref,
          notice: notice,
          isMounted: () => mounted,
        );
      }

      if (next.pendingNavigation != null &&
          next.pendingNavigation?.eventId !=
              previous?.pendingNavigation?.eventId) {
        _schedulePendingPushCheck(ref.read(authControllerProvider));
      }
    });

    ref.listen(authEmailLinksProvider, (_, next) {
      final link = next.asData?.value;

      if (shouldAcceptIncomingEmailLink(
        activeLink: _emailLink,
        incomingLink: link,
      )) {
        setState(() => _emailLink = link);
      }
    });

    ref.watch(pushNotificationCoordinatorProvider);

    final session = ref.watch(authControllerProvider);
    final activeAccount = session.asData?.value?.account;
    final ownerCustomerView =
        activeAccount != null && activeAccount.role == AuthRole.owner
        ? ref.watch(ownerCustomerViewProvider(activeAccount.id))
        : false;

    final destination = resolveAppDestination(
      session: session,
      ownerCustomerView: ownerCustomerView,
    );

    final screen = buildAppDestinationScreen(
      ref: ref,
      destination: destination,
      linkReturnState: _linkReturnState,
    );

    return SplashTransition(
      screen: buildAuthEmailLinkOverlay(
        screen: screen,
        activeLink: _emailLink,
        session: session,
        onCloseLink: (notice, requestNew) => setState(() {
          _emailLink = null;
          _linkReturnState = _linkReturnState.closeWith(
            notice: notice,
            requestNew: requestNew,
          );
        }),
      ),
    );
  }
}
