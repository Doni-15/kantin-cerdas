import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/session/shared_data_revision_provider.dart';
import 'package:kantin_cerdas/core/utils/mutation_id_generator.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_application_review.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_user_access_change.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/pending_admin_mutation.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_mutation_lookup.dart';
import 'package:kantin_cerdas/features/admin/domain/failures/admin_failure.dart';
import 'package:kantin_cerdas/features/admin/domain/repositories/admin_repository.dart';
import 'package:kantin_cerdas/features/admin/presentation/providers/admin_providers.dart';
import 'package:kantin_cerdas/features/admin/presentation/providers/admin_application_providers.dart';
import 'package:kantin_cerdas/features/admin/presentation/providers/admin_user_detail_provider.dart';
import 'package:kantin_cerdas/features/admin/presentation/providers/admin_mutation_journal_provider.dart';

class AdminMutationState {
  const AdminMutationState({
    this.request,
    this.busy = false,
    this.unresolved = false,
    this.succeeded = false,
    this.reconciled = false,
    this.error,
    this.journalLoading = false,
    this.journalError,
    this.configured = true,
    this.revision = 0,
  });
  final PendingAdminMutation? request;
  final bool busy;
  final bool unresolved;
  final bool succeeded;
  final bool reconciled;
  final AdminFailure? error;
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
}

final adminMutationControllerProvider =
    NotifierProvider<AdminMutationController, AdminMutationState>(
      AdminMutationController.new,
      retry: (_, _) => null,
    );

final adminMutationProvider = Provider<AdminMutationState>((ref) {
  final adminId = ref.watch(authStateProvider).activeAdminId;
  if (adminId == null) {
    return const AdminMutationState(configured: false);
  }
  final action = ref.watch(adminMutationControllerProvider);
  final journal = ref.watch(adminMutationJournalProvider(adminId));
  final pending = journal.asData?.value;
  return AdminMutationState(
    request: pending ?? action.request,
    busy: action.busy,
    unresolved: pending != null || action.unresolved,
    succeeded: action.succeeded,
    reconciled: action.reconciled,
    error: action.error,
    revision: action.revision,
    journalLoading:
        journal.isLoading || (!journal.hasError && journal.asData == null),
    journalError: journal.error,
    configured: ref.watch(adminRepositoryProvider).isMutationConfigured,
  );
});

/// Satu pengiriman admin per akun, lintas keputusan pengajuan dan akses pengguna.
class AdminMutationController extends Notifier<AdminMutationState> {
  String _actor = '';
  int _generation = 0;
  int _revision = 0;
  AuthStateNotifier? _session;
  int _sessionGeneration = -1;
  final Set<String> _inFlight = {};
  static const _limit = Duration(seconds: 30);
  @override
  AdminMutationState build() {
    _generation++;
    _revision++;
    _actor = ref.watch(authStateProvider).activeAdminId ?? '';
    _session = ref.watch(authStateProvider.notifier);
    _sessionGeneration = _session!.sessionGeneration;
    return AdminMutationState(
      busy: _inFlight.contains(_actor),
      revision: _revision,
    );
  }

  bool _current(String actor, int generation) {
    if (!ref.mounted ||
        actor.isEmpty ||
        actor != _actor ||
        generation != _generation) {
      return false;
    }
    final auth = ref.read(authStateProvider);
    final session = ref.read(authStateProvider.notifier);
    return auth.activeAdminId == actor &&
        identical(session, _session) &&
        session.sessionGeneration == _sessionGeneration;
  }

  void _publish({
    PendingAdminMutation? request,
    bool busy = false,
    bool unresolved = false,
    bool succeeded = false,
    bool reconciled = false,
    AdminFailure? error,
  }) {
    state = AdminMutationState(
      request: request,
      busy: busy,
      unresolved: unresolved,
      succeeded: succeeded,
      reconciled: reconciled,
      error: error,
      revision: _revision,
    );
  }

  AdminFailure _unknown(AdminMutationKind kind) =>
      kind == AdminMutationKind.reviewApplication
      ? const AdminReviewUnknownFailure()
      : const AdminUserAccessUnknownFailure();
  AdminFailure _conflict(AdminMutationKind kind) =>
      kind == AdminMutationKind.reviewApplication
      ? const AdminReviewConflictFailure()
      : const AdminUserAccessConflictFailure();

