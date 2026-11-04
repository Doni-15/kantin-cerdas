import 'package:kantin_cerdas/features/customer/domain/entities/assistant_reply.dart';

abstract interface class CustomerAssistantRepository {
  /// Satu pertanyaan mandiri, maksimal 500 karakter.
  /// Layanan membaca preferensi tersimpan milik UID aktif, memverifikasi menu/harga
  /// terhadap katalog nyata dan menyimpan secret AI di server. Jangan menganggap
  /// preferensi menjamin keamanan alergi; respons lama tidak direvisi oleh client.
  Future<AssistantReply> recommend(String message);
}
