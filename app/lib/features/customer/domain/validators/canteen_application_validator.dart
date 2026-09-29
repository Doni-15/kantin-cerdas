/// Satu sumber aturan validasi pengajuan kantin.
/// Dipakai UI (feedback cepat), UseCase (pengaman), dan dummy (meniru 422 Backend).
abstract final class CanteenApplicationValidator {
  static String? name(String value) {
    if (value.trim().isEmpty) {
      return 'Nama kantin wajib diisi';
    }

    return null;
  }

  static String? description(String value) {
    if (value.trim().isEmpty) {
      return 'Deskripsi kantin wajib diisi';
    }

    return null;
  }

  static String? address(String value) {
    if (value.trim().isEmpty) {
      return 'Alamat kantin wajib diisi';
    }

    return null;
  }
}
