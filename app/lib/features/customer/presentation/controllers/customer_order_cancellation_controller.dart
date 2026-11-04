import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/session/shared_data_revision_provider.dart';
import 'package:kantin_cerdas/core/utils/mutation_id_generator.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_cancellation.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/pending_order_cancellation.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_cancellation_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_order_cancellation_failure.dart';
import 'package:kantin_cerdas/features/customer/presentation/controllers/customer_order_cancellation_state.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_feature_providers.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_order_detail_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/order_cancellation_journal_provider.dart';

final customerOrderCancellationControllerProvider =
    NotifierProvider<
      CustomerOrderCancellationController,
      CustomerOrderCancellationState
    >(CustomerOrderCancellationController.new, retry: (_, _) => null);

/// Satu pembatalan yang belum pasti per akun. Journal tidak membangun ulang controller.
final customerOrderCancellationProvider =
    Provider<CustomerOrderCancellationState>((ref) {
      final customerId = ref.watch(authStateProvider).activeCustomerId;
      if (customerId == null) {
        return const CustomerOrderCancellationState(configured: false);
      }
      final action = ref.watch(customerOrderCancellationControllerProvider);
      final journal = ref.watch(orderCancellationJournalProvider(customerId));
      final pending = journal.asData?.value;
      return CustomerOrderCancellationState(
        request: pending ?? action.request,
        busy: action.busy,
        unresolved: pending != null || action.unresolved,
        error: action.error,
        confirmed: action.confirmed,
        reconciled: action.reconciled,
        revision: action.revision,
        journalError: journal.error,
        journalLoading:
            journal.isLoading || (!journal.hasError && journal.asData == null),
        configured: ref
            .watch(customerOrderTrackingRepositoryProvider)
            .isCancellationConfigured,
      );
    });

