import 'package:kantin_cerdas_backend/src/modules/customer/domain/customer_errors.dart';
import 'package:supabase/supabase.dart';

const _customerFailureCodes = {
  'KC_ALREADY_OWNER': CustomerFailureCode.alreadyOwner,
  'KC_APPLICATION_ALREADY_PENDING':
      CustomerFailureCode.applicationAlreadyPending,
  'KC_CART_DIFFERENT_STALL': CustomerFailureCode.cartDifferentStall,
  'KC_CART_EMPTY': CustomerFailureCode.cartEmpty,
  'KC_CART_ITEM_NOT_FOUND': CustomerFailureCode.cartItemNotFound,
  'KC_CART_VERSION_CONFLICT': CustomerFailureCode.cartVersionConflict,
  'KC_CUSTOMER_INACTIVE': CustomerFailureCode.customerInactive,
  'KC_EMAIL_NOT_VERIFIED': CustomerFailureCode.emailNotVerified,
  'KC_IDEMPOTENCY_CONFLICT': CustomerFailureCode.idempotencyConflict,
  'KC_INVALID_INPUT': CustomerFailureCode.invalidInput,
  'KC_INVALID_ORDER_TRANSITION': CustomerFailureCode.invalidOrderTransition,
  'KC_MENU_ARCHIVED': CustomerFailureCode.menuArchived,
  'KC_MENU_NOT_FOUND': CustomerFailureCode.menuNotFound,
  'KC_MENU_UNAVAILABLE': CustomerFailureCode.menuUnavailable,
  'KC_ORDER_NOT_FOUND': CustomerFailureCode.orderNotFound,
  'KC_OWNER_INACTIVE': CustomerFailureCode.ownerInactive,
  'KC_PRICE_CHANGED': CustomerFailureCode.priceChanged,
  'KC_STALL_CLOSED': CustomerFailureCode.stallClosed,
};

final _customerErrorToken = RegExp(r'(?<![A-Z0-9_])KC_[A-Z_]+(?![A-Z0-9_])');

CustomerFailure mapCustomerPostgrestException(PostgrestException error) {
  final code =
      _mappedCodeIn(error.message) ??
      _mappedCodeIn(error.details?.toString() ?? '');
  return code == null
      ? const CustomerFailure(CustomerFailureCode.unavailable)
      : CustomerFailure(code);
}

CustomerFailureCode? _mappedCodeIn(String text) {
  for (final match in _customerErrorToken.allMatches(text)) {
    final code = _customerFailureCodes[match.group(0)];
    if (code != null) return code;
  }
  return null;
}
