import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/auth/application/auth_controller.dart';
import 'package:kantin_cerdas/features/customer/presentation/customer_presentation.dart';
import 'package:kantin_cerdas/features/notifications/application/notification_providers.dart';
import 'package:kantin_cerdas/features/notifications/application/push_notification_coordinator.dart';
import 'package:kantin_cerdas/features/notifications/domain/push_notification_payload.dart';
import 'package:kantin_cerdas/features/owner/application/owner_providers.dart';
import 'package:kantin_cerdas/features/owner/presentation/owner_presentation.dart';

void openAuthorizedPushDestination({
  required BuildContext context,
  required WidgetRef ref,
  required AuthorizedPushDestination destination,
}) {
  final navigator = Navigator.maybeOf(context);
  if (navigator == null) return;

  if (destination.targetRole == PushTargetRole.owner) {
    ref
        .read(ownerCustomerViewProvider(destination.accountId).notifier)
        .switchToOwner();

    navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => OwnerOrderDetailPage(
          accountId: destination.accountId,
          orderId: destination.orderId,
        ),
      ),
    );
    return;
  }

  navigator.push(
    MaterialPageRoute<void>(
      builder: (_) => CustomerOrderDetailPage(
        accountId: destination.accountId,
        orderId: destination.orderId,
      ),
    ),
  );
}

void showAuthorizedPushForegroundNotice({
  required BuildContext context,
  required WidgetRef ref,
  required PushForegroundNotice notice,
  required bool Function() isMounted,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!isMounted()) return;
    final activeSession = ref.read(authControllerProvider).asData?.value;
    if (activeSession == null ||
        activeSession.account.id != notice.destination.accountId) {
      ref
          .read(pushNotificationCoordinatorProvider.notifier)
          .dismissForegroundNotice(notice.noticeId);
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${notice.payload.title}: ${notice.payload.body}'),
          action: SnackBarAction(
            label: 'Lihat',
            onPressed: () {
              if (!isMounted()) return;
              final current = ref.read(authControllerProvider).asData?.value;
              final authorized = resolveAuthorizedPushDestination(
                session: current,
                payload: notice.payload,
              );
              if (authorized != null) {
                openAuthorizedPushDestination(
                  context: context,
                  ref: ref,
                  destination: authorized,
                );
              }
            },
          ),
        ),
      );

    ref
        .read(pushNotificationCoordinatorProvider.notifier)
        .dismissForegroundNotice(notice.noticeId);
  });
}
