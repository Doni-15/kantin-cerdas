import 'package:kantin_cerdas/features/customer/domain/entities/pending_order_cancellation.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_order_cancellation_failure.dart';

class CustomerOrderCancellationState {
  const CustomerOrderCancellationState({
    this.request,
    this.busy = false,
    this.unresolved = false,
    this.error,
    this.confirmed = false,
    this.reconciled = false,
    this.journalLoading = false,
    this.journalError,
    this.configured = true,
    this.revision = 0,
  });
  final PendingOrderCancellation? request;
  final bool busy;
  final bool unresolved;
  final CustomerOrderCancellationFailure? error;
  final bool confirmed;
  final bool reconciled;
  final bool journalLoading;
  final Object? journalError;
  final bool configured;
  final int revision;
  bool get blocked =>
      busy ||
      unresolved ||
      journalLoading ||
      journalError != null ||
      !configured;
  bool get hasNotice =>
      busy ||
      unresolved ||
      error != null ||
      confirmed ||
      reconciled ||
      journalLoading ||
      journalError != null;
}
