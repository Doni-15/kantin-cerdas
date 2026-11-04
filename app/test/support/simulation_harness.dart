import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'simulation/simulation.dart';
import 'simulation/simulation_overrides.dart';
import 'package:kantin_cerdas/core/settings/app_settings_provider.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_price_confirmation.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_catalog_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_checkout_journal_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_checkout_review_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/cart_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/controllers/customer_order_controller.dart';

export 'package:flutter_test/flutter_test.dart';
export 'package:flutter_riverpod/flutter_riverpod.dart';
export 'package:flutter/material.dart';
export 'simulation/simulation.dart';
export 'package:kantin_cerdas/kantin_cerdas_app.dart';
export 'package:kantin_cerdas/app/router/auth_redirect.dart';
export 'package:kantin_cerdas/app/router/auth_destination.dart';
export 'package:kantin_cerdas/app/router/routes.dart';
export 'package:kantin_cerdas/app/router/app_router.dart';
export 'package:kantin_cerdas/features/orders/domain/entities/order_record.dart';
export 'package:kantin_cerdas/features/orders/domain/validation/order_record_rules.dart';
export 'package:kantin_cerdas/features/auth/domain/enums/user_role.dart';
export 'package:kantin_cerdas/features/auth/domain/failures/auth_failure.dart';
export 'package:kantin_cerdas/features/auth/domain/repositories/auth_repository.dart';
export 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
export 'package:kantin_cerdas/features/auth/domain/validators/auth_validator.dart';
export 'package:kantin_cerdas/features/auth/domain/usecases/logout_usecase.dart';
export 'package:kantin_cerdas/features/auth/domain/usecases/restore_session_usecase.dart';
export 'package:kantin_cerdas/features/auth/domain/usecases/login_usecase.dart';
export 'package:kantin_cerdas/features/auth/domain/usecases/change_password_usecase.dart';
export 'package:kantin_cerdas/features/auth/domain/usecases/register_usecase.dart';
export 'package:kantin_cerdas/features/auth/domain/usecases/request_password_reset_usecase.dart';
export 'package:kantin_cerdas/features/auth/presentation/providers/auth_providers.dart';
export 'package:kantin_cerdas/features/auth/presentation/providers/register_draft_provider.dart';
export 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
export 'package:kantin_cerdas/features/admin/domain/failures/admin_failure.dart';
export 'package:kantin_cerdas/features/admin/domain/repositories/admin_repository.dart';
export 'package:kantin_cerdas/features/admin/domain/repositories/admin_mutation_journal.dart';
export 'package:kantin_cerdas/features/admin/domain/entities/admin_mutation_lookup.dart';
export 'package:kantin_cerdas/features/admin/domain/entities/admin_application_review.dart';
export 'package:kantin_cerdas/features/admin/domain/entities/pending_admin_mutation.dart';
export 'package:kantin_cerdas/features/admin/domain/entities/admin_user_record.dart';
export 'package:kantin_cerdas/features/admin/domain/entities/admin_application_page.dart';
export 'package:kantin_cerdas/features/admin/domain/entities/admin_user_page.dart';
export 'package:kantin_cerdas/features/admin/domain/entities/admin_summary.dart';
export 'package:kantin_cerdas/features/admin/domain/entities/admin_user_access_change.dart';
export 'package:kantin_cerdas/features/admin/presentation/providers/admin_read_session.dart';
export 'package:kantin_cerdas/features/admin/presentation/providers/admin_application_providers.dart';
export 'package:kantin_cerdas/features/admin/presentation/providers/admin_user_detail_provider.dart';
export 'package:kantin_cerdas/features/admin/presentation/providers/admin_mutation_journal_provider.dart';
export 'package:kantin_cerdas/features/admin/presentation/providers/admin_providers.dart';
export 'package:kantin_cerdas/features/owner/domain/failures/owner_order_detail_failure.dart';
export 'package:kantin_cerdas/features/owner/domain/failures/owner_failure.dart';
export 'package:kantin_cerdas/features/owner/domain/repositories/owner_mutation_journal.dart';
export 'package:kantin_cerdas/features/owner/domain/repositories/owner_repository.dart';
export 'package:kantin_cerdas/features/owner/domain/entities/pending_owner_mutation.dart';
export 'package:kantin_cerdas/features/owner/domain/entities/owner_mutation_lookup.dart';
export 'package:kantin_cerdas/features/owner/domain/entities/owner_menu.dart';
export 'package:kantin_cerdas/features/owner/domain/entities/owner_stall.dart';
export 'package:kantin_cerdas/features/owner/domain/entities/owner_order_transition.dart';
export 'package:kantin_cerdas/features/owner/presentation/providers/owner_mutation_journal_provider.dart';
export 'package:kantin_cerdas/features/owner/presentation/providers/owner_providers.dart';
export 'package:kantin_cerdas/features/owner/presentation/providers/owner_order_detail_provider.dart';
export 'package:kantin_cerdas/features/customer/domain/failures/customer_feature_failure.dart';
export 'package:kantin_cerdas/features/customer/domain/failures/customer_order_detail_failure.dart';
export 'package:kantin_cerdas/features/customer/domain/failures/customer_order_cancellation_failure.dart';
export 'package:kantin_cerdas/features/customer/domain/failures/canteen_application_failure.dart';
export 'package:kantin_cerdas/features/customer/domain/failures/customer_order_failure.dart';
export 'package:kantin_cerdas/features/customer/domain/failures/food_preferences_failure.dart';
export 'package:kantin_cerdas/features/customer/domain/failures/customer_catalog_failure.dart';
export 'package:kantin_cerdas/features/customer/domain/repositories/food_preferences_repository.dart';
export 'package:kantin_cerdas/features/customer/domain/repositories/order_submission_journal.dart';
export 'package:kantin_cerdas/features/customer/domain/repositories/customer_assistant_repository.dart';
export 'package:kantin_cerdas/features/customer/domain/repositories/customer_order_tracking_repository.dart';
export 'package:kantin_cerdas/features/customer/domain/repositories/food_preferences_journal.dart';
export 'package:kantin_cerdas/features/customer/domain/repositories/canteen_application_repository.dart';
export 'package:kantin_cerdas/features/customer/domain/repositories/canteen_application_journal.dart';
export 'package:kantin_cerdas/features/customer/domain/repositories/customer_order_repository.dart';
export 'package:kantin_cerdas/features/customer/domain/repositories/order_cancellation_journal.dart';
export 'package:kantin_cerdas/features/customer/domain/repositories/customer_catalog_repository.dart';
export 'package:kantin_cerdas/features/customer/domain/entities/food_preferences_snapshot.dart';
export 'package:kantin_cerdas/features/customer/domain/entities/pending_order_cancellation.dart';
export 'package:kantin_cerdas/features/customer/domain/entities/canteen_application.dart';
export 'package:kantin_cerdas/features/customer/domain/entities/order_submission_lookup.dart';
export 'package:kantin_cerdas/features/customer/domain/entities/pending_food_preferences.dart';
export 'package:kantin_cerdas/features/customer/domain/entities/customer_order_cancellation.dart';
export 'package:kantin_cerdas/features/customer/domain/entities/assistant_reply.dart';
export 'package:kantin_cerdas/features/customer/domain/entities/food_preferences_lookup.dart';
export 'package:kantin_cerdas/features/customer/domain/entities/cart_state.dart';
export 'package:kantin_cerdas/features/customer/domain/entities/order_draft.dart';
export 'package:kantin_cerdas/features/customer/domain/entities/stall.dart';
export 'package:kantin_cerdas/features/customer/domain/entities/cart_item.dart';
export 'package:kantin_cerdas/features/customer/domain/entities/customer_catalog.dart';
export 'package:kantin_cerdas/features/customer/domain/entities/order_cancellation_lookup.dart';
export 'package:kantin_cerdas/features/customer/domain/entities/customer_order_price_confirmation.dart';
export 'package:kantin_cerdas/features/customer/domain/entities/food_preferences.dart';
export 'package:kantin_cerdas/features/customer/domain/entities/menu_item.dart';
export 'package:kantin_cerdas/features/customer/domain/entities/pending_canteen_application.dart';
export 'package:kantin_cerdas/features/customer/domain/entities/canteen_application_lookup.dart';
export 'package:kantin_cerdas/features/customer/domain/entities/pending_order_submission.dart';
export 'package:kantin_cerdas/features/customer/domain/usecases/get_customer_catalog.dart';
export 'package:kantin_cerdas/features/customer/domain/usecases/create_customer_order.dart';
export 'package:kantin_cerdas/features/customer/domain/validation/customer_input_limits.dart';
export 'package:kantin_cerdas/features/customer/presentation/providers/customer_catalog_provider.dart';
export 'package:kantin_cerdas/features/customer/presentation/providers/customer_order_detail_provider.dart';
export 'package:kantin_cerdas/features/customer/presentation/providers/customer_read_session.dart';
export 'package:kantin_cerdas/features/customer/presentation/providers/customer_order_providers.dart';
export 'package:kantin_cerdas/features/customer/presentation/providers/food_preferences_journal_provider.dart';
export 'package:kantin_cerdas/features/customer/presentation/providers/cart_provider.dart';
export 'package:kantin_cerdas/features/customer/presentation/providers/canteen_application_journal_provider.dart';
export 'package:kantin_cerdas/features/customer/presentation/providers/food_preferences_provider.dart';
export 'package:kantin_cerdas/features/customer/presentation/providers/customer_checkout_review_provider.dart';
export 'package:kantin_cerdas/features/customer/presentation/providers/customer_checkout_journal_provider.dart';
export 'package:kantin_cerdas/features/customer/presentation/providers/order_cancellation_journal_provider.dart';
export 'package:kantin_cerdas/features/customer/presentation/providers/customer_feature_providers.dart';
export 'package:kantin_cerdas/features/customer/presentation/controllers/customer_order_controller.dart';

