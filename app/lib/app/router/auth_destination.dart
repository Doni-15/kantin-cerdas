import 'package:kantin_cerdas/app/router/routes.dart';
import 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';

/// Hanya route internal yang dikenal boleh menjadi tujuan sesudah login.
/// Tidak menyimpan token, password, atau snapshot pesanan di URL.
String? validatedAuthDestination(String? value) {
  if (value == null ||
      value.isEmpty ||
      value.length > 2048 ||
      !value.startsWith('/') ||
      value.startsWith('//') ||
      value.contains('\\') ||
      RegExp(r'[\x00-\x20\x7f]').hasMatch(value)) {
    return null;
  }
  try {
    final uri = Uri.parse(value);
    if (uri.hasScheme || uri.hasAuthority || uri.hasFragment) {
      return null;
    }
    final segments = uri.pathSegments;
    if (segments.any(
      (part) =>
          part.isEmpty ||
          part == '.' ||
          part == '..' ||
          part.contains('/') ||
          part.contains('\\') ||
          RegExp(r'[\x00-\x1f\x7f]').hasMatch(part),
    )) {
      return null;
    }
    const pages = <String>{
      Routes.settings,
      Routes.accountSecurity,
      Routes.changePassword,
      Routes.customerHome,
      Routes.customerSearch,
      Routes.customerCart,
      Routes.customerOrders,
      Routes.customerHistory,
      Routes.customerAiChat,
      Routes.customerProfile,
      Routes.customerCanteenApplication,
      Routes.customerFoodPreferences,
      Routes.customerOrderConfirmation,
      Routes.ownerDashboard,
      Routes.ownerCanteen,
      Routes.ownerOrders,
      Routes.ownerProfile,
      Routes.ownerStallSettings,
      Routes.adminDashboard,
      Routes.adminUsers,
      Routes.adminProfile,
      Routes.adminApplications,
    };
    final stall =
        uri.path.startsWith('/customer/stalls/') &&
        segments.length == 3 &&
        segments[0] == 'customer' &&
        segments[1] == 'stalls' &&
        segments[2].trim().isNotEmpty;
    final order =
        uri.path.startsWith('/customer/orders/') &&
        (segments.length == 3 ||
            (segments.length == 4 && segments[3] == 'success')) &&
        segments[0] == 'customer' &&
        segments[1] == 'orders' &&
        segments[2].trim().isNotEmpty;
    final ownerOrder =
        uri.path.startsWith('/owner/orders/') &&
        segments.length == 3 &&
        segments[0] == 'owner' &&
        segments[1] == 'orders' &&
        segments[2].trim().isNotEmpty;
    final application =
        uri.path.startsWith('/admin/applications/') &&
        segments.length == 3 &&
        segments[0] == 'admin' &&
        segments[1] == 'applications' &&
        segments[2].trim().isNotEmpty;
    final user =
        uri.path.startsWith('/admin/users/') &&
        segments.length == 3 &&
        segments[0] == 'admin' &&
        segments[1] == 'users' &&
        segments[2].trim().isNotEmpty;
    if (!pages.contains(uri.path) &&
        !stall &&
        !order &&
        !ownerOrder &&
        !application &&
        !user) {
      return null;
    }
    // Decode query saat validasi; jangan izinkan tujuan bersarang.
    if (uri.queryParametersAll.containsKey('next')) {
      return null;
    }
    return uri.toString();
  } on FormatException {
    return null;
  }
}

String? authDestinationFrom(Uri location) {
  try {
    final values = location.queryParametersAll['next'];
    if (values == null || values.length != 1) {
      return null;
    }
    return validatedAuthDestination(values.single);
  } on FormatException {
    return null;
  }
}

String authLocation(String path, {String? destination}) {
  final valid = validatedAuthDestination(destination);
  return valid == null
      ? path
      : Uri(path: path, queryParameters: {'next': valid}).toString();
}

/// Dipakai saat berpindah antara masuk, daftar, dan pemulihan sesi.
String continueAuthLocation(Uri current, String path) {
  return authLocation(path, destination: authDestinationFrom(current));
}

UserRole? requiredRouteRole(String path) {
  if (path == '/customer' || path.startsWith('/customer/')) {
    return UserRole.customer;
  }
  if (path == '/owner' || path.startsWith('/owner/')) {
    return UserRole.owner;
  }
  if (path == '/admin' || path.startsWith('/admin/')) {
    return UserRole.admin;
  }
  return null;
}

String? authDestinationForRole(String? destination, UserRole role) {
  final valid = validatedAuthDestination(destination);
  if (valid == null) {
    return null;
  }
  final requiredRole = requiredRouteRole(Uri.parse(valid).path);
  return requiredRole == null || role.allows(requiredRole) ? valid : null;
}
