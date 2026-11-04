# Kamus entity aktual

Deklarasi class/enum/field diambil dari source terkini (`app/lib/`); snippet merangkum field domain sedangkan model serialisasi JSON (`fromJson`/`toJson`) berada di `app/lib/features/*/data/models/`. Constructor, getter dan validasi tetap dibaca pada source. Constraint bisnis dan endpoint ada di [spesifikasi strict](SPESIFIKASI_BACKEND.md).

Pemetaan utama: `MenuItem.price` ↔ `price_idr` server, `available` ↔ `is_available`; kategori menu menggunakan standar tunggal `MenuCategory` (`rice`/`Nasi`, `noodles`/`Mi`, `drinks`/`Minuman`, `snacks`/`Camilan`, `other`/`Lainnya` di `features/orders/domain/entities/menu_category.dart`); `waitTime` teks diturunkan bila server mengirim `prep_time_min`; `OrderDraft.orderNote` → `OrderRecord.note`. `User` tidak menyimpan versi (versi pengguna untuk CAS admin dibungkus pada `AdminUserRecord`).

## admin_application_page

[Source](../../app/lib/features/admin/domain/entities/admin_application_page.dart)

```dart
class AdminApplicationPage {
final List<CanteenApplication> items;
final String? nextCursor;
```

## admin_application_review

[Source](../../app/lib/features/admin/domain/entities/admin_application_review.dart)

```dart
class AdminApplicationReview {
final String applicationId;
final int expectedVersion;
final CanteenApplicationStatus status;
final String? reason;
```

## admin_mutation_lookup

[Source](../../app/lib/features/admin/domain/entities/admin_mutation_lookup.dart)

```dart
enum AdminMutationOutcome { pending, applied, notApplied }
class AdminMutationLookup {
final PendingAdminMutation request;
final AdminMutationOutcome outcome;
final int? resultVersion;
final CanteenApplicationStatus? decision;
final bool? isActive;
final UserRole? resultRole;
final String? approvedStallId;
```

## admin_summary

[Source](../../app/lib/features/admin/domain/entities/admin_summary.dart)

```dart
class AdminSummary {
final int users;
final int stalls;
final int openStalls;
final int pendingApplications;
final int activeOrders;
```

## admin_user_access_change

[Source](../../app/lib/features/admin/domain/entities/admin_user_access_change.dart)

```dart
class AdminUserAccessChange {
final String userId;
final int expectedVersion;
final bool isActive;
final String reason;
```

## admin_user_page

[Source](../../app/lib/features/admin/domain/entities/admin_user_page.dart)

```dart
class AdminUserPage {
final List<User> users;
final String? nextCursor;
```

## admin_user_record

[Source](../../app/lib/features/admin/domain/entities/admin_user_record.dart)

```dart
class AdminUserRecord {
final User user;
final int version;
```

## pending_admin_mutation

[Source](../../app/lib/features/admin/domain/entities/pending_admin_mutation.dart)

```dart
enum AdminMutationKind { reviewApplication, changeAccess }
class PendingAdminMutation {
final String adminId;
final String mutationId;
final AdminMutationKind kind;
final String targetId;
final int expectedVersion;
final CanteenApplicationStatus? decision;
final String? applicantId;
final bool? isActive;
final UserRole? targetRole;
final String reason;
```

## user (session_user)

[Source definisi](../../app/lib/core/session/session_user.dart) · [Re-export fitur auth](../../app/lib/features/auth/domain/entities/user.dart)

```dart
enum UserRole { customer, owner, admin }
class User {
final String id;
final String username;
final String email;
final String name;
final UserRole role;
final bool isActive;
final String? avatarUrl;
```

## media_upload (Zero-Trust image validation)

[Source kategori](../../app/lib/core/media/media_upload_category.dart) · [Source validator](../../app/lib/core/media/image_security_validator.dart)

```dart
enum MediaUploadCategory {
  profileAvatar('profile_avatar'),
  menuPhoto('menu_photo'),
  stallPhoto('stall_photo');
}
class ValidatedUploadImage {
final Uint8List bytes;
final String mimeType;
final String extension;
final String safeFileName;
final MediaUploadCategory category;
```

## assistant_reply

[Source](../../app/lib/features/customer/domain/entities/assistant_reply.dart)

```dart
class AssistantReply {
final String message;
final List<MenuItem> menus;
```

## canteen_application

[Source definisi](../../app/lib/core/domain/entities/canteen_application.dart) · [Re-export fitur customer](../../app/lib/features/customer/domain/entities/canteen_application.dart)

