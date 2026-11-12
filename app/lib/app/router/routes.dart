abstract final class Routes {
  // Pintu masuk aplikasi.
  static const app = '/app';

  // Autentikasi.
  static const login = '/login';
  static const resetPassword = '/reset-password';
  static const register = '/register';
  static const registerProfile = '/register/profile';

  // Halaman bersama.
  static const settings = '/settings';
  static const accountSecurity = '/account-security';
  static const changePassword = '/change-password';
  static const help = '/help';
  static const terms = '/terms';

  // Pelanggan.
  static const customerHome = '/customer/home';
  static const customerSearch = '/customer/search';
  static const customerCart = '/customer/cart';
  static const customerOrders = '/customer/orders';
  static const customerHistory = '/customer/history';
  static const customerAiChat = '/customer/ai-chat';
  static const customerProfile = '/customer/profile';
  static const customerFoodPreferences = '/customer/food-preferences';
  static const customerCanteenApplication = '/customer/canteen-application';
  static const customerOrderConfirmation = '/customer/order-confirmation';

  // Pola route detail yang akan didaftarkan pada GoRouter.
  static const customerStallDetail = '/customer/stalls/:stallId';
  static const customerOrderSuccess = '/customer/orders/:orderId/success';
  static const customerOrderDetail = '/customer/orders/:orderId';

  // Owner.
  static const ownerDashboard = '/owner/dashboard';
  static const ownerCanteen = '/owner/canteen';
  static const ownerOrders = '/owner/orders';
  static const ownerOrderDetail = '/owner/orders/:orderId';

  static String ownerOrderDetailLocation(String orderId) =>
      ownerOrderDetail.replaceFirst(':orderId', Uri.encodeComponent(orderId));
  static const ownerProfile = '/owner/profile';
  static const ownerStallSettings = '/owner/stall-settings';

  // Admin.
  static const adminDashboard = '/admin/dashboard';
  static const adminUsers = '/admin/users';
  static const adminUserDetail = '/admin/users/:userId';

  static String adminUserDetailLocation(String userId) =>
      adminUserDetail.replaceFirst(':userId', Uri.encodeComponent(userId));
  static const adminProfile = '/admin/profile';
  static const adminApplications = '/admin/applications';
  static const adminApplicationDetail = '/admin/applications/:applicationId';

  static String adminApplicationDetailLocation(String applicationId) =>
      adminApplicationDetail.replaceFirst(
        ':applicationId',
        Uri.encodeComponent(applicationId),
      );

  /// Membentuk alamat detail kantin menggunakan ID kantin.
  static String customerStallLocation(String stallId) {
    return customerStallDetail.replaceFirst(
      ':stallId',
      Uri.encodeComponent(stallId),
    );
  }

  static String customerOrderDetailLocation(String orderId) {
    return customerOrderDetail.replaceFirst(
      ':orderId',
      Uri.encodeComponent(orderId),
    );
  }

  /// Membentuk alamat keberhasilan pesanan menggunakan ID pesanan.
  static String customerOrderSuccessLocation(String orderId) {
    return customerOrderSuccess.replaceFirst(
      ':orderId',
      Uri.encodeComponent(orderId),
    );
  }
}
