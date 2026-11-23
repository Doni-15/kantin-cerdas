enum AdminApplicationStatus {
  menungguReview('menunggu_review', 'Menunggu Review'),
  disetujui('disetujui', 'Disetujui'),
  ditolak('ditolak', 'Ditolak');

  const AdminApplicationStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static AdminApplicationStatus fromApi(String? value) =>
      AdminApplicationStatus.values.firstWhere(
        (status) => status.apiValue == value,
        orElse: () => AdminApplicationStatus.menungguReview,
      );
}

enum AdminUserRole {
  customer('customer', 'Customer'),
  owner('owner', 'Owner'),
  admin('admin', 'Admin');

  const AdminUserRole(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static AdminUserRole fromApi(String? value) =>
      AdminUserRole.values.firstWhere(
        (role) => role.apiValue == value,
        orElse: () => AdminUserRole.customer,
      );
}

enum AdminActionType {
  applicationApproved('application_approved', 'Pengajuan Disetujui'),
  applicationRejected('application_rejected', 'Pengajuan Ditolak'),
  userDeactivated('user_deactivated', 'Akun Dinonaktifkan'),
  userReactivated('user_reactivated', 'Akun Diaktifkan Kembali');

  const AdminActionType(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static AdminActionType fromApi(String? value) =>
      AdminActionType.values.firstWhere(
        (type) => type.apiValue == value,
        orElse: () => AdminActionType.userDeactivated,
      );
}

class AdminActiveOrderIndicator {
  const AdminActiveOrderIndicator({
    required this.userId,
    required this.hasActiveOrders,
    required this.activeOrderCount,
  });

  final String userId;
  final bool hasActiveOrders;
  final int activeOrderCount;

