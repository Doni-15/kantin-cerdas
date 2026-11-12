part of 'simulation.dart';

typedef Json = Map<String, dynamic>;
Json asJson(Object? value) => Map<String, dynamic>.from(value as Map);

User unpackUser(Json j) => User(
  id: j['id'] as String,
  username: j['username'] as String,
  email: j['email'] as String,
  name: j['name'] as String,
  role: UserRole.values.byName(j['role'] as String),
  isActive: j['isActive'] as bool,
  avatarUrl: j['avatarUrl'] == null ? null : j['avatarUrl'] as String,
);
Json packUser(User v) => {
  'id': v.id,
  'username': v.username,
  'email': v.email,
  'name': v.name,
  'role': v.role.name,
  'isActive': v.isActive,
  'avatarUrl': v.avatarUrl,
};

AdminUserRecord unpackAdminUserRecord(Json j) => AdminUserRecord(
  user: unpackUser(asJson(j['user'])),
  version: j['version'] as int,
);
Json packAdminUserRecord(AdminUserRecord v) => {
  'user': packUser(v.user),
  'version': v.version,
};

OwnerStall unpackOwnerStall(Json j) => OwnerStall(
  id: j['id'] as String,
  ownerId: j['ownerId'] as String,
  name: j['name'] as String,
  block: j['block'] as String,
  description: j['description'] as String,
  isOpen: j['isOpen'] as bool,
  prepTimeMin: j['prepTimeMin'] as int,
  version: j['version'] as int,
  imageUrl: j['imageUrl'] == null ? null : j['imageUrl'] as String,
);
Json packOwnerStall(OwnerStall v) => {
  'id': v.id,
  'ownerId': v.ownerId,
  'name': v.name,
  'block': v.block,
  'description': v.description,
  'isOpen': v.isOpen,
  'prepTimeMin': v.prepTimeMin,
  'version': v.version,
  'imageUrl': v.imageUrl,
};

OwnerMenu unpackOwnerMenu(Json j) => OwnerMenu(
  id: j['id'] as String,
  stallId: j['stallId'] as String,
  name: j['name'] as String,
  description: j['description'] as String,
  category: OwnerMenuCategory.values.byName(j['category'] as String),
  priceIdr: j['priceIdr'] as int,
  isAvailable: j['isAvailable'] as bool,
  version: j['version'] as int,
  imageUrl: j['imageUrl'] == null ? null : j['imageUrl'] as String,
);
Json packOwnerMenu(OwnerMenu v) => {
  'id': v.id,
  'stallId': v.stallId,
  'name': v.name,
  'description': v.description,
  'category': v.category.name,
  'priceIdr': v.priceIdr,
  'isAvailable': v.isAvailable,
  'version': v.version,
  'imageUrl': v.imageUrl,
};

OrderLine unpackOrderLine(Json j) => OrderLine(
  menuId: j['menuId'] as String,
  name: j['name'] as String,
  quantity: j['quantity'] as int,
  unitPriceIdr: j['unitPriceIdr'] as int,
  note: j['note'] as String,
);
Json packOrderLine(OrderLine v) => {
  'menuId': v.menuId,
  'name': v.name,
  'quantity': v.quantity,
  'unitPriceIdr': v.unitPriceIdr,
  'note': v.note,
};

