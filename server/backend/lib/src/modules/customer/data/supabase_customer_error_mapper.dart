import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_rpc_helper.dart';
import 'package:kantin_cerdas_backend/src/modules/customer/domain/customer_errors.dart';
import 'package:supabase/supabase.dart';

CustomerFailure mapCustomerPostgrestException(PostgrestException error) {
  const mapping = {
    'KC_ALREADY_OWNER': CustomerFailureCode.alreadyOwner,
    'KC_STALL_NOT_FOUND': CustomerFailureCode.stallNotFound,
    'KC_MENU_NOT_FOUND': CustomerFailureCode.menuNotFound,
    'KC_STALL_CLOSED': CustomerFailureCode.stallClosed,
    'KC_OWNER_INACTIVE': CustomerFailureCode.ownerInactive,
    'KC_CUSTOMER_INACTIVE': CustomerFailureCode.customerInactive,
    'KC_EMAIL_NOT_VERIFIED': CustomerFailureCode.emailNotVerified,
    'KC_MENU_ARCHIVED': CustomerFailureCode.menuArchived,
    'KC_MENU_UNAVAILABLE': CustomerFailureCode.menuUnavailable,
    'KC_CART_DIFFERENT_STALL': CustomerFailureCode.cartDifferentStall,
    'KC_CART_ITEM_NOT_FOUND': CustomerFailureCode.cartItemNotFound,
    'KC_CART_EMPTY': CustomerFailureCode.cartEmpty,
    'KC_CART_VERSION_CONFLICT': CustomerFailureCode.cartVersionConflict,
    'KC_PRICE_CHANGED': CustomerFailureCode.priceChanged,
    'KC_IDEMPOTENCY_CONFLICT': CustomerFailureCode.idempotencyConflict,
    'KC_ORDER_NOT_FOUND': CustomerFailureCode.orderNotFound,
    'KC_INVALID_ORDER_TRANSITION': CustomerFailureCode.invalidOrderTransition,
    'KC_APPLICATION_ALREADY_PENDING': CustomerFailureCode.applicationAlreadyPending,
    'KC_INVALID_INPUT': CustomerFailureCode.invalidInput,
  };
  final code = matchPostgrestErrorToken(error, mapping);
  return code == null
    ? const CustomerFailure(CustomerFailureCode.unavailable)
    : CustomerFailure(code);
}
