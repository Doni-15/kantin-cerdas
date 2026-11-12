import 'package:kantin_cerdas/core/config/app_feature_flags.dart';
import 'package:kantin_cerdas/core/session/shared_data_revision_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/cart_catalog_reconciliation_provider.dart';
import '../support/simulation_harness.dart';

void main() {
  group('AppFeatureFlags & RegisterDraft', () {
    test(
      'feature flag yang belum memiliki endpoint backend bernilai false secara default dan RegisterDraft membersihkan password dengan aman',
      () async {
        expect(AppFeatureFlags.enableGoogleAuth, isFalse);
        expect(AppFeatureFlags.enableProfilePhotoUpload, isTrue);
        expect(AppFeatureFlags.enableEmailVerification, isFalse);
        expect(AppFeatureFlags.enableDeviceSessionManagement, isFalse);
        expect(AppFeatureFlags.enableLoginActivityHistory, isFalse);

        final h = await createHarness();
        addTearDown(h.dispose);
        final sub = h.container.listen(registerDraftProvider, (_, _) {});
        addTearDown(sub.close);

        h.container
            .read(registerDraftProvider.notifier)
            .setDraft(
              const RegisterDraft(
                name: 'Budi',
                email: 'budi@kampus.ac.id',
                password: 'Password123!',
              ),
            );
        expect(
          h.container.read(registerDraftProvider)?.password,
          'Password123!',
        );

        h.container.read(registerDraftProvider.notifier).clearPassword();
        expect(h.container.read(registerDraftProvider)?.password, isEmpty);
        expect(
          h.container.read(registerDraftProvider)?.email,
          'budi@kampus.ac.id',
        );
      },
    );
  });

  group('CartCatalogReconciliationProvider (MED-10)', () {
    test(
      'menghitung harga rekonsiliasi terbaru dan mendeteksi perubahan harga katalog',
      () async {
        final h = await createHarness();
        addTearDown(h.dispose);
        await h.cart();

        final initialRec = h.container.read(cartCatalogReconciliationProvider);
        expect(initialRec.canProceedToCheckout, isTrue);
        expect(initialRec.hasPriceChanges, isFalse);
        expect(initialRec.reconciledTotalPriceIdr, 15000);

        final ownerRepo = SimulationOwnerRepository(h.store);
        await SimulationAuthRepository(
          h.store,
        ).login(identifier: 'pemilik', password: 'Simulasi123!');
        final menu = (await ownerRepo.listMenus(
          stallId: 'stall-1',
          search: 'Nasi Ayam',
        )).items.first;
        await ownerRepo.saveMenu(
          OwnerMenuInput(
            id: menu.id,
            stallId: menu.stallId,
            name: menu.name,
            description: menu.description,
            category: menu.category,
            priceIdr: 18000,
            isAvailable: true,
            expectedVersion: menu.version,
          ),
          mutationId: 'update-price-rec',
        );

        await SimulationAuthRepository(
          h.store,
        ).login(identifier: 'pelanggan', password: 'Simulasi123!');
        h.container.invalidate(customerCatalogProvider);
        await h.container.read(customerCatalogProvider.future);

        final updatedRec = h.container.read(cartCatalogReconciliationProvider);
        expect(updatedRec.hasPriceChanges, isTrue);
        expect(updatedRec.reconciledTotalPriceIdr, 18000);
        expect(updatedRec.canProceedToCheckout, isTrue);
      },
    );

    test(
      'checkout tetap diterima bila katalog di-refresh ulang tanpa perubahan harga (HIGH-NEW-01) dan menaikkan sharedDataRevisionProvider (MED-NEW-04)',
      () async {
        final h = await createHarness();
        addTearDown(h.dispose);
        await h.cart();

        final initialConfirmation = h.container.read(
          customerCheckoutReviewProvider,
        )!;

        h.container.invalidate(customerCatalogProvider);
        await h.container.read(customerCatalogProvider.future);
        final refreshedConfirmation = h.container.read(
          customerCheckoutReviewProvider,
        )!;

        expect(identical(initialConfirmation, refreshedConfirmation), isFalse);
        expect(initialConfirmation, equals(refreshedConfirmation));

        final revisionBefore = h.container.read(sharedDataRevisionProvider);
        final orderId = await h.container
            .read(customerOrderControllerProvider.notifier)
            .submit(confirmation: initialConfirmation);

        expect(orderId, isNotNull);
        expect(
          h.container.read(sharedDataRevisionProvider),
          greaterThan(revisionBefore),
        );
      },
    );
  });
}
