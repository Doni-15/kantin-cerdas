enum UserRole {
  customer,
  owner,
  admin;

  static UserRole? tryFromRaw(String? raw) {
    return switch (raw?.trim().toLowerCase()) {
      'customer' => UserRole.customer,
      'owner' => UserRole.owner,
      'admin' => UserRole.admin,
      _ => null,
    };
  }
}

/// Owner retains personal customer features; admin never inherits them.
extension UserRoleCapabilities on UserRole {
  bool get canUseCustomerFeatures =>
      this == UserRole.customer || this == UserRole.owner;
  bool allows(UserRole requiredRole) =>
      this == requiredRole ||
      (requiredRole == UserRole.customer && canUseCustomerFeatures);
}