```dart
enum CanteenApplicationStatus { submitted, reviewing, approved, rejected }
class CanteenApplicationDraft {
final String name;
final String description;
final String location;
final String phone;
class CanteenApplication {
final String id;
final String applicantId;
final String name;
final String description;
final String location;
final String phone;
final CanteenApplicationStatus status;
final DateTime createdAt;
final int version;
final String? reason;
```

## canteen_application_lookup

[Source](../../app/lib/features/customer/domain/entities/canteen_application_lookup.dart)

```dart
enum CanteenApplicationSubmissionStatus { pending, submitted, notSubmitted }
class CanteenApplicationLookup {
final String customerId;
final String submissionId;
final CanteenApplicationSubmissionStatus status;
final CanteenApplication? receipt;
```

## cart_item

[Source](../../app/lib/features/customer/domain/entities/cart_item.dart)

```dart
class CartItem {
final MenuItem menu;
final int quantity;
final String note;
```

## cart_state

[Source](../../app/lib/features/customer/domain/entities/cart_state.dart)

```dart
class CartState {
final List<CartItem> items;
final String orderNote;
```

## customer_catalog

[Source](../../app/lib/features/customer/domain/entities/customer_catalog.dart)

```dart
class CustomerCatalog {
final List<MenuItem> menus;
final List<Stall> stalls;
final Map<String, MenuItem> _menusById;
final Map<String, Stall> _stallsById;
```

## customer_order_cancellation

[Source](../../app/lib/features/customer/domain/entities/customer_order_cancellation.dart)

```dart
class CustomerOrderCancellation {
final String orderId;
final int expectedVersion;
```

## customer_order_price_confirmation

[Source](../../app/lib/features/customer/domain/entities/customer_order_price_confirmation.dart)

```dart
enum CustomerOrderPaymentMethod { cashOnPickup }
class CustomerOrderPriceConfirmation {
final OrderDraft draft;
final Map<String, int> unitPricesIdr;
```

## food_preferences

[Source](../../app/lib/features/customer/domain/entities/food_preferences.dart)

```dart
class FoodPreferences {
final int? maxBudgetIdr;
final bool vegetarian;
final List<String> avoidIngredients;
```

## food_preferences_lookup

[Source](../../app/lib/features/customer/domain/entities/food_preferences_lookup.dart)

```dart
enum FoodPreferencesOutcome { pending, applied, notApplied }
class FoodPreferencesLookup {
final PendingFoodPreferences request;
final FoodPreferencesOutcome outcome;
final FoodPreferencesSnapshot? snapshot;
```

## food_preferences_snapshot

[Source](../../app/lib/features/customer/domain/entities/food_preferences_snapshot.dart)

```dart
class FoodPreferencesSnapshot {
final String customerId;
final int version;
final FoodPreferences preferences;
class FoodPreferencesUpdate {
final FoodPreferences preferences;
final int? expectedVersion;
```

## menu_item

[Source](../../app/lib/features/customer/domain/entities/menu_item.dart)

```dart
class MenuItem {
final String id;
final String name;
final String stallId;
final String stallName;
final String block;
final int price;
final String waitTime;
final String description;
final String category;
final bool available;
final String? imageUrl;
```

## order_cancellation_lookup

[Source](../../app/lib/features/customer/domain/entities/order_cancellation_lookup.dart)

```dart
enum OrderCancellationOutcome { pending, applied, notApplied }
class OrderCancellationLookup {
final PendingOrderCancellation request;
final OrderCancellationOutcome outcome;
final int? resultVersion;
final OrderStatus? status;
final OrderPaymentStatus? paymentStatus;
```

## order_draft

[Source](../../app/lib/features/customer/domain/entities/order_draft.dart)

```dart
class OrderDraftItem {
final String menuId;
final int quantity;
final String note;
class OrderDraft {
final String stallId;
final List<OrderDraftItem> items;
final String orderNote;
```

## order_submission_lookup

[Source](../../app/lib/features/customer/domain/entities/order_submission_lookup.dart)

```dart
enum OrderSubmissionStatus { pending, confirmed, notCreated }
class OrderSubmissionLookup {
final String customerId;
final String submissionId;
final OrderSubmissionStatus status;
final String? orderId;
```

## pending_canteen_application

[Source](../../app/lib/features/customer/domain/entities/pending_canteen_application.dart)

```dart
class PendingCanteenApplication {
final String customerId;
final String submissionId;
final CanteenApplicationDraft draft;
final String? previousId;
final int? previousVersion;
```

