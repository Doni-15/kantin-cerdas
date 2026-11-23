enum AiResponseStatus {
  catalogFallback,
  aiResponse,
  aiUnavailable,
  quotaExhausted;

  static AiResponseStatus fromWire(String? raw) => switch (raw) {
    'ai_response' => AiResponseStatus.aiResponse,
    'ai_unavailable' => AiResponseStatus.aiUnavailable,
    'quota_exhausted' => AiResponseStatus.quotaExhausted,
    _ => AiResponseStatus.catalogFallback,
  };
}

class AiQuotaSnapshot {
  const AiQuotaSnapshot({
    required this.jakartaDate,
    required this.dailyLimit,
    required this.usedToday,
    required this.remainingToday,
    required this.resetSchedule,
    required this.projectCapConfigured,
    required this.projectQuotaKnown,
    this.projectRemainingToday,
  });

  final String jakartaDate;
  final int dailyLimit;
  final int usedToday;
  final int remainingToday;
  final String resetSchedule;
  final bool projectCapConfigured;
  final bool projectQuotaKnown;
  final int? projectRemainingToday;

  factory AiQuotaSnapshot.fromJson(Map<String, dynamic> json) =>
      AiQuotaSnapshot(
        jakartaDate: json['jakarta_date'] as String? ?? '',
        dailyLimit: (json['daily_limit'] as num?)?.toInt() ?? 10,
        usedToday: (json['used_today'] as num?)?.toInt() ?? 0,
        remainingToday: (json['remaining_today'] as num?)?.toInt() ?? 0,
        resetSchedule:
            json['reset_schedule'] as String? ?? '00:00 WIB (Asia/Jakarta)',
        projectCapConfigured: json['project_cap_configured'] as bool? ?? false,
        projectQuotaKnown: json['project_quota_known'] as bool? ?? false,
        projectRemainingToday: (json['project_remaining_today'] as num?)
            ?.toInt(),
      );
}

class AiStallSummary {
  const AiStallSummary({
    required this.id,
    required this.name,
    required this.block,
    required this.waitMinutes,
    required this.isOpen,
    required this.ownerIsActive,
  });

  final String id;
  final String name;
  final String block;
  final int waitMinutes;
  final bool isOpen;
  final bool ownerIsActive;

  factory AiStallSummary.fromJson(Map<String, dynamic> json) => AiStallSummary(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    block: json['block'] as String? ?? '',
    waitMinutes: (json['wait_minutes'] as num?)?.toInt() ?? 0,
    isOpen: json['is_open'] as bool? ?? false,
    ownerIsActive: json['owner_is_active'] as bool? ?? false,
  );
}

class AiMenuRecommendation {
  const AiMenuRecommendation({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.hasPhoto,
    required this.isAvailable,
    required this.isOrderable,
    required this.availabilityLabel,
    required this.stall,
    this.unavailableReason,
  });

  final String id;
  final String name;
  final String description;
  final String category;
  final int price;
  final bool hasPhoto;
  final bool isAvailable;
  final bool isOrderable;
  final String? unavailableReason;
  final String availabilityLabel;
  final AiStallSummary stall;

  factory AiMenuRecommendation.fromJson(Map<String, dynamic> json) {
    final stallJson = json['stall'] as Map<String, dynamic>? ?? const {};
    return AiMenuRecommendation(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      hasPhoto: json['has_photo'] as bool? ?? false,
      isAvailable: json['is_available'] as bool? ?? false,
      isOrderable: json['is_orderable'] as bool? ?? false,
      unavailableReason: json['unavailable_reason'] as String?,
      availabilityLabel:
          json['availability_label'] as String? ??
          ((json['is_orderable'] as bool? ?? false)
              ? 'Tersedia · Kantin Buka'
              : 'Tidak Dapat Dipesan'),
      stall: AiStallSummary.fromJson(stallJson),
    );
  }
}

class AiStatusSnapshot {
  const AiStatusSnapshot({
    required this.providerEnabled,
    required this.providerReady,
    required this.model,
    required this.fallbackActive,
    required this.reasonCode,
    required this.reasonMessage,
    required this.quota,
  });

  final bool providerEnabled;
  final bool providerReady;
  final String model;
  final bool fallbackActive;
  final String reasonCode;
  final String reasonMessage;
  final AiQuotaSnapshot quota;

  factory AiStatusSnapshot.fromJson(Map<String, dynamic> json) =>
      AiStatusSnapshot(
        providerEnabled: json['provider_enabled'] as bool? ?? false,
        providerReady: json['provider_ready'] as bool? ?? false,
        model: json['model'] as String? ?? 'gemini-3.5-flash-lite',
        fallbackActive: json['fallback_active'] as bool? ?? true,
        reasonCode: json['reason_code'] as String? ?? 'provider_disabled',
        reasonMessage: json['reason_message'] as String? ?? '',
        quota: AiQuotaSnapshot.fromJson(
          json['quota'] as Map<String, dynamic>? ?? const {},
        ),
      );
}

class AiChatResult {
  const AiChatResult({
    required this.status,
    required this.reply,
    required this.recommendations,
    required this.isGeneralCulinary,
    required this.isVerifiedCatalogData,
    required this.hasUncertaintyNotice,
    required this.fallbackUsed,
    required this.providerEnabled,
    required this.providerModel,
    required this.quota,
    this.fallbackReason,
    this.appliedMaxBudget,
  });

  final AiResponseStatus status;
  final String reply;
  final List<AiMenuRecommendation> recommendations;
  final bool isGeneralCulinary;
  final bool isVerifiedCatalogData;
  final bool hasUncertaintyNotice;
  final bool fallbackUsed;
  final String? fallbackReason;
  final bool providerEnabled;
  final String providerModel;
  final int? appliedMaxBudget;
  final AiQuotaSnapshot quota;

  factory AiChatResult.fromJson(Map<String, dynamic> json) {
    final rawRecs = json['recommendations'] as List<dynamic>? ?? const [];
    return AiChatResult(
      status: AiResponseStatus.fromWire(json['status'] as String?),
      reply: json['reply'] as String? ?? '',
      recommendations: [
        for (final item in rawRecs)
          AiMenuRecommendation.fromJson(item as Map<String, dynamic>),
      ],
      isGeneralCulinary: json['is_general_culinary'] as bool? ?? false,
      isVerifiedCatalogData: json['is_verified_catalog_data'] as bool? ?? true,
      hasUncertaintyNotice: json['has_uncertainty_notice'] as bool? ?? false,
      fallbackUsed: json['fallback_used'] as bool? ?? true,
      fallbackReason: json['fallback_reason'] as String?,
      providerEnabled: json['provider_enabled'] as bool? ?? false,
      providerModel: json['provider_model'] as String? ?? '',
      appliedMaxBudget: (json['applied_max_budget'] as num?)?.toInt(),
      quota: AiQuotaSnapshot.fromJson(
        json['quota'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class AiChatMessage {
  const AiChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    this.status,
    this.recommendations = const [],
    this.isGeneralCulinary = false,
    this.hasUncertaintyNotice = false,
    this.fallbackUsed = false,
    this.appliedMaxBudget,
  });

  final String id;
  final bool isUser;
  final String text;
  final AiResponseStatus? status;
  final List<AiMenuRecommendation> recommendations;
  final bool isGeneralCulinary;
  final bool hasUncertaintyNotice;
  final bool fallbackUsed;
  final int? appliedMaxBudget;
}
