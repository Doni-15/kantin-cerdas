import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/session/shared_data_revision_provider.dart';
import 'package:kantin_cerdas/core/utils/mutation_id_generator.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_menu.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_mutation_lookup.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_order_transition.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/owner_stall.dart';
import 'package:kantin_cerdas/features/owner/domain/entities/pending_owner_mutation.dart';
import 'package:kantin_cerdas/features/owner/domain/failures/owner_failure.dart';
import 'package:kantin_cerdas/features/owner/domain/repositories/owner_repository.dart';
import 'package:kantin_cerdas/features/owner/presentation/providers/owner_mutation_journal_provider.dart';
import 'package:kantin_cerdas/features/owner/presentation/providers/owner_order_detail_provider.dart';
import 'package:kantin_cerdas/features/owner/presentation/providers/owner_providers.dart';

class OwnerMutationState {
  const OwnerMutationState({
    this.busy = false,
    this.uncertain = false,
    this.operation = '',
    this.error,
    this.succeeded = false,
    this.journalLoading = false,
    this.journalError,
    this.configured = true,
    this.reviewRevision = 0,
  });
  final bool busy;
  final bool uncertain;
  final bool succeeded;
  final String operation;
  final Object? error;
  final bool journalLoading;
  final Object? journalError;
  final bool configured;
  final int reviewRevision;
  bool get blocked =>
      busy ||
      uncertain ||
      journalLoading ||
      journalError != null ||
      !configured;
}

final ownerMutationControllerProvider =
    NotifierProvider<OwnerMutationController, OwnerMutationState>(
      OwnerMutationController.new,
      retry: (_, _) => null,
    );

/// Gabungkan lock persisten dan hasil aksi tanpa membangun ulang controller
/// setiap kali jurnal berubah. UI membaca state ini, event memakai controller.
final ownerMutationProvider = Provider<OwnerMutationState>((ref) {
  final ownerId = ref.watch(authStateProvider).activeOwnerId;
  if (ownerId == null) {
    return const OwnerMutationState(configured: false);
  }
  final action = ref.watch(ownerMutationControllerProvider);
  final journal = ref.watch(ownerMutationJournalProvider(ownerId));
  final pending = journal.asData?.value;
  return OwnerMutationState(
    busy: action.busy,
    uncertain: pending != null || action.uncertain,
    operation: pending?.operation ?? action.operation,
    error: action.error,
    succeeded: action.succeeded,
    journalLoading:
        journal.isLoading || (!journal.hasError && journal.asData == null),
    journalError: journal.error,
    configured: ref.watch(ownerRepositoryProvider).isMutationConfigured,
    reviewRevision: action.reviewRevision,
  );
});

class OwnerMutationController extends Notifier<OwnerMutationState> {
  int _generation = 0;
  int _reviewRevision = 0;
  String _actor = '';
  AuthStateNotifier? _session;
  int _sessionGeneration = -1;
  final Set<String> _inFlight = {};
  static const _limit = Duration(seconds: 30);

  @override
  OwnerMutationState build() {
    _generation++;
    _reviewRevision++;
    _actor = ref.watch(authStateProvider).activeOwnerId ?? '';
    _session = ref.watch(authStateProvider.notifier);
    _sessionGeneration = _session!.sessionGeneration;
    return OwnerMutationState(
      busy: _inFlight.contains(_actor),
      reviewRevision: _reviewRevision,
    );
  }

  bool _current(String actor, int generation) {
    if (!ref.mounted ||
        generation != _generation ||
        actor.isEmpty ||
        actor != _actor) {
      return false;
    }
    final auth = ref.read(authStateProvider);
    final session = ref.read(authStateProvider.notifier);
    return auth.activeOwnerId == actor &&
        identical(session, _session) &&
        session.sessionGeneration == _sessionGeneration;
  }

  bool _owns(String stallId) {
    if (!_current(_actor, _generation)) {
      return false;
    }
    final data = ref.read(ownerStallProvider);
    final stall = data.asData?.value;
    return !data.isLoading &&
        !data.hasError &&
        stall != null &&
        stall.id == stallId &&
        stall.ownerId == _actor;
  }

  void _publish({
    bool busy = false,
    bool uncertain = false,
    bool succeeded = false,
    String operation = '',
    Object? error,
  }) {
    state = OwnerMutationState(
      busy: busy,
      uncertain: uncertain,
      succeeded: succeeded,
      operation: operation,
      error: error,
      reviewRevision: _reviewRevision,
    );
  }

