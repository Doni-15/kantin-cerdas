part of 'simulation.dart';

class SimulationAdminRepository implements AdminRepository {
  SimulationAdminRepository(this.store);
  final SimulationStore store;
  @override
  bool get isMutationConfigured => true;
  AdminUserRecord userRecord(String id) => AdminUserRecord(
    user: unpackUser(asJson(store.table('users')[id])),
    version: store.table('userVersions')[id] as int,
  );
  @override
  Future<AdminUserRecord?> getUser({required String userId}) async {
    await store.begin(UserRole.admin);
    store.readGuard();
    return store.table('users').containsKey(userId) ? userRecord(userId) : null;
  }

  @override
  Future<AdminUserPage> listUsers({
    required String search,
    String? cursor,
    int limit = 30,
  }) async {
    await store.begin(UserRole.admin);
    store.readGuard();
    final items = store.empty
        ? <User>[]
        : store
              .table('users')
              .values
              .map((e) => unpackUser(asJson(e)))
              .where(
                (u) => '${u.name} ${u.email} ${u.username}'
                    .toLowerCase()
                    .contains(search.toLowerCase()),
              )
              .toList();
    items.sort((a, b) => a.id.compareTo(b.id));
    final page = store.page(items, 'users:$search', cursor, limit);
    return AdminUserPage(users: page.$1, nextCursor: page.$2);
  }

  @override
  Future<AdminSummary> getSummary() async {
    await store.begin(UserRole.admin);
    store.readGuard();
    return AdminSummary(
      users: store.table('users').length,
      stalls: store.table('stalls').length,
      openStalls: store
          .table('stalls')
          .values
          .where((e) => asJson(e)['isOpen'] == true)
          .length,
      pendingApplications: store
          .table('applications')
          .values
          .map((e) => unpackCanteenApplication(asJson(e)))
          .where((a) => a.status.canBeReviewed)
          .length,
      activeOrders: store
          .table('orders')
          .values
          .map((e) => unpackOrderRecord(asJson(e)))
          .where((o) => !o.status.isTerminal)
          .length,
    );
  }

  @override
  Future<AdminApplicationPage> listApplications({
    CanteenApplicationStatus? status,
    String? cursor,
    int limit = 30,
  }) async {
    await store.begin(UserRole.admin);
    store.readGuard();
    final items = store.empty
        ? <CanteenApplication>[]
        : store
              .table('applications')
              .values
              .map((e) => unpackCanteenApplication(asJson(e)))
              .where((a) => status == null || a.status == status)
              .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final page = store.page(items, 'applications:$status', cursor, limit);
    return AdminApplicationPage(items: page.$1, nextCursor: page.$2);
  }

  @override
  Future<CanteenApplication?> getApplication({
    required String applicationId,
  }) async {
    await store.begin(UserRole.admin);
    store.readGuard();
    final value = store.table('applications')[applicationId];
    return value == null ? null : unpackCanteenApplication(asJson(value));
  }

