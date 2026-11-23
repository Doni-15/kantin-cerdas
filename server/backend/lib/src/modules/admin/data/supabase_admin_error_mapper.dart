import 'package:kantin_cerdas_backend/src/infrastructure/supabase/supabase_rpc_helper.dart';
import 'package:kantin_cerdas_backend/src/modules/admin/domain/admin_errors.dart';
import 'package:supabase/supabase.dart';

AdminFailure mapAdminPostgrestException(PostgrestException error) {
  const mapping = {
    'KC_ADMIN_REQUIRED': AdminFailureCode.adminRoleRequired,
    'KC_ADMIN_INACTIVE': AdminFailureCode.adminInactive,
    'KC_APPLICATION_NOT_FOUND': AdminFailureCode.applicationNotFound,
    'KC_APPLICATION_ALREADY_DECIDED':
        AdminFailureCode.applicationAlreadyDecided,
    'KC_ALREADY_OWNER': AdminFailureCode.alreadyOwner,
    'KC_TARGET_NOT_CUSTOMER': AdminFailureCode.targetNotCustomer,
    'KC_USER_NOT_FOUND': AdminFailureCode.userNotFound,
    'KC_USER_INACTIVE': AdminFailureCode.userInactive,
    'KC_USER_ALREADY_INACTIVE': AdminFailureCode.userAlreadyInactive,
    'KC_USER_ALREADY_ACTIVE': AdminFailureCode.userAlreadyActive,
    'KC_SELF_DEACTIVATION_NOT_ALLOWED':
        AdminFailureCode.selfDeactivationNotAllowed,
    'KC_LAST_ADMIN_PROTECTED': AdminFailureCode.lastAdminProtected,
    'KC_ACTIVE_ORDERS_PRESENT': AdminFailureCode.activeOrdersPresent,
    'KC_STALL_NOT_FOUND': AdminFailureCode.stallNotFound,
    'KC_REASON_REQUIRED': AdminFailureCode.reasonRequired,
    'KC_INVALID_INPUT': AdminFailureCode.invalidInput,
  };
  final code = matchPostgrestErrorToken(error, mapping);
  return code == null
      ? const AdminFailure(AdminFailureCode.unavailable)
      : AdminFailure(code);
}
