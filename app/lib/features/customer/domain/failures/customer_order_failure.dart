/// Kegagalan pemesanan yang dapat ditangani controller dan UI.
///
/// Pesan untuk pengguna ditentukan di lapisan presentation.
/// Respons mentah backend tidak disimpan sebagai pesan kegagalan domain.
sealed class CustomerOrderFailure implements Exception {
  const CustomerOrderFailure();

  @override
  bool operator ==(Object other) => runtimeType == other.runtimeType;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => runtimeType.toString();
}

/// Backend mengonfirmasi bahwa pesanan tidak dibuat karena ditolak.
///
/// Gunakan hanya jika makna respons pada kontrak API memastikan penolakan.
/// Status HTTP saja belum tentu cukup untuk memastikan hasil pemesanan.
final class CustomerOrderRejectedFailure extends CustomerOrderFailure {
  const CustomerOrderRejectedFailure();
}

/// Layanan menolak secara definitif karena sesi/peran tidak diizinkan (401/403).
final class CustomerOrderForbiddenFailure extends CustomerOrderFailure {
  const CustomerOrderForbiddenFailure();
}

/// Request mungkin sudah diproses, tetapi hasilnya belum dapat dipastikan.
///
/// Contohnya koneksi terputus setelah request dikirim atau respons
/// keberhasilan tidak dapat dibaca sehingga ID pesanan belum diketahui.
///
/// UI harus mempertahankan keranjang dan menjelaskan bahwa hasil pemesanan
/// belum terkonfirmasi. Jangan langsung mengirim ulang request pembuatan.
final class CustomerOrderUnconfirmedFailure extends CustomerOrderFailure {
  const CustomerOrderUnconfirmedFailure();
}

/// Kegagalan lama yang tidak menjelaskan tahap pengiriman.
/// Dipertahankan untuk kompatibilitas tipe; diperlakukan sebagai outcome unknown.
/// Adapter baru harus memakai klasifikasi eksplisit di bawah.
final class CustomerOrderUnexpectedFailure extends CustomerOrderFailure {
  const CustomerOrderUnexpectedFailure();
}

/// Adapter memastikan belum ada request yang dikirim.
final class CustomerOrderNotConfiguredFailure extends CustomerOrderFailure {
  const CustomerOrderNotConfiguredFailure();
}

final class CustomerOrderPreSendFailure extends CustomerOrderFailure {
  const CustomerOrderPreSendFailure();
}

final class CustomerOrderLocalStorageFailure extends CustomerOrderFailure {
  const CustomerOrderLocalStorageFailure();
}

final class CustomerOrderCatalogChangedFailure extends CustomerOrderFailure {
  const CustomerOrderCatalogChangedFailure();
}

/// Layanan secara definitif menolak sebelum membuat pesanan karena harga
/// tidak lagi sama dengan yang disetujui. Bukan klasifikasi untuk timeout.
final class CustomerOrderPriceChangedFailure extends CustomerOrderFailure {
  const CustomerOrderPriceChangedFailure();
}