  @override
  Future<CanteenApplication> reviewApplication(
    AdminApplicationReview review, {
    required String mutationId,
  }) async {
    final actor = await store.begin(UserRole.admin);
    final value = store.table('applications')[review.applicationId];
    if (value == null) {
      throw const AdminReviewRejectedFailure();
    }
    final old = unpackCanteenApplication(asJson(value));
    final pending = PendingAdminMutation(
      adminId: actor.$1,
      mutationId: mutationId,
      kind: AdminMutationKind.reviewApplication,
      targetId: old.id,
      expectedVersion: review.expectedVersion,
      decision: review.status,
      applicantId: old.applicantId,
      reason: review.reason ?? '',
    );
    final result = await store.mutate(
      actor: actor,
      role: UserRole.admin,
      operation: 'admin',
      id: mutationId,
      payload: packPendingAdminMutation(pending),
      conflict: const AdminReviewConflictFailure(),
      apply: () {
        final before = unpackCanteenApplication(
          asJson(store.table('applications')[review.applicationId]),
        );
        if (!review.canApplyTo(before)) {
          throw const AdminReviewConflictFailure();
        }
        String? stallId;
        if (review.status == CanteenApplicationStatus.approved) {
          final applicant = userRecord(before.applicantId);
          if (!applicant.user.isActive ||
              applicant.user.role != UserRole.customer ||
              store
                  .table('stalls')
                  .values
                  .any((e) => asJson(e)['ownerId'] == before.applicantId)) {
            throw const AdminReviewRejectedFailure();
          }
          stallId = store.nextId('stall');
          store.table('stalls')[stallId] = packOwnerStall(
            OwnerStall(
              id: stallId,
              ownerId: before.applicantId,
              name: before.name,
              block: before.location,
              description: before.description,
              isOpen: false,
              prepTimeMin: 15,
              version: 1,
            ),
          );
          store.table('users')[before.applicantId] = {
            ...packUser(applicant.user),
            'role': 'owner',
          };
          store.table('userVersions')[before.applicantId] =
              applicant.version + 1;
        }
        final after = unpackCanteenApplication({
          ...packCanteenApplication(before),
          'status': review.status.name,
          'reason': review.reason,
          'version': before.version + 1,
        });
        store.table('applications')[after.id] = packCanteenApplication(after);
        return {
          'record': packCanteenApplication(after),
          'receipt': packAdminMutationLookup(
            AdminMutationLookup(
              request: pending,
              outcome: AdminMutationOutcome.applied,
              resultVersion: after.version,
              decision: review.status,
              resultRole: stallId == null ? null : UserRole.owner,
              approvedStallId: stallId,
            ),
          ),
        };
      },
    );
    return unpackCanteenApplication(asJson(result['record']));
  }

  @override
  Future<AdminUserRecord> setUserAccess(
    AdminUserAccessChange change, {
    required String mutationId,
  }) async {
    final actor = await store.begin(UserRole.admin);
    final before = userRecord(change.userId);
    final pending = PendingAdminMutation(
      adminId: actor.$1,
      mutationId: mutationId,
      kind: AdminMutationKind.changeAccess,
      targetId: change.userId,
      expectedVersion: change.expectedVersion,
      isActive: change.isActive,
      targetRole: before.user.role,
      reason: change.reason,
    );
    final result = await store.mutate(
      actor: actor,
      role: UserRole.admin,
      operation: 'admin',
      id: mutationId,
      payload: packPendingAdminMutation(pending),
      conflict: const AdminUserAccessConflictFailure(),
      apply: () {
        final current = userRecord(change.userId);
        if (!change.canApplyTo(current, actorId: actor.$1)) {
          throw const AdminUserAccessRejectedFailure();
        }
        final user = unpackUser({
          ...packUser(current.user),
          'isActive': change.isActive,
        });
        final record = AdminUserRecord(
          user: user,
          version: current.version + 1,
        );
        store.table('users')[user.id] = packUser(user);
        store.table('userVersions')[user.id] = record.version;
        return {
          'record': packAdminUserRecord(record),
          'receipt': packAdminMutationLookup(
            AdminMutationLookup(
              request: pending,
              outcome: AdminMutationOutcome.applied,
              resultVersion: record.version,
              isActive: user.isActive,
              resultRole: user.role,
            ),
          ),
        };
      },
    );
    return unpackAdminUserRecord(asJson(result['record']));
  }

  @override
  Future<AdminMutationLookup> lookupMutation({
    required String mutationId,
  }) async {
    final result = await store.lookup('admin', mutationId, UserRole.admin);
    final receipt = result?['receipt'];
    if (receipt != null) {
      return unpackAdminMutationLookup(asJson(receipt));
    }
    final request = await SimulationAdminMutationJournal(
      SimulationKeyValueStorage(store),
    ).read(store.require().id);
    if (request == null || request.mutationId != mutationId) {
      throw const FormatException('Penanda tidak ditemukan.');
    }
    return AdminMutationLookup(
      request: request,
      outcome: result?['sealed'] == true
          ? AdminMutationOutcome.notApplied
          : AdminMutationOutcome.pending,
    );
  }
}
