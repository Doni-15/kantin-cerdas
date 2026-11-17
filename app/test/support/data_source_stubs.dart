// Stub datasource bersama untuk test layer data. Hanya kelas yang dipakai oleh
// lebih dari satu berkas test yang ditempatkan di sini; stub yang dipakai satu
// berkas tetap privat di berkas itu.
import 'dart:async';

import 'package:kantin_cerdas/features/customer/data/datasources/customer_order_datasource.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/customer_order_price_confirmation.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_draft.dart';
import 'package:kantin_cerdas/features/customer/domain/entities/order_submission_lookup.dart';

class StubCustomerOrderDataSource implements CustomerOrderDataSource {
  const StubCustomerOrderDataSource({required this.onCreateOrder});

  final Future<String> Function(
    OrderDraft draft,
    String submissionId,
    CustomerOrderPriceConfirmation confirmation,
  )
  onCreateOrder;

  @override
  bool get isCheckoutConfigured => true;

  @override
  Future<String> createOrder({
    required OrderDraft draft,
    required String submissionId,
    required CustomerOrderPriceConfirmation confirmation,
  }) => onCreateOrder(draft, submissionId, confirmation);

  @override
  Future<OrderSubmissionLookup> lookupSubmission({
    required String submissionId,
  }) => throw UnimplementedError();
}
