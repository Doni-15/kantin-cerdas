/// Penanda lokal minimal. Tidak berisi token, isi keranjang, atau pembayaran.
class PendingOrderSubmission {
  PendingOrderSubmission({
    required this.customerId,
    required this.submissionId,
  }) {
    if (customerId.trim().isEmpty || submissionId.trim().isEmpty) {
      throw ArgumentError('Identitas pengiriman tidak valid.');
    }
  }
  final String customerId;
  final String submissionId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingOrderSubmission &&
          other.customerId == customerId &&
          other.submissionId == submissionId);

  @override
  int get hashCode => Object.hash(customerId, submissionId);
}
