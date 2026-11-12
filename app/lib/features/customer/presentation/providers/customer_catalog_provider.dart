import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/core/session/shared_data_revision_provider.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_catalog.dart';
import 'package:kantin_cerdas/features/customer/domain/failures/customer_catalog_failure.dart';
import 'package:kantin_cerdas/features/customer/domain/providers/customer_domain_providers.dart';
import 'package:kantin_cerdas/features/customer/domain/usecases/get_customer_catalog.dart';
import 'package:kantin_cerdas/features/customer/presentation/providers/customer_read_session.dart';

export 'package:kantin_cerdas/features/customer/domain/providers/customer_domain_providers.dart'
    show customerCatalogRepositoryProvider;

final getCustomerCatalogUseCaseProvider = Provider<GetCustomerCatalog>((ref) {
  return GetCustomerCatalog(ref.watch(customerCatalogRepositoryProvider));
});

/// Memuat katalog pelanggan untuk halaman Beranda, Pencarian, dan Detail Stan.
final customerCatalogProvider = FutureProvider.autoDispose<CustomerCatalog>((
  ref,
) async {
  ref.watch(sharedDataRevisionProvider);
  final session = CustomerReadSession(ref);
  final useCase = ref.watch(getCustomerCatalogUseCaseProvider);
  try {
    final catalog = await useCase.execute().timeout(
      const Duration(seconds: 30),
    );
    session.check(ref);
    return catalog;
  } on TimeoutException {
    throw const CustomerCatalogNetworkFailure();
  }
}, retry: (_, _) => null);