  Future<void> review(AdminApplicationReview input) async {
    if (!ref.mounted ||
        !_current(_actor, _generation) ||
        ref.read(adminMutationProvider).blocked) {
      return;
    }
    final loaded = ref.read(
      adminApplicationDetailProvider(input.applicationId),
    );
    final before = loaded.asData?.value;
    if (loaded.isLoading ||
        loaded.hasError ||
        before == null ||
        !input.canApplyTo(before)) {
      ref.invalidate(adminApplicationDetailProvider(input.applicationId));
      return;
    }
    final actor = _actor;
    await _perform(
      kind: AdminMutationKind.reviewApplication,
      create: (id) => PendingAdminMutation(
        adminId: actor,
        mutationId: id,
        kind: AdminMutationKind.reviewApplication,
        targetId: input.applicationId,
        expectedVersion: input.expectedVersion,
        decision: input.status,
        applicantId: before.applicantId,
        reason: input.reason ?? '',
      ),
      preflight: () {
        final latest = ref.read(
          adminApplicationDetailProvider(input.applicationId),
        );
        return !latest.isLoading &&
            !latest.hasError &&
            latest.asData?.value == before;
      },
      action: (repository, id) async {
        final after = await repository.reviewApplication(input, mutationId: id);
        if (!input.acceptsResult(before: before, after: after)) {
          throw const AdminReviewUnknownFailure();
        }
      },
    );
  }

  Future<void> changeAccess(AdminUserAccessChange input) async {
    if (!ref.mounted ||
        !_current(_actor, _generation) ||
        ref.read(adminMutationProvider).blocked) {
      return;
    }
    final actor = _actor;
    final loaded = ref.read(adminUserDetailProvider(input.userId));
    final before = loaded.asData?.value;
    if (loaded.isLoading ||
        loaded.hasError ||
        before == null ||
        !input.canApplyTo(before, actorId: actor)) {
      ref.invalidate(adminUserDetailProvider(input.userId));
      return;
    }
    await _perform(
      kind: AdminMutationKind.changeAccess,
      create: (id) => PendingAdminMutation(
        adminId: actor,
        mutationId: id,
        kind: AdminMutationKind.changeAccess,
        targetId: input.userId,
        expectedVersion: input.expectedVersion,
        isActive: input.isActive,
        targetRole: before.user.role,
        reason: input.reason,
      ),
      preflight: () {
        final latest = ref.read(adminUserDetailProvider(input.userId));
        return !latest.isLoading &&
            !latest.hasError &&
            latest.asData?.value == before;
      },
      action: (repository, id) async {
        final after = await repository.setUserAccess(input, mutationId: id);
        if (!input.acceptsResult(
          before: before,
          after: after,
          actorId: actor,
        )) {
          throw const AdminUserAccessUnknownFailure();
        }
      },
    );
  }

  Future<void> _perform({
    required AdminMutationKind kind,
    required PendingAdminMutation Function(String) create,
    required bool Function() preflight,
    required Future<void> Function(AdminRepository, String) action,
  }) async {
    if (!_current(_actor, _generation) ||
        _inFlight.contains(_actor) ||
        ref.read(adminMutationProvider).blocked) {
      return;
    }
    final actor = _actor;
    final generation = _generation;
    final repository = ref.read(adminRepositoryProvider);
    final journal = ref.read(adminMutationJournalProvider(actor).notifier);
    _inFlight.add(actor);
    _publish(busy: true);
    PendingAdminMutation? pending;
    var saved = false;
    var dispatched = false;
    try {
      final id = generateSecureMutationId();
      pending = create(id);
      if (!preflight()) {
        throw _conflict(kind);
      }
      _publish(busy: true, request: pending);
      saved = await journal.begin(pending);
      if (!saved) {
        throw const AdminMutationStorageFailure();
      }
      if (!_current(actor, generation)) {
        await journal.finish(id); // Belum dispatch; bersihkan hanya ID ini.
        return;
      }
      if (!preflight()) {
        throw _conflict(kind);
      }
      if (!identical(repository, ref.read(adminRepositoryProvider)) ||
          !repository.isMutationConfigured) {
        throw const AdminNotConfiguredFailure();
      }
      dispatched = true;
      await action(repository, id).timeout(_limit);
      if (!_current(actor, generation)) {
        return;
      }
      if (!await journal.finish(id)) {
        throw const AdminMutationStorageFailure();
      }
      if (!_current(actor, generation)) {
        return;
      }
      _publish(request: pending, succeeded: true);
      _refresh(pending);
    } catch (error) {
      final definitive =
          !dispatched ||
          error is AdminMutationPreSendFailure ||
          error is AdminNotConfiguredFailure ||
          error is AdminAccessFailure ||
          error is AdminReviewRejectedFailure ||
          error is AdminReviewConflictFailure ||
          error is AdminUserAccessRejectedFailure ||
          error is AdminUserAccessConflictFailure;
      if (definitive &&
          saved &&
          pending != null &&
          (!dispatched || _current(actor, generation))) {
        if (!await journal.finish(pending.mutationId)) {
          if (_current(actor, generation)) {
            _publish(
              request: pending,
              error: const AdminMutationStorageFailure(),
            );
          }
          return;
        }
      }
      if (_current(actor, generation)) {
        final storage = error is AdminMutationStorageFailure;
        _publish(
          request: pending,
          unresolved: !definitive && !storage,
          error: storage
              ? error
              : definitive
              ? (error is AdminFailure
                    ? error
                    : const AdminMutationPreSendFailure())
              : _unknown(kind),
        );
        if (pending != null &&
            (!definitive ||
                error is AdminReviewConflictFailure ||
                error is AdminUserAccessConflictFailure ||
                error is AdminAccessFailure)) {
          _refresh(pending);
        }
      }
    } finally {
      _finished(actor);
    }
  }

