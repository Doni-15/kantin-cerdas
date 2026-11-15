/// Input tervalidasi untuk `POST /v1/customer/canteen-applications`.
///
/// Selaras dengan `PendingCanteenApplication` di Flutter dan parameter
/// `public.rpc_submit_canteen_application` di `006_rpc_customer.sql`.
final class ValidatedSubmitCanteenApplicationInput {
  final String submissionId;
  final String name;
  final String description;
  final String location;
  final String phone;
  final String? previousId;
  final int? previousVersion;

  const ValidatedSubmitCanteenApplicationInput({
    required this.submissionId,
    required this.name,
    required this.description,
    required this.location,
    required this.phone,
    this.previousId,
    this.previousVersion,
  });
}
