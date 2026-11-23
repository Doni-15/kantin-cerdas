enum NotificationFailureCode {
  invalidInput,
  roleNotAllowed,
  accountInactive,
  deliveryNotFound,
  unavailable,
}

class NotificationFailure implements Exception {
  const NotificationFailure(this.code, [this.message]);

  final NotificationFailureCode code;
  final String? message;

  @override
  String toString() =>
      'NotificationFailure(${code.name}${message == null ? '' : ': $message'})';
}
