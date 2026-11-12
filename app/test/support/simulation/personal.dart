part of 'simulation.dart';

class SimulationApplicationRepository implements CanteenApplicationRepository {
  SimulationApplicationRepository(this.store);
  final SimulationStore store;
  @override
  bool get isSubmissionConfigured => true;
  CanteenApplication? latest(String id) {
    final items = store
        .table('applications')
        .values
        .map((e) => unpackCanteenApplication(asJson(e)))
        .where((a) => a.applicantId == id)
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items.isEmpty ? null : items.first;
  }

  @override
  Future<CanteenApplication?> getMyApplication() async {
    final actor = await store.begin(UserRole.customer);
    store.readGuard();
    return latest(actor.$1);
  }

  @override
  Future<CanteenApplication> submit(
    PendingCanteenApplication submission,
  ) async {
    final actor = await store.begin(UserRole.customer);
    final result = await store.mutate(
      actor: actor,
      operation: 'application',
      id: submission.submissionId,
      payload: packPendingCanteenApplication(submission),
      conflict: const CanteenApplicationConflictFailure(),
      apply: () {
        if (submission.customerId != actor.$1 ||
            store.require().role != UserRole.customer) {
          throw const CanteenApplicationForbiddenFailure();
        }
        if (!submission.matchesPrevious(latest(actor.$1))) {
          throw const CanteenApplicationConflictFailure();
        }
        final draft = submission.draft;
        final application = CanteenApplication(
          id: store.nextId('application'),
          applicantId: actor.$1,
          name: draft.name,
          description: draft.description,
          location: draft.location,
          phone: draft.phone,
          status: CanteenApplicationStatus.submitted,
          createdAt: DateTime.now().toUtc(),
          version: 1,
        );
        store.table('applications')[application.id] = packCanteenApplication(
          application,
        );
        return {'record': packCanteenApplication(application)};
      },
    );
    return unpackCanteenApplication(asJson(result['record']));
  }

  @override
  Future<CanteenApplicationLookup> lookupSubmission({
    required String submissionId,
  }) async {
    final result = await store.lookup(
      'application',
      submissionId,
      UserRole.customer,
    );
    final record = result?['record'];
    return CanteenApplicationLookup(
      customerId: store.require().id,
      submissionId: submissionId,
      status: record != null
          ? CanteenApplicationSubmissionStatus.submitted
          : result?['sealed'] == true
          ? CanteenApplicationSubmissionStatus.notSubmitted
          : CanteenApplicationSubmissionStatus.pending,
      receipt: record == null ? null : unpackCanteenApplication(asJson(record)),
    );
  }
}

class SimulationPreferencesRepository implements FoodPreferencesRepository {
  SimulationPreferencesRepository(this.store);
  final SimulationStore store;
  @override
  bool get isSaveConfigured => true;
  @override
  Future<FoodPreferencesSnapshot?> getMyPreferences() async {
    final actor = await store.begin(UserRole.customer);
    store.readGuard();
    final value = store.table('preferences')[actor.$1];
    return value == null ? null : unpackFoodPreferencesSnapshot(asJson(value));
  }

  @override
  Future<FoodPreferencesSnapshot> saveMyPreferences(
    FoodPreferencesUpdate update, {
    required String mutationId,
  }) async {
    final actor = await store.begin(UserRole.customer);
    final request = PendingFoodPreferences(
      customerId: actor.$1,
      mutationId: mutationId,
      update: update,
    );
    final result = await store.mutate(
      actor: actor,
      operation: 'preferences',
      id: mutationId,
      payload: packPendingFoodPreferences(request),
      conflict: const FoodPreferencesConflictFailure(),
      apply: () {
        final value = store.table('preferences')[actor.$1];
        final old = value == null
            ? null
            : unpackFoodPreferencesSnapshot(asJson(value));
        if (old?.version != update.expectedVersion) {
          throw const FoodPreferencesConflictFailure();
        }
        final snapshot = FoodPreferencesSnapshot(
          customerId: actor.$1,
          version: (old?.version ?? 0) + 1,
          preferences: update.preferences,
        );
        store.table('preferences')[actor.$1] = packFoodPreferencesSnapshot(
          snapshot,
        );
        return {
          'record': packFoodPreferencesSnapshot(snapshot),
          'receipt': packFoodPreferencesLookup(
            FoodPreferencesLookup(
              request: request,
              outcome: FoodPreferencesOutcome.applied,
              snapshot: snapshot,
            ),
          ),
        };
      },
    );
    return unpackFoodPreferencesSnapshot(asJson(result['record']));
  }

  @override
  Future<FoodPreferencesLookup> lookupSave({required String mutationId}) async {
    final result = await store.lookup(
      'preferences',
      mutationId,
      UserRole.customer,
    );
    final receipt = result?['receipt'];
    if (receipt != null) {
      return unpackFoodPreferencesLookup(asJson(receipt));
    }
    final request = await SimulationFoodPreferencesJournal(
      SimulationKeyValueStorage(store),
    ).read(store.require().id);
    if (request == null || request.mutationId != mutationId) {
      throw const FormatException('Penanda tidak ditemukan.');
    }
    return FoodPreferencesLookup(
      request: request,
      outcome: result?['sealed'] == true
          ? FoodPreferencesOutcome.notApplied
          : FoodPreferencesOutcome.pending,
    );
  }
}