  Future<bool> saveMenu(OwnerMenuInput input, {required int reviewRevision}) {
    if (!ref.mounted || reviewRevision != _reviewRevision) {
      return Future.value(false);
    }
    return _perform(
      kind: OwnerMutationKind.saveMenu,
      stallId: input.stallId,
      targetId: input.id,
      expectedVersion: input.expectedVersion,
      preflight: () => reviewRevision == _reviewRevision,
      action: (repository, id) async {
        final saved = await repository.saveMenu(input, mutationId: id);
        if (!input.acceptsResult(saved)) {
          throw const OwnerUnconfirmedFailure();
        }
      },
    );
  }

  Future<bool> deleteMenu(OwnerMenu menu) => _perform(
    kind: OwnerMutationKind.deleteMenu,
    stallId: menu.stallId,
    targetId: menu.id,
    expectedVersion: menu.version,
    action: (repository, id) => repository.deleteMenu(
      id: menu.id,
      expectedVersion: menu.version,
      mutationId: id,
    ),
  );

  Future<bool> saveStall(OwnerStallInput input) {
    final actor = _actor;
    return _perform(
      kind: OwnerMutationKind.saveStall,
      stallId: input.id,
      targetId: input.id,
      expectedVersion: input.expectedVersion,
      preflight: () =>
          ref.read(ownerStallProvider).asData?.value?.version ==
          input.expectedVersion,
      action: (repository, id) async {
        final saved = await repository.saveStall(input, mutationId: id);
        if (!input.acceptsResult(saved, ownerId: actor)) {
          throw const OwnerUnconfirmedFailure();
        }
      },
    );
  }

  Future<bool> transition(OrderRecord order, OwnerOrderTransition input) {
    if (!ref.mounted) {
      return Future.value(false);
    }
    final current = ref.read(ownerOrderDetailProvider(order.id));
    final snapshot = current.asData?.value;
    if (current.isLoading ||
        current.hasError ||
        snapshot == null ||
        snapshot.stallId != order.stallId ||
        !input.canApplyTo(order) ||
        !input.canApplyTo(snapshot)) {
      return Future.value(false);
    }
    return _perform(
      kind: OwnerMutationKind.transitionOrder,
      stallId: order.stallId,
      targetId: order.id,
      expectedVersion: input.expectedVersion,
      orderStatus: input.status,
      preflight: () {
        final latest = ref.read(ownerOrderDetailProvider(order.id));
        return !latest.isLoading &&
            !latest.hasError &&
            latest.asData?.value == snapshot;
      },
      action: (repository, id) async {
        final saved = await repository.transitionOrder(input, mutationId: id);
        if (!input.acceptsResult(before: snapshot, after: saved)) {
          throw const OwnerUnconfirmedFailure();
        }
      },
    );
  }

  Future<bool> _perform({
    required OwnerMutationKind kind,
    required String stallId,
    String? targetId,
    int? expectedVersion,
    OrderStatus? orderStatus,
    bool Function()? preflight,
    required Future<void> Function(OwnerRepository, String) action,
  }) async {
    if (!ref.mounted ||
        !_owns(stallId) ||
        _inFlight.contains(_actor) ||
        ref.read(ownerMutationProvider).blocked) {
      return false;
    }
    final actor = _actor;
    final generation = _generation;
    final repository = ref.read(ownerRepositoryProvider);
    final journal = ref.read(ownerMutationJournalProvider(actor).notifier);
    final operation = PendingOwnerMutation.operationOf(
      kind,
      targetId: targetId,
    );
    _inFlight.add(actor);
    _publish(busy: true, operation: operation);
    PendingOwnerMutation? pending;
    var saved = false;
    var dispatched = false;
    try {
      final id = generateSecureMutationId();
      pending = PendingOwnerMutation(
        ownerId: actor,
        mutationId: id,
        stallId: stallId,
        kind: kind,
        targetId: targetId,
        expectedVersion: expectedVersion,
        orderStatus: orderStatus,
      );
      if (preflight != null && !preflight()) {
        throw const OwnerConflictFailure();
      }
      saved = await journal.begin(pending);
      if (!saved) {
        throw const OwnerStorageFailure();
      }
      if (!_current(actor, generation)) {
        await journal.finish(
          id,
        ); // Belum dispatch; hanya ID ini yang dibersihkan.
        return false;
      }
      if (!_owns(stallId) || (preflight != null && !preflight())) {
        throw const OwnerConflictFailure();
      }
      if (!identical(repository, ref.read(ownerRepositoryProvider)) ||
          !repository.isMutationConfigured) {
        throw const OwnerNotConfiguredFailure();
      }
      dispatched = true;
      await action(repository, id).timeout(_limit);
      if (!_current(actor, generation)) {
        return false;
      }
      if (!await journal.finish(id)) {
        throw const OwnerStorageFailure();
      }
      if (!_current(actor, generation)) {
        return false;
      }
      _publish(operation: pending.operation, succeeded: true);
      _refresh(pending);
      return true;
    } catch (error) {
      final conflict = error is OwnerConflictFailure;
      final definitive =
          !dispatched ||
          error is OwnerPreSendFailure ||
          error is OwnerNotConfiguredFailure ||
          error is OwnerForbiddenFailure ||
          error is OwnerNoStallFailure ||
          error is OwnerRejectedFailure ||
          error is OwnerConflictFailure;
      if (definitive &&
          saved &&
          pending != null &&
          (!dispatched || _current(actor, generation))) {
        if (!await journal.finish(pending.mutationId)) {
          if (_current(actor, generation)) {
            _publish(
              operation: pending.operation,
              error: const OwnerStorageFailure(),
            );
          }
          return false;
        }
      }
      if (_current(actor, generation)) {
        final storage = error is OwnerStorageFailure;
        _publish(
          operation: pending?.operation ?? operation,
          uncertain: !definitive && !storage,
          error: storage
              ? error
              : definitive
              ? (error is OwnerFailure ? error : const OwnerRejectedFailure())
              : const OwnerUnconfirmedFailure(),
        );
        if (pending != null &&
            (pending.kind == OwnerMutationKind.transitionOrder ||
                ((pending.kind == OwnerMutationKind.saveMenu ||
                        pending.kind == OwnerMutationKind.deleteMenu) &&
                    (!definitive || conflict)))) {
          _refresh(pending);
        }
      }
      return false;
    } finally {
      _finished(actor);
    }
  }

