/// Kegagalan pembacaan katalog pada lapisan domain.
sealed class CustomerCatalogFailure implements Exception {
  const CustomerCatalogFailure();

  @override
  String toString() => runtimeType.toString();
}

/// Sumber data katalog belum dikonfigurasi pada environment ini.
final class CustomerCatalogNotConfiguredFailure extends CustomerCatalogFailure {
  const CustomerCatalogNotConfiguredFailure();
}

/// Pemuatan gagal karena gangguan koneksi atau batas waktu terlampaui.
final class CustomerCatalogNetworkFailure extends CustomerCatalogFailure {
  const CustomerCatalogNetworkFailure();
}

/// Server gagal memproses permintaan katalog.
final class CustomerCatalogServerFailure extends CustomerCatalogFailure {
  const CustomerCatalogServerFailure();
}

/// Kegagalan lainnya, termasuk data respons yang tidak valid.
final class CustomerCatalogUnexpectedFailure extends CustomerCatalogFailure {
  const CustomerCatalogUnexpectedFailure();
}
