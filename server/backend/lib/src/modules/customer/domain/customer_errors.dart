enum CustomerFailureCode {
  customerRoleRequired,
  alreadyOwner,
  stallNotFound,
  menuNotFound,
  stallClosed,
  ownerInactive,
  customerInactive,
  emailNotVerified,
  menuArchived,
  menuUnavailable,
  cartDifferentStall,
  cartItemNotFound,
  cartEmpty,
  cartVersionConflict,
  priceChanged,
  idempotencyConflict,
  orderNotFound,
  invalidOrderTransition,
  applicationAlreadyPending,
  unsupportedMediaType,
  payloadTooLarge,
  invalidInput,
  unavailable,
}

class CustomerFailure implements Exception {
  const CustomerFailure(this.code, [this.message]);

  final CustomerFailureCode code;
  final String? message;
}
