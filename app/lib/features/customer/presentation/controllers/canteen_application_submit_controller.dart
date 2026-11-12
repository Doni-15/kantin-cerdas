import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/session/shared_data_revision_provider.dart';
import 'package:kantin_cerdas/core/utils/mutation_id_generator.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/pending_canteen_application.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/canteen_application_failure.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/canteen_application_journal_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_feature_providers.dart';

class ApplicationSubmitState {
  const ApplicationSubmitState({
    this.busy = false,
    this.needsRefresh = false,
    this.succeeded = false,
    this.error,
  });
  final bool busy;
  final bool needsRefresh;
  final bool succeeded;
  final Object? error;
}

final canteenApplicationSubmitProvider =
    NotifierProvider<
      CanteenApplicationSubmitController,
      ApplicationSubmitState
    >(CanteenApplicationSubmitController.new, retry: (_, _) => null);

class CanteenApplicationSubmitController
    extends Notifier<ApplicationSubmitState> {
  final Set<String> _inFlight = {};
  String? _customerId;
  int _generation = 0;
  AuthStateNotifier? _session;
  int _sessionGeneration = -1;
  static const _requestLimit = Duration(seconds: 30);

  @override
  ApplicationSubmitState build() {
    _generation++;
    _session = ref.read(authStateProvider.notifier);
    _sessionGeneration = _session!.sessionGeneration;
    _customerId = ref.read(authStateProvider).activeCustomerId;
    ref.listen<AsyncValue<User?>>(authStateProvider, (_, next) {
      if (!ref.mounted) {
        return;
      }
      final id = next.activeCustomerId;
      final session = ref.read(authStateProvider.notifier);
      if (id == _customerId &&
          identical(session, _session) &&
          session.sessionGeneration == _sessionGeneration) {
        return;
      }
      _generation++;
      _session = session;
      _sessionGeneration = session.sessionGeneration;
      _customerId = id;
      state = ApplicationSubmitState(
        busy: id != null && _inFlight.contains(id),
      );
    });
    return ApplicationSubmitState(busy: _inFlight.contains(_customerId));
  }

  Future<bool> submit(
    CanteenApplicationDraft draft, {
    required CanteenApplication? expectedPrevious,
  }) async {
    if (!ref.mounted) {
      return false;
    }
    if (ref.read(authStateProvider).asData?.value?.role != UserRole.customer) {
      return false;
    }
    final actor = ref.read(authStateProvider).activeCustomerId;
    if (actor == null ||
        actor != _customerId ||
        _inFlight.contains(actor) ||
        state.needsRefresh) {
      return false;
    }
    final generation = _generation;
    final repository = ref.read(canteenApplicationRepositoryProvider);
    if (!repository.isSubmissionConfigured) {
      _failure(
        actor,
        generation,
        const CanteenApplicationNotConfiguredFailure(),
      );
      return false;
    }
    final persisted = ref.read(canteenApplicationJournalProvider(actor));
    if (persisted.isLoading ||
        persisted.hasError ||
        persisted.asData == null ||
        persisted.asData!.value != null) {
      return false;
    }
    final loaded = ref.read(canteenApplicationProvider);
    if (loaded.isLoading || loaded.hasError || loaded.asData == null) {
      return false;
    }
    final previous = loaded.asData!.value;
    if ((previous?.id != expectedPrevious?.id) ||
        (previous?.version != expectedPrevious?.version) ||
        (previous != null &&
            (previous.applicantId != actor ||
                previous.status != CanteenApplicationStatus.rejected))) {
      _failure(actor, generation, const CanteenApplicationConflictFailure());
      return false;
    }
    final journal = ref.read(canteenApplicationJournalProvider(actor).notifier);
    _inFlight.add(actor);
    state = const ApplicationSubmitState(busy: true);
    PendingCanteenApplication? pending;
    var saved = false;
    var dispatched = false;
    try {
      final id = generateSecureMutationId();
      pending = PendingCanteenApplication(
        customerId: actor,
        submissionId: id,
        draft: draft,
        previousId: previous?.id,
        previousVersion: previous?.version,
      );
      saved = await journal.begin(pending);
      if (!saved) {
        _failure(actor, generation, const CanteenApplicationStorageFailure());
        return false;
      }
      if (!_current(actor, generation)) {
        await journal.finish(
          id,
        ); // Belum dispatch, aman membersihkan hanya ID ini.
        return false;
      }
      final latest = ref.read(canteenApplicationProvider);
      if (latest.isLoading ||
          latest.hasError ||
          latest.asData == null ||
          !pending.matchesPrevious(latest.asData!.value)) {
        throw const CanteenApplicationConflictFailure();
      }
      if (!identical(
            repository,
            ref.read(canteenApplicationRepositoryProvider),
          ) ||
          !repository.isSubmissionConfigured) {
        throw const CanteenApplicationPreSendFailure();
      }
      dispatched = true;
      final result = await repository.submit(pending).timeout(_requestLimit);
      if (!_current(actor, generation)) {
        return false;
      }
      if (!pending.acceptsResult(result)) {
        throw const CanteenApplicationUnconfirmedFailure();
      }
      if (!await journal.finish(id)) {
        _failure(actor, generation, const CanteenApplicationStorageFailure());
        return false;
      }
      if (!_current(actor, generation)) {
        return false;
      }
      state = const ApplicationSubmitState(succeeded: true);
      ref.read(sharedDataRevisionProvider.notifier).bump();
      ref.invalidate(canteenApplicationProvider);
      return true;
    } catch (error) {
      final definitive =
          !dispatched ||
          (error is CanteenApplicationFailure && error.definitelyNotSubmitted);
      if (definitive &&
          saved &&
          pending != null &&
          (!dispatched || _current(actor, generation))) {
        if (!await journal.finish(pending.submissionId)) {
          _failure(actor, generation, const CanteenApplicationStorageFailure());
          return false;
        }
      }
      _failure(
        actor,
        generation,
        definitive
            ? (error is CanteenApplicationFailure
                  ? error
                  : const CanteenApplicationPreSendFailure())
            : const CanteenApplicationUnconfirmedFailure(),
      );
      return false;
    } finally {
      _finished(actor);
    }
  }

  /// Lookup saja. Tidak ada retry submit, termasuk setelah proses app dimulai ulang.
  Future<void> recover() async {
    if (!ref.mounted) {
      return;
    }
    final actor = ref.read(authStateProvider).activeCustomerId;
    if (actor == null || actor != _customerId || _inFlight.contains(actor)) {
      return;
    }
    final persisted = ref.read(canteenApplicationJournalProvider(actor));
    if (persisted.isLoading || persisted.hasError) {
      return;
    }
    final pending = persisted.asData?.value;
    if (pending == null) {
      return;
    }
    final generation = _generation;
    final repository = ref.read(canteenApplicationRepositoryProvider);
    final journal = ref.read(canteenApplicationJournalProvider(actor).notifier);
    _inFlight.add(actor);
    state = const ApplicationSubmitState(busy: true);
    try {
      final result = await repository
          .lookupSubmission(submissionId: pending.submissionId)
          .timeout(_requestLimit);
      if (!_current(actor, generation)) {
        return;
      }
      if (result.customerId != actor ||
          result.submissionId != pending.submissionId ||
          result.status == CanteenApplicationSubmissionStatus.pending ||
          (result.status == CanteenApplicationSubmissionStatus.submitted &&
              (result.receipt == null ||
                  !pending.acceptsResult(result.receipt!)))) {
        throw const CanteenApplicationUnconfirmedFailure();
      }
      if (!await journal.finish(pending.submissionId)) {
        _failure(actor, generation, const CanteenApplicationStorageFailure());
        return;
      }
      if (!_current(actor, generation)) {
        return;
      }
      final submitted =
          result.status == CanteenApplicationSubmissionStatus.submitted;
      state = ApplicationSubmitState(
        succeeded: submitted,
        needsRefresh: !submitted,
      );
      // Status terkini dibaca terpisah; receipt lama tidak menimpa review admin.
      if (submitted) {
        ref.read(sharedDataRevisionProvider.notifier).bump();
        ref.invalidate(canteenApplicationProvider);
      }
    } catch (error) {
      // Error lookup apa pun tidak membuktikan submit sebelumnya gagal.
      _failure(
        actor,
        generation,
        error is CanteenApplicationFailure
            ? error
            : const CanteenApplicationUnconfirmedFailure(),
      );
    } finally {
      _finished(actor);
    }
  }

  /// UI mengonfirmasi pembuangan isian sebelum memanggil ini.
  Future<void> reloadApplication() async {
    if (!ref.mounted) {
      return;
    }
    final actor = ref.read(authStateProvider).activeCustomerId;
    if (actor == null || actor != _customerId || _inFlight.contains(actor)) {
      return;
    }
    final persisted = ref.read(canteenApplicationJournalProvider(actor));
    if (persisted.isLoading ||
        persisted.hasError ||
        persisted.asData == null ||
        persisted.asData!.value != null) {
      return;
    }
    final generation = _generation;
    _inFlight.add(actor);
    state = const ApplicationSubmitState(busy: true, needsRefresh: true);
    try {
      ref.invalidate(canteenApplicationProvider);
      await ref.read(canteenApplicationProvider.future);
      if (_current(actor, generation)) {
        state = const ApplicationSubmitState();
      }
    } catch (error) {
      if (_current(actor, generation)) {
        state = ApplicationSubmitState(needsRefresh: true, error: error);
      }
    } finally {
      _finished(actor);
    }
  }

  bool _current(String actor, int generation) =>
      ref.mounted &&
      _generation == generation &&
      actor == _customerId &&
      actor == ref.read(authStateProvider).activeCustomerId &&
      identical(_session, ref.read(authStateProvider.notifier)) &&
      ref.read(authStateProvider.notifier).sessionGeneration ==
          _sessionGeneration;

  void _failure(
    String actor,
    int generation,
    CanteenApplicationFailure failure,
  ) {
    if (_current(actor, generation)) {
      state = ApplicationSubmitState(
        error: failure,
        needsRefresh:
            failure is CanteenApplicationConflictFailure ||
            failure is CanteenApplicationStorageFailure,
      );
    }
  }

  void _finished(String actor) {
    _inFlight.remove(actor);
    if (ref.mounted && actor == _customerId && state.busy) {
      state = const ApplicationSubmitState();
    }
  }
}
