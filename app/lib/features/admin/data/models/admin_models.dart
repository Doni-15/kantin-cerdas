import 'package:kantin_cerdas/core/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/session/user_role.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_application_page.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_mutation_lookup.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_summary.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_user_page.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/admin_user_record.dart';
import 'package:kantin_cerdas/features/admin/domain/entities/pending_admin_mutation.dart';
import 'package:kantin_cerdas/features/auth/data/mappers/user_mapper.dart';
import 'package:kantin_cerdas/features/auth/data/models/user_model.dart';
import 'package:kantin_cerdas/features/orders/data/models/canteen_application_model.dart';

class AdminSummaryModel {
  const AdminSummaryModel({
    required this.users,
    required this.stalls,
    required this.openStalls,
    required this.pendingApplications,
    required this.activeOrders,
  });

  factory AdminSummaryModel.fromJson(Map<String, Object?> json) {
    final users = json['users'];
    final stalls = json['stalls'];
    final openStalls = json['open_stalls'] ?? json['openStalls'];
    final pendingApps =
        json['pending_applications'] ?? json['pendingApplications'];
    final activeOrders = json['active_orders'] ?? json['activeOrders'];

    if (users is! int ||
        stalls is! int ||
        openStalls is! int ||
        pendingApps is! int ||
        activeOrders is! int) {
      throw const DataParsingException('Format ringkasan admin tidak valid.');
    }

    return AdminSummaryModel(
      users: users,
      stalls: stalls,
      openStalls: openStalls,
      pendingApplications: pendingApps,
      activeOrders: activeOrders,
    );
  }

  final int users;
  final int stalls;
  final int openStalls;
  final int pendingApplications;
  final int activeOrders;

  AdminSummary toEntity() {
    try {
      return AdminSummary(
        users: users,
        stalls: stalls,
        openStalls: openStalls,
        pendingApplications: pendingApplications,
        activeOrders: activeOrders,
      );
    } on ArgumentError catch (e) {
      throw DataParsingException(
        e.message?.toString() ?? 'Ringkasan admin tidak valid.',
      );
    }
  }
}

class AdminUserRecordModel {
  const AdminUserRecordModel({required this.user, required this.version});

  factory AdminUserRecordModel.fromJson(Map<String, Object?> json) {
    final rawUser = asJsonMap(json['user'], fieldName: 'user');
    final version = json['version'];
    if (version is! int) {
      throw const DataParsingException('Format record pengguna admin invalid.');
    }
    return AdminUserRecordModel(
      user: UserModel.fromJson(rawUser),
      version: version,
    );
  }

  final UserModel user;
  final int version;

  AdminUserRecord toEntity() {
    try {
      return AdminUserRecord(user: user.toEntity(), version: version);
    } on ArgumentError catch (e) {
      throw DataParsingException(
        e.message?.toString() ?? 'Record pengguna admin tidak valid.',
      );
    }
  }
}

class AdminUserPageModel {
  const AdminUserPageModel({required this.users, this.nextCursor});

  factory AdminUserPageModel.fromJson(Map<String, Object?> json) {
    final rawUsers = json['users'] ?? json['items'];
    final nextCursor = normalizeOptionalText(
      json['next_cursor'] ?? json['nextCursor'],
      fieldName: 'next_cursor',
    );
    if (rawUsers is! List<Object?>) {
      throw const DataParsingException('Format halaman pengguna invalid.');
    }
    final users = <UserModel>[];
    for (final raw in rawUsers) {
      users.add(UserModel.fromJson(asJsonMap(raw, fieldName: 'users')));
    }
    return AdminUserPageModel(users: users, nextCursor: nextCursor);
  }

  final List<UserModel> users;
  final String? nextCursor;

  AdminUserPage toEntity() {
    try {
      return AdminUserPage(
        users: users.map((u) => u.toEntity()).toList(growable: false),
        nextCursor: nextCursor,
      );
    } on ArgumentError catch (e) {
      throw DataParsingException(
        e.message?.toString() ?? 'Halaman pengguna tidak valid.',
      );
    }
  }
}

class AdminApplicationPageModel {
  const AdminApplicationPageModel({required this.items, this.nextCursor});

  factory AdminApplicationPageModel.fromJson(Map<String, Object?> json) {
    final rawItems = json['items'];
    final nextCursor = normalizeOptionalText(
      json['next_cursor'] ?? json['nextCursor'],
      fieldName: 'next_cursor',
    );
    if (rawItems is! List<Object?>) {
      throw const DataParsingException('Format halaman pengajuan invalid.');
    }
    final items = <CanteenApplicationModel>[];
    for (final raw in rawItems) {
      items.add(
        CanteenApplicationModel.fromJson(asJsonMap(raw, fieldName: 'items')),
      );
    }
    return AdminApplicationPageModel(items: items, nextCursor: nextCursor);
  }

  final List<CanteenApplicationModel> items;
  final String? nextCursor;

  AdminApplicationPage toEntity() {
    try {
      return AdminApplicationPage(
        items: items.map((a) => a.toEntity()).toList(growable: false),
        nextCursor: nextCursor,
      );
    } on ArgumentError catch (e) {
      throw DataParsingException(
        e.message?.toString() ?? 'Halaman pengajuan tidak valid.',
      );
    }
  }
}

class AdminMutationLookupModel {
  const AdminMutationLookupModel({
    required this.adminId,
    required this.mutationId,
    required this.kind,
    required this.targetId,
    required this.expectedVersion,
    required this.reason,
    required this.outcome,
    this.applicantId,
    this.isActive,
    this.decision,
    this.targetRole,
    this.resultVersion,
    this.resultDecision,
    this.resultIsActive,
    this.resultRole,
    this.approvedStallId,
  });