OrderRecord unpackOrderRecord(Json j) => OrderRecord(
  id: j['id'] as String,
  orderNumber: j['orderNumber'] as String,
  customerId: j['customerId'] as String,
  customerName: j['customerName'] as String,
  stallId: j['stallId'] as String,
  stallName: j['stallName'] as String,
  items: (j['items'] as List).map((e) => unpackOrderLine(asJson(e))).toList(),
  status: OrderStatus.values.byName(j['status'] as String),
  paymentStatus: OrderPaymentStatus.values.byName(j['paymentStatus'] as String),
  totalPriceIdr: j['totalPriceIdr'] as int,
  note: j['note'] as String,
  createdAt: DateTime.parse(j['createdAt'] as String),
  updatedAt: DateTime.parse(j['updatedAt'] as String),
  version: j['version'] as int,
  rejectionReason: j['rejectionReason'] == null
      ? null
      : j['rejectionReason'] as String,
);
Json packOrderRecord(OrderRecord v) => {
  'id': v.id,
  'orderNumber': v.orderNumber,
  'customerId': v.customerId,
  'customerName': v.customerName,
  'stallId': v.stallId,
  'stallName': v.stallName,
  'items': v.items.map((e) => packOrderLine(e)).toList(),
  'status': v.status.name,
  'paymentStatus': v.paymentStatus.name,
  'totalPriceIdr': v.totalPriceIdr,
  'note': v.note,
  'createdAt': v.createdAt.toIso8601String(),
  'updatedAt': v.updatedAt.toIso8601String(),
  'version': v.version,
  'rejectionReason': v.rejectionReason,
};

CanteenApplicationDraft unpackCanteenApplicationDraft(Json j) =>
    CanteenApplicationDraft(
      name: j['name'] as String,
      description: j['description'] as String,
      location: j['location'] as String,
      phone: j['phone'] as String,
    );
Json packCanteenApplicationDraft(CanteenApplicationDraft v) => {
  'name': v.name,
  'description': v.description,
  'location': v.location,
  'phone': v.phone,
};

CanteenApplication unpackCanteenApplication(Json j) => CanteenApplication(
  id: j['id'] as String,
  applicantId: j['applicantId'] as String,
  name: j['name'] as String,
  description: j['description'] as String,
  location: j['location'] as String,
  phone: j['phone'] as String,
  status: CanteenApplicationStatus.values.byName(j['status'] as String),
  createdAt: DateTime.parse(j['createdAt'] as String),
  version: j['version'] as int,
  reason: j['reason'] == null ? null : j['reason'] as String,
);
Json packCanteenApplication(CanteenApplication v) => {
  'id': v.id,
  'applicantId': v.applicantId,
  'name': v.name,
  'description': v.description,
  'location': v.location,
  'phone': v.phone,
  'status': v.status.name,
  'createdAt': v.createdAt.toIso8601String(),
  'version': v.version,
  'reason': v.reason,
};

FoodPreferences unpackFoodPreferences(Json j) => FoodPreferences(
  maxBudgetIdr: j['maxBudgetIdr'] == null ? null : j['maxBudgetIdr'] as int,
  vegetarian: j['vegetarian'] as bool,
  avoidIngredients: (j['avoidIngredients'] as List)
      .map((e) => e as String)
      .toList(),
);
Json packFoodPreferences(FoodPreferences v) => {
  'maxBudgetIdr': v.maxBudgetIdr,
  'vegetarian': v.vegetarian,
  'avoidIngredients': v.avoidIngredients.map((e) => e).toList(),
};

FoodPreferencesSnapshot unpackFoodPreferencesSnapshot(Json j) =>
    FoodPreferencesSnapshot(
      customerId: j['customerId'] as String,
      version: j['version'] as int,
      preferences: unpackFoodPreferences(asJson(j['preferences'])),
    );
Json packFoodPreferencesSnapshot(FoodPreferencesSnapshot v) => {
  'customerId': v.customerId,
  'version': v.version,
  'preferences': packFoodPreferences(v.preferences),
};

FoodPreferencesUpdate unpackFoodPreferencesUpdate(Json j) =>
    FoodPreferencesUpdate(
      preferences: unpackFoodPreferences(asJson(j['preferences'])),
      expectedVersion: j['expectedVersion'] == null
          ? null
          : j['expectedVersion'] as int,
    );
Json packFoodPreferencesUpdate(FoodPreferencesUpdate v) => {
  'preferences': packFoodPreferences(v.preferences),
  'expectedVersion': v.expectedVersion,
};

CustomerOrderCancellation unpackCustomerOrderCancellation(Json j) =>
    CustomerOrderCancellation(
      orderId: j['orderId'] as String,
      expectedVersion: j['expectedVersion'] as int,
    );