  Future<void> recover() async {
    if (!_current(_actor, _generation) || _inFlight.contains(_actor)) {
      return;
    }
    final actor = _actor;
    final generation = _generation;
    final persisted = ref.read(adminMutationJournalProvider(actor));
    if (persisted.isLoading || persisted.hasError) {
      return;
    }
    final pending = persisted.asData?.value;
    if (pending == null) {
      return;
    }
    final repository = ref.read(adminRepositoryProvider);
    final journal = ref.read(adminMutationJournalProvider(actor).notifier);
    _inFlight.add(actor);
    _publish(request: pending, busy: true);
    try {
      final result = await repository
          .lookupMutation(mutationId: pending.mutationId)
          .timeout(_limit);
      if (!_current(actor, generation)) {
        return;
      }
      if (!pending.matches(result.request) ||
          result.outcome == AdminMutationOutcome.pending) {
        throw _unknown(pending.kind);
      }
      if (!await journal.finish(pending.mutationId)) {
        throw const AdminMutationStorageFailure();
      }
      if (!_current(actor, generation)) {
        return;
      }
      _revision++;
      _publish(
        request: pending,
        succeeded: result.outcome == AdminMutationOutcome.applied,
        reconciled: result.outcome == AdminMutationOutcome.notApplied,
      );
      _refresh(pending);
    } catch (error) {
      if (_current(actor, generation)) {
        _publish(
          request: pending,
          unresolved: true,
          error: error is AdminFailure ? error : _unknown(pending.kind),
        );
      }
    } finally {
      _finished(actor);
    }
  }

  Future<void> reloadJournal() async {
    if (!_current(_actor, _generation) || _inFlight.contains(_actor)) {
      return;
    }
    final actor = _actor;
    final generation = _generation;
    final journal = ref.read(adminMutationJournalProvider(actor).notifier);
    _inFlight.add(actor);
    _publish(busy: true);
    try {
      await journal.reload();
      if (!_current(actor, generation)) {
        return;
      }
      final persisted = ref.read(adminMutationJournalProvider(actor));
      if (!persisted.isLoading &&
          !persisted.hasError &&
          persisted.asData != null &&
          persisted.asData!.value == null) {
        _revision++;
        ref.invalidate(adminApplicationDetailProvider);
        ref.invalidate(adminUserDetailProvider);
        ref.invalidate(adminApplicationsProvider);
        ref.invalidate(adminUsersProvider);
        ref.invalidate(adminSummaryProvider);
      }
      _publish();
    } finally {
      _finished(actor);
    }
  }

  void _refresh(PendingAdminMutation pending) {
    ref.read(sharedDataRevisionProvider.notifier).bump();
    ref.invalidate(adminUsersProvider);
    ref.invalidate(adminSummaryProvider);
    if (pending.kind == AdminMutationKind.reviewApplication) {
      ref.invalidate(adminApplicationsProvider);
      ref.invalidate(adminApplicationDetailProvider(pending.targetId));
      ref.invalidate(adminUserDetailProvider(pending.applicantId!));
    } else {
      ref.invalidate(adminUserDetailProvider(pending.targetId));
    }
  }

  void _finished(String actor) {
    _inFlight.remove(actor);
    if (ref.mounted && _actor == actor && state.busy) {
      _publish();
    }
  }
}
