import 'package:kantin_cerdas/features/customer/domain/enums/canteen_application_status.dart';

class CanteenApplication {
  const CanteenApplication({
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

  final CanteenApplicationStatus status;
  final String? rejectionReason;

  final DateTime submittedAt;
}