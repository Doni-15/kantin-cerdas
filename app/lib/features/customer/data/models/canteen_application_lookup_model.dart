import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application_lookup.dart';
import 'package:kantin_cerdas/features/orders/data/models/canteen_application_model.dart';

class CanteenApplicationLookupModel {
  const CanteenApplicationLookupModel({
    required this.customerId,
    required this.submissionId,
    required this.status,
    this.receipt,
  });

  factory CanteenApplicationLookupModel.fromJson(Map<String, Object?> json) {
    final customerId = json['customer_id'] ?? json['customerId'];
    final submissionId = json['submission_id'] ?? json['submissionId'];
    final status = json['status'] ?? json['outcome'];
    final rawReceipt = tryAsJsonMap(json['receipt'] ?? json['application']);

    if (customerId is! String || submissionId is! String || status is! String) {
      throw const DataParsingException(
        'Format lookup pengajuan stan tidak valid.',
      );
    }

    return CanteenApplicationLookupModel(
      customerId: customerId,
      submissionId: submissionId,
      status: status,
      receipt: rawReceipt == null
          ? null
          : CanteenApplicationModel.fromJson(rawReceipt),
    );
  }

  final String customerId;
  final String submissionId;
  final String status;
  final CanteenApplicationModel? receipt;

  CanteenApplicationLookup toEntity() {
    final parsedStatus = switch (status.trim().toLowerCase()) {
      'pending' => CanteenApplicationSubmissionStatus.pending,
      'submitted' || 'applied' => CanteenApplicationSubmissionStatus.submitted,
      'not_submitted' ||
      'notsubmitted' ||
      'not_applied' ||
      'notapplied' => CanteenApplicationSubmissionStatus.notSubmitted,
      _ => throw const DataParsingException(
        'Status lookup pengajuan stan tidak dikenali.',
      ),
    };
    try {
      return CanteenApplicationLookup(
        customerId: customerId,
        submissionId: submissionId,
        status: parsedStatus,
        receipt: receipt?.toEntity(),
      );
    } on ArgumentError catch (e) {
      throw DataParsingException(
        e.message?.toString() ?? 'Data lookup pengajuan stan tidak valid.',
      );
    }
  }
}
