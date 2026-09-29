import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/features/customer/domain/enums/canteen_application_status.dart';

class CanteenApplicationModel {
  const CanteenApplicationModel({
    required this.id,
    required this.customerId,
    required this.name,
    required this.description,
    required this.address,
    required this.status,
    required this.submittedAt,
    this.rejectionReason,
  });

  final String id;
  final String customerId;
  final String name;
  final String description;
  final String address;

  /// Nilai mentah dari Backend (mis. "under_review").
  final String status;
  final String? rejectionReason;
  final DateTime submittedAt;

  factory CanteenApplicationModel.fromJson(Map<String, dynamic> json) {
    return CanteenApplicationModel(
      // `as Object` melempar TypeError jika null/hilang, lalu ditangani Repository.
      id: (json['id'] as Object).toString(),
      customerId: (json['customer_id'] as Object).toString(),
      name: json['name'] as String,
      description: json['description'] as String,
      address: json['address'] as String,
      status: json['status'] as String,
      rejectionReason: json['rejection_reason'] as String?,
      submittedAt: DateTime.parse(json['submitted_at'] as String),
    );
  }

  CanteenApplication toEntity() {
    return CanteenApplication(
      id: id,
      customerId: customerId,
      name: name,
      description: description,
      address: address,
      status: _mapStatus(status),
      rejectionReason: rejectionReason,
      submittedAt: submittedAt,
    );
  }

  /// Enum -> nilai yang dikirim ke Backend (snake_case).
  static String statusToJson(CanteenApplicationStatus status) {
    return switch (status) {
      CanteenApplicationStatus.submitted => 'submitted',
      CanteenApplicationStatus.underReview => 'under_review',
      CanteenApplicationStatus.approved => 'approved',
      CanteenApplicationStatus.rejected => 'rejected',
    };
  }

  /// Toleran terhadap huruf besar/kecil dan pemisah: "under_review",
  /// "UNDER_REVIEW", "underReview" semuanya menjadi underReview.
  static CanteenApplicationStatus _mapStatus(String value) {
    final normalized =
        value.trim().toLowerCase().replaceAll('_', '').replaceAll('-', '');

    for (final status in CanteenApplicationStatus.values) {
      if (status.name.toLowerCase() == normalized) {
        return status;
      }
    }

    throw DataParsingException('Unknown application status: $value');
  }
}
