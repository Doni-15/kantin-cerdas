import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/utils/mutation_id_generator.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences_snapshot.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/food_preferences_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/pending_food_preferences.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/food_preferences_failure.dart';
import 'package:kantin_cerdas/features/customer/presentation/controllers/food_preferences_save_state.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/food_preferences_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/food_preferences_journal_provider.dart';

final foodPreferencesControllerProvider =
    NotifierProvider<FoodPreferencesController, FoodPreferencesSaveState>(
      FoodPreferencesController.new,
      retry: (_, _) => null,
    );

/// View menggabungkan journal tanpa membangun ulang controller ketika storage berubah.
final foodPreferencesSaveProvider = Provider<FoodPreferencesSaveState>((ref) {
  final customerId = ref.watch(authStateProvider).activeCustomerId;
  if (customerId == null) {
    return const FoodPreferencesSaveState(configured: false);
  }
  final action = ref.watch(foodPreferencesControllerProvider);
  final journal = ref.watch(foodPreferencesJournalProvider(customerId));
  return FoodPreferencesSaveState(
    busy: action.busy,
    pending: journal.asData?.value,
    error: action.error,
    saved: action.saved,
    reconciled: action.reconciled,
    needsRefresh: action.needsRefresh,
    revision: action.revision,
    journalLoading:
        journal.isLoading || (!journal.hasError && journal.asData == null),
    journalError: journal.error,
    configured: ref.watch(foodPreferencesRepositoryProvider).isSaveConfigured,
  );
});

class FoodPreferencesController extends Notifier<FoodPreferencesSaveState> {
  String _actor = '';
  int _epoch = 0;
  int _revision = 0;
  AuthStateNotifier? _session;
  int _sessionGeneration = -1;
  final Set<String> _inFlight = {};
  static const _limit = Duration(seconds: 30);
  @override
  FoodPreferencesSaveState build() {
    _epoch++;
    _revision++;
    _actor = ref.watch(authStateProvider).activeCustomerId ?? '';
    _session = ref.watch(authStateProvider.notifier);
    _sessionGeneration = _session!.sessionGeneration;
    return FoodPreferencesSaveState(
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
    bool busy = false,
    bool saved = false,
    bool reconciled = false,
    bool needsRefresh = false,
    FoodPreferencesFailure? error,
  }) {
    state = FoodPreferencesSaveState(
      busy: busy,
      saved: saved,
      reconciled: reconciled,
      needsRefresh: needsRefresh,
      error: error,
      revision: _revision,
    );
  }

