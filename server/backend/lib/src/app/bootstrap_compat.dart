part of 'bootstrap.dart';

Handler buildAppHandlerWithAllModulesAndAi(
  AppConfig config, {
  EnvConfig? env,
  AiProviderConfig? aiConfig,
  NotificationsConfig? notificationsConfig,
  AuthGateway? authGateway,
  AvatarStore? avatarStore,
  CatalogStore? catalogStore,
  OwnerStore? ownerStore,
  OwnerMediaStore? ownerMediaStore,
  CustomerStore? customerStore,
  AdminStore? adminStore,
  AiStore? aiStore,
  AiProvider? aiProvider,
  NotificationStore? notificationStore,
  FcmTransport? fcmTransport,
  RealtimeBroadcaster? realtimeBroadcaster,
}) => buildAppHandler(
  config,
  env: env,
  aiConfig: aiConfig,
  notificationsConfig: notificationsConfig,
  authGateway: authGateway,
  avatarStore: avatarStore,
  catalogStore: catalogStore,
  ownerStore: ownerStore,
  ownerMediaStore: ownerMediaStore,
  customerStore: customerStore,
  adminStore: adminStore,
  aiStore: aiStore,
  aiProvider: aiProvider,
  notificationStore: notificationStore,
  fcmTransport: fcmTransport,
  realtimeBroadcaster: realtimeBroadcaster,
);

Handler buildAppHandlerWithOwner(
  AppConfig config, {
  AuthGateway? authGateway,
  AvatarStore? avatarStore,
  CatalogStore? catalogStore,
  OwnerStore? ownerStore,
  OwnerMediaStore? ownerMediaStore,
}) => buildAppHandler(
  config,
  authGateway: authGateway,
  avatarStore: avatarStore,
  catalogStore: catalogStore,
  ownerStore: ownerStore,
  ownerMediaStore: ownerMediaStore,
);

Handler buildAppHandlerWithCustomer(
  AppConfig config, {
  AuthGateway? authGateway,
  AvatarStore? avatarStore,
  CatalogStore? catalogStore,
  OwnerStore? ownerStore,
  OwnerMediaStore? ownerMediaStore,
  CustomerStore? customerStore,
}) => buildAppHandler(
  config,
  authGateway: authGateway,
  avatarStore: avatarStore,
  catalogStore: catalogStore,
  ownerStore: ownerStore,
  ownerMediaStore: ownerMediaStore,
  customerStore: customerStore,
);

Handler buildAppHandlerWithCustomerAndOwner(
  AppConfig config, {
  AuthGateway? authGateway,
  AvatarStore? avatarStore,
  CatalogStore? catalogStore,
  OwnerStore? ownerStore,
  OwnerMediaStore? ownerMediaStore,
  CustomerStore? customerStore,
}) => buildAppHandler(
  config,
  authGateway: authGateway,
  avatarStore: avatarStore,
  catalogStore: catalogStore,
  ownerStore: ownerStore,
  ownerMediaStore: ownerMediaStore,
  customerStore: customerStore,
);

Handler buildAppHandlerWithAdmin(
  AppConfig config, {
  AuthGateway? authGateway,
  AvatarStore? avatarStore,
  CatalogStore? catalogStore,
  OwnerStore? ownerStore,
  OwnerMediaStore? ownerMediaStore,
  CustomerStore? customerStore,
  AdminStore? adminStore,
}) => buildAppHandler(
  config,
  authGateway: authGateway,
  avatarStore: avatarStore,
  catalogStore: catalogStore,
  ownerStore: ownerStore,
  ownerMediaStore: ownerMediaStore,
  customerStore: customerStore,
  adminStore: adminStore,
);

Handler buildAppHandlerWithAllModules(
  AppConfig config, {
  AuthGateway? authGateway,
  AvatarStore? avatarStore,
  CatalogStore? catalogStore,
  OwnerStore? ownerStore,
  OwnerMediaStore? ownerMediaStore,
  CustomerStore? customerStore,
  AdminStore? adminStore,
}) => buildAppHandler(
  config,
  authGateway: authGateway,
  avatarStore: avatarStore,
  catalogStore: catalogStore,
  ownerStore: ownerStore,
  ownerMediaStore: ownerMediaStore,
  customerStore: customerStore,
  adminStore: adminStore,
);