  Future<void> recover() async {
    if (!ref.mounted ||
        !_current(_actor, _generation) ||
        _inFlight.contains(_actor)) {
      return;
    }
    final actor = _actor;
    final generation = _generation;
    final persisted = ref.read(ownerMutationJournalProvider(actor));
    if (persisted.isLoading || persisted.hasError) {
      return;
    }
    final pending = persisted.asData?.value;
    if (pending == null) {
      return;
    }
    final repository = ref.read(ownerRepositoryProvider);
    final journal = ref.read(ownerMutationJournalProvider(actor).notifier);
    _inFlight.add(actor);
    _publish(busy: true, operation: pending.operation);
    try {
      final result = await repository
          .lookupMutation(mutationId: pending.mutationId)
          .timeout(_limit);
      if (!_current(actor, generation)) {
        return;
      }
      if (!pending.matches(result.request) ||
          result.outcome == OwnerMutationOutcome.pending) {
        throw const OwnerUnconfirmedFailure();
      }
      if (!await journal.finish(pending.mutationId)) {
        throw const OwnerStorageFailure();
      }
      if (!_current(actor, generation)) {
        return;
      }
      _reviewRevision++;
      _publish(
        operation: pending.operation,
        succeeded: result.outcome == OwnerMutationOutcome.applied,
        error: result.outcome == OwnerMutationOutcome.notApplied
            ? const OwnerConflictFailure()
            : null,
      );
      _refresh(pending);
    } catch (error) {
      if (_current(actor, generation)) {
        _publish(
          operation: pending.operation,
          uncertain: true,
          error: error is OwnerFailure
              ? error
              : const OwnerUnconfirmedFailure(),
        );
      }
    } finally {
      _finished(actor);
    }
  }

  Future<void> reloadJournal() async {
    if (!ref.mounted ||
        !_current(_actor, _generation) ||
        _inFlight.contains(_actor)) {
      return;
    }
    final actor = _actor;
    final generation = _generation;
    final journal = ref.read(ownerMutationJournalProvider(actor).notifier);
    _inFlight.add(actor);
    _publish(busy: true);
    try {
      await journal.reload();
      if (!_current(actor, generation)) {
        return;
      }
      final persisted = ref.read(ownerMutationJournalProvider(actor));
      if (!persisted.isLoading &&
          !persisted.hasError &&
          persisted.asData != null &&
          persisted.asData!.value == null) {
        _reviewRevision++;
        ref.invalidate(ownerStallProvider);
        ref.invalidate(ownerMenusProvider);
        ref.invalidate(ownerOrdersProvider);
        ref.invalidate(ownerOrderDetailProvider);
      }
      _publish();
    } finally {
      _finished(actor);
    }
  }

  void _refresh(PendingOwnerMutation pending) {
    ref.read(sharedDataRevisionProvider.notifier).bump();
    switch (pending.kind) {
      case OwnerMutationKind.saveMenu:
      case OwnerMutationKind.deleteMenu:
        ref.invalidate(ownerMenusProvider);
      case OwnerMutationKind.saveStall:
        ref.invalidate(ownerStallProvider);
      case OwnerMutationKind.transitionOrder:
        ref.invalidate(ownerOrdersProvider);
        ref.invalidate(ownerOrderDetailProvider(pending.targetId!));
    }
  }

  void _finished(String actor) {
    _inFlight.remove(actor);
    if (ref.mounted && actor == _actor && state.busy) {
      _publish();
    }
  }
}