Json packCustomerOrderCancellation(CustomerOrderCancellation v) => {
  'orderId': v.orderId,
  'expectedVersion': v.expectedVersion,
};

PendingOrderCancellation unpackPendingOrderCancellation(Json j) =>
    PendingOrderCancellation(
      customerId: j['customerId'] as String,
      mutationId: j['mutationId'] as String,
      stallId: j['stallId'] as String,
      orderNumber: j['orderNumber'] as String,
      input: unpackCustomerOrderCancellation(asJson(j['input'])),
    );
Json packPendingOrderCancellation(PendingOrderCancellation v) => {
  'customerId': v.customerId,
  'mutationId': v.mutationId,
  'stallId': v.stallId,
  'orderNumber': v.orderNumber,
  'input': packCustomerOrderCancellation(v.input),
};

PendingFoodPreferences unpackPendingFoodPreferences(Json j) =>
    PendingFoodPreferences(
      customerId: j['customerId'] as String,
      mutationId: j['mutationId'] as String,
      update: unpackFoodPreferencesUpdate(asJson(j['update'])),
    );
Json packPendingFoodPreferences(PendingFoodPreferences v) => {
  'customerId': v.customerId,
  'mutationId': v.mutationId,
  'update': packFoodPreferencesUpdate(v.update),
};

PendingOwnerMutation unpackPendingOwnerMutation(Json j) => PendingOwnerMutation(
  ownerId: j['ownerId'] as String,
  mutationId: j['mutationId'] as String,
  stallId: j['stallId'] as String,
  kind: OwnerMutationKind.values.byName(j['kind'] as String),
  targetId: j['targetId'] == null ? null : j['targetId'] as String,
  expectedVersion: j['expectedVersion'] == null
      ? null
      : j['expectedVersion'] as int,
  orderStatus: j['orderStatus'] == null
      ? null
      : OrderStatus.values.byName(j['orderStatus'] as String),
);
Json packPendingOwnerMutation(PendingOwnerMutation v) => {
  'ownerId': v.ownerId,
  'mutationId': v.mutationId,
  'stallId': v.stallId,
  'kind': v.kind.name,
  'targetId': v.targetId,
  'expectedVersion': v.expectedVersion,
  'orderStatus': v.orderStatus?.name,
};

PendingAdminMutation unpackPendingAdminMutation(Json j) => PendingAdminMutation(
  adminId: j['adminId'] as String,
  mutationId: j['mutationId'] as String,
  kind: AdminMutationKind.values.byName(j['kind'] as String),
  targetId: j['targetId'] as String,
  expectedVersion: j['expectedVersion'] as int,
  decision: j['decision'] == null
      ? null
      : CanteenApplicationStatus.values.byName(j['decision'] as String),
  applicantId: j['applicantId'] == null ? null : j['applicantId'] as String,
  isActive: j['isActive'] == null ? null : j['isActive'] as bool,
  targetRole: j['targetRole'] == null
      ? null
      : UserRole.values.byName(j['targetRole'] as String),
  reason: j['reason'] as String,
);
Json packPendingAdminMutation(PendingAdminMutation v) => {
  'adminId': v.adminId,
  'mutationId': v.mutationId,
  'kind': v.kind.name,
  'targetId': v.targetId,
  'expectedVersion': v.expectedVersion,
  'decision': v.decision?.name,
  'applicantId': v.applicantId,
  'isActive': v.isActive,
  'targetRole': v.targetRole?.name,
  'reason': v.reason,
};

PendingCanteenApplication unpackPendingCanteenApplication(Json j) =>
    PendingCanteenApplication(
      customerId: j['customerId'] as String,
      submissionId: j['submissionId'] as String,
      draft: unpackCanteenApplicationDraft(asJson(j['draft'])),
      previousId: j['previousId'] == null ? null : j['previousId'] as String,
      previousVersion: j['previousVersion'] == null
          ? null
          : j['previousVersion'] as int,
    );