  factory AdminMutationLookupModel.fromJson(Map<String, Object?> json) {
    final req = tryAsJsonMap(json['request']) ?? json;
    final adminId =
        req['admin_id'] ??
        req['adminId'] ??
        req['actor_id'] ??
        req['actorId'] ??
        json['admin_id'] ??
        json['adminId'] ??
        json['actor_id'] ??
        json['actorId'];
    final mutationId =
        req['mutation_id'] ??
        req['mutationId'] ??
        json['mutation_id'] ??
        json['mutationId'];
    final kind = req['kind'] ?? json['kind'];
    final targetId = req['target_id'] ?? req['targetId'];
    final expectedVersion = req['expected_version'] ?? req['expectedVersion'];
    final reason = req['reason'] ?? '';
    final applicantId = normalizeOptionalText(
      req['applicant_id'] ?? req['applicantId'],
      fieldName: 'applicant_id',
    );
    final isActive = req['is_active'] ?? req['isActive'];
    final decision = normalizeOptionalText(
      req['decision'],
      fieldName: 'decision',
    );
    final targetRole = normalizeOptionalText(
      req['target_role'] ?? req['targetRole'],
      fieldName: 'target_role',
    );
    final outcome = json['outcome'] ?? json['status'];
    final resultVersion = json['result_version'] ?? json['resultVersion'];
    final resultDecision = normalizeOptionalText(
      json['result_decision'] ?? json['resultDecision'],
      fieldName: 'result_decision',
    );
    final resultIsActive = json['result_is_active'] ?? json['resultIsActive'];
    final resultRole = normalizeOptionalText(
      json['result_role'] ?? json['resultRole'],
      fieldName: 'result_role',
    );
    final approvedStallId = normalizeOptionalText(
      json['approved_stall_id'] ?? json['approvedStallId'],
      fieldName: 'approved_stall_id',
    );

    if (adminId is! String ||
        mutationId is! String ||
        kind is! String ||
        targetId is! String ||
        expectedVersion is! int ||
        reason is! String ||
        outcome is! String ||
        (isActive != null && isActive is! bool) ||
        (resultVersion != null && resultVersion is! int) ||
        (resultIsActive != null && resultIsActive is! bool)) {
      throw const DataParsingException('Format lookup mutasi admin invalid.');
    }

    return AdminMutationLookupModel(
      adminId: adminId,
      mutationId: mutationId,
      kind: kind,
      targetId: targetId,
      expectedVersion: expectedVersion,
      reason: reason,
      outcome: outcome,
      applicantId: applicantId,
      isActive: isActive as bool?,
      decision: decision,
      targetRole: targetRole,
      resultVersion: resultVersion as int?,
      resultDecision: resultDecision,
      resultIsActive: resultIsActive as bool?,
      resultRole: resultRole,
      approvedStallId: approvedStallId,
    );
  }

  final String adminId;
  final String mutationId;
  final String kind;
  final String targetId;
  final int expectedVersion;
  final String reason;
  final String outcome;
  final String? applicantId;
  final bool? isActive;
  final String? decision;
  final String? targetRole;
  final int? resultVersion;
  final String? resultDecision;
  final bool? resultIsActive;
  final String? resultRole;
  final String? approvedStallId;

  AdminMutationLookup toEntity() {
    final parsedKind = switch (kind.trim()) {
      'review_application' ||
      'reviewApplication' => AdminMutationKind.reviewApplication,
      'change_access' || 'changeAccess' => AdminMutationKind.changeAccess,
      _ => throw const DataParsingException('Jenis mutasi admin tidak valid.'),
    };
    CanteenApplicationStatus? parseDecision(String? raw) => raw == null
        ? null
        : (CanteenApplicationStatus.tryFromRaw(raw) ??
              (throw const DataParsingException(
                'Keputusan pengajuan admin tidak valid.',
              )));
    UserRole? parseRole(String? raw) => raw == null
        ? null
        : (UserRole.tryFromRaw(raw) ??
              (throw const DataParsingException(
                'Peran target admin tidak valid.',
              )));
    final parsedDecision = parseDecision(decision);
    final parsedRole = parseRole(targetRole);
    final parsedResultDecision = parseDecision(resultDecision);
    final parsedResultRole = parseRole(resultRole);
    final parsedOutcome = switch (outcome.trim().toLowerCase()) {
      'pending' => AdminMutationOutcome.pending,
      'applied' => AdminMutationOutcome.applied,
      'not_applied' || 'notapplied' => AdminMutationOutcome.notApplied,
      _ => throw const DataParsingException(
        'Outcome lookup mutasi admin tidak dikenali.',
      ),
    };

    try {
      return AdminMutationLookup(
        request: PendingAdminMutation(
          adminId: adminId,
          mutationId: mutationId,
          kind: parsedKind,
          targetId: targetId,
          expectedVersion: expectedVersion,
          reason: reason,
          applicantId: applicantId,
          isActive: isActive,
          decision: parsedDecision,
          targetRole: parsedRole,
        ),
        outcome: parsedOutcome,
        resultVersion: resultVersion,
        decision: parsedResultDecision,
        isActive: resultIsActive,
        resultRole: parsedResultRole,
        approvedStallId: approvedStallId,
      );
    } on ArgumentError catch (e) {
      throw DataParsingException(
        e.message?.toString() ?? 'Data lookup mutasi admin tidak valid.',
      );
    }
  }
}
