import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/utils/rupiah_formatter.dart';
import 'package:kantin_cerdas/core/widgets/kc_button.dart';
import 'package:kantin_cerdas/core/widgets/kc_loading_skeleton.dart';
import 'package:kantin_cerdas/core/widgets/kc_status_panel.dart';
import 'package:kantin_cerdas/features/customer/presentation/controllers/customer_order_controller.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_catalog_provider.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_checkout_review_provider.dart';
import 'package:kantin_cerdas/theme/kc_spacing.dart';

class CustomerCheckoutSubmit extends ConsumerWidget {
  const CustomerCheckoutSubmit({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(customerCheckoutConfiguredProvider)) {
      return const KcStatusPanel(
        title: 'Pemesanan belum tersedia',
        message:
            'Kamu masih bisa meninjau keranjang. Layanan pemesanan belum terhubung.',
      );
    }
    final submission = ref.watch(customerOrderControllerProvider);
    if (submission.isLoading) {
      return const KcStatusPanel(
        title: 'Memproses pesanan',
        message: 'Menunggu konfirmasi hasil pesanan.',
        loading: true,
      );
    }
    final catalog = ref.watch(customerCatalogProvider);
    if (catalog.isLoading) {
      return const KcLoadingSkeleton(
        label: 'Memuat harga dan ketersediaan menu',
        layout: KcSkeletonLayout.detail,
      );
    }
    final confirmation = ref.watch(customerCheckoutReviewProvider);
    if (confirmation == null) {
      return KcStatusPanel(
        title: 'Pesanan perlu ditinjau kembali',
        message:
            'Harga atau ketersediaan menu belum dapat dipastikan. Muat ulang katalog dan periksa pilihanmu.',
        action: KcButton(
          label: 'Muat ulang katalog',
          onPressed: () => ref.invalidate(customerCatalogProvider),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tunai saat pengambilan',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: KcSpacing.xs),
        const Text(
          'Harga dan ketersediaan diperiksa saat pesanan dibuat. '
          'Jika berubah, pesanan tidak dibuat dan kamu perlu meninjau ulang.',
        ),
        const SizedBox(height: KcSpacing.md),
        KcButton(
          label: 'Buat pesanan · ${formatRupiah(confirmation.totalPriceIdr)}',
          onPressed: () {
            ref
                .read(customerOrderControllerProvider.notifier)
                .submit(confirmation: confirmation);
          },
        ),
      ],
    );
  }
}
