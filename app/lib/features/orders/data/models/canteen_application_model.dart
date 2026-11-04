import 'package:kantin_cerdas/core/domain/entities/canteen_application.dart';
import 'package:kantin_cerdas/core/errors/data_parsing_exception.dart';
import 'package:kantin_cerdas/core/utils/json_map_utils.dart';

class CanteenApplicationModel {
  const CanteenApplicationModel({
    required this.id,
    required this.applicantId,
    required this.name,
    required this.description,
    required this.location,
    required this.phone,
    required this.status,
    required this.createdAtIso,
    required this.version,
    this.reason,
  });

  factory CanteenApplicationModel.fromJson(Map<String, Object?> json) {
    final id = json['id'];
    final applicantId = json['applicant_id'] ?? json['applicantId'];
    final name = json['name'];
    final description = json['description'];
    final location = json['location'];
    final phone = json['phone'];
    final status = json['status'];
    final createdAt = json['created_at'] ?? json['createdAt'];
    final version = json['version'];
    final reason = normalizeOptionalText(json['reason'], fieldName: 'reason');

    if (id is! String ||
        applicantId is! String ||
        name is! String ||
        description is! String ||
        location is! String ||
        phone is! String ||
        status is! String ||
        createdAt is! String ||
        version is! int) {
      throw const DataParsingException('Format pengajuan stan tidak valid.');
    }

    return CanteenApplicationModel(
      id: id,
      applicantId: applicantId,
      name: name,
      description: description,
      location: location,
      phone: phone,
      status: status,
      createdAtIso: createdAt,
      version: version,
      reason: reason,
    );
  }

  final String id;
  final String applicantId;
  final String name;
  final String description;
  final String location;
  final String phone;
  final String status;
  final String createdAtIso;
  final int version;
  final String? reason;

  CanteenApplication toEntity() {
    final createdAt = parseStrictUtcDateTime(
      createdAtIso,
      fieldName: 'created_at',
    );
    final parsedStatus = CanteenApplicationStatus.tryFromRaw(status);
    if (parsedStatus == null) {
      throw const DataParsingException('Status pengajuan stan tidak dikenali.');
    }
    try {
      return CanteenApplication(
        id: id,
        applicantId: applicantId,
        name: name,
        description: description,
        location: location,
        phone: phone,
        status: parsedStatus,
        createdAt: createdAt,
        version: version,
        reason: reason,
      );
    } on ArgumentError catch (e) {
      throw DataParsingException(
        e.message?.toString() ?? 'Pengajuan stan tidak valid.',
      );
    }
  }
}
