enum OwnerFailureCode {
  ownerRoleRequired,
  stallAlreadyExists,
  stallNotFound,
  stallAlreadyPublished,
  stallNotPublished,
  publishProfileIncomplete,
  publishMenuRequired,
  unpublishNotAllowed,
  invalidSchedule,
  categoryNotFound,
  categoryNameExists,
  categoryNotEmpty,
  menuNotFound,
  orderNotFound,
  invalidOrderTransition,
  reasonRequired,
  completeConfirmationRequired,
  invalidImage,
  unsupportedMediaType,
  imageTooLarge,
  invalidInput,
  unavailable,
}

class OwnerFailure implements Exception {
  const OwnerFailure(this.code, [this.message]);

  final OwnerFailureCode code;
  final String? message;
}