class TestSettings extends AppSettingsController {
  @override
  AppSettings build() => const AppSettings(themeMode: ThemeMode.light);
}

class SimulationHarness {
  SimulationHarness(this.store, this.container);
  final SimulationStore store;
  final ProviderContainer container;
  void dispose() => container.dispose();
  Future<void> login(String username) async {
    await container.read(authStateProvider.notifier).logout();
    await container
        .read(authStateProvider.notifier)
        .login(identifier: username, password: 'Simulasi123!');
  }

  Future<void> restoreCheckoutJournal() async {
    final id = container.read(authStateProvider).asData!.value!.id;
    container.listen(customerCheckoutJournalProvider(id), (_, _) {});
    await container
        .read(customerCheckoutJournalProvider(id).future)
        .timeout(const Duration(seconds: 3));
  }

  Future<CustomerOrderPriceConfirmation> cart() async {
    final id = container.read(authStateProvider).asData!.value!.id;
    container.listen(customerCatalogProvider, (_, _) {});
    container.listen(customerCheckoutJournalProvider(id), (_, _) {});
    final catalog = await container.read(customerCatalogProvider.future);
    await container.read(customerCheckoutJournalProvider(id).future);
    final added = container
        .read(cartProvider.notifier)
        .addItem(catalog.menuById('menu-0-0')!);
    if (!added) {
      throw StateError('Keranjang fixture gagal.');
    }
    await container.read(customerOrderControllerProvider.future);
    // Keep read<T> nullable and independent of the async return context.
    final confirmation = container.read<CustomerOrderPriceConfirmation?>(
      customerCheckoutReviewProvider,
    );
    if (confirmation == null) {
      throw StateError('Snapshot konfirmasi fixture belum tersedia.');
    }
    return confirmation;
  }
}

Future<SimulationHarness> createHarness({String username = 'pelanggan'}) async {
  final store = SimulationStore.memory();
  await SimulationAuthRepository(
    store,
  ).login(identifier: username, password: 'Simulasi123!');
  final container = ProviderContainer(
    overrides: [
      ...simulationOverrides(store),
      appSettingsProvider.overrideWith(TestSettings.new),
    ],
  );
  final ready = Completer<void>();
  container.listen<AsyncValue<User?>>(authStateProvider, (_, state) {
    if (!state.isLoading && !ready.isCompleted) {
      if (state.hasError) {
        ready.completeError(state.error!, state.stackTrace);
      } else {
        ready.complete();
      }
    }
  }, fireImmediately: true);
  await ready.future.timeout(const Duration(seconds: 3));
  return SimulationHarness(store, container);
}