## pending_food_preferences

[Source](../../app/lib/features/customer/domain/entities/pending_food_preferences.dart)

```dart
class PendingFoodPreferences {
final String customerId;
final String mutationId;
final FoodPreferencesUpdate update;
```

## pending_order_cancellation

[Source](../../app/lib/features/customer/domain/entities/pending_order_cancellation.dart)

```dart
class PendingOrderCancellation {
final String customerId;
final String mutationId;
final String stallId;
final String orderNumber;
final CustomerOrderCancellation input;
```

## pending_order_submission

[Source](../../app/lib/features/customer/domain/entities/pending_order_submission.dart)

```dart
class PendingOrderSubmission {
final String customerId;
final String submissionId;
```

## stall

[Source](../../app/lib/features/customer/domain/entities/stall.dart)

```dart
class Stall {
final String id;
final String name;
final String block;
final String waitTime;
final String description;
final List<MenuItem> menus;
final bool isOpen;
final String? imageUrl;
```

## order_record

[Source](../../app/lib/features/orders/domain/entities/order_record.dart)

```dart
enum OrderStatus { waiting, processing, ready, completed, rejected, cancelled }
enum OrderPaymentStatus { unpaid, paid, notCharged }
class OrderLine {
final String menuId;
final String name;
final int quantity;
final int unitPriceIdr;
final String note;
class OrderRecord {
final String id;
final String orderNumber;
final String customerId;
final String customerName;
final String stallId;
final String stallName;
final List<OrderLine> items;
final OrderStatus status;
final OrderPaymentStatus paymentStatus;
final int totalPriceIdr;
final String note;
final DateTime createdAt;
final DateTime updatedAt;
final int version;
final String? rejectionReason;
class OrderRecordPage {
final List<OrderRecord> items;
final String? nextCursor;
```

## menu_category

[Source](../../app/lib/features/orders/domain/entities/menu_category.dart)

```dart
enum MenuCategory {
  rice('Nasi'),
  noodles('Mi'),
  drinks('Minuman'),
  snacks('Camilan'),
  other('Lainnya');
}
```

## owner_menu

[Source](../../app/lib/features/owner/domain/entities/owner_menu.dart)

```dart
enum MenuCategory { rice, noodles, drinks, snacks, other }
class OwnerMenu {
final String id;
final String stallId;
final String name;
final String description;
final MenuCategory category;
final int priceIdr;
final bool isAvailable;
final int version;
final String? imageUrl;
class OwnerMenuInput {
final String? id;
final String stallId;
final String name;
final String description;
final MenuCategory category;
final int priceIdr;
final bool isAvailable;
final int? expectedVersion;
final String? imageUrl;
class OwnerMenuPage {
final List<OwnerMenu> items;
final String? nextCursor;
```

## owner_mutation_lookup

[Source](../../app/lib/features/owner/domain/entities/owner_mutation_lookup.dart)

```dart
enum OwnerMutationOutcome { pending, applied, notApplied }
class OwnerMutationLookup {
final PendingOwnerMutation request;
final OwnerMutationOutcome outcome;
final String? resultId;
final int? resultVersion;
final OrderStatus? orderStatus;
final OrderPaymentStatus? paymentStatus;
```

## owner_order_transition

[Source](../../app/lib/features/owner/domain/entities/owner_order_transition.dart)

```dart
class OwnerOrderTransition {
final String orderId;
final OrderStatus status;
final int expectedVersion;
final String reason;
final bool cashReceived;
final bool foodHandedOver;
```

## owner_stall

[Source](../../app/lib/features/owner/domain/entities/owner_stall.dart)

```dart
class OwnerStall {
final String id;
final String ownerId;
final String name;
final String block;
final String description;
final bool isOpen;
final int prepTimeMin;
final int version;
final String? imageUrl;
class OwnerStallInput {
final String id;
final String name;
final String block;
final String description;
final bool isOpen;
final int prepTimeMin;
final int expectedVersion;
final String? imageUrl;
```

## pending_owner_mutation

[Source](../../app/lib/features/owner/domain/entities/pending_owner_mutation.dart)

```dart
enum OwnerMutationKind { saveMenu, deleteMenu, saveStall, transitionOrder }
class PendingOwnerMutation {
final String ownerId;
final String mutationId;
final String stallId;
final OwnerMutationKind kind;
final String? targetId;
final int? expectedVersion;
final OrderStatus? orderStatus;
```