class CustomerOrderCancellationController
    extends Notifier<CustomerOrderCancellationState> {
  String _actor = '';
  int _epoch = 0;
  int _revision = 0;
  AuthStateNotifier? _session;
  int _sessionGeneration = -1;
  final Set<String> _inFlight = {};
  static const _limit = Duration(seconds: 30);
  @override
  CustomerOrderCancellationState build() {
    _epoch++;
    _revision++;
    _actor = ref.watch(authStateProvider).activeCustomerId ?? '';
    _session = ref.watch(authStateProvider.notifier);
    _sessionGeneration = _session!.sessionGeneration;
    return CustomerOrderCancellationState(
      busy: _inFlight.contains(_actor),
      revision: _revision,
    );
  }

  bool _current(String actor, int epoch) {
    if (!ref.mounted || actor.isEmpty || actor != _actor || epoch != _epoch) {
      return false;
    }
    final auth = ref.read(authStateProvider);
    final session = ref.read(authStateProvider.notifier);
    return auth.activeCustomerId == actor &&
        identical(session, _session) &&
        session.sessionGeneration == _sessionGeneration;
  }

  void _publish({
    PendingOrderCancellation? request,
    bool busy = false,
    bool unresolved = false,
    bool confirmed = false,
    bool reconciled = false,
    CustomerOrderCancellationFailure? error,
  }) {
    state = CustomerOrderCancellationState(
      request: request,
      busy: busy,
      unresolved: unresolved,
      confirmed: confirmed,
      reconciled: reconciled,
      error: error,
      revision: _revision,
    );
  }

  Future<void> cancel(
    CustomerOrderCancellation input, {
    required int revision,
  }) async {
    if (!_current(_actor, _epoch) ||
        _inFlight.contains(_actor) ||
        ref.read(customerOrderCancellationProvider).blocked ||
        revision != _revision ||
        (state.confirmed && state.request?.orderId == input.orderId)) {
      return;
    }
    final actor = _actor;
    final epoch = _epoch;
    final data = ref.read(customerOrderDetailProvider(input.orderId));
    final before = data.asData?.value;
    if (data.isLoading ||
        data.hasError ||
        before == null ||
        !input.canApplyTo(before, customerId: actor)) {
      _publish(error: const CustomerOrderCancellationConflictFailure());
      ref.invalidate(customerOrderDetailProvider(input.orderId));
      return;
    }
    bool matchesBase() {
      final latest = ref.read(customerOrderDetailProvider(input.orderId));
      return !latest.isLoading &&
          !latest.hasError &&
          latest.asData?.value == before &&
          input.canApplyTo(before, customerId: actor);
    }

    final repository = ref.read(customerOrderTrackingRepositoryProvider);
    final journal = ref.read(orderCancellationJournalProvider(actor).notifier);
    _inFlight.add(actor);
    _publish(busy: true);
    PendingOrderCancellation? pending;
    var persisted = false;
    var dispatched = false;
    try {
      final id = generateSecureMutationId();
      pending = PendingOrderCancellation(
        customerId: actor,
        mutationId: id,
        input: input,
        stallId: before.stallId,
        orderNumber: before.orderNumber,
      );
      _publish(request: pending, busy: true);
      persisted = await journal.begin(pending);
      if (!persisted) {
        throw const CustomerOrderCancellationStorageFailure();
      }
      if (!_current(actor, epoch)) {
        await journal.finish(id); // Belum dispatch; bersihkan hanya ID ini.
        return;
      }
      if (!matchesBase()) {
        throw const CustomerOrderCancellationConflictFailure();
      }
      if (!identical(
            repository,
            ref.read(customerOrderTrackingRepositoryProvider),
          ) ||
          !repository.isCancellationConfigured) {
        throw const CustomerOrderCancellationNotConfiguredFailure();
      }
      dispatched = true;
      final after = await repository
          .cancelMyOrder(input, mutationId: id)
          .timeout(_limit);
      if (!_current(actor, epoch)) {
        return;
      }
      if (!input.acceptsResult(
        before: before,
        after: after,
        customerId: actor,
      )) {
        throw const CustomerOrderCancellationUnknownFailure();
      }
      if (!await journal.finish(id)) {
        throw const CustomerOrderCancellationStorageFailure();
      }
      if (!_current(actor, epoch)) {
        return;
      }
      _revision++;
      _publish(request: pending, confirmed: true);
      _refresh(input.orderId);
    } catch (error) {
      final failure = error is CustomerOrderCancellationFailure
          ? error
          : (dispatched
                ? const CustomerOrderCancellationUnknownFailure()
                : const CustomerOrderCancellationPreSendFailure());
      final definitive =
          !dispatched ||
          switch (failure) {
            CustomerOrderCancellationPreSendFailure() ||
            CustomerOrderCancellationNotConfiguredFailure() ||
            CustomerOrderCancellationForbiddenFailure() ||
            CustomerOrderCancellationRejectedFailure() ||
            CustomerOrderCancellationConflictFailure() => true,
            _ => false,
          };
      if (definitive &&
          persisted &&
          pending != null &&
          (!dispatched || _current(actor, epoch))) {
        if (!await journal.finish(pending.mutationId)) {
          if (_current(actor, epoch)) {
            _publish(
              request: pending,
              error: const CustomerOrderCancellationStorageFailure(),
            );
          }
          return;
        }
      }
      if (_current(actor, epoch)) {
        final storage = failure is CustomerOrderCancellationStorageFailure;
        _publish(
          request: pending,
          unresolved: !definitive && !storage,
          error: definitive || storage
              ? failure
              : const CustomerOrderCancellationUnknownFailure(),
        );
        if (failure is CustomerOrderCancellationConflictFailure ||
            failure is CustomerOrderCancellationForbiddenFailure) {
          _refresh(input.orderId);
        }
      }
    } finally {
      _finished(actor);
    }
  }

  Future<void> recover() async {
    if (!_current(_actor, _epoch) || _inFlight.contains(_actor)) {
      return;
    }
    final actor = _actor;
    final epoch = _epoch;
    final data = ref.read(orderCancellationJournalProvider(actor));
    if (data.isLoading || data.hasError) {
      return;
    }
    final pending = data.asData?.value;
    if (pending == null) {
      return;
    }
    final journal = ref.read(orderCancellationJournalProvider(actor).notifier);
    final repository = ref.read(customerOrderTrackingRepositoryProvider);
    _inFlight.add(actor);
    _publish(request: pending, busy: true);
    try {
      final result = await repository
          .lookupCancellation(mutationId: pending.mutationId)
          .timeout(_limit);
      if (!_current(actor, epoch)) {
        return;
      }
      if (!pending.matches(result.request) ||
          result.outcome == OrderCancellationOutcome.pending) {
        throw const CustomerOrderCancellationUnknownFailure();
      }
      if (!await journal.finish(pending.mutationId)) {
        throw const CustomerOrderCancellationStorageFailure();
      }
      if (!_current(actor, epoch)) {
        return;
      }
      _revision++;
      _publish(
        request: pending,
        confirmed: result.outcome == OrderCancellationOutcome.applied,
        reconciled: result.outcome == OrderCancellationOutcome.notApplied,
      );
      _refresh(pending.orderId);
    } catch (error) {
      if (_current(actor, epoch)) {
        _publish(
          request: pending,
          unresolved: true,
          error: error is CustomerOrderCancellationFailure
              ? error
              : const CustomerOrderCancellationUnknownFailure(),
        );
      }
    } finally {
      _finished(actor);
    }
  }

  Future<void> reloadJournal() async {
    if (!_current(_actor, _epoch) || _inFlight.contains(_actor)) {
      return;
    }
    final actor = _actor;
    final epoch = _epoch;
    final journal = ref.read(orderCancellationJournalProvider(actor).notifier);
    _inFlight.add(actor);
    _publish(busy: true);
    try {
      await journal.reload();
      if (!_current(actor, epoch)) {
        return;
      }
      final value = ref.read(orderCancellationJournalProvider(actor));
      if (!value.isLoading &&
          !value.hasError &&
          value.asData != null &&
          value.asData!.value == null) {
        _revision++;
        ref.invalidate(customerOrderDetailProvider);
        ref.invalidate(customerOrderFeedProvider);
      }
      _publish();
    } finally {
      _finished(actor);
    }
  }

  void _refresh(String orderId) {
    ref.read(sharedDataRevisionProvider.notifier).bump();
    ref.invalidate(customerOrderDetailProvider(orderId));
    ref.invalidate(customerOrderFeedProvider);
  }

  void _finished(String actor) {
    _inFlight.remove(actor);
    if (ref.mounted && actor == _actor && state.busy) {
      _publish();
    }
  }
}