Json packPendingCanteenApplication(PendingCanteenApplication v) => {
  'customerId': v.customerId,
  'submissionId': v.submissionId,
  'draft': packCanteenApplicationDraft(v.draft),
  'previousId': v.previousId,
  'previousVersion': v.previousVersion,
};

OwnerMutationLookup unpackOwnerMutationLookup(Json j) => OwnerMutationLookup(
  request: unpackPendingOwnerMutation(asJson(j['request'])),
  outcome: OwnerMutationOutcome.values.byName(j['outcome'] as String),
  resultId: j['resultId'] == null ? null : j['resultId'] as String,
  resultVersion: j['resultVersion'] == null ? null : j['resultVersion'] as int,
  orderStatus: j['orderStatus'] == null
      ? null
      : OrderStatus.values.byName(j['orderStatus'] as String),
  paymentStatus: j['paymentStatus'] == null
      ? null
      : OrderPaymentStatus.values.byName(j['paymentStatus'] as String),
);
Json packOwnerMutationLookup(OwnerMutationLookup v) => {
  'request': packPendingOwnerMutation(v.request),
  'outcome': v.outcome.name,
  'resultId': v.resultId,
  'resultVersion': v.resultVersion,
  'orderStatus': v.orderStatus?.name,
  'paymentStatus': v.paymentStatus?.name,
};

AdminMutationLookup unpackAdminMutationLookup(Json j) => AdminMutationLookup(
  request: unpackPendingAdminMutation(asJson(j['request'])),
  outcome: AdminMutationOutcome.values.byName(j['outcome'] as String),
  resultVersion: j['resultVersion'] == null ? null : j['resultVersion'] as int,
  decision: j['decision'] == null
      ? null
      : CanteenApplicationStatus.values.byName(j['decision'] as String),
  isActive: j['isActive'] == null ? null : j['isActive'] as bool,
  resultRole: j['resultRole'] == null
      ? null
      : UserRole.values.byName(j['resultRole'] as String),
  approvedStallId: j['approvedStallId'] == null
      ? null
      : j['approvedStallId'] as String,
);
Json packAdminMutationLookup(AdminMutationLookup v) => {
  'request': packPendingAdminMutation(v.request),
  'outcome': v.outcome.name,
  'resultVersion': v.resultVersion,
  'decision': v.decision?.name,
  'isActive': v.isActive,
  'resultRole': v.resultRole?.name,
  'approvedStallId': v.approvedStallId,
};

OrderCancellationLookup unpackOrderCancellationLookup(Json j) =>
    OrderCancellationLookup(
      request: unpackPendingOrderCancellation(asJson(j['request'])),
      outcome: OrderCancellationOutcome.values.byName(j['outcome'] as String),
      resultVersion: j['resultVersion'] == null
          ? null
          : j['resultVersion'] as int,
      status: j['status'] == null
          ? null
          : OrderStatus.values.byName(j['status'] as String),
      paymentStatus: j['paymentStatus'] == null
          ? null
          : OrderPaymentStatus.values.byName(j['paymentStatus'] as String),
    );
Json packOrderCancellationLookup(OrderCancellationLookup v) => {
  'request': packPendingOrderCancellation(v.request),
  'outcome': v.outcome.name,
  'resultVersion': v.resultVersion,
  'status': v.status?.name,
  'paymentStatus': v.paymentStatus?.name,
};

FoodPreferencesLookup unpackFoodPreferencesLookup(Json j) =>
    FoodPreferencesLookup(
      request: unpackPendingFoodPreferences(asJson(j['request'])),
      outcome: FoodPreferencesOutcome.values.byName(j['outcome'] as String),
      snapshot: j['snapshot'] == null
          ? null
          : unpackFoodPreferencesSnapshot(asJson(j['snapshot'])),
    );
Json packFoodPreferencesLookup(FoodPreferencesLookup v) => {
  'request': packPendingFoodPreferences(v.request),
  'outcome': v.outcome.name,
  'snapshot': v.snapshot == null
      ? null
      : packFoodPreferencesSnapshot(v.snapshot!),
};