  factory AdminActiveOrderIndicator.fromJson(Map<String, dynamic> json) {
    return AdminActiveOrderIndicator(
      userId: json['user_id'] as String? ?? '',
      hasActiveOrders: json['has_active_orders'] as bool? ?? false,
      activeOrderCount: (json['active_order_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminApplicationPreview {
  const AdminApplicationPreview({
    required this.id,
    required this.customerId,
    required this.applicantName,
    required this.applicantEmail,
    required this.plannedStallName,
    required this.plannedLocation,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String customerId;
  final String applicantName;
  final String applicantEmail;
  final String plannedStallName;
  final String plannedLocation;
  final AdminApplicationStatus status;
  final DateTime createdAt;

  factory AdminApplicationPreview.fromJson(Map<String, dynamic> json) {
    return AdminApplicationPreview(
      id: json['id'] as String,
      customerId: json['customer_id'] as String? ?? '',
      applicantName: json['applicant_name'] as String? ?? '-',
      applicantEmail: json['applicant_email'] as String? ?? '',
      plannedStallName: json['planned_stall_name'] as String? ?? '-',
      plannedLocation: json['planned_location'] as String? ?? '-',
      status: AdminApplicationStatus.fromApi(json['status'] as String?),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

class AdminDashboardSummary {
  const AdminDashboardSummary({
    required this.totalUsers,
    required this.activeUsers,
    required this.inactiveUsers,
    required this.pendingApplications,
    required this.totalStalls,
    required this.publishedStalls,
    required this.openStalls,
    required this.recentPendingApplications,
  });

  final int totalUsers;
  final int activeUsers;
  final int inactiveUsers;
  final int pendingApplications;
  final int totalStalls;
  final int publishedStalls;
  final int openStalls;
  final List<AdminApplicationPreview> recentPendingApplications;

  factory AdminDashboardSummary.fromJson(Map<String, dynamic> json) {
    final recentRaw = json['recent_pending_applications'] as List? ?? const [];
    return AdminDashboardSummary(
      totalUsers: (json['total_users'] as num?)?.toInt() ?? 0,
      activeUsers: (json['active_users'] as num?)?.toInt() ?? 0,
      inactiveUsers: (json['inactive_users'] as num?)?.toInt() ?? 0,
      pendingApplications: (json['pending_applications'] as num?)?.toInt() ?? 0,
      totalStalls: (json['total_stalls'] as num?)?.toInt() ?? 0,
      publishedStalls: (json['published_stalls'] as num?)?.toInt() ?? 0,
      openStalls: (json['open_stalls'] as num?)?.toInt() ?? 0,
      recentPendingApplications: [
        for (final item in recentRaw)
          if (item is Map<String, dynamic>)
            AdminApplicationPreview.fromJson(item)
          else if (item is Map)
            AdminApplicationPreview.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }
}

class AdminOwnerApplication {
  const AdminOwnerApplication({
    required this.id,
    required this.customerId,
    required this.applicantName,
    required this.applicantEmail,
    required this.applicantRole,
    required this.applicantIsActive,
    required this.plannedStallName,
    required this.plannedLocation,
    required this.reason,
    required this.status,
    this.rejectionReason,
    this.decidedBy,
    this.decidedByName,
    this.decidedAt,
    required this.createdAt,
    required this.activeOrderIndicator,
  });

  final String id;
  final String customerId;
  final String applicantName;
  final String applicantEmail;
  final AdminUserRole applicantRole;
  final bool applicantIsActive;
  final String plannedStallName;
  final String plannedLocation;
  final String reason;
  final AdminApplicationStatus status;
  final String? rejectionReason;
  final String? decidedBy;
  final String? decidedByName;
  final DateTime? decidedAt;
  final DateTime createdAt;
  final AdminActiveOrderIndicator activeOrderIndicator;

  factory AdminOwnerApplication.fromJson(Map<String, dynamic> json) {
    final indicatorRaw = json['active_order_indicator'];
    final indicatorMap = indicatorRaw is Map<String, dynamic>
        ? indicatorRaw
        : indicatorRaw is Map
        ? Map<String, dynamic>.from(indicatorRaw)
        : const <String, dynamic>{};

    return AdminOwnerApplication(
      id: json['id'] as String,
      customerId: json['customer_id'] as String? ?? '',
      applicantName: json['applicant_name'] as String? ?? '-',
      applicantEmail: json['applicant_email'] as String? ?? '',
      applicantRole: AdminUserRole.fromApi(json['applicant_role'] as String?),
      applicantIsActive: json['applicant_is_active'] as bool? ?? true,
      plannedStallName: json['planned_stall_name'] as String? ?? '-',
      plannedLocation: json['planned_location'] as String? ?? '-',
      reason: json['reason'] as String? ?? '',
      status: AdminApplicationStatus.fromApi(json['status'] as String?),
      rejectionReason: json['rejection_reason'] as String?,
      decidedBy: json['decided_by'] as String?,
      decidedByName: json['decided_by_name'] as String?,
      decidedAt: json['decided_at'] is String
          ? DateTime.tryParse(json['decided_at'] as String)
          : null,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      activeOrderIndicator: AdminActiveOrderIndicator.fromJson(indicatorMap),
    );
  }
}

class AdminActionLog {
  const AdminActionLog({
    required this.id,
    required this.adminId,
    required this.adminName,
    required this.actionType,
    required this.targetUserId,
    this.targetUserName,
    this.targetApplicationId,
    this.reason,
    required this.summary,
    required this.createdAt,
  });

  final String id;
  final String adminId;
  final String adminName;
  final AdminActionType actionType;
  final String targetUserId;
  final String? targetUserName;
  final String? targetApplicationId;
  final String? reason;
  final String summary;
  final DateTime createdAt;

  factory AdminActionLog.fromJson(Map<String, dynamic> json) {
    return AdminActionLog(
      id: json['id'] as String,
      adminId: json['admin_id'] as String? ?? '',
      adminName: json['admin_name'] as String? ?? 'Admin',
      actionType: AdminActionType.fromApi(json['action_type'] as String?),
      targetUserId: json['target_user_id'] as String? ?? '',
      targetUserName: json['target_user_name'] as String?,
      targetApplicationId: json['target_application_id'] as String?,
      reason: json['reason'] as String?,
      summary: json['summary'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

class AdminManagedUser {
  const AdminManagedUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isActive,
    required this.emailVerified,
    required this.createdAt,
    required this.activeOrderIndicator,
    this.recentLogs = const [],
  });

  final String id;
  final String email;
  final String displayName;
  final AdminUserRole role;
  final bool isActive;
  final bool emailVerified;
  final DateTime createdAt;
  final AdminActiveOrderIndicator activeOrderIndicator;
  final List<AdminActionLog> recentLogs;

  factory AdminManagedUser.fromJson(Map<String, dynamic> json) {
    final indicatorRaw = json['active_order_indicator'];
    final indicatorMap = indicatorRaw is Map<String, dynamic>
        ? indicatorRaw
        : indicatorRaw is Map
        ? Map<String, dynamic>.from(indicatorRaw)
        : const <String, dynamic>{};
    final logsRaw = json['recent_logs'] as List? ?? const [];

    return AdminManagedUser(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '-',
      role: AdminUserRole.fromApi(json['role'] as String?),
      isActive: json['is_active'] as bool? ?? true,
      emailVerified: json['email_verified'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      activeOrderIndicator: AdminActiveOrderIndicator.fromJson(indicatorMap),
      recentLogs: [
        for (final item in logsRaw)
          if (item is Map<String, dynamic>)
            AdminActionLog.fromJson(item)
          else if (item is Map)
            AdminActionLog.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }
}

class AdminScheduleDay {
  const AdminScheduleDay({
    required this.dayOfWeek,
    required this.isOpenDay,
    this.openTime,
    this.closeTime,
  });

  final int dayOfWeek;
  final bool isOpenDay;
  final String? openTime;
  final String? closeTime;

  factory AdminScheduleDay.fromJson(Map<String, dynamic> json) {
    return AdminScheduleDay(
      dayOfWeek: (json['day_of_week'] as num?)?.toInt() ?? 1,
      isOpenDay: json['is_open_day'] as bool? ?? false,
      openTime: json['open_time'] as String?,
      closeTime: json['close_time'] as String?,
    );
  }
}

class AdminStallSummary {
  const AdminStallSummary({
    required this.id,
    required this.name,
    required this.campus,
    required this.block,
    required this.waitMinutes,
    required this.isListed,
    required this.isOpen,
    required this.hasPhoto,
    required this.ownerId,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerIsActive,
    required this.updatedAt,
    this.description,
    this.schedules = const [],
  });

  final String id;
  final String name;
  final String campus;
  final String block;
  final int waitMinutes;
  final bool isListed;
  final bool isOpen;
  final bool hasPhoto;
  final String ownerId;
  final String ownerName;
  final String ownerEmail;
  final bool ownerIsActive;
  final DateTime updatedAt;
  final String? description;
  final List<AdminScheduleDay> schedules;

  factory AdminStallSummary.fromJson(Map<String, dynamic> json) {
    final schedulesRaw = json['schedules'] as List? ?? const [];
    return AdminStallSummary(
      id: json['id'] as String,
      name: json['name'] as String? ?? '-',
      campus: json['campus'] as String? ?? '-',
      block: json['block'] as String? ?? '-',
      waitMinutes: (json['wait_minutes'] as num?)?.toInt() ?? 0,
      isListed: json['is_listed'] as bool? ?? false,
      isOpen: json['is_open'] as bool? ?? false,
      hasPhoto: json['has_photo'] as bool? ?? false,
      ownerId: json['owner_id'] as String? ?? '',
      ownerName: json['owner_name'] as String? ?? '-',
      ownerEmail: json['owner_email'] as String? ?? '',
      ownerIsActive: json['owner_is_active'] as bool? ?? true,
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      description: json['description'] as String?,
      schedules: [
        for (final item in schedulesRaw)
          if (item is Map<String, dynamic>)
            AdminScheduleDay.fromJson(item)
          else if (item is Map)
            AdminScheduleDay.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }
}
