enum AdminFailureCode {
  adminRoleRequired,
  adminInactive,
  applicationNotFound,
  applicationAlreadyDecided,
  alreadyOwner,
  targetNotCustomer,
  userNotFound,
  userInactive,
  userAlreadyInactive,
  userAlreadyActive,
  selfDeactivationNotAllowed,
  lastAdminProtected,
  activeOrdersPresent,
  stallNotFound,
  reasonRequired,
  unsupportedMediaType,
  payloadTooLarge,
  invalidInput,
  unavailable,
}

class AdminFailure implements Exception {
  const AdminFailure(this.code, [this.message]);

  final AdminFailureCode code;
  final String? message;
}
