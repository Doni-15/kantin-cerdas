import 'package:kantin_cerdas/features/customer/domain/failures/food_preferences_failure.dart';

String foodPreferencesMessage(Object? error) => error is FoodPreferencesFailure
    ? switch (error) {
        FoodPreferencesNotConfiguredFailure() =>
          'Layanan preferensi belum tersedia. Data belum dapat dibaca atau disimpan.',
        FoodPreferencesForbiddenFailure() =>
          'Akses preferensi tidak tersedia. Periksa kembali sesi akunmu.',
        FoodPreferencesInvalidDataFailure() =>
          'Data preferensi dari layanan tidak valid. Coba muat ulang.',
        FoodPreferencesReadTimeoutFailure() =>
          'Waktu pembacaan habis. Periksa koneksi lalu coba lagi.',
        FoodPreferencesRejectedFailure() =>
          'Layanan menolak perubahan. Periksa isian sebelum mencoba lagi.',
        FoodPreferencesConflictFailure() =>
          'Preferensi sudah berubah. Muat data terbaru sebelum menyimpan lagi; isian akan diganti dengan data layanan.',
        FoodPreferencesStorageFailure() =>
          'Penanda penyimpanan belum dapat dibaca atau diperbarui. Periksa penyimpanan perangkat lalu baca ulang penanda.',
        FoodPreferencesPreSendFailure() =>
          'Permintaan belum dikirim. Periksa kembali isian dan coba lagi.',
        FoodPreferencesUnknownFailure() =>
          'Penyimpanan mungkin sudah diterapkan. Periksa status sebelum mengirim perubahan lagi.',
      }
    : 'Preferensi belum dapat diproses. Periksa koneksi lalu coba lagi.';