  Future<void> save(
    FoodPreferencesUpdate input, {
    required int revision,
  }) async {
    if (!_current(_actor, _epoch) ||
        _inFlight.contains(_actor) ||
        ref.read(foodPreferencesSaveProvider).blocked ||
        revision != _revision) {
      return;
    }
    final actor = _actor;
    final epoch = _epoch;
    final loaded = ref.read(foodPreferencesProvider);
    final before = loaded.asData?.value;
    bool matchesBase() {
      final data = ref.read(foodPreferencesProvider);
      return !data.isLoading &&
          !data.hasError &&
          data.asData != null &&
          data.asData!.value == before &&
          before?.version == input.expectedVersion &&
          (before == null || before.customerId == actor);
    }

    if (!matchesBase()) {
      _publish(
        needsRefresh: true,
        error: const FoodPreferencesConflictFailure(),
      );
      return;
    }
    if (before != null && input.preferences.sameAs(before.preferences)) {
      return;
    }
    final repository = ref.read(foodPreferencesRepositoryProvider);
    final journal = ref.read(foodPreferencesJournalProvider(actor).notifier);
    _inFlight.add(actor);
    _publish(busy: true);
    PendingFoodPreferences? pending;
    var persisted = false;
    var dispatched = false;
    try {
      final id = generateSecureMutationId();
      pending = PendingFoodPreferences(
        customerId: actor,
        mutationId: id,
        update: input,
      );
      persisted = await journal.begin(pending);
      if (!persisted) {
        throw const FoodPreferencesStorageFailure();
      }
      if (!_current(actor, epoch)) {
        await journal.finish(id); // Belum dispatch; hanya bersihkan ID ini.
        return;
      }
      if (!matchesBase()) {
        throw const FoodPreferencesConflictFailure();
      }
      if (!identical(repository, ref.read(foodPreferencesRepositoryProvider)) ||
          !repository.isSaveConfigured) {
        throw const FoodPreferencesNotConfiguredFailure();
      }
      dispatched = true;
      final result = await repository
          .saveMyPreferences(input, mutationId: id)
          .timeout(_limit);
      if (!_current(actor, epoch)) {
        return;
      }
      if (!pending.accepts(result)) {
        throw const FoodPreferencesUnknownFailure();
      }
      if (!await journal.finish(id)) {
        throw const FoodPreferencesStorageFailure();
      }
      if (!_current(actor, epoch)) {
        return;
      }
      _revision++;
      _publish(saved: true);
      ref.invalidate(foodPreferencesProvider);
    } catch (error) {
      final failure = error is FoodPreferencesFailure
          ? error
          : (dispatched
                ? const FoodPreferencesUnknownFailure()
                : const FoodPreferencesPreSendFailure());
      final definitive =
          !dispatched ||
          switch (failure) {
            FoodPreferencesPreSendFailure() ||
            FoodPreferencesNotConfiguredFailure() ||
            FoodPreferencesForbiddenFailure() ||
            FoodPreferencesRejectedFailure() ||
            FoodPreferencesConflictFailure() => true,
            _ => false,
          };
      if (definitive &&
          persisted &&
          pending != null &&
          (!dispatched || _current(actor, epoch))) {
        if (!await journal.finish(pending.mutationId)) {
          if (_current(actor, epoch)) {
            _publish(error: const FoodPreferencesStorageFailure());
          }
          return;
        }
      }
      if (_current(actor, epoch)) {
        _publish(
          needsRefresh: failure is FoodPreferencesConflictFailure,
          error: definitive || failure is FoodPreferencesStorageFailure
              ? failure
              : const FoodPreferencesUnknownFailure(),
        );
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
    final data = ref.read(foodPreferencesJournalProvider(actor));
    if (data.isLoading || data.hasError) {
      return;
    }
    final pending = data.asData?.value;
    if (pending == null) {
      return;
    }
    final journal = ref.read(foodPreferencesJournalProvider(actor).notifier);
    final repository = ref.read(foodPreferencesRepositoryProvider);
    _inFlight.add(actor);
    _publish(busy: true);
    try {
      final result = await repository
          .lookupSave(mutationId: pending.mutationId)
          .timeout(_limit);
      if (!_current(actor, epoch)) {
        return;
      }
      if (!pending.matches(result.request) ||
          result.outcome == FoodPreferencesOutcome.pending) {
        throw const FoodPreferencesUnknownFailure();
      }
      if (!await journal.finish(pending.mutationId)) {
        throw const FoodPreferencesStorageFailure();
      }
      if (!_current(actor, epoch)) {
        return;
      }
      _revision++;
      _publish(
        saved: result.outcome == FoodPreferencesOutcome.applied,
        reconciled: result.outcome == FoodPreferencesOutcome.notApplied,
      );
      ref.invalidate(foodPreferencesProvider);
    } catch (error) {
      if (_current(actor, epoch)) {
        _publish(
          error: error is FoodPreferencesFailure
              ? error
              : const FoodPreferencesUnknownFailure(),
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
    final journal = ref.read(foodPreferencesJournalProvider(actor).notifier);
    _inFlight.add(actor);
    _publish(busy: true);
    try {
      await journal.reload();
      if (!_current(actor, epoch)) {
        return;
      }
      final value = ref.read(foodPreferencesJournalProvider(actor));
      if (!value.isLoading &&
          !value.hasError &&
          value.asData != null &&
          value.asData!.value == null) {
        // Pertahankan isian sampai pengguna menyetujui pemuatan data terbaru.
        _publish(needsRefresh: true);
      } else {
        _publish();
      }
    } finally {
      _finished(actor);
    }
  }

  /// UI sudah mengonfirmasi penggantian isian. Read tidak menghapus penanda pending.
  void refreshData() {
    if (!_current(_actor, _epoch) || _inFlight.contains(_actor)) {
      return;
    }
    final visible = ref.read(foodPreferencesSaveProvider);
    if (visible.pending != null ||
        visible.journalLoading ||
        visible.journalError != null) {
      ref.invalidate(foodPreferencesProvider);
      return;
    }
    _revision++;
    _publish();
    ref.invalidate(foodPreferencesProvider);
  }

  void clearNotice() {
    if (_current(_actor, _epoch) &&
        !ref.read(foodPreferencesSaveProvider).blocked) {
      _publish();
    }
  }

  void _finished(String actor) {
    _inFlight.remove(actor);
    if (ref.mounted && actor == _actor && state.busy) {
      _publish();
    }
  }
}
