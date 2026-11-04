import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/session/shared_data_revision_provider.dart';
import 'package:kantin_cerdas/core/utils/mutation_id_generator.dart';
import 'package:kantin_cerdas/features/auth/domain/entities/user.dart';
import 'package:kantin_cerdas/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_price_confirmation.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_draft.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_submission_lookup.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/pending_order_submission.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_order_failure.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/cart_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_catalog_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_checkout_journal_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_checkout_review_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_feature_providers.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_order_detail_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_order_providers.dart';

final customerOrderControllerProvider =
    AsyncNotifierProvider<CustomerOrderController, String?>(
      CustomerOrderController.new,
      retry: (_, _) => null,
    );

class CustomerOrderController extends AsyncNotifier<String?> {
  String? _customerId;
  int _generation = 0;
  AuthStateNotifier? _session;
  int _sessionGeneration = -1;
  final Set<String> _inFlight = {};
  static const _requestLimit = Duration(seconds: 45);

  @override
  String? build() {
    _generation++;
    _session = ref.read(authStateProvider.notifier);
    _sessionGeneration = _session!.sessionGeneration;
    _customerId = ref.read(authStateProvider).activeCustomerId;
    ref.listen<AsyncValue<User?>>(authStateProvider, (_, next) {
      if (!ref.mounted) {
        return;
      }
      final id = next.activeCustomerId;
      final session = ref.read(authStateProvider.notifier);
      if (id == _customerId &&
          identical(session, _session) &&
          session.sessionGeneration == _sessionGeneration) {
        return;
      }
      _generation++;
      _session = session;
      _sessionGeneration = session.sessionGeneration;
      _customerId = id;
      state = id != null && _inFlight.contains(id)
          ? const AsyncLoading<String?>()
          : const AsyncData<String?>(null);
    });
    return null;
  }

  /// Aksi eksplisit dengan snapshot harga yang ditampilkan pada tombol.
  /// Adapter harus dikonfigurasi; tidak dipanggil saat build/restore.
  Future<String?> submit({
    required CustomerOrderPriceConfirmation confirmation,
  }) async {
    if (!ref.mounted) {
      return null;
    }
    final customerId = ref.read(authStateProvider).activeCustomerId;
    if (customerId == null ||
        customerId != _customerId ||
        _inFlight.contains(customerId)) {
      return null;
    }
    if (!ref.read(customerCheckoutConfiguredProvider)) {
      state = AsyncError(
        const CustomerOrderNotConfiguredFailure(),
        StackTrace.current,
      );
      return null;
    }
    if (ref.read(customerCheckoutReviewProvider) != confirmation) {
      state = AsyncError(
        const CustomerOrderCatalogChangedFailure(),
        StackTrace.current,
      );
      return null;
    }
    final persisted = ref.read(customerCheckoutJournalProvider(customerId));
    if (persisted.isLoading || persisted.hasError || persisted.asData == null) {
      state = AsyncError(
        const CustomerOrderLocalStorageFailure(),
        StackTrace.current,
      );
      return null;
    }
    if (persisted.asData!.value != null) {
      state = AsyncError(
        const CustomerOrderUnconfirmedFailure(),
        StackTrace.current,
      );
      return null;
    }
    final cart = ref.read(cartProvider);
    final loaded = ref.read(customerCatalogProvider);
    final catalog = loaded.isLoading || loaded.hasError
        ? null
        : loaded.asData?.value;
    if (cart.isEmpty ||
        catalog == null ||
        cart.items.any((item) => !catalog.canOrder(item.menu.id))) {
      state = AsyncError(
        const CustomerOrderCatalogChangedFailure(),
        StackTrace.current,
      );
      return null;
    }
    final draft = OrderDraft.fromCart(cart);
    if (!confirmation.matchesDraft(draft)) {
      state = AsyncError(
        const CustomerOrderCatalogChangedFailure(),
        StackTrace.current,
      );
      return null;
    }
    final useCase = ref.read(createCustomerOrderUseCaseProvider);
    final journal = ref.read(
      customerCheckoutJournalProvider(customerId).notifier,
    );
    final generation = _generation;
    _inFlight.add(customerId);
    state = const AsyncLoading<String?>();
    String? submissionId;
    bool saved = false;
    bool dispatched = false;
    try {
      submissionId = generateSecureMutationId();
      saved = await journal.begin(
        PendingOrderSubmission(
          customerId: customerId,
          submissionId: submissionId,
        ),
      );
      if (!saved) {
        _error(
          customerId,
          generation,
          const CustomerOrderLocalStorageFailure(),
        );
        return null;
      }
      if (!_current(customerId, generation)) {
        await journal.finish(submissionId);
        return null;
      }
      // begin sudah mengunci cart. Tolak snapshot yang berubah saat write lokal.
      if (!ref.read(customerCheckoutConfiguredProvider)) {
        throw const CustomerOrderNotConfiguredFailure();
      }
      if (ref.read(cartProvider) != cart ||
          ref.read(customerCheckoutReviewProvider) != confirmation) {
        throw const CustomerOrderCatalogChangedFailure();
      }
      dispatched = true;
      final orderId = await useCase
          .execute(
            draft: draft,
            submissionId: submissionId,
            confirmation: confirmation,
          )
          .timeout(_requestLimit);
      if (orderId.trim().isEmpty) {
        throw const CustomerOrderUnconfirmedFailure();
      }
      if (!_current(customerId, generation)) {
        return null;
      }
      final cleared = ref
          .read(cartProvider.notifier)
          .completeSubmission(submissionId: submissionId, expectedCart: cart);
      if (!cleared || !await journal.finish(submissionId)) {
        _error(
          customerId,
          generation,
          const CustomerOrderLocalStorageFailure(),
        );
        return null;
      }
      if (!_current(customerId, generation)) {
        return null;
      }
      _refreshOrders(orderId);
      state = AsyncData(orderId);
      return orderId;
    } catch (error) {
      final definitelyNotCreated =
          !dispatched ||
          error is CustomerOrderNotConfiguredFailure ||
          error is CustomerOrderPreSendFailure ||
          error is CustomerOrderForbiddenFailure ||
          error is CustomerOrderRejectedFailure ||
          error is CustomerOrderPriceChangedFailure;
      if (definitelyNotCreated && saved && submissionId != null) {
        if (!await journal.finish(submissionId)) {
          _error(
            customerId,
            generation,
            const CustomerOrderLocalStorageFailure(),
          );
          return null;
        }
      }
      final failure = definitelyNotCreated
          ? (error is CustomerOrderFailure
                ? error
                : const CustomerOrderPreSendFailure())
          : const CustomerOrderUnconfirmedFailure();
      if (_current(customerId, generation) &&
          error is CustomerOrderPriceChangedFailure) {
        ref.invalidate(customerCatalogProvider);
      }
      _error(customerId, generation, failure);
      return null;
    } finally {
      _finished(customerId);
    }
  }

