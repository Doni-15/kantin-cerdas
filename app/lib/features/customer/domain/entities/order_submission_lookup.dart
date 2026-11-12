enum OrderSubmissionStatus { pending, confirmed, notCreated }

/// Hasil layanan untuk pengiriman milik sesi terautentikasi.
/// notCreated harus berarti key disegel: request terlambat tidak boleh membuat order.
/// Dokumen yang belum ditemukan tidak cukup untuk menyatakan notCreated.
class OrderSubmissionLookup {
  OrderSubmissionLookup({
    required this.customerId,
    required this.submissionId,
    required this.status,
    this.orderId,
  }) {
    if (customerId.trim().isEmpty ||
        submissionId.trim().isEmpty ||
        (status == OrderSubmissionStatus.confirmed &&
            (orderId == null || orderId!.trim().isEmpty)) ||
        (status != OrderSubmissionStatus.confirmed && orderId != null)) {
      throw ArgumentError('Hasil pemeriksaan pengiriman tidak valid.');
    }
  }
  final String customerId;
  final String submissionId;
  final OrderSubmissionStatus status;
  final String? orderId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderSubmissionLookup &&
          other.customerId == customerId &&
          other.submissionId == submissionId &&
          other.status == status &&
          other.orderId == orderId);

  @override
  int get hashCode => Object.hash(customerId, submissionId, status, orderId);
}
