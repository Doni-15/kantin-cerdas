import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kelas dasar generik untuk seluruh AsyncNotifier pengelola jurnal mutasi per akun.
abstract class MutationJournalControllerBase<TPending>
    extends AsyncNotifier<TPending?> {
  bool _writing = false;

  String get actorId;
  String pendingActorId(TPending pending);
  String pendingMutationId(TPending pending);

  Future<TPending?> readJournal(String actorId);
  Future<void> saveJournal(TPending pending);
  Future<bool> clearJournal(String actorId, String mutationId);

  @override
  Future<TPending?> build() => readJournal(actorId);

  Future<bool> begin(TPending pending) async {
    if (!ref.mounted ||
        _writing ||
        pendingActorId(pending) != actorId ||
        state.isLoading ||
        state.hasError ||
        state.asData == null ||
        state.asData!.value != null) {
      return false;
    }
    _writing = true;
    state = const AsyncLoading();
    try {
      await saveJournal(pending);
      if (!ref.mounted) {
        return false;
      }
      state = AsyncData(pending);
      return true;
    } catch (error, stack) {
      if (ref.mounted) {
        state = AsyncError(error, stack);
      }
      return false;
    } finally {
      _writing = false;
    }
  }

  Future<bool> finish(String mutationId) async {
    final current = state.asData?.value;
    if (!ref.mounted ||
        _writing ||
        state.isLoading ||
        state.hasError ||
        current == null ||
        pendingMutationId(current) != mutationId) {
      return false;
    }
    _writing = true;
    state = const AsyncLoading();
    try {
      final cleared = await clearJournal(actorId, mutationId);
      if (!cleared) {
        throw StateError('Penanda pengiriman telah berubah.');
      }
      if (!ref.mounted) {
        return false;
      }
      state = const AsyncData(null);
      return true;
    } catch (error, stack) {
      if (ref.mounted) {
        state = AsyncError(error, stack);
      }
      return false;
    } finally {
      _writing = false;
    }
  }

  Future<void> reload() async {
    if (!ref.mounted || _writing || state.isLoading) {
      return;
    }
    _writing = true;
    state = const AsyncLoading();
    try {
      final pending = await readJournal(actorId);
      if (ref.mounted) {
        state = AsyncData(pending);
      }
    } catch (error, stack) {
      if (ref.mounted) {
        state = AsyncError(error, stack);
      }
    } finally {
      _writing = false;
    }
  }
}
