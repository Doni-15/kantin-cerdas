/// Pasangan kursor paginasi keyset (`created_at`, `id`) yang sudah didekode.
final class ValidatedKeysetCursor {
  final String cursorTsIso;
  final String cursorId;

  const ValidatedKeysetCursor({
    required this.cursorTsIso,
    required this.cursorId,
  });
}

/// Input tervalidasi untuk `GET /v1/admin/users`.
final class ValidatedListAdminUsersInput {
  final String search;
  final ValidatedKeysetCursor? cursor;
  final int limit;

  const ValidatedListAdminUsersInput({
    required this.search,
    required this.cursor,
    required this.limit,
  });
}

/// Input tervalidasi untuk `POST /v1/admin/users/<userId>/access`.
final class ValidatedSetUserAccessInput {
  final String mutationId;
  final String targetUserId;
  final int expectedVersion;
  final bool isActive;
  final String reason;

  const ValidatedSetUserAccessInput({
    required this.mutationId,
    required this.targetUserId,
    required this.expectedVersion,
    required this.isActive,
    required this.reason,
  });
}

/// Input tervalidasi untuk `GET /v1/admin/applications`.
final class ValidatedListAdminApplicationsInput {
  final String? status;
  final ValidatedKeysetCursor? cursor;
  final int limit;

  const ValidatedListAdminApplicationsInput({
    required this.status,
    required this.cursor,
    required this.limit,
  });
}

/// Input tervalidasi untuk `POST /v1/admin/applications/<applicationId>/review`.
final class ValidatedReviewApplicationInput {
  final String mutationId;
  final String applicationId;
  final int expectedVersion;
  final String decision;
  final String? reason;

  const ValidatedReviewApplicationInput({
    required this.mutationId,
    required this.applicationId,
    required this.expectedVersion,
    required this.decision,
    required this.reason,
  });
}