import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kantin_cerdas/features/customer/domain/providers/customer_domain_providers.dart';
import 'package:kantin_cerdas/features/customer/domain/usecases/create_customer_order.dart';

export 'package:kantin_cerdas/features/customer/domain/providers/customer_domain_providers.dart'
    show customerOrderRepositoryProvider;

final createCustomerOrderUseCaseProvider = Provider<CreateCustomerOrder>((ref) {
  return CreateCustomerOrder(ref.watch(customerOrderRepositoryProvider));
});