  /// Hanya lookup dengan ID tersimpan. Tidak memanggil createOrder lagi.
  Future<String?> recover() async {
    if (!ref.mounted) {
      return null;
    }
    final customerId = ref.read(authStateProvider).activeCustomerId;
    if (customerId == null ||
        customerId != _customerId ||
        _inFlight.contains(customerId)) {
      return null;
    }
    final persisted = ref.read(customerCheckoutJournalProvider(customerId));
    if (persisted.isLoading || persisted.hasError) {
      return null;
    }
    final pending = persisted.asData?.value;
    if (pending == null) {
      return null;
    }
    final repository = ref.read(customerOrderRepositoryProvider);
    final journal = ref.read(
      customerCheckoutJournalProvider(customerId).notifier,
    );
    final cart = ref.read(cartProvider);
    final generation = _generation;
    _inFlight.add(customerId);
    state = const AsyncLoading<String?>();
    try {
      final result = await repository
          .lookupSubmission(submissionId: pending.submissionId)
          .timeout(_requestLimit);
      if (result.customerId != customerId ||
          result.submissionId != pending.submissionId) {
        throw const CustomerOrderUnconfirmedFailure();
      }
      if (!_current(customerId, generation)) {
        return null;
      }
      if (result.status == OrderSubmissionStatus.pending) {
        _error(customerId, generation, const CustomerOrderUnconfirmedFailure());
        return null;
      }
      if (result.status == OrderSubmissionStatus.confirmed) {
        if (!ref
            .read(cartProvider.notifier)
            .completeSubmission(
              submissionId: pending.submissionId,
              expectedCart: cart,
            )) {
          throw const CustomerOrderUnconfirmedFailure();
        }
      }
      if (!await journal.finish(pending.submissionId)) {
        _error(
          customerId,
          generation,
          const CustomerOrderLocalStorageFailure(),
        );
        return null;
      }
      if (!_current(customerId, generation)) {
        return null;
      }
      final orderId = result.orderId;
      if (orderId != null) {
        _refreshOrders(orderId);
      }
      state = AsyncData(orderId);
      return result.orderId;
    } catch (error) {
      // Gagal lookup tidak membuktikan request awal gagal dibuat.
      _error(
        customerId,
        generation,
        error is CustomerOrderNotConfiguredFailure
            ? error
            : const CustomerOrderUnconfirmedFailure(),
      );
      return null;
    } finally {
      _finished(customerId);
    }
  }

  bool _current(String id, int generation) =>
      ref.mounted &&
      generation == _generation &&
      id == _customerId &&
      id == ref.read(authStateProvider).activeCustomerId &&
      identical(ref.read(authStateProvider.notifier), _session) &&
      ref.read(authStateProvider.notifier).sessionGeneration ==
          _sessionGeneration;

  void _refreshOrders(String orderId) {
    ref.read(sharedDataRevisionProvider.notifier).bump();
    ref.invalidate(customerOrderFeedProvider);
    ref.invalidate(customerOrderDetailProvider(orderId));
  }

  void _error(String id, int generation, CustomerOrderFailure error) {
    if (_current(id, generation)) {
      state = AsyncError(error, StackTrace.current);
    }
  }

  void _finished(String id) {
    _inFlight.remove(id);
    if (ref.mounted && id == _customerId && state.isLoading) {
      final persisted = ref.read(customerCheckoutJournalProvider(id));
      state =
          persisted.isLoading ||
              persisted.asData?.value != null ||
              persisted.hasError
          ? AsyncError(
              const CustomerOrderUnconfirmedFailure(),
              StackTrace.current,
            )
          : const AsyncData<String?>(null);
    }
  }
}
