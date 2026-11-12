import 'package:characters/characters.dart';

enum CanteenApplicationStatus {
  submitted,
  reviewing,
  approved,
  rejected;

  static CanteenApplicationStatus? tryFromRaw(String? raw) {
    return switch (raw?.trim().toLowerCase()) {
      'submitted' => CanteenApplicationStatus.submitted,
      'reviewing' => CanteenApplicationStatus.reviewing,
      'approved' => CanteenApplicationStatus.approved,
      'rejected' => CanteenApplicationStatus.rejected,
      _ => null,
    };
  }
}

extension CanteenApplicationReviewStatus on CanteenApplicationStatus {
  bool get canBeReviewed =>
      this == CanteenApplicationStatus.submitted ||
      this == CanteenApplicationStatus.reviewing;
}

class CanteenApplicationDraft {
  CanteenApplicationDraft({
    required String name,
    required String description,
    required String location,
    required String phone,
  }) : name = name.trim(),
       description = description.trim(),
       location = location.trim(),
       phone = phone.trim() {
    if (this.name.isEmpty ||
        this.name.characters.length > 120 ||
        this.description.isEmpty ||
        this.description.characters.length > 1000 ||
        this.location.isEmpty ||
        this.location.characters.length > 120 ||
        !validPhone(this.phone)) {
      throw ArgumentError('Data pengajuan tidak valid.');
    }
  }
  final String name;
  final String description;
  final String location;
  final String phone;

  static bool validPhone(String value) {
    final text = value.trim();
    if (text.length > 24 || !RegExp(r'^\+?[0-9 ()-]+$').hasMatch(text)) {
      return false;
    }
    final digits = text.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 8 && digits.length <= 15;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CanteenApplicationDraft &&
          other.name == name &&
          other.description == description &&
          other.location == location &&
          other.phone == phone);

  @override
  int get hashCode => Object.hash(name, description, location, phone);
}

class CanteenApplication {
  CanteenApplication({
    required this.id,
    required this.applicantId,
    required this.name,
    required this.description,
    required this.location,
    required this.phone,
    required this.status,
    required this.createdAt,
    required this.version,
    String? reason,
  }) : reason = reason != null && reason.trim().isNotEmpty
           ? reason.trim()
           : null {
    CanteenApplicationDraft(
      name: name,
      description: description,
      location: location,
      phone: phone,
    );
    if (id.trim().isEmpty ||
        applicantId.trim().isEmpty ||
        version < 1 ||
        (this.reason?.characters.length ?? 0) > 300 ||
        (status == CanteenApplicationStatus.rejected
            ? this.reason == null
            : this.reason != null)) {
      throw ArgumentError('Status pengajuan tidak valid.');
    }
  }
  final String id;
  final String applicantId;
  final String name;
  final String description;
  final String location;
  final String phone;
  final CanteenApplicationStatus status;
  final DateTime createdAt;
  final int version;
  final String? reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CanteenApplication &&
          other.id == id &&
          other.applicantId == applicantId &&
          other.name == name &&
          other.description == description &&
          other.location == location &&
          other.phone == phone &&
          other.status == status &&
          other.createdAt.isAtSameMomentAs(createdAt) &&
          other.version == version &&
          other.reason == reason);

  @override
  int get hashCode => Object.hash(
    id,
    applicantId,
    name,
    description,
    location,
    phone,
    status,
    createdAt.millisecondsSinceEpoch,
    version,
    reason,
  );
}
